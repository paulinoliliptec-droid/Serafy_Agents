from fastapi import APIRouter, HTTPException
from langchain_core.messages import HumanMessage
import structlog

from .schemas import ChatRequest, ChatResponse, HealthResponse
from agents import OrchestratorAgent, SupportAgent, CommercialAgent, LegalAgent
from config import settings

logger = structlog.get_logger(__name__)
router = APIRouter()

# Agent singletons — initialised once at startup
_orchestrator = OrchestratorAgent()
_agents: dict = {
    "support": SupportAgent(),
    "commercial": CommercialAgent(),
    "legal": LegalAgent(),
}


@router.get("/health", response_model=HealthResponse, tags=["infra"])
async def health_check() -> HealthResponse:
    return HealthResponse(environment=settings.app_env)


@router.post("/chat", response_model=ChatResponse, tags=["agents"])
async def chat(request: ChatRequest) -> ChatResponse:
    logger.info("chat_request", session_id=request.session_id, agent=request.agent)

    try:
        if request.agent == "auto":
            orch_result = _orchestrator.invoke(request.message, session_id=request.session_id)
            target_agent = orch_result.get("next_agent", "support")
            routed = True
        else:
            target_agent = request.agent
            routed = False

        if target_agent not in _agents:
            target_agent = "support"

        specialist = _agents[target_agent]
        result = specialist.invoke(
            messages=[HumanMessage(content=request.message)],
            session_id=request.session_id,
        )

        last_message = result["messages"][-1]
        reply = last_message.content if hasattr(last_message, "content") else str(last_message)

        logger.info("chat_response", session_id=request.session_id, agent_used=target_agent)
        return ChatResponse(
            session_id=request.session_id,
            agent_used=target_agent,
            reply=reply,
            routed_by_orchestrator=routed,
        )

    except Exception as exc:
        logger.exception("chat_error", session_id=request.session_id, error=str(exc))
        raise HTTPException(status_code=500, detail="Internal agent error. Please try again.")
