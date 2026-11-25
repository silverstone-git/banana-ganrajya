from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./banana.db"
    
    # Authentication, storage & payment integrations
    AUTH0_DOMAIN: str = "your-auth0-domain.auth0.com"
    AUTH0_CLIENT_ID: str = ""
    AUTH0_CLIENT_SECRET: str = ""
    AUTH0_AUDIENCE: str = ""
    PAYTM_MERCHANT_KEY: str = "mock-paytm-merchant-key"
    PAYTM_MERCHANT_ID: str = "mock-paytm-merchant-id"
    AWS_ACCESS_KEY_ID: str = "mock-aws-access-key"
    AWS_SECRET_ACCESS_KEY: str = "mock-aws-secret-key"
    AWS_BUCKET_NAME: str = "banana-media-bucket"
    
    # Cloudflare R2 Storage Configurations
    CLOUDFLARE_ACCESS_KEY_ID: str = ""
    CLOUDFLARE_SECRET_ACCESS_KEY: str = ""
    R2_BUCKET_NAME: str = ""
    R2_REGION: str = "us-east-1"
    R2_ENDPOINT: str = ""
    
    # Administrator Portal access configurations
    ADMIN_EMAIL: str = "admin@banana.in"
    # Required, no default: the app refuses to start without a real key.
    ADMIN_API_KEY: str

    @field_validator("ADMIN_API_KEY")
    @classmethod
    def _admin_key_must_be_set(cls, v: str) -> str:
        v = v.strip().strip("\"'")
        if not v:
            raise ValueError(
                "ADMIN_API_KEY must be set to a long random secret "
                "(e.g. `python -c \"import secrets; print(secrets.token_urlsafe(48))\"`)."
            )
        return v

    model_config = SettingsConfigDict(
        env_file=[".env", "../.env"],
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()

# Strip any surrounding quotes that Docker or env files might preserve
if settings.DATABASE_URL.startswith('"') or settings.DATABASE_URL.startswith("'"):
    settings.DATABASE_URL = settings.DATABASE_URL.strip('"\'')

# Rewrite postgresql:// to cockroachdb:// ONLY when the target is actually CockroachDB
# (Cockroach Cloud host or its default port), so the correct SQLAlchemy dialect is used.
# Plain self-hosted PostgreSQL URLs are left untouched.
_is_cockroach = "cockroachlabs.cloud" in settings.DATABASE_URL or ":26257/" in settings.DATABASE_URL
if _is_cockroach:
    for _prefix in ("postgresql+psycopg2://", "postgresql://"):
        if settings.DATABASE_URL.startswith(_prefix):
            settings.DATABASE_URL = settings.DATABASE_URL.replace(_prefix, "cockroachdb://", 1)
            break

