# CodeBud - A Visual Coding Adventure for Kids

CodeBud is an educational game designed for preschoolers aged 4 to 7 to explore the fundamentals of programming and algorithmic thinking through engaging, visual puzzles. Built using Flutter (frontend) and Flask with MongoDB (backend), CodeBud avoids all text, making it accessible to non-readers by relying solely on colorful drag-and-drop blocks, animations, and sound feedback.

---

## 🌟 Product Vision

**FOR** preschool children aged 4 to 7,  
**WHO** are just beginning to explore thinking in sequences and logic,  
**THE** CodeBud App is an educational app  
**THAT** helps develop programming and algorithmic thinking skills through interactive, visual puzzles.  
**UNLIKE** traditional text-based tools,  
**OUR PRODUCT** provides a completely text-free, drag-and-drop interface with friendly animations and sounds, making coding concepts like sequencing, loops, and conditionals intuitive and fun for early learners.

---

## 🧰 Tech Stack

- **Frontend:** Flutter
- **Backend:** Python (Flask)
- **Database:** MongoDB
- **Prototyping Tools:** Visily

---

## 🧒 User Personas

1. **Ella (Age 5)**: Loves bright visuals and reacts to fun sounds. She learns through repetition and needs simple instructions.
2. **Liam (Age 6)**: Curious and loves solving puzzles. Can understand logical relationships with visual cues.
3. **Sophia (Age 4)**: New to digital interfaces. Needs intuitive design to avoid frustration and promote interaction.

---

## ✨ Core Features

### 1. Drag-and-Drop Command Blocks
- Visual icons like arrows and turns instead of text.
- Children drag blocks onto a sequence strip to form a "code".
- Icons are large, colorful, and animated.

### 2. Puzzle-Based Levels
- Guide CodeBud to reach the star.
- Levels gradually introduce complexity: straight paths → turns → obstacles → logic.
- Each level has a grid-based layout with defined start and goal positions.

### 3. Loops (Simplified)
- Introduce visual loop blocks like “Repeat X times”.
- Children can drag commands into the loop block and set a number of iterations visually.

### 4. If-Then Logic (Visual Conditionals)
- Introduces basic logic: e.g., `If rock ahead → turn right`.
- Uses icons for conditions and actions, eliminating any reading requirement.
- Teaches logical branching in a visual and intuitive way.

### 5. Interactive Feedback and Rewards
- Sound effects like claps and cheerful tones when the player succeeds.
- Animations such as CodeBud jumping or stars shining.
- Star-based reward system (1 to 3 stars based on move efficiency).

---

## 🧩 User Stories

### Story 1: Puzzle Navigation and Goal Completion
**As a** child,  
**I want to** guide CodeBud through puzzles using drag-and-drop blocks,  
**So that** I can reach the goal and feel a sense of achievement.  
✅ Acceptance Criteria:
- Grid-based level appears.
- CodeBud follows command sequence.
- Game detects goal reached and shows animation.

### Story 2: Looping Movement
**As a** player,  
**I want to** use loops to repeat actions,  
**So that** I can solve puzzles more efficiently.  
✅ Acceptance Criteria:
- Drag loop block into sequence.
- Insert commands inside the loop visually.
- Choose iteration count using visual counter.

### Story 3: Obstacle Handling with Conditionals
**As a** child,  
**I want to** make CodeBud avoid obstacles using "if-then" blocks,  
**So that** I can solve more complex levels.  
✅ Acceptance Criteria:
- Visual logic block appears in command list.
- Condition triggers when CodeBud detects obstacle.
- Appropriate action is executed (e.g., turn or jump).

### Story 4: Animated Feedback and Stars
**As a** young learner,  
**I want to** receive stars and hear sounds when I solve a puzzle,  
**So that** I feel rewarded and want to keep playing.  
✅ Acceptance Criteria:
- Puzzle completion shows stars based on move efficiency.
- Cheerful animations and sounds play upon success.

---

## 📐 Design Guidelines

- **No Text**: All instructions and gameplay use images, animations, and sound.
- **Touch-Friendly UI**: Large buttons and drag areas to match motor skills of children.
- **Progressive Difficulty**: Introduce concepts gradually with increasing challenge.
- **Safe & Encouraging**: No failure penalties. Focus is on trial-and-error learning.

---

## 🏗️ Architecture

```
frontend/flutter_app/        Flutter app (web build is deployed to Firebase Hosting)
  lib/config/                build-time config (API_BASE_URL)
  lib/services/              ApiClient, AuthService, PuzzleService, token storage, AppScope
  lib/game/engine.dart       game rules: runs a program and returns the path, result and stars
  lib/models/                Puzzle, CommandItem (blocks), categories
  lib/screens/, lib/widgets/ UI only, with no HTTP calls
backend/                     Flask API (deployed to Render)
  app.py                     WSGI entry point (gunicorn app:app)
  codebud/__init__.py        create_app() factory
  codebud/engine.py          the same game rules as engine.dart
  codebud/routes/            auth, puzzles, progress blueprints
  tests/                     pytest suite (in-memory MongoDB via mongomock)
database/
  build_puzzles.py           source of truth for levels (ASCII maps + reference solutions)
  puzzles.json               generated from build_puzzles.py
  seed.py                    loads puzzles.json into MongoDB and creates indexes
```

The **game rules exist twice**: once in Dart, so the robot animates instantly with no round trip, and once in Python, so the server can check results. When a child solves a level, the app sends the *program* rather than a star count. The server replays it and awards the stars itself. Tests on both sides run every shipped puzzle's reference solution, so the two engines can't drift apart.

### Game rules

| Block | Meaning |
|---|---|
| ⬆️ ⬇️ ⬅️ ➡️ | Move one cell. Hitting the grid edge or a rock ends the run with a hint. |
| 🔁 Loop | Repeat the blocks inside 2–10 times. A loop can contain moves and If blocks. |
| ❓ If | Run the blocks inside only when the next cell in a direction is a rock (the edge counts), empty, or the star. |

### Sound effects

The sounds are synthesized by `frontend/flutter_app/tool/generate_sounds.py`, not downloaded, so there are no licensing concerns. Edit the script and run it to regenerate `assets/sounds/*.wav`. There is a sound for adding a block, each robot step, bumping into a wall or rock, a gentle "try again", and a success jingle with claps, and each earned star chimes. Sound plays through `SoundService`, which never throws, so a missing sound can't break the game. The mute setting is remembered between sessions.

### Rules

The run ends as soon as the robot reaches the star. Stars reward short programs, and every block counts, including nested ones. A program at or under the level's *par* earns ⭐⭐⭐, up to par + 2 earns ⭐⭐, and any other solution earns ⭐. Finishing a level never earns zero stars. Each level unlocks when the one before it is finished.

### API

| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/signup` | – | Create a parent + child account |
| POST | `/login` | – | Returns a JWT (valid for 7 days) |
| GET | `/api/me` | JWT | Child's name and age |
| GET | `/api/puzzles/<category>` | JWT | Levels in a category with best stars |
| GET | `/api/puzzle/<id>` | – | One level, plus a link to the next one (no solution) |
| POST | `/api/validate_sequence` | – | Run a program and get the result and a hint |
| POST | `/api/progress` | JWT | Save a solved program; the server computes the stars |
| GET | `/api/progress` | JWT | Per-category star totals |
| GET | `/health` | – | Health check for Render |

---

## 🛠️ Development

**Backend** (Python 3.10+):

```bash
cd backend
python -m venv .venv && source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install -r requirements-dev.txt
cp .env.example .env                                 # then fill in MONGO_URI
pytest
python app.py                                        # http://127.0.0.1:5000
```

**Database**: edit levels in `database/build_puzzles.py`, then:

```bash
python database/build_puzzles.py      # validates every level and regenerates puzzles.json
python database/seed.py               # upserts puzzles into MONGO_URI and creates indexes
```

**Frontend** (Flutter 3.32):

```bash
cd frontend/flutter_app
flutter pub get
flutter test
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:5000
```

## 🚀 CI/CD

| Workflow | On pull requests | On push to `main` |
|---|---|---|
| `backend.yml` | pytest and a check that `puzzles.json` is up to date | the same, then triggers the Render deploy hook |
| `frontend.yml` | format check, `flutter analyze`, `flutter test`, web build, and a Firebase preview channel | the same, then deploys to the live Firebase channel |

Deploys run only after the checks pass. Required secrets: `RENDER_DEPLOY_HOOK`, `FIREBASE_SERVICE_ACCOUNT`, `FIREBASE_PROJECT_ID`. The optional repository variable `API_BASE_URL` points the web build at a different backend. On Render, set `MONGO_URI` and `JWT_SECRET_KEY`, and turn off Auto-Deploy so that only the workflow deploys.

---

## 📎 Links

- 🔗 **Prototype**: [CodeBud Prototype in Visily](https://app.visily.ai/projects/44b88f73-7690-4228-86c4-96b70062a295/boards/1927196)
- 📁 **Repository**: [github.com/HAMZl/codebud-learning-app](https://github.com/HAMZl/codebud-learning-app)

---

## 👨‍👩‍👧 Team Code of Conduct

- Weekly team meetings every Tuesday at 7PM CST.
- Transparent communication via Discord.
- Equitable workload distribution.
- Respect, collaboration, and constructive feedback encouraged.

---

## 📅 Future Enhancements

- ~~Profile & Progress Tracking~~ (done: best stars per level and per-category totals)
- ~~Multiple Puzzle Categories~~ (done: Sequencing, Loops, Conditionals) · Free Play mode
- ~~Sound effects~~ (done: tap, step, bump, try-again, success with claps, and a star chime; mute button on the home and puzzle screens)
- **More Characters and Themes**
- **Parent Dashboard for Monitoring Progress**

