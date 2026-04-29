---
description: "[BMAD] Show current BMAD project status — phase, active work type, current wave, parallel-wave health, open bugs, next recommended action. Supports --json for machine-readable output."
argument-hint: "[--json]"
---

Produce a concise BMAD project status report. Auto-infers the current phase, detects
the active work type with recency, pairs bug reports with their verifications, and uses
the shared metrics library so this command and `/bmad:eval` stay in sync.

## Steps

### 0. Source the shared metrics library

```bash
LIB=""
for c in shared/scripts/bmad-metrics-lib.sh \
         ~/.bmad/scripts/bmad-metrics-lib.sh \
         ~/bmad-sdlc-agents/shared/scripts/bmad-metrics-lib.sh; do
  [ -f "$c" ] && LIB="$c" && break
done
[ -z "$LIB" ] && { echo "❌ bmad-metrics-lib.sh not found — run scripts/install-global.sh"; exit 1; }
# shellcheck disable=SC1090
source "$LIB"

GENERATED_AT="$(bmad_iso_now)"
JSON_MODE=false
[ "$ARGUMENTS" = "--json" ] && JSON_MODE=true
```

### 1. Read project context

```bash
if [ ! -f .bmad/PROJECT-CONTEXT.md ]; then
  echo "ℹ️  .bmad/PROJECT-CONTEXT.md not found."
  echo "    Find the scaffold script: find ~ -name scaffold-project.sh -path '*/bmad-sdlc-agents/scripts/*' 2>/dev/null"
  echo "    Then run: bash <found-path> \"<project-name>\""
  exit 0
fi
cat .bmad/PROJECT-CONTEXT.md
```

### 2. Read last handoff (graceful empty)

```bash
last_handoff=$(ls .bmad/handoffs/*.md 2>/dev/null | grep -v _template | sort | tail -1)
total_handoffs=$(bmad_handoff_count)
if [ -z "$last_handoff" ]; then
  echo "ℹ️  No handoffs yet — start with /<agent>:brainstorm."
else
  echo "Last handoff: $last_handoff (of $total_handoffs total)"
fi
```

### 3. Auto-infer phase

```bash
phase=$(bmad_infer_phase)
echo "Phase: $phase"
```

### 4. Detect active work type (recency-aware)

Scan signals in priority order. **Hotfix and bug states must be ACTIVE** (not yet
verified) to qualify, and a hotfix only counts as active if it was modified within
the last 30 days.

```bash
active_type="Unknown"

# Hotfix — only if a -verified.md companion is missing AND modified in last 30d
hotfix=$(bmad_active_hotfix 30)
[ -n "$hotfix" ] && active_type="Hotfix"

# Bug fix — open bugs (Status not in Fixed/Verified, fix-plan/verified pairs missing)
if [ "$active_type" = "Unknown" ]; then
  open_bugs=$(bmad_open_bugs)
  [ "$open_bugs" -gt 0 ] && active_type="Bug Fix"
fi

# Sprint execution — kickoff exists for the LATEST sprint and no results file yet
if [ "$active_type" = "Unknown" ]; then
  latest_sprint=$(ls docs/architecture/sprint-*-kickoff.md 2>/dev/null \
    | sed -E 's/.*sprint-([0-9]+)-kickoff\.md/\1/' | sort -n | tail -1)
  if [ -n "$latest_sprint" ] && [ ! -f "docs/testing/sprint-${latest_sprint}-results.md" ]; then
    active_type="Sprint Execution"
  fi
fi

# Feature — at least one *-impact.md without a corresponding *-plan.md OR a sprint mapping
if [ "$active_type" = "Unknown" ]; then
  for impact in docs/analysis/*-impact.md; do
    [ -f "$impact" ] || continue
    stem=$(basename "$impact" -impact.md)
    if [ ! -f "docs/architecture/${stem}-plan.md" ]; then
      active_type="Feature"
      break
    fi
  done
fi

# Backlog
if [ "$active_type" = "Unknown" ]; then
  for analysis in docs/analysis/*-analysis.md; do
    [ -f "$analysis" ] || continue
    stem=$(basename "$analysis" -analysis.md)
    if [ ! -f "docs/architecture/${stem}-notes.md" ]; then
      active_type="Backlog"
      break
    fi
  done
fi

# New project — fall through if a brief or PRD exists
if [ "$active_type" = "Unknown" ]; then
  if [ -f docs/project-brief.md ] || [ -f docs/prd.md ]; then
    active_type="New Project"
  fi
fi

echo "Active work type: $active_type"
```

### 5. Wave status (using ✅ / ⏳ / ❌ consistently)

Use a single helper to avoid the empty-dir-echoes-✅ bug from the v1 script:

```bash
mark() { [ -f "$1" ] && echo "✅" || echo "❌"; }
mark_dir() { [ -n "$(find "$1" -mindepth 1 -name '*.md' -print -quit 2>/dev/null)" ] && echo "✅" || echo "❌"; }
```

Then evaluate the wave checklist for the active work type. Example for **New Project — Plan**:

```bash
echo "W1 BA $(mark docs/project-brief.md)"
echo "W2 PO $(mark docs/prd.md)"
echo "W3 SA $(mark docs/architecture/solution-architecture.md)"
echo "W4 EA $(mark docs/architecture/enterprise-architecture.md) (parallel)"
echo "W4 UX $(mark docs/ux/DESIGN.md) (parallel)"
echo "W5 TL $(mark docs/architecture/sprint-plan.md)"
echo "W6 BE-spec $(mark docs/architecture/backend-implementation-spec.md) (parallel)"
echo "W6 FE-spec $(mark docs/architecture/frontend-implementation-spec.md) (parallel)"
echo "W6 ME-spec $(mark docs/architecture/mobile-implementation-spec.md) (parallel)"
echo "W7 TQE $(mark docs/testing/test-strategy.md)"
```

For **Sprint Execution**, also show the in-flight engineering worktrees:

```bash
worktrees=$(bmad_active_engineer_worktrees)
if [ -n "$worktrees" ]; then
  echo "Active engineering worktrees (E2):"
  echo "$worktrees" | sed 's/^/  • /'
fi
[ -n "$latest_sprint" ] && echo "E3 TQE $(mark docs/testing/sprint-${latest_sprint}-results.md)"
```

For **Bug Fix**, show open vs verified pairs:

```bash
for f in docs/testing/bugs/*.md; do
  [ -f "$f" ] || continue
  case "$(basename "$f")" in *-fix-plan.md|*-verified.md) continue ;; esac
  stem="${f%.md}"
  [ -f "${stem}-verified.md" ] && tag="✅ verified" \
    || { [ -f "${stem}-fix-plan.md" ] && tag="⏳ fix planned" || tag="❌ open"; }
  echo "$f — $tag (status: $(bmad_bug_status "$f"))"
done
```

### 6. Code-health indicators (shared with /bmad:eval)

```bash
dev_open=$(bmad_count_markers '// DEVIATION:|# DEVIATION:')
fix_open=$(bmad_count_markers '// FIX:|# FIX:')
hot_open=$(bmad_count_markers '// HOTFIX:|# HOTFIX:')
dev_added=$(bmad_count_markers_added_since '// DEVIATION:|# DEVIATION:' '7 days ago')

echo "Open markers — DEVIATION:$dev_open  FIX:$fix_open  HOTFIX:$hot_open"
echo "DEVIATION added in last 7 days: $dev_added"
```

### 7. JSON output mode

If `--json` was passed, emit a single object instead of a markdown report:

```bash
if [ "$JSON_MODE" = true ]; then
  python3 - <<PY
import json, os, subprocess
def sh(c): return subprocess.run(c, shell=True, capture_output=True, text=True).stdout.strip()
out = {
  "schemaVersion": 2,
  "generatedAt":   "$GENERATED_AT",
  "phase":         sh("source $LIB; bmad_infer_phase"),
  "activeWorkType":"$active_type",
  "totalHandoffs": int(sh("source $LIB; bmad_handoff_count") or 0),
  "openBugs":      int(sh("source $LIB; bmad_open_bugs") or 0),
  "activeHotfix":  sh("source $LIB; bmad_active_hotfix") or None,
  "markers": {
    "deviationOpen":    int("$dev_open" or 0),
    "fixOpen":          int("$fix_open" or 0),
    "hotfixOpen":       int("$hot_open" or 0),
    "deviationAdded7d": int("$dev_added" or 0),
  },
  "lastHandoff":   "$last_handoff" or None,
}
print(json.dumps(out, indent=2))
PY
  exit 0
fi
```

### 8. Markdown report (default)

---

## BMAD Project Status

**Generated:** `[GENERATED_AT]`
**Project:** [name from PROJECT-CONTEXT.md]
**Phase:** [auto-inferred from `bmad_infer_phase` — Analysis · Planning · Solutioning · Implementation · Unknown]
**Active Work Type:** [auto-detected — New Project · Feature · Backlog · Bug Fix · Hotfix · Sprint Execution · Unknown]
**Total Handoffs:** [N] — see `.bmad/handoff-log.md`

### Last Handoff
**[from-agent] → [to-agent]** — [one-line summary]
[link: `.bmad/handoffs/<filename>`]
*(or "No handoffs yet — start with `/<agent>:brainstorm`" if empty)*

### Wave Status

Use `✅` (done), `⏳` (in progress / waiting on peer), `❌` (not started). Show only
waves relevant to the active work type.

| Wave | Agent(s) | Output Artifact | Status |
|------|----------|-----------------|--------|
| ... | | | ✅ / ⏳ / ❌ |

> ⚠️ **Parallel wave incomplete:** [If any W4/W6/E2 agents show mixed ✅/❌, flag here]
> e.g. "EA ✅ but UX ❌ — Tech Lead cannot start until both W4 agents complete."

### Artifact Checklist

Show only sections relevant to the active work type.

**Sprint Execution (when applicable):**

| Artifact | Path | Status |
|----------|------|--------|
| Sprint Plan | `docs/architecture/sprint-plan.md` | ✅ / ❌ |
| Latest Sprint Kickoff | `docs/architecture/sprint-N-kickoff.md` | Sprint [N] / ❌ |
| Latest Sprint Results | `docs/testing/sprint-N-results.md` | Sprint [N] ✅ / ❌ |
| Active engineering worktrees | (from `git worktree list`) | [list] |

**Bug Fix / Hotfix (when applicable):**

For each bug/hotfix doc, show: filename · status from `**Status:**` line · verified-pair check.

### Code Health Indicators

| Indicator | Open | Added 7d | Notes |
|-----------|------|----------|-------|
| DEVIATION markers | [N] | [N] | Architecture deviations |
| FIX markers | [N] | — | Applied fixes still in code |
| HOTFIX markers | [N] | — | Applied hotfixes still in code |
| Open bugs | [N] | — | Status ≠ Fixed/Verified |

### Open Items (from last handoff)

[open questions and risks parsed from the most recent handoff file, or "(none)"]

### Next Recommended Action

Based on active work type, current phase, and missing artifacts:

- **"W4 incomplete: EA ✅ but UX ❌ → Invoke `/ux-designer` to complete Wave 4, then `/tech-lead` for W5."**
- **"W6 specs all ✅ → Invoke `/tester-qe` for test strategy (W7), then proceed to sprint execution."**
- **"Sprint N kickoff exists, no results → Spawn `/backend-engineer` ∥ `/frontend-engineer` ∥ `/mobile-engineer` (Wave E2) in parallel worktrees."**
- **"Active hotfix `<file>` not yet verified → run `/tester-qe:run-quality-gate` to verify."**

---

## If `.bmad/PROJECT-CONTEXT.md` doesn't exist

Step 1 already prints the bootstrap instructions and exits 0. No further action needed.
