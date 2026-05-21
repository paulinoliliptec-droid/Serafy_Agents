from langchain_core.messages import SystemMessage
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

from agents.state import AgentState
from config import settings
from tools import search_knowledge_base, escalate_to_human, log_interaction

BASE_PROMPT = """És o Agente de Recursos Humanos do agentOS-angola.

Apoias colaboradores e gestores em questões de RH no contexto angolano:
contratação, admissão, folha de pagamento, férias, subsídios, rescisões
e conformidade com o Código Geral do Trabalho de Angola.

Directrizes:
- Pesquisa a base de conhecimento antes de responder.
- Para questões salariais ou disciplinares sensíveis, usa escalate_to_human.
- Refere sempre a legislação angolana aplicável (Lei nº 7/15 – Código Geral do Trabalho).
- Respeita a confidencialidade dos dados dos colaboradores.
- Regista a interacção com log_interaction.
- Responde no idioma do cliente (Português ou Inglês).
"""

_graph = None


def _get_graph():
    global _graph
    if _graph is None:
        llm = ChatOpenAI(
            model=settings.hr_model,
            api_key=settings.openai_api_key,
            temperature=0.2,
        )
        _graph = create_react_agent(
            model=llm,
            tools=[search_knowledge_base, escalate_to_human, log_interaction],
        )
    return _graph


def hr_node(state: AgentState) -> dict:
    memory = state.get("memory", {})
    system_content = BASE_PROMPT
    if memory.get("summary"):
        system_content += f"\n\nContexto anterior: {memory['summary']}"

    messages_in = [SystemMessage(content=system_content)] + list(state["messages"])
    result = _get_graph().invoke({"messages": messages_in})

    new_messages = result["messages"][len(messages_in):]
    return {"messages": new_messages}
