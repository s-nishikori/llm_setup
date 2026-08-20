#!/usr/bin/env bash

set -Eeuo pipefail

PROJECT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

load_env() {
  if [[ -f "${PROJECT_DIR}/.env" ]]; then
    set -a
    # shellcheck disable=SC1091
    source "${PROJECT_DIR}/.env"
    set +a
  fi
}
require_value() {
  local name="$1"
  local value="${!name:-}"
  if [[ -z "${value}" || "${value}" == REPLACE_WITH_* ]]; then
    echo "ERROR: ${name} is not configured in .env" >&2
    exit 1
  fi
}
