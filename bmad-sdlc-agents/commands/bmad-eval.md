---
description: Collect productivity metrics from .bmad/ artifacts and output a JSON evaluation snapshot compatible with the BMAD Eval Dashboard.
argument-hint: "[week-number] (optional — defaults to current week)"
---

Collect BMAD productivity metrics for the current project and output a JSON evaluation
record compatible with the **BMAD Agent Productivity Evaluation Dashboard**.

## Context

This command auto-measures what it can from `.bmad/` artifacts, git history, and project
files — then asks the practitioner to fill in gaps that require human judgment.
The output is a single JSON record that can be appended to the dashboard's `DATA` array.

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
  # Weeks since first commit in .bmad/
  first_commit=$(git log --diff-filter=A --format="%ct" -- .bmad/ 2>/dev/null | tail -1)
  ```
  If this fails, ask the user for the week number.

### 3. Auto-collect Speed metrics

**Time-to-First-Draft** — Measure from task assignment to first artifact commit:
```bash
# For each artifact type, find earliest commit adding the file
for f in docs/project-brief.md docs/prd.md docs/architecture/solution-architecture.md \
         docs/architecture/enterprise-architecture.md docs/ux/design-system.md \
         docs/testing/test-strategy.md; do
  if [ -f "$f" ]; then
    created=$(git log --diff-filter=A --format="%ai" -- "$f" 2>/dev/null | tail -1)
    echo "$f | created: $created"
  fi
done
```

**Iteration Turnaround** — Count revision commits per artifact:
```bash
for f in docs/project-brief.md docs/prd.md docs/architecture/solution-architecture.md; do
  if [ -f "$f" ]; then
    revisions=$(git log --oneline -- "$f" 2>/dev/null | wc -l)
    first=$(git log --format="%ai" -- "$f" 2>/dev/null | tail -1)
    last=$(git log --format="%ai" -- "$f" 2>/dev/null | head -1)
    echo "$f | revisions: $revisions | first: $first | last: $last"
  fi
done
```

### 4. Auto-collect Quality metrics

**NFR Coverage Score** — Parse the solution architecture for NFR sections:
```bash
if [ -f docs/architecture/solution-architecture.md ]; then
  # Count how many of these NFR categories appear
  for nfr in "security" "performance" "scalability" "availability" "reliability" \
             "accessibility" "compliance" "observability" "maintainability"; do
    grep -qi "$nfr" docs/architecture/solution-architecture.md && echo "  ✅ $nfr" || echo "  ❌ $nfr"
  done
fi
```

**Architecture Debt** — Count ADR "deferred" or "debt" items:
```bash
debt_count=0
if [ -d docs/architecture/adr ]; then
  debt_count=$(grep -rli "debt\|deferred\|workaround\|technical-debt\|tech.debt" docs/architecture/adr/ 2>/dev/null | wc -l)
fi
echo "Arch debt items: $debt_count"
```

### 5. Auto-collect Coverage metrics

**Alternatives Evaluated** — Count options in ADRs:
```bash
if [ -d docs/architecture/adr ]; then
  for adr in docs/architecture/adr/*.md; do
    options=$(grep -ci "option\|alternative\|approach" "$adr" 2>/dev/null)
    echo "  $(basename $adr): ~$options options mentioned"
  done
fi
```

**Risks Identified** — Count risks across artifacts:
```bash
risk_count=0
for f in docs/project-brief.md docs/prd.md docs/architecture/solution-architecture.md; do
  if [ -f "$f" ]; then
    risks=$(grep -ci "risk\|concern\|caveat\|limitation\|constraint" "$f" 2>/dev/null)
    risk_count=$((risk_count + risks))
  fi
done
echo "Total risk mentions: $risk_count"
```

**Stakeholder Scenarios** — Count scenarios/use-cases:
```bash
scenario_count=0
for f in docs/prd.md docs/ux/design-system.md; do
  if [ -f "$f" ]; then
    sc=$(grep -ci "scenario\|use.case\|user.story\|workflow\|journey" "$f" 2>/dev/null)
    scenario_count=$((scenario_count + sc))
  fi
done
# Also count story files
story_count=$(ls docs/stories/*.md 2>/dev/null | wc -l)
echo "Scenarios: $scenario_count mentions + $story_count story files"
```

### 6. Count handoffs as a process health indicator

```bash
handoff_count=$(ls .bmad/handoffs/*.md 2>/dev/null | grep -v _template | wc -l)
echo "Handoffs completed: $handoff_count"
```

### 7. Ask the practitioner for metrics that can't be auto-collected

Present what was auto-collected, then ask for:

- **Practitioner ID and role** (e.g., "EA-01" / "SA-03")
- **Time-to-Artifact (hours)** — "How many hours from task start to the artifact being approved?"
- **Time-to-First-Draft (hours)** — "How many hours from task start to first draft commit?"
- **First-Pass Review Rate** — "Was the most recent artifact approved on first review? (y/n or ratio like 3/5)"
- **Phase** — "Is this a `baseline` (no AI) or `assisted` (AI-assisted) measurement?"

If the user declines to provide manual inputs, use the auto-collected approximations with
a `"confidence": "auto-estimated"` flag.

### 8. Output the evaluation record

Output a fenced JSON block in this exact schema:

```json
{
  "practitioner": "<ID>",
  "name": "<Name>",
  "role": "<EA|SA>",
  "week": <N>,
  "phase": "<baseline|assisted>",
  "timeToArtifact": <hours>,
  "timeToDraft": <hours>,
  "iterTurnaround": <hours>,
  "firstPassRate": <0.0-1.0>,
  "nfrCoverage": <0.0-1.0>,
  "archDebt": <count>,
  "alternatives": <count>,
  "risks": <count>,
  "scenarios": <count>,
  "_autoCollected": {
    "nfrSections": ["list of NFRs found"],
    "adrCount": <N>,
    "storyCount": <N>,
    "handoffCount": <N>,
    "artifactRevisions": {"file": <N>}
  },
  "_collectedAt": "<ISO-8601 timestamp>"
}
```

### 9. Suggest appending to the dashboard

Tell the user:

> **To add this to your dashboard:**
> 1. Open `.bmad/eval/bmad-agent-eval-dashboard.html` (scaffolded with your project) or
>    `~/.bmad/eval/bmad-agent-eval-dashboard.html` (installed globally)
> 2. Find the `const DATA = genData();` line
> 3. Replace it with `const DATA = [` ... paste your records ... `];`
> 4. Or append this record to an existing `DATA` array
>
> Once you have 4+ weeks of baseline and 4+ weeks of AI-assisted data,
> the statistical significance tests will become meaningful.

### 10. Append to local eval log (optional)

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

1. **Auto-collected metrics summary** — table showing what was found and confidence level
2. **Practitioner input prompts** — for metrics that need human judgment
3. **Final JSON record** — copy-paste ready for the dashboard
4. **Next steps** — how to accumulate records and when statistical tests become valid
