from datetime import datetime, timezone

from flask import Blueprint, jsonify
from flask_jwt_extended import get_jwt_identity, jwt_required
from pymongo import ReturnDocument

from .. import engine
from ..db import PROGRESS, PUZZLES, get_db
from ..errors import ApiError
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
    """
    data = json_body()
    puzzle = find_puzzle(data.get("puzzle_id"))

    if "program" in data:
        program = parse_program(data)
        result = engine.run(engine.Board.from_puzzle(puzzle), program, puzzle.get("par"))
        if not result.solved:
            raise ApiError("That program doesn't solve the puzzle yet.", code=422, **result.to_dict())
        stars = result.stars
    else:
        stars = int_in_range(data.get("stars"), "stars", "Stars", 0, 3)

    now = datetime.now(timezone.utc)
    before = get_db()[PROGRESS].find_one_and_update(
        {"username": get_jwt_identity(), "puzzle_id": puzzle["id"]},
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
    """Per-category totals for the home screen."""
    db = get_db()
    totals = {c: {"total": 0, "completed": 0, "stars": 0, "max_stars": 0} for c in CATEGORIES}
    category_of = {}
    for p in db[PUZZLES].find({}, {"_id": 0, "id": 1, "category": 1}):
        if p.get("category") in totals:
            category_of[p["id"]] = p["category"]
            totals[p["category"]]["total"] += 1
            totals[p["category"]]["max_stars"] += 3

    for row in db[PROGRESS].find({"username": get_jwt_identity()}, {"_id": 0, "puzzle_id": 1, "stars": 1}):
        category = category_of.get(row["puzzle_id"])
        if category:
            totals[category]["completed"] += 1
            totals[category]["stars"] += row.get("stars", 0)

    return jsonify({"categories": totals})
