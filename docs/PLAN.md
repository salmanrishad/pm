# Project Plan

Ten parts, executed in order. Each part has a checklist, tests, and success
criteria. Nothing in a part is done until its success criteria pass.

## Resolved decisions

These were open questions in the original plan. They are now settled and the
parts below assume them.

| Topic | Decision |
| --- | --- |
| Per-directory docs | `CLAUDE.md` everywhere (the `AGENTS.md` stubs were renamed) |
| Database | Relational SQLite (users / boards / columns / cards / chat_messages), stdlib `sqlite3`, no ORM. The schema proposal is also written out as JSON |
| AI model | `nvidia/nemotron-3-super-120b-a12b:free`, overridable with `OPENROUTER_MODEL`. Verified: it honours strict `json_schema` structured outputs. Fallbacks if it is rate limited: `dots-studio/dots-3-note-preview:free`, `liquid/lfm-2.5-2.6b:free` (both verified) |
| Frontend serving | Next static export (`output: "export"`, `trailingSlash: true`), served by FastAPI from `/`. No SSR, no middleware, no Next route handlers |
| Auth | `users` table with a PBKDF2 hash (stdlib `hashlib`, no extra dependency), seeded with `user` / `password`. Session is a signed httpOnly cookie via `itsdangerous`; no sessions table |
| Container | Single image, multi-stage: `node:22-alpine` builds the static site, `python:3.13-slim` plus `uv` runs FastAPI and serves it. Host port 8000. SQLite at `/app/data/pm.db` on a named volume |
| Scripts | `scripts/start.sh` and `stop.sh` (Mac, Linux), `scripts/start.ps1` and `stop.ps1` (Windows). Start builds then runs; Docker layer caching makes rebuilds cheap. Plain `docker` commands, no compose |
| Chat history | Persisted in SQLite so a reload keeps the conversation. Single-shot responses, no streaming (structured outputs make streaming pointless here) |
| Columns | Exactly the 5 seeded columns. Renameable. No add, no delete |
| Card fields | `title` and `details` only, plus an explicit integer `position` for ordering |
| Approval gates | User sign-off at the end of Part 1 and Part 5. Short summary after every other part |

## Conventions

- Backend lives in `backend/`, package `app/`. Managed by `uv` (`pyproject.toml` plus `uv.lock`).
- API is mounted under `/api`. Everything else falls through to the static site.
- Backend tests are `pytest` in `backend/tests/`, run against the FastAPI app with a temporary database.
- Frontend tests stay as they are: `vitest` for units, Playwright for e2e.
- Secrets come from `.env` at the project root, which is gitignored. Never commit or print the key.

## Environment variables

| Name | Default | First used |
| --- | --- | --- |
| `OPENROUTER_API_KEY` | none (required for Parts 8-10) | Part 8 |
| `OPENROUTER_MODEL` | `nvidia/nemotron-3-super-120b-a12b:free` | Part 8 |
| `DB_PATH` | `/app/data/pm.db` in Docker, `./data/pm.db` locally | Part 6 |
| `SECRET_KEY` | dev default, overridable | Part 4 |

---

## Part 1: Plan

Enrich this document, document the existing frontend, get sign-off.

- [x] Review `CLAUDE.md` and the existing frontend code
- [x] Resolve the open questions with the user
- [x] Verify empirically which free OpenRouter models support strict structured outputs
- [x] Rename `backend/AGENTS.md` and `scripts/AGENTS.md` to `CLAUDE.md`
- [x] Write `frontend/CLAUDE.md` describing the existing code and its gaps
- [x] Rewrite this document with per-part checklists, tests, and success criteria
- [ ] User reviews and approves

Tests: none (documentation only).

Success criteria: the user has explicitly approved this plan.

---

## Part 2: Scaffolding

Docker infrastructure, a FastAPI backend that serves a placeholder page and one
API route, and start/stop scripts.

- [x] `backend/pyproject.toml` with `fastapi`, `uvicorn[standard]`; dev group `pytest`, `httpx2` (Starlette's `TestClient` deprecates plain `httpx`)
- [x] `backend/app/main.py` - FastAPI app, `GET /api/health` returning `{"status": "ok"}`
- [x] `backend/app/static.py` - mount a static directory at `/`, tolerating it being empty or absent during development
- [x] `backend/static/index.html` - placeholder page that calls `/api/health` and shows the result
- [x] `Dockerfile` - `python:3.14-slim`, `uv` binary copied from the official image, `uv sync --frozen --no-dev`, runs `uvicorn`. The frontend build stage is added in Part 3 rather than left as a no-op stage now
- [x] `.dockerignore`
- [x] `scripts/start.sh`, `scripts/stop.sh`, `scripts/start.ps1`, `scripts/stop.ps1` - build the image, run or stop the `pm-app` container, map port 8000, mount the `pm-data` volume, pass `.env`
- [x] `backend/tests/test_health.py`
- [x] Fill in `backend/CLAUDE.md` and `scripts/CLAUDE.md`
- [x] Minimal root `README.md` (how to start, how to stop, how to test)

Tests: 6 pytest cases pass.
- [x] `/api/health` returns 200 and `{"status": "ok"}`; `/` serves the static page
- [x] `mount_static` no-ops on a missing directory and mounts an existing one
- [x] The API route is not shadowed by the static catch-all; an unknown path is 404

Container and scripts, all four scripts exercised on both shells:
- [x] `start.sh` and `start.ps1` build and run, from the repo root and from an unrelated working directory
- [x] Running `start` again while a container exists replaces it cleanly
- [x] `stop.sh` and `stop.ps1` report correctly whether something was running, are idempotent, and leave `pm-data` intact
- [x] The `pm-data` volume is mounted rw at `/app/data`, and a file written there survives the container being destroyed and recreated
- [x] `--env-file .env` reaches the container (`OPENROUTER_API_KEY` present)
- [x] `--no-dev` holds: `pytest` is absent from the image. Image is 215MB
- [x] Container logs are clean; a headless browser load of `/` shows the health span reading `ok` with no console or page errors

Success criteria: met.

Three bugs were found by this round and fixed:
- `stop.sh` printed "Stopped." even when nothing was running, because Docker 27's `docker rm -f` exits 0 on a missing container. Now queries first, matching the PowerShell version
- `start.sh` expanded an empty bash array under `set -u`, which fails on the bash 3.2 that macOS ships. Replaced with a plain string
- Both start scripts announced "Running at ..." roughly two seconds before uvicorn was listening, so opening the URL immediately failed. They now poll `/api/health` until it answers

Note: `uv` is not installed on the host. Backend tests and lockfile updates run
in the official uv image with `backend/` mounted; see `backend/CLAUDE.md`.

---

## Part 3: Add in Frontend

Statically build the Next app and serve it from FastAPI, so the demo Kanban is
at `/`.

- [ ] `frontend/next.config.ts`: `output: "export"`, `trailingSlash: true`, `images: { unoptimized: true }`
- [ ] Verify `next build` produces `frontend/out/` and that `next/font/google` self-hosts correctly in the export
- [ ] Dockerfile stage 1: `node:22-alpine`, `npm ci`, `npm run build`; copy `frontend/out` into the Python stage static directory
- [ ] Delete `backend/static/index.html`; static content now comes from the build
- [ ] FastAPI serves the export: `index.html` at `/`, assets under `/_next`, and a catch-all returning `index.html` for unknown non-`/api` paths
- [x] Add card editing to the frontend (inline form, local state only for now) - done ahead of this part; sorting is disabled while a card is in edit mode
- [ ] Extend `vitest` coverage: rename, add, delete, and `moveCard` edge cases (unknown id, drop on own position, drop on empty column). Card edit and cancel-edit are already covered
- [ ] Extend Playwright coverage: rename a column. Load, drag between columns, add, and edit are already covered
- [ ] Add a Playwright project that runs against the container at `http://localhost:8000` in addition to the dev server
- [ ] Update `frontend/CLAUDE.md`

Tests:
- `npm run test:unit` - all pass, `moveCard` and every board handler covered
- `npm run test:e2e` - passes against the dev server and against the container
- `pytest` - static routes: `/` returns HTML 200, a `/_next/...` asset returns 200, `/api/health` still returns JSON, an unknown path returns the app shell rather than an API 404

Success criteria: `http://localhost:8000` in the container shows the working
Kanban demo with drag and drop, rename, add, edit, and delete; no console
errors; all three test suites pass.

---

## Part 4: Fake user sign in

- [ ] `backend/app/auth.py` - PBKDF2 hashing helpers, `itsdangerous` signed session cookie (`pm_session`, httpOnly, SameSite=Lax, seven day max age)
- [ ] Hardcoded credential check for now against `user` and `password`; the check moves to the `users` table in Part 6
- [ ] `POST /api/auth/login` (sets the cookie), `POST /api/auth/logout` (clears it), `GET /api/auth/me` (401 when unauthenticated)
- [ ] A FastAPI dependency `current_user` that returns 401, ready to protect the Part 6 routes
- [ ] `frontend/src/app/login/page.tsx` - login form in the project palette (purple submit button), inline error on bad credentials
- [ ] `frontend/src/lib/api.ts` - fetch wrapper with `credentials: "include"` that redirects to `/login` on 401
- [ ] Client-side guard: the board page calls `/api/auth/me` on mount and redirects to `/login` when unauthenticated
- [ ] Log out control in the board header
- [ ] Update `backend/CLAUDE.md` and `frontend/CLAUDE.md`

Tests:
- `pytest` - login with correct credentials sets the cookie; wrong username, wrong password, and missing fields each return 401 without a cookie; `/api/auth/me` is 401 without a cookie and 200 with one; logout clears it; a tampered cookie is rejected
- `vitest` - login form renders, submits, and shows an error on failure; the guard redirects when `/api/auth/me` fails
- Playwright - hitting `/` unauthenticated lands on `/login`; logging in shows the board; reloading keeps the session; logging out returns to `/login` and the board is no longer reachable

Success criteria: the board is unreachable without logging in, the session
survives a reload, logout works, and all suites pass.

---

## Part 5: Database modeling

Propose the schema, document it, get sign-off. No implementation in this part.

- [ ] `docs/DATABASE.md` - prose: tables, columns, types, keys, constraints, ordering strategy, the seed data written at first boot, and how a fresh database is created
- [ ] `docs/schema.json` - the same proposal in machine-readable JSON
- [ ] Proposed tables:
  - `users` (id, username unique, password_hash, created_at)
  - `boards` (id, user_id FK, name, created_at) - one per user for the MVP
  - `columns` (id, board_id FK, title, position) - 5 rows seeded per board
  - `cards` (id, column_id FK, title, details, position, created_at, updated_at)
  - `chat_messages` (id, board_id FK, role, content, created_at)
- [ ] Document ordering: integer `position`, contiguous per parent, renumbered on write
- [ ] Document cascade deletes and the indexes worth having
- [ ] User reviews and approves

Tests: none (documentation only).

Success criteria: the user has explicitly approved the schema; the JSON parses;
the documented shape maps cleanly onto the frontend `BoardData` type.

---

## Part 6: Backend

Implement the schema and the CRUD API.

- [ ] `backend/app/schema.sql` - the approved DDL
- [ ] `backend/app/db.py` - connection helper, `DB_PATH` from env, foreign keys on, create the database and schema if absent, seed the `user` account plus one board with the five columns and the demo cards on first run, idempotent
- [ ] Move the Part 4 credential check onto the `users` table
- [ ] Pydantic models for board, column, and card payloads
- [ ] Routes, all requiring `current_user` and scoped to that user's board:
  - `GET /api/board` - the whole board in the frontend `BoardData` shape
  - `PATCH /api/columns/{id}` - rename
  - `POST /api/cards` - create (column id, title, details)
  - `PATCH /api/cards/{id}` - edit title or details
  - `DELETE /api/cards/{id}`
  - `POST /api/cards/{id}/move` - target column id and index, renumbers positions
- [ ] Repository functions kept separate from the route handlers so Part 9 can reuse them
- [ ] Update `backend/CLAUDE.md`

Tests (`pytest`, each against a fresh temporary database):
- A missing database file is created, seeded, and the seed is not duplicated on a second start
- `GET /api/board` returns the seeded shape and matches the frontend type
- Rename a column; it persists across a re-read
- Create, edit, and delete a card; deleting renumbers the remaining positions
- Move a card within a column, to another column, to an empty column, and to the first and last index; positions stay contiguous in every case
- Every route returns 401 without a session
- One user cannot read or modify another user's board (create a second user directly in the database)
- Unknown card id and unknown column id return 404; a move to a column on another board returns 404

Success criteria: full CRUD works, the database is created from nothing,
ordering is always contiguous, cross-user access is impossible, and `pytest`
passes with the whole route layer covered.

---

## Part 7: Frontend plus Backend

Replace local state with the API so the board actually persists.

- [ ] `frontend/src/lib/api.ts` - typed client for every Part 6 route
- [ ] `KanbanBoard` loads the board from `GET /api/board` on mount, with loading and error states
- [ ] Every mutation (rename, add, edit, delete, move) calls the API; apply optimistically and roll back on failure
- [ ] Debounce column rename so a keystroke does not become one request per character
- [ ] Remove `initialData` from the runtime path (the seed now lives in the backend); keep it only if tests need a fixture
- [ ] Update `frontend/CLAUDE.md`

Tests:
- `vitest` with the client mocked: initial load renders the fetched board; each mutation issues the right request; a failed request rolls the UI back and surfaces an error; rename debouncing collapses rapid keystrokes into one request
- `pytest` - unchanged, still green
- Playwright against the container: log in, drag a card to another column, reload, the card is still there; rename a column, reload, the name persists; add a card, reload, it persists; edit a card, reload, it persists; delete a card, reload, it stays deleted

Success criteria: every change survives a reload and a container restart; no
board state remains in the frontend as the source of truth; all suites pass.

---

## Part 8: AI connectivity

- [ ] `backend/app/ai.py` - `httpx` client for OpenRouter chat completions, key and model from env, sensible timeout, clear error when the key is missing
- [ ] `POST /api/ai/ping` - sends "what is 2+2" and returns the reply (temporary, removed in Part 9)
- [ ] Document the model choice and the verified fallbacks in `backend/CLAUDE.md`

Tests:
- `pytest` with the OpenRouter call mocked: a successful response is parsed, an HTTP error surfaces as a clean 502, a missing key returns a clear error, and the request carries the right model and auth header
- One live integration test, skipped when `OPENROUTER_API_KEY` is absent, asserting the model answers 4

Success criteria: a live call through the container returns 4; the mocked tests
cover the failure paths; the key is never logged.

---

## Part 9: AI with board context and structured outputs

- [ ] Define the response schema: `{ reply: string, board_updates: [...] | null }`, where each update is one of create card, edit card, move card, delete card, rename column
- [ ] Pydantic models mirroring that schema, and a strict `json_schema` sent as `response_format`
- [ ] Prompt builder: system prompt describing the board and the allowed operations, the current board JSON, the persisted conversation history, and the user question
- [ ] `POST /api/ai/chat` - authenticated; persists the user message, calls the model, applies any `board_updates` through the Part 6 repository functions, persists the assistant reply, returns `{ reply, board_changed, board }`
- [ ] `GET /api/ai/messages` - conversation history for the board
- [ ] Validate every update before applying: unknown ids are rejected, and the whole batch is applied in one transaction or not at all
- [ ] Remove `/api/ai/ping`
- [ ] Update `backend/CLAUDE.md`

Tests (`pytest`, model mocked unless stated):
- A reply with no updates leaves the board untouched
- Each update type applies correctly: create, edit, move, delete, rename
- A batch of several updates applies in order
- An update naming an unknown card or column is rejected and nothing in the batch is applied
- An update targeting another user's board is rejected
- Malformed model output returns a clean error and leaves the board untouched
- History is persisted and passed back to the model on the next turn
- Live integration test, skipped without a key: "move Ship marketing page to Done" actually moves the card

Success criteria: the model can read the board and change it through structured
outputs; invalid updates never corrupt the board; failures are atomic; all
suites pass.

---

## Part 10: AI chat sidebar

- [ ] `frontend/src/components/ChatSidebar.tsx` - collapsible right sidebar in the project palette, message list with user and assistant styling, input with send, in-flight indicator, error state, autoscroll
- [ ] Loads history from `GET /api/ai/messages` on mount
- [ ] Sends to `POST /api/ai/chat`; when the response reports `board_changed`, refresh the board from the returned payload so the UI updates without a reload
- [ ] Layout: board and sidebar side by side on wide screens, sidebar collapses to a toggle on narrow ones
- [ ] Keyboard: Enter sends, Shift plus Enter inserts a newline
- [ ] Update `frontend/CLAUDE.md`; final pass on the root `README.md`

Tests:
- `vitest` - history renders on mount; sending appends the user message then the reply; a `board_changed` response updates the board; an API error shows a message and keeps the typed input; the in-flight state disables send
- Playwright against the container with a live key (skipped without one): log in, open the sidebar, ask the AI to move a named card to Done, the card visibly moves without a reload, and the move survives a reload
- Full run: `pytest`, `npm run test:unit`, and `npm run test:e2e` all green

Success criteria: chatting with the AI updates the board live; the conversation
persists across reloads; the whole app runs from a single start script on a
clean machine with only Docker and a `.env`.
