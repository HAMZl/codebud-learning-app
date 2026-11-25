from datetime import datetime, timezone

from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required
from pymongo import ReturnDocument

from .. import engine
from ..db import PROGRESS, PUZZLES, get_db
from ..errors import ApiError
from ..family import current_user, find_child, parent_required
from ..validation import int_in_range, json_body
from .puzzles import CATEGORIES, find_puzzle, parse_program

bp = Blueprint("progress", __name__, url_prefix="/api")


@bp.post("/progress")
@jwt_required()
def save_progress():
    """Record a completed puzzle and keep the best star count.

    New clients send the ``program`` they ran. The server replays it and
    computes the stars itself, so clients can't award stars they didn't earn.
    Older clients send ``stars`` directly; that value is clamped to 0-3.
    ``child_id`` says whose progress it is. Without it, the first child's.
    """
    data = json_body()
    user = current_user()
    child = find_child(user, data.get("child_id"))
    puzzle = find_puzzle(data.get("puzzle_id"))

    if "program" in data:
        program = parse_program(data)
        result = engine.run_puzzle(puzzle, program, puzzle.get("par"))
        if not result.solved:
            raise ApiError("That program doesn't solve the puzzle yet.", code=422, **result.to_dict())
        stars = result.stars
    else:
        stars = int_in_range(data.get("stars"), "stars", "Stars", 0, 3)

    now = datetime.now(timezone.utc)
    before = get_db()[PROGRESS].find_one_and_update(
        {"username": user["username"], "child_id": child["id"], "puzzle_id": puzzle["id"]},
        {
            "$max": {"stars": stars},
            "$set": {"status": "completed", "last_played_at": now},
            "$setOnInsert": {"created_at": now},
        },
        upsert=True,
        return_document=ReturnDocument.BEFORE,
    )

    if before is None:
        return jsonify({"success": True, "message": "Progress created", "stars": stars, "best_stars": stars}), 201
    best = max(before.get("stars", 0), stars)
    if stars > before.get("stars", 0):
        return jsonify({"success": True, "message": "Progress updated", "stars": stars, "best_stars": best}), 200
    return jsonify(
        {"success": True, "message": "No update needed (equal or lower stars)", "stars": stars, "best_stars": best}
    ), 200


@bp.get("/progress")
@jwt_required()
def progress_summary():
    """Per-category totals for the home screen, for ``?child_id=`` (default: the first child)."""
    user = current_user()
    child = find_child(user, request.args.get("child_id"))
    db = get_db()
    totals = {c: {"total": 0, "completed": 0, "stars": 0, "max_stars": 0} for c in CATEGORIES}
    category_of = {}
    for p in db[PUZZLES].find({}, {"_id": 0, "id": 1, "category": 1}):
        if p.get("category") in totals:
            category_of[p["id"]] = p["category"]
            totals[p["category"]]["total"] += 1
            totals[p["category"]]["max_stars"] += 3

    rows = db[PROGRESS].find(
        {"username": user["username"], "child_id": child["id"]}, {"_id": 0, "puzzle_id": 1, "stars": 1}
    )
    for row in rows:
        category = category_of.get(row["puzzle_id"])
        if category:
            totals[category]["completed"] += 1
            totals[category]["stars"] += row.get("stars", 0)

    return jsonify({"categories": totals})


@bp.delete("/progress")
@parent_required
def reset_progress():
    """Erase one child's progress (``?child_id=``), either everything or one ``?category=``."""
    user = current_user()
    child = find_child(user, request.args.get("child_id"))
    db = get_db()
    query: dict = {"username": user["username"], "child_id": child["id"]}
    category = request.args.get("category")
    if category:
        if category not in CATEGORIES:
            raise ApiError(f"Unknown category: {category}", code=404)
        ids = [p["id"] for p in db[PUZZLES].find({"category": category}, {"_id": 0, "id": 1})]
        query["puzzle_id"] = {"$in": ids}
    removed = db[PROGRESS].delete_many(query).deleted_count
    return jsonify({"success": True, "message": "Progress reset.", "removed": removed})
