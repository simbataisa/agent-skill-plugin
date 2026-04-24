---
description: "[BMAD] Collect productivity metrics from .bmad/ artifacts and output a JSON evaluation snapshot compatible with the BMAD Eval Dashboard."
argument-hint: "[week-number] (optional — defaults to current week)"
---

Collect BMAD productivity metrics for the current project and output a JSON evaluation
record compatible with the **BMAD Agent Productivity Evaluation Dashboard**.

## Context

This command auto-measures what it can from `.bmad/` artifacts, git history, and project
files — then asks the practitioner to fill in gaps that require human judgment.
The output is a single JSON record that can be appended to the dashboard's `DATA` array.

Metrics cover five dimensions: **Speed**, **Quality**, **Coverage**, **Parallel Efficiency**, and **Compliance**.

---

## Steps

### 1. Read project context

```bash
cat .bmad/PROJECT-CONTEXT.md 2>/dev/null
```

Extract: project name, current phase, practitioner info (if present).

If `.bmad/PROJECT-CONTEXT.md` doesn't exist, tell the user to run `/bmad-status` first.

### 2. Determine the evaluation week

- If `$ARGUMENTS` contains a number, use that as the week number.
- Otherwise, calculate the week number from git history:
  ```bash
  first_commit=$(git log --diff-filter=A --format="%ct" -- .bmad/ 2>/dev/null | tail -1)
  now=$(date +%s)
  [ -n "$first_commit" ] && echo $(( (now - first_commit) / 604800 + 1 )) || echo "unknown"
  ```
  If this fails, ask the user for the week number.

---

### 3. Auto-collect Speed metrics

**Time-to-First-Draft** — Measure from task assignment to first artifact commit:
```bash
for f in \
  docs/project-brief.md \
  docs/prd.md \
  docs/architecture/solution-architecture.md \
  docs/architecture/enterprise-architecture.md \
  docs/ux/DESIGN.md \
  docs/testing/test-strategy.md \
  docs/architecture/sprint-plan.md; do
  if [ -f "$f" ]; then
    created=$(git log --diff-filter=A --format="%ai" -- "$f" 2>/dev/null | tail -1)
    echo "$f | created: $created"
  fi
done

# Also check feature/backlog analysis artifacts
for f in docs/analysis/*.md; do
  [ -f "$f" ] && created=$(git log --diff-filter=A --format="%ai" -- "$f" 2>/dev/null | tail -1) && echo "$f | created: $created"
done
```

**Iteration Turnaround** — Count revision commits per artifact:
```bash
for f in \
  docs/project-brief.md \
  docs/prd.md \
  docs/architecture/solution-architecture.md \
  docs/analysis/*.md; do
  if [ -f "$f" ]; then
    revisions=$(git log --oneline -- "$f" 2>/dev/null | wc -l)
    first=$(git log --format="%ai" -- "$f" 2>/dev/null | tail -1)
    last=$(git log --format="%ai" -- "$f" 2>/dev/null | head -1)
    echo "$f | revisions: $revisions | first: $first | last: $last"
  fi
done
```

**Sprint Velocity** — Stories completed per sprint:
```bash
for results in docs/testing/sprint-*-results.md; do
  [ -f "$results" ] || continue
  sprint_n=$(echo "$results" | grep -oP 'sprint-\K[0-9]+')
  # Count passed stories (lines containing ✅ or "pass")
  passed=$(grep -ci "✅\|pass\|accepted\|verified" "$results" 2>/dev/null)
  # Count failed stories
  failed=$(grep -ci "❌\|fail\|rejected\|unmet" "$results" 2>/dev/null)
  echo "Sprint $sprint_n: ~$passed passed, ~$failed failed"
done
```

---

### 4. Auto-collect Quality metrics

**NFR Coverage Score** — Parse the solution architecture for NFR sections:
```bash
if [ -f docs/architecture/solution-architecture.md ]; then
  for nfr in "security" "performance" "scalability" "availability" "reliability" \
             "accessibility" "compliance" "observability" "maintainability" "privacy"; do
    grep -qi "$nfr" docs/architecture/solution-architecture.md && echo "  ✅ $nfr" || echo "  ❌ $nfr"
  done
fi
```

**Architecture Debt** — Count ADR "deferred" or "debt" items:
```bash
debt_count=0
if [ -d docs/architecture/adr ]; then
  debt_count=$(grep -rli "debt\|deferred\|workaround\|technical-debt\|tech.debt" \
    docs/architecture/adr/ 2>/dev/null | wc -l)
fi
echo "Arch debt items: $debt_count"
```

**Agent Rules Compliance — DEVIATION count:**
```bash
# Count DEVIATION markers across all source code (signals intentional rule deviations)
dev_count=$(grep -r "// DEVIATION:\|# DEVIATION:" . \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" \
  --include="*.py" --include="*.go" --include="*.java" --include="*.kt" \
  --include="*.swift" --include="*.rb" --include="*.cs" \
  2>/dev/null | wc -l)
echo "DEVIATION markers: $dev_count"

# Count FIX markers (applied bug fixes)
fix_count=$(grep -r "// FIX:\|# FIX:" . \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" \
  2>/dev/null | wc -l)
echo "FIX markers: $fix_count"

# Count HOTFIX markers (applied hotfixes)
hotfix_count=$(grep -r "// HOTFIX:\|# HOTFIX:" . \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" \
  2>/dev/null | wc -l)
echo "HOTFIX markers: $hotfix_count"
```

**Security Rules Coverage** — Check if key security artifacts are present:
```bash
# Threat model in solution architecture?
grep -qi "threat\|attack\|trust boundary" docs/architecture/solution-architecture.md 2>/dev/null && \
  echo "✅ Threat model present" || echo "❌ No threat model"

# Secrets management defined?
grep -qi "vault\|secrets manager\|kms\|key management" \
  docs/architecture/enterprise-architecture.md 2>/dev/null && \
  echo "✅ Secrets management defined" || echo "❌ No secrets strategy"

# WCAG / accessibility defined?
grep -qi "wcag\|accessibility\|aria\|a11y" docs/ux/DESIGN.md 2>/dev/null && \
  echo "✅ Accessibility standards defined" || echo "❌ No accessibility spec"
```

---

### 5. Auto-collect Coverage metrics

**Alternatives Evaluated** — Count options in ADRs:
```bash
if [ -d docs/architecture/adr ]; then
  total_options=0
  adr_count=$(ls docs/architecture/adr/*.md 2>/dev/null | wc -l)
  for adr in docs/architecture/adr/*.md; do
    options=$(grep -ci "option\|alternative\|approach\|considered" "$adr" 2>/dev/null)
    total_options=$((total_options + options))
    echo "  $(basename $adr): ~$options options/alternatives mentioned"
  done
  echo "ADRs: $adr_count | Total alternative mentions: $total_options"
fi
```

**Risks Identified** — Count risks across all artifacts including new analysis docs:
```bash
risk_count=0
for f in \
  docs/project-brief.md \
  docs/prd.md \
  docs/architecture/solution-architecture.md \
  docs/analysis/*.md; do
  if [ -f "$f" ]; then
    risks=$(grep -ci "risk\|concern\|caveat\|limitation\|constraint\|vulnerability" "$f" 2>/dev/null)
    risk_count=$((risk_count + risks))
    echo "  $f: $risks risk mentions"
  fi
done
echo "Total risk mentions: $risk_count"
```

**Stakeholder Scenarios** — Count scenarios/use-cases:
```bash
scenario_count=0
for f in docs/prd.md docs/ux/DESIGN.md docs/analysis/*.md; do
  if [ -f "$f" ]; then
    sc=$(grep -ci "scenario\|use.case\|user.story\|workflow\|journey\|persona" "$f" 2>/dev/null)
    scenario_count=$((scenario_count + sc))
  fi
done
story_count=$(ls docs/stories/*.md 2>/dev/null | wc -l)
feature_story_count=$(ls docs/stories/**/*.md 2>/dev/null | wc -l)
echo "Scenario mentions: $scenario_count | Story files: $((story_count + feature_story_count))"
```

---

### 6. Auto-collect Parallel Execution metrics

```bash
# Count waves that required parallel execution and completed successfully
echo "=== Parallel Wave Health ==="

# W4 (EA + UX) — new project plan
ea_done=0; ux_done=0
[ -f docs/architecture/enterprise-architecture.md ] && ea_done=1
[ -f docs/ux/DESIGN.md ] && ux_done=1
echo "W4 (EA ∥ UX): EA=$ea_done UX=$ux_done | Complete=$([ $ea_done -eq 1 ] && [ $ux_done -eq 1 ] && echo yes || echo no)"

# W6 (BE ∥ FE ∥ ME specs) — new project plan
be_done=0; fe_done=0; me_done=0
[ -f docs/architecture/backend-implementation-spec.md ] && be_done=1
[ -f docs/architecture/frontend-implementation-spec.md ] && fe_done=1
[ -f docs/architecture/mobile-implementation-spec.md ] && me_done=1
echo "W6 (BE ∥ FE ∥ ME spec): BE=$be_done FE=$fe_done ME=$me_done"

# Sprint E2 waves — count completed sprints
sprint_count=$(ls docs/architecture/sprint-*-kickoff.md 2>/dev/null | wc -l)
result_count=$(ls docs/testing/sprint-*-results.md 2>/dev/null | wc -l)
echo "Sprints kicked off: $sprint_count | Sprints with results: $result_count"

# Feature W3 (SA ∥ UX)
feature_count=$(ls docs/analysis/*-impact.md 2>/dev/null | wc -l)
feature_plan_count=$(ls docs/architecture/*-plan.md 2>/dev/null | wc -l)
echo "Feature analyses (BA): $feature_count | Feature plans (TL): $feature_plan_count"

# Backlog W2 (BA analysis)
backlog_analysis_count=$(ls docs/analysis/*-analysis.md 2>/dev/null | wc -l)
backlog_notes_count=$(ls docs/architecture/*-notes.md 2>/dev/null | wc -l)
echo "Backlog analyses (BA): $backlog_analysis_count | Backlog notes (TL): $backlog_notes_count"
```

---

### 7. Count handoffs as process health indicator

```bash
handoff_count=$(ls .bmad/handoffs/*.md 2>/dev/null | grep -v _template | wc -l)
echo "Handoffs completed: $handoff_count"

# Count handoffs per agent type
for agent in business-analyst product-owner solution-architect enterprise-architect \
             ux-designer tech-lead backend-engineer frontend-engineer mobile-engineer tester-qe; do
  count=$(grep -rl "from.*$agent\|to.*$agent" .bmad/handoffs/*.md 2>/dev/null | wc -l)
  echo "  $agent: $count handoffs"
done
```

---

### 8. Ask the practitioner for metrics that can't be auto-collected

Present what was auto-collected, then ask for:

- **Practitioner ID and role** (e.g., "TL-01" / "BA-02" / "SA-03")
- **Time-to-Artifact (hours)** — "How many hours from task start to the artifact being approved?"
- **Time-to-First-Draft (hours)** — "How many hours from task start to first draft commit?"
- **First-Pass Review Rate** — "Was the most recent artifact approved on first review? (y/n or ratio like 3/5)"
- **Phase** — "Is this a `baseline` (no AI) or `assisted` (AI-assisted) measurement?"
- **Sprint velocity (if in execution)** — "How many stories were planned vs. completed this sprint?"
- **Rules compliance rating** — "On a scale of 1–5, how well did agents follow their agent rules this session? (5 = no violations)"

If the user declines to provide manual inputs, use the auto-collected approximations with
a `"confidence": "auto-estimated"` flag.

---

### 9. Output the evaluation record

Output a fenced JSON block in this exact schema:

```json
{
  "practitioner": "<ID>",
  "name": "<Name>",
  "role": "<role>",
  "week": <N>,
  "phase": "<baseline|assisted>",

  "_speed": {
    "timeToArtifact": <hours>,
    "timeToDraft": <hours>,
    "iterTurnaround": <hours>,
    "sprintVelocityPlanned": <N>,
    "sprintVelocityCompleted": <N>
  },

  "_quality": {
    "firstPassRate": <0.0-1.0>,
    "nfrCoverage": <0.0-1.0>,
    "archDebt": <count>,
    "deviationCount": <count>,
    "fixMarkerCount": <count>,
    "hotfixMarkerCount": <count>,
    "securityRulesCoverage": <0.0-1.0>
  },

  "_coverage": {
    "alternatives": <count>,
    "risks": <count>,
    "scenarios": <count>,
    "storyCount": <count>,
    "featureAnalysisCount": <count>,
    "backlogAnalysisCount": <count>
  },

  "_parallelEfficiency": {
    "w4Complete": <true|false>,
    "w6Complete": <true|false>,
    "sprintsKickedOff": <N>,
    "sprintsWithResults": <N>,
    "featuresWithBAAnalysis": <N>,
    "backlogWithBAAnalysis": <N>
  },

  "_compliance": {
    "rulesRating": <1-5>,
    "deviationsJustified": <true|false|"partial">,
    "adrLockRespected": <true|false|"unknown">
  },

  "_autoCollected": {
    "nfrSections": ["list of NFRs found"],
    "adrCount": <N>,
    "handoffCount": <N>,
    "artifactRevisions": {"file": <N>}
  },

  "_collectedAt": "<ISO-8601 timestamp>"
}
```

---

### 10. Suggest appending to the dashboard

Tell the user:

> **To add this to your dashboard:**
> 1. Open `.bmad/eval/bmad-agent-eval-dashboard.html` (scaffolded with your project) or
>    `~/.bmad/eval/bmad-agent-eval-dashboard.html` (installed globally)
> 2. Find the `const DATA = genData();` line
> 3. Replace it with `const DATA = [` ... paste your records ... `];`
> 4. Or append this record to an existing `DATA` array
>
> The dashboard tracks 5 dimensions: Speed, Quality, Coverage, Parallel Efficiency, and Compliance.
> Once you have 4+ weeks of baseline and 4+ weeks of AI-assisted data,
> the statistical significance tests will become meaningful.

---

### 11. Append to local eval log (optional)

If `.bmad/eval/eval-log.jsonl` exists or the user confirms, append the JSON record:

```bash
mkdir -p .bmad/eval
echo '<json-record>' >> .bmad/eval/eval-log.jsonl
```

This creates a running log alongside the dashboard in `.bmad/eval/`, which can later be
bulk-imported into `bmad-agent-eval-dashboard.html`.

---

## Output Format

The output should include:

1. **Auto-collected metrics summary** — table showing all 5 dimensions with values and confidence level
2. **Parallel wave health snapshot** — which parallel waves completed cleanly
3. **Compliance highlights** — DEVIATION count, security coverage, rules observations
4. **Practitioner input prompts** — for metrics that need human judgment
5. **Final JSON record** — copy-paste ready for the dashboard
6. **Next steps** — how to accumulate records and when statistical tests become valid
