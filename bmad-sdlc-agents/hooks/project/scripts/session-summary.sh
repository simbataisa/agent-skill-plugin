#!/usr/bin/env bash
set -euo pipefail

# Session summary when Claude stops
# Lists files modified in the last hour and summarizes changes

# Find files modified in the last hour under docs/ and src/
modified_count=0

if [[ -d docs ]]; then
  modified_count=$(find docs -type f -mmin -60 2>/dev/null | wc -l)
fi

if [[ -d src ]]; then
  modified_count=$((modified_count + $(find src -type f -mmin -60 2>/dev/null | wc -l)))
fi

# Print session summary
if [[ ${modified_count} -gt 0 ]]; then
  echo "📋 BMAD Session Summary: ${modified_count} files written. Check .bmad/handoff-log.md for details."
else
  echo "📋 BMAD Session Summary: No files modified in the last hour."
fi

exit 0
