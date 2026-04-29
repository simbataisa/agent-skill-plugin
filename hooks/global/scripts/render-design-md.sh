#!/usr/bin/env bash
# ============================================================================
# Auto-regenerate docs/ux/DESIGN.html whenever docs/ux/DESIGN.md is written.
# Wired into PostToolUse for Write / Edit / MultiEdit.
#
# The UX Designer maintains docs/ux/DESIGN.md (Google Stitch DESIGN.md format)
# as the authoritative design system source. This hook keeps the HTML
# visualization in lockstep with the markdown source so reviewers and
# downstream engineers always see the current state — no agent can forget
# to regenerate after an edit.
#
# Takes $1 as the file path written / edited by the Claude Code tool call.
# ============================================================================

set -uo pipefail

file_path="${1:-}"

# Fast-path: bail if no file path was passed.
[[ -z "$file_path" ]] && exit 0

# We only care about the project's DESIGN.md. Accept absolute OR relative.
case "$file_path" in
  *"/docs/ux/DESIGN.md"|"docs/ux/DESIGN.md")
    ;;
  *)
    exit 0
    ;;
esac

# Locate the renderer. Prefer the globally-installed copy under ~/.bmad/scripts/;
# fall back to the repo source if this hook is being exercised from a checkout.
renderer=""
for candidate in \
    "$HOME/.bmad/scripts/render-design-md.py" \
    "$(dirname "$0")/../../../scripts/render-design-md.py" \
    "$(pwd)/scripts/render-design-md.py"; do
  if [[ -f "$candidate" ]]; then
    renderer="$candidate"
    break
  fi
done

if [[ -z "$renderer" ]]; then
  echo "⚠️  render-design-md.py not found (looked in ~/.bmad/scripts/ and repo). Skipping HTML regen." >&2
  exit 0
fi

# Require python3. Don't block the tool call if it's missing — warn and skip.
if ! command -v python3 >/dev/null 2>&1; then
  echo "⚠️  python3 not on PATH. Skipping docs/ux/DESIGN.html regeneration." >&2
  exit 0
fi

# Resolve the target HTML next to the written source, preserving directory.
# Use the exact file path that was written so cwd changes don't confuse us.
if [[ "$file_path" = /* ]]; then
  input_path="$file_path"
else
  input_path="$(pwd)/$file_path"
fi
output_path="${input_path%.md}.html"

# Run the renderer. Capture stdout so we can surface the per-file summary in
# one neat line; suppress stderr only on non-zero exit so errors are visible.
if output=$(python3 "$renderer" --input "$input_path" --output "$output_path" 2>&1); then
  # Collapse the two-line script output into one token-frugal line.
  summary=$(echo "$output" | tr '\n' ' ' | sed 's/  */ /g')
  echo "🎨 DESIGN.html auto-regenerated: $summary"
else
  echo "⚠️  DESIGN.html regeneration failed:" >&2
  echo "$output" >&2
fi

exit 0
