#!/usr/bin/env bash
# =============================================================================
# BMAD Shared Metrics Library
# -----------------------------------------------------------------------------
# Sourced by /bmad:eval and /bmad:status to keep their measurement logic
# identical and well-tested. Pure bash + python3 for date/JSON. No jq dep.
#
# Conventions assumed (from shared/templates/*):
#   - Handoffs: .bmad/handoffs/NNN-YYYY-MM-DD-from→to.md with **From:**/**To:**
#   - Stories : `> **Status:** Draft | Ready | In Progress | Done` blockquote
#   - ADRs    : `## Options Considered` followed by `### Option A: …` headings
#   - Bug rpt : `**Status:** Open | In Progress | Fixed | Verified`
#
# All functions are namespaced `bmad_*` to avoid collisions when sourced.
# =============================================================================

# ---- Constants --------------------------------------------------------------

# Source code extensions we scan for markers. Keep both eval and status in sync
# by ALWAYS using bmad_code_includes() instead of hard-coding --include flags.
BMAD_CODE_EXTS=(ts tsx js jsx mjs cjs py go java kt swift rb cs rs php scala)

# Directories we never want to grep into (vendored / generated).
BMAD_EXCLUDE_DIRS=(node_modules vendor dist build .git .next target out
                   coverage __pycache__ .venv venv .nuxt .svelte-kit)

# NFR keywords used for coverage scoring. Each must appear inside a heading
# (^#{1,6} ...) to count — prose mentions don't qualify.
BMAD_NFR_KEYWORDS=(security performance scalability availability reliability
                   accessibility compliance observability maintainability privacy)

# ---- Helpers ---------------------------------------------------------------

bmad_code_includes() {
  # Echo `--include=*.<ext>` flags for grep based on BMAD_CODE_EXTS.
  local ext
  for ext in "${BMAD_CODE_EXTS[@]}"; do printf -- "--include=*.%s " "$ext"; done
}

bmad_exclude_dirs() {
  # Echo `--exclude-dir=<dir>` flags for grep based on BMAD_EXCLUDE_DIRS.
  local d
  for d in "${BMAD_EXCLUDE_DIRS[@]}"; do printf -- "--exclude-dir=%s " "$d"; done
}

bmad_json_escape() {
  # Escape a value for safe inclusion as a JSON string. Reads stdin or $1.
  local input
  if [ -n "${1:-}" ]; then input="$1"; else input="$(cat)"; fi
  python3 -c 'import json,sys; sys.stdout.write(json.dumps(sys.argv[1]))' "$input"
}

bmad_iso_now() {
  # ISO-8601 UTC timestamp.
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

bmad_iso_week() {
  # Compute ISO week number (1..53) for an epoch seconds arg, defaults to now.
  local epoch="${1:-$(date +%s)}"
  python3 -c "import datetime,sys; print(datetime.datetime.utcfromtimestamp(int(sys.argv[1])).isocalendar()[1])" "$epoch"
}

bmad_project_week() {
  # Weeks since the first commit that touched .bmad/, anchored to ISO weeks
  # (so two runs in the same calendar week always return the same number).
  # Falls back to first commit on the repo if .bmad/ is empty.
  local first
  first=$(git log --diff-filter=A --format="%ct" -- .bmad/ 2>/dev/null | tail -1)
  if [ -z "$first" ]; then
    first=$(git log --reverse --format="%ct" 2>/dev/null | head -1)
  fi
  if [ -z "$first" ]; then echo "unknown"; return; fi
  python3 -c "
import datetime, sys
first = datetime.datetime.utcfromtimestamp(int(sys.argv[1])).date()
today = datetime.datetime.utcnow().date()
anchor = first - datetime.timedelta(days=first.weekday())
print((today - anchor).days // 7 + 1)
" "$first"
}

# ---- Marker counters (DEVIATION / FIX / HOTFIX) -----------------------------

bmad_count_markers() {
  # Count source-code lines matching the regex passed as $1 across the repo,
  # excluding vendored / generated dirs.
  #   $1 = grep ERE, e.g. '// DEVIATION:|# DEVIATION:'
  local pattern="$1"
  # shellcheck disable=SC2046
  grep -rE $(bmad_code_includes) $(bmad_exclude_dirs) "$pattern" . 2>/dev/null | wc -l | tr -d ' '
}

bmad_count_markers_added_since() {
  # Count marker hits introduced in commits since <date> (e.g. "30 days ago").
  #   $1 = grep ERE
  #   $2 = git --since value
  local pattern="$1" since="$2"
  git log --since="$since" --diff-filter=A -p -- ':(glob)**/*' 2>/dev/null \
    | grep -cE "^\+.*($pattern)" || true
}

# ---- NFR coverage ----------------------------------------------------------

bmad_nfr_ratio() {
  # Ratio (0..1, 3 decimals) of NFR keywords that appear inside a heading
  # in the given file. Empty / missing file → 0.
  #   $1 = file path
  local file="$1"
  [ -f "$file" ] || { echo "0"; return; }
  local found=0 nfr
  for nfr in "${BMAD_NFR_KEYWORDS[@]}"; do
    if grep -qiE "^#{1,6}[[:space:]].*\b${nfr}\b" "$file"; then
      found=$((found + 1))
    fi
  done
  python3 -c "print(round($found/${#BMAD_NFR_KEYWORDS[@]},3))"
}

bmad_nfr_found_list() {
  # Echo each NFR keyword present in headings, one per line.
  local file="$1"
  [ -f "$file" ] || return
  local nfr
  for nfr in "${BMAD_NFR_KEYWORDS[@]}"; do
    if grep -qiE "^#{1,6}[[:space:]].*\b${nfr}\b" "$file"; then
      echo "$nfr"
    fi
  done
}

# ---- ADR alternatives (structured) -----------------------------------------

bmad_count_adr_options() {
  # Count `### Option …` headings under `## Options Considered` in one ADR.
  #   $1 = ADR file path
  local file="$1"
  [ -f "$file" ] || { echo "0"; return; }
  awk '
    /^## Options Considered/        { in_block=1; next }
    /^## /                          { in_block=0 }
    in_block && /^### Option[ A-Z:]/{ count++ }
    END                             { print count+0 }
  ' "$file"
}

bmad_total_adr_options() {
  # Sum of options across every ADR in $1 (default docs/architecture/adr).
  local dir="${1:-docs/architecture/adr}"
  [ -d "$dir" ] || { echo "0"; return; }
  local total=0 f n
  for f in "$dir"/*.md; do
    [ -f "$f" ] || continue
    n=$(bmad_count_adr_options "$f")
    total=$((total + n))
  done
  echo "$total"
}

bmad_adr_count() {
  local dir="${1:-docs/architecture/adr}"
  [ -d "$dir" ] || { echo "0"; return; }
  find "$dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' '
}

bmad_adr_debt_count() {
  # Count ADRs whose status line is Deprecated/Superseded OR that explicitly
  # mark themselves as deferred/debt in the Status block.
  local dir="${1:-docs/architecture/adr}"
  [ -d "$dir" ] || { echo "0"; return; }
  grep -lE '^>\s*\*\*Status:\*\*\s*(Deprecated|Superseded|Deferred)' \
    "$dir"/*.md 2>/dev/null | wc -l | tr -d ' '
}

# ---- Risks (structured) ----------------------------------------------------

bmad_count_risks_in_file() {
  # Count risk-register-style rows / bullets under a `## Risks` (or
  # `### Risks`) heading. Falls back to 0 if no such section exists.
  #   $1 = file path
  local file="$1"
  [ -f "$file" ] || { echo "0"; return; }
  awk '
    BEGIN { in_block=0; count=0 }
    /^#{2,3}[[:space:]]+Risks([[:space:]]|$|\/)/ { in_block=1; next }
    /^#{1,3}[[:space:]]/                          { in_block=0 }
    in_block && /^[[:space:]]*[-*][[:space:]]+\S/ { count++ }
    in_block && /^\|[^|]+\|[^|]+\|/ && $0 !~ /^\|[-:| ]+\|$/ && $0 !~ /Risk[[:space:]]*\|/ { count++ }
    END { print count+0 }
  ' "$file"
}

bmad_total_risks() {
  # Sum risks across the standard set of artifact files.
  local total=0 n f
  for f in docs/project-brief.md \
           docs/prd.md \
           docs/architecture/solution-architecture.md \
           docs/architecture/enterprise-architecture.md; do
    n=$(bmad_count_risks_in_file "$f")
    total=$((total + n))
  done
  for f in docs/analysis/*.md docs/architecture/adr/*.md; do
    [ -f "$f" ] || continue
    n=$(bmad_count_risks_in_file "$f")
    total=$((total + n))
  done
  echo "$total"
}

# ---- Scenarios (Gherkin + use-cases) ---------------------------------------

bmad_count_scenarios_in_file() {
  # Count Gherkin `Scenario:` lines, `## Use Case` or `## User Journey`
  # headings, and explicit `Scenario N:` enumerations.
  local file="$1"
  [ -f "$file" ] || { echo "0"; return; }
  local s
  s=$(grep -cE '^[[:space:]]*Scenario:|^#{2,4}[[:space:]]+(Use[[:space:]]Case|User[[:space:]]Journey|Scenario)[[:space:]]?[0-9A-Z:]?' \
      "$file" 2>/dev/null)
  echo "${s:-0}"
}

bmad_total_scenarios() {
  local total=0 n f
  for f in docs/prd.md docs/ux/DESIGN.md docs/analysis/*.md docs/stories/**/*.md docs/stories/*.md; do
    [ -f "$f" ] || continue
    n=$(bmad_count_scenarios_in_file "$f")
    total=$((total + n))
  done
  echo "$total"
}

# ---- Stories: status parsing -----------------------------------------------

bmad_story_status() {
  # Echo the literal status string from the `> **Status:** …` blockquote.
  # Empty if file missing or no status line.
  local file="$1"
  [ -f "$file" ] || return
  awk '
    /^>[[:space:]]*\*\*Status:\*\*/ {
      sub(/^>[[:space:]]*\*\*Status:\*\*[[:space:]]*/, "")
      sub(/[[:space:]]+$/, "")
      print; exit
    }' "$file"
}

bmad_count_stories_by_status() {
  # $1 = stories root (e.g. docs/stories)
  # $2 = ERE matching desired status (e.g. 'Done|Accepted')
  local root="${1:-docs/stories}" pattern="$2"
  [ -d "$root" ] || { echo "0"; return; }
  local count=0 status f
  while IFS= read -r f; do
    status=$(bmad_story_status "$f")
    [[ "$status" =~ $pattern ]] && count=$((count + 1))
  done < <(find "$root" -type f -name '*.md' 2>/dev/null)
  echo "$count"
}

bmad_count_stories_total() {
  local root="${1:-docs/stories}"
  [ -d "$root" ] || { echo "0"; return; }
  find "$root" -type f -name '*.md' 2>/dev/null | wc -l | tr -d ' '
}

# ---- Sprint velocity --------------------------------------------------------

bmad_sprint_planned() {
  # Stories listed in sprint-N-kickoff.md (counted by `### Story` or table rows
  # under `## Stories`). Falls back to 0 if file absent.
  local n="$1"
  local f="docs/architecture/sprint-${n}-kickoff.md"
  [ -f "$f" ] || { echo "0"; return; }
  awk '
    /^##[[:space:]]+Stories/ { in_block=1; next }
    /^##[[:space:]]/         { in_block=0 }
    in_block && /^###[[:space:]]/                                   { c++ }
    in_block && /^\|[^|]+\|[^|]+\|/ && $0 !~ /^\|[-:| ]+\|$/ &&
      $0 !~ /Story[[:space:]]*\|/                                   { c++ }
    END { print c+0 }
  ' "$f"
}

bmad_sprint_completed() {
  # Stories accepted in sprint-N-results.md, parsed from a `Status` column
  # in the results table OR `✅` markers in story rows.
  local n="$1"
  local f="docs/testing/sprint-${n}-results.md"
  [ -f "$f" ] || { echo "0"; return; }
  awk '
    /^\|.*\|.*\|/ {
      if ($0 ~ /[Aa]ccepted|[Dd]one|[Pp]assed|✅/ &&
          $0 !~ /^\|[-:| ]+\|$/ && $0 !~ /[Ss]tatus[[:space:]]*\|/) c++
    }
    END { print c+0 }' "$f"
}

# ---- Handoffs ---------------------------------------------------------------

bmad_handoff_count() {
  # Total handoffs (excludes _template).
  ls .bmad/handoffs/*.md 2>/dev/null | grep -v '_template' | wc -l | tr -d ' '
}

bmad_handoff_first_to_agent() {
  # ISO timestamp (commit time) of the earliest handoff whose **To:** matches
  # the abbrev in $1 (case-insensitive). Used to anchor "task started" for
  # time-to-draft computations.
  local agent="$1"
  local f
  while IFS= read -r f; do
    if grep -qiE "^\*\*To:\*\*.*\b${agent}\b" "$f" 2>/dev/null; then
      git log --diff-filter=A --format='%aI' -- "$f" 2>/dev/null | tail -1
      return
    fi
  done < <(ls .bmad/handoffs/*.md 2>/dev/null | grep -v '_template' | sort)
}

bmad_handoff_count_by_agent() {
  # Count handoffs where the agent appears in either **From:** or **To:**.
  local agent="$1" count=0 f
  while IFS= read -r f; do
    if grep -qiE "^\*\*(From|To):\*\*.*\b${agent}\b" "$f" 2>/dev/null; then
      count=$((count + 1))
    fi
  done < <(ls .bmad/handoffs/*.md 2>/dev/null | grep -v '_template')
  echo "$count"
}

# ---- Time math --------------------------------------------------------------

bmad_first_commit_iso() {
  git log --diff-filter=A --format="%aI" -- "$1" 2>/dev/null | tail -1
}

bmad_last_commit_iso() {
  git log --format="%aI" -- "$1" 2>/dev/null | head -1
}

bmad_artifact_revisions() {
  # Total commits that touched the artifact (including the initial create).
  git log --format="%H" -- "$1" 2>/dev/null | wc -l | tr -d ' '
}

bmad_mean_intercommit_hours() {
  # Mean Δ in hours between consecutive commits on the artifact.
  # < 2 commits → echoes `null` (caller should handle).
  local file="$1"
  local stamps
  stamps=$(git log --format='%ct' -- "$file" 2>/dev/null)
  python3 -c '
import sys
ts = [int(x) for x in sys.argv[1].split() if x.strip()]
if len(ts) < 2:
    print("null")
else:
    ts.sort()
    deltas = [ts[i+1] - ts[i] for i in range(len(ts)-1)]
    print(round(sum(deltas)/len(deltas)/3600.0, 2))
' "$stamps"
}

bmad_hours_between_iso() {
  # Hours between two ISO-8601 timestamps. Echo `null` if either is empty.
  local a="$1" b="$2"
  [ -z "$a" ] || [ -z "$b" ] && { echo "null"; return; }
  python3 -c "
import datetime, sys
def p(s):
    return datetime.datetime.fromisoformat(s.replace('Z','+00:00'))
a, b = p(sys.argv[1]), p(sys.argv[2])
print(round(abs((b-a).total_seconds())/3600.0, 2))
" "$a" "$b"
}

# ---- Bugs / Hotfixes --------------------------------------------------------

bmad_bug_status() {
  local file="$1"
  [ -f "$file" ] || return
  awk '
    /^[[:space:]]*\*\*Status:\*\*/ {
      sub(/^[[:space:]]*\*\*Status:\*\*[[:space:]]*/, "")
      sub(/[[:space:]]+$/, "")
      print; exit
    }' "$file"
}

bmad_open_bugs() {
  # Bug files in docs/testing/bugs/*.md whose Status is not Fixed/Verified.
  # Skips *-fix-plan.md and *-verified.md companion files.
  local dir="${1:-docs/testing/bugs}"
  [ -d "$dir" ] || { echo "0"; return; }
  local count=0 f status
  while IFS= read -r f; do
    case "$(basename "$f")" in
      *-fix-plan.md|*-verified.md) continue ;;
    esac
    status=$(bmad_bug_status "$f")
    if [ -z "$status" ] || ! [[ "$status" =~ ^(Fixed|Verified)$ ]]; then
      count=$((count + 1))
    fi
  done < <(find "$dir" -maxdepth 1 -type f -name '*.md' 2>/dev/null)
  echo "$count"
}

bmad_active_hotfix() {
  # Echo basename of the most recent active hotfix (no companion -verified.md
  # AND modified within $1 days, default 30). Empty if none.
  local max_age="${1:-30}"
  local dir="docs/testing/hotfixes"
  [ -d "$dir" ] || return
  local cutoff f stem
  cutoff=$(date -u -d "${max_age} days ago" +%s 2>/dev/null \
            || date -v-"${max_age}"d +%s)
  while IFS= read -r f; do
    [ -f "$f" ] || continue
    case "$(basename "$f")" in *-verified.md) continue ;; esac
    stem="${f%.md}"
    [ -f "${stem}-verified.md" ] && continue
    local mtime
    mtime=$(stat -c %Y "$f" 2>/dev/null || stat -f %m "$f" 2>/dev/null)
    [ -z "$mtime" ] && continue
    if [ "$mtime" -ge "$cutoff" ]; then
      echo "$f"
      return
    fi
  done < <(ls -t "$dir"/*.md 2>/dev/null)
}

# ---- Phase inference --------------------------------------------------------

bmad_infer_phase() {
  # Echo the most-likely current phase based on which artifacts exist.
  if ls docs/architecture/sprint-*-kickoff.md >/dev/null 2>&1 || \
     [ -f "docs/architecture/sprint-plan.md" ]; then
    echo "Implementation"; return
  fi
  if [ -f "docs/architecture/solution-architecture.md" ] || \
     [ -f "docs/ux/DESIGN.md" ] || \
     [ -f "docs/architecture/enterprise-architecture.md" ]; then
    echo "Solutioning"; return
  fi
  if [ -f "docs/prd.md" ]; then
    echo "Planning"; return
  fi
  if [ -f "docs/project-brief.md" ] || ls docs/analysis/*.md >/dev/null 2>&1; then
    echo "Analysis"; return
  fi
  echo "Unknown"
}

# ---- Sprint sub-phase (E2 worktrees) ---------------------------------------

bmad_active_engineer_worktrees() {
  # List git worktrees whose branch matches feature/sprint engineering branches.
  git worktree list --porcelain 2>/dev/null \
    | awk '/^branch / {sub(/^branch /, ""); print}' \
    | grep -E '/(backend|frontend|mobile|be|fe|me)[-/]|sprint-' || true
}
