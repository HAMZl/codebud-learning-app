from flask import Flask, jsonify
from werkzeug.exceptions import HTTPException


class ApiError(Exception):
    """An error with a message that is safe to show to the user."""

    def __init__(self, message: str, code: int = 400, **extra):
        super().__init__(message)
        self.message = message
        self.code = code
        self.extra = extra


def register_error_handlers(app: Flask) -> None:
    @app.errorhandler(ApiError)
    def handle_api_error(err: ApiError):
        return jsonify({"success": False, "message": err.message, **err.extra}), err.code

    @app.errorhandler(HTTPException)
    def handle_http_error(err: HTTPException):
        return jsonify({"success": False, "message": err.description}), err.code

    @app.errorhandler(Exception)
    def handle_unexpected(err: Exception):
        app.logger.exception("Unhandled error")
        return jsonify({"success": False, "message": "Something went wrong. Please try again."}), 500
