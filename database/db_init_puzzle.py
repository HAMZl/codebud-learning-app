from pymongo import MongoClient

# Connect to local MongoDB
client = MongoClient("mongodb://localhost:27017/")
db = client['codebud']
puzzles_collection = db['puzzles']

# Clear existing puzzles
puzzles_collection.delete_many({})

# Define 3 puzzles for each type
sequence_puzzles = [
    {
        "id": "seq1",
        "category": "sequence",
        "title": "Sequence Puzzle 1",
        "gridSize": 5,
        "start": [0, 0],
        "goal": [4, 4],
        "obstacles": [[1, 1], [2, 2], [3, 3]]
    },
    {
        "id": "seq2",
        "category": "sequence",
        "title": "Sequence Puzzle 2",
        "gridSize": 5,
        "start": [0, 1],
        "goal": [4, 3],
        "obstacles": [[1, 2], [2, 1]]
    },
    {
        "id": "seq3",
        "category": "sequence",
        "title": "Sequence Puzzle 3",
        "gridSize": 5,
        "start": [1, 1],
        "goal": [3, 4],
        "obstacles": [[0, 2], [2, 3]]
    }
]

loop_puzzles = [
    {
        "id": "loop1",
        "category": "loop",
        "title": "Loop Puzzle 1",
        "gridSize": 5,
        "start": [0, 0],
        "goal": [4, 0],
        "obstacles": [[2, 0]]
    },
    {
        "id": "loop2",
        "category": "loop",
        "title": "Loop Puzzle 2",
        "gridSize": 5,
        "start": [0, 2],
        "goal": [4, 2],
        "obstacles": [[1, 2], [3, 2]]
    },
    {
        "id": "loop3",
        "category": "loop",
        "title": "Loop Puzzle 3",
        "gridSize": 5,
        "start": [2, 0],
        "goal": [2, 4],
        "obstacles": [[2, 2]]
    }
]

conditional_puzzles = [
    {
        "id": "cond1",
        "category": "conditional",
        "title": "Conditional Puzzle 1",
        "gridSize": 5,
        "start": [0, 0],
        "goal": [0, 4],
        "obstacles": [[0, 2]]
    },
    {
        "id": "cond2",
        "category": "conditional",
        "title": "Conditional Puzzle 2",
        "gridSize": 5,
        "start": [4, 0],
        "goal": [0, 0],
        "obstacles": [[2, 0], [3, 0]]
    },
    {
        "id": "cond3",
        "category": "conditional",
        "title": "Conditional Puzzle 3",
        "gridSize": 5,
        "start": [2, 2],
        "goal": [4, 4],
        "obstacles": [[3, 3], [1, 2]]
    }
]

# Combine all puzzles
all_puzzles = sequence_puzzles + loop_puzzles + conditional_puzzles

# Insert into MongoDB
result = puzzles_collection.insert_many(all_puzzles)
print(f"Inserted {len(result.inserted_ids)} puzzles into MongoDB.")
