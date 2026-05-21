"""Tests for the orchestrator node and conditional router."""
import pytest
from unittest.mock import MagicMock, patch
from langchain_core.messages import HumanMessage, SystemMessage

from agents.orchestrator import RoutingDecision, orchestrate, route_to_agent


# ── route_to_agent ────────────────────────────────────────────────────────────

class TestRouteToAgent:
    @pytest.mark.parametrize("destination", [
        "suporte", "comercial", "juridico", "rh", "financeiro", "marketing",
    ])
    def test_known_destinations_route_correctly(self, destination):
        state = {"messages": [], "next_agent": destination, "tenant_id": "t1", "memory": {}}
        assert route_to_agent(state) == destination

    def test_end_routes_to_end(self):
        state = {"messages": [], "next_agent": "end", "tenant_id": "t1", "memory": {}}
        assert route_to_agent(state) == "end"

    def test_empty_next_agent_routes_to_end(self):
        state = {"messages": [], "next_agent": "", "tenant_id": "t1", "memory": {}}
        assert route_to_agent(state) == "end"

    def test_unknown_destination_routes_to_end(self):
        state = {"messages": [], "next_agent": "desconhecido", "tenant_id": "t1", "memory": {}}
        assert route_to_agent(state) == "end"

    def test_missing_next_agent_key_routes_to_end(self):
        state = {"messages": [], "tenant_id": "t1", "memory": {}}
        assert route_to_agent(state) == "end"


# ── orchestrate node ──────────────────────────────────────────────────────────

class TestOrchestrateNode:
    @patch("agents.orchestrator._get_llm")
    def test_sets_next_agent_from_llm_decision(self, mock_get_llm):
        mock_llm = MagicMock()
        mock_llm.invoke.return_value = RoutingDecision(
            destination="suporte", reason="problema técnico"
        )
        mock_get_llm.return_value = mock_llm

        state = {
            "messages": [HumanMessage(content="O meu serviço está offline")],
            "next_agent": "",
            "tenant_id": "t1",
            "memory": {},
        }
        result = orchestrate(state)
        assert result["next_agent"] == "suporte"

    @patch("agents.orchestrator._get_llm")
    def test_passes_messages_to_llm(self, mock_get_llm):
        mock_llm = MagicMock()
        mock_llm.invoke.return_value = RoutingDecision(destination="comercial", reason="vendas")
        mock_get_llm.return_value = mock_llm

        state = {
            "messages": [HumanMessage(content="Quero comprar")],
            "next_agent": "",
            "tenant_id": "t1",
            "memory": {},
        }
        orchestrate(state)

        call_args = mock_llm.invoke.call_args[0][0]
        # First message is the system prompt, second is the user message
        assert any(isinstance(m, HumanMessage) for m in call_args)

    @patch("agents.orchestrator._get_llm")
    def test_injects_memory_summary_into_system_prompt(self, mock_get_llm):
        mock_llm = MagicMock()
        mock_llm.invoke.return_value = RoutingDecision(destination="rh", reason="rh")
        mock_get_llm.return_value = mock_llm

        state = {
            "messages": [HumanMessage(content="Férias")],
            "next_agent": "",
            "tenant_id": "t1",
            "memory": {"summary": "Colaborador da empresa XYZ"},
        }
        orchestrate(state)

        system_msg = mock_llm.invoke.call_args[0][0][0]
        assert isinstance(system_msg, SystemMessage)
        assert "Colaborador da empresa XYZ" in system_msg.content

    @patch("agents.orchestrator._get_llm")
    def test_no_memory_summary_no_context_injected(self, mock_get_llm):
        mock_llm = MagicMock()
        mock_llm.invoke.return_value = RoutingDecision(destination="end", reason="done")
        mock_get_llm.return_value = mock_llm

        state = {
            "messages": [HumanMessage(content="Obrigado")],
            "next_agent": "",
            "tenant_id": "t1",
            "memory": {},
        }
        orchestrate(state)

        system_msg = mock_llm.invoke.call_args[0][0][0]
        assert "Contexto acumulado" not in system_msg.content

    @pytest.mark.parametrize("destination", [
        "suporte", "comercial", "juridico", "rh", "financeiro", "marketing", "end",
    ])
    @patch("agents.orchestrator._get_llm")
    def test_all_valid_destinations_propagated(self, mock_get_llm, destination):
        mock_llm = MagicMock()
        mock_llm.invoke.return_value = RoutingDecision(destination=destination, reason="test")
        mock_get_llm.return_value = mock_llm

        state = {
            "messages": [HumanMessage(content="msg")],
            "next_agent": "",
            "tenant_id": "t1",
            "memory": {},
        }
        result = orchestrate(state)
        assert result["next_agent"] == destination
