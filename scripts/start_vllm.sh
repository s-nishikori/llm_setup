#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib.sh
source "${SCRIPT_DIR}/lib.sh"
load_env
require_value VLLM_API_KEY

MODEL_DIR="${MODEL_DIR:-/workspace/models/qwen}"
MODEL_ID="${MODEL_ID:-}"
SERVED_MODEL_NAME="${SERVED_MODEL_NAME:-qwen}"
HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8000}"
MAX_MODEL_LEN="${MAX_MODEL_LEN:-16384}"
GPU_MEMORY_UTILIZATION="${GPU_MEMORY_UTILIZATION:-0.90}"
TENSOR_PARALLEL_SIZE="${TENSOR_PARALLEL_SIZE:-1}"

if [[ -f "${MODEL_DIR}/config.json" ]]; then
  model_source="${MODEL_DIR}"
else
  require_value MODEL_ID
  model_source="${MODEL_ID}"
  echo "Local model not found; vLLM will load ${MODEL_ID} through Hugging Face."
fi

args=(
  serve "${model_source}"
  --served-model-name "${SERVED_MODEL_NAME}"
  --host "${HOST}"
  --port "${PORT}"
  --dtype auto
  --max-model-len "${MAX_MODEL_LEN}"
  --gpu-memory-utilization "${GPU_MEMORY_UTILIZATION}"
  --tensor-parallel-size "${TENSOR_PARALLEL_SIZE}"
  --api-key "${VLLM_API_KEY}"
)

if [[ -n "${VLLM_EXTRA_ARGS:-}" ]]; then
  # This field intentionally accepts shell-style, space-separated vLLM flags.
  read -r -a extra_args <<< "${VLLM_EXTRA_ARGS}"
  args+=("${extra_args[@]}")
fi

echo "Starting vLLM as '${SERVED_MODEL_NAME}' at ${HOST}:${PORT}"
exec vllm "${args[@]}"
