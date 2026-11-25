"""Checks on the shipped puzzle data, so a broken level can't reach players."""

from collections import Counter

import pytest

from codebud import engine


def test_every_category_has_ten_puzzles(puzzle_data):
    assert Counter(p["category"] for p in puzzle_data) == {"sequence": 10, "loop": 10, "conditional": 10}


def test_ids_are_unique(puzzle_data):
    ids = [p["id"] for p in puzzle_data]
    assert len(ids) == len(set(ids))


@pytest.fixture(params=range(30), ids=lambda i: f"puzzle{i}")
def puzzle(request, puzzle_data):
    return puzzle_data[request.param]


def test_start_and_goal_are_free(puzzle):
    for board in engine.boards_of(puzzle):
        assert board.in_bounds(board.start) and board.start not in board.obstacles
        assert board.in_bounds(board.goal) and board.goal not in board.obstacles
        assert board.start != board.goal


def test_reference_solution_earns_three_stars(puzzle):
    result = engine.run_puzzle(puzzle, engine.normalize_program(puzzle["solution"]), puzzle["par"])
    assert result.solved, f"{puzzle['id']} solution ends with {result.status} on board {result.board + 1}"
    assert result.stars == 3


def test_par_is_not_beaten_by_plain_moves(puzzle):
    common = engine.shortest_common_path(engine.boards_of(puzzle))
    if common is not None:
        assert puzzle["par"] <= len(common)


def test_multi_board_puzzles_need_an_if_block(puzzle):
    if puzzle.get("variants"):
        assert puzzle["category"] == "conditional"
        assert engine.shortest_common_path(engine.boards_of(puzzle)) is None


def test_most_conditional_levels_have_moving_rocks(puzzle_data):
    multi = [p["id"] for p in puzzle_data if p["category"] == "conditional" and p.get("variants")]
    assert len(multi) >= 8
