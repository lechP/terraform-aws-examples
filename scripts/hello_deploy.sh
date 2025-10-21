#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"

echo "Deploy placeholder"
echo "Environment: ${ENVIRONMENT}"
echo "(Future spot for: terraform init/plan/apply)"

