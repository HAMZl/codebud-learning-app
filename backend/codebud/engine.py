"""Pure game logic for CodeBud puzzles.

This module has no Flask or MongoDB dependencies so it can be unit tested in
isolation and reused by the API, the progress endpoint, and the puzzle content
tests. ``frontend/flutter_app/lib/game/engine.dart`` mirrors these rules; keep
the two in sync.

A *program* is a list of blocks::

    [
        {"type": "Right"},
        {"type": "Loop", "repeat": 3, "body": [{"type": "Down"}]},
        {"type": "If", "condition": "obstacle_right", "body": [{"type": "Down"}]},
    ]

Rules:
  * Moves are Up / Down / Left / Right, one grid cell each.
  * ``Loop`` runs its body ``repeat`` times. A loop body may hold moves and ``If`` blocks.
  * ``If`` runs its body only when the neighbouring cell in the given direction
    matches the target. Targets are ``obstacle`` (a rock or the grid edge),
    ``empty`` (a free cell, which includes the goal), and ``goal``. An ``If``
    body may only hold moves.
  * The run stops as soon as the robot reaches the goal.
  * A puzzle can have ``variants``: extra boards of the same size where the
    rocks (and sometimes the start or the goal) are somewhere else. One
    program must solve every board. A fixed list of moves usually can't, so
    these puzzles are where ``If`` blocks earn their place.
  * Stars reward short programs. Every block counts once, including the blocks
    nested in a Loop or If. At or under ``par`` earns 3 stars, up to ``par + 2``
    earns 2, and any other solution earns 1. Finishing a puzzle never earns 0.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Iterable

MOVES: dict[str, tuple[int, int]] = {
    "Up": (-1, 0),
    "Down": (1, 0),
    "Left": (0, -1),
    "Right": (0, 1),
}
DIRECTIONS: dict[str, tuple[int, int]] = {k.lower(): v for k, v in MOVES.items()}
TARGETS = ("obstacle", "empty", "goal")

MAX_REPEAT = 10
MAX_BLOCKS = 60
MAX_DEPTH = 2  # top level -> loop -> if

# Result statuses
SUCCESS = "success"
WALL = "wall"
OBSTACLE = "obstacle"
INCOMPLETE = "incomplete"

HINTS = {
    WALL: "Oops! You're bumping into a wall.",
    OBSTACLE: "Watch out! There's an obstacle in the way.",
    INCOMPLETE: "Hmm... you didn't reach the goal. Try changing your moves.",
}

Cell = tuple[int, int]


class ProgramError(ValueError):
    """Raised when a program is malformed, e.g. an unknown block or a bad repeat count."""


@dataclass(frozen=True)
class Board:
    size: int
    start: Cell
    goal: Cell
    obstacles: frozenset[Cell]

    @classmethod
    def from_puzzle(cls, puzzle: dict[str, Any]) -> "Board":
        return cls(
            size=int(puzzle["gridSize"]),
            start=_cell(puzzle["start"]),
            goal=_cell(puzzle["goal"]),
            obstacles=frozenset(_cell(o) for o in puzzle.get("obstacles", [])),
        )

    def in_bounds(self, cell: Cell) -> bool:
        return 0 <= cell[0] < self.size and 0 <= cell[1] < self.size

    def is_blocked(self, cell: Cell) -> bool:
        return not self.in_bounds(cell) or cell in self.obstacles


def boards_of(puzzle: dict[str, Any]) -> list[Board]:
    """The puzzle's main board followed by its variants. A program has to solve all of them."""
    main = Board.from_puzzle(puzzle)
    boards = [main]
    for variant in puzzle.get("variants") or []:
        boards.append(
            Board(
                size=main.size,
                start=_cell(variant["start"]) if "start" in variant else main.start,
                goal=_cell(variant["goal"]) if "goal" in variant else main.goal,
                obstacles=frozenset(_cell(o) for o in variant.get("obstacles", [])),
            )
        )
    return boards


@dataclass
class RunResult:
    status: str
    path: list[Cell] = field(default_factory=list)
    blocks: int = 0
    stars: int = 0
    # Set by run_puzzle: which board ``path`` belongs to, and the result on every board.
    board: int = 0
    boards: list["RunResult"] = field(default_factory=list)

    @property
    def solved(self) -> bool:
        return self.status == SUCCESS

    @property
    def hint(self) -> str | None:
        return HINTS.get(self.status)

    def to_dict(self) -> dict[str, Any]:
        data: dict[str, Any] = {
            "status": self.status,
            "path": [list(c) for c in self.path],
            "steps": max(len(self.path) - 1, 0),
            "blocks": self.blocks,
            "stars": self.stars,
        }
        if self.hint:
            data["hint"] = self.hint
        if len(self.boards) > 1:
            data["board"] = self.board
            data["boards"] = [{"status": r.status, "path": [list(c) for c in r.path]} for r in self.boards]
        return data


def _cell(value: Iterable[Any]) -> Cell:
    row, col = list(value)
    return int(row), int(col)


def stars_for(blocks: int, par: int) -> int:
    if blocks <= par:
        return 3
    if blocks <= par + 2:
        return 2
    return 1


def normalize_program(raw: Any) -> list[dict[str, Any]]:
    """Validate a program and convert it to canonical form.

    Bare strings like ``"Up"`` are accepted as moves, so legacy clients that
    send ``["Up", "Right"]`` still work. Raises ProgramError on bad input.
    """
    if not isinstance(raw, list):
        raise ProgramError("Program must be a list of blocks.")
    program = [_normalize_block(b, depth=0) for b in raw]
    if count_blocks(program) > MAX_BLOCKS:
        raise ProgramError(f"Program is too long (max {MAX_BLOCKS} blocks).")
    return program


def _normalize_block(raw: Any, depth: int) -> dict[str, Any]:
    if isinstance(raw, str):
        raw = {"type": raw}
    if not isinstance(raw, dict):
        raise ProgramError("Each block must be an object or a move name.")

    kind = raw.get("type")
    if kind in MOVES:
        return {"type": kind}

    if kind not in ("Loop", "If"):
        raise ProgramError(f"Unknown block type: {kind!r}.")
    if depth >= MAX_DEPTH:
        raise ProgramError(f"{kind} blocks are nested too deeply.")

    body_raw = raw.get("body", raw.get("nested", []))
    if not isinstance(body_raw, list):
        raise ProgramError(f"{kind} body must be a list.")
    body = [_normalize_block(b, depth + 1) for b in body_raw]

    if kind == "Loop":
        if any(b["type"] == "Loop" for b in body):
            raise ProgramError("Loops cannot contain other loops.")
        repeat = raw.get("repeat", raw.get("repeatCount"))
        if not isinstance(repeat, int) or isinstance(repeat, bool) or not 1 <= repeat <= MAX_REPEAT:
            raise ProgramError(f"Loop repeat must be a whole number from 1 to {MAX_REPEAT}.")
        return {"type": "Loop", "repeat": repeat, "body": body}

    if any(b["type"] not in MOVES for b in body):
        raise ProgramError("If blocks can only contain moves.")
    condition = raw.get("condition")
    parse_condition(condition)
    return {"type": "If", "condition": condition, "body": body}


def parse_condition(condition: Any) -> tuple[str, str]:
    if not isinstance(condition, str) or "_" not in condition:
        raise ProgramError("If condition must look like 'obstacle_right'.")
    target, direction = condition.split("_", 1)
    if target not in TARGETS or direction not in DIRECTIONS:
        raise ProgramError(f"Unknown condition: {condition!r}.")
    return target, direction


def count_blocks(program: list[dict[str, Any]]) -> int:
    return sum(1 + count_blocks(b.get("body", [])) for b in program)


class _Stop(Exception):
    def __init__(self, status: str):
        self.status = status


def run(board: Board, program: list[dict[str, Any]], par: int | None = None) -> RunResult:
    """Execute a normalized program on a board."""
    pos = board.start
    path = [pos]

    def check(target: str, direction: str) -> bool:
        dr, dc = DIRECTIONS[direction]
        cell = (pos[0] + dr, pos[1] + dc)
        if target == "obstacle":
            return board.is_blocked(cell)
        if target == "goal":
            return cell == board.goal
        return not board.is_blocked(cell)

    def execute(blocks: list[dict[str, Any]]) -> None:
        nonlocal pos
        for block in blocks:
            kind = block["type"]
            if kind == "Loop":
                for _ in range(block["repeat"]):
                    execute(block["body"])
            elif kind == "If":
                if check(*parse_condition(block["condition"])):
                    execute(block["body"])
            else:
                dr, dc = MOVES[kind]
                nxt = (pos[0] + dr, pos[1] + dc)
                if not board.in_bounds(nxt):
                    raise _Stop(WALL)
                if nxt in board.obstacles:
                    raise _Stop(OBSTACLE)
                pos = nxt
                path.append(pos)
                if pos == board.goal:
                    raise _Stop(SUCCESS)

    try:
        execute(program)
        status = INCOMPLETE
    except _Stop as stop:
        status = stop.status

    blocks = count_blocks(program)
    stars = stars_for(blocks, par) if status == SUCCESS and par is not None else 0
    return RunResult(status=status, path=path, blocks=blocks, stars=stars)


def run_puzzle(puzzle: dict[str, Any], program: list[dict[str, Any]], par: int | None = None) -> RunResult:
    """Run a normalized program on every board of a puzzle.

    The result describes the first board the program fails on, or the first
    board when it solves them all. Stars are only awarded when every board is solved.
    """
    results = [run(board, program, par) for board in boards_of(puzzle)]
    failed = next((i for i, r in enumerate(results) if not r.solved), None)
    shown = results[failed or 0]
    return RunResult(
        status=shown.status,
        path=shown.path,
        blocks=shown.blocks,
        stars=shown.stars if failed is None else 0,
        board=failed or 0,
        boards=results,
    )


def shortest_common_path(boards: list[Board], max_len: int = 60) -> list[str] | None:
    """Return a shortest list of plain moves that solves every board, or None if there is none.

    The robots on all boards follow the same moves. A board is finished once its
    robot reaches the goal, and a move that bumps into anything on an unfinished
    board ends the search down that branch.
    """
    from collections import deque

    State = tuple[Cell | None, ...]
    start: State = tuple(None if b.start == b.goal else b.start for b in boards)
    came_from: dict[State, tuple[State, str] | None] = {start: None}
    queue = deque([(start, 0)])
    while queue:
        state, depth = queue.popleft()
        if all(pos is None for pos in state):
            moves: list[str] = []
            while (prev := came_from[state]) is not None:
                state, move = prev
                moves.append(move)
            return moves[::-1]
        if depth >= max_len:
            continue
        for move, (dr, dc) in MOVES.items():
            nxt: list[Cell | None] = []
            for board, pos in zip(boards, state):
                if pos is None:
                    nxt.append(None)
                    continue
                cell = (pos[0] + dr, pos[1] + dc)
                if board.is_blocked(cell):
                    break
                nxt.append(None if cell == board.goal else cell)
            else:
                key = tuple(nxt)
                if key not in came_from:
                    came_from[key] = (state, move)
                    queue.append((key, depth + 1))
    return None


def shortest_path(board: Board) -> list[str] | None:
    """Return a shortest list of moves from start to goal (BFS), or None if there is none."""
    from collections import deque

    if board.is_blocked(board.start) or board.is_blocked(board.goal):
        return None
    came_from: dict[Cell, tuple[Cell, str] | None] = {board.start: None}
    queue = deque([board.start])
    while queue:
        cell = queue.popleft()
        if cell == board.goal:
            moves: list[str] = []
            while (prev := came_from[cell]) is not None:
                cell, move = prev
                moves.append(move)
            return moves[::-1]
        for move, (dr, dc) in MOVES.items():
            nxt = (cell[0] + dr, cell[1] + dc)
            if nxt not in came_from and not board.is_blocked(nxt):
                came_from[nxt] = (cell, move)
                queue.append(nxt)
    return None
