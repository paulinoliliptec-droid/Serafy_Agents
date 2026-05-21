from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    # LLM providers
    openai_api_key: str = Field(default="", alias="OPENAI_API_KEY")
    anthropic_api_key: str = Field(default="", alias="ANTHROPIC_API_KEY")

    # Model per agent
    orchestrator_model: str = "gpt-4o"
    support_model: str = "gpt-4o-mini"
    commercial_model: str = "gpt-4o-mini"
    legal_model: str = "gpt-4o"
    hr_model: str = "gpt-4o-mini"
    financial_model: str = "gpt-4o"
    marketing_model: str = "gpt-4o-mini"

    # LangSmith
    langchain_tracing_v2: bool = False
    langchain_api_key: str = ""
    langchain_project: str = "agentOS-angola"

    # App
    app_env: str = "development"
    app_host: str = "0.0.0.0"
    app_port: int = 8080
    log_level: str = "INFO"

    # Security
    api_secret_key: str = "change-me"
    allowed_origins: str = "http://localhost:3000"

    # GCP / Firestore
    gcp_project_id: str = ""
    firestore_collection: str = "agentos_checkpoints"
    checkpointer_backend: str = "memory"  # "memory" | "firestore"

    # Firebase Authentication
    firebase_project_id: str = ""
    # Path to a service-account JSON — leave empty on Cloud Run (uses ADC)
    firebase_credentials_path: str = ""

    # WhatsApp Business API
    whatsapp_verify_token: str = "change-me-verify-token"
    whatsapp_app_secret: str = ""   # used to verify X-Hub-Signature-256
    whatsapp_api_token: str = ""    # permanent system user token from Meta
    whatsapp_default_tenant: str = "default"  # tenant_id for WA-originated sessions

    @property
    def cors_origins(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(",")]

    @property
    def is_production(self) -> bool:
        return self.app_env == "production"


settings = Settings()
