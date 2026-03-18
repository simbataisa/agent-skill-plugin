#!/usr/bin/env bash
set -euo pipefail

# Auto-append to .bmad/handoff-log.md when key artifacts are written
# Takes $1 as the file path written

file_path="${1:-.}"

# Check if path is under docs/ and is a significant artifact
case "${file_path}" in
  docs/project-brief.md|docs/prd.md|docs/solution-architecture.md|docs/enterprise-architecture.md|docs/design-system.md)
    # Create .bmad/handoff-log.md if it doesn't exist
    if [[ ! -f .bmad/handoff-log.md ]]; then
      mkdir -p .bmad
      echo "# BMAD Handoff Log" > .bmad/handoff-log.md
    fi

    # Append timestamped entry
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "<!-- auto: [${timestamp}] artifact written: ${file_path} -->" >> .bmad/handoff-log.md
    ;;
esac

exit 0
