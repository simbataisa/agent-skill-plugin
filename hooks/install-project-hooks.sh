#!/usr/bin/env bash
# =============================================================================
# install-project-hooks.sh — wire BMAD hooks into the current git repo
# -----------------------------------------------------------------------------
# Run this from the root of any project where you want BMAD's auto-eval hooks
# to fire on git events:
#
#     bash <bmad-repo>/hooks/install-project-hooks.sh
#
# What it installs (idempotent):
#   - .git/hooks/post-merge → wraps hooks/global/scripts/post-merge-eval.sh
#   - .claude/hooks/auto-eval-on-sprint-results.sh   (referenced by settings.json)
#   - .claude/hooks/post-cleanup-eval.sh             (called by Yolo wrap-up)
#
# Existing files with a "BMAD-MANAGED" sentinel comment are overwritten;
# everything else is preserved (we abort if the hook exists without the sentinel
# and the user hasn't passed --force).
# =============================================================================

set -euo pipefail

FORCE=0
for a in "$@"; do
  case "$a" in
    --force) FORCE=1 ;;
    *) echo "unknown arg: $a" >&2; exit 1 ;;
  esac
done

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "error: not inside a git repository" >&2
  exit 1
fi
repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

# Resolve the BMAD repo (where this script lives).
bmad_root=$(cd "$(dirname "$0")/.." && pwd)
echo "→ Installing BMAD hooks into $repo_root"
echo "  (sourced from $bmad_root)"

# ---- 1. Git post-merge hook ----
hook_dst=".git/hooks/post-merge"
hook_src="$bmad_root/hooks/global/scripts/post-merge-eval.sh"

if [ -f "$hook_dst" ] && ! grep -q "BMAD-MANAGED" "$hook_dst" 2>/dev/null; then
  if [ "$FORCE" != "1" ]; then
    echo "  ⚠️  $hook_dst already exists (not BMAD-managed). Use --force to overwrite, or merge manually."
    echo "      Suggested merge: append the line below to your existing post-merge:"
    echo "        bash \"$hook_src\""
  else
    backup="$hook_dst.pre-bmad.$(date +%s)"
    cp "$hook_dst" "$backup"
    echo "  📦 Backed up existing post-merge → $backup"
    cat > "$hook_dst" <<EOF
#!/usr/bin/env bash
# BMAD-MANAGED — installed by install-project-hooks.sh
exec bash "$hook_src" "\$@"
EOF
    chmod +x "$hook_dst"
    echo "  ✅ Installed (forced) → $hook_dst"
  fi
else
  cat > "$hook_dst" <<EOF
#!/usr/bin/env bash
# BMAD-MANAGED — installed by install-project-hooks.sh
exec bash "$hook_src" "\$@"
EOF
  chmod +x "$hook_dst"
  echo "  ✅ Installed → $hook_dst"
fi

# ---- 2. Claude project hooks (PostToolUse on Write for sprint results) ----
mkdir -p .claude/hooks
for src in "$bmad_root/hooks/project/scripts/auto-eval-on-sprint-results.sh" \
           "$bmad_root/hooks/yolo-harness/hooks/post-cleanup-eval.sh"; do
  base=$(basename "$src")
  cp -f "$src" ".claude/hooks/$base"
  chmod +x ".claude/hooks/$base"
  echo "  ✅ Copied → .claude/hooks/$base"
done

# ---- 3. Friendly summary ----
echo ""
echo "Done. Verify:"
echo "  git pull on this repo will now record an eval snapshot when .bmad/ exists."
echo "  Writing a docs/testing/sprint-N-results.md will also record one."
echo ""
echo "Identity defaults — set in ~/.bmadrc and source it from your shell rc:"
echo "  export BMAD_PRACTITIONER_ID=\"TL-01\""
echo "  export BMAD_PRACTITIONER_NAME=\"Your Name\""
echo "  export BMAD_PRACTITIONER_ROLE=\"TL\""
echo "  export BMAD_PHASE=\"assisted\""
