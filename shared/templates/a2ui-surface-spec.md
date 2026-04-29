# A2UI Surface Spec — `<SurfaceName>`

> Owner: Solution Architect (authoring) · Reviewers: UX Designer, InfoSec Architect, Backend Engineer, Frontend/Mobile Engineer
> Parent doc: `docs/architecture/solution-architecture.md` — append under `## Agent-Driven Surfaces (A2UI)`
> A2UI spec version: **v0.10** (update explicitly when bumping)

## 1. Identity

- **surfaceId:** `<stable_snake_case_id>`
- **catalogId:** `<https://mycompany.com/<ver>/<catalog>>` (URL-shaped unique ID; does not need to resolve)
- **Catalog choice:** `basic` / `custom` / `hybrid` (with reason)
- **Theme params (if any):** `{ "primaryColor": "#...", ... }`
- **`sendDataModel`:** `true` / `false` (see InfoSec review below)

## 2. Purpose

One-paragraph statement of what the surface accomplishes and when the agent opens it.

## 3. Component tree sketch

Write an adjacency-list sketch — one line per component, indent children. Use catalog component types.

```
root (Column)
├── header (Row)
│   ├── header_icon (Icon: "mail")
│   └── header_text (Text: "Contact")
├── email_field (TextField, value=/contact/email)
└── submit (Button → action submitContact)
    └── submit_label (Text: "Send")
```

## 4. Data model

JSON Schema (or informal shape) for the surface's data model.

```json
{
  "contact": {
    "email": "string",
    "phone": "string?"
  }
}
```

Call out JSON-Pointer paths components bind to and which paths the server writes vs. the client writes.

## 5. Action contracts

For every interactive component that fires a server event:

| Action `name` | Source component | Context payload | `wantResponse` | Server handler |
|---|---|---|---|---|
| `submitContact` | `submit` | `{ email }` | `false` | `ContactService.submit()` |

## 6. Transport binding

- **Chosen transport:** A2A / AG-UI / MCP / SSE / WebSocket / REST (pick one)
- **Why:** (one-line rationale tied to project constraints)
- **Capabilities advertised:** list any non-default `a2uiServerCapabilities`.

## 7. Accessibility

- Every interactive component has `AccessibilityAttributes` set.
- Tab order and focus management noted where non-obvious.
- Colour contrast / font-size obligations inherited from the catalog.

## 8. InfoSec review

- PII in data model? Yes/No, list fields.
- `sendDataModel` justification (if `true`).
- Allow-listed `action.event.name` values.
- Rate-limit / abuse notes for action channel.

## 9. Test plan hooks

- Conformance: envelope order, one `root` per surface, all `child`/`children` IDs resolve, catalog compliance.
- Rendering: snapshot for initial state; update-on-`updateDataModel` snapshot.
- Actions: happy-path + `wantResponse` + error round-trip.

## 10. Open questions / risks

- …
