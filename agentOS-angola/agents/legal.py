"""
Legal agent — routes queries to the Kiesse legal API (Dra. Kiesse).

Flow:
  1. Detect CPLP country from tenant_id
  2. POST to KIESSE_API_URL with {query, pais, tenant_id, session_id}
  3. On failure → fallback to Gemini with a CPLP-aware legal prompt
  4. Fire-and-forget billing log to Firestore (legal_billing collection)
"""
from __future__ import annotations

import asyncio
import time
import uuid
from typing import Optional

import httpx
import structlog
from langchain_core.messages import AIMessage, HumanMessage, SystemMessage

from agents.state import AgentState
from config import settings

logger = structlog.get_logger(__name__)

# ── CPLP country detection ────────────────────────────────────────────────────

_COUNTRY_PREFIXES: dict[str, str] = {
    "ao": "AO", "angola": "AO",
    "pt": "PT", "portugal": "PT",
    "mz": "MZ", "mozambique": "MZ", "mocambique": "MZ",
    "cv": "CV", "caboverde": "CV", "cabo_verde": "CV",
    "st": "ST", "saotome": "ST", "sao_tome": "ST",
    "gw": "GW", "guine": "GW", "guinea": "GW",
    "br": "BR", "brasil": "BR", "brazil": "BR",
}

_COUNTRY_NAMES: dict[str, str] = {
    "AO": "Angola", "PT": "Portugal", "MZ": "Moçambique",
    "CV": "Cabo Verde", "ST": "São Tomé e Príncipe",
    "GW": "Guiné-Bissau", "BR": "Brasil",
}

_LEGAL_FRAMEWORKS: dict[str, str] = {
    "AO": (
        "Constituição da República (2010) · Lei das Sociedades Comerciais (Lei 1/04) · "
        "Código Geral do Trabalho (Lei 7/15) · Lei de Bases do Investimento Privado (Lei 10/18) · "
        "Regulamentação BNA · AGT · INAD"
    ),
    "PT": (
        "Código Civil · Código do Trabalho (CT 2009) · Código das Sociedades Comerciais (CSC) · "
        "RGPD/GDPR · Código IRS/IRC · Legislação UE aplicável"
    ),
    "MZ": (
        "Código Comercial · Lei do Trabalho (Lei 23/2007) · Lei das Empresas (Lei 1/2013) · "
        "Regulamentação MIREME e Banco de Moçambique"
    ),
    "CV": (
        "Código Comercial (DL 3/99) · Código Laboral (Lei 101/IV/93) · Regulamentação ADEI"
    ),
    "ST": (
        "Código Civil · Código do Trabalho (Lei 6/92) · "
        "Regulamentação Banco Central de São Tomé e Príncipe"
    ),
    "GW": (
        "Código Civil · Código do Trabalho · Legislação UEMOA · OHADA aplicável"
    ),
    "BR": (
        "Constituição Federal · Código Civil (Lei 10.406/2002) · CLT · "
        "Código de Defesa do Consumidor (CDC) · LGPD · Legislação estadual"
    ),
}

DISCLAIMER = (
    "*Esta informação é fornecida para fins informativos e não constitui "
    "aconselhamento jurídico formal. Consulte um advogado licenciado no seu "
    "país para questões específicas.*"
)

_GEMINI_SYSTEM_PROMPT = """\
És um especialista em orientação jurídica para os países da CPLP \
(Comunidade dos Países de Língua Portuguesa).

País do utilizador: {country_name}
Enquadramento legal aplicável: {framework}

Directrizes:
- Apresenta orientação clara e estruturada em Português (ou no idioma da pergunta).
- Referencia legislação específica quando aplicável.
- Para matérias de alto risco, indica explicitamente que é necessário advogado.
- Nunca emitas pareceres definitivos; enquadra sempre como orientação geral.
- Inclui SEMPRE o seguinte aviso no final da resposta:

{disclaimer}
"""


def _detect_country(tenant_id: str) -> str:
    """Detect CPLP country from tenant_id prefix. Defaults to AO (Angola)."""
    tid = tenant_id.lower().replace("-", "_")
    for prefix, code in _COUNTRY_PREFIXES.items():
        if tid == prefix or tid.startswith(f"{prefix}_"):
            return code
    return "AO"


def _extract_query(state: AgentState) -> str:
    """Return the last HumanMessage content as the legal query."""
    for msg in reversed(state["messages"]):
        if isinstance(msg, HumanMessage):
            return str(msg.content)
    return str(state["messages"][-1].content) if state["messages"] else ""


# ── Kiesse API call ───────────────────────────────────────────────────────────

async def _call_kiesse(
    query: str,
    country: str,
    tenant_id: str,
    session_id: str,
) -> tuple[str, int]:
    """
    POST to the Kiesse legal API.
    Returns (response_text, http_status_code).
    Raises httpx.HTTPStatusError or httpx.TimeoutException on failure.
    """
    async with httpx.AsyncClient(timeout=settings.kiesse_timeout) as client:
        resp = await client.post(
            settings.kiesse_api_url,
            json={
                "query": query,
                "pais": country,
                "tenant_id": tenant_id,
                "session_id": session_id,
            },
            headers={"Authorization": f"Bearer {settings.kiesse_api_key}"},
        )
        resp.raise_for_status()
        data = resp.json()
        # Accept {"response": "..."}, {"answer": "..."}, or plain text body
        text = data.get("response") or data.get("answer") or resp.text
        return str(text), resp.status_code


# ── Gemini fallback ───────────────────────────────────────────────────────────

async def _fallback_gemini(query: str, country: str) -> str:
    """Gemini-based fallback with a CPLP-aware legal prompt."""
    try:
        from langchain_google_genai import ChatGoogleGenerativeAI
    except ImportError:
        raise RuntimeError("langchain-google-genai não está instalado")

    llm = ChatGoogleGenerativeAI(
        model=settings.gemini_legal_model,
        google_api_key=settings.gemini_api_key,
        temperature=0.1,
    )
    system_content = _GEMINI_SYSTEM_PROMPT.format(
        country_name=_COUNTRY_NAMES.get(country, country),
        framework=_LEGAL_FRAMEWORKS.get(country, _LEGAL_FRAMEWORKS["AO"]),
        disclaimer=DISCLAIMER,
    )
    response = await llm.ainvoke([
        SystemMessage(content=system_content),
        HumanMessage(content=query),
    ])
    return str(response.content)


# ── Firestore billing log ─────────────────────────────────────────────────────

async def _log_billing(
    tenant_id: str,
    session_id: str,
    country: str,
    query: str,
    source: str,
    latency_ms: int,
    kiesse_status: Optional[int],
    kiesse_error: Optional[str],
) -> None:
    """
    Write a billing record to Firestore (legal_billing collection).
    Silently skipped when GCP_PROJECT_ID is not set (local dev).
    """
    if not settings.gcp_project_id:
        return
    try:
        from google.cloud import firestore
        client = firestore.AsyncClient(project=settings.gcp_project_id)
        await client.collection("legal_billing").add({
            "tenant_id": tenant_id,
            "session_id": session_id,
            "country": country,
            "query_preview": query[:120],   # no full query stored for privacy
            "source": source,               # "kiesse" | "gemini_fallback" | "error"
            "latency_ms": latency_ms,
            "kiesse_status_code": kiesse_status,
            "kiesse_error": kiesse_error,
            "created_at": firestore.SERVER_TIMESTAMP,
        })
        logger.debug("billing_logged", tenant_id=tenant_id, source=source)
    except Exception as exc:
        logger.warning("billing_log_failed", error=str(exc))


# ── Main node ─────────────────────────────────────────────────────────────────

async def legal_node(state: AgentState) -> dict:
    """
    Legal specialist node.

    Priority:
      1. Kiesse API  (external legal service)
      2. Gemini fallback  (CPLP legal prompt)
      3. Graceful error message
    """
    tenant_id = state.get("tenant_id", "default")
    memory = state.get("memory", {})
    session_id = memory.get("session_id") or memory.get("user_id") or str(uuid.uuid4())
    country = _detect_country(tenant_id)
    query = _extract_query(state)

    source = "kiesse"
    kiesse_status: Optional[int] = None
    kiesse_error: Optional[str] = None
    reply: Optional[str] = None
    t0 = time.monotonic()

    logger.info(
        "legal_node_start",
        tenant_id=tenant_id,
        country=country,
        session_id=session_id,
        query_len=len(query),
    )

    # ── 1. Kiesse API ─────────────────────────────────────────────────────────
    if settings.kiesse_api_url and settings.kiesse_api_key:
        try:
            reply, kiesse_status = await _call_kiesse(query, country, tenant_id, session_id)
            logger.info("kiesse_success", status=kiesse_status, tenant_id=tenant_id)
        except httpx.TimeoutException:
            kiesse_error = f"Timeout after {settings.kiesse_timeout}s"
            logger.warning("kiesse_timeout", tenant_id=tenant_id)
            source = "gemini_fallback"
        except httpx.HTTPStatusError as exc:
            kiesse_status = exc.response.status_code
            kiesse_error = f"HTTP {kiesse_status}: {exc.response.text[:200]}"
            logger.warning("kiesse_http_error", status=kiesse_status, tenant_id=tenant_id)
            source = "gemini_fallback"
        except Exception as exc:
            kiesse_error = str(exc)
            logger.warning("kiesse_error", error=kiesse_error, tenant_id=tenant_id)
            source = "gemini_fallback"
    else:
        logger.info("kiesse_not_configured", fallback="gemini")
        source = "gemini_fallback"

    # ── 2. Gemini fallback ────────────────────────────────────────────────────
    if reply is None:
        if settings.gemini_api_key:
            try:
                reply = await _fallback_gemini(query, country)
                logger.info("gemini_fallback_success", country=country, tenant_id=tenant_id)
            except Exception as exc:
                logger.error("gemini_fallback_failed", error=str(exc))
                source = "error"
        else:
            logger.warning("gemini_api_key_not_set")
            source = "error"

    # ── 3. Graceful error ─────────────────────────────────────────────────────
    if reply is None:
        reply = (
            f"Não foi possível processar o seu pedido jurídico de momento. "
            f"Por favor, tente novamente ou contacte directamente um advogado.\n\n{DISCLAIMER}"
        )

    latency_ms = int((time.monotonic() - t0) * 1000)

    # ── 4. Billing log (fire-and-forget) ─────────────────────────────────────
    asyncio.create_task(
        _log_billing(
            tenant_id=tenant_id,
            session_id=session_id,
            country=country,
            query=query,
            source=source,
            latency_ms=latency_ms,
            kiesse_status=kiesse_status,
            kiesse_error=kiesse_error,
        )
    )

    logger.info("legal_node_done", source=source, latency_ms=latency_ms)
    return {"messages": [AIMessage(content=reply)]}
