#!/usr/bin/env bash
# =============================================================================
# bmad-eval-run.sh — standalone auto-mode runner for /bmad:eval
# -----------------------------------------------------------------------------
# Computes the auto-collectable metrics for the current project and appends a
# schema-v2 record to .bmad/eval/eval-log.jsonl + ~/.bmad/eval/global-log.jsonl.
#
# Skips the practitioner interview entirely — every manual-only field becomes
# null with confidence "missing". Practitioner identity comes from env:
#   BMAD_PRACTITIONER_ID, BMAD_PRACTITIONER_NAME, BMAD_PRACTITIONER_ROLE, BMAD_PHASE
# Set these in ~/.bmadrc (sourced by your shell) so hook-driven runs attribute
# correctly.
#
# Flags:
#   --trigger=<name>   Logged in the record's _trigger field. Default "manual".
#                      Hooks set this to post-merge / sprint-results / worktree-cleanup.
#   --note=<text>      Free-text note logged in the record's _note field.
#   --debounce=<min>   Skip if a record was written within N minutes (default 30).
#                      Use --debounce=0 to disable debounce (forced run).
#   --week=<N>         Override the auto-detected project week.
#   --verbose          Print a one-line confirmation; otherwise silent on success.
#   --help             Show usage.
#
# Exit codes:
#   0  recorded successfully (or debounced)
#   1  hard error (lib missing, JSON build failed, etc.)
#   2  not in a BMAD project (no .bmad/ dir) — silently skipped
# =============================================================================

set -uo pipefail

# ---- Locate and source the shared library --------------------------------

LIB=""
for c in "$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")/../shared/scripts/bmad-metrics-lib.sh" \
         "shared/scripts/bmad-metrics-lib.sh" \
         "$HOME/.bmad/scripts/bmad-metrics-lib.sh" \
         "$HOME/bmad-sdlc-agents/shared/scripts/bmad-metrics-lib.sh"; do
  [ -f "$c" ] && LIB="$c" && break
done
if [ -z "$LIB" ]; then
  echo "bmad-eval-run: shared lib not found; run scripts/install-global.sh first" >&2
  exit 1
fi
# shellcheck disable=SC1090
source "$LIB"

# ---- Parse args ---------------------------------------------------------

TRIGGER="manual"
NOTE=""
DEBOUNCE_MIN=30
WEEK_OVERRIDE=""
VERBOSE=0
for arg in "$@"; do
  case "$arg" in
    --trigger=*)  TRIGGER="${arg#--trigger=}" ;;
    --note=*)     NOTE="${arg#--note=}" ;;
    --debounce=*) DEBOUNCE_MIN="${arg#--debounce=}" ;;
    --week=*)     WEEK_OVERRIDE="${arg#--week=}" ;;
    --verbose)    VERBOSE=1 ;;
    --help|-h)    sed -n '2,30p' "$0"; exit 0 ;;
    *)            ;;
  esac
done

# ---- Sanity: is this a BMAD project? -----------------------------------

if [ ! -d .bmad ]; then
  [ "$VERBOSE" = "1" ] && echo "bmad-eval-run: no .bmad/ here, skipping"
  exit 2
fi

# ---- Debounce ------------------------------------------------------------

if [ "$DEBOUNCE_MIN" != "0" ] && ! bmad_eval_debounce_ok "$DEBOUNCE_MIN"; then
  [ "$VERBOSE" = "1" ] && echo "bmad-eval-run: debounced (last eval within ${DEBOUNCE_MIN}m)"
  exit 0
fi

# ---- Practitioner identity from env ---------------------------------------

PRACTITIONER_ID="${BMAD_PRACTITIONER_ID:-${USER:-anon}-auto}"
PRACTITIONER_NAME="${BMAD_PRACTITIONER_NAME:-${USER:-Anonymous}}"
PRACTITIONER_ROLE="${BMAD_PRACTITIONER_ROLE:-TL}"
PHASE="${BMAD_PHASE:-assisted}"

# ---- Auto-collected metrics ------------------------------------------------

PROJECT_NAME="$(bmad_project_name)"
WEEK="${WEEK_OVERRIDE:-$(bmad_project_week)}"
[[ "$WEEK" =~ ^[0-9]+$ ]] || WEEK=""

shopt -s globstar nullglob 2>/dev/null

# Quality
NFR_RATIO=$(bmad_nfr_ratio docs/architecture/solution-architecture.md)
ARCH_DEBT=$(bmad_adr_debt_count)
DEV_OPEN=$(bmad_count_markers '// DEVIATION:|# DEVIATION:')
FIX_OPEN=$(bmad_count_markers '// FIX:|# FIX:')
HOT_OPEN=$(bmad_count_markers '// HOTFIX:|# HOTFIX:')
DEV_ADDED7=$(bmad_count_markers_added_since '// DEVIATION:|# DEVIATION:' '7 days ago')
FIX_ADDED7=$(bmad_count_markers_added_since '// FIX:|# FIX:' '7 days ago')
HOT_ADDED7=$(bmad_count_markers_added_since '// HOTFIX:|# HOTFIX:' '7 days ago')

# Coverage
ALTERNATIVES=$(bmad_total_adr_options)
ADR_COUNT=$(bmad_adr_count)
RISKS=$(bmad_total_risks)
SCENARIOS=$(bmad_total_scenarios)
STORY_TOTAL=$(bmad_count_stories_total)
STORY_DONE=$(bmad_count_stories_by_status docs/stories 'Done|Accepted|Verified')

# Speed (per-artifact + sprint-derived). For a single record we summarise:
ITER_TURNAROUND="null"
for f in docs/architecture/sprint-plan.md \
         docs/architecture/solution-architecture.md \
         docs/prd.md \
         docs/project-brief.md; do
  [ -f "$f" ] || continue
  v=$(bmad_mean_intercommit_hours "$f")
  if [ "$v" != "null" ]; then
    ITER_TURNAROUND="$v"
    break
  fi
done

# Parallel efficiency
W4_COMPLETE=false
[ -f docs/architecture/enterprise-architecture.md ] && [ -f docs/ux/DESIGN.md ] && W4_COMPLETE=true
W6_COMPLETE=false
[ -f docs/architecture/backend-implementation-spec.md ] && \
  [ -f docs/architecture/frontend-implementation-spec.md ] && \
  [ -f docs/architecture/mobile-implementation-spec.md ] && W6_COMPLETE=true
SPRINTS_KICKED=$(ls docs/architecture/sprint-*-kickoff.md 2>/dev/null | wc -l | tr -d ' ')
SPRINTS_RESULTS=$(ls docs/testing/sprint-*-results.md   2>/dev/null | wc -l | tr -d ' ')
FEATURES=$(ls docs/analysis/*-impact.md   2>/dev/null | wc -l | tr -d ' ')
BACKLOGS=$(ls docs/analysis/*-analysis.md 2>/dev/null | wc -l | tr -d ' ')

NFR_LIST=$(bmad_nfr_found_list docs/architecture/solution-architecture.md \
            | python3 -c 'import json,sys; print(json.dumps([l.strip() for l in sys.stdin if l.strip()]))')
HANDOFF_TOTAL=$(bmad_handoff_count)

# ---- Build the JSON record ------------------------------------------------

# Marshal everything into JSON via python so quoting/null handling is correct.
RECORD_JSON=$(PROJECT_NAME="$PROJECT_NAME" \
  PRACTITIONER_ID="$PRACTITIONER_ID" PRACTITIONER_NAME="$PRACTITIONER_NAME" \
  PRACTITIONER_ROLE="$PRACTITIONER_ROLE" PHASE="$PHASE" WEEK="$WEEK" \
  TRIGGER="$TRIGGER" NOTE="$NOTE" \
  NFR_RATIO="$NFR_RATIO" ARCH_DEBT="$ARCH_DEBT" \
  DEV_OPEN="$DEV_OPEN" FIX_OPEN="$FIX_OPEN" HOT_OPEN="$HOT_OPEN" \
  DEV_ADDED7="$DEV_ADDED7" FIX_ADDED7="$FIX_ADDED7" HOT_ADDED7="$HOT_ADDED7" \
  ALTERNATIVES="$ALTERNATIVES" ADR_COUNT="$ADR_COUNT" RISKS="$RISKS" \
  SCENARIOS="$SCENARIOS" STORY_TOTAL="$STORY_TOTAL" STORY_DONE="$STORY_DONE" \
  ITER_TURNAROUND="$ITER_TURNAROUND" \
  W4_COMPLETE="$W4_COMPLETE" W6_COMPLETE="$W6_COMPLETE" \
  SPRINTS_KICKED="$SPRINTS_KICKED" SPRINTS_RESULTS="$SPRINTS_RESULTS" \
  FEATURES="$FEATURES" BACKLOGS="$BACKLOGS" \
  NFR_LIST_JSON="$NFR_LIST" HANDOFF_TOTAL="$HANDOFF_TOTAL" \
  python3 - <<'PY'
import datetime, json, os

def num(s, default=None, kind=int):
    s = (s or "").strip()
    if not s or s == "null": return default
    try: return kind(s)
    except: return default

def bf(s):  # boolean from string "true"/"false"
    return (s or "").strip().lower() == "true"

record = {
    "schemaVersion": 2,
    "project":      os.environ.get("PROJECT_NAME") or "unknown-project",
    "practitioner": os.environ.get("PRACTITIONER_ID") or "anon",
    "name":         os.environ.get("PRACTITIONER_NAME") or "Anonymous",
    "role":         os.environ.get("PRACTITIONER_ROLE") or "TL",
    "week":         num(os.environ.get("WEEK"), default=None),
    "phase":        os.environ.get("PHASE") or "assisted",

    "timeToArtifact": None,
    "timeToDraft":    None,
    "iterTurnaround": num(os.environ.get("ITER_TURNAROUND"), default=None, kind=float),
    "firstPassRate":  None,
    "nfrCoverage":    num(os.environ.get("NFR_RATIO"), default=None, kind=float),
    "archDebt":       num(os.environ.get("ARCH_DEBT"), default=0, kind=int) or 0,
    "alternatives":   num(os.environ.get("ALTERNATIVES"), default=0, kind=int) or 0,
    "risks":          num(os.environ.get("RISKS"), default=0, kind=int) or 0,
    "scenarios":      num(os.environ.get("SCENARIOS"), default=0, kind=int) or 0,

    "_confidence": {
        "timeToArtifact":"missing", "timeToDraft":"missing",
        "iterTurnaround": "derived" if (os.environ.get("ITER_TURNAROUND") or "null") != "null" else "missing",
        "firstPassRate": "missing",
        "nfrCoverage":  "derived" if (os.environ.get("NFR_RATIO") or "0") != "0" else "fuzzy",
        "archDebt":     "derived",
        "alternatives": "derived",
        "risks":        "derived",
        "scenarios":    "derived",
    },

    "_extras": {
        "quality": {
            "deviationOpen":    num(os.environ.get("DEV_OPEN"), 0),
            "deviationAdded7d": num(os.environ.get("DEV_ADDED7"), 0),
            "fixOpen":          num(os.environ.get("FIX_OPEN"), 0),
            "fixAdded7d":       num(os.environ.get("FIX_ADDED7"), 0),
            "hotfixOpen":       num(os.environ.get("HOT_OPEN"), 0),
            "hotfixAdded7d":    num(os.environ.get("HOT_ADDED7"), 0),
        },
        "coverage": {
            "adrCount":   num(os.environ.get("ADR_COUNT"), 0),
            "storyTotal": num(os.environ.get("STORY_TOTAL"), 0),
            "storyDone":  num(os.environ.get("STORY_DONE"), 0),
        },
        "parallelEfficiency": {
            "w4Complete":         bf(os.environ.get("W4_COMPLETE")),
            "w6Complete":         bf(os.environ.get("W6_COMPLETE")),
            "sprintsKickedOff":   num(os.environ.get("SPRINTS_KICKED"), 0),
            "sprintsWithResults": num(os.environ.get("SPRINTS_RESULTS"), 0),
            "featureAnalyses":    num(os.environ.get("FEATURES"), 0),
            "backlogAnalyses":    num(os.environ.get("BACKLOGS"), 0),
        },
        "autoCollected": {
            "nfrSections":  json.loads(os.environ.get("NFR_LIST_JSON") or "[]"),
            "handoffCount": num(os.environ.get("HANDOFF_TOTAL"), 0),
        },
    },

    "_trigger":     os.environ.get("TRIGGER") or "manual",
    "_note":        os.environ.get("NOTE") or "",
    "_collectedAt": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
}

print(json.dumps(record))
PY
)

if [ -z "$RECORD_JSON" ]; then
  echo "bmad-eval-run: failed to build JSON record" >&2
  exit 1
fi

# ---- Append (dual-write: per-project + global mirror) -----------------------

if ! bmad_append_eval_log "$RECORD_JSON" >/dev/null; then
  echo "bmad-eval-run: append failed" >&2
  exit 1
fi

if [ "$VERBOSE" = "1" ]; then
  echo "✓ bmad-eval recorded: project=${PROJECT_NAME} week=${WEEK:-?} role=${PRACTITIONER_ROLE} trigger=${TRIGGER}"
fi
exit 0
