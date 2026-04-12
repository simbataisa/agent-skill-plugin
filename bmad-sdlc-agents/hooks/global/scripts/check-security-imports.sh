#!/usr/bin/env bash
set -euo pipefail

# PreToolUse hook: Warn about insecure code patterns
# Triggered on: Write | Edit | MultiEdit

content="${CLAUDE_TOOL_INPUT_CONTENT:-}"
path="${CLAUDE_TOOL_INPUT_PATH:-}"

# Only check source code files
case "${path}" in
  *.js|*.ts|*.tsx|*.jsx|*.py|*.go|*.java|*.rb|*.php|*.rs) : ;;
  *) exit 0 ;;
esac

warnings=()

# JavaScript/TypeScript insecure patterns
if echo "${path}" | grep -qE '\.(js|ts|tsx|jsx)$'; then
  echo "${content}" | grep -qn 'eval(' && warnings+=("eval() — use safer alternatives")
  echo "${content}" | grep -qn 'dangerouslySetInnerHTML' && warnings+=("dangerouslySetInnerHTML — ensure input is sanitised")
  echo "${content}" | grep -qn '\.innerHTML\s*=' && warnings+=("innerHTML assignment — use textContent or sanitise input")
  echo "${content}" | grep -qn 'document\.write' && warnings+=("document.write — avoid, use DOM APIs instead")
fi

# Python insecure patterns
if echo "${path}" | grep -qE '\.py$'; then
  echo "${content}" | grep -qn 'exec(' && warnings+=("exec() — avoid executing dynamic code")
  echo "${content}" | grep -qn 'eval(' && warnings+=("eval() — avoid evaluating dynamic expressions")
  echo "${content}" | grep -qn 'shell=True' && warnings+=("subprocess shell=True — use shell=False with argument list")
  echo "${content}" | grep -qn 'pickle\.load' && warnings+=("pickle.load on untrusted data — deserialization vulnerability")
  echo "${content}" | grep -qn 'yaml\.load(' && warnings+=("yaml.load() — use yaml.safe_load() instead")
fi

# Go insecure patterns
if echo "${path}" | grep -qE '\.go$'; then
  echo "${content}" | grep -qn 'exec\.Command.*\$' && warnings+=("exec.Command with variable — validate input to prevent injection")
  echo "${content}" | grep -qn 'http\.ListenAndServe(' && warnings+=("http.ListenAndServe without TLS — use ListenAndServeTLS in production")
fi

# Java insecure patterns
if echo "${path}" | grep -qE '\.java$'; then
  echo "${content}" | grep -qn 'Runtime\.getRuntime()\.exec' && warnings+=("Runtime.exec — validate input, prefer ProcessBuilder")
  echo "${content}" | grep -qn 'ObjectInputStream' && warnings+=("ObjectInputStream — deserialization vulnerability, validate source")
fi

if [[ ${#warnings[@]} -gt 0 ]]; then
  echo "🔒 BMAD DevSecOps — security patterns detected in '${path}':" >&2
  for w in "${warnings[@]}"; do
    echo "   ⚠️  ${w}" >&2
  done
  echo "   Review these patterns for security implications." >&2
fi

exit 0
