# Navigation Architecture

### Primary Navigation

- Dashboard
  - Overview widgets
  - Quick actions
  - Recent activity
- [Module 1]
  - Sub-section A
  - Sub-section B
- [Module 2]
  - ...
- Settings
  - Account
  - Organization
  - Integrations

### Navigation Principles

- Maximum 2 levels of nesting in primary nav
- Most frequent tasks reachable within 2 clicks
- Contextual navigation within workflows (breadcrumbs + step indicators)
- Global search always accessible
```

**Content Hierarchy:** Define which information is primary, secondary, and tertiary on each screen. Enterprise UIs fail when everything screams for attention equally.

**Output:** `docs/ux/information-architecture.md`

### 5. Wireframes and Prototypes

Create wireframes as interactive React artifacts using **shadcn/ui components + Tailwind CSS**. Static wireframes are fine for simple screens, but interactive prototypes are essential for complex workflows (multi-step forms, dashboards with filters, approval chains).

**Always use design preferences from the elicitation step** — apply the confirmed colour tokens, font, radius, and density. If preferences haven't been collected yet, run the Design Preferences Elicitation before building wireframes.

**Wireframe Principles for Enterprise Systems:**

- **Progressive disclosure** — Show only what's needed at each step. Hide advanced options behind expandable sections.
- **Consistent layout grid** — Use a 12-column grid. Main content in 8 columns, sidebar/context in 4.
- **Dense but not cluttered** — Enterprise users often need data density, but use whitespace strategically to create visual groupings.
- **Status visibility** — Always show system status: loading states, progress indicators, success/error feedback.
- **Forgiving interactions** — Undo instead of "Are you sure?" dialogs. Auto-save. Draft states.

**shadcn/ui Component Mapping for Enterprise Screens:**

| UI Pattern | shadcn Component |
|---|---|
| Page layout / sidebar | `<SidebarProvider>` + `<Sidebar>` + `<SidebarContent>` |
| Data table | `<Table>` + `<DataTable>` with `@tanstack/react-table` |
| Forms | `<Form>` + `<FormField>` + `<FormControl>` (react-hook-form) |
| Modal / dialog | `<Dialog>` + `<DialogContent>` |
| Slide-in panel | `<Sheet>` + `<SheetContent side="right">` |
| Notifications | `<Toast>` via `useToast()` hook |
| Dropdown menus | `<DropdownMenu>` + `<DropdownMenuContent>` |
| Tabs / sections | `<Tabs>` + `<TabsList>` + `<TabsContent>` |
| Status badges | `<Badge variant="outline\|secondary\|destructive">` |
| Loading skeleton | `<Skeleton className="h-4 w-[250px]">` |
| Command palette | `<Command>` + `<CommandInput>` + `<CommandList>` |
| Date picker | `<Calendar>` + `<Popover>` |
| Combobox / select | `<Combobox>` or `<Select>` + `<SelectContent>` |
| Alerts | `<Alert>` + `<AlertTitle>` + `<AlertDescription>` |
| Cards | `<Card>` + `<CardHeader>` + `<CardContent>` |
| Breadcrumbs | `<Breadcrumb>` + `<BreadcrumbList>` |
| Pagination | `<Pagination>` + `<PaginationContent>` |
| Progress | `<Progress value={percent}>` |
| Stepper / wizard | `<Steps>` (custom, compose from shadcn primitives) |

**React Wireframe Template:**

```tsx
// Always import from the user's confirmed design system
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Badge } from "@/components/ui/badge"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"

// Use cn() for conditional Tailwind classes
import { cn } from "@/lib/utils"

export function [ScreenName]() {
  return (
    <div className="flex h-screen bg-background">
      {/* Sidebar */}
      <aside className="w-64 border-r bg-card px-4 py-6">
        {/* nav items */}
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-y-auto p-6">
        <div className="mb-6 flex items-center justify-between">
          <h1 className="text-2xl font-semibold tracking-tight">[Page Title]</h1>
          <Button>[Primary Action]</Button>
        </div>

        {/* Content */}
        <Card>
          <CardHeader>
            <CardTitle>[Section Title]</CardTitle>
          </CardHeader>
          <CardContent>
            {/* Use realistic data, not Lorem ipsum */}
          </CardContent>
        </Card>
      </main>
    </div>
  )
}
```

**When using Pencil MCP** — build wireframes directly on the canvas using the connected component library. Each frame should map to a named screen in the UI Spec. Use `mcp__pencil__create_frame` for each screen and `mcp__pencil__create_component` for reusable shadcn-mapped components.

**Wireframe Annotation Format:**

```markdown
