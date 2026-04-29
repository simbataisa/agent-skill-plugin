# ADR: Adopt A2UI for Agent-Driven UIs

> Owner: Enterprise Architect · Status: Proposed / Accepted / Rejected / Superseded
> Date: `<YYYY-MM-DD>` · Supersedes: `—`

## 1. Context

Describe the problem: we are building agent-driven experiences where an LLM needs to produce rich, interactive UI beyond plain text. Options considered included raw HTML, bespoke JSON over an app-defined schema, and standard protocols. A2UI ([google/A2UI](https://github.com/google/A2UI), Apache-2.0) is a declarative JSON protocol purpose-built for this.

- Current A2UI version: **v0.10** (Draft / Public Preview, Dec 2025).
- Maturity risk: spec is still evolving; catalog and extension mechanisms are stabilising.

## 2. Decision

- **Adopt A2UI:** yes / no
- **Version pinned to:** `v0.10`
- **Catalog strategy:** `basic` (bootstrap only) / `custom` (own design system) / `hybrid` (basic + extensions). Chosen: `<…>`.
- **Transport default:** A2A primary, AG-UI secondary. Per-system deviations require an addendum ADR.
- **Renderer platforms in scope:** web / mobile-iOS / mobile-Android / desktop.
- **Compliance:** this ADR applies to all new agent-driven surfaces starting `<date>`. Existing bespoke JSON UIs are grandfathered and migrated opportunistically.

## 3. Consequences

**Positive**
- Clean security posture (declarative, allow-listed catalog, no code execution client-side).
- Natural fit with A2A-based multi-agent systems.
- Agents can reuse a single authoring mental model across products.

**Negative**
- Spec is pre-1.0; breaking changes are possible across minor versions.
- Teams must maintain their catalog alongside the design system.
- Tooling ecosystem (validators, observability) is young.

## 4. Governance

- **Catalog ownership:** `<team / person>` — central registry at `<repo path or URL>`.
- **Versioning policy:** one A2UI spec version per release train; upgrades via ADR addendum.
- **Custom-component policy:** a new custom component requires UX + InfoSec sign-off; no string-typed child references (enforce `ComponentId` / `ChildList` refs so validators check the tree).
- **Action-name policy:** server-side `action.event.name` values are explicitly registered; unknown names are dropped.
- **Observability:** every `action` event is logged with `actionId`, `surfaceId`, `sourceComponentId`.

## 5. Alternatives considered

- **Raw HTML/React streamed by the agent.** Rejected: executes arbitrary code, hard to sandbox, no catalog discipline.
- **Bespoke internal JSON schema.** Rejected: duplicates A2UI's design, no ecosystem.
- **AG-UI without A2UI.** Considered: usable as a transport but does not solve the declarative-component problem A2UI addresses.

## 6. Review triggers

- A2UI v1.0 release.
- More than 5 surfaces shipped → revisit catalog strategy.
- Security incident involving an `action` payload.
- Introduction of a new renderer platform.
