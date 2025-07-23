import pytest
import sys
import os
import pytest

sys.path.append(os.path.dirname(os.path.abspath(__file__)) + "/..")
from app import app as flask_app
from unittest.mock import patch

@pytest.fixture
def app():
    flask_app.config['TESTING'] = True
    flask_app.config['JWT_SECRET_KEY'] = 'test-secret'
    yield flask_app

@pytest.fixture
def client(app):
    return app.test_client()

@pytest.fixture
def auth_header():
    with patch("flask_jwt_extended.view_decorators.verify_jwt_in_request", return_value=None), \
         patch("flask_jwt_extended.get_jwt_identity", return_value="testuser"):
        yield {"Authorization": "Bearer faketoken"}

@pytest.fixture
def mock_db_user():
    with patch("app.db.users") as mock:
        yield mock

@pytest.fixture
def mock_db_progress():
    with patch("app.db.progress") as mock:
        yield mock

@pytest.fixture
def mock_db_puzzles():
    with patch("app.db.puzzles") as mock:
        yield mock
