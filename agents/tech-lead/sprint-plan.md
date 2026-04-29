---
description: "[Tech Lead] Generate a sprint plan from the current backlog. Reviews docs/stories/ and produces a prioritized, capacity-matched sprint."
argument-hint: "[sprint number] [capacity in points, e.g. 40]"
---

Generate a sprint plan.

Steps:
1. Parse $ARGUMENTS for sprint number and team capacity (points). Defaults: sprint=next, capacity=40 points.
2. Read `.bmad/PROJECT-CONTEXT.md` for project context and team size
3. Read all files in `docs/stories/` — extract: Story ID, title, points (if specified), priority, dependencies, assigned agent
4. Read `.bmad/tech-stack.md` to understand tech boundaries
5. Apply prioritization:
   - P0 (must): stories blocking other stories, stories with overdue dependencies
   - P1 (should): highest RICE or MoSCoW "Must" items
   - P2 (could): nice-to-haves if capacity allows
6. Generate sprint plan:

## Sprint [N] Plan
**Capacity:** [N] points | **Team:** [N] engineers

### Committed Stories (total: N points)
| Story | Title | Points | Owner | Dependencies |
|---|---|---|---|---|

### Stretch Stories (if capacity allows)
| Story | Title | Points | Owner |
|---|---|---|---|

### Not This Sprint
[Stories deferred and brief reason]

### Sprint Goal
[One sentence describing the sprint's theme/outcome]

### Risks
[Any dependencies, blockers, or uncertainties]

7. Ask: "Shall I save this as docs/sprint-[N]-plan.md?"
