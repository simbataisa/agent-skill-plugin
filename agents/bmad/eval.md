---
description: "[BMAD] Collect productivity metrics from .bmad/ artifacts and emit a JSON evaluation snapshot (schema v2) compatible with the BMAD Eval Dashboard."
argument-hint: "[week-number] [--auto] [--verbose] [--note=\"...\"] [--debounce=N]"
---

Collect BMAD productivity metrics for the current project and emit a JSON evaluation
record (schema v2) consumable by the **BMAD Agent Productivity Evaluation Dashboard**.

## Context

This command auto-measures what it can from `.bmad/` artifacts, git history, and project
files — then asks the practitioner to fill in gaps that require human judgment.
The output is a single **flat** JSON record matching the dashboard's `DATA[]` row shape,
plus an `_extras` bag of nested observability data.

Metrics cover five dimensions: **Speed**, **Quality**, **Coverage**, **Parallel Efficiency**, and **Compliance**.

**Every numeric metric carries a `confidence` tag** (`manual` | `derived` | `fuzzy` | `missing`).
The dashboard dims metrics tagged `fuzzy`/`missing` so practitioners can see where to apply
human judgment.

## Modes

| Mode          | Trigger                            | Practitioner interview | Output    |
|---------------|------------------------------------|------------------------|-----------|
| Interactive   | `/bmad:eval` (default)             | Yes — one Q per turn   | Verbose   |
| Auto          | `/bmad:eval --auto`                | Skipped (env defaults) | Silent unless `--verbose` |

`--auto` is the mode invoked by hooks (post-merge, sprint-results-write, worktree
cleanup). It honors a debounce window (default 30 min) — back-to-back triggers within
the window become no-ops so a flurry of commits/merges doesn't spam the eval log.

---

## Steps

### 0. Source the shared metrics library + parse arguments

All measurements go through `shared/scripts/bmad-metrics-lib.sh` so this command and
`/bmad:status` agree on definitions. Locate it (project copy first, then global install):

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

# Parse $ARGUMENTS into flags
AUTO=0; VERBOSE=0; NOTE=""; DEBOUNCE_MIN=30; week_arg=""
for a in $ARGUMENTS; do
  case "$a" in
    --auto)        AUTO=1 ;;
    --verbose)     VERBOSE=1 ;;
    --debounce=*)  DEBOUNCE_MIN="${a#--debounce=}" ;;
    --note=*)      NOTE="${a#--note=}" ;;
    [0-9]*)        week_arg="$a" ;;
    *)             [ $VERBOSE -eq 1 ] && echo "ignoring arg: $a" ;;
  esac
done

# In --auto mode, honor the debounce window. Skip silently if a recent record exists.
if [ "$AUTO" = "1" ]; then
  if ! bmad_eval_debounce_ok "$DEBOUNCE_MIN"; then
    [ "$VERBOSE" = "1" ] && echo "⏱  debounced (last eval within ${DEBOUNCE_MIN}m)"
    exit 0
  fi
fi
```

**Practitioner defaults for `--auto` mode** (read from env, with fallbacks):

```bash
if [ "$AUTO" = "1" ]; then
  PRACTITIONER_ID="${BMAD_PRACTITIONER_ID:-${USER:-anon}-auto}"
  PRACTITIONER_NAME="${BMAD_PRACTITIONER_NAME:-${USER:-Anonymous}}"
  PRACTITIONER_ROLE="${BMAD_PRACTITIONER_ROLE:-TL}"
  PHASE="${BMAD_PHASE:-assisted}"
fi
```

Users wire these into `~/.bmadrc` (sourced by their shell) so hook-driven runs always
attribute to the right person:

```bash
# ~/.bmadrc
export BMAD_PRACTITIONER_ID="TL-01"
export BMAD_PRACTITIONER_NAME="Dennis Dao"
export BMAD_PRACTITIONER_ROLE="TL"
export BMAD_PHASE="assisted"
```

### 1. Read project context

```bash
cat .bmad/PROJECT-CONTEXT.md 2>/dev/null
```

Extract: project name, current phase, practitioner info (if present).
If `.bmad/PROJECT-CONTEXT.md` doesn't exist, tell the user to run `/bmad:status` first.

### 2. Determine the evaluation week

- If a positive integer was passed in `$ARGUMENTS`, use that.
- Otherwise call `bmad_project_week` — it returns weeks since the first commit on `.bmad/`,
  anchored to ISO-week boundaries so two same-day runs always agree.
- If both fail and we're in interactive mode, ask the user. In `--auto` mode, fall back
  to `null` (the dashboard treats null weeks as undated points and excludes them from
  trend lines).

```bash
week="${week_arg:-$(bmad_project_week)}"
[[ "$week" =~ ^[0-9]+$ ]] || week=""
echo "Week: ${week:-unknown}"
```

Capture the project name for the record:

```bash
PROJECT_NAME="$(bmad_project_name)"
```

---

### 3. Auto-collect Speed metrics

```bash
shopt -s globstar nullglob 2>/dev/null

# Time-to-First-Draft per artifact: ISO timestamp of first commit creating the file.
declare -A artifact_drafts
for f in docs/project-brief.md \
         docs/prd.md \
         docs/architecture/solution-architecture.md \
         docs/architecture/enterprise-architecture.md \
         docs/ux/DESIGN.md \
         docs/architecture/sprint-plan.md \
         docs/testing/test-strategy.md \
         docs/analysis/*.md; do
  [ -f "$f" ] || continue
  artifact_drafts["$f"]=$(bmad_first_commit_iso "$f")
  echo "$f | first commit: ${artifact_drafts[$f]}"
done

# Iteration turnaround = mean Δ in hours between consecutive commits on the artifact.
# This is the value the dashboard's iterTurnaround field expects.
declare -A artifact_iter
for f in "${!artifact_drafts[@]}"; do
  artifact_iter["$f"]=$(bmad_mean_intercommit_hours "$f")
  echo "$f | mean inter-commit hours: ${artifact_iter[$f]}"
done

# Time-to-Draft (HOURS), derived from handoff timestamp → first commit.
# Falls back to manual entry. Echo a candidate per artifact.
for f in "${!artifact_drafts[@]}"; do
  case "$f" in
    docs/project-brief.md)                   to_agent="ba" ;;
    docs/prd.md)                             to_agent="po" ;;
    docs/architecture/solution-architecture.md) to_agent="sa" ;;
    docs/architecture/enterprise-architecture.md) to_agent="ea" ;;
    docs/ux/DESIGN.md)                       to_agent="ux" ;;
    docs/architecture/sprint-plan.md)        to_agent="tl" ;;
    docs/testing/test-strategy.md)           to_agent="qe" ;;
    *)                                       to_agent="" ;;
  esac
  start=""; [ -n "$to_agent" ] && start=$(bmad_handoff_first_to_agent "$to_agent")
  hours=$(bmad_hours_between_iso "$start" "${artifact_drafts[$f]}")
  echo "$f | task-start (handoff to $to_agent): $start | timeToDraft hours: $hours"
done
```

**Sprint velocity** — structured count of stories per sprint:

```bash
# Pick the latest sprint with both a kickoff and a results file
latest_sprint=$(ls docs/architecture/sprint-*-kickoff.md 2>/dev/null \
  | sed -E 's/.*sprint-([0-9]+)-kickoff\.md/\1/' | sort -n | tail -1)
if [ -n "$latest_sprint" ]; then
  planned=$(bmad_sprint_planned "$latest_sprint")
  completed=$(bmad_sprint_completed "$latest_sprint")
  echo "Sprint $latest_sprint: planned=$planned completed=$completed"
fi
```

---

### 4. Auto-collect Quality metrics

```bash
# NFR coverage as a 0..1 ratio (the dashboard's nfrCoverage field).
nfr_ratio=$(bmad_nfr_ratio docs/architecture/solution-architecture.md)
nfr_list=$(bmad_nfr_found_list docs/architecture/solution-architecture.md | paste -sd, -)
echo "NFR coverage: $nfr_ratio ($nfr_list)"

# Architecture debt: ADRs explicitly marked Deferred / Deprecated / Superseded.
arch_debt=$(bmad_adr_debt_count)
echo "Arch debt (deferred/deprecated ADRs): $arch_debt"

# DEVIATION / FIX / HOTFIX markers — both stock (current) and flow (added this week).
dev_open=$(bmad_count_markers '// DEVIATION:|# DEVIATION:')
fix_open=$(bmad_count_markers '// FIX:|# FIX:')
hot_open=$(bmad_count_markers '// HOTFIX:|# HOTFIX:')

dev_added=$(bmad_count_markers_added_since '// DEVIATION:|# DEVIATION:' '7 days ago')
fix_added=$(bmad_count_markers_added_since '// FIX:|# FIX:' '7 days ago')
hot_added=$(bmad_count_markers_added_since '// HOTFIX:|# HOTFIX:' '7 days ago')

echo "Markers (open / added-7d): DEVIATION=$dev_open/$dev_added FIX=$fix_open/$fix_added HOTFIX=$hot_open/$hot_added"

# Security rules coverage: presence of structured sections.
sec_present=0; sec_total=3
grep -qiE "^#{2,4}.*\b(threat|attack|trust boundary)\b" docs/architecture/solution-architecture.md 2>/dev/null && sec_present=$((sec_present+1))
grep -qiE "^#{2,4}.*\b(secrets|vault|kms|key management)\b" docs/architecture/enterprise-architecture.md 2>/dev/null && sec_present=$((sec_present+1))
grep -qiE "^#{2,4}.*\b(wcag|accessibility|aria|a11y)\b" docs/ux/DESIGN.md 2>/dev/null && sec_present=$((sec_present+1))
sec_ratio=$(python3 -c "print(round($sec_present/$sec_total,3))")
echo "Security rules coverage: $sec_ratio ($sec_present/$sec_total sections)"

# First-pass review rate — derive from PRs if `gh` is available; else mark missing.
first_pass_rate="null"; first_pass_conf="missing"
if command -v gh >/dev/null 2>&1; then
  data=$(gh pr list --state merged --limit 50 \
    --json reviewDecision,reviews --jq \
    '[.[] | select(.reviewDecision != null)] | {total: length, clean: ([.[] | select((.reviews // []) | all(.state != "CHANGES_REQUESTED"))] | length)}' 2>/dev/null)
  if [ -n "$data" ]; then
    first_pass_rate=$(python3 -c "
import json,sys
d=json.loads(sys.argv[1])
print('null' if not d['total'] else round(d['clean']/d['total'],3))" "$data")
    first_pass_conf="derived"
  fi
fi
echo "First-pass review rate: $first_pass_rate ($first_pass_conf)"
```

---

### 5. Auto-collect Coverage metrics

```bash
# Alternatives — sum of `### Option …` headings across ADRs.
alternatives=$(bmad_total_adr_options)
adr_count=$(bmad_adr_count)
echo "Alternatives (across $adr_count ADRs): $alternatives"

# Risks — entries inside `## Risks` sections / risk tables across artifacts.
risks=$(bmad_total_risks)
echo "Risks: $risks"

# Scenarios — Gherkin Scenario: lines + Use Case / User Journey headings.
scenarios=$(bmad_total_scenarios)
echo "Scenarios: $scenarios"

# Story counts.
story_total=$(bmad_count_stories_total)
story_done=$(bmad_count_stories_by_status docs/stories 'Done|Accepted|Verified')
echo "Stories: $story_done done / $story_total total"
```

---

### 6. Auto-collect Parallel Execution metrics

```bash
# W4 (EA ∥ UX)
ea_done=0; ux_done=0
[ -f docs/architecture/enterprise-architecture.md ] && ea_done=1
[ -f docs/ux/DESIGN.md ] && ux_done=1
w4_complete=$([ $ea_done -eq 1 ] && [ $ux_done -eq 1 ] && echo true || echo false)

# W6 (BE ∥ FE ∥ ME specs)
be_done=0; fe_done=0; me_done=0
[ -f docs/architecture/backend-implementation-spec.md ]  && be_done=1
[ -f docs/architecture/frontend-implementation-spec.md ] && fe_done=1
[ -f docs/architecture/mobile-implementation-spec.md ]   && me_done=1
w6_complete=$([ $be_done -eq 1 ] && [ $fe_done -eq 1 ] && [ $me_done -eq 1 ] && echo true || echo false)

sprint_count=$(ls docs/architecture/sprint-*-kickoff.md 2>/dev/null | wc -l | tr -d ' ')
result_count=$(ls docs/testing/sprint-*-results.md   2>/dev/null | wc -l | tr -d ' ')
feature_count=$(ls docs/analysis/*-impact.md         2>/dev/null | wc -l | tr -d ' ')
backlog_count=$(ls docs/analysis/*-analysis.md       2>/dev/null | wc -l | tr -d ' ')

echo "W4: $w4_complete | W6: $w6_complete"
echo "Sprints kicked-off: $sprint_count | results: $result_count"
echo "Feature analyses: $feature_count | Backlog analyses: $backlog_count"
```

---

### 7. Handoff health

```bash
total_handoffs=$(bmad_handoff_count)
echo "Total handoffs: $total_handoffs"
for agent in ba po sa ea ux tl be fe me qe sec; do
  echo "  $agent: $(bmad_handoff_count_by_agent "$agent")"
done
```

---

### 8. Practitioner interview — ONE question per turn

**SKIP this step entirely if `AUTO=1`.** In auto mode, every manual-only field becomes
`null` with `confidence: "missing"`, and the practitioner identity comes from the env
defaults set in Step 0.

After the auto-collection summary (interactive mode only), conduct a
**sequential, one-question-per-turn** interview. Do **not** dump all questions at once.
After each answer:

1. Parse and store the response.
2. If the user replies `skip` (case-insensitive), record the metric as `null` with
   `confidence: "missing"` (or use the auto-estimate where one exists, with
   `confidence: "fuzzy"`) and proceed to the next question.
3. If the answer is malformed (e.g., non-numeric where a number is expected), echo the
   captured value back and ask once for confirmation before moving on.
4. Then ask the next question.

**Open the interview with this preamble** (verbatim — practitioners recognize it):

> Please answer these (or reply **"skip"** to use auto-estimates):

Then ask the questions below in order. **Substitute the bracketed contextual placeholders
with values you already auto-collected** so each prompt is concrete to the practitioner's
actual project state — e.g., the latest sprint number, the most recently committed
artifact, the role abbreviation that matches the active wave.

Use the markdown formatting shown (numbered, bold lead-in, em-dash, italicized hint) so
the questions render identically in every chat surface.

```
1. **Practitioner ID & name** — e.g., "TL-01 / Dennis" — what should I use?

2. **Phase** — is this session `baseline` (no AI) or `assisted` (AI-assisted)?

3. **Time-to-artifact (hours)** — for **Sprint <N>** specifically: roughly how many
   hours from "sprint kickoff issued" to "QE verified complete"?
   *(Substitute <N> with the latest sprint number; if no sprint is active, ask about
   the most recent approved artifact instead — e.g., "the latest PRD".)*

4. **Time-to-first-draft (hours)** — for the most recent artifact (**<artifact title>**):
   how long from task start to first draft?
   *(Substitute <artifact title> with the basename of the newest file in the
   auto-collected `artifact_drafts` map.)*

5. **First-pass review rate** — for the last 5 sprint reviews, were artifacts approved
   on first review? (e.g., `4/5` or "all passed first time")
   *(Skip this question entirely if firstPassRate was successfully derived from `gh`
   in Step 4 — confidence is already `derived`.)*

6. **Rules compliance rating (1–5)** — how well did agents follow their rules this
   session? (5 = zero violations observed)

7. **Iteration turnaround (hours)** — average time between a review comment and the
   next revision?
   *(Skip if `iterTurnaround` was successfully derived from inter-commit Δ in Step 3 —
   confidence is already `derived`.)*
```

**Question routing rules**:

| Q  | Field             | Always ask? | Skip when                                                |
|----|-------------------|-------------|----------------------------------------------------------|
| 1  | `practitioner` + `name` | yes   | never                                                    |
| 2  | `phase`           | yes         | never                                                    |
| 3  | `timeToArtifact`  | conditional | a sprint kickoff/results pair was found *and* a handoff timestamp exists for the QE approval — then derive and skip |
| 4  | `timeToDraft`     | conditional | a handoff timestamp exists for the artifact in question — then derive and skip |
| 5  | `firstPassRate`   | conditional | `gh pr list` derivation succeeded in Step 4              |
| 6  | `rulesRating`     | yes         | never (always subjective)                                |
| 7  | `iterTurnaround`  | conditional | mean inter-commit Δ ≥ 2 commits exists for the artifact  |

**Answer-parsing notes**:

- For Q1, accept `<ID> / <Name>`, `<ID>, <Name>`, or two separate replies if the user
  splits them.
- For Q3/4/7, accept hours as a number, a range like `8-12` (use the midpoint, set
  `confidence: "fuzzy"`), or a phrase like `~6 hours`.
- For Q5, accept `4/5`, `0.8`, `80%`, or "all passed" → `1.0`. Convert to a `0..1` float.
- For Q6, accept `1`–`5` (clamp out-of-range and warn).

**Confidence assignment based on the answer**:

- A direct numeric answer → `confidence: "manual"`
- A range or hedged answer (`~6`, `8-12`) → `confidence: "fuzzy"`
- `skip` with no auto-estimate → `confidence: "missing"`, value `null`
- `skip` with an auto-estimate available → use the auto value, `confidence: "fuzzy"`

---

### 9. Emit the evaluation record (schema v2 — FLAT, dashboard-compatible)

The dashboard reads keys directly off each row (`r.firstPassRate`, `r.timeToArtifact`,
…). **Top-level metric keys MUST stay flat** — anything nested goes into `_extras`.

```json
{
  "schemaVersion": 2,
  "project": "<name from PROJECT-CONTEXT.md or repo basename>",
  "practitioner": "<ID>",
  "name": "<Name>",
  "role": "<EA|SA|BA|PO|UX|TL|BE|FE|ME|QE|SEC|DSO>",
  "week": <N|null>,
  "phase": "<baseline|assisted>",

  "timeToArtifact":    <hours|null>,
  "timeToDraft":       <hours|null>,
  "iterTurnaround":    <hours|null>,
  "firstPassRate":     <0..1|null>,
  "nfrCoverage":       <0..1|null>,
  "archDebt":          <count>,
  "alternatives":      <count>,
  "risks":             <count>,
  "scenarios":         <count>,

  "_confidence": {
    "timeToArtifact":  "manual|derived|fuzzy|missing",
    "timeToDraft":     "...",
    "iterTurnaround":  "...",
    "firstPassRate":   "...",
    "nfrCoverage":     "...",
    "archDebt":        "...",
    "alternatives":    "...",
    "risks":           "...",
    "scenarios":       "..."
  },

  "_extras": {
    "speed": {
      "sprintVelocityPlanned":   <N|null>,
      "sprintVelocityCompleted": <N|null>,
      "perArtifactDraftIso":     {"<path>": "<iso>"},
      "perArtifactIterHours":    {"<path>": <hours|null>}
    },
    "quality": {
      "deviationOpen":     <N>,
      "deviationAdded7d":  <N>,
      "fixOpen":           <N>,
      "fixAdded7d":        <N>,
      "hotfixOpen":        <N>,
      "hotfixAdded7d":     <N>,
      "securityRulesCoverage": <0..1>
    },
    "coverage": {
      "adrCount":   <N>,
      "storyTotal": <N>,
      "storyDone":  <N>
    },
    "parallelEfficiency": {
      "w4Complete":         <bool>,
      "w6Complete":         <bool>,
      "sprintsKickedOff":   <N>,
      "sprintsWithResults": <N>,
      "featureAnalyses":    <N>,
      "backlogAnalyses":    <N>
    },
    "compliance": {
      "rulesRating":        <1-5|null>,
      "deviationsJustified":<bool|"partial"|"unknown">,
      "adrLockRespected":   <bool|"unknown">
    },
    "autoCollected": {
      "nfrSections":  ["security","performance",...],
      "handoffCount": <N>,
      "handoffByAgent": {"ba": <N>, "po": <N>, ...}
    }
  },

  "_trigger":     "manual|post-merge|sprint-results|worktree-cleanup",
  "_note":        "<free-text note from --note=… (or empty)>",
  "_collectedAt": "<ISO-8601 UTC>"
}
```

**Construction tip** — emit the JSON via Python from inside the command so quoting and
escaping are correct. Build it as a single-line JSON string for log appending:

```bash
RECORD_JSON=$(python3 - <<PY
import json, datetime, os
record = {
  "schemaVersion": 2,
  "project":      "${PROJECT_NAME}",
  "practitioner": "${PRACTITIONER_ID}",
  "name":         "${PRACTITIONER_NAME}",
  "role":         "${PRACTITIONER_ROLE}",
  "week":         int("${week}") if "${week}".isdigit() else None,
  "phase":        "${PHASE}",
  # … flat metrics …
  "_trigger":     "manual" if "${AUTO}" == "0" else (os.environ.get("BMAD_TRIGGER") or "auto"),
  "_note":        "${NOTE}",
  "_collectedAt": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
}
print(json.dumps(record))
PY
)
```

---

### 10. Append to eval logs (per-project + global mirror)

Use the shared library helper — it does the dual-write **and** dedupe. The dedupe key
is `(project, practitioner, role, week)`, so re-runs in the same week overwrite the
prior snapshot rather than piling up duplicates.

```bash
bmad_append_eval_log "$RECORD_JSON"
# Writes to:
#   <project>/.bmad/eval/eval-log.jsonl  (always)
#   ~/.bmad/eval/global-log.jsonl        (unless BMAD_NO_GLOBAL_MIRROR=1)
```

**Auto-mode runs end here** — print nothing else (or just a one-line summary if
`--verbose` was passed) and exit. Interactive runs continue to Step 11 to advise the
practitioner on dashboard ingestion.

```bash
if [ "$AUTO" = "1" ]; then
  [ "$VERBOSE" = "1" ] && echo "✓ recorded eval for ${PROJECT_NAME} wk${week} (${PRACTITIONER_ID})"
  exit 0
fi
```

---

### 11. Suggest dashboard ingestion

> **To view this record in the dashboard:**
> 1. Open `eval/bmad-agent-eval-dashboard.html` (project) or
>    `~/.bmad/eval/bmad-agent-eval-dashboard.html` (global).
> 2. Click **Import** and pick **`~/.bmad/eval/global-log.jsonl`** to load every
>    project's history at once — or pick the per-project `.bmad/eval/eval-log.jsonl`
>    for a single-project view. Drag-and-drop also works.
> 3. With ≥4 baseline + ≥4 assisted weeks, statistical-significance tests become valid.

---

## Output Format

The conversation should proceed in this order:

1. **Auto-collected snapshot** (single message) — table of all five dimensions with
   values + confidence. State up-front which questions you'll skip because they're
   already `derived`.
2. **Parallel-wave health** — W4 / W6 / sprints / features / backlog status.
3. **Compliance highlights** — open vs. added-this-week markers; security sections.
4. **Practitioner interview** — the preamble line, then **one question per turn** as
   defined in Step 8. Wait for the user's reply before sending the next question.
5. **Final JSON record** (after all answers collected) — fenced JSON block, schema v2,
   copy-paste ready.
6. **Next steps** — append to log, ingest into dashboard, when stats become meaningful.
