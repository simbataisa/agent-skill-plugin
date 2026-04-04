# Template: Use Case

```markdown
## Use Case: [Use Case Name]

**Primary Actor:** [User role, e.g., "Customer Service Rep"]
**Scope:** [System or subsystem]
**Level:** [User goal, Subfunction, Task]
**Preconditions:** [What must be true before the use case starts?]
**Success Postcondition:** [What's true when the use case succeeds?]
**Failure Postcondition:** [What's true if the use case fails?]

### Main Success Flow
1. Actor [does something]
2. System [responds with something]
3. Actor [does something else]
...
N. System [achieves goal]

### Alternative Flows
**A2.1: [Condition], e.g., "Customer is not in database"**
- 2.1a. System [alternative behavior]
- 2.1b. System [resolves or branches back to main flow]

**A5.1: [Condition], e.g., "Payment fails"**
- 5.1a. System [alternative behavior]

### Exception Flows
**E1: [Exception], e.g., "System timeout"**
- 1a. System [recovery action or fail]
```

