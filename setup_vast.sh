#!/usr/bin/env bash
set -euo pipefail

repo_url="https://github.com/s-nishikori/llm_setup.git"
target_dir="/workspace/llm_setup"

if ! command -v git >/dev/null 2>&1; then
    echo "git is not installed on the Vast.ai instance." >&2
    exit 1
fi

mkdir -p "$(dirname "$target_dir")"

if [[ -d "$target_dir/.git" ]]; then
    echo "Repository already exists; pulling the latest changes."
    git -C "$target_dir" pull --ff-only
elif [[ -e "$target_dir" ]]; then
    echo "$target_dir already exists but is not a Git repository." >&2
    exit 1
else
    git clone "$repo_url" "$target_dir"
fi

echo "Repository is ready at $target_dir"
