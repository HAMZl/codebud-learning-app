import pytest
from werkzeug.security import generate_password_hash
from unittest.mock import patch

def test_signup_success(client, mock_db_user):
    mock_db_user.find_one.return_value = None
    mock_db_user.insert_one.return_value = None  # Prevent real DB call

    response = client.post("/signup", json={
        "parent_name": "Jane",
        "email": "jane@example.com",
        "child_name": "Tommy",
        "child_age": 6,
        "username": "testuser",
        "password": "testpass"
    })

    assert response.status_code == 200
    assert response.json["message"] == "Account created successfully!"

def test_signup_user_exists(client, mock_db_user):
    mock_db_user.find_one.return_value = {"username": "testuser"}

    response = client.post("/signup", json={
        "parent_name": "Jane",
        "email": "jane@example.com",
        "child_name": "Tommy",
        "child_age": 6,
        "username": "testuser",
        "password": "testpass"
    })

    assert response.status_code == 400
    assert response.json["message"] == "Account already exists!"

def test_login_success(client, mock_db_user):
    hashed = generate_password_hash("testpass")
    mock_db_user.find_one.return_value = {
        "username": "testuser",
        "password": hashed,
        "child_name": "Tommy"
    }

    response = client.post("/login", json={
        "username": "testuser",
        "password": "testpass"
    })

    assert response.status_code == 200
    assert response.json["success"] is True
    assert "token" in response.json

def test_login_wrong_password(client, mock_db_user):
    hashed = generate_password_hash("anotherpass")
    mock_db_user.find_one.return_value = {
        "username": "testuser",
        "password": hashed,
        "child_name": "Tommy"
    }

    response = client.post("/login", json={
        "username": "testuser",
        "password": "testpass"
    })

    assert response.status_code == 401
    assert response.json["message"] == "Incorrect password!"

def test_login_user_not_found(client, mock_db_user):
    mock_db_user.find_one.return_value = None

    response = client.post("/login", json={
        "username": "ghost",
        "password": "nopass"
    })

    assert response.status_code == 401
    assert response.json["message"] == "No account with that username!"
