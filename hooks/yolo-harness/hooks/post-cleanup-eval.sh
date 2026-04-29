#!/usr/bin/env bash
# =============================================================================
# post-cleanup-eval.sh — Yolo harness worktree-cleanup eval trigger
# -----------------------------------------------------------------------------
# Called from session-wrap-up.sh (or directly by the harness teardown) after
# engineer worktrees have been merged + cleaned up. Records a /bmad:eval --auto
# snapshot tagged with _trigger=worktree-cleanup so the dashboard can correlate
# productivity metrics with each merged sprint wave.
# =============================================================================

set -uo pipefail

[ -d .bmad ] || exit 0

RUNNER=""
for c in scripts/bmad-eval-run.sh \
         "$HOME/.bmad/scripts/bmad-eval-run.sh" \
         "$HOME/bmad-sdlc-agents/scripts/bmad-eval-run.sh"; do
  [ -f "$c" ] && RUNNER="$c" && break
done
[ -z "$RUNNER" ] && exit 0

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "?")
bash "$RUNNER" \
  --trigger=worktree-cleanup \
  --note="branch: ${branch}" \
  --debounce=10 \
  >/dev/null 2>&1 || true
exit 0
