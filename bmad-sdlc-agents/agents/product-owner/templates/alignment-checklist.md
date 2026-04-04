# Template: Alignment Checklist

Use this to verify PRD ↔ Architecture ↔ Stories consistency:

```markdown
## Alignment Checklist — [Date]

### PRD Completeness
- [ ] All epics in PRD have a clear business goal
- [ ] All functional requirements are testable (acceptance criteria defined)
- [ ] All non-functional requirements (security, scalability, compliance) are present
- [ ] Dependencies between requirements are documented
- [ ] Stakeholder assumptions are documented

### Architecture Alignment
- [ ] Every PRD feature maps to at least one architecture component
- [ ] Every architecture component addresses at least one PRD requirement
- [ ] Non-functional requirements (security, scalability, etc.) are addressed in architecture
- [ ] Integration points between components are specified
- [ ] Data model supports all PRD features

### Story Alignment
- [ ] Every user story implements at least one PRD requirement
- [ ] Story acceptance criteria are traceable to PRD
- [ ] Stories are appropriately sized (1-3 days of work)
- [ ] Dependencies between stories are identified
- [ ] Stories reference architecture components they implement

### Conflict Summary
- Gap: [description]
  - Impact: [what breaks if not resolved]
  - Resolution: [who owns, what to fix]
```

