---
description: Log a BMAD agent-to-agent handoff. Creates a numbered child file and updates the master index.
argument-hint: "[from-agent] [to-agent]"
---

Log a formal BMAD handoff. Handoffs are stored as individual files in `.bmad/handoffs/`
so the master `.bmad/handoff-log.md` stays concise and every entry is independently
readable in git.

## Steps

1. Parse $ARGUMENTS to extract from-agent and to-agent abbreviations.
   If not provided, ask: "Which agent is handing off, and to whom?"
   Use these abbreviations: ba, po, sa, ea, ux, tl, qe, be, fe, me, hu

2. Read `.bmad/handoff-log.md` to determine the next handoff number:
   - Use the Bash tool: `ls .bmad/handoffs/*.md 2>/dev/null | grep -v _template | sort | tail -1`
   - Extract the numeric prefix and increment by 1, zero-padded to 3 digits (e.g. 004)

3. Ask the user (all at once, not one-by-one):
   - "What artifacts were completed? (list file paths)"
   - "What key decisions were made?"
   - "What open questions should the next agent address?"
   - "Any risks or watch-outs?"
   - "What should the next agent read first / focus on?"

4. Determine today's date with the Bash tool: `date '+%Y-%m-%d'`

5. Create the child file at `.bmad/handoffs/<NNN>-<YYYY-MM-DD>-<from>→<to>.md`:

```markdown
# Handoff #<NNN> — <YYYY-MM-DD>

**From:** <from-agent full name> (`<from>`)
**To:** <to-agent full name> (`<to>`)
**Phase:** <current phase from .bmad/PROJECT-CONTEXT.md>
**Session duration:** <ask if not obvious>

---

## Completed Deliverables

| Artifact | Path | Status |
|----------|------|--------|
<rows from user input>

## Key Decisions Made

<decisions from user input>

## Open Questions for Next Agent

<open questions as checklist items>

## Risks / Watch-outs

<risks from user input>

## Starting Point for Next Agent

<starting point from user input>
```

6. Update `.bmad/handoff-log.md` master index:
   - Remove the "No handoffs yet" placeholder row if it exists
   - Append a new row to the table:
     `| <NNN> | <date> | \`<from>\` → \`<to>\` | <phase> | <one-line summary> | [→ view](handoffs/<filename>) |`

7. Update `.bmad/PROJECT-CONTEXT.md` Last Handoff field to reference the new child file.

8. Confirm: "Handoff #<NNN> logged → `.bmad/handoffs/<filename>`. <to-agent full name> can now begin."
