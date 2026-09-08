from fastapi import FastAPI

from app.static import mount_static

app = FastAPI(title="Project Management MVP")


@app.get("/api/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


# Mounted last so the catch-all static route does not shadow the API.
mount_static(app)
