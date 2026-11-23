import pytest

from codebud import engine
from codebud.engine import Board, ProgramError, normalize_program, run

# 3x3 board: start top-left, goal bottom-right, rock in the middle.
BOARD = Board(size=3, start=(0, 0), goal=(2, 2), obstacles=frozenset({(1, 1)}))


def prog(*blocks):
    return normalize_program(list(blocks))


def test_simple_success_and_path():
    result = run(BOARD, prog("Right", "Right", "Down", "Down"), par=4)
    assert result.status == engine.SUCCESS
    assert result.path == [(0, 0), (0, 1), (0, 2), (1, 2), (2, 2)]
    assert result.stars == 3


def test_wall_and_obstacle():
    assert run(BOARD, prog("Up")).status == engine.WALL
    assert run(BOARD, prog("Right", "Down")).status == engine.OBSTACLE


def test_incomplete():
    result = run(BOARD, prog("Right"))
    assert result.status == engine.INCOMPLETE
    assert result.hint


def test_stops_when_goal_reached():
    # Extra moves after reaching the goal don't count as a crash.
    result = run(BOARD, prog("Down", "Down", "Right", "Right", "Right"))
    assert result.solved


def test_loop():
    result = run(BOARD, prog({"type": "Loop", "repeat": 2, "body": ["Right"]}, {"type": "Loop", "repeat": 2, "body": ["Down"]}), par=4)
    assert result.solved
    assert result.blocks == 4


@pytest.mark.parametrize(
    "condition, expected",
    [
        ("obstacle_down", True),   # the rock is below (0,1)
        ("empty_right", True),
        ("obstacle_up", True),     # the grid edge counts as an obstacle
        ("goal_down", False),
    ],
)
def test_conditions(condition, expected):
    program = prog("Right", {"type": "If", "condition": condition, "body": ["Right"]})
    result = run(BOARD, program)
    moved_again = result.path[-1] == (0, 2)
    assert moved_again is expected


def test_stars_scale_with_blocks():
    assert engine.stars_for(4, par=4) == 3
    assert engine.stars_for(6, par=4) == 2
    assert engine.stars_for(20, par=4) == 1  # finishing always earns at least one star


def test_legacy_field_names_are_accepted():
    program = normalize_program([{"type": "Loop", "repeatCount": 2, "nested": [{"type": "Right"}]}])
    assert program == [{"type": "Loop", "repeat": 2, "body": [{"type": "Right"}]}]


@pytest.mark.parametrize(
    "bad",
    [
        "Right",
        [{"type": "Jump"}],
        [{"type": "Loop", "repeat": 0, "body": []}],
        [{"type": "Loop", "repeat": 99, "body": []}],
        [{"type": "Loop", "repeat": True, "body": []}],
        [{"type": "Loop", "repeat": 2, "body": [{"type": "Loop", "repeat": 2, "body": []}]}],
        [{"type": "If", "condition": "lava_up", "body": []}],
        [{"type": "If", "condition": "goal_up", "body": [{"type": "If", "condition": "goal_up", "body": []}]}],
        ["Right"] * (engine.MAX_BLOCKS + 1),
    ],
)
def test_malformed_programs_are_rejected(bad):
    with pytest.raises(ProgramError):
        normalize_program(bad)


def test_shortest_path():
    assert len(engine.shortest_path(BOARD)) == 4
    walled = Board(size=3, start=(0, 0), goal=(2, 2), obstacles=frozenset({(1, 2), (2, 1)}))
    assert engine.shortest_path(walled) is None
