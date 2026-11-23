import pytest

from codebud import create_app
from codebud.config import Config

from .conftest import USER


def test_signup_success(signup, db):
    res = signup()
    assert res.status_code == 200
    assert res.json["message"] == "Account created successfully!"

    stored = db.users.find_one({"username": "tommy"})
    assert stored["password"] != USER["password"]  # hashed
    assert stored["child_age"] == 6


def test_signup_accepts_age_as_string(signup, db):
    # The Flutter text field sends the age as a string.
    assert signup(child_age="5").status_code == 200
    assert db.users.find_one({"username": "tommy"})["child_age"] == 5


def test_signup_duplicate_username(signup):
    signup()
    res = signup()
    assert res.status_code == 400
    assert res.json["message"] == "Account already exists!"


@pytest.mark.parametrize(
    "overrides, field",
    [
        ({"parent_name": ""}, "parent_name"),
        ({"email": "not-an-email"}, "email"),
        ({"child_age": 40}, "child_age"),
        ({"child_age": "five"}, "child_age"),
        ({"username": "a b"}, "username"),
        ({"password": "123"}, "password"),
    ],
)
def test_signup_validation(signup, overrides, field):
    res = signup(**overrides)
    assert res.status_code == 400
    assert res.json["success"] is False
    assert res.json["field"] == field


def test_signup_missing_body(client):
    res = client.post("/signup", data="nope", content_type="text/plain")
    assert res.status_code == 400
    assert res.json["success"] is False


def test_login_success(client, signup):
    signup()
    res = client.post("/login", json={"username": "tommy", "password": "secret123"})
    assert res.status_code == 200
    assert res.json["success"] is True
    assert res.json["child_name"] == "Tommy"
    assert res.json["token"]


@pytest.mark.parametrize("username, password", [("tommy", "wrong-pass"), ("ghost", "secret123")])
def test_login_failure_does_not_reveal_which_part_was_wrong(client, signup, username, password):
    signup()
    res = client.post("/login", json={"username": username, "password": password})
    assert res.status_code == 401
    assert res.json["message"] == "Incorrect username or password."


def test_me(client, auth_header):
    res = client.get("/api/me", headers=auth_header)
    assert res.status_code == 200
    assert res.json == {"username": "tommy", "child_name": "Tommy", "child_age": 6}


def test_protected_route_requires_token(client):
    assert client.get("/api/me").status_code == 401


def test_production_requires_jwt_secret(monkeypatch, db):
    class Prod(Config):
        ENV = "production"
        DEBUG = False
        JWT_SECRET_KEY = None

    with pytest.raises(RuntimeError, match="JWT_SECRET_KEY"):
        create_app(Prod, db=db)


def test_health(client):
    assert client.get("/health").json == {"status": "ok"}
