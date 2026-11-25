"""Families: one parent account with one or more child profiles.

A user document looks like this::

    {
        "username": "jane", "password": "<hash>", "parent_name": "Jane", "email": "...",
        "children": [
            {"id": "a1b2c3d4", "name": "Tommy", "age": 6,
             "robot": {"character": "robot", "color": "teal", "nickname": "Sparky"}},
        ],
    }

Progress rows carry the ``child_id`` they belong to. Accounts made before
families existed have a single ``child_name`` and ``child_age``; they are
converted the first time they are loaded (see :func:`load_user`).

Parent-only actions need a short-lived *parent token*, which the app gets by
re-entering the account password (``POST /api/parent/unlock``). A child who
picks up a logged-in tablet can play, and change their own robot, but can't
change the account.
"""

from __future__ import annotations

import secrets
from datetime import timedelta
from functools import wraps
from typing import Any, Callable

from flask_jwt_extended import get_jwt, get_jwt_identity, jwt_required

from .db import PROGRESS, USERS, get_db
from .errors import ApiError
from .validation import int_in_range

MAX_CHILDREN = 6
MIN_AGE, MAX_AGE = 3, 12
MAX_NAME = 30
MAX_NICKNAME = 20
PARENT_TOKEN_LIFETIME = timedelta(minutes=30)

CHARACTERS = ("robot", "rocket", "bunny", "bird", "puppy", "bee")
COLORS = ("teal", "sky", "violet", "pink", "red", "orange", "yellow", "lime")


def default_robot(index: int) -> dict[str, str]:
    # Brothers and sisters start with different colours, so their robots are easy to tell apart.
    return {"character": "robot", "color": COLORS[index % len(COLORS)], "nickname": ""}


def new_child(name: str, age: Any, index: int) -> dict[str, Any]:
    return {"id": secrets.token_hex(4), "name": name, "age": age, "robot": default_robot(index)}


def parse_child(raw: Any, index: int, field: str = "children") -> dict[str, Any]:
    if not isinstance(raw, dict):
        raise ApiError("Each child needs a name and an age.", field=field)
    name = raw.get("name")
    if not isinstance(name, str) or not name.strip():
        raise ApiError("Every child needs a name.", field=field)
    if len(name.strip()) > MAX_NAME:
        raise ApiError("That child's name is too long.", field=field)
    age = int_in_range(raw.get("age"), field, "Child age", MIN_AGE, MAX_AGE)
    return new_child(name.strip(), age, index)


def parse_robot(raw: Any, current: dict[str, str]) -> dict[str, str]:
    """Apply robot changes on top of ``current``. Only the fields that are sent change."""
    if not isinstance(raw, dict):
        raise ApiError("robot must be an object.", field="robot")
    robot = dict(current)
    if "character" in raw:
        if raw["character"] not in CHARACTERS:
            raise ApiError(f"Unknown character. Pick one of: {', '.join(CHARACTERS)}.", field="character")
        robot["character"] = raw["character"]
    if "color" in raw:
        if raw["color"] not in COLORS:
            raise ApiError(f"Unknown colour. Pick one of: {', '.join(COLORS)}.", field="color")
        robot["color"] = raw["color"]
    if "nickname" in raw:
        nickname = raw["nickname"]
        if not isinstance(nickname, str):
            raise ApiError("Nickname must be text.", field="nickname")
        nickname = " ".join(nickname.split())  # trim and collapse spaces
        if len(nickname) > MAX_NICKNAME:
            raise ApiError(f"Nickname can be up to {MAX_NICKNAME} letters.", field="nickname")
        robot["nickname"] = nickname
    return robot


def public_child(child: dict[str, Any]) -> dict[str, Any]:
    robot = {**default_robot(0), **(child.get("robot") or {})}
    return {"id": child["id"], "name": child["name"], "age": child.get("age"), "robot": robot}


def load_user(username: str | None) -> dict[str, Any]:
    """Find an account, converting a pre-family account to the ``children`` list on the way."""
    db = get_db()
    user = db[USERS].find_one({"username": username})
    if not user:
        raise ApiError("Account not found.", code=404)
    if user.get("children"):
        return user

    child = new_child(user.get("child_name") or "Player", user.get("child_age"), 0)
    db[USERS].update_one(
        {"_id": user["_id"], "children": {"$exists": False}},
        {"$set": {"children": [child]}, "$unset": {"child_name": "", "child_age": ""}},
    )
    # Re-read in case another request converted the account at the same moment.
    user = db[USERS].find_one({"_id": user["_id"]})
    first = user["children"][0]["id"]
    db[PROGRESS].update_many(
        {"username": user["username"], "child_id": {"$exists": False}}, {"$set": {"child_id": first}}
    )
    return user


def current_user() -> dict[str, Any]:
    return load_user(get_jwt_identity())


def find_child(user: dict[str, Any], child_id: Any) -> dict[str, Any]:
    """The child with ``child_id``. Without an id, the first child, which keeps older clients working."""
    children = user["children"]
    if child_id in (None, ""):
        return children[0]
    for child in children:
        if child["id"] == child_id:
            return child
    raise ApiError("That child profile was not found.", code=404, field="child_id")


def is_parent() -> bool:
    return bool(get_jwt().get("parent"))


def parent_required(fn: Callable) -> Callable:
    """Like ``jwt_required``, but the token must come from ``POST /api/parent/unlock``."""

    @wraps(fn)
    @jwt_required()
    def wrapper(*args, **kwargs):
        if not is_parent():
            raise ApiError("A grown-up needs to unlock parent settings first.", code=403, error="parent_required")
        return fn(*args, **kwargs)

    return wrapper
