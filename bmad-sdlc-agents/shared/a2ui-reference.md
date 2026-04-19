# A2UI (Agent-to-UI) — BMAD Reference

> **Status:** A2UI v0.10 is **Draft / Public Preview** as of Dec 2025 (Google, Apache-2.0, [google/A2UI](https://github.com/google/A2UI)).
> Treat it as a stable-enough target for design artifacts and prototypes, but gate production adoption behind an Enterprise Architect ADR (see `shared/templates/adr-a2ui-adoption.md`).

This is the shared reference that all BMAD agents can rely on when a project involves agent-driven user interfaces. It is authoring-and-advisory context — it does **not** make any agent a live A2UI emitter.

---

## 1. What A2UI is in one paragraph

A2UI is a **declarative JSON protocol** for agent-driven UIs. An agent streams JSON envelopes; a client renderer builds the UI from a flat, ID-referenced component list and populates it from a separate data model. Because the wire format is data (not code), the client only ever renders components from an allow-listed **Catalog**, which gives A2UI a clean security posture and a natural fit with any existing design system. It is **transport-agnostic** — the same envelopes ride over A2A, AG-UI, MCP, SSE+JSON-RPC, WebSockets, or REST.

---

## 2. The five envelope messages

Every server-to-client message is a JSON object with exactly one of these keys:

| Envelope | Purpose |
|---|---|
| `createSurface` | Initialise a surface. Carries `surfaceId`, `catalogId`, optional `theme`, and optional `sendDataModel` flag. |
| `updateComponents` | Add or replace components in a surface. Components are a flat list; parent-child relationships are by ID. One component MUST have `id: "root"`. |
| `updateDataModel` | Push data at a JSON-Pointer `path` (default `/`). Components bind to these paths via `Dynamic*` types. |
| `deleteSurface` | Remove a surface and all its components/data. |
| `actionResponse` | Server's reply to a client `action` that set `wantResponse: true`. |

Client-to-server has one primary message: `action` (fired by interactive components like `Button`). Carries `name`, `surfaceId`, `sourceComponentId`, `context`, optional `wantResponse` and `actionId`.

**End-of-turn** is signalled by the transport, not the protocol.

---

## 3. The component model

- **Flat adjacency list.** Container components (`Row`, `Column`, `List`, `Card`, `Tabs`, `Modal`) reference children by `id`. The client builds the tree at render time and handles progressive / out-of-order arrival.
- **Catalog.** The set of allowed components for a surface. v0.10 ships a **basic catalog** of 18 components: `Text`, `Image`, `Icon`, `Video`, `AudioPlayer`, `Row`, `Column`, `List`, `Card`, `Tabs`, `Modal`, `Divider`, `Button`, `TextField`, `CheckBox`, `ChoicePicker`, `Slider`, `DateTimeInput`. Most production teams define a **custom catalog** that maps 1:1 to their design system.
- **Component object shape:** `{ id, component, ...properties }`. Properties on interactive components include an `action` (server event or local function) and `checks` (validation rules like `required`, `email`, `regex`).
- **`AccessibilityAttributes`** is a first-class field in `common_types.json` — A2UI components carry screen-reader hints natively.

---

## 4. Data binding — the `Dynamic*` primitives

Any bindable property is typed as one of `DynamicString` / `DynamicNumber` / `DynamicBoolean` / `DynamicStringList`. Each accepts:

1. A literal (`"Hello"`, `42`, `true`).
2. A `path` object pointing into the data model with JSON Pointer (`{"path": "/user/name"}`).
3. A `FunctionCall` invoking a client-registered function (e.g. `formatDate`).

The data model per surface is a plain JSON document; `updateDataModel` patches values at a path or replaces the whole tree when `path` is omitted.

---

## 5. Transports — pick one, don't tie the agent to it

A2UI is transport-agnostic. Common bindings, in order of current fit-for-purpose for BMAD projects:

| Transport | When it's the right pick |
|---|---|
| **A2A (Agent2Agent)** — **default recommendation** | Multi-agent systems, remote agents, agent-to-frontend over a secure channel. Maps envelopes onto A2A message Parts; data model + capabilities ride on A2A metadata; A2UI sessions = A2A `contextId`. |
| **AG-UI** — **strong alternative** | Rich frontend integrations (CopilotKit and similar), low-latency shared state between an agent backend and a web app. |
| **MCP** | If the UI is emitted as an MCP tool output or resource subscription from an MCP server the agent already talks to. |
| **SSE + JSON-RPC** | Browser clients with no framework, one-way streaming, synchronous RPC for actions. |
| **WebSockets** | Bidirectional real-time sessions where actions and updates interleave heavily. |
| **REST** | Simple / non-streaming cases; no progressive rendering. |

Transport contract (regardless of choice): ordered delivery, message framing, metadata support (for `sendDataModel` + capabilities exchange), and optionally a return channel for `action`.

---

## 6. Capabilities handshake

Clients advertise `a2uiClientCapabilities` (supported catalogs, custom components, etc.); servers advertise `a2uiServerCapabilities`. These exchange over transport metadata — Agent Cards in A2A, init in MCP. The agent must emit only components the client's catalog supports.

---

## 7. Security posture — what BMAD gets "for free"

- **No code execution on the client.** The wire format is declarative JSON; components are rendered by pre-compiled native widgets.
- **Catalog as allow-list.** Anything the catalog does not define cannot appear on screen, full stop.
- **Action names as capability.** Only `action.event.name` values the server knows about should be accepted; unknowns are dropped.
- **`sendDataModel` is a PII decision.** Enabling it means the full surface data model rides on every client→server message — treat it as a data-sharing surface in the threat model.

See `agents/infosec-architect/SKILL.md` §"A2UI Threat Surface" for the required review checklist.

---

## 8. Fit with BMAD roles

| Role | What they do with A2UI |
|---|---|
| **Product Owner** | Calls out agent-driven surfaces in PRD/epics; describes surface intent, user actions, driving data in business language. |
| **Enterprise Architect** | Adoption ADR, catalog-governance policy, transport standard, versioning policy, tech-radar entry. |
| **Solution Architect** | Per-feature surface spec: `surfaceId`, `catalogId`, component tree sketch, data-model schema, action contracts, transport binding. |
| **UX Designer** | Visual-to-component mapping, catalog extension/taxonomy, accessibility conformance of the catalog. |
| **InfoSec Architect** | Threat-model `action` payloads, custom-component allow-list policy, `sendDataModel` PII review. |
| **Backend Engineer** | Implements the emitter; maps domain events to envelopes; handles `action` events and `wantResponse` round-trips. |
| **Frontend / Mobile Engineer** | Implements the renderer against the agreed catalog; registers `FunctionCall` targets. |
| **Tester / QE** | Conformance tests for envelope ordering, catalog compliance, render integrity, action-response correctness. |
| **DevSecOps** | Transport deployment (SSE/WS/A2A endpoints), telemetry, rate-limits, audit of action events. |

---

## 9. Canonical minimal example (v0.10, JSONL)

```jsonl
{"version":"v0.10","createSurface":{"surfaceId":"contact_form","catalogId":"https://mycompany.com/1.0/catalog"}}
{"version":"v0.10","updateComponents":{"surfaceId":"contact_form","components":[
  {"id":"root","component":"Column","children":["email_field","submit"]},
  {"id":"email_field","component":"TextField","label":"Email","value":{"path":"/contact/email"},
   "checks":[{"call":"email","args":{"value":{"path":"/contact/email"}},"message":"Invalid email."}]},
  {"id":"submit","component":"Button","child":"submit_label",
   "action":{"event":{"name":"submitContact","context":{"email":{"path":"/contact/email"}}}}},
  {"id":"submit_label","component":"Text","text":"Send"}
]}}
{"version":"v0.10","updateDataModel":{"surfaceId":"contact_form","path":"/contact","value":{"email":""}}}
```

---

## 10. BMAD defaults

- **Transport default:** A2A primary, AG-UI secondary, others by exception.
- **Catalog default:** neutral — the Enterprise Architect's ADR picks `basic` / `custom` / `hybrid`. Favour `custom` once more than ~two surfaces exist.
- **Versioning default:** pin to one A2UI version per release (start at v0.10); upgrade as an ADR.
- **Maturity gate:** EA ADR required before committing to A2UI in a production system.

---

## 11. Authoritative sources

- Spec + schemas: [`google/A2UI`](https://github.com/google/A2UI) (Apache-2.0, maintained by Google).
- Protocol v0.10: `specification/v0_10/docs/a2ui_protocol.md` in the repo.
- Ecosystem comparison: [a2ui.org/introduction/agent-ui-ecosystem/](https://a2ui.org/introduction/agent-ui-ecosystem/).
- AG-UI: [docs.ag-ui.com](https://docs.ag-ui.com/introduction).
- A2A: [a2a-protocol.org](https://a2a-protocol.org/latest/).
- MCP: [modelcontextprotocol.io](https://modelcontextprotocol.io/docs/getting-started/intro).
