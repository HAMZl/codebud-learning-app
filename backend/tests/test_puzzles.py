import pytest
from unittest.mock import patch

def test_get_puzzles_by_category(client, mock_db_puzzles, mock_db_progress):
    mock_db_puzzles.find.return_value = [
        {"_id": "mockid1", "id": "puzzle1", "category": "intro"},
        {"_id": "mockid2", "id": "puzzle2", "category": "intro"},
    ]
    mock_db_progress.find.return_value = [
        {"puzzle_id": "puzzle1", "stars": 2},
    ]

    with patch("flask_jwt_extended.view_decorators.verify_jwt_in_request", return_value=None), \
         patch("flask_jwt_extended.get_jwt_identity", return_value="testuser"), \
         patch("flask_jwt_extended.utils.get_jwt", return_value={"sub": "testuser"}):
        
        response = client.get("/api/puzzles/intro", headers={"Authorization": "Bearer faketoken"})

    assert response.status_code == 200
    data = response.get_json()
    assert "puzzles" in data
    assert len(data["puzzles"]) == 2
    assert data["puzzles"][0]["stars"] == ["yellow", "yellow", "gray"]

def test_get_puzzle_by_id_found(client, mock_db_puzzles):
    mock_db_puzzles.find_one.return_value = {
        "_id": "fake_id",
        "id": "puzzle123",
        "category": "intro"
    }

    response = client.get("/api/puzzle/puzzle123")
    assert response.status_code == 200
    assert response.json["id"] == "puzzle123"

def test_get_puzzle_by_id_not_found(client, mock_db_puzzles):
    mock_db_puzzles.find_one.return_value = None

    response = client.get("/api/puzzle/unknown")
    assert response.status_code == 404
    assert "error" in response.json
