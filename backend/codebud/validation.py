import re
from typing import Any

from flask import request

from .errors import ApiError

USERNAME_RE = re.compile(r"^[A-Za-z0-9_.-]{3,30}$")
EMAIL_RE = re.compile(r"^[^@\s]+@[^@\s]+\.[^@\s]+$")


def json_body() -> dict[str, Any]:
    data = request.get_json(silent=True)
    if not isinstance(data, dict):
        raise ApiError("Request body must be a JSON object.")
    return data


def required_str(data: dict[str, Any], field: str, label: str, max_len: int = 100) -> str:
    value = data.get(field)
    if not isinstance(value, str) or not value.strip():
        raise ApiError(f"{label} is required.", field=field)
    value = value.strip()
    if len(value) > max_len:
        raise ApiError(f"{label} is too long.", field=field)
    return value


def int_in_range(value: Any, field: str, label: str, lo: int, hi: int) -> int:
    if isinstance(value, str) and value.strip().isdigit():
        value = int(value.strip())
    if not isinstance(value, int) or isinstance(value, bool) or not lo <= value <= hi:
        raise ApiError(f"{label} must be a number from {lo} to {hi}.", field=field)
    return value
