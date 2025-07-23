from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from pymongo import MongoClient
from flask_cors import CORS
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity

app = Flask(__name__)
CORS(app)

# Configure JWT
app.config['JWT_SECRET_KEY'] = 'your-secret-key'  # Change this to a secure value in production
jwt = JWTManager(app)

# MongoDB connection
client = MongoClient('mongodb://localhost:27017/')
db = client['codebud']

@app.route('/signup', methods=['POST'])
def signup():
    data = request.json
    username = data['username']
    if db.users.find_one({'username': username}):
        return jsonify({'success': False, 'message': 'Account already exists!'}), 400
    hashed_password = generate_password_hash(data['password'])
    user = {
        'parent_name': data['parent_name'],
        'email': data['email'],
        'child_name': data['child_name'],
        'child_age': data['child_age'],
        'username': username,
        'password': hashed_password
    }
    db['users'].insert_one(user)
    return jsonify({'success': True, 'message': 'Account created successfully!'}), 200

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')

    user = db.users.find_one({'username': username})
    if not user:
        return jsonify({'success': False, 'message': 'No account with that username!'}), 401

    if check_password_hash(user['password'], password):
        access_token = create_access_token(identity=username)
        return jsonify({
            'success': True,
            'message': f'Welcome, {user["child_name"]}!',
            'token': access_token
        }), 200
    else:
        return jsonify({'success': False, 'message': 'Incorrect password!'}), 401

@app.route('/api/puzzles/<category>', methods=['GET'])
@jwt_required()
def get_puzzles_by_category(category):
    username = get_jwt_identity()

    puzzles = list(db.puzzles.find({"category": category}))
    puzzle_ids = [p['id'] for p in puzzles]

    progress = list(db.progress.find({"username": username, "puzzle_id": {"$in": puzzle_ids}}))
    progress_dict = {p['puzzle_id']: p for p in progress}

    for p in puzzles:
        pid = p['id']
        p['_id'] = str(p['_id'])
        stars = progress_dict.get(pid, {}).get('stars', 0)
        p['stars'] = ['yellow' if i < stars else 'gray' for i in range(3)]

    return jsonify({'puzzles': puzzles}), 200

@app.route('/api/puzzle/<puzzle_id>', methods=['GET'])
def get_puzzle(puzzle_id):
    puzzle = db.puzzles.find_one({"id": puzzle_id})

    if not puzzle:
        return jsonify({"error": "Puzzle not found"}), 404

    puzzle['_id'] = str(puzzle['_id'])
    return jsonify(puzzle)

@app.route('/api/progress', methods=['POST'])
@jwt_required()
def save_progress():
    username = get_jwt_identity()
    data = request.get_json()

    db.progress.update_one(
        {'username': username, 'puzzle_id': data['puzzle_id']},
        {'$set': {
            'status': data['status'],
            'stars': data['stars'],
            'updated_at': data.get('updated_at')
        }},
        upsert=True
    )
    return jsonify({'success': True, 'message': 'Progress saved'}), 200

# ✅ NEW ERROR HINT SYSTEM ENDPOINT
@app.route('/api/validate_sequence', methods=['POST'])
def validate_sequence():
    data = request.get_json()
    sequence = data.get('sequence', [])
    puzzle_id = data.get('puzzle_id')

    puzzle = db.puzzles.find_one({'id': puzzle_id})
    if not puzzle:
        return jsonify({'status': 'error', 'hint': 'Puzzle not found'}), 404

    size = puzzle['gridSize']
    obstacles = [tuple(ob) for ob in puzzle['obstacles']]
    pos = tuple(puzzle['start'])
    goal = tuple(puzzle['goal'])

    for move in sequence:
        if move == 'Up':
            pos = (pos[0] - 1, pos[1])
        elif move == 'Down':
            pos = (pos[0] + 1, pos[1])
        elif move == 'Left':
            pos = (pos[0], pos[1] - 1)
        elif move == 'Right':
            pos = (pos[0], pos[1] + 1)

        if pos[0] < 0 or pos[1] < 0 or pos[0] >= size or pos[1] >= size:
            return jsonify({'status': 'invalid', 'hint': 'Oops! You’re bumping into a wall.'})

        if pos in obstacles:
            return jsonify({'status': 'invalid', 'hint': 'Watch out! There’s an obstacle in the way.'})

    if pos != goal:
        return jsonify({'status': 'invalid', 'hint': 'Hmm... you didn’t reach the goal. Try changing your moves.'})

    return jsonify({'status': 'valid'})


if __name__ == '__main__':
    app.run(debug=True)
