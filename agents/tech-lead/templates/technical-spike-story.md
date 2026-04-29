# Template: Technical Spike Story

Create spike stories during Planning when uncertainty is high. Put in `docs/stories/spikes/`:

```markdown
# Technical Spike: [Spike ID] — [Title]

## Problem Statement
[What is uncertain? What do we need to learn?]

Example: "We don't know if our current database schema can support multi-tenancy at scale. This uncertainty blocks feature implementation."

## Spike Goals
1. [Specific learning goal 1]
2. [Specific learning goal 2]
3. [Specific learning goal 3]

Example:
1. Design a multi-tenant schema using row-level security
2. Measure performance impact of RLS on typical queries
3. Estimate effort to migrate existing data

## Success Criteria
- Spike is complete when we can:
  1. [Measurable outcome 1]
  2. [Measurable outcome 2]

Example:
1. We have a proof-of-concept schema that handles 100k users with RLS
2. Query latency with RLS is < 50ms (verified by load test)
3. We've estimated migration effort and identified blocking issues

## Approach / Methodology
[How will you explore this?]

Example:
1. Create isolated test database with POC schema
2. Load representative data volume
3. Write queries against POC; measure latency
4. Identify migration blockers and workarounds
5. Document learnings and recommendations

## Timeline
- **Duration:** [X days/weeks]
- **Effort:** [X story points / hours]
- **Owner:** [Engineer or specialist]

## Output Artifacts
- Design document: `docs/spikes/multi-tenancy-schema-design.md`
- POC code: `spike/multi-tenancy-poc/`
- Performance test results: `docs/spikes/rls-performance-test.md`
- Recommendation: Approve/reject approach with rationale

## Assumptions
- [Assumption 1]
- [Assumption 2]

## Blockers / Dependencies
- Depends on: [Other spike, infrastructure, team availability]
- Blocks: [Features that wait for this spike outcome]

---

**Outcome:** [After spike completes, document the decision and next steps]

**Decision:** Use RLS for multi-tenancy (approved by Tech Lead + Architect)
**Rationale:** Meets performance targets, lower migration risk
**Next Steps:** Break feature story into implementable tasks with schema migration as first story
```

