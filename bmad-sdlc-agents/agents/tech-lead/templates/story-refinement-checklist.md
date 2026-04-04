# Template: Story Refinement Checklist

Use this when reviewing stories during Planning phase:

```markdown
# Story Refinement Checklist

## Story: [Story ID] — [Title]

### Clarity & Completeness
- [ ] Story title is specific and action-oriented (not generic)
- [ ] User story follows format: "As a [role], I want [action], so that [benefit]"
- [ ] Acceptance criteria are SMART (Specific, Measurable, Achievable, Relevant, Time-bound)
- [ ] No vague words ("easy," "fast," "simple," "elegant")
- [ ] Definition of Done is clear and testable

### Technical Clarity
- [ ] Story identifies affected services/components
- [ ] API contracts or data model changes documented
- [ ] Integration points with other services listed
- [ ] Dependencies on other stories identified
- [ ] Performance requirements explicit (if any)
- [ ] Security requirements explicit (authentication, authorization, encryption)
- [ ] Database changes scoped (schema migration, data transformation)

### Complexity Assessment
- **Estimated Complexity:** Simple / Medium / Complex
- If Complex:
  - [ ] Story broken into smaller stories (if possible)
  - [ ] Technical spike recommended before implementation
  - [ ] Epic-level dependencies called out

### Testing & QE Alignment
- [ ] Testable acceptance criteria (not subjective)
- [ ] QE agent has reviewed and agrees on test cases
- [ ] Test data requirements defined
- [ ] Integration test scenarios identified

### Architectural Alignment
- [ ] Story aligns with ADRs (Architecture Decision Records)
- [ ] Design patterns consistent with codebase
- [ ] No shortcuts or "quick hacks" that create debt
- [ ] Non-functional requirements considered (scalability, security, observability)

### Risk Assessment
- **Technical Risk:** Low / Medium / High
- If High:
  - [ ] Mitigation strategy defined
  - [ ] Spike task recommended
  - [ ] Buffer time added to estimate
- **Integration Risk:** Low / Medium / High
  - If High: Dependencies mapped, other teams notified

### Ready to Implement?
- [ ] Story is estimated (story points)
- [ ] All questions answered
- [ ] All blockers resolved
- [ ] Tech Lead and QE sign-off
- [ ] No hidden complexity

**Signed Off By:** [Tech Lead] — Date: [YYYY-MM-DD]

---

**If any checkbox is unchecked:** Story is NOT READY. Return to refinement with Product Manager and Architect.
```

