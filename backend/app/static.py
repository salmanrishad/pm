from pathlib import Path

from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

STATIC_DIR = Path(__file__).resolve().parent.parent / "static"


def mount_static(app: FastAPI) -> None:
    """Serve the static site at /. Skipped when the directory is not present,
    which is the case in a checkout where the frontend has not been built."""
    if STATIC_DIR.is_dir():
        app.mount("/", StaticFiles(directory=STATIC_DIR, html=True), name="static")
