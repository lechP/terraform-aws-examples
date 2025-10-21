#!/usr/bin/env bash
set -euo pipefail

ENVIRONMENT="${1:-dev}"

echo "Destroy placeholder"
echo "Environment: ${ENVIRONMENT}"
echo "(Future spot for: terraform destroy)"

