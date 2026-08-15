#!/bin/sh
set -eu

exec /opt/manager/ManagerServer \
  --urls "${MANAGER_URLS:-http://0.0.0.0:8080}" \
  --path "${MANAGER_DATA_PATH:-/data}" \
  "$@"

