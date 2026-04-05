# Business Analyst Quality Gate Checklist

> Load this reference before signaling completion — verify all quality dimensions before handing off to Enterprise Architect and UX Designer.

Before handing off to EA + UX Designer (parallel), verify:

```markdown
## Business Analyst Quality Gate

### Requirements Analysis Document
- [ ] Requirements Analysis document exists at docs/requirements/requirements-analysis.md
- [ ] All sections completed — no placeholder text remaining
- [ ] Traces back to PO's BRD and PRD (BRQ-# and feature references present)
- [ ] Handoff Notes section completed for BOTH EA and UX Designer

### Stakeholder Analysis
- [ ] All key stakeholders identified (users, operators, executives, gatekeepers, regulators)
- [ ] Power/Interest matrix completed
- [ ] Each stakeholder's specific requirements documented
- [ ] Stakeholder conflicts identified and escalated or resolved
- [ ] Decision authority documented (who makes the call on open questions)

### Requirements Completeness
- [ ] Every PRD feature decomposed into specific, testable functional requirements
- [ ] Non-functional requirements refined and quantified (not vague: "fast" → "< 2s P95")
- [ ] Business constraints fully documented (timeline, budget, technology, team)
- [ ] All integration requirements specified (system, direction, data, trigger, latency SLA)
- [ ] Regulatory/compliance requirements captured and mapped to NFRs
- [ ] Traceability: every requirement traces to a BRD requirement or stakeholder need

### Gap Analysis
- [ ] Current capabilities assessed vs. desired future state
- [ ] All gaps identified, classified by impact (High/Medium/Low)
- [ ] Each gap has a recommendation and owner
- [ ] Gaps that are blocking EA/UX have been escalated to PO for decision

### Business Rules Catalogue
- [ ] All business rules documented (approval policies, calculation rules, access control rules)
- [ ] Each rule has a source (which policy, which stakeholder)
- [ ] Rules are unambiguous — engineers can implement them without further clarification

### Use Case Quality
- [ ] All major use cases documented (one UC per primary user goal or system interaction)
- [ ] Each UC has: header, preconditions, main success scenario, alternative flows, exception flows
- [ ] Business rules referenced within the UC they apply to
- [ ] Acceptance criteria listed per UC
- [ ] All UCs reviewed and validated with relevant stakeholders

### User Story Quality
- [ ] All stories in the Epic Story Inventory (from PO's epics) have been authored as detailed story documents
- [ ] Every story uses the correct format: As a [specific persona], I want [capability], so that [value]
- [ ] Persona is specific — not "user" or "admin" but a named persona from the PRD
- [ ] Acceptance criteria are in Given–When–Then format
- [ ] Happy path, edge cases, AND error cases all covered in AC
- [ ] Non-functional criteria included per story (performance, security, accessibility where applicable)
- [ ] Business rules listed and linked to the rules catalogue
- [ ] Data inputs and outputs documented per story
- [ ] Dependencies between stories explicitly mapped
- [ ] Definition of Done present on every story

### Acceptance Criteria Quality
- [ ] Every acceptance criterion is independently testable (Tester-QE can write a test without asking BA)
- [ ] No vague language: "works correctly," "loads fast," "user-friendly" — all replaced with measurable conditions
- [ ] Error states and failure scenarios covered (not just happy path)
- [ ] Boundary conditions included (minimum values, maximum values, empty states)
- [ ] Security acceptance criteria on stories involving auth, payments, PII, or data export

### Feasibility & Risk
- [ ] Technical feasibility assessed for all major requirements
- [ ] Timeline feasibility assessed
- [ ] Budget feasibility assessed
- [ ] Organizational feasibility assessed (skills, change management)
- [ ] Top risks documented with likelihood, impact, and mitigation
- [ ] Unknowns listed — items that need resolution before EA or UX can proceed flagged

### Data & Integration
- [ ] Data dictionary complete (all entities with classification, retention, regulatory flag)
- [ ] Integration requirements fully specified (enough for EA to design integration architecture)
- [ ] No PII in documents — all examples use synthetic data

### Handoff Readiness to EA + UX
- [ ] Requirements Analysis document is complete and approved
- [ ] All user stories authored and in docs/stories/
- [ ] All use cases authored and in docs/analysis/use-cases/
- [ ] Handoff Notes section completed: EA priorities listed; UX priorities listed
- [ ] No blocking open questions — or open questions explicitly flagged with owner and deadline
- [ ] Business Analyst has briefed EA and UX leads on key risks and constraints

**Gate Status:** [PASS / PASS WITH FLAGS / FAIL]
**Flags (if any):** [List items EA or UX must be aware of; list any open questions still pending]
**Sign-off:** Business Analyst + date
```
