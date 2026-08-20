#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
load_env
require_value VLLM_API_KEY

HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"
SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-qwen}"
base_url="http://${HOST}:${PORT}/v1"

curl --fail --silent --show-error "${base_url}/models" \
  -H "Authorization: Bearer ${VLLM_API_KEY}"
echo
curl --fail --silent --show-error "${base_url}/chat/completions" \
  -H "Authorization: Bearer ${VLLM_API_KEY}" \
  -H "Content-Type: application/json" \
  --data "{\"model\":\"${SERVED_MODEL_NAME}\",\"messages\":[{\"role\":\"user\",\"content\":\"Hello. Reply with one short sentence.\"}],\"max_tokens\":64}"
echo
