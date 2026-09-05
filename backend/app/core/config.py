from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    DATABASE_URL: str = "sqlite:///./banana.db"
    
    # Authentication & S3 / Paytm integrations (to support future steps of PLAN.md)
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
    ADMIN_API_KEY: str = "secure_banana_admin_secret_key_2026"

    model_config = SettingsConfigDict(
        env_file=[".env", "../.env"],
        env_file_encoding="utf-8",
        extra="ignore"
    )

settings = Settings()

# Strip any surrounding quotes that Docker or env files might preserve
if settings.DATABASE_URL.startswith('"') or settings.DATABASE_URL.startswith("'"):
    settings.DATABASE_URL = settings.DATABASE_URL.strip('"\'')

# Automatically rewrite postgresql:// to cockroachdb:// if connecting to CockroachDB to use the correct SQLAlchemy dialect
if settings.DATABASE_URL.startswith("postgresql://"):
    settings.DATABASE_URL = settings.DATABASE_URL.replace("postgresql://", "cockroachdb://", 1)
elif settings.DATABASE_URL.startswith("postgresql+psycopg2://"):
    settings.DATABASE_URL = settings.DATABASE_URL.replace("postgresql+psycopg2://", "cockroachdb://", 1)

