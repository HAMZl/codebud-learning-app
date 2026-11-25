"""Families: several children per account, the parent lock, and robot customisation."""

import pytest

from .conftest import USER

FAMILY = {
    "parent_name": "Sam",
    "email": "sam@example.com",
    "username": "the-lees",
    "password": "secret123",
    "children": [{"name": "Ava", "age": 5}, {"name": "Noah", "age": "7"}],
}


def login(client, username="the-lees", password="secret123"):
    res = client.post("/login", json={"username": username, "password": password})
    assert res.status_code == 200
    return res.json


@pytest.fixture
def family(client):
    assert client.post("/signup", json=FAMILY).status_code == 200
    data = login(client)
    headers = {"Authorization": f"Bearer {data['token']}"}
    unlock = client.post("/api/parent/unlock", json={"password": "secret123"}, headers=headers)
    parent = {"Authorization": f"Bearer {unlock.json['parent_token']}"}
    return {"children": data["children"], "headers": headers, "parent": parent}


def test_signup_with_several_children(client, db):
    assert client.post("/signup", json=FAMILY).status_code == 200
    stored = db.users.find_one({"username": "the-lees"})
    assert [(c["name"], c["age"]) for c in stored["children"]] == [("Ava", 5), ("Noah", 7)]
    assert len({c["id"] for c in stored["children"]}) == 2
    # Each child starts with a robot in a different colour.
    assert stored["children"][0]["robot"]["color"] != stored["children"][1]["robot"]["color"]


@pytest.mark.parametrize(
    "children",
    [[], "Ava", [{"name": "", "age": 5}], [{"name": "Ava", "age": 2}], [{"name": "Ava"}] * 7, ["Ava"]],
)
def test_signup_rejects_bad_children(client, children):
    res = client.post("/signup", json={**FAMILY, "children": children})
    assert res.status_code == 400
    assert res.json["field"] == "children"


def test_login_lists_the_children(client, family):
    data = login(client)
    assert [c["name"] for c in data["children"]] == ["Ava", "Noah"]
    assert data["children"][0]["robot"] == {"character": "robot", "color": "teal", "nickname": ""}
    assert data["message"] == "Welcome back, Sam!"


def test_unlock_needs_the_right_password(client, family):
    res = client.post("/api/parent/unlock", json={"password": "nope"}, headers=family["headers"])
    assert res.status_code == 403
    assert res.json["field"] == "password"


@pytest.mark.parametrize(
    "method, path, body",
    [
        ("patch", "/api/me", {"parent_name": "Kid"}),
        ("post", "/api/me/password", {"current_password": "secret123", "new_password": "hacked1"}),
        ("post", "/api/children", {"name": "Zed", "age": 4}),
        ("delete", "/api/progress", None),
    ],
)
def test_parent_actions_need_a_parent_token(client, family, method, path, body):
    res = getattr(client, method)(path, json=body, headers=family["headers"])
    assert res.status_code == 403
    assert res.json["error"] == "parent_required"


def test_add_and_remove_children(client, family, db):
    res = client.post("/api/children", json={"name": "Zed", "age": 4}, headers=family["parent"])
    assert res.status_code == 201
    zed = res.json["child"]
    names = [c["name"] for c in client.get("/api/children", headers=family["headers"]).json["children"]]
    assert names == ["Ava", "Noah", "Zed"]

    client.post("/api/progress", json={"puzzle_id": "seq1", "stars": 3, "child_id": zed["id"]}, headers=family["headers"])
    res = client.delete(f"/api/children/{zed['id']}", headers=family["parent"])
    assert res.status_code == 200
    assert res.json["removed_progress"] == 1
    assert len(db.users.find_one({"username": "the-lees"})["children"]) == 2


def test_cannot_remove_the_last_child(client, parent_header, db):
    only = db.users.find_one({"username": "tommy"})["children"][0]["id"]
    res = client.delete(f"/api/children/{only}", headers=parent_header)
    assert res.status_code == 400


def test_family_size_is_limited(client, family):
    for i in range(4):
        assert client.post("/api/children", json={"name": f"Kid{i}", "age": 6}, headers=family["parent"]).status_code == 201
    res = client.post("/api/children", json={"name": "One too many", "age": 6}, headers=family["parent"])
    assert res.status_code == 400


def test_kids_can_customise_their_robot(client, family):
    ava = family["children"][0]
    res = client.patch(
        f"/api/children/{ava['id']}",
        json={"robot": {"character": "rocket", "color": "violet", "nickname": "  Zoom   Zoom "}},
        headers=family["headers"],  # no parent token needed
    )
    assert res.status_code == 200
    assert res.json["child"]["robot"] == {"character": "rocket", "color": "violet", "nickname": "Zoom Zoom"}

    # Only the fields that are sent change.
    res = client.patch(f"/api/children/{ava['id']}", json={"robot": {"color": "lime"}}, headers=family["headers"])
    assert res.json["child"]["robot"] == {"character": "rocket", "color": "lime", "nickname": "Zoom Zoom"}


@pytest.mark.parametrize(
    "robot", [{"character": "dragon"}, {"color": "plaid"}, {"nickname": "x" * 21}, {"nickname": 5}, "rocket"]
)
def test_robot_validation(client, family, robot):
    ava = family["children"][0]
    res = client.patch(f"/api/children/{ava['id']}", json={"robot": robot}, headers=family["headers"])
    assert res.status_code == 400


def test_only_parents_can_rename_children(client, family):
    ava = family["children"][0]
    res = client.patch(f"/api/children/{ava['id']}", json={"name": "Boss"}, headers=family["headers"])
    assert res.status_code == 403
    res = client.patch(f"/api/children/{ava['id']}", json={"name": "Ava Rose", "age": 6}, headers=family["parent"])
    assert res.status_code == 200
    assert (res.json["child"]["name"], res.json["child"]["age"]) == ("Ava Rose", 6)


def test_unknown_child_is_404(client, family):
    assert client.patch("/api/children/nope", json={"robot": {}}, headers=family["headers"]).status_code == 404
    res = client.get("/api/progress?child_id=nope", headers=family["headers"])
    assert res.status_code == 404


def test_progress_is_kept_per_child(client, family):
    ava, noah = family["children"]
    h = family["headers"]
    client.post("/api/progress", json={"puzzle_id": "seq1", "stars": 3, "child_id": ava["id"]}, headers=h)
    client.post("/api/progress", json={"puzzle_id": "seq1", "stars": 1, "child_id": noah["id"]}, headers=h)

    def seq_stars(child):
        return client.get(f"/api/progress?child_id={child['id']}", headers=h).json["categories"]["sequence"]["stars"]

    assert (seq_stars(ava), seq_stars(noah)) == (3, 1)
    levels = client.get(f"/api/puzzles/sequence?child_id={noah['id']}", headers=h).json["puzzles"]
    assert levels[0]["best_stars"] == 1

    res = client.delete(f"/api/progress?child_id={noah['id']}", headers=family["parent"])
    assert res.json["removed"] == 1
    assert (seq_stars(ava), seq_stars(noah)) == (3, 0)


def test_requests_without_a_child_use_the_first_child(client, family):
    ava = family["children"][0]
    h = family["headers"]
    client.post("/api/progress", json={"puzzle_id": "seq1", "stars": 2}, headers=h)
    res = client.get(f"/api/progress?child_id={ava['id']}", headers=h)
    assert res.json["categories"]["sequence"]["stars"] == 2


def test_old_single_child_accounts_are_converted(client, db):
    # An account and progress row as they were stored before families existed.
    from werkzeug.security import generate_password_hash

    db.users.insert_one(
        {
            "username": "oldie",
            "password": generate_password_hash("secret123"),
            "parent_name": "Pat",
            "email": "pat@example.com",
            "child_name": "Max",
            "child_age": 6,
        }
    )
    db.progress.insert_one({"username": "oldie", "puzzle_id": "seq1", "stars": 3})

    data = login(client, "oldie")
    assert [c["name"] for c in data["children"]] == ["Max"]
    max_id = data["children"][0]["id"]

    stored = db.users.find_one({"username": "oldie"})
    assert "child_name" not in stored
    assert db.progress.find_one({"username": "oldie"})["child_id"] == max_id

    h = {"Authorization": f"Bearer {data['token']}"}
    assert client.get("/api/progress", headers=h).json["categories"]["sequence"]["stars"] == 3


def test_parent_token_works_for_normal_requests_too(client, parent_header):
    assert client.get("/api/me", headers=parent_header).status_code == 200


def test_me_lists_children(client, auth_header):
    res = client.get("/api/me", headers=auth_header)
    assert [c["name"] for c in res.json["children"]] == [USER["child_name"]]
    assert res.json["child_name"] == USER["child_name"]
