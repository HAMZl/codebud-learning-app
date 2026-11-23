import json
from pathlib import Path

import mongomock
import pytest

from codebud import create_app
from codebud.config import TestConfig

PUZZLES_JSON = Path(__file__).resolve().parents[2] / "database" / "puzzles.json"

USER = {
    "parent_name": "Jane",
    "email": "jane@example.com",
    "child_name": "Tommy",
    "child_age": 6,
    "username": "tommy",
    "password": "secret123",
}


@pytest.fixture(scope="session")
def puzzle_data():
    return json.loads(PUZZLES_JSON.read_text(encoding="utf-8"))


@pytest.fixture
def db(puzzle_data):
    database = mongomock.MongoClient()["codebud_test"]
    database.puzzles.insert_many([dict(p) for p in puzzle_data])
    return database


@pytest.fixture
def app(db):
    return create_app(TestConfig, db=db)


@pytest.fixture
def client(app):
    return app.test_client()


@pytest.fixture
def signup(client):
    def _signup(**overrides):
        return client.post("/signup", json={**USER, **overrides})

    return _signup


@pytest.fixture
def auth_header(client, signup):
    assert signup().status_code == 200
    res = client.post("/login", json={"username": USER["username"], "password": USER["password"]})
    assert res.status_code == 200
    return {"Authorization": f"Bearer {res.json['token']}"}
