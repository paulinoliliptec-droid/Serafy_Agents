from langchain_core.messages import BaseMessage
from langchain_openai import ChatOpenAI
from langgraph.prebuilt import create_react_agent

from config import settings
from tools import search_knowledge_base, log_interaction

SYSTEM_PROMPT = """You are the Commercial Agent for agentOS-angola.

You handle all sales-related enquiries: pricing, proposals, product information,
partnership opportunities, and procurement for Angolan businesses.

Guidelines:
- Always search the knowledge base before quoting prices or availability.
- Present offers clearly, highlighting value relevant to the Angolan market (e.g. Kwanza pricing, local partnerships).
- Do not invent prices or features; if unsure, say so and offer to connect the customer with a sales representative.
- Log the interaction at the end of each session.
- Respond in the same language the customer uses (Portuguese or English).
"""


class CommercialAgent:
    def __init__(self) -> None:
        self.llm = ChatOpenAI(
            model=settings.commercial_model,
            api_key=settings.openai_api_key,
            temperature=0.4,
        )
        self.tools = [search_knowledge_base, log_interaction]
        self.graph = create_react_agent(
            model=self.llm,
            tools=self.tools,
            state_modifier=SYSTEM_PROMPT,
        )

    def invoke(self, messages: list[BaseMessage], session_id: str = "default") -> dict:
        return self.graph.invoke({"messages": messages})
