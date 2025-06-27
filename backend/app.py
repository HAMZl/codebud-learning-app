from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from pymongo import MongoClient
from flask_cors import CORS
from flask_jwt_extended import (
    JWTManager, create_access_token, jwt_required, get_jwt_identity
)

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
def get_puzzles_by_category(category):
    puzzles = list(db.puzzles.find({"category": category}))
    for p in puzzles:
        p['_id'] = str(p['_id'])  # Convert ObjectId to string
    return jsonify({'puzzles': puzzles}), 200

@app.route('/api/puzzle/<puzzle_id>', methods=['GET'])
def get_puzzle(puzzle_id):
    puzzle = db.puzzles.find_one({"id": puzzle_id})

    if not puzzle:
        return jsonify({"error": "Puzzle not found"}), 404

    puzzle['_id'] = str(puzzle['_id'])  # Optional cleanup
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

if __name__ == '__main__':
    app.run(debug=True)
