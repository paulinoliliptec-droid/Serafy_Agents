"""Shared fixtures for the agentOS-angola test suite."""
import pytest
from fastapi.testclient import TestClient
from langchain_core.messages import AIMessage, HumanMessage


# ── App + HTTP client ──────────────────────────────────────────────────────────

@pytest.fixture(scope="session")
def app():
    from main import app as _app
    return _app


@pytest.fixture
def client(app):
    return TestClient(app)


# ── Firebase user ─────────────────────────────────────────────────────────────

@pytest.fixture
def mock_user():
    from api.auth import FirebaseUser
    return FirebaseUser(
        uid="uid-test-123",
        email="teste@serafy.ao",
        tenant_id="tenant-serafy",
    )


@pytest.fixture
def authenticated_client(app, mock_user):
    """TestClient with Firebase auth dependency overridden."""
    from api.auth import require_firebase_auth

    async def _override():
        return mock_user

    app.dependency_overrides[require_firebase_auth] = _override
    with TestClient(app) as c:
        yield c, mock_user
    app.dependency_overrides.clear()


# ── AgentState ────────────────────────────────────────────────────────────────

@pytest.fixture
def base_state():
    return {
        "messages": [HumanMessage(content="Olá, preciso de ajuda")],
        "next_agent": "",
        "tenant_id": "tenant-test",
        "memory": {},
    }


@pytest.fixture
def state_with_memory():
    return {
        "messages": [HumanMessage(content="Qual é o preço?")],
        "next_agent": "",
        "tenant_id": "tenant-test",
        "memory": {"summary": "Cliente recorrente. Última sessão: pedido de proposta comercial."},
    }


# ── WhatsApp payload ──────────────────────────────────────────────────────────

@pytest.fixture
def wa_text_payload():
    return {
        "object": "whatsapp_business_account",
        "entry": [{
            "id": "WABA_123",
            "changes": [{
                "value": {
                    "messaging_product": "whatsapp",
                    "metadata": {
                        "display_phone_number": "+244900000000",
                        "phone_number_id": "phone-id-123",
                    },
                    "contacts": [{"profile": {"name": "João Silva"}, "wa_id": "244900000001"}],
                    "messages": [{
                        "from": "244900000001",
                        "id": "wamid.test123",
                        "timestamp": "1716300000",
                        "type": "text",
                        "text": {"body": "Quero saber o preço dos vossos serviços"},
                    }],
                },
                "field": "messages",
            }],
        }],
    }


@pytest.fixture
def wa_status_payload():
    """Payload with delivery status update (not a message — should be ignored)."""
    return {
        "object": "whatsapp_business_account",
        "entry": [{
            "id": "WABA_123",
            "changes": [{
                "value": {
                    "messaging_product": "whatsapp",
                    "metadata": {
                        "display_phone_number": "+244900000000",
                        "phone_number_id": "phone-id-123",
                    },
                    "statuses": [{"id": "wamid.abc", "status": "delivered"}],
                },
                "field": "messages",
            }],
        }],
    }
