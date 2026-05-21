from typing import Annotated, Literal
from langchain_core.messages import BaseMessage, HumanMessage, AIMessage
from langchain_openai import ChatOpenAI
from langgraph.graph import StateGraph, END
from langgraph.graph.message import add_messages
from pydantic import BaseModel
from typing_extensions import TypedDict

from config import settings
from tools import search_knowledge_base, escalate_to_human, log_interaction


class AgentState(TypedDict):
    messages: Annotated[list[BaseMessage], add_messages]
    next_agent: str
    session_id: str


class RoutingDecision(BaseModel):
    destination: Literal["support", "commercial", "legal", "end"]
    reason: str


SYSTEM_PROMPT = """You are the Orchestrator for agentOS-angola — an AI platform serving Angolan businesses.

Your sole responsibility is to analyse the user's intent and route the conversation to the
most appropriate specialist agent:

• **support**    — Technical issues, complaints, account problems, after-sales assistance.
• **commercial** — Pricing, proposals, product information, sales, partnerships.
• **legal**      — Contracts, compliance, regulatory questions, legal advice.
• **end**        — The conversation is complete and no further routing is needed.

Respond ONLY with a JSON object matching the RoutingDecision schema.
Do not add any extra text outside of JSON.
"""


class OrchestratorAgent:
    def __init__(self) -> None:
        self.llm = ChatOpenAI(
            model=settings.orchestrator_model,
            api_key=settings.openai_api_key,
            temperature=0,
        ).with_structured_output(RoutingDecision)

        self.tools = [search_knowledge_base, escalate_to_human, log_interaction]
        self.graph = self._build_graph()

    def _route(self, state: AgentState) -> RoutingDecision:
        messages = [{"role": "system", "content": SYSTEM_PROMPT}] + [
            {"role": "user" if isinstance(m, HumanMessage) else "assistant", "content": m.content}
            for m in state["messages"]
        ]
        return self.llm.invoke(messages)

    def _build_graph(self) -> StateGraph:
        graph = StateGraph(AgentState)

        def orchestrate(state: AgentState) -> dict:
            decision = self._route(state)
            return {
                "next_agent": decision.destination,
                "messages": [AIMessage(content=f"[Orchestrator] Routing to: {decision.destination}. Reason: {decision.reason}")],
            }

        def should_continue(state: AgentState) -> str:
            return state.get("next_agent", "end")

        graph.add_node("orchestrate", orchestrate)
        graph.set_entry_point("orchestrate")
        graph.add_conditional_edges(
            "orchestrate",
            should_continue,
            {
                "support": END,
                "commercial": END,
                "legal": END,
                "end": END,
            },
        )
        return graph.compile()

    def invoke(self, user_message: str, session_id: str = "default") -> AgentState:
        return self.graph.invoke(
            {
                "messages": [HumanMessage(content=user_message)],
                "next_agent": "",
                "session_id": session_id,
            }
        )
