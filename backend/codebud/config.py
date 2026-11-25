import os
from datetime import timedelta
from pathlib import Path

from dotenv import load_dotenv

# Config reads the environment when this module is imported, so backend/.env
# must be loaded first. Variables already set in the environment take precedence.
load_dotenv(Path(__file__).resolve().parent.parent / ".env")


def _env_bool(name: str, default: bool = False) -> bool:
    value = os.getenv(name)
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


class Config:
    """Settings read from environment variables. A local ``.env`` file is loaded in development."""

    ENV = os.getenv("CODEBUD_ENV", "production")
    DEBUG = _env_bool("FLASK_DEBUG")
    TESTING = False

    MONGO_URI = os.getenv("MONGO_URI", "mongodb://localhost:27017")
    MONGO_DB_NAME = os.getenv("MONGO_DB_NAME", "codebud")

    # SECRET_KEY is accepted because older Render setups configured that name.
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY") or os.getenv("SECRET_KEY")
    # flask-jwt-extended defaults to 15 minutes. That is too short for a child's play session.
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(days=int(os.getenv("JWT_EXPIRES_DAYS", "7")))

    # Comma-separated list of allowed origins, e.g. "https://codebud-app.web.app".
    CORS_ORIGINS = [o.strip() for o in os.getenv("CORS_ORIGINS", "*").split(",") if o.strip()]

    # Create MongoDB indexes on startup. This is idempotent and cheap.
    CREATE_INDEXES = _env_bool("CREATE_INDEXES", True)

    @property
    def is_development(self) -> bool:
        return self.ENV == "development" or self.DEBUG


class TestConfig(Config):
    ENV = "testing"
    TESTING = True
    JWT_SECRET_KEY = "test-secret-key-that-is-long-enough-for-hs256"
    CORS_ORIGINS = ["*"]
