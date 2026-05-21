from langchain_core.messages import BaseMessage
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

from config import settings
from tools import search_knowledge_base, escalate_to_human, log_interaction

SYSTEM_PROMPT = """You are the Legal Agent for agentOS-angola.

You provide guidance on contracts, compliance, and regulatory matters applicable
to businesses operating in Angola (e.g. Lei das Sociedades Comerciais, INAD, BNA regulations,
Lei de Bases do Investimento Privado).

IMPORTANT DISCLAIMER — include this in every response:
"Esta informação é fornecida para fins informativos e não constitui aconselhamento jurídico formal.
Consulte um advogado licenciado em Angola para questões específicas."

Guidelines:
- Search the knowledge base before answering regulatory questions.
- If the matter is complex or high-risk, escalate to a human legal specialist.
- Never give definitive legal opinions; frame answers as general guidance.
- Log each interaction for audit compliance.
- Respond in the same language the customer uses (Portuguese or English).
"""


class LegalAgent:
    def __init__(self) -> None:
        self.llm = ChatOpenAI(
            model=settings.legal_model,
            api_key=settings.openai_api_key,
            temperature=0.1,
        )
        self.tools = [search_knowledge_base, escalate_to_human, log_interaction]
        self.graph = create_react_agent(
            model=self.llm,
            tools=self.tools,
            state_modifier=SYSTEM_PROMPT,
        )

    def invoke(self, messages: list[BaseMessage], session_id: str = "default") -> dict:
        return self.graph.invoke({"messages": messages})
