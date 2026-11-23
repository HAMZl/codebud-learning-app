"""WSGI entry point: ``gunicorn app:app`` on Render, or ``python app.py`` locally."""

from codebud import create_app

app = create_app()

if __name__ == "__main__":
    app.run(debug=app.config.get("DEBUG", False))
