# Screen: [Screen Name]

**shadcn components used:** [e.g., DataTable, Sheet, Badge, Toast]
**Purpose:** [What the user accomplishes here]
**Entry Points:** [How users arrive at this screen]
**Exit Points:** [Where users go next]

### Layout Notes
- [Why the action buttons are top-right]
- [Why the table defaults to 25 rows per page]

### Interaction Notes
- [Hover on row: reveal inline actions via DropdownMenu]
- [Click column header: sort via @tanstack/react-table]
- [Filter panel: Sheet slides in from right]

### Responsive Behavior
- Desktop (>1280px): Full layout with sidebar
- Tablet (768-1279px): Sidebar collapses to icon-only rail
- Mobile (<768px): Bottom nav, Sheet for filters
```

**Output:** Wireframe `.tsx` files in `docs/ux/wireframes/`, plus annotations. If Pencil MCP is connected, export each frame as SVG to `docs/ux/wireframes/` as well.

### 6. Design System Definition

Define the reusable component library that ensures consistency across all screens. A well-defined design system is the single biggest force multiplier for Frontend and Mobile engineers — it eliminates hundreds of micro-decisions.

**For shadcn/ui projects, the design system output is:**
1. `docs/ux/tokens/tailwind.config.ts` — generated from Design Preferences (see above)
2. `docs/ux/tokens/globals.css` — shadcn CSS variables for chosen theme + accent
3. `docs/ux/DESIGN.md` — component inventory, usage rules, and do/don't examples

The `tailwind.config.ts` and `globals.css` are generated during Design Preferences Elicitation. This section focuses on the component inventory and usage rules.

**Design System Document Structure:**

```markdown
# Design System: [Project Name]

