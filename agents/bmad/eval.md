---
description: "[BMAD] Collect productivity metrics from .bmad/ artifacts and emit a JSON evaluation snapshot (schema v2) compatible with the BMAD Eval Dashboard."
argument-hint: "[week-number] (optional — defaults to current project week)"
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

---

## Steps

### 0. Source the shared metrics library

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
```

### 1. Read project context

```bash
cat .bmad/PROJECT-CONTEXT.md 2>/dev/null
```

Extract: project name, current phase, practitioner info (if present).
If `.bmad/PROJECT-CONTEXT.md` doesn't exist, tell the user to run `/bmad:status` first.

### 2. Determine the evaluation week

- If `$ARGUMENTS` contains a positive integer, use that as the week number.
- Otherwise call `bmad_project_week` — it returns weeks since the first commit on `.bmad/`,
  anchored to ISO-week boundaries so two same-day runs always agree.
- If both fail, ask the user.

```bash
week="${ARGUMENTS:-$(bmad_project_week)}"
[[ "$week" =~ ^[0-9]+$ ]] || week="unknown"
echo "Week: $week"
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

### 8. Practitioner inputs (only for what couldn't be derived)

Present the auto-collected snapshot, then prompt for fields whose `confidence` is
`fuzzy` or `missing`. **Skip prompts for any field already at `derived` or `manual`.**

Always required:

- **Practitioner ID and role** (e.g., `TL-01`, `BA-02`, `SA-03`)
- **Practitioner name** (matches the dashboard's `name`)
- **Phase** — `baseline` (no AI) or `assisted` (AI-assisted)

Required only if not derivable:

- `timeToArtifact` (hours) — if no handoff timestamp + approval marker exists.
- `timeToDraft` (hours) — if no handoff-to-agent timestamp exists for this artifact.
- `firstPassRate` (0..1 or fraction like `3/5`) — if `gh` derivation failed.
- `rulesRating` (1–5 integer) — always manual; subjective compliance score.

If the practitioner declines a prompt, set the field to `null` and confidence to `missing`.

---

### 9. Emit the evaluation record (schema v2 — FLAT, dashboard-compatible)

The dashboard reads keys directly off each row (`r.firstPassRate`, `r.timeToArtifact`,
…). **Top-level metric keys MUST stay flat** — anything nested goes into `_extras`.

```json
{
  "schemaVersion": 2,
  "practitioner": "<ID>",
  "name": "<Name>",
  "role": "<EA|SA|BA|PO|UX|TL|BE|FE|ME|QE|SEC|DSO>",
  "week": <N>,
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

  "_collectedAt": "<ISO-8601 UTC>"
}
```

**Construction tip** — emit the JSON via Python from inside the command so quoting and
escaping are correct:

```bash
python3 - <<PY
import json, datetime, os
record = {
  "schemaVersion": 2,
  "practitioner": "${PRACTITIONER_ID:-unknown}",
  "name":         "${PRACTITIONER_NAME:-Anonymous}",
  "role":         "${PRACTITIONER_ROLE:-TL}",
  "week":         int("${week}") if "${week}".isdigit() else None,
  "phase":        "${PHASE:-baseline}",
  # … flat metrics …
  "_collectedAt": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
}
print(json.dumps(record, indent=2))
PY
```

---

### 10. Append to local eval log

If `.bmad/eval/eval-log.jsonl` exists or the user agrees, append the record as a single
JSON line:

```bash
mkdir -p .bmad/eval
printf '%s\n' "$RECORD_JSON" >> .bmad/eval/eval-log.jsonl
```

This jsonl can be bulk-imported into `bmad-agent-eval-dashboard.html` later.

---

### 11. Suggest dashboard ingestion

> **To ingest this record into the dashboard:**
> 1. Open `eval/bmad-agent-eval-dashboard.html` (project) or
>    `~/.bmad/eval/bmad-agent-eval-dashboard.html` (global).
> 2. The dashboard auto-detects `schemaVersion: 2` records and merges them into `DATA`.
>    Records with `null` metrics are excluded from those metrics' charts but still
>    contribute where they have values.
> 3. With ≥4 baseline + ≥4 assisted weeks, statistical-significance tests become valid.

---

## Output Format

The chat output should include, in order:

1. **Auto-collected snapshot** — table of all five dimensions with values + confidence.
2. **Parallel-wave health** — W4 / W6 / sprints / features / backlog status.
3. **Compliance highlights** — open vs. added-this-week markers; security sections.
4. **Practitioner prompts** — only for fields still at `fuzzy`/`missing` confidence.
5. **Final JSON record** — fenced JSON block, schema v2, copy-paste ready.
6. **Next steps** — append to log, ingest into dashboard, when stats become meaningful.
