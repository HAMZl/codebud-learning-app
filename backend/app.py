"""WSGI entry point: ``gunicorn app:app`` on Render, or ``python app.py`` locally."""

import os

from codebud import create_app

app = create_app()

if __name__ == "__main__":
    # PORT lets you avoid clashes. On macOS, the AirPlay Receiver already uses port 5000.
    app.run(port=int(os.getenv("PORT", "5000")), debug=app.config.get("DEBUG", False))
