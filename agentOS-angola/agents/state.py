from typing import Annotated
from langchain_core.messages import BaseMessage
from langgraph.graph.message import add_messages
from typing_extensions import TypedDict


def _merge_memory(existing: dict, incoming: dict) -> dict:
    """Merge incoming memory updates into existing memory without overwriting unchanged keys."""
    return {**existing, **incoming}


class AgentState(TypedDict):
    messages: Annotated[list[BaseMessage], add_messages]
    next_agent: str          # routing target set by orchestrator
    tenant_id: str           # multi-tenant namespace
    memory: Annotated[dict, _merge_memory]  # persistent cross-session context
