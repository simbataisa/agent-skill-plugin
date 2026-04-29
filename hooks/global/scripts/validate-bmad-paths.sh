#!/usr/bin/env bash
set -euo pipefail

# Validate BMAD project paths before file writes
# Takes $1 as the file path being written
# Warns if writing outside allowed BMAD directories

target_path="${1:-.}"

# Check if .bmad/ exists (is a BMAD project)
if [[ -d .bmad ]]; then
  # Check if the path is within allowed directories
  case "${target_path}" in
    docs/*|.bmad/*|src/*|tests/*|*.md)
      # Path is allowed
      exit 0
      ;;
    *)
      # Path is outside allowed directories
      echo "⚠️  BMAD: Writing to '${target_path}' — ensure this is intentional. BMAD artifacts should go in docs/" >&2
      exit 0
      ;;
  esac
fi

exit 0
