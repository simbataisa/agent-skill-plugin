#!/usr/bin/env bash
set -euo pipefail

# Enforce team conventions from .bmad/team-conventions.md
# Takes $1 as file path, $2 as content (or reads stdin)

file_path="${1:-.}"
content="${2:-.}"

# Return early if no .bmad/team-conventions.md exists
if [[ ! -f .bmad/team-conventions.md ]]; then
  exit 0
fi

# Check test file naming conventions
if [[ "${file_path}" == *test* ]] || [[ "${file_path}" == *_test* ]]; then
  case "${file_path}" in
    *.test.ts)
      # Correct TypeScript test format
      ;;
    *_test.go)
      # Correct Go test format
      ;;
    *test_*.py)
      # Correct Python test format
      ;;
    *.test.ts|*_test.go|*test_*.py)
      # Already in correct format
      ;;
    *)
      # Check if it should be a test file and isn't in correct format
      if [[ "${file_path}" == *test* ]]; then
        echo "⚠️  BMAD: Test file '${file_path}' should follow naming convention (.test.ts, _test.go, or test_.py)" >&2
      fi
      ;;
  esac
fi

# Check migration file naming conventions
if [[ "${file_path}" == db/migrations/* ]]; then
  if [[ ! "${file_path}" =~ V[0-9]+__.*\.sql ]]; then
    echo "⚠️  BMAD: Migration file '${file_path}' should follow pattern V{N}__{desc}.sql (e.g., V001__init_schema.sql)" >&2
  fi
fi

exit 0
