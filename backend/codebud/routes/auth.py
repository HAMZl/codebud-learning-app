from datetime import datetime, timezone

from flask import Blueprint, jsonify
from flask_jwt_extended import create_access_token, get_jwt_identity, jwt_required
from pymongo.errors import DuplicateKeyError
from werkzeug.security import check_password_hash, generate_password_hash

from ..db import USERS, get_db
from ..errors import ApiError
from ..validation import EMAIL_RE, USERNAME_RE, int_in_range, json_body, required_str

bp = Blueprint("auth", __name__)

MIN_PASSWORD_LENGTH = 6
BAD_LOGIN = "Incorrect username or password."


@bp.post("/signup")
def signup():
    data = json_body()
    parent_name = required_str(data, "parent_name", "Parent name")
    email = required_str(data, "email", "Email", max_len=254).lower()
    child_name = required_str(data, "child_name", "Child name")
    child_age = int_in_range(data.get("child_age"), "child_age", "Child age", 3, 12)
    username = required_str(data, "username", "Username", max_len=30)
    password = data.get("password")

    if not EMAIL_RE.match(email):
        raise ApiError("Please enter a valid email address.", field="email")
    if not USERNAME_RE.match(username):
        raise ApiError(
            "Username must be 3-30 letters, numbers, dots, dashes or underscores.", field="username"
        )
    if not isinstance(password, str) or len(password) < MIN_PASSWORD_LENGTH:
        raise ApiError(f"Password must be at least {MIN_PASSWORD_LENGTH} characters.", field="password")

    users = get_db()[USERS]
    if users.find_one({"username": username}):
        raise ApiError("Account already exists!", field="username")

    try:
        users.insert_one(
            {
                "parent_name": parent_name,
                "email": email,
                "child_name": child_name,
                "child_age": child_age,
                "username": username,
                "password": generate_password_hash(password),
                "created_at": datetime.now(timezone.utc),
            }
        )
    except DuplicateKeyError:
        raise ApiError("Account already exists!", field="username")

    # 200 rather than 201, because clients that are already deployed check for 200.
    return jsonify({"success": True, "message": "Account created successfully!"}), 200


@bp.post("/login")
def login():
    data = json_body()
    username = data.get("username")
    password = data.get("password")
    if not isinstance(username, str) or not isinstance(password, str) or not username.strip():
        raise ApiError("Please enter your username and password.", code=400)

    user = get_db()[USERS].find_one({"username": username.strip()})
    # One message for both cases, so the response doesn't reveal which usernames exist.
    if not user or not check_password_hash(user["password"], password):
        raise ApiError(BAD_LOGIN, code=401)

    token = create_access_token(identity=user["username"])
    return jsonify(
        {
            "success": True,
            "message": f"Welcome, {user['child_name']}!",
            "token": token,
            "child_name": user["child_name"],
        }
    ), 200


def _current_user() -> dict:
    user = get_db()[USERS].find_one({"username": get_jwt_identity()})
    if not user:
        raise ApiError("Account not found.", code=404)
    return user


def _profile(user: dict) -> dict:
    return {
        "username": user["username"],
        "child_name": user["child_name"],
        "child_age": user.get("child_age"),
        "parent_name": user.get("parent_name"),
        "email": user.get("email"),
    }


@bp.get("/api/me")
@jwt_required()
def me():
    return jsonify(_profile(_current_user()))


@bp.patch("/api/me")
@jwt_required()
def update_me():
    """Update profile fields. Only the fields that are sent are changed."""
    data = json_body()
    user = _current_user()
    changes: dict = {}
    if "child_name" in data:
        changes["child_name"] = required_str(data, "child_name", "Child name")
    if "child_age" in data:
        changes["child_age"] = int_in_range(data["child_age"], "child_age", "Child age", 3, 12)
    if "parent_name" in data:
        changes["parent_name"] = required_str(data, "parent_name", "Parent name")
    if "email" in data:
        email = required_str(data, "email", "Email", max_len=254).lower()
        if not EMAIL_RE.match(email):
            raise ApiError("Please enter a valid email address.", field="email")
        changes["email"] = email
    if not changes:
        raise ApiError("Nothing to update.")

    get_db()[USERS].update_one({"_id": user["_id"]}, {"$set": changes})
    return jsonify({"success": True, "message": "Profile updated.", **_profile({**user, **changes})})


@bp.post("/api/me/password")
@jwt_required()
def change_password():
    data = json_body()
    user = _current_user()
    current = data.get("current_password")
    new = data.get("new_password")
    if not isinstance(current, str) or not check_password_hash(user["password"], current):
        raise ApiError("Current password is incorrect.", code=403, field="current_password")
    if not isinstance(new, str) or len(new) < MIN_PASSWORD_LENGTH:
        raise ApiError(f"Password must be at least {MIN_PASSWORD_LENGTH} characters.", field="new_password")

    get_db()[USERS].update_one({"_id": user["_id"]}, {"$set": {"password": generate_password_hash(new)}})
    return jsonify({"success": True, "message": "Password changed."})
