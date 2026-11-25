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
    assert [(c["name"], c["age"]) for c in stored["children"]] == [("Tommy", 6)]


def test_signup_accepts_age_as_string(signup, db):
    # The Flutter text field sends the age as a string.
    assert signup(child_age="5").status_code == 200
    assert db.users.find_one({"username": "tommy"})["children"][0]["age"] == 5


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
    assert res.json["username"] == "tommy" and res.json["child_name"] == "Tommy" and res.json["child_age"] == 6


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


def test_me_includes_parent_details(client, auth_header):
    res = client.get("/api/me", headers=auth_header)
    assert res.json["parent_name"] == "Jane"
    assert res.json["email"] == "jane@example.com"


def test_update_profile(client, parent_header, db):
    res = client.patch("/api/me", json={"parent_name": "Janet", "email": "J@Example.com"}, headers=parent_header)
    assert res.status_code == 200
    stored = db.users.find_one({"username": "tommy"})
    assert (stored["parent_name"], stored["email"]) == ("Janet", "j@example.com")


def test_update_profile_legacy_child_fields_change_the_first_child(client, parent_header, db):
    res = client.patch("/api/me", json={"child_name": "Tom", "child_age": "7"}, headers=parent_header)
    assert res.status_code == 200
    assert res.json["child_name"] == "Tom"
    child = db.users.find_one({"username": "tommy"})["children"][0]
    assert (child["name"], child["age"]) == ("Tom", 7)


@pytest.mark.parametrize("body", [{}, {"child_age": 99}, {"email": "nope"}, {"child_name": " "}])
def test_update_profile_validation(client, parent_header, body):
    assert client.patch("/api/me", json=body, headers=parent_header).status_code == 400


def test_change_password(client, parent_header):
    res = client.post(
        "/api/me/password", json={"current_password": "secret123", "new_password": "newpass1"}, headers=parent_header
    )
    assert res.status_code == 200
    assert client.post("/login", json={"username": "tommy", "password": "secret123"}).status_code == 401
    assert client.post("/login", json={"username": "tommy", "password": "newpass1"}).status_code == 200


def test_change_password_requires_current_password(client, parent_header):
    res = client.post(
        "/api/me/password", json={"current_password": "wrong", "new_password": "newpass1"}, headers=parent_header
    )
    assert res.status_code == 403


def test_change_password_rejects_short_password(client, parent_header):
    res = client.post(
        "/api/me/password", json={"current_password": "secret123", "new_password": "123"}, headers=parent_header
    )
    assert res.status_code == 400
