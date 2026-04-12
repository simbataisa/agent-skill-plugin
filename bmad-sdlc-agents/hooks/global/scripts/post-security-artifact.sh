#!/usr/bin/env bash
set -euo pipefail

# PostToolUse hook: Auto-log security artifact writes
# Triggered on: Write to docs/security/*.md

file_path="${CLAUDE_TOOL_INPUT_PATH:-}"

# Only trigger on security docs
case "${file_path}" in
  docs/security/*.md) : ;;
  *) exit 0 ;;
esac

# Auto-update a security artifact index if one exists
index_file="docs/security/INDEX.md"
if [[ ! -f "${index_file}" ]]; then
  mkdir -p docs/security
  cat > "${index_file}" << 'EOF'
# Security Artifacts Index

> Auto-maintained by BMAD DevSecOps/InfoSec hooks.

| Artifact | Last Updated | Agent |
|----------|-------------|-------|
EOF
fi

artifact_name=$(basename "${file_path}")
date_str=$(date '+%Y-%m-%d %H:%M')

# Check if artifact already in index — update the date if so, else append
if grep -q "${artifact_name}" "${index_file}" 2>/dev/null; then
  sed -i.bak "s|${artifact_name}.*|${artifact_name} | ${date_str} | auto-detected |" "${index_file}"
  rm -f "${index_file}.bak"
else
  echo "| ${artifact_name} | ${date_str} | auto-detected |" >> "${index_file}"
fi

exit 0
