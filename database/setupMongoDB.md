# MongoDB Setup Guide for CodeBud

## 1. Get a MongoDB database

**Option A: MongoDB Atlas (recommended; this is what production uses).** Create a free cluster at
https://www.mongodb.com/atlas and copy its `mongodb+srv://...` connection string.

**Option B: local install.**

- Windows: install MongoDB Community Server (MSI) from https://www.mongodb.com/try/download/community and choose "Install MongoDB as a Service".
- macOS:
  ```bash
  brew tap mongodb/brew
  brew install mongodb-community
  brew services start mongodb-community
  ```

The local connection string is `mongodb://localhost:27017`.

## 2. Load the puzzles

From the repository root, with the backend virtual environment active:

```bash
export MONGO_URI="mongodb+srv://..."   # or put MONGO_URI in backend/.env
python database/seed.py
```

This creates the indexes (unique usernames, one progress row per child and puzzle) and upserts every puzzle by `id`. It is safe to run again, and it never touches users or progress. Add `--prune` to delete puzzles that were removed from `puzzles.json`.

## 3. Editing levels

Levels are drawn as ASCII maps in `build_puzzles.py`:

```
S  start    G  goal (star)    #  rock    .  free
```

After editing, regenerate and re-seed:

```bash
python database/build_puzzles.py   # fails if a level is unsolvable or its reference solution doesn't work
python database/seed.py
```

CI runs `build_puzzles.py --check` and fails if `puzzles.json` wasn't regenerated.
