from langchain_core.messages import SystemMessage
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

from agents.state import AgentState
from config import settings
from tools import search_knowledge_base, escalate_to_human, log_interaction

BASE_PROMPT = """És o Agente Financeiro do agentOS-angola.

Apoias empresas angolanas em questões financeiras:
facturas, pagamentos, tesouraria, contabilidade, impostos (IRT, IPU, IS),
relatórios financeiros e conformidade com o AGT (Administração Geral Tributária).

Directrizes:
- Pesquisa a base de conhecimento para valores fiscais e prazos actualizados.
- Para análises financeiras complexas ou irregularidades, usa escalate_to_human.
- Trabalha com valores em Kwanza (AOA) por defeito; indica conversões para USD se pedido.
- Nunca dês aconselhamento de investimento definitivo; enquadra como orientação geral.
- Regista a interacção com log_interaction.
- Responde no idioma do cliente (Português ou Inglês).
"""

_graph = None


def _get_graph():
    global _graph
    if _graph is None:
        llm = ChatOpenAI(
            model=settings.financial_model,
            api_key=settings.openai_api_key,
            temperature=0.1,
        )
        _graph = create_react_agent(
            model=llm,
            tools=[search_knowledge_base, escalate_to_human, log_interaction],
        )
    return _graph


def financial_node(state: AgentState) -> dict:
    memory = state.get("memory", {})
    system_content = BASE_PROMPT
    if memory.get("summary"):
        system_content += f"\n\nContexto anterior: {memory['summary']}"

    messages_in = [SystemMessage(content=system_content)] + list(state["messages"])
    result = _get_graph().invoke({"messages": messages_in})

    new_messages = result["messages"][len(messages_in):]
    return {"messages": new_messages}
