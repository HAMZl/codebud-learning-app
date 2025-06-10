from pymongo import MongoClient

# Connect to local MongoDB (default port)
client = MongoClient('mongodb://localhost:27017/')

# Create (or get) the database
db = client['codebud']

# Create collections (MongoDB creates them automatically when you insert, but explicit is better)
collections = ['users', 'puzzles', 'progress']
for col in collections:
    # Create collection if it doesn't exist
    if col not in db.list_collection_names():
        db.create_collection(col)
        print(f"Collection '{col}' created.")

# (Optional) Insert a sample user document
db['users'].insert_one({
    "username": "hamza",
    "email": "hamza@example.com",
    "password": "hashed_password",
    "name": "Hamza",
    "age": 5,
})

print("Setup complete.")