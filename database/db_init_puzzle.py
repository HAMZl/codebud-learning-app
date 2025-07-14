from pymongo import MongoClient
import json
import os 
from dotenv import load_dotenv

load_dotenv()

client = MongoClient(os.getenv("MONGO_URI"))

try:
    client.admin.command('ping')
    print("✅ Successfully connected to MongoDB Atlas!")
except Exception as e:
    print("❌ Connection failed:", e)

db = client['codebud']
puzzles_collection = db['puzzles']

# Load puzzles from file
with open("generated_puzzles.json", "r") as f:
    puzzles = json.load(f)

puzzles_collection.delete_many({})
puzzles_collection.insert_many(puzzles)

print(f"Inserted {len(puzzles)} puzzles into MongoDB.")
