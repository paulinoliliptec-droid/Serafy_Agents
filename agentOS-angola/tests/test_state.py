"""Tests for AgentState definition and memory reducer."""
import pytest
from langchain_core.messages import AIMessage, HumanMessage
from langgraph.graph.message import add_messages

from agents.state import AgentState, _merge_memory


class TestMergeMemory:
    def test_merges_new_keys_into_existing(self):
        result = _merge_memory({"user": "João"}, {"language": "pt"})
        assert result == {"user": "João", "language": "pt"}

    def test_incoming_overwrites_existing_key(self):
        result = _merge_memory({"summary": "old summary"}, {"summary": "new summary"})
        assert result["summary"] == "new summary"

    def test_existing_keys_not_in_incoming_are_preserved(self):
        result = _merge_memory({"user": "João", "lang": "pt"}, {"summary": "x"})
        assert result["user"] == "João"
        assert result["lang"] == "pt"

    def test_empty_existing(self):
        result = _merge_memory({}, {"key": "value"})
        assert result == {"key": "value"}

    def test_empty_incoming(self):
        result = _merge_memory({"key": "value"}, {})
        assert result == {"key": "value"}

    def test_both_empty(self):
        assert _merge_memory({}, {}) == {}

    def test_does_not_mutate_existing(self):
        existing = {"key": "original"}
        _merge_memory(existing, {"key": "changed"})
        assert existing["key"] == "original"


class TestAgentStateShape:
    def test_state_accepts_required_keys(self):
        state: AgentState = {
            "messages": [HumanMessage(content="olá")],
            "next_agent": "suporte",
            "tenant_id": "tenant-1",
            "memory": {},
        }
        assert state["tenant_id"] == "tenant-1"
        assert state["next_agent"] == "suporte"
        assert len(state["messages"]) == 1

    def test_messages_reducer_appends(self):
        existing = [HumanMessage(content="msg1")]
        incoming = [AIMessage(content="msg2")]
        result = add_messages(existing, incoming)
        assert len(result) == 2
        assert result[1].content == "msg2"
