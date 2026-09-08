#!/usr/bin/env bash
# Stop and remove the app container. The pm-data volume is left intact.
set -euo pipefail

# Query first: "docker rm -f" exits 0 even when the container does not exist,
# so its status cannot tell us whether anything was actually running.
if [ -n "$(docker ps -aq -f 'name=^pm-app$')" ]; then
  docker rm -f pm-app >/dev/null
  echo "Stopped."
else
  echo "Not running."
fi
