# UI Spec: [Feature/Screen Name]

### Screen States

| State     | Trigger           | Visual                         | Data              |
| --------- | ----------------- | ------------------------------ | ----------------- |
| Loading   | Initial page load | Skeleton placeholders          | Fetching from API |
| Empty     | No data returned  | Empty state illustration + CTA | None              |
| Populated | Data available    | Full layout with content       | From API          |
| Error     | API failure       | Error banner + retry button    | Cached or none    |
| Partial   | Some data failed  | Content + inline error badges  | Partial           |

### Interaction Specifications

#### [Interaction Name]

- **Trigger:** [Click/Hover/Focus/Swipe/Keyboard shortcut]
- **Animation:** [Duration, easing, property] (e.g., 200ms ease-out opacity)
- **Feedback:** [Visual/auditory response]
- **Loading:** [Optimistic update / spinner / skeleton]
- **Success:** [Toast message / inline confirmation / redirect]
- **Error:** [Inline error / toast / modal]
- **Undo:** [Available for N seconds / not applicable]

### Responsive Breakpoints

| Breakpoint          | Layout Changes    | Hidden Elements       | Modified Components |
| ------------------- | ----------------- | --------------------- | ------------------- |
| ≥1280px (Desktop)   | Full layout       | None                  | Full table          |
| 768-1279px (Tablet) | Sidebar collapses | Secondary nav         | Table → card list   |
| <768px (Mobile)     | Single column     | Sidebar, bulk actions | Bottom sheet nav    |

### Keyboard Shortcuts

| Shortcut | Action              | Context          |
| -------- | ------------------- | ---------------- |
| /        | Focus global search | Anywhere         |
| Esc      | Close modal/panel   | When modal open  |
| Ctrl+S   | Save form           | Within forms     |
| ← →      | Navigate pages      | Table pagination |

### Error State Mapping

| Error Type      | HTTP Status | User Message                     | Action                                  |
| --------------- | ----------- | -------------------------------- | --------------------------------------- |
| Network failure | 0 / timeout | "Connection lost. Retrying..."   | Auto-retry 3x, then manual retry button |
| Auth expired    | 401         | "Session expired"                | Redirect to login, preserve form state  |
| Forbidden       | 403         | "You don't have access"          | Link to request access                  |
| Not found       | 404         | "This item was deleted or moved" | Link to parent list                     |
| Validation      | 422         | Field-specific inline errors     | Scroll to first error, focus field      |
| Server error    | 500         | "Something went wrong"           | Retry button + support link             |
| Rate limited    | 429         | "Too many requests"              | Auto-retry with backoff indicator       |
```

**Output:** `docs/ux/ui-spec.md`

