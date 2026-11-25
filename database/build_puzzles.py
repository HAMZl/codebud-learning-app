"""Source of truth for CodeBud puzzle content.

Puzzles are drawn as ASCII maps so they are easy to read and edit:

    S  start      G  goal (star)      #  rock      .  free cell

A puzzle can have several boards of the same size (a list of maps). One program
has to solve all of them, which is how conditional levels make If blocks matter.

Each puzzle is checked with the backend game engine before it is written out:
  * start and goal must be free and the goal must be reachable on every board;
  * the reference solution (if given) must reach the goal on every board;
  * a puzzle with several boards must not be solvable with plain moves alone;
  * ``par`` (the block count for 3 stars) is the smaller of the reference
    solution's block count and the shortest plain-move path.
Sequence puzzles do not need a reference solution. Their shortest path is used.

Regenerate puzzles.json after editing:

    python database/build_puzzles.py

To check, without writing, that puzzles.json matches this file (CI runs this):

    python database/build_puzzles.py --check
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent / "backend"))

from codebud import engine  # noqa: E402

OUTPUT = ROOT / "puzzles.json"


# --- tiny DSL for reference solutions -------------------------------------------------

def loop(times: int, *body):
    return {"type": "Loop", "repeat": times, "body": [_block(b) for b in body]}


def when(condition: str, *body):
    return {"type": "If", "condition": condition, "body": [_block(b) for b in body]}


def _block(b):
    return {"type": b} if isinstance(b, str) else b


# --- puzzle definitions ---------------------------------------------------------------

SEQUENCE = [
    ("First Steps", ["....",
                     "S..G",
                     "....",
                     "...."]),
    ("Going Down", [".S..",
                    "....",
                    "....",
                    ".G.."]),
    ("Hidden Star", [".....",
                     ".###.",
                     ".#G#.",
                     ".#.#.",
                     "S...."]),
    ("Turn the Corner", ["S...",
                         "....",
                         "....",
                         "...G"]),
    ("Around the Rock", [".....",
                         ".....",
                         "S.#.G",
                         ".....",
                         "....."]),
    ("The Wall", ["S.#..",
                  "..#..",
                  "..#.G",
                  ".....",
                  "....."]),
    ("Rocky Road", ["..S..",
                    ".###.",
                    ".....",
                    ".#.#.",
                    ".#G#."]),
    ("Zig Zag", ["S#...",
                 ".#.#.",
                 ".#.#.",
                 "...#G",
                 "....."]),
    ("Up and Over", [".....",
                     ".....",
                     "..#..",
                     "..#..",
                     "S.#.G"]),
    ("Long Way Home", ["G#...",
                       ".#.#.",
                       ".#.#.",
                       ".#.#.",
                       "...#S"]),
]

LOOP = [
    ("Repeat Right", [".....",
                      ".....",
                      "S...G",
                      ".....",
                      "....."],
     [loop(4, "Right")]),
    ("Repeat Down", ["..S..",
                     ".....",
                     ".....",
                     ".....",
                     "..G.."],
     [loop(4, "Down")]),
    ("Two Loops", ["S....",
                   ".....",
                   ".....",
                   ".....",
                   "....G"],
     [loop(4, "Right"), loop(4, "Down")]),
    ("Loop and Step", [".....",
                       "S...#",
                       "....G",
                       ".....",
                       "....."],
     [loop(3, "Right"), "Down", "Right"]),
    ("Staircase", ["S#...",
                   "..#..",
                   "...#.",
                   "....#",
                   "....G"],
     [loop(4, "Down", "Right")]),
    ("Climb Up", ["...#G",
                  "..#..",
                  ".#...",
                  "#....",
                  "S...."],
     [loop(4, "Right", "Up")]),
    ("Big Steps", ["S....",
                   "##...",
                   ".....",
                   "..##.",
                   "....G"],
     [loop(2, "Right", "Right", "Down", "Down")]),
    ("Down and Back", ["S.#.G",
                       "..#..",
                       "..#..",
                       "..#..",
                       "....."],
     [loop(4, "Down"), loop(4, "Right"), loop(4, "Up")]),
    ("Spiral", ["S....",
                "####.",
                ".G.#.",
                ".###.",
                "....."],
     [loop(4, "Right"), loop(4, "Down"), loop(4, "Left"), loop(2, "Up"), "Right"]),
    ("Snake", ["S....",
               "####.",
               ".....",
               ".####",
               "....G"],
     [loop(4, "Right"), loop(2, "Down"), loop(4, "Left"), loop(2, "Down"), loop(4, "Right")]),
]

# Most conditional levels have several boards: the rocks (and sometimes the star) move,
# and one program has to solve every board. No list of plain moves can do that, so the
# robot has to look before it moves. The build checks this for every multi-board level.
CONDITIONAL = [
    ("Look Ahead", ["S.#..",
                    "...#.",
                    "....G",
                    ".....",
                    "....."],
     [loop(4, when("obstacle_right", "Down"), "Right")]),
    ("Rocks on the Move", [["S.#..",
                            "#..#.",
                            "....G",
                            ".....",
                            "....."],
                           ["S#...",
                            "..#..",
                            "....G",
                            ".....",
                            "....."]],
     [loop(4, when("obstacle_right", "Down"), "Right")]),
    ("Find the Star", [[".....",
                        "S....",
                        "###G#",
                        ".....",
                        "....."],
                       [".....",
                        "S....",
                        "####G",
                        ".....",
                        "....."]],
     [loop(4, "Right", when("goal_down", "Down"))]),
    ("Look Down", [["S#...",
                    ".....",
                    "#....",
                    ".#...",
                    "..G.."],
                   ["S....",
                    "#....",
                    ".#...",
                    ".....",
                    "..G.."]],
     [loop(4, when("obstacle_down", "Right"), "Down")]),
    ("Fall Down", [["S....",
                    ".....",
                    "...##",
                    "....G",
                    "...#."],
                   ["S....",
                    "#....",
                    ".##.G",
                    ".....",
                    "....."]],
     [loop(4, when("empty_down", "Down"), "Right")]),
    ("Star Hunt", [["......",
                    "S.....",
                    "##G###",
                    "......",
                    "......",
                    "......"],
                   ["......",
                    "S.....",
                    "####G#",
                    "......",
                    "......",
                    "......"],
                   ["......",
                    "S.....",
                    "#####G",
                    "......",
                    "......",
                    "......"]],
     [loop(5, "Right", when("goal_down", "Down"))]),
    ("Rocky Steps", [["S.##..",
                      ".....G",
                      ".#.#..",
                      "......",
                      "......",
                      "......"],
                     ["S#....",
                      "..#..#",
                      ".....G",
                      ".#....",
                      "......",
                      "......"],
                     ["S....#",
                      "##...G",
                      ".....#",
                      "......",
                      "......",
                      "......"]],
     [loop(5, when("obstacle_right", "Down"), "Right")]),
    ("Down the Cliff", [["S#....",
                         "......",
                         "......",
                         "#.#...",
                         "......",
                         ".G...."],
                        ["S.....",
                         "#.....",
                         "......",
                         "......",
                         "...#..",
                         ".#G..."]],
     [loop(5, when("obstacle_down", "Right"), "Down")]),
    ("Bumpy Road", [["......",
                     "......",
                     "......",
                     "......",
                     "......",
                     "S#.#.G"],
                    ["......",
                     "......",
                     "......",
                     "......",
                     "#.....",
                     "S.#..G"]],
     [loop(5, when("obstacle_right", "Up"), "Right", when("empty_down", "Down"))]),
    ("Clever Robot", [["......",
                       "......",
                       "......",
                       "......",
                       "......",
                       "S#..#G"],
                      ["......",
                       "......",
                       "......",
                       "......",
                       "#.....",
                       "S.#.#G"],
                      ["......",
                       "......",
                       "......",
                       "......",
                       "#.....",
                       "S..##G"]],
     [loop(5, when("obstacle_right", "Up"), "Right", when("empty_down", "Down"))]),
]

CATEGORIES = [
    ("sequence", "seq", SEQUENCE),
    ("loop", "loop", LOOP),
    ("conditional", "cond", CONDITIONAL),
]


# --- build ---------------------------------------------------------------------------

def parse_map(rows: list[str]) -> dict:
    size = len(rows)
    obstacles, start, goal = [], None, None
    for r, line in enumerate(rows):
        if len(line) != size:
            raise ValueError(f"map must be square, row {r} is {len(line)} wide (expected {size})")
        for c, ch in enumerate(line):
            if ch == "#":
                obstacles.append([r, c])
            elif ch == "S":
                start = [r, c]
            elif ch == "G":
                goal = [r, c]
            elif ch != ".":
                raise ValueError(f"unknown map symbol {ch!r}")
    if start is None or goal is None:
        raise ValueError("map needs exactly one S and one G")
    return {"gridSize": size, "start": start, "goal": goal, "obstacles": obstacles}


def build_one(pid: str, category: str, order: int, title: str, maps: list, solution=None) -> dict:
    # A single board is a list of rows; several boards are a list of those.
    boards = [parse_map(m) for m in (maps if isinstance(maps[0], list) else [maps])]
    if any(b["gridSize"] != boards[0]["gridSize"] for b in boards):
        raise ValueError(f"{pid}: every board must be the same size")
    puzzle = {"id": pid, "category": category, "order": order, "title": title, **boards[0]}
    if len(boards) > 1:
        puzzle["variants"] = [{k: b[k] for k in ("start", "goal", "obstacles")} for b in boards[1:]]

    for i, board in enumerate(engine.boards_of(puzzle), start=1):
        if engine.shortest_path(board) is None:
            raise ValueError(f"{pid}: the goal on board {i} is not reachable")
    common = engine.shortest_common_path(engine.boards_of(puzzle))
    if len(boards) > 1 and common is not None:
        raise ValueError(f"{pid}: plain moves {common} solve every board, so no If block is needed")

    if solution is None:
        solution = [{"type": m} for m in common]
    solution = engine.normalize_program(solution)
    result = engine.run_puzzle(puzzle, solution)
    if not result.solved:
        raise ValueError(
            f"{pid}: reference solution fails on board {result.board + 1} "
            f"with status {result.status!r} at {result.path[-1]}"
        )

    blocks = engine.count_blocks(solution)
    puzzle["par"] = blocks if common is None else min(blocks, len(common))
    puzzle["solution"] = solution
    return puzzle


def build_all() -> list[dict]:
    puzzles = []
    for category, prefix, defs in CATEGORIES:
        for i, d in enumerate(defs, start=1):
            puzzles.append(build_one(f"{prefix}{i}", category, i, *d))
    return puzzles


def render(puzzles: list[dict]) -> str:
    return json.dumps(puzzles, indent=2) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--check", action="store_true", help="fail if puzzles.json is out of date")
    args = parser.parse_args()

    try:
        puzzles = build_all()
    except ValueError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1

    for p in puzzles:
        boards = engine.boards_of(p)
        common = engine.shortest_common_path(boards)
        plain = f"plain moves={len(common):2}" if common else "needs an If  "
        print(f"{p['id']:7} {p['gridSize']}x{p['gridSize']}  boards={len(boards)}  par={p['par']:2}  {plain}  {p['title']}")

    text = render(puzzles)
    if args.check:
        if not OUTPUT.exists() or OUTPUT.read_text(encoding="utf-8") != text:
            print(f"error: {OUTPUT.name} is out of date, run: python database/build_puzzles.py", file=sys.stderr)
            return 1
        print(f"{OUTPUT.name} is up to date")
        return 0

    OUTPUT.write_text(text, encoding="utf-8", newline="\n")
    print(f"wrote {len(puzzles)} puzzles to {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
