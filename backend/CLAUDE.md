# Backend

FastAPI app served by uvicorn, packaged in the project Docker image. Python
3.14, dependencies managed by `uv`.

## Layout

- `app/main.py` - creates the `FastAPI` app, defines `GET /api/health`, then calls `mount_static`. The mount happens last on purpose: `StaticFiles` at `/` is a catch-all and would shadow API routes registered after it.
- `app/static.py` - mounts `backend/static/` at `/` with `html=True`. No-ops when the directory is absent, so the app still runs in a checkout where the frontend has not been built.
- `static/` - the served site. Currently a placeholder page that calls `/api/health`; Part 3 replaces it with the Next static export.
- `tests/` - pytest.

## Dependencies

`pyproject.toml` plus `uv.lock`. Runtime: `fastapi`, `uvicorn[standard]`. Dev
group: `pytest`, `httpx2`.

Note `httpx2`, not `httpx`. Starlette's `TestClient` now emits a deprecation
warning on plain `httpx` and asks for `httpx2`.

## Running tests

`uv` is not required on the host. Both commands below run in the official uv
image with the backend directory mounted:

```bash
cd backend
docker run --rm -v "$(pwd -W):/w" -w /w ghcr.io/astral-sh/uv:python3.14-bookworm-slim uv run --frozen pytest
```

On Git Bash for Windows, prefix with `MSYS_NO_PATHCONV=1` and use `$(pwd -W)`.
On Mac and Linux, use `$(pwd)`.

Regenerate the lockfile the same way after editing `pyproject.toml`:

```bash
docker run --rm -v "$(pwd -W):/w" -w /w ghcr.io/astral-sh/uv:python3.14-bookworm-slim uv lock
```

`pyproject.toml` sets `pythonpath = ["."]` for pytest so `from app.main import app`
resolves without installing the package.

## Conventions

- All API routes live under `/api`. Everything else falls through to the static site.
- The image runs `uvicorn app.main:app` on port 8000.
