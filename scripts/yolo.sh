#!/bin/bash
# BMAD Yolo Mode Toggle — Effective Harness Edition
#
# Enables/disables Claude Code Yolo mode with a safety harness.
#
# Yolo mode:    All tool calls execute without confirmation prompts.
# Harness:      Pre-hooks block irreversible commands, create git checkpoints
#               before every file write, log all writes, and wrap up on Stop.
#
# Usage:
#   ./scripts/yolo.sh on     — activate Yolo + Harness for this project
#   ./scripts/yolo.sh off    — restore original project settings
#   ./scripts/yolo.sh status — show current mode

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
YOLO_SETTINGS="$BASE_DIR/hooks/yolo-harness/settings.json"
YOLO_HOOKS_SRC="$BASE_DIR/hooks/yolo-harness/hooks"

CLAUDE_DIR=".claude"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
SETTINGS_BACKUP="$CLAUDE_DIR/settings.backup.json"
YOLO_HOOKS_DEST="$CLAUDE_DIR/hooks/yolo"
YOLO_MARKER="$CLAUDE_DIR/.yolo-active"

ACTION="${1:-}"

# ── Helpers ────────────────────────────────────────────────────────────────────

check_project_root() {
  if [[ ! -d ".bmad" ]]; then
    echo -e "${RED}Error: Must be run from a BMAD project root (no .bmad/ directory found).${NC}"
    echo "Run scaffold-project.sh first, or cd to your project root."
    exit 1
  fi
}

print_header() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  ⚡ BMAD Yolo Mode — Effective Harness${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo ""
}

# ── Status ─────────────────────────────────────────────────────────────────────

cmd_status() {
  print_header
  if [[ -f "$YOLO_MARKER" ]]; then
    ACTIVATED_AT=$(cat "$YOLO_MARKER" 2>/dev/null || echo "unknown")
    echo -e "  Status:  ${GREEN}● ACTIVE${NC} (since $ACTIVATED_AT)"
    echo -e "  Settings: $SETTINGS_FILE → yolo-harness config"
    echo -e "  Hooks:    $YOLO_HOOKS_DEST/"
    echo ""
    echo -e "  Harness guards:"
    echo -e "    ${GREEN}✓${NC} Irreversible bash commands blocked"
    echo -e "    ${GREEN}✓${NC} Git WIP checkpoint before every file write"
    echo -e "    ${GREEN}✓${NC} All file writes logged to .bmad/yolo-session-log.md"
    echo -e "    ${GREEN}✓${NC} Session summary printed on Stop"
    echo -e "    ${GREEN}✓${NC} Autonomous agent chaining active (.bmad/signals/autonomous-mode)"
    echo ""
    echo -e "  To disable: ${CYAN}./scripts/yolo.sh off${NC}"
  else
    echo -e "  Status:  ${YELLOW}○ INACTIVE${NC} (standard project settings active)"
    echo ""
    echo -e "  To enable: ${CYAN}./scripts/yolo.sh on${NC}"
  fi
  echo ""
}

# ── On ─────────────────────────────────────────────────────────────────────────

cmd_on() {
  check_project_root
  print_header

  if [[ -f "$YOLO_MARKER" ]]; then
    echo -e "  ${YELLOW}Yolo mode is already active.${NC}"
    echo -e "  Run ${CYAN}./scripts/yolo.sh status${NC} for details."
    echo ""
    exit 0
  fi

  # Validate source files exist
  if [[ ! -f "$YOLO_SETTINGS" ]]; then
    echo -e "${RED}Error: Yolo harness settings not found at:${NC}"
    echo "  $YOLO_SETTINGS"
    echo "Re-run the BMAD install script or check your bmad-sdlc-agents installation."
    exit 1
  fi

  # Ensure .claude/ exists
  mkdir -p "$CLAUDE_DIR/hooks"

  # Back up current settings if present
  if [[ -f "$SETTINGS_FILE" ]]; then
    cp "$SETTINGS_FILE" "$SETTINGS_BACKUP"
    echo -e "  ${GREEN}✓${NC} Backed up current settings → $SETTINGS_BACKUP"
  fi

  # Install yolo-harness settings
  cp "$YOLO_SETTINGS" "$SETTINGS_FILE"
  echo -e "  ${GREEN}✓${NC} Installed yolo-harness settings → $SETTINGS_FILE"

  # Install harness hook scripts
  mkdir -p "$YOLO_HOOKS_DEST"
  cp "$YOLO_HOOKS_SRC"/*.sh "$YOLO_HOOKS_DEST/"
  chmod +x "$YOLO_HOOKS_DEST"/*.sh
  echo -e "  ${GREEN}✓${NC} Installed harness hooks → $YOLO_HOOKS_DEST/"

  # Activate autonomous agent chaining
  mkdir -p .bmad/signals
  touch .bmad/signals/autonomous-mode
  echo -e "  ${GREEN}✓${NC} Autonomous agent chaining enabled → .bmad/signals/autonomous-mode"

  # Write marker
  date "+%Y-%m-%d %H:%M:%S" > "$YOLO_MARKER"

  echo ""
  echo -e "  ${GREEN}⚡ Yolo mode ACTIVE with Effective Harness${NC}"
  echo ""
  echo -e "  ${CYAN}What this means:${NC}"
  echo "  • Claude Code will NOT ask for confirmation on any tool call"
  echo "  • All tool calls (Bash, Write, Edit, Glob, etc.) auto-approved"
  echo ""
  echo -e "  ${CYAN}Harness guardrails still enforced:${NC}"
  echo "  • Irreversible commands blocked (rm -rf /, git push --force, DROP TABLE, etc.)"
  echo "  • git push --force and --no-verify always denied"
  echo "  • Git WIP checkpoint auto-created before every file write"
  echo "  • All writes logged to .bmad/yolo-session-log.md"
  echo "  • Session diff summary printed when Claude finishes"
  echo ""
  echo -e "  ${YELLOW}Start your Claude Code session now:${NC}"
  echo -e "  ${CYAN}claude --agent tech-lead${NC}  (for TL-orchestrated sprint)"
  echo -e "  ${CYAN}claude${NC}                    (for any other session)"
  echo ""
  echo -e "  To turn off: ${CYAN}./scripts/yolo.sh off${NC}"
  echo ""
}

# ── Off ────────────────────────────────────────────────────────────────────────

cmd_off() {
  check_project_root
  print_header

  if [[ ! -f "$YOLO_MARKER" ]]; then
    echo -e "  ${YELLOW}Yolo mode is not currently active.${NC}"
    echo ""
    exit 0
  fi

  # Restore original settings
  if [[ -f "$SETTINGS_BACKUP" ]]; then
    cp "$SETTINGS_BACKUP" "$SETTINGS_FILE"
    rm -f "$SETTINGS_BACKUP"
    echo -e "  ${GREEN}✓${NC} Restored original settings from backup"
  else
    # No backup means there was no settings.json before — remove the yolo one
    rm -f "$SETTINGS_FILE"
    echo -e "  ${GREEN}✓${NC} Removed yolo-harness settings (no original to restore)"
  fi

  # Remove harness hooks
  if [[ -d "$YOLO_HOOKS_DEST" ]]; then
    rm -rf "$YOLO_HOOKS_DEST"
    echo -e "  ${GREEN}✓${NC} Removed harness hooks from $YOLO_HOOKS_DEST"
  fi

  # Deactivate autonomous agent chaining
  rm -f .bmad/signals/autonomous-mode
  # Clear planning-phase sentinels
  rm -f .bmad/signals/ba-done .bmad/signals/po-done .bmad/signals/sa-done \
        .bmad/signals/ea-done .bmad/signals/ux-done .bmad/signals/tl-plan-done
  # Clear execution-phase E2 sentinels (ready, done, and rework for all engineer roles)
  rm -f .bmad/signals/E2-be-ready .bmad/signals/E2-fe-ready .bmad/signals/E2-me-ready
  rm -f .bmad/signals/E2-be-done  .bmad/signals/E2-fe-done  .bmad/signals/E2-me-done
  rm -f .bmad/signals/E2-be-rework .bmad/signals/E2-fe-rework .bmad/signals/E2-me-rework
  echo -e "  ${GREEN}✓${NC} Autonomous agent chaining disabled — all signals cleared"

  # Remove marker
  rm -f "$YOLO_MARKER"

  echo ""
  echo -e "  ${GREEN}✓ Yolo mode DEACTIVATED — standard settings restored${NC}"
  echo ""

  # Remind about WIP commits
  if git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
    WIP_COUNT=$(git log --oneline --grep="yolo-harness: WIP checkpoint" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$WIP_COUNT" -gt 0 ]]; then
      echo -e "  ${YELLOW}⚠️  $WIP_COUNT WIP checkpoint commit(s) from your Yolo session remain.${NC}"
      echo "  Squash them into a clean commit before pushing:"
      echo -e "  ${CYAN}git rebase -i HEAD~$((WIP_COUNT + 1))${NC}"
      echo ""
    fi
  fi

  echo -e "  Session log preserved at: ${CYAN}.bmad/yolo-session-log.md${NC}"
  echo ""
}

# ── Dispatch ───────────────────────────────────────────────────────────────────

case "$ACTION" in
  on)     cmd_on ;;
  off)    cmd_off ;;
  status) cmd_status ;;
  *)
    echo ""
    echo -e "${BLUE}Usage:${NC} ./scripts/yolo.sh <on|off|status>"
    echo ""
    echo "  on      Activate Yolo mode + Effective Harness for this project"
    echo "  off     Restore original settings and remove harness hooks"
    echo "  status  Show whether Yolo mode is currently active"
    echo ""
    exit 1
    ;;
esac
