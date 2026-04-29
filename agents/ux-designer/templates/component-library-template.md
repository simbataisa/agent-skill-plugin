# Component Library

### Buttons

| Variant        | Usage                         | States                                    |
| -------------- | ----------------------------- | ----------------------------------------- |
| Primary        | Main CTA per screen (limit 1) | Default, Hover, Active, Disabled, Loading |
| Secondary      | Secondary actions             | Same                                      |
| Tertiary/Ghost | Low-emphasis actions          | Same                                      |
| Danger         | Destructive actions           | Same                                      |
| Icon-only      | Toolbar actions               | Same + Tooltip required                   |

### Form Controls

- Text Input: Single line, with label, helper text, error state, character count
- Text Area: Multi-line, auto-growing, with character limit
- Select/Dropdown: Single and multi-select, with search for >7 options
- Checkbox: Single and group, with indeterminate state
- Radio: Mutually exclusive options (use when ≤5 options)
- Toggle: Immediate effect settings (not for form submissions)
- Date Picker: Single date, date range, with keyboard input fallback
- File Upload: Drag-and-drop zone + click, with file type/size validation

### Data Display

- Table: Sortable, filterable, paginated, with row selection and bulk actions
- Card: Content container with optional header, body, footer, actions
- List: Ordered, unordered, with icons/avatars, clickable items
- Stat/Metric: Large number with label, trend indicator, sparkline
- Badge/Tag: Status indicators, categories, counts
- Empty State: Illustration + message + primary action

### Navigation

- Top Bar: Logo, global search, notifications, user menu
- Side Nav: Collapsible, with icons, active state, section grouping
- Breadcrumbs: For deep hierarchies (>2 levels)
- Tabs: In-page content switching (max 6 tabs)
- Stepper: Multi-step workflows with progress indication

### Feedback

- Toast/Snackbar: Transient success/info messages (auto-dismiss 5s)
- Alert/Banner: Persistent warnings/errors (user dismissible)
- Modal/Dialog: Confirmations, focused tasks (use sparingly)
- Skeleton: Loading placeholder matching content shape
- Progress Bar: Determinate progress for long operations
- Spinner: Indeterminate loading (use only when duration unknown)
```

**Output:** `docs/ux/DESIGN.md`

### 7. Accessibility Compliance (WCAG 2.2 AA)

Accessibility isn't an afterthought — it's a first-class design constraint. Enterprise software is legally required to be accessible in many jurisdictions, and good accessibility improves usability for everyone.

**Accessibility Checklist:**

```markdown
