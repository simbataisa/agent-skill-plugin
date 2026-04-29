#!/usr/bin/env bash
# =============================================================================
# post-merge-eval.sh — git post-merge hook for BMAD projects
# -----------------------------------------------------------------------------
# Installed at <repo>/.git/hooks/post-merge by hooks/install-project-hooks.sh.
# Fires after `git pull`, `git merge`, or a successful `git rebase` finishes
# applying changes locally. Runs /bmad:eval --auto in the background so the
# merge command returns immediately.
#
# This hook is a no-op outside BMAD projects (no .bmad/ directory).
# =============================================================================

set -uo pipefail

repo_root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$repo_root" || exit 0
[ -d .bmad ] || exit 0

# Locate bmad-eval-run.sh — prefer the project's vendored copy if present.
RUNNER=""
for c in scripts/bmad-eval-run.sh \
         "$HOME/.bmad/scripts/bmad-eval-run.sh" \
         "$HOME/bmad-sdlc-agents/scripts/bmad-eval-run.sh"; do
  [ -x "$c" ] || [ -f "$c" ] && RUNNER="$c" && break
done
[ -z "$RUNNER" ] && exit 0

# Fire-and-forget so `git pull` doesn't block. nohup detaches; >/dev/null swallows
# output; bash -c invocation works whether the file is +x or not.
nohup bash "$RUNNER" --trigger=post-merge --debounce=30 \
    >/dev/null 2>&1 < /dev/null &
disown 2>/dev/null || true
exit 0
