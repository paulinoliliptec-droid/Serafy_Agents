"""
Firestore checkpoint saver for LangGraph.

Document structure:
  Collection: {collection}/checkpoints
    Document ID: {tenant_id}:{thread_id}:{checkpoint_ns}:{checkpoint_id}
    Fields:
      - tenant_id, thread_id, checkpoint_ns, checkpoint_id
      - parent_checkpoint_id (str | None)
      - checkpoint_type, checkpoint_data   (serde-encoded)
      - metadata_type, metadata_data       (serde-encoded)
      - channel_versions                   (JSON-serialisable dict)
      - created_at                         (Firestore Timestamp)

  Collection: {collection}/writes
    Document ID: {tenant_id}:{thread_id}:{checkpoint_ns}:{checkpoint_id}:{task_id}:{idx}
    Fields:
      - task_id, task_path, idx
      - channel
      - value_type, value_data             (serde-encoded)
"""

from __future__ import annotations

import base64
import logging
from typing import Any, AsyncIterator, Iterator, Optional, Sequence

from langchain_core.runnables import RunnableConfig
from langgraph.checkpoint.base import (
    BaseCheckpointSaver,
    ChannelVersions,
    Checkpoint,
    CheckpointMetadata,
    CheckpointTuple,
)

logger = logging.getLogger(__name__)


def _doc_id(*parts: str) -> str:
    return ":".join(parts)


def _encode(serde, obj: Any) -> tuple[str, str]:
    """Serialise obj → (type_str, base64_data)."""
    type_str, raw = serde.dumps_typed(obj)
    return type_str, base64.b64encode(raw).decode()


def _decode(serde, type_str: str, b64_data: str) -> Any:
    """Deserialise (type_str, base64_data) → obj."""
    return serde.loads_typed((type_str, base64.b64decode(b64_data)))


def _extract_config(config: RunnableConfig) -> tuple[str, str, str]:
    """Return (tenant_id, thread_id, checkpoint_ns) from config."""
    cfg = config.get("configurable", {})
    tenant_id = cfg.get("tenant_id", "default")
    thread_id = cfg.get("thread_id", "")
    checkpoint_ns = cfg.get("checkpoint_ns", "")
    return tenant_id, thread_id, checkpoint_ns


def _to_checkpoint_tuple(serde, doc: dict) -> CheckpointTuple:
    checkpoint = _decode(serde, doc["checkpoint_type"], doc["checkpoint_data"])
    metadata = _decode(serde, doc["metadata_type"], doc["metadata_data"])
    config = {
        "configurable": {
            "tenant_id": doc["tenant_id"],
            "thread_id": doc["thread_id"],
            "checkpoint_ns": doc["checkpoint_ns"],
            "checkpoint_id": doc["checkpoint_id"],
        }
    }
    parent_config = None
    if doc.get("parent_checkpoint_id"):
        parent_config = {
            "configurable": {
                "tenant_id": doc["tenant_id"],
                "thread_id": doc["thread_id"],
                "checkpoint_ns": doc["checkpoint_ns"],
                "checkpoint_id": doc["parent_checkpoint_id"],
            }
        }
    return CheckpointTuple(
        config=config,
        checkpoint=checkpoint,
        metadata=metadata,
        parent_config=parent_config,
    )


class FirestoreCheckpointer(BaseCheckpointSaver):
    """
    LangGraph checkpoint saver backed by Google Cloud Firestore.

    Provides tenant-isolated, persistent state across sessions for multi-tenant
    deployments on GCP Cloud Run.

    Usage:
        from google.cloud import firestore as _fs
        checkpointer = FirestoreCheckpointer(
            sync_client=_fs.Client(project="my-project"),
            async_client=_fs.AsyncClient(project="my-project"),
        )
        graph = build_graph(checkpointer=checkpointer)

        # Include tenant_id in every invoke config:
        config = {"configurable": {"thread_id": session_id, "tenant_id": tenant_id}}
        result = await graph.ainvoke(state, config=config)
    """

    def __init__(
        self,
        sync_client,   # google.cloud.firestore.Client
        async_client,  # google.cloud.firestore.AsyncClient
        collection: str = "agentos_checkpoints",
    ) -> None:
        super().__init__()
        self._sync = sync_client
        self._async = async_client
        self._col = collection

    # ── Internal helpers ──────────────────────────────────────────────────────

    def _checkpoints_col(self):
        return self._sync.collection(f"{self._col}/checkpoints")

    def _writes_col(self):
        return self._sync.collection(f"{self._col}/writes")

    def _async_checkpoints_col(self):
        return self._async.collection(f"{self._col}/checkpoints")

    def _async_writes_col(self):
        return self._async.collection(f"{self._col}/writes")

    def _build_doc(
        self,
        config: RunnableConfig,
        checkpoint: Checkpoint,
        metadata: CheckpointMetadata,
        new_versions: ChannelVersions,
        parent_checkpoint_id: str | None,
    ) -> tuple[str, dict]:
        tenant_id, thread_id, checkpoint_ns = _extract_config(config)
        checkpoint_id = checkpoint["id"]
        doc_id = _doc_id(tenant_id, thread_id, checkpoint_ns, checkpoint_id)

        cp_type, cp_data = _encode(self.serde, checkpoint)
        meta_type, meta_data = _encode(self.serde, metadata)

        doc = {
            "tenant_id": tenant_id,
            "thread_id": thread_id,
            "checkpoint_ns": checkpoint_ns,
            "checkpoint_id": checkpoint_id,
            "parent_checkpoint_id": parent_checkpoint_id,
            "checkpoint_type": cp_type,
            "checkpoint_data": cp_data,
            "metadata_type": meta_type,
            "metadata_data": meta_data,
            "channel_versions": dict(new_versions),
        }
        return doc_id, doc

    # ── Sync interface ────────────────────────────────────────────────────────

    def get_tuple(self, config: RunnableConfig) -> Optional[CheckpointTuple]:
        tenant_id, thread_id, checkpoint_ns = _extract_config(config)
        checkpoint_id = config.get("configurable", {}).get("checkpoint_id")

        col = self._checkpoints_col()
        try:
            if checkpoint_id:
                doc_id = _doc_id(tenant_id, thread_id, checkpoint_ns, checkpoint_id)
                snap = col.document(doc_id).get()
                if not snap.exists:
                    return None
                return _to_checkpoint_tuple(self.serde, snap.to_dict())
            else:
                # Latest checkpoint for this thread
                query = (
                    col
                    .where("tenant_id", "==", tenant_id)
                    .where("thread_id", "==", thread_id)
                    .where("checkpoint_ns", "==", checkpoint_ns)
                    .order_by("checkpoint_id", direction="DESCENDING")
                    .limit(1)
                )
                docs = list(query.stream())
                if not docs:
                    return None
                return _to_checkpoint_tuple(self.serde, docs[0].to_dict())
        except Exception:
            logger.exception("firestore get_tuple failed")
            return None

    def list(
        self,
        config: Optional[RunnableConfig],
        *,
        filter: Optional[dict[str, Any]] = None,
        before: Optional[RunnableConfig] = None,
        limit: Optional[int] = None,
    ) -> Iterator[CheckpointTuple]:
        if not config:
            return
        tenant_id, thread_id, checkpoint_ns = _extract_config(config)
        col = self._checkpoints_col()
        try:
            query = (
                col
                .where("tenant_id", "==", tenant_id)
                .where("thread_id", "==", thread_id)
                .where("checkpoint_ns", "==", checkpoint_ns)
                .order_by("checkpoint_id", direction="DESCENDING")
            )
            if before:
                before_id = before.get("configurable", {}).get("checkpoint_id")
                if before_id:
                    query = query.where("checkpoint_id", "<", before_id)
            if limit:
                query = query.limit(limit)
            for snap in query.stream():
                yield _to_checkpoint_tuple(self.serde, snap.to_dict())
        except Exception:
            logger.exception("firestore list failed")

    def put(
        self,
        config: RunnableConfig,
        checkpoint: Checkpoint,
        metadata: CheckpointMetadata,
        new_versions: ChannelVersions,
    ) -> RunnableConfig:
        parent_id = config.get("configurable", {}).get("checkpoint_id")
        doc_id, doc = self._build_doc(config, checkpoint, metadata, new_versions, parent_id)
        try:
            self._checkpoints_col().document(doc_id).set(doc)
        except Exception:
            logger.exception("firestore put failed")
        tenant_id, thread_id, checkpoint_ns = _extract_config(config)
        return {
            "configurable": {
                "tenant_id": tenant_id,
                "thread_id": thread_id,
                "checkpoint_ns": checkpoint_ns,
                "checkpoint_id": checkpoint["id"],
            }
        }

    def put_writes(
        self,
        config: RunnableConfig,
        writes: Sequence[tuple[str, Any]],
        task_id: str,
        task_path: str = "",
    ) -> None:
        tenant_id, thread_id, checkpoint_ns = _extract_config(config)
        checkpoint_id = config.get("configurable", {}).get("checkpoint_id", "")
        col = self._writes_col()
        batch = self._sync.batch()
        for idx, (channel, value) in enumerate(writes):
            val_type, val_data = _encode(self.serde, value)
            doc_id = _doc_id(tenant_id, thread_id, checkpoint_ns, checkpoint_id, task_id, str(idx))
            doc = {
                "task_id": task_id,
                "task_path": task_path,
                "idx": idx,
                "channel": channel,
                "value_type": val_type,
                "value_data": val_data,
            }
            batch.set(col.document(doc_id), doc)
        try:
            batch.commit()
        except Exception:
            logger.exception("firestore put_writes failed")

    # ── Async interface ───────────────────────────────────────────────────────

    async def aget_tuple(self, config: RunnableConfig) -> Optional[CheckpointTuple]:
        tenant_id, thread_id, checkpoint_ns = _extract_config(config)
        checkpoint_id = config.get("configurable", {}).get("checkpoint_id")
        col = self._async_checkpoints_col()
        try:
            if checkpoint_id:
                doc_id = _doc_id(tenant_id, thread_id, checkpoint_ns, checkpoint_id)
                snap = await col.document(doc_id).get()
                if not snap.exists:
                    return None
                return _to_checkpoint_tuple(self.serde, snap.to_dict())
            else:
                query = (
                    col
                    .where("tenant_id", "==", tenant_id)
                    .where("thread_id", "==", thread_id)
                    .where("checkpoint_ns", "==", checkpoint_ns)
                    .order_by("checkpoint_id", direction="DESCENDING")
                    .limit(1)
                )
                docs = [d async for d in query.stream()]
                if not docs:
                    return None
                return _to_checkpoint_tuple(self.serde, docs[0].to_dict())
        except Exception:
            logger.exception("firestore aget_tuple failed")
            return None

    async def alist(
        self,
        config: Optional[RunnableConfig],
        *,
        filter: Optional[dict[str, Any]] = None,
        before: Optional[RunnableConfig] = None,
        limit: Optional[int] = None,
    ) -> AsyncIterator[CheckpointTuple]:
        if not config:
            return
        tenant_id, thread_id, checkpoint_ns = _extract_config(config)
        col = self._async_checkpoints_col()
        try:
            query = (
                col
                .where("tenant_id", "==", tenant_id)
                .where("thread_id", "==", thread_id)
                .where("checkpoint_ns", "==", checkpoint_ns)
                .order_by("checkpoint_id", direction="DESCENDING")
            )
            if before:
                before_id = before.get("configurable", {}).get("checkpoint_id")
                if before_id:
                    query = query.where("checkpoint_id", "<", before_id)
            if limit:
                query = query.limit(limit)
            async for snap in query.stream():
                yield _to_checkpoint_tuple(self.serde, snap.to_dict())
        except Exception:
            logger.exception("firestore alist failed")

    async def aput(
        self,
        config: RunnableConfig,
        checkpoint: Checkpoint,
        metadata: CheckpointMetadata,
        new_versions: ChannelVersions,
    ) -> RunnableConfig:
        parent_id = config.get("configurable", {}).get("checkpoint_id")
        doc_id, doc = self._build_doc(config, checkpoint, metadata, new_versions, parent_id)
        try:
            await self._async_checkpoints_col().document(doc_id).set(doc)
        except Exception:
            logger.exception("firestore aput failed")
        tenant_id, thread_id, checkpoint_ns = _extract_config(config)
        return {
            "configurable": {
                "tenant_id": tenant_id,
                "thread_id": thread_id,
                "checkpoint_ns": checkpoint_ns,
                "checkpoint_id": checkpoint["id"],
            }
        }

    async def aput_writes(
        self,
        config: RunnableConfig,
        writes: Sequence[tuple[str, Any]],
        task_id: str,
        task_path: str = "",
    ) -> None:
        tenant_id, thread_id, checkpoint_ns = _extract_config(config)
        checkpoint_id = config.get("configurable", {}).get("checkpoint_id", "")
        col = self._async_checkpoints_col()
        # Firestore async SDK doesn't support batches the same way; write concurrently
        import asyncio
        writes_col = self._async_writes_col()
        tasks = []
        for idx, (channel, value) in enumerate(writes):
            val_type, val_data = _encode(self.serde, value)
            doc_id = _doc_id(tenant_id, thread_id, checkpoint_ns, checkpoint_id, task_id, str(idx))
            doc = {
                "task_id": task_id,
                "task_path": task_path,
                "idx": idx,
                "channel": channel,
                "value_type": val_type,
                "value_data": val_data,
            }
            tasks.append(writes_col.document(doc_id).set(doc))
        try:
            await asyncio.gather(*tasks)
        except Exception:
            logger.exception("firestore aput_writes failed")
