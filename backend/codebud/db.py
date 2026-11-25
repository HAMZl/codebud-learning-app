"""MongoDB access.

The database handle lives in ``app.extensions`` so tests can inject an
in-memory database (mongomock) instead of connecting to a real server.
"""

from flask import current_app
from pymongo import ASCENDING, MongoClient
from pymongo.database import Database

USERS = "users"
PUZZLES = "puzzles"
PROGRESS = "progress"


def connect(uri: str, db_name: str) -> Database:
    # connect=False defers the network connection until the first query, so
    # importing the app (for example under gunicorn or in tests) never blocks.
    client = MongoClient(uri, connect=False, serverSelectionTimeoutMS=5000)
    return client[db_name]


def get_db() -> Database:
    return current_app.extensions["codebud_db"]


def ensure_indexes(db: Database) -> None:
    db[USERS].create_index([("username", ASCENDING)], unique=True)
    db[PUZZLES].create_index([("id", ASCENDING)], unique=True)
    db[PUZZLES].create_index([("category", ASCENDING), ("order", ASCENDING)])
    # Before families, progress was unique per account. Now it is unique per child.
    if "username_1_puzzle_id_1" in db[PROGRESS].index_information():
        db[PROGRESS].drop_index("username_1_puzzle_id_1")
    db[PROGRESS].create_index(
        [("username", ASCENDING), ("child_id", ASCENDING), ("puzzle_id", ASCENDING)], unique=True
    )
