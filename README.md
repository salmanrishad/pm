# Project Management MVP

A single-board Kanban app with an AI assistant. FastAPI backend serving a Next
static frontend, packaged in one Docker container.

## Run

Requires Docker.

```bash
scripts/start.sh     # Mac, Linux
scripts\start.ps1    # Windows
```

Then open http://localhost:8000.

```bash
scripts/stop.sh      # Mac, Linux
scripts\stop.ps1     # Windows
```

The SQLite database lives on the `pm-data` volume and survives a stop.

## Configuration

`.env` in the project root, passed into the container when present:

```
OPENROUTER_API_KEY=...
```

## Tests

Backend (no host Python or uv needed, runs in the uv image). From `backend/`:

```powershell
docker run --rm -v "${PWD}:/w" -w /w ghcr.io/astral-sh/uv:python3.14-bookworm-slim uv run --frozen pytest
```

On Mac and Linux use `$(pwd)` in place of `${PWD}`. See `backend/CLAUDE.md` for
the Git Bash form, which needs an extra flag.

Frontend:

```bash
cd frontend
npm ci
npm run test:all
```

## Documentation

Plan and design notes are in `docs/`. Each of `backend/`, `frontend/`, and
`scripts/` has its own `CLAUDE.md`.
