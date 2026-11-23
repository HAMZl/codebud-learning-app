def test_list_puzzles_in_order_with_progress(client, auth_header, db):
    db.progress.insert_one({"username": "tommy", "puzzle_id": "seq2", "stars": 2})

    res = client.get("/api/puzzles/sequence", headers=auth_header)
    assert res.status_code == 200
    puzzles = res.json["puzzles"]

    assert [p["id"] for p in puzzles] == [f"seq{i}" for i in range(1, 11)]  # numeric, not "seq10" after "seq1"
    assert puzzles[1]["best_stars"] == 2
    assert puzzles[1]["stars"] == ["yellow", "yellow", "gray"]  # legacy field
    assert puzzles[0]["best_stars"] == 0
    assert all("solution" not in p and "_id" not in p for p in puzzles)


def test_list_puzzles_unknown_category(client, auth_header):
    assert client.get("/api/puzzles/nope", headers=auth_header).status_code == 404


def test_list_puzzles_requires_login(client):
    assert client.get("/api/puzzles/sequence").status_code == 401


def test_get_puzzle_hides_solution_and_links_next(client):
    res = client.get("/api/puzzle/loop3")
    assert res.status_code == 200
    assert res.json["id"] == "loop3"
    assert "solution" not in res.json
    assert res.json["next"] == {"id": "loop4", "title": "Loop and Step"}


def test_last_puzzle_in_category_has_no_next(client):
    assert client.get("/api/puzzle/cond10").json["next"] is None


def test_get_puzzle_not_found(client):
    res = client.get("/api/puzzle/unknown")
    assert res.status_code == 404
    assert "error" in res.json


def test_validate_legacy_sequence(client):
    res = client.post("/api/validate_sequence", json={"puzzle_id": "seq1", "sequence": ["Right"] * 3})
    assert res.status_code == 200
    assert res.json["status"] == "success"
    assert res.json["valid"] is True
    assert res.json["stars"] == 3


def test_validate_program_with_loop(client):
    program = [{"type": "Loop", "repeat": 4, "body": [{"type": "Right"}]}]
    res = client.post("/api/validate_sequence", json={"puzzle_id": "loop1", "program": program})
    assert res.json["status"] == "success"
    assert res.json["blocks"] == 2


def test_validate_reports_wall_hint(client):
    res = client.post("/api/validate_sequence", json={"puzzle_id": "seq1", "sequence": ["Up", "Up"]})
    assert res.json["status"] == "wall"
    assert res.json["valid"] is False
    assert "wall" in res.json["hint"]


def test_validate_rejects_malformed_program(client):
    res = client.post("/api/validate_sequence", json={"puzzle_id": "seq1", "program": [{"type": "Jump"}]})
    assert res.status_code == 400
    assert "Unknown block" in res.json["message"]
