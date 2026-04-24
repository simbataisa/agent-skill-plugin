#!/usr/bin/env bash
set -euo pipefail

# Auto-create a handoff child file when a key artifact is written,
# and update the master .bmad/handoff-log.md index.
# Takes $1 as the file path that was written.

file_path="${1:-.}"

# Only trigger on significant deliverable artifacts
case "${file_path}" in
  docs/project-brief.md|\
  docs/prd.md|\
  docs/architecture/solution-architecture.md|\
  docs/architecture/enterprise-architecture.md|\
  docs/ux/DESIGN.md|\
  docs/architecture/adr/*.md|\
  docs/testing/test-strategy.md)
    : # fall through to logging
    ;;
  *)
    exit 0
    ;;
esac

# Ensure directories exist
mkdir -p .bmad/handoffs

# Determine the next handoff number
last_num=$(ls .bmad/handoffs/*.md 2>/dev/null \
  | grep -v '_template' \
  | grep -Eo '^\.bmad/handoffs/([0-9]+)' \
  | grep -Eo '[0-9]+' \
  | sort -n \
  | tail -1)
next_num=$(printf "%03d" $(( ${last_num:-0} + 1 )))

date_str=$(date '+%Y-%m-%d')
time_str=$(date '+%H:%M')

# Infer a short from→to label based on the artifact written
case "${file_path}" in
  docs/project-brief.md)              from="ba"; to="po" ;;
  docs/prd.md)                        from="po"; to="sa" ;;
  docs/architecture/solution-*.md)    from="sa"; to="ea" ;;
  docs/architecture/enterprise-*.md)  from="ea"; to="tl" ;;
  docs/ux/DESIGN.md)           from="ux"; to="tl" ;;
  docs/architecture/adr/*.md)         from="sa"; to="hu" ;;
  docs/testing/test-strategy.md)      from="qe"; to="hu" ;;
  *)                                  from="hu"; to="hu" ;;
esac

child_file=".bmad/handoffs/${next_num}-${date_str}-${from}→${to}.md"

# Create child file from template if available, otherwise inline
if [[ -f .bmad/handoffs/_template.md ]]; then
  cp .bmad/handoffs/_template.md "${child_file}"
  # Fill in the number and date
  sed -i.bak "s/\[NNN\]/${next_num}/g; s/\[YYYY-MM-DD\]/${date_str}/g" "${child_file}"
  rm -f "${child_file}.bak"
else
  cat > "${child_file}" << EOF
# Handoff #${next_num} — ${date_str}

**From:** ${from}
**To:** ${to}
**Artifact written:** \`${file_path}\`
**Time:** ${time_str}

## Notes

*(Auto-created — fill in decisions, open questions, and risks)*
EOF
fi

# Update the master index — replace the "no handoffs yet" placeholder row
# or append a new row after the last data row.
index_file=".bmad/handoff-log.md"

if [[ -f "${index_file}" ]]; then
  # Remove the placeholder "no handoffs yet" row if present
  sed -i.bak '/No handoffs yet/d' "${index_file}"
  rm -f "${index_file}.bak"

  # Append the new index row
  echo "| ${next_num} | ${date_str} | \`${from}\` → \`${to}\` | — | Auto: \`${file_path}\` written | [→ view](handoffs/$(basename "${child_file}")) |" \
    >> "${index_file}"
fi

exit 0
