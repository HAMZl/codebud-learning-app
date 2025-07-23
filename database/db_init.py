from pymongo import MongoClient
import os 
from dotenv import load_dotenv

load_dotenv()

client = MongoClient(os.getenv("MONGO_URI"))

try:
    client.admin.command('ping')
    print("✅ Successfully connected to MongoDB Atlas!")
except Exception as e:
    print("❌ Connection failed:", e)


# Create (or get) the database
db = client['codebud']

# Create collections (MongoDB creates them automatically when you insert, but explicit is better)
collections = ['users', 'puzzles', 'progress']
for col in collections:
    # Create collection if it doesn't exist
    if col not in db.list_collection_names():
        db.create_collection(col)
        print(f"Collection '{col}' created.")
    else:
        print(f"Collection '{col}' already exists.")