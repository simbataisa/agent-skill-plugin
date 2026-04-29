# Architecture & Agent Intelligence

The BMAD two-layer architecture, agent intelligence layers (mode detection, autonomous task routing, parallel waves, sentinel-based orchestration), and the on-disk file organization that ties it all together.

## Table of Contents

- [Two-Layer Architecture](#two-layer-architecture)
- [Agent Intelligence](#agent-intelligence)
- [File Organization](#file-organization)

---

## Two-Layer Architecture

### Global Layer

**Install once.** Available in all projects.

- **`agents/`** – 13 specialized agent skills, each in its own folder
  - `<agent-name>/SKILL.md` – Core skill body (≤500 lines; loads on invocation). Opens with an `## Engineering Discipline` section that restates the Karpathy principles before any project-context loading.
  - `<agent-name>/brainstorm.md` – 5-phase clarification command (`/<agent>:brainstorm`) with the same principles as preamble.
  - `<agent-name>/references/` – Deep-dive guides, patterns, and worked examples (loaded on demand)
  - `<agent-name>/templates/` – Output templates for deliverables (loaded on demand)
  - `<agent-name>/sub-agents/` – Specialist helpers invoked via the Agent tool
- **`shared/`** – Company-wide context, references, and templates
  - `BMAD-SHARED-CONTEXT.md` – Organization context, principles, standards
  - `karpathy-principles/` – 10 tool-tailored rulebooks + index (`README.md`). Installed per tool by `install-global.sh`.
  - `a2ui-reference.md` – Protocol reference for agent-driven UIs (A2UI v0.10). Installed per tool by `install-global.sh`.
  - `references/technology-radar.md` – Technology choices, maturity tiers
  - `templates/` – ADR, story, test strategy, handoff log templates + `adr-a2ui-adoption.md` and `a2ui-surface-spec.md` (agent-specific BRD/PRD/requirements templates live in `agents/<agent>/templates/`)
- **`hooks/`** – Session-hook settings + scripts for Claude Code / Kiro, plus the Yolo autonomous harness
- **`rules/`** – Per-tool rules fragments (Cursor / Windsurf / Trae / Copilot / Gemini / OpenCode / Aider) generated from agent content

### Project Layer

**Copy per project.** Checked into each project's git repo.

- **`.bmad/`** – Project-specific context files
  - `PROJECT-CONTEXT.md` – Project vision, goals, stakeholders, timeline
  - `tech-stack.md` – Technologies, versions, dependencies, build setup
  - `team-conventions.md` – Code style, naming, patterns, architecture rules
  - `domain-glossary.md` – Business domain terms, concepts, entities
  - `handoff-log.md` – Record of handoffs between agents/humans
  - `ux-design-master.md` – Design tool choice (ASCII/Pencil/Figma), master file reference, page index (created by UX Designer on first run)
  - `signals/` – Sentinel files for inter-agent coordination

- **`docs/`** – Project documentation
  - `architecture/` – System design, decision records, diagrams
  - `stories/` – User stories, epics, acceptance criteria
  - `testing/` – Test plans, test cases, coverage goals
  - `ux/` – Personas, journeys, wireframes, design specs

### Agent Context Loading Order

When an agent runs, it loads context in this order (later overrides earlier):

1. `shared/BMAD-SHARED-CONTEXT.md` (baseline)
2. `.bmad/PROJECT-CONTEXT.md` (project goals, stakeholders)
3. `.bmad/tech-stack.md` (technology choices)
4. `.bmad/team-conventions.md` (project rules and standards)
5. `.bmad/ux-design-master.md` (design tool + master file reference, if exists)
6. User prompt (immediate task)

This creates project-aware agents that respect global conventions while adapting to project specifics.

### 📂 Progressive Disclosure (Three-Level Loading)

Each agent skill uses a three-level loading strategy to keep context windows lean:

| Level                   | What                                                      | When loaded                                                                   |
| ----------------------- | --------------------------------------------------------- | ----------------------------------------------------------------------------- |
| **1 — Metadata**        | YAML frontmatter (`name`, `description`, `allowed-tools`) | Always — used by the tool for skill discovery                                 |
| **2 — Skill body**      | `SKILL.md` (≤500 lines)                                   | On invocation — quick mode detection, responsibilities, completion protocol   |
| **3 — Reference files** | `references/*.md` and `templates/*.md`                    | On demand — agent reads the relevant file only when working on that task area |

This means a Tech Lead doing code review loads `templates/code-review-checklist.md` without also loading the risk assessment or debt registry templates. Agents are instructed to `Read` the appropriate reference file before starting each deliverable.

---

## Agent Intelligence

Each agent skill embeds three layers of autonomous intelligence that eliminate manual overhead and keep sessions focused.

### ⚡ Quick Mode Detection

Before loading any project context, every agent runs a 2-second binary check to determine its operating mode:

| Signal File                                    | Mode                                                    |
| ---------------------------------------------- | ------------------------------------------------------- |
| `docs/architecture/sprint-N-kickoff.md` exists | 🔨 **Execute Mode** — sprint implementation in progress |
| `docs/testing/bugs/*-fix-plan.md` exists       | 🔨 **Execute Mode** — bug fix in progress               |
| `docs/testing/hotfixes/*.md` exists            | 🔨 **Execute Mode** — hotfix in progress                |
| None of the above                              | 📋 **Plan Mode** — creating or refining artifacts       |

**Why it matters:** Execute Mode agents skip `docs/prd.md` and the full planning artifact tree — loading only 2–3 targeted files (tech-stack, conventions, kickoff doc). This prevents context overload and dramatically speeds up sprint execution.

### 🔍 Autonomous Task Detection

After loading project context, each agent scans `.bmad/handoffs/` and `docs/` to determine its current task without explicit instructions. Each agent follows a priority table covering all work types it can handle — for example:

- **Tech Lead** checks for hotfix docs → bug fix plans → sprint kickoffs → sprint plans → PRD, in that priority order, always handling the most urgent work type first
- **Backend / Frontend / Mobile Engineers** scan for fix plans → sprint kickoffs → feature plans, selecting whichever is active
- **Tester-QE** distinguishes "diagnose bug" (no fix-plan yet) from "verify fix" (fix-plan exists and fix applied)

Each agent announces what it detected and what it will do — or reports `Blocked: [what's missing]` if prerequisites haven't been met, and names which agent to invoke first.

### 🚀 Implementation Kickoff Suggestions

Every agent's Completion Protocol includes a `🚀` line in the review summary pointing to the next agent in the chain:

| Agent                 | 🚀 Suggests                                                                                 |
| --------------------- | ------------------------------------------------------------------------------------------- |
| Product Owner         | `/business-analyst` — deep requirements analysis of your BRD + PRD                          |
| Business Analyst      | `/enterprise-architect` ∥ `/ux-designer` in parallel — both read your requirements analysis |
| Enterprise Architect  | `/solution-architect` (after UX is also done)                                               |
| UX Designer           | `/solution-architect` (after EA is also done)                                               |
| Solution Architect    | `/tech-lead` — sprint plan from your solution architecture                                  |
| Tech Lead (Plan Mode) | Execute Prompt B (squad) or individual engineer commands                                    |
| Backend Engineer      | `/frontend-engineer` then `/tester-qe`                                                      |
| Frontend Engineer     | `/mobile-engineer` (if in scope) or `/tester-qe`                                             |
| Mobile Engineer       | `/tester-qe` — full sprint testing                                                          |
| Tester-QE (all pass)  | `/tech-lead` — release sign-off or next sprint kickoff                                      |
| Tester-QE (failures)  | Return to the failing engineer for fixes                                                    |

You never need to remember the agent sequence — each agent hands you off to the next one.

### 🎯 EA vs. SA — Which Architect Owns This Decision?

EA and SA both do architecture, but at different layers and scopes. The rule of thumb: **EA sets the guardrails; SA designs within them.** If a decision applies across systems, teams, or release trains, it's EA. If it affects only one solution, one service, or one API, it's SA.

**Two-axis heuristic:**

- **Scope axis** — EA = cross-system / enterprise-wide. SA = within one solution / system.
- **Layer axis** — EA = infrastructure, platform, governance, operations. SA = application, components, contracts, code-adjacent.

**Decision matrix (pick the right agent by topic):**

| Topic                                                            | EA  | SA  | InfoSec  | DevSecOps |
| ---------------------------------------------------------------- | :-: | :-: | :------: | :-------: |
| Cloud provider / region strategy                                 | ✅  |     |          |           |
| Multi-environment topology (dev / staging / prod / DR parity)    | ✅  |     |          |           |
| Compute platform (K8s distro vs. serverless vs. hybrid)          | ✅  |     |          |           |
| Disaster recovery strategy / RTO / RPO                           | ✅  |     |          |           |
| Compliance posture (SOC2 / GDPR / HIPAA / PCI)                   | ✅  |     | ✅ coord |           |
| Enterprise observability stack choice                            | ✅  |     |          |           |
| CI/CD pipeline template (org-wide)                               | ✅  |     |          |  ✅ impl  |
| FinOps tagging + budget envelope                                 | ✅  |     |          |           |
| Shared platform services (identity, API gateway, mesh, bus)      | ✅  |     |          |           |
| Cross-system integration contract ("Order → SAP")                | ✅  |     |          |           |
| Technology radar governance (Adopt / Trial / Assess / Hold)      | ✅  |     |          |           |
| A2UI adoption, version pin, catalog governance                   | ✅  |     |          |           |
| Service decomposition within a solution                          |     | ✅  |          |           |
| API contracts (OpenAPI / AsyncAPI) for a solution                |     | ✅  |          |           |
| Data model / schema / indexes for a service                      |     | ✅  |          |           |
| Database choice (per service, from EA-approved catalog)          |     | ✅  |          |           |
| Application framework (NestJS / FastAPI / Spring Boot)           |     | ✅  |          |           |
| Solution-level integration patterns (saga / CQRS / outbox)       |     | ✅  |          |           |
| Per-service auth flow (OAuth/OIDC) within EA's identity platform |     | ✅  | ✅ coord |           |
| Solution-level ADRs                                              |     | ✅  |          |           |
| C4 Component / Code-level diagrams                               |     | ✅  |          |           |
| A2UI per-surface spec (surfaceId, tree, action contracts)        |     | ✅  |          |           |
| Threat models, controls catalogue, encryption choices            |     |     |    ✅    |           |
| Secret-rotation cadence, threat-modeling methodology             |     |     |    ✅    |           |
| Terraform / Helm / GitHub Actions YAML                           |     |     |          |    ✅     |
| Provisioning runbooks, log-shipper wiring                        |     |     |          |    ✅     |

**Quick triage — start here when unsure:**

| If the decision...                                                         | Invoke                                          |
| -------------------------------------------------------------------------- | ----------------------------------------------- |
| Applies to the whole estate or multiple solutions                          | **Enterprise Architect**                        |
| Sets a standard others must follow (pipeline, stack, platform, compliance) | **Enterprise Architect**                        |
| Lives inside one solution and its services                                 | **Solution Architect**                          |
| Is an API, data model, or service-boundary choice                          | **Solution Architect**                          |
| Introduces a new technology to the organisation                            | **EA first** (radar update) → then SA adopts it |
| Is about _how to defend_ a system (threats, controls, crypto)              | **InfoSec Architect**                           |
| Is about _how to operate_ a system (IaC, pipelines, runbooks)              | **DevSecOps Engineer**                          |

**Invocation order for a new project:**
`PO → BA → EA ∥ UX (parallel) → SA → Tech Lead → engineers → Tester-QE`

EA runs **before** SA because SA's component-level choices depend on EA's platform and governance decisions. If you invoke SA before EA exists, SA will block with "Requires enterprise-architecture.md" in its Autonomous Task Detection.

Full scope-boundary tables with overlap-zone coordination rules live inline in each agent's `SKILL.md` under the **🚧 Scope Boundary** section.

### 📏 Agent Rules (Inline Guardrails)

Every agent embeds a `## Agent Rules` section with non-negotiable guardrails across four categories:

| Category                     | What It Covers                                                                     | Example                                                                                |
| ---------------------------- | ---------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------- |
| **Security & Compliance**    | Data handling, secrets management, PII protection, auth patterns, audit trails     | BE: "Parameterized queries only — zero tolerance for SQL injection"                    |
| **Code Quality & Standards** | Testing requirements, documentation, naming, error handling, coverage              | TQE: "Every test must reference the story ID and acceptance criterion it validates"    |
| **Workflow & Process**       | Approval gates, scope control, deviation protocols, rollback procedures            | TL: "ADR lock is irreversible per sprint — scope changes require a new ADR"            |
| **Architecture Governance**  | ADR enforcement, tech radar compliance, API contract alignment, service boundaries | SA: "All technologies must be on the technology radar — unlisted tech requires an ADR" |

Rules are role-specific — engineers get secure coding rules, architects get governance rules, testers get coverage rules, etc. Every agent verifies its outputs against its rules before completing the Completion Protocol.

### ⚡ Parallel Execution Waves

Agents are organized into **waves** — all agents in the same wave run simultaneously with no inter-dependencies. The orchestrator (human, squad prompt, or parent agent) spawns a wave, waits for all agents to complete, then spawns the next wave.

**New Project — Plan Phase:**

| Wave | Agents                                              | Depends On                                            |
| ---- | --------------------------------------------------- | ----------------------------------------------------- |
| W1   | Product Owner                                       | —                                                     |
| W2   | Business Analyst                                    | PO → `docs/brd.md` + `docs/prd.md`                    |
| W3   | Enterprise Architect ∥ UX Designer                  | BA → `docs/analysis/requirements-analysis.md`         |
| W4   | Solution Architect                                  | EA → `enterprise-architecture.md` AND UX → `docs/ux/` |
| W5   | Tech Lead                                           | SA → `solution-architecture.md`                       |
| W6   | Backend Eng ∥ Frontend Eng ∥ Mobile Eng (spec only) | TL → `sprint-plan.md`                                 |
| W7   | Tester & QE (strategy only)                         | All three specs from W6                               |

**Sprint Execution:**

| Wave | Agents                                  | Depends On                               |
| ---- | --------------------------------------- | ---------------------------------------- |
| E1   | Tech Lead (kickoff)                     | Plan approval or previous sprint results |
| E2   | Backend Eng ∥ Frontend Eng ∥ Mobile Eng | TL → `sprint-N-kickoff.md`               |
| E3   | Tester & QE                             | All three engineers from E2              |

**Feature — Plan Phase:**

| Wave | Agents                             | Depends On                                    |
| ---- | ---------------------------------- | --------------------------------------------- |
| W1   | Product Owner                      | —                                             |
| W2   | Business Analyst (impact analysis) | PO → `docs/features/[feature-name]-brief.md`  |
| W3   | Enterprise Architect ∥ UX Designer | BA → `docs/analysis/[feature-name]-impact.md` |
| W4   | Solution Architect                 | EA + UX (both must complete)                  |
| W5   | Tech Lead                          | SA → updated `solution-architecture.md`       |
| W6   | Tester & QE                        | TL → `[feature]-plan.md`                      |

**How to spawn parallel waves:** In Claude Code, use the `Agent` tool to launch multiple sub-agents in a single message. In Cursor/Windsurf/Trae, open parallel composer/Builder windows. The key rule: **never start the next wave until ALL agents in the current wave have printed their ✅ summary.** Each agent knows its topology — if it finishes before a parallel peer, it reports completion and notes which peer to wait for.

### 🤖 Autonomous Orchestration (Claude Code)

In Claude Code, Tech Lead can fully orchestrate the sprint execution pipeline without any manual intervention.

> **TQE fast-path:** When TQE detects `.bmad/signals/E3-tqe-invoke`, it skips its E2 completion check (Step 0 in its Autonomous Task Detection) and proceeds directly to testing — no re-verification of engineer outputs needed.

> **Other AI tools.** Kiro, Codex CLI, Cursor, Windsurf, and Trae IDE do not support sub-agent spawning. In those environments the wave structure is **human-orchestrated** — the `🚀` suggestion lines in each agent's Completion Protocol guide you to spawn the next wave manually. The sentinel files still work the same way; you just write them yourself (or check for them) rather than having TL do it automatically.

> **⚠️ Critical prerequisite:** The Agent tool can only be used from the **main thread**. Sub-agents cannot spawn further sub-agents. You must start the session with `claude --agent tech-lead` so Tech Lead IS the main thread.

**Two modes are available:**

#### Path A — Subagent Mode (Stable, recommended)

Launch with: `claude --agent tech-lead`

| Step                      | What Happens                                                                                                                   |
| ------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| A — Spawn engineers       | TL uses Agent tool to launch BE ∥ FE ∥ ME in parallel, all reading `sprint-N-kickoff.md`                                       |
| B — Monitor ready signals | TL polls `.bmad/signals/` for `E2-[role]-ready` files written by engineers                                                     |
| C — Worktree code review  | For each ready signal: `git worktree add` → run TL Code Review Checklist → `git worktree remove` → write done or rework signal |
| D — Converge              | When all three `E2-[role]-done` signals exist → TL invokes TQE via Agent tool                                                  |

#### Path B — Agent Teams Mode (Experimental)

Launch with: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1 claude --agent tech-lead`

Requires Claude Code v2.1.32+. Enables peer-to-peer messaging between BE/FE/ME for interface coordination. The sentinel file protocol is identical to Path A.

#### Sentinel File Protocol

All inter-agent coordination uses files in `.bmad/signals/`. No direct agent-to-agent messaging is required.

**Planning phase sentinels (written by each agent, triggers the next):**

| File                         | Written By           | Meaning                                                                      |
| ---------------------------- | -------------------- | ---------------------------------------------------------------------------- |
| `.bmad/signals/po-done`      | Product Owner        | BRD + PRD complete; BA can proceed                                           |
| `.bmad/signals/ba-done`      | Business Analyst     | Requirements analysis complete; EA + UX can proceed in parallel              |
| `.bmad/signals/ea-done`      | Enterprise Architect | Enterprise architecture complete (converges with `ux-done` before SA starts) |
| `.bmad/signals/ux-done`      | UX Designer          | UX specs complete (converges with `ea-done` before SA starts)                |
| `.bmad/signals/sa-done`      | Solution Architect   | Detailed solution architecture complete; TL can proceed                      |
| `.bmad/signals/tl-plan-done` | Tech Lead            | Sprint kickoff complete; engineers can proceed                               |

**Execution phase sentinels (two-phase TL verification protocol):**

| File                         | Written By         | Meaning                                                                 |
| ---------------------------- | ------------------ | ----------------------------------------------------------------------- |
| `.bmad/signals/E2-be-ready`  | Backend Engineer   | Implementation complete, awaiting TL code review. Content = branch name |
| `.bmad/signals/E2-fe-ready`  | Frontend Engineer  | Implementation complete, awaiting TL code review. Content = branch name |
| `.bmad/signals/E2-me-ready`  | Mobile Engineer    | Implementation complete, awaiting TL code review. Content = branch name |
| `.bmad/signals/E2-be-done`   | **Tech Lead only** | TL has reviewed BE branch via worktree and approved                     |
| `.bmad/signals/E2-fe-done`   | **Tech Lead only** | TL has reviewed FE branch via worktree and approved                     |
| `.bmad/signals/E2-me-done`   | **Tech Lead only** | TL has reviewed ME branch via worktree and approved                     |
| `.bmad/signals/E2-be-rework` | **Tech Lead only** | BE review failed; content = path to review notes in `docs/reviews/`     |
| `.bmad/signals/E2-fe-rework` | **Tech Lead only** | FE review failed; content = path to review notes in `docs/reviews/`     |
| `.bmad/signals/E2-me-rework` | **Tech Lead only** | ME review failed; content = path to review notes in `docs/reviews/`     |

> **Engineers never write `E2-*-done`.** The done signal is the Tech Lead's approval stamp — it is only created after a real code review via git worktree. Claiming completion without verification is dishonesty, not efficiency.

**Autonomous mode sentinel:**

| File                            | Written By                             | Meaning                                                                            |
| ------------------------------- | -------------------------------------- | ---------------------------------------------------------------------------------- |
| `.bmad/signals/autonomous-mode` | `scripts/yolo.sh` / `scripts/yolo.ps1` | All planning agents skip the human-review wait step and auto-invoke the next agent |

Enable with: `bash scripts/yolo.sh on` (Linux/macOS) or `.\scripts\yolo.ps1 on` (Windows)

### 🛠️ Tool Capability Matrix

Agent behaviour is not identical across AI coding tools — and the gap has narrowed considerably as each tool has shipped multi-agent, hooks, and rules support over the last year. This matrix is a pragmatic cross-section as of the latest release; rate cells conservatively and verify against your tool's current docs before committing a workflow.

Legend: ✅ first-class · 🟡 works but with caveats · ❌ not currently supported.

| Capability                                                                        | Claude Code                            | Cowork                             | Cursor                                        | Windsurf                                       | Trae IDE                                         | GitHub Copilot                                         | Codex CLI                         | Gemini CLI                                                            | Kiro                                      | OpenCode                                 | Aider                                    |
| --------------------------------------------------------------------------------- | -------------------------------------- | ---------------------------------- | --------------------------------------------- | ---------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------ | --------------------------------- | --------------------------------------------------------------------- | ----------------------------------------- | ---------------------------------------- | ---------------------------------------- |
| **Init file / rules entry**                                                       | `CLAUDE.md`                            | `~/.skills/` + `.bmad/`            | `.cursor/rules/*.mdc`                         | `.windsurf/rules/*.md` (+ `.windsurfrules`)    | `.trae/rules/*.md` (+ `user_rules.md`)           | `.github/copilot-instructions.md`                      | `AGENTS.md`                       | `GEMINI.md`                                                           | `AGENTS.md` + `.kiro/steering/`           | `AGENTS.md`                              | `.aider.conventions.md`                  |
| **Agent/skill container**                                                         | `~/.claude/skills/` (folder-per-skill) | `~/.skills/skills/`                | Rules only                                    | Rules only                                     | `~/.trae/rules/` (+ `~/.trae/skills/` refs)      | Rules only                                             | `~/.codex/skills/`                | `~/.gemini/skills/` (skills) + `~/.gemini/agents/` (native subagents) | `~/.kiro/skills/`                         | `~/.opencode/instructions.md`            | conventions file                         |
| **Typical model(s)**                                                              | Claude Opus / Sonnet / Haiku           | Claude Opus / Sonnet               | User-selected (Claude, GPT, Gemini, …)        | User-selected                                  | User-selected (Claude, GPT, Gemini, DeepSeek, …) | GPT-family + Claude option                             | GPT-5 / o-series                  | Gemini 2.5 Pro / Flash                                                | Claude via Bedrock                        | User-selected                            | User-selected (architect + editor split) |
| **Subagent spawning**                                                             | ✅ Agent tool                          | ✅ Agent tool                      | 🟡 Background agents / Tasks                  | 🟡 Cascade sub-flows                           | ❌ (single-session; routing-advisor model)       | 🟡 Coding Agent (PR-scale)                             | 🟡 via Responses API              | ✅ Native subagents (markdown-defined) with isolated context          | ✅ Agent tool                             | 🟡 runner-level                          | ❌ (single-session)                      |
| **Parallel E2 engineers** (BE ∥ FE ∥ ME)                                          | ✅ True parallel                       | ✅ True parallel                   | 🟡 Multiple background agents                 | 🟡 Parallel Cascade sessions                   | 🟡 Multiple Trae windows                         | 🟡 Multiple Coding Agent PRs                           | 🟡 limited parallelism            | 🟡 Sequential subagent calls (isolated context, not parallel)         | ✅ True parallel                          | 🟡 manual                                | ❌ Sequential                            |
| **Session hooks** (Pre/Post/Stop)                                                 | ✅ Full                                | ✅ Full                            | ❌                                            | ❌                                             | ❌                                               | ❌                                                     | 🟡 (some CLI hooks)               | 🟡 (extension hooks)                                                  | ✅ Full                                   | 🟡 limited                               | ❌                                       |
| **Slash / invocation syntax**                                                     | `/agent-name`                          | `/skill-name`                      | `@agent` rules + Composer                     | `@agent` mentions in Cascade                   | `@agent` rules + Builder                         | `@workspace` / Agent Mode                              | `/agent-name`                     | `@<subagent-name>` + `/agents` manager                                | `@agent-name`                             | `@agent-name`                            | `/ask`, `/architect`, `/run`             |
| **Yolo / autonomous harness**                                                     | ✅ Full                                | ✅ Scheduled tasks + auto-run      | 🟡 Background agents                          | 🟡 Cascade autopilot                           | 🟡 Builder autopilot                             | 🟡 Coding Agent (GitHub-hosted)                        | 🟡 --dangerously-auto             | 🟡 --yolo flag                                                        | ✅ Full                                   | 🟡                                       | 🟡 --auto-commit                         |
| **Sentinel-file protocol**                                                        | ✅ Reliable                            | ✅ Reliable                        | 🟡 Works; requires explicit rule              | 🟡 Works; requires explicit rule               | 🟡 Works; requires explicit rule                 | 🟡 Inconsistent outside Agent Mode                     | 🟡 Usually reliable post GPT-5    | 🟡 Improved on 2.5-Pro                                                | ✅ Reliable                               | 🟡                                       | 🟡                                       |
| **Protocol-step compliance**                                                      | ✅ High                                | ✅ High                            | 🟡 Good inside Composer                       | 🟡 Good inside Cascade                         | 🟡 Good inside Builder                           | 🟡 Good in Agent Mode                                  | 🟡 Medium–High (GPT-5)            | 🟡 High inside subagent context; medium in main session               | ✅ High                                   | 🟡 Medium                                | 🟡 Medium                                |
| **MCP client support**                                                            | ✅                                     | ✅                                 | ✅                                            | ✅                                             | ✅ (`~/.trae/mcp.json`)                          | ✅ (Agent Mode)                                        | ✅                                | ✅                                                                    | ✅                                        | ✅                                       | 🟡 via plugins                           |
| **Git worktree TL review**                                                        | ✅                                     | ✅                                 | ✅                                            | ✅                                             | ✅                                               | ✅                                                     | ✅                                | ✅                                                                    | ✅                                        | ✅                                       | ✅                                       |
| **Karpathy-principles auto-install path**                                         | `~/.claude/KARPATHY-PRINCIPLES.md`     | `~/.skills/KARPATHY-PRINCIPLES.md` | `~/.cursor/rules/001-karpathy-principles.mdc` | `~/.windsurf/rules/001-karpathy-principles.md` | `~/.trae/rules/001-karpathy-principles.md`       | `~/.github/copilot-instructions.md` (appended)         | `~/.codex/KARPATHY-PRINCIPLES.md` | `~/.gemini/KARPATHY-PRINCIPLES.md`                                    | `~/.kiro/steering/karpathy-principles.md` | `~/.opencode/instructions.md` (appended) | `~/.aider.conventions.md` (appended)     |
| **Agent-driven UI authoring (A2UI)** — reference deployed for PO/EA/SA/UX/InfoSec | `~/.claude/A2UI-REFERENCE.md`          | `~/.skills/A2UI-REFERENCE.md`      | `~/.cursor/rules/002-a2ui-reference.md`       | `~/.windsurf/rules/002-a2ui-reference.md`      | `~/.trae/rules/002-a2ui-reference.md`            | — (reference in-repo under `shared/a2ui-reference.md`) | `~/.codex/A2UI-REFERENCE.md`      | `~/.gemini/A2UI-REFERENCE.md`                                         | `~/.kiro/steering/a2ui-reference.md`      | `~/.opencode/A2UI-REFERENCE.md`          | `~/.aider/A2UI-REFERENCE.md`             |

**Practical impact by tool:**

- **Claude Code** — Reference implementation. Full BMAD pipeline: autonomous sentinel chaining, parallel engineers (BE ∥ FE ∥ ME), hooks, Yolo harness, plugins. Use this as the benchmark the other tools are measured against.
- **Cowork (Claude Desktop)** — The desktop/agentic surface with skills, scheduled tasks, and MCP. Strong for document-producing roles (PO/BA/UX/EA) and for long-running orchestration of the squad. Shares Claude Code's compliance profile.
- **Cursor** — Composer / Agent Mode + background agents cover multi-file changes and long-running work; rules system (`.cursor/rules/*.mdc`) is the right home for persistent BMAD guidance. No Claude-Code-style hooks, so harness features don't apply.
- **Windsurf** — Cascade is the agentic equivalent of Composer; planning mode works well for brainstorm.md prompts. Rules files at `.windsurf/rules/` are first-class. Use its autopilot rather than the Yolo harness.
- **Trae IDE (ByteDance)** — Rules-based paradigm similar to Cursor/Windsurf. `install-global.sh` deploys the 13 role bodies to `~/.trae/rules/<role>.md` (always-on guidelines), mirrors the framework seed to `~/.trae/rules/user_rules.md` for Trae versions that only auto-load that single file, and drops the per-command rules under `~/.trae/rules/bmad-commands/<agent>/<cmd>.md`. Reference files (templates/, references/) are copied to `~/.trae/skills/<role>/` so you can `Read` them from inside a session. Single-session like Windsurf — no native subagent spawning; use parallel Trae windows for Wave E2. MCP servers are configured at `~/.trae/mcp.json` (Settings → MCP & Agents).
- **GitHub Copilot** — Agent Mode (in IDE) is well-suited to individual agent roles; the asynchronous Coding Agent can run long-form work against a branch/PR. Uses `.github/copilot-instructions.md` and `.github/instructions/*.instructions.md`. Hooks/harness don't apply.
- **Codex CLI** — GPT-5 / o-series era. Protocol compliance is much better than on GPT-4o, but sentinel chaining and multi-branch logic still drift occasionally — verify explicitly. Parallelism is improving via the Responses API but is not yet at Claude-Code parity. Each agent's Completion Protocol keeps a `### 🔧 On Codex CLI / Gemini CLI` fallback for safety.
- **Gemini CLI** — Gemini 2.5 / 3 era. Now ships **native subagents** (markdown files at `.gemini/agents/*.md` or `~/.gemini/agents/*.md`) with isolated context windows, per-subagent tool allow-lists, and `@<name>` invocation. `install-global.sh` deploys all 13 BMAD roles as subagents alongside the existing skills/extensions, so you can write `@backend-engineer implement BE-001` and the main agent delegates with token-efficient context isolation. Subagents cannot call other subagents (recursion-protected), so the BMAD orchestrator role acts as a routing advisor and the main agent is responsible for chained delegation. Manage interactively with `/agents` inside the CLI. Sequential — not yet parallel — but a major step up from the old "no subagents" baseline.
- **Kiro (AWS)** — Spec-driven workflow with Skills, Steering, and Hooks — effectively a peer of Claude Code for BMAD. Only difference is `@agent-name` vs `/agent-name` invocation syntax.
- **OpenCode** — Open standards (`AGENTS.md`, MCP) make install straightforward; exact capability depends on the model/runner you pair it with.
- **Aider** — Architect+editor split is a natural fit for Karpathy-style "think before coding": use a strong model in `/architect` to produce the plan, a cheap model to apply edits. No subagents — drive the squad manually turn-by-turn.

> **Recommendation:** if you want the fully autonomous BMAD pipeline (sentinels, parallel engineers, hooks, Yolo), pick **Claude Code**, **Kiro**, or **Cowork**. For IDE-integrated workflows with agentic modes, pick **Cursor**, **Windsurf**, **Trae IDE**, or **GitHub Copilot**. For CLI-first teams, **Codex CLI** or **Gemini CLI** are solid — just budget for the occasional sentinel-verification step. **Aider** is excellent for disciplined single-threaded work where you want tight human control.

---

## File Organization

```
bmad-sdlc-agents/
├── agents/                                 # Global: 13 agent skills (ordered by BMAD flow)
│   ├── bmad/                               # Orchestrator — routes work to the right sub-agent
│   │   └── SKILL.md
│   ├── product-owner/                      # W1 — BRD, PRD, epics, MVP scope
│   │   ├── SKILL.md                        # Core skill body (≤500 lines)
│   │   ├── brainstorm.md                   # /<agent>:brainstorm — 5-phase clarification flow
│   │   ├── implement-story.md              # (engineers) or role-specific command files
│   │   ├── references/                     # prioritisation-frameworks, quality-gate, scenarios
│   │   ├── templates/                      # brd, prd, epic, rice, handoff-memo, …
│   │   └── sub-agents/                     # Specialist helpers invoked via Agent tool
│   ├── business-analyst/                   # W2 — requirements, user stories, use cases
│   ├── enterprise-architect/               # W3 ∥ — cloud infra, compliance, CI/CD
│   ├── ux-designer/                        # W3 ∥ — wireframes (ASCII/Pencil/Figma), a11y
│   ├── solution-architect/                 # W4 — detailed solution design within EA boundaries
│   ├── infosec-architect/                  # W4 ∥ — threat modelling, controls, privacy, SBOM
│   ├── devsecops-engineer/                 # W4 ∥ — pipelines, IaC, SLOs, FinOps, reliability
│   ├── tech-lead/                          # W5 — sprint planning, code review, orchestration
│   ├── backend-engineer/                   # E2 ∥ — services, APIs, data, auth, events
│   ├── frontend-engineer/                  # E2 ∥ — web UI, perf budgets, flags, i18n
│   ├── mobile-engineer/                    # E2 ∥ — iOS/Android, offline, app-size, crash tools
│   └── tester-qe/                          # E3 — test plan, quality gates, shift-left
│
│   # Every agent folder carries the same internal layout:
│   #   SKILL.md (entry point, now opens with an "Engineering Discipline" /
│   #     Karpathy-principles section before Project Context Loading),
│   #   brainstorm.md (5-phase clarification command; preamble enforces the
│   #     same principles), references/, templates/, sub-agents/.
│
├── shared/                                 # Global: resources for all projects
│   ├── BMAD-SHARED-CONTEXT.md              # Four-phase cycle + handoff model
│   ├── karpathy-principles/                # Tool-tailored "discipline" rulebooks (NEW)
│   │   ├── README.md                       # Index + install recipes per tool
│   │   ├── claude-code.md                  # Canonical adaptation for Claude Code
│   │   ├── cowork.md                       # Desktop/file-creation framing
│   │   ├── codex-cli.md                    # CLI + destructive-command caution
│   │   ├── kiro.md                         # Has `inclusion: always` frontmatter
│   │   ├── cursor.mdc                      # Has `alwaysApply: true` frontmatter
│   │   ├── windsurf.md                     # Targets Cascade multi-file changesets
│   │   ├── copilot-instructions.md         # Ties to green-PR success criteria
│   │   ├── gemini-cli.md                   # Tool-call safety framing
│   │   ├── opencode.md                     # Near-canonical
│   │   └── aider.md                        # /add, /ask, /run, edit-block terminology
│   ├── references/
│   │   └── technology-radar.md
│   ├── scripts/
│   │   └── bmad-metrics-lib.sh             # Shared metrics library (NEW) — sourced
│   │                                       # by /bmad:eval, /bmad:status, and the
│   │                                       # auto-eval hooks. Installed to
│   │                                       # ~/.bmad/scripts/ on global install.
│   └── templates/
│       ├── adr-template.md
│       ├── story-template.md
│       ├── test-strategy-template.md
│       └── handoff-log-template.md
│       # Note: BRD, PRD, epic, requirements-analysis, and user-story templates
│       # live in their respective agents/product-owner/templates/ and
│       # agents/business-analyst/templates/ for agent-level progressive disclosure.
│
├── hooks/                                  # Session hooks (Claude Code / Kiro)
│   ├── global/
│   │   ├── settings.json                   # PreToolUse / PostToolUse / Stop bindings
│   │   └── scripts/
│   │       └── post-merge-eval.sh          # Git post-merge hook (NEW) — fires
│   │                                       # /bmad:eval --auto on merge/pull
│   ├── project/
│   │   ├── settings.json
│   │   └── scripts/
│   │       └── auto-eval-on-sprint-results.sh  # PostToolUse on sprint-N-results.md
│   ├── yolo-harness/                       # Autonomous orchestration harness
│   │   ├── settings.json
│   │   ├── settings-windows.json
│   │   └── hooks/
│   │       └── post-cleanup-eval.sh        # Records eval after worktree cleanup
│   └── install-project-hooks.sh            # Per-repo installer (NEW) — wires the
│                                           # git post-merge hook + copies Claude
│                                           # PostToolUse hooks into .claude/hooks/
│
├── rules/                                  # Per-tool rules files generated from agents/
│   ├── README.md
│   ├── aider/                              # .aider.conventions.md fragments
│   ├── copilot/                            # copilot-instructions.md fragments
│   ├── cursor/                             # .cursor/rules/*.mdc
│   ├── gemini/                             # GEMINI.md fragments
│   │   ├── global/                         # User-level context fragments
│   │   ├── project/                        # Project-level context fragments
│   │   └── agents/                         # 13 native Gemini subagent definitions
│   │       ├── bmad.md                     #   @bmad — routing advisor
│   │       ├── product-owner.md            #   @product-owner — BRD / PRD / epics
│   │       ├── business-analyst.md         #   @business-analyst — stories + NFRs
│   │       ├── enterprise-architect.md     #   @enterprise-architect — EA boundaries
│   │       ├── ux-designer.md              #   @ux-designer — wireframes + a11y
│   │       ├── solution-architect.md       #   @solution-architect — APIs + ADRs
│   │       ├── infosec-architect.md        #   @infosec-architect — threat model + SBOM
│   │       ├── devsecops-engineer.md       #   @devsecops-engineer — pipelines + SLOs
│   │       ├── tech-lead.md                #   @tech-lead — kickoff + code review
│   │       ├── backend-engineer.md         #   @backend-engineer — services + APIs
│   │       ├── frontend-engineer.md        #   @frontend-engineer — web UI + perf
│   │       ├── mobile-engineer.md          #   @mobile-engineer — iOS/Android
│   │       └── tester-qe.md                #   @tester-qe — test plan + quality gates
│   ├── opencode/                           # AGENTS.md fragments
│   ├── windsurf/                           # .windsurf/rules/*.md
│   └── trae/                               # .trae/rules/*.md (framework seed)
│       └── global/
│           └── bmad-framework.md           # Deployed as user_rules.md + 000-bmad-framework.md
│
├── mcp-configs/                            # MCP server configuration files
│   └── global/
│       ├── pencil.json                     # Pencil desktop MCP (UX wireframing)
│       ├── figma.json                      # Figma MCP (UX wireframing)
│       ├── browser.json                    # Browser automation (Playwright / TQE)
│       ├── filesystem.json                 # Filesystem access
│       ├── github.json                     # GitHub integration
│       └── playwright.json                 # Playwright testing automation
│
├── eval/                                   # Agent-quality eval dashboard
│   └── bmad-agent-eval-dashboard.html      # Schema-v2 aware. Import button +
│                                           # drag-drop accept any .jsonl log
│                                           # (per-project or ~/.bmad/eval/global-log.jsonl).
│                                           # Records dedupe by (project, practitioner,
│                                           # role, week); latest _collectedAt wins.
│
├── templates/                              # Top-level instruction-file templates
│                                           # (CLAUDE.md / GEMINI.md / AGENTS.md / …)
│
├── project-scaffold/                       # Template for new projects
│   ├── .bmad/
│   │   ├── PROJECT-CONTEXT.md
│   │   ├── tech-stack.md
│   │   ├── team-conventions.md
│   │   ├── domain-glossary.md
│   │   ├── handoff-log.md
│   │   ├── ux-design-master.md             # Created by UX Designer on first run
│   │   └── signals/                        # Sentinel files for inter-agent coordination
│   └── docs/
│       ├── brd.md                          # Business Requirements Document (PO)
│       ├── prd.md                          # Product Requirements Document (PO)
│       ├── features/                       # Feature briefs (PO, one per feature)
│       ├── epics/                          # Epic definitions (PO)
│       ├── stories/                        # User stories with GWT ACs (BA)
│       ├── analysis/                       # Requirements analysis, use cases, impact analyses (BA)
│       ├── architecture/                   # EA, SA, ADRs, sprint plans (EA + SA + TL)
│       ├── security/                       # Threat models, controls, SBOM (InfoSec)
│       ├── platform/                       # IaC, pipelines, runbooks, SLOs (DevSecOps)
│       ├── ux/                             # Personas, wireframes, design system (UX)
│       └── testing/                        # Test strategies, results, bug reports (TQE)
│
├── scripts/
│   ├── install-global.sh                   # Deploy agents/ + shared/ + karpathy-principles to all detected tools
│   ├── scaffold-project.sh                 # Create .bmad/ + project wiring files
│   ├── update.sh                           # Update global install + all projects
│   ├── bmad-eval-run.sh                    # Standalone --auto eval runner (NEW) —
│   │                                       # called by hooks. Mirrors the slash
│   │                                       # command's auto-mode behaviour without
│   │                                       # an LLM in the loop.
│   ├── clean-duplicate-hooks.py            # Dedup hooks after upgrades
│   ├── migrate-handoff-log.py              # Migrate legacy handoff logs
│   ├── yolo.sh                             # Yolo harness launcher (macOS/Linux)
│   └── yolo.ps1                            # Yolo harness launcher (Windows)
│
├── CLAUDE.md                               # Project-level auto-load for Claude Code
├── GEMINI.md                               # Project-level auto-load for Gemini CLI
├── gemini-extension.json                   # Gemini CLI extension manifest
├── FILES_CREATED.md                        # Changelog of generated files
└── NEW_FILES_SUMMARY.txt                   # Upgrade audit trail
```

> **Where the Karpathy principles live.** Three layers, all installed together by `scripts/install-global.sh`:
>
> 1. **`shared/karpathy-principles/`** — 10 tool-tailored rulebooks + index. Installed per tool (e.g. `~/.claude/KARPATHY-PRINCIPLES.md`, `~/.cursor/rules/001-karpathy-principles.mdc`, appended to `~/.aider.conventions.md`, etc.).
> 2. **`agents/*/SKILL.md`** — each of the 13 agent skills opens with an `## Engineering Discipline` section that restates the four principles before any project-context loading.
> 3. **`agents/*/brainstorm.md`** — the 5-phase clarification command carries the same principles as a preamble so brainstorming stays surgical, not performative.

---

[← Back to README](../README.md)  ·  [Agents](agents.md)  ·  [Architecture](architecture.md)  ·  [Workflows](workflows.md)  ·  [Tooling](tooling.md)  ·  [Adoption](adoption.md)
