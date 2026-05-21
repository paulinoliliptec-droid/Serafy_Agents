from __future__ import annotations

from typing import Any, Literal, Optional
import uuid

from pydantic import BaseModel, Field

AGENT_NAMES = Literal["auto", "suporte", "comercial", "juridico", "rh", "financeiro", "marketing"]


# ── /chat ─────────────────────────────────────────────────────────────────────

class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4096, description="Mensagem do utilizador")
    session_id: str = Field(
        default_factory=lambda: str(uuid.uuid4()),
        description="Identificador da sessão — mantém histórico via checkpointer",
    )
    tenant_id: str = Field(
        default="default",
        description="Namespace do tenant (sobreposto pelo custom claim do Firebase JWT quando disponível)",
    )
    agent: AGENT_NAMES = Field(
        default="auto",
        description="Agente alvo. 'auto' deixa o orquestrador decidir.",
    )
    memory: Optional[dict] = Field(
        default=None,
        description="Contexto de memória extra a injectar nesta sessão",
    )


class ChatResponse(BaseModel):
    session_id: str
    tenant_id: str
    user_id: str
    agent_used: str
    reply: str
    routed_by_orchestrator: bool


# ── /health ───────────────────────────────────────────────────────────────────

class HealthResponse(BaseModel):
    status: Literal["ok", "degraded"] = "ok"
    version: str = "0.3.0"
    environment: str
    checkpointer: str


# ── /webhook/whatsapp — Meta WhatsApp Business API v18 ───────────────────────

class WAProfile(BaseModel):
    name: str


class WAContact(BaseModel):
    profile: WAProfile
    wa_id: str


class WATextBody(BaseModel):
    body: str


class WAMessage(BaseModel):
    id: str
    from_: str = Field(..., alias="from")
    timestamp: str
    type: str
    text: Optional[WATextBody] = None
    # stubs for other types — extend as needed
    audio: Optional[dict] = None
    image: Optional[dict] = None
    document: Optional[dict] = None
    interactive: Optional[dict] = None

    model_config = {"populate_by_name": True}


class WAMetadata(BaseModel):
    display_phone_number: str
    phone_number_id: str


class WAValue(BaseModel):
    messaging_product: str
    metadata: WAMetadata
    contacts: Optional[list[WAContact]] = None
    messages: Optional[list[WAMessage]] = None
    statuses: Optional[list[dict]] = None


class WAChange(BaseModel):
    value: WAValue
    field: str


class WAEntry(BaseModel):
    id: str
    changes: list[WAChange]


class WAWebhookPayload(BaseModel):
    object: str
    entry: list[WAEntry]


class WAWebhookResponse(BaseModel):
    received: bool = True
    processed: int = 0
    errors: list[str] = []
