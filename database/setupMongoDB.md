# MongoDB Setup Guide for CodeBud

This guide explains how to install MongoDB and initialize the project database using `db_init.py` and `db_init_puzzle.py`.

---

## Step 1: Install MongoDB

### Windows
1. Download MongoDB Community Server from: https://www.mongodb.com/try/download/community
2. Select:
   - Version: MongoDB 6.0 or newer
   - Platform: Windows
   - Package: MSI
3. Run the installer:
   - Choose **Complete Setup**
   - Ensure **"Install MongoDB as a Service"** is selected
4. (Optional) Install **MongoDB Compass** for GUI management.

### macOS
```bash
brew tap mongodb/brew
brew install mongodb-community@6.0
brew services start mongodb-community@6.0
```


## Step 2: Verify MongoDB Installation
```bash
mongosh 
```

## Step 3: Install Python Dependencies
```bash
pip install pymongo dnspython
```
## Step 4: Initialize the CodeBud Database
```bash
python db_init.py
python db_init_puzzle.py
```
