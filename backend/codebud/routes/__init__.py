from flask import Flask

from . import auth, progress, puzzles


def register_blueprints(app: Flask) -> None:
    app.register_blueprint(auth.bp)
    app.register_blueprint(puzzles.bp)
    app.register_blueprint(progress.bp)
