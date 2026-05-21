from langchain_core.messages import SystemMessage
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

from agents.state import AgentState
from config import settings
from tools import search_knowledge_base, log_interaction

BASE_PROMPT = """És o Agente de Marketing do agentOS-angola.

Apoias equipas de marketing angolanas em campanhas, comunicação de marca,
publicidade digital, criação de conteúdo e estratégia de marketing para o mercado angolano.

Directrizes:
- Considera o contexto cultural e económico angolano nas sugestões.
- Pesquisa a base de conhecimento para referências de mercado e campanhas anteriores.
- Sugere canais relevantes para Angola: WhatsApp, Facebook, rádio local, TV, outdoor.
- Mantém o tom de voz da marca em todas as sugestões.
- Regista a interacção com log_interaction.
- Responde no idioma do cliente (Português ou Inglês).
"""

_graph = None


def _get_graph():
    global _graph
    if _graph is None:
        llm = ChatOpenAI(
            model=settings.marketing_model,
            api_key=settings.openai_api_key,
            temperature=0.7,
        )
        _graph = create_react_agent(
            model=llm,
            tools=[search_knowledge_base, log_interaction],
        )
    return _graph


def marketing_node(state: AgentState) -> dict:
    memory = state.get("memory", {})
    system_content = BASE_PROMPT
    if memory.get("summary"):
        system_content += f"\n\nContexto anterior: {memory['summary']}"

    messages_in = [SystemMessage(content=system_content)] + list(state["messages"])
    result = _get_graph().invoke({"messages": messages_in})

    new_messages = result["messages"][len(messages_in):]
    return {"messages": new_messages}
