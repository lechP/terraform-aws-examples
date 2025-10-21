#!/usr/bin/env bash
set -euo pipefail

echo "Hello from CI!"
echo "Repo: ${GITHUB_REPOSITORY:-unknown}"
echo "Commit: ${GITHUB_SHA:-unknown}"
echo "Run URL: https://github.com/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID:-}"

