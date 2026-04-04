#!/bin/bash
# BMAD Yolo Harness — PostToolUse: Write/Edit/MultiEdit logger
# Appends every file write to .bmad/yolo-session-log.md so there's a full
# audit trail of what Claude touched during the Yolo session.
# Exit 0 always — never blocks the post-tool result.

FILE_PATH="${1:-}"
LOG_FILE=".bmad/yolo-session-log.md"
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# Ensure .bmad/ exists
mkdir -p .bmad

# Bootstrap the log if this is the first write this session
if [[ ! -f "$LOG_FILE" ]]; then
  cat > "$LOG_FILE" <<EOF
# BMAD Yolo Session Log

**Mode:** Yolo + Effective Harness
**Started:** $TIMESTAMP
**Branch:** $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

---

## Files Written This Session

| Timestamp | File |
|-----------|------|
EOF
fi

# Append the write entry
echo "| $TIMESTAMP | \`$FILE_PATH\` |" >> "$LOG_FILE"

exit 0
