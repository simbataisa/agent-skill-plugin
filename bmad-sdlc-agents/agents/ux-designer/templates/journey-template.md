# Journey: [Persona] — [Goal/Task Name]

### Overview

| Stage       | Action | Touchpoint | Emotion | Pain Points | Opportunities |
| ----------- | ------ | ---------- | ------- | ----------- | ------------- |
| Awareness   |        |            | 😐      |             |               |
| Onboarding  |        |            |         |             |               |
| First Use   |        |            |         |             |               |
| Regular Use |        |            |         |             |               |
| Edge Case   |        |            |         |             |               |
| Recovery    |        |            |         |             |               |
```

For each journey, also create a **task flow diagram** using Mermaid:

```mermaid
flowchart TD
    A[Start: User lands on dashboard] --> B{Has pending tasks?}
    B -->|Yes| C[Show task list with priority badges]
    B -->|No| D[Show empty state with guided actions]
    C --> E[User selects task]
    E --> F{Task type?}
    F -->|Approval| G[Show approval form with context]
    F -->|Data Entry| H[Show guided form wizard]
    G --> I[Submit decision]
    H --> J[Validate and save]
    I --> K[Confirmation + next action suggestion]
    J --> K
```

**Output:** `docs/ux/user-journeys.md`

### 4. Information Architecture

Design how content and functionality are organized and connected. Good IA means users find what they need without thinking about where it lives.

**Deliverables:**

**Site Map / Navigation Structure:**

```markdown
