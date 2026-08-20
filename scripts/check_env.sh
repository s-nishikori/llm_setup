#!/usr/bin/env bash
set -Eeuo pipefail

echo "== GPU =="
nvidia-smi

echo
echo "== Commands =="
for command_name in python vllm hf; do
  if command -v "${command_name}" >/dev/null 2>&1; then
    printf '%-8s %s\n' "${command_name}" "$(command -v "${command_name}")"
  else
    printf '%-8s %s\n' "${command_name}" "NOT FOUND"
  fi
done

echo
echo "== Python packages =="
python - <<'PY'
import importlib

for name in ("torch", "vllm", "huggingface_hub"):
    try:
        module = importlib.import_module(name)
        print(f"{name}: {getattr(module, '__version__', 'unknown')}")
    except Exception as exc:
        print(f"{name}: unavailable ({exc})")

try:
    import torch
    print(f"CUDA available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"GPU: {torch.cuda.get_device_name(0)}")
except Exception:
    pass
PY
