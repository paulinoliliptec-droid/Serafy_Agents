"""
Firebase Admin SDK — JWT verification dependency for FastAPI.

Usage:
    @router.post("/endpoint")
    async def endpoint(user: FirebaseUser = Depends(require_firebase_auth)):
        ...

The dependency reads the `Authorization: Bearer <id_token>` header,
verifies it against the Firebase project, and returns a FirebaseUser.
Raises HTTP 401 if the token is missing, expired, or invalid.
"""

from __future__ import annotations

from functools import lru_cache

import firebase_admin
import structlog
from firebase_admin import auth as firebase_auth, credentials
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from pydantic import BaseModel

from config import settings

logger = structlog.get_logger(__name__)

_bearer = HTTPBearer(auto_error=True)


# ── Firebase app singleton ────────────────────────────────────────────────────

@lru_cache(maxsize=1)
def _get_firebase_app() -> firebase_admin.App:
    """Initialise Firebase Admin SDK exactly once (lazy, cached)."""
    if firebase_admin._apps:
        return firebase_admin.get_app()

    if settings.firebase_credentials_path:
        cred = credentials.Certificate(settings.firebase_credentials_path)
        logger.info("firebase_init_service_account", path=settings.firebase_credentials_path)
    else:
        # Application Default Credentials — works automatically on Cloud Run
        cred = credentials.ApplicationDefault()
        logger.info("firebase_init_adc")

    return firebase_admin.initialize_app(
        cred,
        {"projectId": settings.firebase_project_id or None},
    )


# ── User model returned by the dependency ────────────────────────────────────

class FirebaseUser(BaseModel):
    uid: str
    email: str | None = None
    # Custom claim — set this on the Firebase token to identify the tenant
    tenant_id: str = "default"
    # Raw decoded token payload for advanced use
    claims: dict = {}


# ── FastAPI dependency ────────────────────────────────────────────────────────

async def require_firebase_auth(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer),
) -> FirebaseUser:
    """
    Verify the Firebase ID token from the Authorization header.

    Returns a FirebaseUser on success.
    Raises HTTP 401 on any verification failure.
    """
    _get_firebase_app()  # ensure SDK is initialised
    token = credentials.credentials
    try:
        decoded = firebase_auth.verify_id_token(token, check_revoked=True)
    except firebase_auth.RevokedIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token revogado. Faça login novamente.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except firebase_auth.ExpiredIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token expirado. Faça login novamente.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except firebase_auth.InvalidIdTokenError as exc:
        logger.warning("invalid_firebase_token", error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as exc:
        logger.exception("firebase_auth_error", error=str(exc))
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Erro de autenticação.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    return FirebaseUser(
        uid=decoded["uid"],
        email=decoded.get("email"),
        # tenant_id can be set as a Firebase custom claim: auth.set_custom_user_claims(uid, {"tenant_id": "..."})
        tenant_id=decoded.get("tenant_id", "default"),
        claims=decoded,
    )


# Optional: public-only dependency (no auth required, but accepted if present)
async def optional_firebase_auth(
    credentials: HTTPAuthorizationCredentials | None = Depends(
        HTTPBearer(auto_error=False)
    ),
) -> FirebaseUser | None:
    if not credentials:
        return None
    return await require_firebase_auth(credentials)
