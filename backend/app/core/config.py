from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # App
    app_name: str = "Rooster"
    debug: bool = False
    app_url: str = "http://localhost:3000"  # Frontend URL for invite links

    # Database
    database_url: str = "postgresql+asyncpg://localhost:5433/rooster"

    # Authentication
    secret_key: str = "dev-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 days

    # Email (SMTP) - For Gmail, use smtp.gmail.com with an App Password
    # Example .env for Gmail:
    #   SMTP_HOST=smtp.gmail.com
    #   SMTP_PORT=587
    #   SMTP_USER=your-email@gmail.com
    #   SMTP_PASSWORD=your-app-password
    #   SMTP_FROM_EMAIL=your-email@gmail.com
    #   EMAIL_ENABLED=true
    smtp_host: str = "smtp.gmail.com"
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_password: str = ""  # For Gmail, use an App Password
    smtp_from_email: str = ""
    smtp_from_name: str = "Rooster"
    smtp_use_tls: bool = True  # Use STARTTLS (required for Gmail)
    email_enabled: bool = False  # Set to true when SMTP credentials are configured

    # Email provider: "smtp" or "resend"
    email_provider: str = "smtp"

    # Resend API (alternative to SMTP)
    resend_api_key: str = ""

    # CORS
    cors_origins: str = "*"  # Comma-separated list of origins, or "*" for all

    # Web Push (VAPID) - Generate at https://vapidkeys.com
    vapid_public_key: str = ""
    vapid_private_key: str = ""
    vapid_subject: str = "mailto:admin@rooster.app"

    class Config:
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    return Settings()
