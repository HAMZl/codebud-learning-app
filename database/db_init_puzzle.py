from pymongo import MongoClient
import json

client = MongoClient("mongodb://localhost:27017/")
db = client['codebud']
puzzles_collection = db['puzzles']

# Load puzzles from file
with open("generated_puzzles.json", "r") as f:
    puzzles = json.load(f)

puzzles_collection.delete_many({})
puzzles_collection.insert_many(puzzles)

print(f"Inserted {len(puzzles)} puzzles into MongoDB.")
