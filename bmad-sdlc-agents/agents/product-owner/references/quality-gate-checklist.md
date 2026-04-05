# Product Owner Quality Gate Checklist

> Load this reference before signaling completion — verify BRD quality, PRD quality, epic definitions, and stakeholder readiness before handing off to Business Analyst.

Run this before transitioning to Business Analyst:

```markdown
## Product Owner Quality Gate

### BRD Quality
- [ ] Executive summary written for C-suite audience (no technical jargon)
- [ ] Business objectives listed with measurable KPIs and targets
- [ ] Problem statement is specific and quantified (revenue, time, compliance risk)
- [ ] All key stakeholders listed with power/interest and primary need
- [ ] High-level functional needs documented in business language (not implementation)
- [ ] Non-functional needs captured at business level (availability, performance, compliance)
- [ ] Data classification table completed (sensitivity levels for all data types)
- [ ] Regulatory requirements explicitly listed — or stated as "No regulatory requirements identified"
- [ ] Known integration requirements listed (systems the solution must connect with)
- [ ] Business constraints documented (budget, timeline, technology, geography)
- [ ] MVP scope indication provided (high-level what is in/out of v1)
- [ ] Business success criteria are measurable (baselines + targets + measurement methods)
- [ ] Open questions listed with owner and target resolution date
- [ ] Executive sponsor sign-off obtained

### PRD Quality
- [ ] Objectives trace back to BRD requirements (BRQ-# references present)
- [ ] User personas are specific (named, with goals and pain points — not just "user")
- [ ] Epic overview table complete — all major capability groupings identified
- [ ] Feature catalogue written in business language (WHAT, not HOW)
- [ ] Every feature has a measurable success criterion
- [ ] MoSCoW priorities assigned to all features
- [ ] MVP scope definition is explicit — both "In Scope" and "Out of Scope" lists complete
- [ ] "Out of Scope" explicitly lists items stakeholders raised but we are NOT building
- [ ] Business-level NFRs included (availability, performance, compliance, data retention)
- [ ] Roadmap overview shows MVP → v2 → v3 progression
- [ ] No silent assumptions — all ambiguities flagged as open questions
- [ ] Stakeholder sign-off obtained

### Epic Quality (for each epic produced)
- [ ] Clear problem statement (specific, quantified where possible)
- [ ] Business value is measurable (success metrics with baselines and targets)
- [ ] Scope definition: "In Scope" and "Out of Scope" sections complete
- [ ] Affected user personas identified
- [ ] Story inventory table created — story titles and MoSCoW priorities only
- [ ] Story inventory clearly marked as "Pending BA" — no story point estimates set by PO
- [ ] Milestones defined at phase level (MVP, v2, etc.)
- [ ] Risks and assumptions documented
- [ ] Stakeholder sign-off section complete

### Handoff Readiness to Business Analyst
- [ ] BRD complete and signed off
- [ ] PRD complete and signed off
- [ ] All epics from PRD have at least a Story Inventory table
- [ ] All ambiguities are flagged as open questions — no silent assumptions passed downstream
- [ ] Handoff memo prepared (templates/artifact-handoff-memo.md) with context for BA
- [ ] BA has been briefed: project background, key stakeholder personalities, political sensitivities

**Gate Status:** [PASS / PASS WITH FLAGS / FAIL]
**Flags (if any):** [List open questions or gaps BA must be aware of]
**Sign-off:** Product Owner + date
```
