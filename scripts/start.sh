#!/usr/bin/env bash
# Build the image and run the app at http://localhost:8000
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

docker build -t pm-app .
docker rm -f pm-app >/dev/null 2>&1 || true

# Plain string, not an array: expanding an empty array under "set -u" is an
# error on bash 3.2, which is what macOS ships. Unquoted is safe here because
# the value never contains spaces.
env_arg=""
if [ -f .env ]; then
  env_arg="--env-file .env"
fi

docker run -d --name pm-app -p 8000:8000 -v pm-data:/app/data $env_arg pm-app >/dev/null

# The container is up before uvicorn is listening, so wait for a real response
# rather than claiming the app is ready when it is not.
printf "Starting"
for _ in $(seq 1 60); do
  if curl -fsS http://localhost:8000/api/health >/dev/null 2>&1; then
    printf "\nRunning at http://localhost:8000\n"
    exit 0
  fi
  printf "."
  sleep 0.5
done

printf "\nServer did not respond in time. Check: docker logs pm-app\n" >&2
exit 1
