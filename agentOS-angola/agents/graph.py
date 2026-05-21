from langgraph.graph import StateGraph, END
from langgraph.checkpoint.base import BaseCheckpointSaver

from agents.state import AgentState
from agents.orchestrator import orchestrate, route_to_agent
from agents.support import support_node
from agents.commercial import commercial_node
from agents.legal import legal_node
from agents.hr import hr_node
from agents.financial import financial_node
from agents.marketing import marketing_node

SPECIALIST_NODES = {
    "suporte": support_node,
    "comercial": commercial_node,
    "juridico": legal_node,
    "rh": hr_node,
    "financeiro": financial_node,
    "marketing": marketing_node,
}

ROUTING_TARGETS = {
    **{name: name for name in SPECIALIST_NODES},
    "end": END,
}


def build_graph(checkpointer: BaseCheckpointSaver | None = None):
    """
    Build and compile the full multi-agent StateGraph.

    Graph topology:
        START → orchestrator → [conditional router] → specialist node → END
                                                     └──────────────────► END (direct)

    Args:
        checkpointer: Optional checkpoint saver for state persistence.
                      Pass a FirestoreCheckpointer for production,
                      or MemorySaver for local testing.

    Returns:
        CompiledGraph ready to invoke with AgentState.
    """
    graph = StateGraph(AgentState)

    # ── Nodes ─────────────────────────────────────────────────────────────────
    graph.add_node("orchestrator", orchestrate)
    for name, fn in SPECIALIST_NODES.items():
        graph.add_node(name, fn)

    # ── Entry point ───────────────────────────────────────────────────────────
    graph.set_entry_point("orchestrator")

    # ── Conditional router: orchestrator → specialist or END ──────────────────
    graph.add_conditional_edges(
        "orchestrator",
        route_to_agent,
        ROUTING_TARGETS,
    )

    # ── Each specialist always terminates the turn ─────────────────────────────
    for name in SPECIALIST_NODES:
        graph.add_edge(name, END)

    return graph.compile(checkpointer=checkpointer)
