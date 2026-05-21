from langchain_core.messages import BaseMessage, HumanMessage, AIMessage, SystemMessage
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

from config import settings
from tools import search_knowledge_base, escalate_to_human, log_interaction

SYSTEM_PROMPT = """You are the Support Agent for agentOS-angola.

Your mission is to resolve technical issues, complaints, and after-sales enquiries
for Angolan customers with empathy, clarity, and efficiency.

Guidelines:
- Greet the customer warmly and acknowledge their issue.
- Use the search_knowledge_base tool to find relevant solutions before answering.
- If you cannot resolve the issue, use escalate_to_human with a clear reason.
- Always log the interaction at the end using log_interaction.
- Respond in the same language the customer uses (Portuguese or English).
- Be concise: no more than 3 short paragraphs per response.
"""


class SupportAgent:
    def __init__(self) -> None:
        self.llm = ChatOpenAI(
            model=settings.support_model,
            api_key=settings.openai_api_key,
            temperature=0.3,
        )
        self.tools = [search_knowledge_base, escalate_to_human, log_interaction]
        self.graph = create_react_agent(
            model=self.llm,
            tools=self.tools,
            state_modifier=SYSTEM_PROMPT,
        )

    def invoke(self, messages: list[BaseMessage], session_id: str = "default") -> dict:
        return self.graph.invoke({"messages": messages})
