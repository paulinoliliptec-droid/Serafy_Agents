from langchain_core.messages import SystemMessage
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

from agents.state import AgentState
from config import settings
from tools import search_knowledge_base, escalate_to_human, log_interaction

BASE_PROMPT = """És o Agente de Suporte do agentOS-angola.

A tua missão é resolver problemas técnicos, reclamações e questões pós-venda
para clientes angolanos com empatia, clareza e eficiência.

Directrizes:
- Cumprimenta o cliente e reconhece o problema apresentado.
- Usa search_knowledge_base antes de responder.
- Se não conseguires resolver, usa escalate_to_human com uma razão clara.
- Regista a interacção no final com log_interaction.
- Responde no idioma do cliente (Português ou Inglês).
- Sê conciso: máximo 3 parágrafos curtos por resposta.
"""

_graph = None


def _get_graph():
    global _graph
    if _graph is None:
        llm = ChatOpenAI(
            model=settings.support_model,
            api_key=settings.openai_api_key,
            temperature=0.3,
        )
        _graph = create_react_agent(
            model=llm,
            tools=[search_knowledge_base, escalate_to_human, log_interaction],
        )
    return _graph


def support_node(state: AgentState) -> dict:
    memory = state.get("memory", {})
    system_content = BASE_PROMPT
    if memory.get("summary"):
        system_content += f"\n\nContexto de sessões anteriores: {memory['summary']}"

    messages_in = [SystemMessage(content=system_content)] + list(state["messages"])
    result = _get_graph().invoke({"messages": messages_in})

    new_messages = result["messages"][len(messages_in):]
    return {"messages": new_messages}
