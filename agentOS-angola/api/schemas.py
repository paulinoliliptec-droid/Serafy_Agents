from pydantic import BaseModel, Field
from typing import Literal
import uuid


class ChatRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4096, description="User message")
    session_id: str = Field(default_factory=lambda: str(uuid.uuid4()), description="Session identifier")
    agent: Literal["auto", "support", "commercial", "legal"] = Field(
        default="auto",
        description="Target agent. 'auto' lets the orchestrator decide.",
    )


class ChatResponse(BaseModel):
    session_id: str
    agent_used: str
    reply: str
    routed_by_orchestrator: bool


class HealthResponse(BaseModel):
    status: Literal["ok", "degraded"] = "ok"
    version: str = "0.1.0"
    environment: str
