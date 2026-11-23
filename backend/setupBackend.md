# Backend Setup Guide for CodeBud

## Prerequisites

- Python 3.10 or higher
- A MongoDB database: a local install, or a free MongoDB Atlas cluster (see `../database/setupMongoDB.md`)

## 1. Create a virtual environment

```bash
python -m venv .venv

# Windows
.venv\Scripts\activate
# macOS / Linux
source .venv/bin/activate
```

## 2. Install dependencies

```bash
pip install -r requirements-dev.txt   # runtime + test dependencies
```

`requirements.txt` holds only what production (Render) needs.

## 3. Configure

```bash
cp .env.example .env
```

Fill in `MONGO_URI`. With `CODEBUD_ENV=development` a throwaway JWT secret is used. In production the app refuses to start without `JWT_SECRET_KEY`.

## 4. Run the tests

```bash
pytest
```

The tests use an in-memory MongoDB (mongomock), so they need no database or network.

## 5. Run the server

```bash
python app.py
```

```
* Running on http://127.0.0.1:5000/
```

Check that it is up: `curl http://127.0.0.1:5000/health` should return `{"status": "ok"}`.
