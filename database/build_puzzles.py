"""Source of truth for CodeBud puzzle content.

Puzzles are drawn as ASCII maps so they are easy to read and edit:

    S  start      G  goal (star)      #  rock      .  free cell

Each puzzle is checked with the backend game engine before it is written out:
  * start and goal must be free and the goal must be reachable;
  * the reference solution (if given) must reach the goal;
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

CONDITIONAL = [
    ("Look Ahead", ["S.#..",
                    "...#.",
                    "....G",
                    ".....",
                    "....."],
     [loop(4, when("obstacle_right", "Down"), "Right")]),
    ("Edge of the World", ["S..#.",
                           ".....",
                           "....G",
                           ".....",
                           "....."],
     [loop(5, when("obstacle_right", "Down"), "Right")]),
    ("Look Down", ["S....",
                   "#....",
                   ".#...",
                   "..#..",
                   "...#G"],
     [loop(4, when("obstacle_down", "Right"), "Down")]),
    ("Find the Star", [".....",
                       "S....",
                       "####G",
                       ".....",
                       "....."],
     [loop(4, "Right", when("goal_down", "Down"))]),
    ("Fall Down", ["S....",
                   ".....",
                   ".#...",
                   ".....",
                   "....G"],
     [loop(5, when("empty_down", "Down"), "Right")]),
    ("Wall Follower", ["S.#..",
                       "....#",
                       ".....",
                       "....G",
                       "....."],
     [loop(5, when("obstacle_right", "Down"), "Right")]),
    ("Down the Cliff", ["S....",
                        ".....",
                        "#....",
                        ".....",
                        ".#.G."],
     [loop(5, when("obstacle_down", "Right"), "Down")]),
    ("Long Staircase", ["S..#..",
                        "....#.",
                        "......",
                        ".....G",
                        "......",
                        "......"],
     [loop(6, when("obstacle_right", "Down"), "Right")]),
    ("Bumpy Road", ["......",
                    "......",
                    "......",
                    "......",
                    "......",
                    "S#.#.G"],
     [loop(5, when("obstacle_right", "Up"), "Right", when("empty_down", "Down"))]),
    ("Clever Robot", ["......",
                      "......",
                      "......",
                      "......",
                      "......",
                      "S#..#G"],
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


def build_one(pid: str, category: str, order: int, title: str, rows: list[str], solution=None) -> dict:
    puzzle = {"id": pid, "category": category, "order": order, "title": title, **parse_map(rows)}
    board = engine.Board.from_puzzle(puzzle)

    path = engine.shortest_path(board)
    if path is None:
        raise ValueError(f"{pid}: goal is not reachable")

    if solution is None:
        solution = [{"type": m} for m in path]
    solution = engine.normalize_program(solution)
    result = engine.run(board, solution)
    if not result.solved:
        raise ValueError(f"{pid}: reference solution fails with status {result.status!r} at {result.path[-1]}")

    puzzle["par"] = min(engine.count_blocks(solution), len(path))
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
        board = engine.Board.from_puzzle(p)
        shortest = len(engine.shortest_path(board))
        print(f"{p['id']:7} {p['gridSize']}x{p['gridSize']}  par={p['par']:2}  shortest path={shortest:2}  {p['title']}")

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
