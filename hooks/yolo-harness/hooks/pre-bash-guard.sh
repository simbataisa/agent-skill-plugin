#!/bin/bash
# BMAD Yolo Harness — PreToolUse: Bash guard
# Blocks irreversible or globally destructive bash commands even in Yolo mode.
# Exit 2 to block the command (Claude Code treats non-zero as block).
# Exit 0 to allow.

COMMAND="${1:-}"

# ── Patterns that are ALWAYS blocked in Yolo mode ─────────────────────────────

BLOCKED_PATTERNS=(
  # Recursive force-delete of root or home
  "rm -rf /"
  "rm -rf ~"
  "rm -rf \$HOME"
  # Force-push to any remote (deny list in settings.json catches git push --force,
  # but guard against variations here too)
  "git push --force"
  "git push -f"
  # Skip hooks — never bypass quality gates
  "--no-verify"
  # Drop/truncate production database tables
  "DROP TABLE"
  "DROP DATABASE"
  "TRUNCATE TABLE"
  # Disk formatting
  "mkfs"
  "fdisk"
  "dd if=/dev/zero"
  # Shutdown / reboot
  "shutdown"
  "reboot"
  "halt"
  "poweroff"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qi "$pattern"; then
    echo "🚫 [YOLO HARNESS] Blocked: command matches guardrail pattern '$pattern'" >&2
    echo "   Command: $COMMAND" >&2
    echo "   Disable Yolo mode (./scripts/yolo.sh off) and run manually if intentional." >&2
    exit 2
  fi
done

# ── Warn (but allow) on moderately risky patterns ─────────────────────────────

WARN_PATTERNS=(
  "git reset --hard"
  "git clean -f"
  "git checkout -- ."
  "rm -rf"
)

for pattern in "${WARN_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qi "$pattern"; then
    echo "⚠️  [YOLO HARNESS] Warning: potentially destructive command detected." >&2
    echo "   Command: $COMMAND" >&2
    echo "   Proceeding (allowed in Yolo mode — ensure git checkpoint exists)." >&2
    break
  fi
done

exit 0
