---
description: Show current BMAD project status — phase, last handoff, artifact checklist, and open items.
argument-hint: (no arguments needed)
---

Produce a concise BMAD project status report. Use the Bash tool to read files.

## Steps

1. Read `.bmad/PROJECT-CONTEXT.md` for project name, current phase, and artifact index.

2. Find the most recent handoff child file:
   ```bash
   ls .bmad/handoffs/*.md 2>/dev/null | grep -v _template | sort | tail -1
   ```
   Read that file for: from/to agents, phase, completed deliverables, open questions, risks,
   and starting point for next agent.
   Also read `.bmad/handoff-log.md` for the total handoff count and overall history.

3. Check which artifact files actually exist on disk using the Bash tool.
   **Only check the 8 BMAD-defined artifact paths listed in the template below.**
   Do NOT include files from other skill systems or methodology tools (e.g. `docs/superpowers/`,
   `docs/personas/`, `docs/plans/`, etc.) — those are outside BMAD scope and must be excluded.

4. Output this report:

---

## BMAD Project Status

**Project:** [name from PROJECT-CONTEXT.md]
**Current Phase:** [ ] Analysis  [ ] Planning  [ ] Solutioning  [ ] Implementation
*(mark the active phase with [x])*

**Total Handoffs:** [N] — see `.bmad/handoff-log.md` for full index

### Last Handoff (#NNN — YYYY-MM-DD)
**[from-agent] → [to-agent]**
[one-line summary of what was handed off]
[link: `.bmad/handoffs/<filename>`]

### Artifact Checklist
| Artifact | Path | Status |
|----------|------|--------|
| Project Brief | `docs/project-brief.md` | ✅ / ❌ |
| PRD | `docs/prd.md` | ✅ / ❌ |
| Solution Architecture | `docs/architecture/solution-architecture.md` | ✅ / ❌ |
| Enterprise Architecture | `docs/architecture/enterprise-architecture.md` | ✅ / ❌ |
| Design System | `docs/ux/design-system.md` | ✅ / ❌ |
| ADRs | `docs/architecture/adr/` | [N files] / ❌ |
| Test Strategy | `docs/testing/test-strategy.md` | ✅ / ❌ |
| User Stories | `docs/stories/` | [N files] / ❌ |

### Open Items (from last handoff)
[open questions and risks from the most recent handoff child file]

### Next Recommended Action
[Based on current phase, last handoff, and missing artifacts — what should happen next and which agent should do it]

---

## If `.bmad/PROJECT-CONTEXT.md` doesn't exist

1. Use the Bash tool to search for the scaffold script:
   `find ~ -name "scaffold-project.sh" -path "*/bmad-sdlc-agents/scripts/*" 2>/dev/null | head -1`
2. If found, show the user the exact command to run from their project root:
   `bash <found-path> "<project-name>"`
3. If not found, tell them to manually create `.bmad/PROJECT-CONTEXT.md` or clone the BMAD agents repo first.
