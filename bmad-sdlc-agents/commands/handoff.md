---
description: Log a BMAD agent-to-agent handoff. Records what was completed and what the next agent should do.
argument-hint: "[from-agent] [to-agent]"
---

Log a formal BMAD handoff in `.bmad/handoff-log.md`.

Steps:
1. Parse $ARGUMENTS to extract: from-agent and to-agent (e.g., "business-analyst product-owner")
2. If not provided, ask: "Which agent is handing off, and to whom?"
3. Read `.bmad/handoff-log.md` to find the current handoff number
4. Ask the user:
   - "What artifacts were completed in this handoff?" (list file paths)
   - "What key decisions were made?"
   - "What open questions should the next agent address?"
   - "Any risks or watch-outs?"
5. Append a new handoff entry to `.bmad/handoff-log.md` using this format:

---
## Handoff #[N] — [today's date]
**From:** [from-agent]
**To:** [to-agent]
**Phase:** [current phase from PROJECT-CONTEXT.md]

### Completed Deliverables
[list of artifacts]

### Key Decisions Made
[decisions]

### Open Questions for Next Agent
[questions]

### Risks / Watch-outs
[risks]

### Next Agent's Starting Point
Read [most important artifact] first, then focus on [next task].

6. Update `.bmad/PROJECT-CONTEXT.md` Last Handoff field
7. Confirm: "Handoff #[N] logged. [to-agent] can now begin."
