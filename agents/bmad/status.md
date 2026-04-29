---
description: "[BMAD] Show current BMAD project status — active work type, current wave, artifact checklist, parallel wave health, and next recommended action."
argument-hint: "(no arguments needed)"
---

Produce a concise BMAD project status report. Use the Bash tool to read files.

## Steps

### 1. Read project context

```bash
cat .bmad/PROJECT-CONTEXT.md 2>/dev/null
```

Extract: project name, current phase, practitioner info (if present).

### 2. Read last handoff

```bash
ls .bmad/handoffs/*.md 2>/dev/null | grep -v _template | sort | tail -1
```

Read that file for: from/to agents, phase, completed deliverables, open questions, risks,
and starting point for next agent. Also read `.bmad/handoff-log.md` for the total handoff count.

### 3. Detect active work type

Scan for signal files in this priority order:

```bash
# Hotfix?
ls docs/testing/hotfixes/*.md 2>/dev/null | grep -v "\-verified" | head -1

# Bug fix?
ls docs/testing/bugs/*-fix-plan.md 2>/dev/null | head -1

# Sprint executing?
ls docs/architecture/sprint-*-kickoff.md 2>/dev/null | sort | tail -1

# Feature in progress?
ls docs/analysis/*-impact.md 2>/dev/null | head -1
ls docs/stories/*/  2>/dev/null | head -1

# Backlog in progress?
ls docs/analysis/*-analysis.md 2>/dev/null | head -1

# New project planning?
ls docs/project-brief.md 2>/dev/null
```

Use the highest-priority match to set **Active Work Type**:
`Hotfix | Bug Fix | Sprint Execution | Feature | Backlog | New Project | Unknown`

### 4. Detect current wave and parallel wave health

Based on the active work type, check which agents have produced their outputs:

**New Project — Plan:**
```bash
# W1 BA done?
[ -f docs/project-brief.md ] && echo "W1 BA ✅" || echo "W1 BA ❌"
# W2 PO done?
[ -f docs/prd.md ] && echo "W2 PO ✅" || echo "W2 PO ❌"
# W3 SA done?
[ -f docs/architecture/solution-architecture.md ] && echo "W3 SA ✅" || echo "W3 SA ❌"
# W4 EA + UX (parallel) — both must be done before W5
[ -f docs/architecture/enterprise-architecture.md ] && echo "W4 EA ✅" || echo "W4 EA ❌ (parallel)"
[ -f docs/ux/DESIGN.md ] && echo "W4 UX ✅" || echo "W4 UX ❌ (parallel)"
# W5 TL done?
[ -f docs/architecture/sprint-plan.md ] && echo "W5 TL ✅" || echo "W5 TL ❌"
# W6 specs (parallel) — all three needed
[ -f docs/architecture/backend-implementation-spec.md ] && echo "W6 BE-spec ✅" || echo "W6 BE-spec ❌ (parallel)"
[ -f docs/architecture/frontend-implementation-spec.md ] && echo "W6 FE-spec ✅" || echo "W6 FE-spec ❌ (parallel)"
[ -f docs/architecture/mobile-implementation-spec.md ] && echo "W6 ME-spec ✅" || echo "W6 ME-spec ❌ (parallel)"
# W7 TQE strategy done?
[ -f docs/testing/test-strategy.md ] && echo "W7 TQE ✅" || echo "W7 TQE ❌"
```

**Feature — Plan:**
```bash
# W1 PO done?
ls docs/stories/ 2>/dev/null && echo "W1 PO ✅" || echo "W1 PO ❌"
# W2 BA impact analysis done?
ls docs/analysis/*-impact.md 2>/dev/null | head -1 && echo "W2 BA ✅" || echo "W2 BA ❌"
# W3 SA + UX (parallel)
[ -f docs/architecture/solution-architecture.md ] && echo "W3 SA ✅" || echo "W3 SA ❌ (parallel)"
ls docs/ux/ 2>/dev/null | head -1 && echo "W3 UX ✅" || echo "W3 UX ❌ (parallel)"
# W4 TL feature plan
ls docs/architecture/*-plan.md 2>/dev/null | head -1 && echo "W4 TL ✅" || echo "W4 TL ❌"
# W5 TQE
[ -f docs/testing/test-strategy.md ] && echo "W5 TQE ✅" || echo "W5 TQE ❌"
```

**Sprint Execution:**
```bash
# Latest kickoff
latest_kickoff=$(ls docs/architecture/sprint-*-kickoff.md 2>/dev/null | sort | tail -1)
echo "Latest kickoff: $latest_kickoff"
# Sprint N from filename
sprint_n=$(echo "$latest_kickoff" | grep -oP 'sprint-\K[0-9]+')
echo "Sprint: $sprint_n"
# Results file
[ -f "docs/testing/sprint-${sprint_n}-results.md" ] && echo "E3 TQE ✅" || echo "E3 TQE ❌"
```

**Backlog:**
```bash
# W1 PO story
ls docs/stories/*.md 2>/dev/null | sort | tail -1 && echo "W1 PO ✅" || echo "W1 PO ❌"
# W2 BA analysis
ls docs/analysis/*-analysis.md 2>/dev/null | head -1 && echo "W2 BA ✅" || echo "W2 BA ❌"
# W3 TL notes
ls docs/architecture/*-notes.md 2>/dev/null | head -1 && echo "W3 TL ✅" || echo "W3 TL ❌"
```

**Bug Fix:**
```bash
latest_bug=$(ls docs/testing/bugs/*.md 2>/dev/null | grep -v "\-fix-plan\|-verified" | sort | tail -1)
fix_plan=$(ls docs/testing/bugs/*-fix-plan.md 2>/dev/null | sort | tail -1)
verified=$(ls docs/testing/bugs/*-verified.md 2>/dev/null | sort | tail -1)
echo "Bug report: $latest_bug"
echo "Fix plan: $fix_plan"
echo "Verified: $verified"
```

**Hotfix:**
```bash
latest_hotfix=$(ls docs/testing/hotfixes/*.md 2>/dev/null | grep -v "\-verified" | sort | tail -1)
verified=$(ls docs/testing/hotfixes/*-verified.md 2>/dev/null | sort | tail -1)
echo "Hotfix doc: $latest_hotfix"
echo "Verified: $verified"
```

### 5. Count deviations and open issues

```bash
# DEVIATION comments in source code
deviation_count=$(grep -r "// DEVIATION:\|# DEVIATION:" . \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" \
  --include="*.go" --include="*.java" --include="*.swift" --include="*.kt" \
  2>/dev/null | wc -l)
echo "Open deviations: $deviation_count"

# FIX / HOTFIX markers
fix_count=$(grep -r "// FIX:\|// HOTFIX:\|# FIX:\|# HOTFIX:" . \
  --include="*.ts" --include="*.tsx" --include="*.js" --include="*.py" \
  2>/dev/null | wc -l)
echo "Fix/hotfix markers: $fix_count"
```

### 6. Output the report

---

## BMAD Project Status

**Project:** [name from PROJECT-CONTEXT.md]
**Active Work Type:** [ ] New Project  [ ] Feature  [ ] Backlog  [ ] Bug Fix  [ ] Hotfix  [ ] Sprint Execution
*(mark active with [x])*

**Current Phase:** [ ] Analysis  [ ] Planning  [ ] Solutioning  [ ] Implementation
*(mark active with [x])*

**Total Handoffs:** [N] — see `.bmad/handoff-log.md` for full index

### Last Handoff (#NNN — YYYY-MM-DD)
**[from-agent] → [to-agent]**
[one-line summary]
[link: `.bmad/handoffs/<filename>`]

### Wave Status
*Show only waves relevant to the active work type. Use ✅ (done), ⏳ (in progress / waiting for peer), ❌ (not started).*

| Wave | Agent(s) | Output Artifact | Status |
|------|----------|-----------------|--------|
| [wave] | [agent] | [artifact path] | ✅ / ⏳ / ❌ |
| ... | | | |

> ⚠️ **Parallel wave incomplete:** [If any W4/W6/E2 agents show mixed ✅/❌, flag it here]
> e.g. "EA ✅ but UX ❌ — Tech Lead cannot start until both W4 agents complete."

### Artifact Checklist
*Check only artifacts relevant to the active work type.*

**Core Planning (New Project):**
| Artifact | Path | Status |
|----------|------|--------|
| Project Brief | `docs/project-brief.md` | ✅ / ❌ |
| PRD | `docs/prd.md` | ✅ / ❌ |
| Solution Architecture | `docs/architecture/solution-architecture.md` | ✅ / ❌ |
| Enterprise Architecture | `docs/architecture/enterprise-architecture.md` | ✅ / ❌ |
| UX / Design System | `docs/ux/DESIGN.md` | ✅ / ❌ |
| ADRs | `docs/architecture/adr/` | [N files] / ❌ |
| Backend Impl Spec | `docs/architecture/backend-implementation-spec.md` | ✅ / ❌ |
| Frontend Impl Spec | `docs/architecture/frontend-implementation-spec.md` | ✅ / ❌ |
| Mobile Impl Spec | `docs/architecture/mobile-implementation-spec.md` | ✅ / ❌ |
| Test Strategy | `docs/testing/test-strategy.md` | ✅ / ❌ |
| User Stories | `docs/stories/` | [N files] / ❌ |

**Feature / Backlog (when applicable):**
| Artifact | Path | Status |
|----------|------|--------|
| Feature Impact Analysis | `docs/analysis/*-impact.md` | [N files] / ❌ |
| Backlog Requirements Analysis | `docs/analysis/*-analysis.md` | [N files] / ❌ |
| Feature Plan | `docs/architecture/*-plan.md` | [N files] / ❌ |

**Sprint Execution (when applicable):**
| Artifact | Path | Status |
|----------|------|--------|
| Sprint Plan | `docs/architecture/sprint-plan.md` | ✅ / ❌ |
| Latest Sprint Kickoff | `docs/architecture/sprint-N-kickoff.md` | Sprint [N] / ❌ |
| Latest Sprint Results | `docs/testing/sprint-N-results.md` | Sprint [N] ✅ / ❌ |

**Bug Fix / Hotfix (when applicable):**
| Artifact | Path | Status |
|----------|------|--------|
| Bug Reports | `docs/testing/bugs/` | [N files] / ❌ |
| Fix Plans | `docs/testing/bugs/*-fix-plan.md` | [N files] / ❌ |
| Verified Fixes | `docs/testing/bugs/*-verified.md` | [N files] / ❌ |
| Hotfix Docs | `docs/testing/hotfixes/` | [N files] / ❌ |

### Code Health Indicators
| Indicator | Count | Notes |
|-----------|-------|-------|
| DEVIATION markers | [N] | Architecture deviations to review |
| FIX/HOTFIX markers | [N] | Applied fixes/hotfixes in code |

### Open Items (from last handoff)
[open questions and risks from the most recent handoff file]

### Next Recommended Action

*Based on active work type, current wave, and missing artifacts:*

[Specific recommendation — e.g.:]
- **"W4 is incomplete: EA ✅ but UX ❌ → Invoke `/ux-designer` to complete Wave 4, then invoke `/tech-lead` for W5."]
- **"W6 all specs complete → Invoke `/tester-qe` for test strategy (W7), then proceed to sprint execution."]
- **"Feature: PO ✅, BA ❌ → Invoke `/business-analyst` for feature impact analysis (W2) before SA/UX."]
- **"Sprint N kickoff exists, no results → Spawn `/backend-engineer` ∥ `/frontend-engineer` ∥ `/mobile-engineer` in parallel (Wave E2)."]

---

## If `.bmad/PROJECT-CONTEXT.md` doesn't exist

1. Use the Bash tool to search for the scaffold script:
   `find ~ -name "scaffold-project.sh" -path "*/bmad-sdlc-agents/scripts/*" 2>/dev/null | head -1`
2. If found, show the user the exact command to run from their project root:
   `bash <found-path> "<project-name>"`
3. If not found, tell them to manually create `.bmad/PROJECT-CONTEXT.md` or clone the BMAD agents repo first.
