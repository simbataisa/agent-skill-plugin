#!/usr/bin/env bash
# =============================================================================
# auto-eval-on-sprint-results.sh — PostToolUse hook for sprint completion
# -----------------------------------------------------------------------------
# Wired into hooks/project/settings.json on the `Write` matcher. Triggers
# /bmad:eval --auto when Claude writes a sprint results file
# (docs/testing/sprint-N-results.md) — that's the natural "sprint cycle done"
# moment.
#
# Args: $1 = path to the file just written.
# Returns: always exits 0 so it never blocks Claude.
# =============================================================================

set -uo pipefail

file_path="${1:-}"
case "$file_path" in
  docs/testing/sprint-*-results.md) ;;
  *) exit 0 ;;
esac

# Locate the runner.
RUNNER=""
for c in scripts/bmad-eval-run.sh \
         "$HOME/.bmad/scripts/bmad-eval-run.sh" \
         "$HOME/bmad-sdlc-agents/scripts/bmad-eval-run.sh"; do
  [ -f "$c" ] && RUNNER="$c" && break
done
[ -z "$RUNNER" ] && exit 0

# Extract the sprint number for the note (e.g. "sprint 7 results").
sprint_n=$(echo "$file_path" | sed -nE 's@.*/sprint-([0-9]+)-results\.md@\1@p')

bash "$RUNNER" \
  --trigger=sprint-results \
  --note="sprint-${sprint_n:-?} results written: ${file_path}" \
  --debounce=15 \
  >/dev/null 2>&1 || true
exit 0
