"""Load puzzles.json into MongoDB and create indexes.

    MONGO_URI="mongodb+srv://..." python database/seed.py

Puzzles are upserted by ``id``, so running the script again updates existing
puzzles without touching users or progress. Pass ``--prune`` to also delete
puzzles that are no longer in puzzles.json.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from pymongo import MongoClient, ReplaceOne

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent / "backend"))

from codebud.db import PUZZLES, ensure_indexes  # noqa: E402


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--prune", action="store_true", help="delete puzzles that are not in puzzles.json")
    parser.add_argument("--db", default=os.getenv("MONGO_DB_NAME", "codebud"), help="database name")
    args = parser.parse_args()

    load_dotenv(ROOT / ".env")
    load_dotenv(ROOT.parent / "backend" / ".env")
    uri = os.getenv("MONGO_URI")
    if not uri:
        print("error: set MONGO_URI (or add it to database/.env or backend/.env)", file=sys.stderr)
        return 1

    puzzles = json.loads((ROOT / "puzzles.json").read_text(encoding="utf-8"))
    db = MongoClient(uri, serverSelectionTimeoutMS=10000)[args.db]
    db.command("ping")
    print(f"Connected to MongoDB, database '{args.db}'")

    ensure_indexes(db)
    result = db[PUZZLES].bulk_write([ReplaceOne({"id": p["id"]}, p, upsert=True) for p in puzzles])
    print(f"Puzzles: {result.upserted_count} inserted, {result.modified_count} updated")

    if args.prune:
        removed = db[PUZZLES].delete_many({"id": {"$nin": [p["id"] for p in puzzles]}})
        print(f"Puzzles: {removed.deleted_count} removed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
