import pytest
from unittest.mock import patch

def test_create_new_progress(client, mock_db_progress):
    mock_db_progress.find_one.return_value = None

    with patch("flask_jwt_extended.view_decorators.verify_jwt_in_request", return_value=None), \
         patch("flask_jwt_extended.get_jwt_identity", return_value="testuser"), \
         patch("flask_jwt_extended.utils.get_jwt", return_value={"sub": "testuser"}):
        
        response = client.post("/api/progress", json={
            "puzzle_id": "p1",
            "status": "completed",
            "stars": 3,
            "updated_at": "2025-07-18"
        }, headers={"Authorization": "Bearer faketoken"})

    assert response.status_code == 201
    assert response.json["message"] == "Progress created"

def test_update_progress_with_more_stars(client, mock_db_progress):
    mock_db_progress.find_one.return_value = {
        "_id": "abc123",
        "username": "testuser",
        "puzzle_id": "p1",
        "stars": 1
    }

    with patch("flask_jwt_extended.view_decorators.verify_jwt_in_request", return_value=None), \
         patch("flask_jwt_extended.get_jwt_identity", return_value="testuser"), \
         patch("flask_jwt_extended.utils.get_jwt", return_value={"sub": "testuser"}):

        response = client.post("/api/progress", json={
            "puzzle_id": "p1",
            "status": "completed",
            "stars": 3,
            "updated_at": "2025-07-18"
        }, headers={"Authorization": "Bearer faketoken"})

    assert response.status_code == 200
    assert response.json["message"] == "Progress updated"

def test_update_progress_with_fewer_stars(client, mock_db_progress):
    mock_db_progress.find_one.return_value = {
        "_id": "abc123",
        "username": "testuser",
        "puzzle_id": "p1",
        "stars": 3
    }

    with patch("flask_jwt_extended.view_decorators.verify_jwt_in_request", return_value=None), \
         patch("flask_jwt_extended.get_jwt_identity", return_value="testuser"), \
         patch("flask_jwt_extended.utils.get_jwt", return_value={"sub": "testuser"}):

        response = client.post("/api/progress", json={
            "puzzle_id": "p1",
            "status": "completed",
            "stars": 2,
            "updated_at": "2025-07-18"
        }, headers={"Authorization": "Bearer faketoken"})

    assert response.status_code == 200
    assert response.json["message"] == "No update needed (equal or lower stars)"
