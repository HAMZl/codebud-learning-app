def post_progress(client, headers, **body):
    return client.post("/api/progress", json=body, headers=headers)


def moves(*names):
    return [{"type": n} for n in names]


def test_create_progress_from_program(client, auth_header, db):
    res = post_progress(client, auth_header, puzzle_id="seq1", program=moves("Right", "Right", "Right"))
    assert res.status_code == 201
    assert res.json["message"] == "Progress created"
    assert res.json["stars"] == 3
    assert db.progress.find_one({"username": "tommy", "puzzle_id": "seq1"})["stars"] == 3


def test_server_computes_stars_from_program(client, auth_header):
    # loop1 has par 2 (a 4x Right loop). Four separate moves use 4 blocks, which is 2 stars.
    res = post_progress(client, auth_header, puzzle_id="loop1", program=moves("Right", "Right", "Right", "Right"))
    assert res.json["stars"] == 2


def test_unsolved_program_is_rejected(client, auth_header, db):
    res = post_progress(client, auth_header, puzzle_id="seq1", program=moves("Right"))
    assert res.status_code == 422
    assert res.json["status"] == "incomplete"
    assert db.progress.count_documents({}) == 0


def test_best_stars_are_kept(client, auth_header, db):
    post_progress(client, auth_header, puzzle_id="seq1", stars=1)

    res = post_progress(client, auth_header, puzzle_id="seq1", stars=3)
    assert res.json["message"] == "Progress updated"

    res = post_progress(client, auth_header, puzzle_id="seq1", stars=2)
    assert res.json["message"] == "No update needed (equal or lower stars)"
    assert res.json["best_stars"] == 3
    assert db.progress.find_one({"puzzle_id": "seq1"})["stars"] == 3
    assert db.progress.count_documents({}) == 1


def test_legacy_stars_are_validated(client, auth_header):
    assert post_progress(client, auth_header, puzzle_id="seq1", stars=99).status_code == 400


def test_progress_for_unknown_puzzle(client, auth_header):
    assert post_progress(client, auth_header, puzzle_id="nope", stars=3).status_code == 404


def test_progress_requires_login(client):
    assert client.post("/api/progress", json={"puzzle_id": "seq1", "stars": 3}).status_code == 401


def test_progress_summary(client, auth_header):
    post_progress(client, auth_header, puzzle_id="seq1", stars=3)
    post_progress(client, auth_header, puzzle_id="seq2", stars=2)

    res = client.get("/api/progress", headers=auth_header)
    assert res.status_code == 200
    cats = res.json["categories"]
    assert cats["sequence"] == {"total": 10, "completed": 2, "stars": 5, "max_stars": 30}
    assert cats["loop"]["completed"] == 0


def test_reset_one_category(client, auth_header, parent_header, db):
    post_progress(client, auth_header, puzzle_id="seq1", stars=3)
    post_progress(client, auth_header, puzzle_id="loop1", stars=3)

    res = client.delete("/api/progress?category=sequence", headers=parent_header)
    assert res.status_code == 200
    assert res.json["removed"] == 1
    assert [p["puzzle_id"] for p in db.progress.find()] == ["loop1"]


def test_reset_all_progress_only_affects_this_player(client, auth_header, parent_header, db):
    db.progress.insert_one({"username": "someone-else", "puzzle_id": "seq1", "stars": 3})
    post_progress(client, auth_header, puzzle_id="seq1", stars=3)

    assert client.delete("/api/progress", headers=parent_header).json["removed"] == 1
    assert db.progress.count_documents({"username": "someone-else"}) == 1


def test_reset_unknown_category(client, parent_header):
    assert client.delete("/api/progress?category=nope", headers=parent_header).status_code == 404


def test_reset_needs_a_parent_token(client, auth_header, db):
    post_progress(client, auth_header, puzzle_id="seq1", stars=3)
    res = client.delete("/api/progress", headers=auth_header)
    assert res.status_code == 403
    assert res.json["error"] == "parent_required"
    assert db.progress.count_documents({}) == 1


def test_multi_board_puzzle_must_be_solved_on_every_board(client, auth_header, puzzle_data):
    # cond2 has two boards. These plain moves solve the first board but hit a rock on the second.
    first_board_only = moves("Right", "Down", "Right", "Down", "Right", "Right")
    res = post_progress(client, auth_header, puzzle_id="cond2", program=first_board_only)
    assert res.status_code == 422
    assert res.json["board"] == 1
    assert [b["status"] for b in res.json["boards"]] == ["success", "obstacle"]

    solution = next(p["solution"] for p in puzzle_data if p["id"] == "cond2")
    res = post_progress(client, auth_header, puzzle_id="cond2", program=solution)
    assert res.status_code == 201
    assert res.json["stars"] == 3
