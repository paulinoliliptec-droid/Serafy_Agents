"""Tests for all specialist agent nodes."""
import pytest
from unittest.mock import MagicMock, patch
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage


# ── Parametrised across all six specialist nodes ──────────────────────────────

SPECIALIST_NODES = [
    ("agents.support",     "support_node"),
    ("agents.commercial",  "commercial_node"),
    ("agents.legal",       "legal_node"),
    ("agents.hr",          "hr_node"),
    ("agents.financial",   "financial_node"),
    ("agents.marketing",   "marketing_node"),
]


def _import_node(module_path: str, fn_name: str):
    import importlib
    return getattr(importlib.import_module(module_path), fn_name)


def _make_mock_graph(extra_ai_reply: str = "Posso ajudar!"):
    """Return a mock internal ReAct graph that appends one AI message."""
    mock_graph = MagicMock()

    def _invoke(input_dict):
        msgs = list(input_dict["messages"])
        return {"messages": msgs + [AIMessage(content=extra_ai_reply)]}

    mock_graph.invoke.side_effect = _invoke
    return mock_graph


class TestSpecialistNodesBehaviour:
    @pytest.mark.parametrize("module_path,node_name", SPECIALIST_NODES)
    def test_returns_only_new_messages(self, module_path, node_name):
        node_fn = _import_node(module_path, node_name)
        mock_graph = _make_mock_graph("Resposta do agente")

        with patch(f"{module_path}._get_graph", return_value=mock_graph):
            state = {
                "messages": [HumanMessage(content="mensagem")],
                "next_agent": "",
                "tenant_id": "t1",
                "memory": {},
            }
            result = node_fn(state)

        assert "messages" in result
        # Only the new AI message — not the system message or user message
        assert len(result["messages"]) == 1
        assert result["messages"][0].content == "Resposta do agente"

    @pytest.mark.parametrize("module_path,node_name", SPECIALIST_NODES)
    def test_prepends_system_message_to_graph_call(self, module_path, node_name):
        node_fn = _import_node(module_path, node_name)
        mock_graph = _make_mock_graph()
        captured = {}

        def _invoke(input_dict):
            captured["messages"] = input_dict["messages"]
            return {"messages": list(input_dict["messages"]) + [AIMessage(content="ok")]}

        mock_graph.invoke.side_effect = _invoke

        with patch(f"{module_path}._get_graph", return_value=mock_graph):
            node_fn({
                "messages": [HumanMessage(content="msg")],
                "next_agent": "",
                "tenant_id": "t1",
                "memory": {},
            })

        assert isinstance(captured["messages"][0], SystemMessage)

    @pytest.mark.parametrize("module_path,node_name", SPECIALIST_NODES)
    def test_memory_summary_injected_into_system_prompt(self, module_path, node_name):
        node_fn = _import_node(module_path, node_name)
        mock_graph = _make_mock_graph()
        captured = {}

        def _invoke(input_dict):
            captured["messages"] = input_dict["messages"]
            return {"messages": list(input_dict["messages"]) + [AIMessage(content="ok")]}

        mock_graph.invoke.side_effect = _invoke

        with patch(f"{module_path}._get_graph", return_value=mock_graph):
            node_fn({
                "messages": [HumanMessage(content="msg")],
                "next_agent": "",
                "tenant_id": "t1",
                "memory": {"summary": "Cliente VIP desde 2020"},
            })

        system_content = captured["messages"][0].content
        assert "Cliente VIP desde 2020" in system_content

    @pytest.mark.parametrize("module_path,node_name", SPECIALIST_NODES)
    def test_no_memory_summary_prompt_unchanged(self, module_path, node_name):
        node_fn = _import_node(module_path, node_name)
        mock_graph = _make_mock_graph()
        captured_with = {}
        captured_without = {}

        def _invoke_with(input_dict):
            captured_with["content"] = input_dict["messages"][0].content
            return {"messages": list(input_dict["messages"]) + [AIMessage(content="ok")]}

        def _invoke_without(input_dict):
            captured_without["content"] = input_dict["messages"][0].content
            return {"messages": list(input_dict["messages"]) + [AIMessage(content="ok")]}

        base_state = {
            "messages": [HumanMessage(content="msg")],
            "next_agent": "",
            "tenant_id": "t1",
        }

        mock_graph.invoke.side_effect = _invoke_without
        with patch(f"{module_path}._get_graph", return_value=mock_graph):
            node_fn({**base_state, "memory": {}})

        mock_graph.invoke.side_effect = _invoke_with
        with patch(f"{module_path}._get_graph", return_value=mock_graph):
            node_fn({**base_state, "memory": {"summary": "Contexto extra"}})

        assert "Contexto extra" not in captured_without["content"]
        assert "Contexto extra" in captured_with["content"]

    @pytest.mark.parametrize("module_path,node_name", SPECIALIST_NODES)
    def test_graph_called_exactly_once_per_invocation(self, module_path, node_name):
        node_fn = _import_node(module_path, node_name)
        mock_graph = _make_mock_graph()

        with patch(f"{module_path}._get_graph", return_value=mock_graph):
            node_fn({
                "messages": [HumanMessage(content="msg")],
                "next_agent": "",
                "tenant_id": "t1",
                "memory": {},
            })

        mock_graph.invoke.assert_called_once()


class TestLegalNodeDisclaimer:
    """Legal agent must include the mandatory disclaimer in its BASE_PROMPT."""

    def test_legal_base_prompt_contains_disclaimer(self):
        from agents.legal import BASE_PROMPT
        assert "aconselhamento jurídico formal" in BASE_PROMPT
        assert "advogado licenciado" in BASE_PROMPT


class TestFinancialNodeAngola:
    """Financial agent must reference Angolan tax authority."""

    def test_financial_base_prompt_references_agt(self):
        from agents.financial import BASE_PROMPT
        assert "AGT" in BASE_PROMPT or "Kwanza" in BASE_PROMPT
