#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook: Scan content being written for potential secrets
# Triggered on: Write | Edit | MultiEdit
# Environment: $CLAUDE_TOOL_INPUT_CONTENT, $CLAUDE_TOOL_INPUT_PATH

content="${CLAUDE_TOOL_INPUT_CONTENT:-}"
path="${CLAUDE_TOOL_INPUT_PATH:-}"

# Skip binary / non-text paths
case "${path}" in
  *.png|*.jpg|*.gif|*.ico|*.woff|*.ttf|*.eot) exit 0 ;;
esac

# Check for common secret patterns
patterns=(
  'AKIA[0-9A-Z]{16}'                             # AWS Access Key ID
  'sk-[a-zA-Z0-9]{20,}'                          # Stripe/OpenAI secret keys
  'ghp_[a-zA-Z0-9]{36}'                          # GitHub personal access token
  'gho_[a-zA-Z0-9]{36}'                          # GitHub OAuth token
  'glpat-[a-zA-Z0-9\-]{20,}'                     # GitLab personal access token
  'xox[baprs]-[a-zA-Z0-9\-]+'                    # Slack tokens
  'eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.'      # JWT tokens
  '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----'  # Private keys
  'postgres://[^:]+:[^@]+@'                       # PostgreSQL connection strings with password
  'mongodb(\+srv)?://[^:]+:[^@]+@'               # MongoDB connection strings with password
  'mysql://[^:]+:[^@]+@'                          # MySQL connection strings with password
)

found=0
for pattern in "${patterns[@]}"; do
  if echo "${content}" | grep -qPi "${pattern}" 2>/dev/null; then
    echo "⚠️  BMAD DevSecOps: Potential secret detected in '${path}' matching pattern. Review before committing." >&2
    found=1
  fi
done

if [[ ${found} -eq 1 ]]; then
  echo "💡 Secrets should use environment variables or a secrets manager (Vault, AWS Secrets Manager, SOPS)." >&2
fi

# Always allow the write (advisory, not blocking) — the warning surfaces in the chat
exit 0
