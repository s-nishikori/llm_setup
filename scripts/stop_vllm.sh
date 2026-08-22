#!/usr/bin/env bash
set -Eeuo pipefail

mapfile -t pids < <(pgrep -f '[v]llm serve' || true)

if (( ${#pids[@]} == 0 )); then
  echo "vLLM is not running."
  exit 0
fi

echo "Stopping vLLM process(es): ${pids[*]}"
kill -TERM "${pids[@]}"

for _ in {1..10}; do
  remaining=()
  for pid in "${pids[@]}"; do
    if kill -0 "${pid}" 2>/dev/null; then
      remaining+=("${pid}")
    fi
  done
  if (( ${#remaining[@]} == 0 )); then
    echo "vLLM stopped."
    exit 0
  fi
  sleep 1
done

echo "vLLM did not stop within 10 seconds: ${remaining[*]}" >&2
echo "Inspect these processes before forcing them to stop." >&2
exit 1
