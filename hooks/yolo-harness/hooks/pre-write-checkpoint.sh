#!/bin/bash
# BMAD Yolo Harness — PreToolUse: Write/Edit/MultiEdit checkpoint
# Creates a git WIP checkpoint before Claude writes to a file, so every
# file change is recoverable via git even when running without confirmations.
# Exit 0 always — this hook is advisory/checkpoint only, never blocks writes.

FILE_PATH="${1:-}"

# Only checkpoint if inside a git repo
if ! git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  exit 0
fi

# Check if there are already staged/unstaged changes that haven't been checkpointed
DIRTY=$(git status --porcelain 2>/dev/null)

if [[ -n "$DIRTY" ]]; then
  # Create a WIP checkpoint commit on current branch
  TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
  git add -A &>/dev/null 2>&1
  git commit -m "chore(yolo-harness): WIP checkpoint before write — $TIMESTAMP

Auto-checkpoint created by BMAD Yolo Harness pre-write hook.
Triggered by: write to $FILE_PATH
This commit is safe to squash/rebase after the Yolo session ends." \
    --no-verify &>/dev/null 2>&1 || true
  # '--no-verify' is intentional here: this is an automated safety commit,
  # not a code quality commit. The real commit comes after the session.
fi

exit 0
