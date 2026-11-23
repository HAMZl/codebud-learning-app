# Deploying CodeBud

CodeBud runs on three hosted services:

| Part | Service | What it runs |
|---|---|---|
| Database | **MongoDB Atlas** | users, puzzles, progress |
| API | **Render** (Python web service) | `backend/`: Flask, served by gunicorn |
| Web app | **Firebase Hosting** | `frontend/flutter_app/build/web`: the Flutter web build |

Once everything is set up, the GitHub Actions workflows deploy automatically after the checks pass on `main`. Do steps 1–4 once, in order. Steps 5–6 cover everyday use.

---

## 1. MongoDB Atlas

1. Create a cluster at <https://cloud.mongodb.com>. The free M0 tier is enough.
2. **Database Access:** add a database user with a password. Give it *Read and write to any database*.
3. **Network Access:** allow `0.0.0.0/0`. Render's outgoing IP addresses aren't fixed on the free plan. The database is still protected by the user and password.
4. **Connect → Drivers:** copy the connection string, e.g.
   `mongodb+srv://<user>:<password>@<cluster>.mongodb.net/?retryWrites=true&w=majority`
5. Load the puzzles from your machine. Run this from the repository root, with the backend virtual environment active:

   ```bash
   MONGO_URI="mongodb+srv://..." python database/seed.py
   ```

   This creates the indexes and upserts all 30 puzzles. It is safe to re-run, and it never touches users or progress.
   Re-run it whenever `database/puzzles.json` changes.

## 2. Backend on Render

1. In the [Render dashboard](https://dashboard.render.com), go to **New → Web Service** and connect the GitHub repository.
2. Settings:

   | Setting | Value |
   |---|---|
   | Root Directory | `backend` |
   | Runtime | Python 3 |
   | Build Command | `pip install -r requirements.txt` |
   | Start Command | `gunicorn app:app` |
   | Health Check Path | `/health` |
   | Auto-Deploy | **Off**. GitHub Actions deploys after the tests pass |

3. **Environment** variables:

   | Key | Value |
   |---|---|
   | `MONGO_URI` | the Atlas connection string from step 1 |
   | `JWT_SECRET_KEY` | a long random string: `python -c "import secrets; print(secrets.token_hex(32))"` |
   | `PYTHON_VERSION` | `3.12.7` |
   | `CORS_ORIGINS` | *(optional)* your web app URLs, comma-separated, e.g. `https://codebud-app.web.app,https://codebud-app.firebaseapp.com`. Leave it unset to allow any origin. |

   The API **refuses to start** without `JWT_SECRET_KEY`. Changing it later signs everyone out.

4. Deploy, then check that it's running:

   ```bash
   curl https://<your-service>.onrender.com/health      # {"status": "ok"}
   ```

5. **Settings → Deploy Hook:** copy the URL. You'll need it for GitHub in step 4.

> `backend/render.yaml` describes the same service as a Render Blueprint, if you prefer to create it that way.
>
> The free plan sleeps after 15 minutes without traffic. The first request after that can take around 30 seconds while it wakes. The app waits up to 45 seconds before giving up.

## 3. Web app on Firebase Hosting

1. Create a project in the [Firebase console](https://console.firebase.google.com) and open **Hosting**.
2. `frontend/flutter_app/firebase.json` deploys to the Hosting site `codebud-app`. If your site ID is different, edit the `"site"` value.
3. Install the CLI and log in:

   ```bash
   npm install -g firebase-tools
   firebase login
   ```

4. Build against your API and deploy:

   ```bash
   cd frontend/flutter_app
   flutter build web --release --dart-define=API_BASE_URL=https://<your-service>.onrender.com
   firebase deploy --only hosting --project <firebase-project-id>
   ```

5. Open `https://<site>.web.app`. You should see the landing page. Sign up, play a level, and check the stars appear.

`API_BASE_URL` is compiled into the build. If the API address changes, rebuild and redeploy the web app.

## 4. Automatic deploys (GitHub Actions)

The workflows are in `.github/workflows/`:

| Workflow | Runs on | Checks | Then |
|---|---|---|---|
| `backend.yml` | changes to `backend/**` or `database/**` | pytest, and a check that `puzzles.json` is up to date | on `main`: calls the Render deploy hook |
| `frontend.yml` | changes to `frontend/flutter_app/**` or `database/puzzles.json` | format check, analyze, tests, web build | on `main`: deploys to Firebase (live). On PRs from this repository: a 7-day preview link |

1. **Repository secrets** (*Settings → Secrets and variables → Actions*):

   | Secret | Where to get it |
   |---|---|
   | `RENDER_DEPLOY_HOOK` | Render → your service → Settings → Deploy Hook |
   | `FIREBASE_SERVICE_ACCOUNT` | Run `firebase init hosting:github` in `frontend/flutter_app` and it creates this for you. Or go to Google Cloud console → IAM → Service Accounts, create one with the *Firebase Hosting Admin* role, and paste its JSON key. |
   | `FIREBASE_PROJECT_ID` | Firebase console → Project settings |

2. **Repository variable** (optional): `API_BASE_URL`, for when your API isn't at `https://codebud-learning-app.onrender.com`.

3. **Turn the workflows on.** They are currently disabled:

   ```bash
   gh workflow enable backend.yml
   gh workflow enable frontend.yml
   ```

   Or use the **Actions** tab: pick each workflow and click **Enable workflow**.

4. Push to `main`, or run a workflow by hand with **Run workflow** (`workflow_dispatch`), and watch it under **Actions**.

## 5. Releasing a change

1. Open a pull request. Checks run, and frontend changes get a Firebase preview link in the PR.
2. Merge to `main`. Each workflow deploys if the files it watches changed.
3. If you changed levels, re-run `python database/seed.py` against production. CI doesn't write to the database.

## 6. Rolling back

| Part | How |
|---|---|
| API | Render → your service → **Events**: pick an earlier deploy → **Rollback** |
| Web app | Firebase console → Hosting → **Release history**: pick an earlier release → **Roll back**. Or run `firebase hosting:rollback` |
| Code | `git revert <commit>` and push. The workflows deploy the reverted version |

## Checklist for a fresh deployment

- [ ] Atlas cluster, user and network access set up
- [ ] `python database/seed.py` run against production
- [ ] Render service created, with `MONGO_URI` and `JWT_SECRET_KEY` set and Auto-Deploy off
- [ ] `/health` returns `{"status": "ok"}`
- [ ] Web build deployed with the right `API_BASE_URL`, and sign-up works end to end
- [ ] `RENDER_DEPLOY_HOOK`, `FIREBASE_SERVICE_ACCOUNT` and `FIREBASE_PROJECT_ID` secrets added
- [ ] Workflows enabled
- [ ] *(optional)* `CORS_ORIGINS` limited to your web app's domains
