"""CodeBud backend: a Flask API for auth, puzzles and progress."""

from __future__ import annotations

from typing import Any

from dotenv import load_dotenv
from flask import Flask, jsonify
from flask_cors import CORS
from flask_jwt_extended import JWTManager

from . import db as database
from .config import Config
from .errors import register_error_handlers
from .routes import register_blueprints

DEV_FALLBACK_SECRET = "dev-only-secret-change-me-0123456789abcdef"


def create_app(config: type[Config] | Config | None = None, *, db: Any = None) -> Flask:
    """Build the Flask app.

    ``db`` injects a database object, for example a ``mongomock`` database in
    tests. Without it the app connects to ``MONGO_URI``.
    """
    load_dotenv()
    app = Flask(__name__)
    cfg = config() if isinstance(config, type) else (config or Config())
    app.config.from_object(cfg)

    if not app.config.get("JWT_SECRET_KEY"):
        if cfg.is_development:
            app.logger.warning("JWT_SECRET_KEY is not set; using an insecure development secret.")
            app.config["JWT_SECRET_KEY"] = DEV_FALLBACK_SECRET
        else:
            raise RuntimeError(
                "JWT_SECRET_KEY must be set. Generate one with: "
                'python -c "import secrets; print(secrets.token_hex(32))"'
            )

    CORS(app, origins=app.config["CORS_ORIGINS"])
    JWTManager(app)

    if db is None:
        db = database.connect(app.config["MONGO_URI"], app.config["MONGO_DB_NAME"])
    app.extensions["codebud_db"] = db
    if app.config.get("CREATE_INDEXES"):
        try:
            database.ensure_indexes(db)
        except Exception:  # The database may not be reachable yet; don't stop the server from booting.
            app.logger.exception("Could not create MongoDB indexes")

    register_error_handlers(app)
    register_blueprints(app)

    @app.get("/health")
    def health():
        return jsonify({"status": "ok"})

    return app
