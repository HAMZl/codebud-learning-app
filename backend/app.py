from flask import Flask, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from pymongo import MongoClient
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

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
        return jsonify({'success': True, 'message': f'Welcome, {user["child_name"]}!'}), 200
    else:
        return jsonify({'success': False, 'message': 'Incorrect password!'}), 401

@app.route('/api/puzzles/<category>', methods=['GET'])
def get_puzzles_by_category(category):
    puzzles = list(db.puzzles.find({"category": category}))
    for p in puzzles:
        p['_id'] = str(p['_id'])  # Convert ObjectId to string
    return jsonify({'puzzles': puzzles}), 200

if __name__ == '__main__':
    app.run(debug=True)
