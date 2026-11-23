from typing import Any

from flask import Blueprint, jsonify
from flask_jwt_extended import get_jwt_identity, jwt_required

from .. import engine
from ..db import PROGRESS, PUZZLES, get_db
from ..errors import ApiError
from ..validation import json_body

bp = Blueprint("puzzles", __name__, url_prefix="/api")

CATEGORIES = ("sequence", "loop", "conditional")

# Fields that are never sent to clients. The reference solution would give the answer away.
_HIDDEN = {"_id": 0, "solution": 0}


def find_puzzle(puzzle_id: Any) -> dict[str, Any]:
    if not isinstance(puzzle_id, str) or not puzzle_id:
        raise ApiError("puzzle_id is required.")
    puzzle = get_db()[PUZZLES].find_one({"id": puzzle_id}, _HIDDEN)
    if not puzzle:
        raise ApiError("Puzzle not found", code=404, error="Puzzle not found")
    return puzzle


def legacy_star_colors(stars: int) -> list[str]:
    # Clients that are already deployed read this list of colours.
    return ["yellow" if i < stars else "gray" for i in range(3)]


@bp.get("/puzzles/<category>")
@jwt_required()
def list_puzzles(category: str):
    if category not in CATEGORIES:
        raise ApiError(f"Unknown category: {category}", code=404)

    db = get_db()
    puzzles = list(db[PUZZLES].find({"category": category}, _HIDDEN).sort("order", 1))
    progress = db[PROGRESS].find(
        {"username": get_jwt_identity(), "puzzle_id": {"$in": [p["id"] for p in puzzles]}},
        {"_id": 0, "puzzle_id": 1, "stars": 1},
    )
    best = {p["puzzle_id"]: p.get("stars", 0) for p in progress}

    for p in puzzles:
        p["best_stars"] = best.get(p["id"], 0)
        p["stars"] = legacy_star_colors(p["best_stars"])
    return jsonify({"puzzles": puzzles}), 200


@bp.get("/puzzle/<puzzle_id>")
def get_puzzle(puzzle_id: str):
    puzzle = find_puzzle(puzzle_id)
    nxt = get_db()[PUZZLES].find_one(
        {"category": puzzle.get("category"), "order": {"$gt": puzzle.get("order", 0)}},
        {"_id": 0, "id": 1, "title": 1},
        sort=[("order", 1)],
    )
    puzzle["next"] = nxt
    return jsonify(puzzle)


@bp.post("/validate_sequence")
def validate_sequence():
    """Run a program on a puzzle and say what happened.

    Accepts ``{"puzzle_id": ..., "program": [...]}``. The older
    ``{"sequence": ["Up", ...]}`` form is also accepted.
    """
    data = json_body()
    puzzle = find_puzzle(data.get("puzzle_id"))
    program = parse_program(data)
    result = engine.run(engine.Board.from_puzzle(puzzle), program, puzzle.get("par"))
    body = result.to_dict()
    # Older clients check for "valid" and "invalid".
    body["valid"] = result.solved
    if not result.solved:
        body.setdefault("hint", engine.HINTS[engine.INCOMPLETE])
    return jsonify(body)


def parse_program(data: dict[str, Any]) -> list[dict[str, Any]]:
    raw = data.get("program", data.get("sequence"))
    if raw is None:
        raise ApiError("program is required.")
    try:
        return engine.normalize_program(raw)
    except engine.ProgramError as e:
        raise ApiError(str(e))
