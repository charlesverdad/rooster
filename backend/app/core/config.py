from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # App
    app_name: str = "Rooster"
    debug: bool = False

    # Database
    database_url: str = "postgresql+asyncpg://localhost:5433/rooster"

    # Authentication
    secret_key: str = "dev-secret-key-change-in-production"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60 * 24 * 7  # 7 days

    class Config:
        env_file = ".env"


@lru_cache
def get_settings() -> Settings:
    return Settings()
