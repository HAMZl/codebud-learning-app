# Running CodeBud locally

This guide gets the whole stack running on your machine: MongoDB, the Flask API, and the Flutter app. It takes about 10 minutes.

## 1. Install the tools

| Tool | Version | Check with |
|---|---|---|
| Python | 3.10 or newer (CI and Render use 3.12) | `python --version` |
| Flutter | 3.32.1, stable channel (the same as CI) | `flutter --version` |
| MongoDB | 6 or newer: Docker, a local install, or a free Atlas cluster | see step 2 |
| Git | any recent version | `git --version` |

Chrome is the easiest device to run the app on. Run `flutter doctor` to check your Flutter setup.

> **Windows:** Flutter plugins need symlink support. If `flutter pub get` asks for it, turn on Developer Mode (`start ms-settings:developers`).

```bash
git clone https://github.com/HAMZl/codebud-learning-app.git
cd codebud-learning-app
```

## 2. Start MongoDB

Pick **one** of these.

**Docker (easiest):**

```bash
docker run -d --name codebud-mongo -p 27017:27017 mongo:7
```

The connection string is `mongodb://localhost:27017`. Later, use `docker stop codebud-mongo` and `docker start codebud-mongo` to stop and restart it.

**Local install:** install MongoDB Community Server from <https://www.mongodb.com/try/download/community>. On macOS you can use `brew install mongodb-community && brew services start mongodb-community`. The connection string is `mongodb://localhost:27017`.

On Windows the installer usually sets MongoDB up as a service, so it may already be running. Check in PowerShell with `Get-Service MongoDB`, and start it with `Start-Service MongoDB` (run as administrator).

**MongoDB Atlas:** create a free cluster and a database user. Under *Network Access*, allow your IP address, then copy the `mongodb+srv://...` connection string.

## 3. Run the backend

```bash
cd backend
python -m venv .venv

# macOS / Linux
source .venv/bin/activate
# Windows (PowerShell)
.venv\Scripts\Activate.ps1

pip install -r requirements-dev.txt
cp .env.example .env        # Windows: copy .env.example .env
```

> **Already have a `backend/.env`?** Don't overwrite it, especially if it points `MONGO_URI` at a shared or production database. The settings you set in your shell take precedence over `.env`, so you can leave the file alone:
>
> ```bash
> # bash
> export CODEBUD_ENV=development MONGO_URI=mongodb://localhost:27017
> # PowerShell
> $env:CODEBUD_ENV="development"; $env:MONGO_URI="mongodb://localhost:27017"
> ```
>
> Run `seed.py` and `app.py` from that same terminal.

Edit `backend/.env`:

```ini
CODEBUD_ENV=development          # uses a throwaway JWT secret, so you don't need to set one
MONGO_URI=mongodb://localhost:27017
MONGO_DB_NAME=codebud
```

Load the puzzles into the database. This also creates the indexes:

```bash
python ../database/seed.py
```

You should see `Puzzles: 30 inserted, 0 updated`. If the database already had puzzles, you'll see `0 inserted, 30 updated` instead. Users and progress are never touched. Then start the API:

```bash
python app.py                # http://127.0.0.1:5000
```

Check that it's up:

```bash
curl http://127.0.0.1:5000/health        # {"status": "ok"}
```

> **Port 5000 taken?** On macOS the AirPlay Receiver uses it. Pick another port, run `PORT=5001 python app.py` (PowerShell: `$env:PORT=5001; python app.py`), and use 5001 below.

## 4. Run the app

In a second terminal:

```bash
cd frontend/flutter_app
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

Without `--dart-define`, the app talks to the production API.

If you'd rather not have Flutter open a Chrome window, serve the app and open it in any browser yourself:

```bash
flutter run -d web-server --web-port 8080 --dart-define=API_BASE_URL=http://127.0.0.1:5000
# then open http://127.0.0.1:8080
```

Try it out: the landing page loads first. Play a demo puzzle (no account needed), then **Sign up**, log in, and play a level. The stars you earn are saved in your local MongoDB.

The **Settings** gear on the home screen opens the device settings. The parent area asks a multiplication question first.

### VS Code

`.vscode/launch.json` includes:

- **Backend (Flask)**: runs `backend/app.py` with the debugger attached. Create the `.venv` and `.env` first.
- **App (Chrome, local API)**: runs the Flutter app against `http://127.0.0.1:5000`.
- **Backend + App**: starts both.

## 5. Run the tests

```bash
# Backend: uses an in-memory MongoDB, so no database is needed
cd backend && pytest

# Frontend
cd frontend/flutter_app
flutter analyze
dart format --output=none --set-exit-if-changed lib test
flutter test
```

These are the same checks the GitHub Actions workflows run.

## Common tasks

| Task | Command |
|---|---|
| Edit or add levels | Edit `database/build_puzzles.py`, then run `python database/build_puzzles.py` and `python database/seed.py` |
| Check that `puzzles.json` is up to date | `python database/build_puzzles.py --check` |
| Regenerate sound effects | `cd frontend/flutter_app && python tool/generate_sounds.py` |
| Regenerate screenshots | `cd frontend/flutter_app && flutter test test_screenshots --update-goldens` |
| Release web build | `cd frontend/flutter_app && flutter build web --release --dart-define=API_BASE_URL=<url>` |

## Troubleshooting

| Symptom | Fix |
|---|---|
| `RuntimeError: JWT_SECRET_KEY must be set` | Add `CODEBUD_ENV=development` to `backend/.env`, or set `JWT_SECRET_KEY`. |
| `seed.py`: `error: set MONGO_URI` | Put `MONGO_URI` in `backend/.env` or export it in your shell. |
| `ServerSelectionTimeoutError` | MongoDB isn't running or can't be reached. Check `docker ps`. For Atlas, check *Network Access*. |
| The app shows "Network error" | Is the API running? Does `API_BASE_URL` match its port? Check `curl <url>/health`. |
| Levels list is empty | You haven't seeded the database yet. Run `python database/seed.py`. |
| Logged out unexpectedly | Tokens last 7 days. A `JWT_SECRET_KEY` change also signs everyone out. |
