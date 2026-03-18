#!/usr/bin/env bash
set -euo pipefail

# Check BMAD context is loaded before tool use
# Verifies PROJECT-CONTEXT.md exists and is properly configured

# Check if PROJECT-CONTEXT.md exists
if [[ ! -f .bmad/PROJECT-CONTEXT.md ]]; then
  echo "ℹ️  BMAD: No .bmad/PROJECT-CONTEXT.md found. Run: bmad-scaffold <project-name> to initialize." >&2
  exit 0
fi

# Check if the file still has placeholder text
if grep -q "\[Project Name\]" .bmad/PROJECT-CONTEXT.md 2>/dev/null; then
  echo "⚠️  BMAD: PROJECT-CONTEXT.md has not been filled in yet." >&2
fi

exit 0
