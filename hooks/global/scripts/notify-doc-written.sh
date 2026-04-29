#!/usr/bin/env bash
set -euo pipefail

# Notify when a file is written to docs/
# Takes $1 as the file path

file_path="${1:-.}"

# Check if path starts with docs/
if [[ "${file_path}" == docs/* ]]; then
  echo "📄 BMAD artifact written: ${file_path}"
fi

exit 0
