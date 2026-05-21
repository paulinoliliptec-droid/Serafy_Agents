from fastapi import APIRouter, HTTPException
from langchain_core.messages import HumanMessage
from langgraph.checkpoint.memory import MemorySaver
import structlog

from .schemas import ChatRequest, ChatResponse, HealthResponse
from agents import AgentState, build_graph
from config import settings

logger = structlog.get_logger(__name__)
router = APIRouter()

# ── Checkpointer factory ──────────────────────────────────────────────────────

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
            logger.warning("google-cloud-firestore not installed, falling back to MemorySaver")
    return MemorySaver()


_checkpointer = _build_checkpointer()
_graph = build_graph(checkpointer=_checkpointer)

# Direct-routing agent map (when agent != "auto")
_DIRECT_TARGETS = {"suporte", "comercial", "juridico", "rh", "financeiro", "marketing"}

# ── Routes ────────────────────────────────────────────────────────────────────

@router.get("/health", response_model=HealthResponse, tags=["infra"])
async def health_check() -> HealthResponse:
    return HealthResponse(
        environment=settings.app_env,
        checkpointer=type(_checkpointer).__name__,
    )


@router.post("/chat", response_model=ChatResponse, tags=["agents"])
async def chat(request: ChatRequest) -> ChatResponse:
    logger.info(
        "chat_request",
        session_id=request.session_id,
        tenant_id=request.tenant_id,
        agent=request.agent,
    )

    initial_state: AgentState = {
        "messages": [HumanMessage(content=request.message)],
        "next_agent": request.agent if request.agent != "auto" else "",
        "tenant_id": request.tenant_id,
        "memory": request.memory or {},
    }

    # Thread config — namespaces checkpoints by tenant + session
    invoke_config = {
        "configurable": {
            "thread_id": request.session_id,
            "tenant_id": request.tenant_id,
        }
    }

    try:
        result: AgentState = await _graph.ainvoke(initial_state, config=invoke_config)

        agent_used = result.get("next_agent") or request.agent
        if not agent_used or agent_used == "end":
            agent_used = "orquestrador"

        last_msg = result["messages"][-1]
        reply = last_msg.content if hasattr(last_msg, "content") else str(last_msg)

        logger.info(
            "chat_response",
            session_id=request.session_id,
            tenant_id=request.tenant_id,
            agent_used=agent_used,
        )
        return ChatResponse(
            session_id=request.session_id,
            tenant_id=request.tenant_id,
            agent_used=agent_used,
            reply=reply,
            routed_by_orchestrator=(request.agent == "auto"),
        )

    except Exception as exc:
        logger.exception(
            "chat_error",
            session_id=request.session_id,
            tenant_id=request.tenant_id,
            error=str(exc),
        )
        raise HTTPException(status_code=500, detail="Erro interno do agente. Tente novamente.")
