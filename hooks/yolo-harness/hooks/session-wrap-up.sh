#!/bin/bash
# BMAD Yolo Harness — Stop: session wrap-up
# Runs when Claude Code finishes a Yolo session. Prints a git diff summary,
# finalises the session log, and prompts for a clean commit.

LOG_FILE=".bmad/yolo-session-log.md"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  🛑 BMAD Yolo Session Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# ── Git summary ───────────────────────────────────────────────────────────────
if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  echo ""
  echo "  Branch: $BRANCH"
  echo ""

  DIRTY=$(git status --porcelain 2>/dev/null)
  if [[ -n "$DIRTY" ]]; then
    echo "  📝 Uncommitted changes:"
    git diff --stat HEAD 2>/dev/null | sed 's/^/     /'
    echo ""
    echo "  ⚠️  Run: git add -A && git commit -m '<your message>'"
    echo "      to finalise this Yolo session's changes."
  else
    echo "  ✅ All changes committed (WIP checkpoints were auto-committed)."
    echo "     Consider squashing WIP commits: git rebase -i HEAD~<n>"
  fi

  # Show WIP checkpoint commits from this session for easy squash reference
  WIP_COUNT=$(git log --oneline --grep="yolo-harness: WIP checkpoint" 2>/dev/null | wc -l | tr -d ' ')
  if [[ "$WIP_COUNT" -gt 0 ]]; then
    echo ""
    echo "  🔁 $WIP_COUNT WIP checkpoint commit(s) created during this session."
    echo "     Squash them into a clean commit before pushing:"
    echo "     git rebase -i HEAD~$((WIP_COUNT + 1))"
  fi
else
  echo "  (Not a git repo — no git summary available)"
fi

# ── Finalise session log ──────────────────────────────────────────────────────
if [[ -f "$LOG_FILE" ]]; then
  echo "" >> "$LOG_FILE"
  echo "---" >> "$LOG_FILE"
  echo "" >> "$LOG_FILE"
  echo "**Session ended:** $TIMESTAMP" >> "$LOG_FILE"
  FILE_COUNT=$(grep -c "^|" "$LOG_FILE" 2>/dev/null || echo 0)
  echo "**Total files written:** $((FILE_COUNT - 1))" >> "$LOG_FILE"
  echo ""
  echo "  📋 Session log: $LOG_FILE"
fi

echo ""
echo "  To turn off Yolo mode: ./scripts/yolo.sh off"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Productivity snapshot (silent) ────────────────────────────────────────────
# Records a /bmad:eval --auto snapshot tagged worktree-cleanup so the dashboard
# can track Yolo-driven productivity over time. No-op outside BMAD projects.
HOOK_DIR="$(dirname "${BASH_SOURCE[0]}")"
[ -f "$HOOK_DIR/post-cleanup-eval.sh" ] && bash "$HOOK_DIR/post-cleanup-eval.sh" || true

exit 0
