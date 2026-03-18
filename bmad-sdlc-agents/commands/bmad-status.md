---
description: Show current BMAD project status — phase, last handoff, artifact checklist, and open items.
argument-hint: (no arguments needed)
---

Read `.bmad/PROJECT-CONTEXT.md` and `.bmad/handoff-log.md` (if they exist) and produce a concise status report in this format:

## BMAD Project Status

**Project:** [name from PROJECT-CONTEXT.md]
**Current Phase:** [phase with checkbox showing active one]
**Last Handoff:** [from → to, date, summary from handoff-log.md]

### Artifact Checklist
| Artifact | Path | Status |
|---|---|---|
[Check whether each file in the artifact index actually exists on disk using available tools]

### Open Items
[Any open questions or risks from the most recent handoff log entry]

### Next Recommended Action
[Based on the current phase and last handoff, what should happen next]

If .bmad/PROJECT-CONTEXT.md doesn't exist:
1. Use the Bash tool to search for the scaffold script: `find ~ -name "scaffold-project.sh" -path "*/bmad-sdlc-agents/scripts/*" 2>/dev/null | head -1`
2. If found, show the user the exact command to run: `bash <found-path> "<project-name>"` — tell them to run it from their project root directory (the directory that will contain .bmad/, src/, etc.)
3. If not found, tell them to manually create `.bmad/PROJECT-CONTEXT.md` or clone the BMAD agents repo first.
