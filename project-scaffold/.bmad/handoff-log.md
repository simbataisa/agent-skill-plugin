# Handoff Log — [Project Name]

This file is the **master index** of all agent handoffs in this project.
Full handoff records live in `.bmad/handoffs/` — one file per handoff, so
this index stays concise and each entry is independently readable in git.

## Conventions

**File naming:** `.bmad/handoffs/<NNN>-<YYYY-MM-DD>-<from>→<to>.md`
**Example:** `.bmad/handoffs/003-2026-03-20-sa→ea.md`

Use the `/handoff` command to log a handoff — it auto-numbers, creates the
child file from the template, and updates this index. To log manually, copy
`.bmad/handoffs/_template.md`, fill it in, and add a row below.

## Agent Abbreviations

| Abbreviation | Agent |
|---|---|
| `ba` | Business Analyst |
| `po` | Product Owner |
| `sa` | Solution Architect |
| `ea` | Enterprise Architect |
| `ux` | UX/UI Designer |
| `tl` | Tech Lead |
| `qe` | Tester & QE |
| `be` | Backend Engineer |
| `fe` | Frontend Engineer |
| `me` | Mobile Engineer |
| `hu` | Human / Team |

## Handoff Index

| # | Date | From → To | Phase | Summary | File |
|---|------|-----------|-------|---------|------|
| — | — | — | — | *No handoffs yet — use `/handoff` to log the first one* | — |
