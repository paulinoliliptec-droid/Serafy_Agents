from __future__ import annotations

import asyncio
import hashlib
import hmac
import time
import uuid
from datetime import datetime
from typing import Annotated, Any, Optional

import httpx
import structlog
from fastapi import APIRouter, Depends, HTTPException, Query, Request, status
from langchain_core.messages import HumanMessage
from langgraph.checkpoint.memory import MemorySaver

from agents import AgentState, build_graph
from config import settings
from .auth import FirebaseUser, require_firebase_auth
from .schemas import (
    ChatRequest,
    ChatResponse,
    HealthResponse,
    WAWebhookPayload,
    WAWebhookResponse,
)

logger = structlog.get_logger(__name__)
router = APIRouter()

# ── Lazy Firestore client (reused across requests within the same instance) ──

_firestore: Any = None


def _get_firestore() -> Any:
    global _firestore
    if _firestore is None and settings.gcp_project_id:
        try:
            from google.cloud import firestore
            _firestore = firestore.AsyncClient(project=settings.gcp_project_id)
        except ImportError:
            pass
    return _firestore


# ── Firestore write helpers (all fire-and-forget) ────────────────────────────

async def _persist_conversation(
    session_id: str,
    tenant_id: str,
    user_id: str,
    channel: str,
    last_message: str,
    agent_used: str,
    status: str = "active",
) -> None:
    db = _get_firestore()
    if db is None:
        return
    try:
        from google.cloud import firestore
        ref = db.collection("conversations").document(session_id)
        doc = await ref.get()
        if doc.exists:
            await ref.update({
                "last_message": last_message[:200],
                "last_agent": agent_used,
                "status": status,
                "message_count": firestore.Increment(1),
                "updated_at": firestore.SERVER_TIMESTAMP,
            })
        else:
            await ref.set({
                "channel": channel,
                "tenant_id": tenant_id,
                "user_id": user_id,
                "last_message": last_message[:200],
                "last_agent": agent_used,
                "status": status,
                "message_count": 1,
                "started_at": firestore.SERVER_TIMESTAMP,
                "updated_at": firestore.SERVER_TIMESTAMP,
            })
    except Exception as exc:
        logger.warning("persist_conversation_failed", error=str(exc))


async def _persist_agent_log(
    session_id: str,
    tenant_id: str,
    agent: str,
    latency_ms: int,
) -> None:
    db = _get_firestore()
    if db is None:
        return
    try:
        from google.cloud import firestore
        await db.collection("agent_logs").add({
            "session_id": session_id,
            "tenant_id": tenant_id,
            "agent": agent,
            "latency_ms": latency_ms,
            "timestamp": firestore.SERVER_TIMESTAMP,
        })
    except Exception as exc:
        logger.warning("persist_agent_log_failed", error=str(exc))


async def _update_daily_metrics(agent_used: str, latency_ms: int) -> None:
    db = _get_firestore()
    if db is None:
        return
    try:
        from google.cloud import firestore
        today = datetime.now().strftime("%Y-%m-%d")
        ref = db.collection("metrics").document("today")
        await ref.set({
            "date": today,
            "total_messages": firestore.Increment(1),
            "total_latency_ms": firestore.Increment(latency_ms),
            f"agent_breakdown.{agent_used}": firestore.Increment(1),
            "updated_at": firestore.SERVER_TIMESTAMP,
        }, merge=True)
    except Exception as exc:
        logger.warning("update_daily_metrics_failed", error=str(exc))


async def _update_system_status() -> None:
    db = _get_firestore()
    if db is None:
        return
    try:
        from google.cloud import firestore
        await db.collection("system_status").document("current").set({
            "cloud_run_healthy": True,
            "openai_active": bool(settings.openai_api_key),
            "gemini_active": bool(settings.gemini_api_key),
            "whatsapp_configured": bool(settings.whatsapp_api_token),
            "updated_at": firestore.SERVER_TIMESTAMP,
        }, merge=True)
    except Exception as exc:
        logger.warning("update_system_status_failed", error=str(exc))

# ── Graph + checkpointer (initialised once at startup) ───────────────────────

def _build_checkpointer():
    if settings.checkpointer_backend == "firestore" and settings.gcp_project_id:
        try:
            from google.cloud import firestore as _fs
            from config.firestore_checkpointer import FirestoreCheckpointer
            return FirestoreCheckpointer(
                sync_client=_fs.Client(project=settings.gcp_project_id),
                async_client=_fs.AsyncClient(project=settings.gcp_project_id),
                collection=settings.firestore_collection,
            )
        except ImportError:
            logger.warning("google_cloud_firestore_missing", fallback="MemorySaver")
    return MemorySaver()


_checkpointer = _build_checkpointer()
_graph = build_graph(checkpointer=_checkpointer)


# ── Shared graph invocation helper ───────────────────────────────────────────

async def _run_graph(
    message: str,
    session_id: str,
    tenant_id: str,
    user_id: str,
    agent: str = "auto",
    memory: dict | None = None,
) -> tuple[str, str, int]:
    """
    Invoke the agent graph and return (reply, agent_used, latency_ms).
    Raises RuntimeError on graph failure.
    """
    initial_state: AgentState = {
        "messages": [HumanMessage(content=message)],
        "next_agent": agent if agent != "auto" else "",
        "tenant_id": tenant_id,
        "memory": {**(memory or {}), "user_id": user_id},
    }
    invoke_config = {
        "configurable": {
            "thread_id": session_id,
            "tenant_id": tenant_id,
        }
    }
    t0 = time.monotonic()
    result: AgentState = await _graph.ainvoke(initial_state, config=invoke_config)
    latency_ms = int((time.monotonic() - t0) * 1000)

    agent_used = result.get("next_agent") or agent
    if not agent_used or agent_used == "end":
        agent_used = "orquestrador"

    last_msg = result["messages"][-1]
    reply = last_msg.content if hasattr(last_msg, "content") else str(last_msg)
    return reply, agent_used, latency_ms


# ── GET /health ───────────────────────────────────────────────────────────────

@router.get("/health", response_model=HealthResponse, tags=["infra"])
async def health_check() -> HealthResponse:
    """Healthcheck endpoint — used by Cloud Run readiness and liveness probes."""
    asyncio.create_task(_update_system_status())
    return HealthResponse(
        environment=settings.app_env,
        checkpointer=type(_checkpointer).__name__,
    )


# ── POST /chat ────────────────────────────────────────────────────────────────

@router.post("/chat", response_model=ChatResponse, tags=["agents"])
async def chat(
    request: ChatRequest,
    user: Annotated[FirebaseUser, Depends(require_firebase_auth)],
) -> ChatResponse:
    """
    Send a message to the agent graph.

    - Requires a valid Firebase ID token in `Authorization: Bearer <token>`.
    - `tenant_id` is taken from the Firebase custom claim when set, otherwise
      falls back to the request body value.
    - `session_id` is used as the LangGraph thread_id for checkpoint continuity.
    """
    # Firebase custom claim wins over the request body tenant_id
    effective_tenant = user.tenant_id if user.tenant_id != "default" else request.tenant_id

    logger.info(
        "chat_request",
        uid=user.uid,
        session_id=request.session_id,
        tenant_id=effective_tenant,
        agent=request.agent,
    )

    try:
        reply, agent_used, latency_ms = await _run_graph(
            message=request.message,
            session_id=request.session_id,
            tenant_id=effective_tenant,
            user_id=user.uid,
            agent=request.agent,
            memory=request.memory,
        )
    except Exception as exc:
        logger.exception("chat_error", uid=user.uid, error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Erro interno do agente. Tente novamente.",
        )

    logger.info("chat_response", uid=user.uid, agent_used=agent_used, latency_ms=latency_ms)

    asyncio.create_task(_persist_conversation(
        session_id=request.session_id,
        tenant_id=effective_tenant,
        user_id=user.uid,
        channel="chat",
        last_message=request.message,
        agent_used=agent_used,
    ))
    asyncio.create_task(_persist_agent_log(
        session_id=request.session_id,
        tenant_id=effective_tenant,
        agent=agent_used,
        latency_ms=latency_ms,
    ))
    asyncio.create_task(_update_daily_metrics(agent_used, latency_ms))

    return ChatResponse(
        session_id=request.session_id,
        tenant_id=effective_tenant,
        user_id=user.uid,
        agent_used=agent_used,
        reply=reply,
        routed_by_orchestrator=(request.agent == "auto"),
    )


# ── POST /webhook/whatsapp ────────────────────────────────────────────────────

def _verify_whatsapp_signature(raw_body: bytes, signature_header: str | None) -> bool:
    """
    Verify Meta's X-Hub-Signature-256 header.
    Returns True if the app secret is not configured (dev mode).
    """
    if not settings.whatsapp_app_secret:
        return True  # skip verification in dev
    if not signature_header or not signature_header.startswith("sha256="):
        return False
    expected = hmac.new(
        settings.whatsapp_app_secret.encode(),
        raw_body,
        hashlib.sha256,
    ).hexdigest()
    received = signature_header.removeprefix("sha256=")
    return hmac.compare_digest(expected, received)


async def _send_whatsapp_reply(phone_number_id: str, to: str, text: str) -> None:
    """Send a reply message via the WhatsApp Business API."""
    if not settings.whatsapp_api_token:
        logger.warning("whatsapp_api_token_not_set", to=to)
        return
    url = f"https://graph.facebook.com/v19.0/{phone_number_id}/messages"
    payload = {
        "messaging_product": "whatsapp",
        "to": to,
        "type": "text",
        "text": {"body": text},
    }
    async with httpx.AsyncClient(timeout=10) as client:
        try:
            resp = await client.post(
                url,
                json=payload,
                headers={"Authorization": f"Bearer {settings.whatsapp_api_token}"},
            )
            resp.raise_for_status()
            logger.info("whatsapp_reply_sent", to=to, status=resp.status_code)
        except Exception as exc:
            logger.error("whatsapp_reply_failed", to=to, error=str(exc))


@router.get("/webhook/whatsapp", tags=["webhook"])
async def whatsapp_verify(
    hub_mode: str = Query(alias="hub.mode", default=""),
    hub_verify_token: str = Query(alias="hub.verify_token", default=""),
    hub_challenge: str = Query(alias="hub.challenge", default=""),
):
    """
    Meta webhook verification handshake.
    Meta sends GET with hub.mode=subscribe and hub.verify_token;
    we echo back hub.challenge to confirm ownership.
    """
    if hub_mode == "subscribe" and hub_verify_token == settings.whatsapp_verify_token:
        logger.info("whatsapp_webhook_verified")
        return int(hub_challenge)
    logger.warning("whatsapp_webhook_verify_failed", token=hub_verify_token)
    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Verify token inválido.")


@router.post("/webhook/whatsapp", response_model=WAWebhookResponse, tags=["webhook"])
async def whatsapp_webhook(request: Request) -> WAWebhookResponse:
    """
    Receive incoming WhatsApp messages and inject them into the agent graph.

    - Verifies the X-Hub-Signature-256 HMAC signature (when WHATSAPP_APP_SECRET is set).
    - Processes only `text` messages; other types are acknowledged but skipped.
    - Returns 200 immediately — graph execution happens inline (use a task queue for scale).
    - Agent replies are sent back via the WhatsApp Business API.
    - tenant_id is derived from WHATSAPP_DEFAULT_TENANT env var.
    """
    raw_body = await request.body()
    signature = request.headers.get("X-Hub-Signature-256")

    if not _verify_whatsapp_signature(raw_body, signature):
        logger.warning("whatsapp_invalid_signature")
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Assinatura inválida.")

    try:
        payload = WAWebhookPayload.model_validate_json(raw_body)
    except Exception as exc:
        logger.warning("whatsapp_payload_parse_error", error=str(exc))
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(exc))

    processed = 0
    errors: list[str] = []

    for entry in payload.entry:
        for change in entry.changes:
            if change.field != "messages" or not change.value.messages:
                continue

            phone_number_id = change.value.metadata.phone_number_id
            tenant_id = settings.whatsapp_default_tenant

            for wa_msg in change.value.messages:
                if wa_msg.type != "text" or not wa_msg.text:
                    logger.info("whatsapp_non_text_skipped", type=wa_msg.type, from_=wa_msg.from_)
                    continue

                user_id = wa_msg.from_  # WhatsApp phone number as user identifier
                session_id = f"wa_{user_id}"  # persistent session per WhatsApp user
                message_text = wa_msg.text.body

                logger.info(
                    "whatsapp_message_received",
                    from_=user_id,
                    tenant_id=tenant_id,
                    session_id=session_id,
                    preview=message_text[:60],
                )

                try:
                    reply, agent_used, latency_ms = await _run_graph(
                        message=message_text,
                        session_id=session_id,
                        tenant_id=tenant_id,
                        user_id=user_id,
                        agent="auto",
                        memory={"channel": "whatsapp"},
                    )
                    await _send_whatsapp_reply(phone_number_id, user_id, reply)
                    logger.info("whatsapp_processed", from_=user_id, agent_used=agent_used, latency_ms=latency_ms)

                    asyncio.create_task(_persist_conversation(
                        session_id=session_id,
                        tenant_id=tenant_id,
                        user_id=user_id,
                        channel="whatsapp",
                        last_message=message_text,
                        agent_used=agent_used,
                    ))
                    asyncio.create_task(_persist_agent_log(
                        session_id=session_id,
                        tenant_id=tenant_id,
                        agent=agent_used,
                        latency_ms=latency_ms,
                    ))
                    asyncio.create_task(_update_daily_metrics(agent_used, latency_ms))
                    processed += 1
                except Exception as exc:
                    err = f"Erro ao processar mensagem de {user_id}: {exc}"
                    logger.exception("whatsapp_processing_error", from_=user_id, error=str(exc))
                    errors.append(err)

    return WAWebhookResponse(received=True, processed=processed, errors=errors)
