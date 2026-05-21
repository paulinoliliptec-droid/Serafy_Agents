from typing import Literal
from langchain_core.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI
from pydantic import BaseModel

from agents.state import AgentState
from config import settings

DESTINATIONS = Literal["suporte", "comercial", "juridico", "rh", "financeiro", "marketing", "end"]

ROUTING_MAP = {
    "suporte": "suporte",
    "comercial": "comercial",
    "juridico": "juridico",
    "rh": "rh",
    "financeiro": "financeiro",
    "marketing": "marketing",
    "end": "end",
}

SYSTEM_PROMPT = """És o Orquestrador do agentOS-angola — plataforma de IA para empresas angolanas.

A tua única responsabilidade é analisar a intenção do utilizador e encaminhar para o agente
especialista mais adequado:

• suporte    — Problemas técnicos, reclamações, conta, assistência pós-venda, devoluções.
• comercial  — Vendas, propostas, preços, produtos, parcerias, procurement.
• juridico   — Contratos, compliance, regulação (BNA, INAD, FIARA), questões legais.
• rh         — Recursos humanos, contratação, folha de pagamento, férias, colaboradores.
• financeiro — Facturas, pagamentos, tesouraria, contabilidade, impostos, relatórios.
• marketing  — Campanhas, comunicação, marca, publicidade, conteúdo digital.
• end        — Conversa concluída, não requer mais encaminhamento.

Responde APENAS com um objecto JSON conforme o schema RoutingDecision.
Não incluas texto fora do JSON.
"""


class RoutingDecision(BaseModel):
    destination: DESTINATIONS
    reason: str


def _build_llm() -> ChatOpenAI:
    return ChatOpenAI(
        model=settings.orchestrator_model,
        api_key=settings.openai_api_key,
        temperature=0,
    ).with_structured_output(RoutingDecision)


_llm: ChatOpenAI | None = None


def _get_llm():
    global _llm
    if _llm is None:
        _llm = _build_llm()
    return _llm


def orchestrate(state: AgentState) -> dict:
    """Orchestrator node: classifies user intent and sets next_agent."""
    llm = _get_llm()

    memory = state.get("memory", {})
    system_content = SYSTEM_PROMPT
    if memory.get("summary"):
        system_content += f"\n\nContexto acumulado do tenant: {memory['summary']}"

    messages_for_llm = [SystemMessage(content=system_content)] + list(state["messages"])
    decision: RoutingDecision = llm.invoke(messages_for_llm)

    return {
        "next_agent": decision.destination,
    }


def route_to_agent(state: AgentState) -> str:
    """Conditional edge function: returns the node name to go to next."""
    return ROUTING_MAP.get(state.get("next_agent", "end"), "end")
