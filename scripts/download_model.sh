#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
load_env
require_value MODEL_ID

MODEL_DIR="${MODEL_DIR:-/workspace/models/qwen}"
mkdir -p "${MODEL_DIR}"

args=(download "${MODEL_ID}" --local-dir "${MODEL_DIR}")
if [[ -n "${HF_TOKEN:-}" ]]; then
  args+=(--token "${HF_TOKEN}")
fi

echo "Downloading ${MODEL_ID} to ${MODEL_DIR}"
hf "${args[@]}"
echo "Download complete."
