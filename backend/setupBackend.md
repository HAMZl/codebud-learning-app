# Backend Setup Guide for CodeBud

This guide walks you through setting up the backend environment for the CodeBud project using Flask.

---

## Prerequisites

Ensure the following are installed:

- Python 3.8 or higher
- pip (Python package manager)


## Step 2: Create a Virtual Environment
To isolate project dependencies:
```bash
# Create the virtual environment
python -m venv venv

# Activate the virtual environment

# On Windows:
venv\Scripts\activate

# On macOS/Linux:
source venv/bin/activate
```
## Step 3: Install Python Dependencies
```bash
pip install -r requirements.txt
```
## Step 4: Run the Flask App
Start the development server:
```bash
python app.py
```
You should see output similar to:
```bash
* Running on http://127.0.0.1:5000/ (Press CTRL+C to quit)
```