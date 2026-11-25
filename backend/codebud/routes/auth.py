from datetime import datetime, timezone

from flask import Blueprint, jsonify
from flask_jwt_extended import create_access_token, jwt_required
from pymongo.errors import DuplicateKeyError
from werkzeug.security import check_password_hash, generate_password_hash

from .. import family
from ..db import PROGRESS, USERS, get_db
from ..errors import ApiError
from ..family import MAX_CHILDREN, current_user, find_child, parent_required, public_child
from ..validation import EMAIL_RE, USERNAME_RE, int_in_range, json_body, required_str

bp = Blueprint("auth", __name__)

MIN_PASSWORD_LENGTH = 6
BAD_LOGIN = "Incorrect username or password."


def _parse_children(data: dict) -> list[dict]:
    """Read ``children: [{name, age}, ...]``, or the older single ``child_name`` and ``child_age``."""
    if "children" not in data:
        name = required_str(data, "child_name", "Child name", max_len=family.MAX_NAME)
        age = int_in_range(data.get("child_age"), "child_age", "Child age", family.MIN_AGE, family.MAX_AGE)
        return [family.new_child(name, age, 0)]

    raw = data["children"]
    if not isinstance(raw, list) or not raw:
        raise ApiError("Add at least one child.", field="children")
    if len(raw) > MAX_CHILDREN:
        raise ApiError(f"A family can have up to {MAX_CHILDREN} children.", field="children")
    return [family.parse_child(c, i) for i, c in enumerate(raw)]


@bp.post("/signup")
def signup():
    data = json_body()
    parent_name = required_str(data, "parent_name", "Parent name")
    email = required_str(data, "email", "Email", max_len=254).lower()
    children = _parse_children(data)
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
                "children": children,
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

    user = family.load_user(user["username"])
    token = create_access_token(identity=user["username"])
    children = [public_child(c) for c in user["children"]]
    return jsonify(
        {
            "success": True,
            "message": f"Welcome back, {user.get('parent_name') or user['username']}!",
            "token": token,
            "parent_name": user.get("parent_name"),
            "children": children,
            # Older clients greet the first child by name.
            "child_name": children[0]["name"],
        }
    ), 200


def _profile(user: dict) -> dict:
    children = [public_child(c) for c in user["children"]]
    return {
        "username": user["username"],
        "parent_name": user.get("parent_name"),
        "email": user.get("email"),
        "children": children,
        # Kept for older clients, which only know about one child.
        "child_name": children[0]["name"],
        "child_age": children[0]["age"],
    }


@bp.get("/api/me")
@jwt_required()
def me():
    return jsonify(_profile(current_user()))


@bp.post("/api/parent/unlock")
@jwt_required()
def unlock_parent():
    """Swap the account password for a short-lived token that allows parent-only actions."""
    data = json_body()
    user = current_user()
    password = data.get("password")
    if not isinstance(password, str) or not check_password_hash(user["password"], password):
        raise ApiError("That password isn't right.", code=403, field="password")
    token = create_access_token(
        identity=user["username"],
        additional_claims={"parent": True},
        expires_delta=family.PARENT_TOKEN_LIFETIME,
    )
    return jsonify(
        {
            "success": True,
            "parent_token": token,
            "expires_in": int(family.PARENT_TOKEN_LIFETIME.total_seconds()),
        }
    )


@bp.patch("/api/me")
@parent_required
def update_me():
    """Update the parent's details. Only the fields that are sent are changed.

    ``child_name`` and ``child_age`` are still accepted from older clients and
    change the first child.
    """
    data = json_body()
    user = current_user()
    changes: dict = {}
    if "parent_name" in data:
        changes["parent_name"] = required_str(data, "parent_name", "Parent name")
    if "email" in data:
        email = required_str(data, "email", "Email", max_len=254).lower()
        if not EMAIL_RE.match(email):
            raise ApiError("Please enter a valid email address.", field="email")
        changes["email"] = email

    children = [dict(c) for c in user["children"]]
    if "child_name" in data:
        children[0]["name"] = required_str(data, "child_name", "Child name", max_len=family.MAX_NAME)
    if "child_age" in data:
        children[0]["age"] = int_in_range(
            data["child_age"], "child_age", "Child age", family.MIN_AGE, family.MAX_AGE
        )
    if children != user["children"]:
        changes["children"] = children
    if not changes:
        raise ApiError("Nothing to update.")

    get_db()[USERS].update_one({"_id": user["_id"]}, {"$set": changes})
    return jsonify({"success": True, "message": "Profile updated.", **_profile({**user, **changes})})


@bp.post("/api/me/password")
@parent_required
def change_password():
    data = json_body()
    user = current_user()
    current = data.get("current_password")
    new = data.get("new_password")
    if not isinstance(current, str) or not check_password_hash(user["password"], current):
        raise ApiError("Current password is incorrect.", code=403, field="current_password")
    if not isinstance(new, str) or len(new) < MIN_PASSWORD_LENGTH:
        raise ApiError(f"Password must be at least {MIN_PASSWORD_LENGTH} characters.", field="new_password")

    get_db()[USERS].update_one({"_id": user["_id"]}, {"$set": {"password": generate_password_hash(new)}})
    return jsonify({"success": True, "message": "Password changed."})


# --- children ------------------------------------------------------------------------


def _save_children(user: dict, children: list[dict]) -> None:
    get_db()[USERS].update_one({"_id": user["_id"]}, {"$set": {"children": children}})


@bp.get("/api/children")
@jwt_required()
def list_children():
    return jsonify({"children": [public_child(c) for c in current_user()["children"]]})


@bp.post("/api/children")
@parent_required
def add_child():
    user = current_user()
    children = list(user["children"])
    if len(children) >= MAX_CHILDREN:
        raise ApiError(f"A family can have up to {MAX_CHILDREN} children.", field="children")
    child = family.parse_child(json_body(), len(children), field="name")
    children.append(child)
    _save_children(user, children)
    return jsonify({"success": True, "child": public_child(child)}), 201


@bp.patch("/api/children/<child_id>")
@jwt_required()
def update_child(child_id: str):
    """Kids may change their own robot. Changing a name or age needs a parent token."""
    data = json_body()
    user = current_user()
    child = dict(find_child(user, child_id))

    if "name" in data or "age" in data:
        if not family.is_parent():
            raise ApiError("Ask a grown-up to change names and ages.", code=403, error="parent_required")
        if "name" in data:
            child["name"] = required_str(data, "name", "Child name", max_len=family.MAX_NAME)
        if "age" in data:
            child["age"] = int_in_range(data["age"], "age", "Child age", family.MIN_AGE, family.MAX_AGE)
    if "robot" in data:
        child["robot"] = family.parse_robot(data["robot"], public_child(child)["robot"])
    if not {"name", "age", "robot"} & data.keys():
        raise ApiError("Nothing to update.")

    _save_children(user, [child if c["id"] == child_id else c for c in user["children"]])
    return jsonify({"success": True, "child": public_child(child)})


@bp.delete("/api/children/<child_id>")
@parent_required
def remove_child(child_id: str):
    user = current_user()
    find_child(user, child_id)  # 404 if it isn't one of this family's children
    if len(user["children"]) == 1:
        raise ApiError("An account needs at least one child.", field="children")
    _save_children(user, [c for c in user["children"] if c["id"] != child_id])
    removed = get_db()[PROGRESS].delete_many({"username": user["username"], "child_id": child_id}).deleted_count
    return jsonify({"success": True, "message": "Child removed.", "removed_progress": removed})
