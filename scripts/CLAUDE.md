# Scripts

Start and stop the app container.

- `start.sh` / `start.ps1` - build the `pm-app` image from the repo root Dockerfile, remove any existing `pm-app` container, then run a new one detached on port 8000 with the `pm-data` volume mounted at `/app/data`. Passes `--env-file .env` when that file exists. Both resolve paths relative to the script, so they work from any working directory.
- `stop.sh` / `stop.ps1` - remove the `pm-app` container. The `pm-data` volume is deliberately left alone so the database survives a restart.

Use the `.sh` pair on Mac and Linux, the `.ps1` pair on Windows.

## Traps these scripts already work around

Keep these patterns when editing.

- **Readiness.** `docker run -d` returns well before uvicorn is listening, about two seconds on this machine. Both start scripts poll `/api/health` before printing the URL, so the message is not a lie.
- **`docker rm -f` exit status.** On Docker 27 it exits 0 even when the container does not exist, so its status cannot tell you whether anything was running. Both stop scripts query `docker ps -aq -f 'name=^pm-app$'` first.
- **PowerShell native stderr.** Windows PowerShell 5.1 turns a native command's stderr into a terminating error when redirected, and `docker rm` on a missing container writes to stderr. Do not use `2>$null` on `docker` here.
- **bash 3.2.** macOS ships bash 3.2, where expanding an empty array under `set -u` is an error. `start.sh` builds the optional `--env-file` argument as a plain string instead of an array.
