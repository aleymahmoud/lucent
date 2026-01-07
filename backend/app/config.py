# ============================================
# LUCENT Backend - Configuration & Settings
# ============================================

from pydantic_settings import BaseSettings
from typing import Optional
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables"""

    # Application
    APP_NAME: str = "LUCENT"
    APP_ENV: str = "development"
    DEBUG: bool = True

    # API
    API_VERSION: str = "v1"
    API_PREFIX: str = "/api/v1"
    CORS_ORIGINS: str = "http://localhost:3000,http://localhost:3001"

    # Security
    SECRET_KEY: str
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_HOURS: int = 24

    # Database - PostgreSQL
    DATABASE_URL: str
    DATABASE_URL_UNPOOLED: Optional[str] = None
    PGHOST: Optional[str] = None
    PGUSER: Optional[str] = None
    PGDATABASE: Optional[str] = None
    PGPASSWORD: Optional[str] = None
    PGSSLMODE: str = "require"

    # Redis
    REDIS_URL: str
    KV_REST_API_URL: Optional[str] = None
    KV_REST_API_TOKEN: Optional[str] = None

    # Celery
    CELERY_BROKER_URL: Optional[str] = None
    CELERY_RESULT_BACKEND: Optional[str] = None

    # File Upload
    MAX_UPLOAD_SIZE_MB: int = 100
    UPLOAD_DIR: str = "./uploads"

    # Rate Limiting
    RATE_LIMIT_ENABLED: bool = True
    RATE_LIMIT_PER_MINUTE: int = 60

    # Multi-Tenant Limits
    DEFAULT_MAX_USERS: int = 10
    DEFAULT_MAX_FILE_SIZE_MB: int = 100
    DEFAULT_MAX_ENTITIES_PER_BATCH: int = 50
    DEFAULT_MAX_CONCURRENT_FORECASTS: int = 3
    DEFAULT_MAX_FORECAST_HORIZON: int = 365
    DEFAULT_RATE_LIMIT_FORECASTS_PER_HOUR: int = 20

    # Logging
    LOG_LEVEL: str = "INFO"
    LOG_FILE: str = "./logs/lucent.log"

    # Stack Auth
    STACK_PROJECT_ID: Optional[str] = None
    STACK_PUBLISHABLE_CLIENT_KEY: Optional[str] = None
    STACK_SECRET_SERVER_KEY: Optional[str] = None

    @property
    def cors_origins_list(self) -> list[str]:
        """Convert CORS_ORIGINS string to list"""
        return [origin.strip() for origin in self.CORS_ORIGINS.split(",")]

    @property
    def celery_broker(self) -> str:
        """Get Celery broker URL (fallback to Redis)"""
        return self.CELERY_BROKER_URL or self.REDIS_URL

    @property
    def celery_backend(self) -> str:
        """Get Celery result backend (fallback to Redis)"""
        return self.CELERY_RESULT_BACKEND or self.REDIS_URL

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance"""
    return Settings()


# Export settings instance
settings = get_settings()
