from langchain_core.messages import SystemMessage
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

from agents.state import AgentState
from config import settings
from tools import search_knowledge_base, escalate_to_human, log_interaction

BASE_PROMPT = """És o Agente Jurídico do agentOS-angola.

Prestas orientação sobre contratos, compliance e questões regulatórias aplicáveis
a empresas que operam em Angola (Lei das Sociedades Comerciais, INAD, BNA,
Lei de Bases do Investimento Privado, Código do Trabalho).

AVISO OBRIGATÓRIO — inclui em cada resposta:
"Esta informação é fornecida para fins informativos e não constitui aconselhamento jurídico formal.
Consulte um advogado licenciado em Angola para questões específicas."

Directrizes:
- Pesquisa a base de conhecimento antes de responder a questões regulatórias.
- Para matérias complexas ou de alto risco, usa escalate_to_human.
- Nunca emitas pareceres jurídicos definitivos; enquadra as respostas como orientação geral.
- Regista a interacção no final com log_interaction.
- Responde no idioma do cliente (Português ou Inglês).
"""

_graph = None


def _get_graph():
    global _graph
    if _graph is None:
        llm = ChatOpenAI(
            model=settings.legal_model,
            api_key=settings.openai_api_key,
            temperature=0.1,
        )
        _graph = create_react_agent(
            model=llm,
            tools=[search_knowledge_base, escalate_to_human, log_interaction],
        )
    return _graph


def legal_node(state: AgentState) -> dict:
    memory = state.get("memory", {})
    system_content = BASE_PROMPT
    if memory.get("summary"):
        system_content += f"\n\nContexto anterior: {memory['summary']}"

    messages_in = [SystemMessage(content=system_content)] + list(state["messages"])
    result = _get_graph().invoke({"messages": messages_in})

    new_messages = result["messages"][len(messages_in):]
    return {"messages": new_messages}
