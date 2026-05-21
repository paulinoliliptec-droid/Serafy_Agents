from pydantic import BaseModel, Field
from typing import Literal, Optional
import uuid

AGENT_NAMES = Literal["auto", "suporte", "comercial", "juridico", "rh", "financeiro", "marketing"]


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4096, description="Mensagem do utilizador")
    session_id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        description="Identificador único da sessão (persistido via checkpointer)",
    )
    tenant_id: str = Field(
        default="default",
        description="Identificador do tenant — isola dados e checkpoints por organização",
    )
    agent: AGENT_NAMES = Field(
        default="auto",
        description="Agente alvo. 'auto' deixa o orquestrador decidir.",
    )
    memory: Optional[dict] = Field(
        default=None,
        description="Contexto de memória opcional a injectar nesta sessão",
    )


class ChatResponse(BaseModel):
    session_id: str
    tenant_id: str
    agent_used: str
    reply: str
    routed_by_orchestrator: bool


class HealthResponse(BaseModel):
    status: Literal["ok", "degraded"] = "ok"
    version: str = "0.2.0"
    environment: str
    checkpointer: str
