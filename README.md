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

Backend (no host Python needed, runs in the uv image):

```bash
cd backend
docker run --rm -v "$(pwd -W):/w" -w /w ghcr.io/astral-sh/uv:python3.14-bookworm-slim uv run --frozen pytest
```

Frontend:

```bash
cd frontend
npm ci
npm run test:all
```

## Documentation

Plan and design notes are in `docs/`. Each of `backend/`, `frontend/`, and
`scripts/` has its own `CLAUDE.md`.
