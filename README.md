# BMAD SDLC Agents

> **Two-layer agent architecture for governed, parallel, AI-native software delivery.**

[![License: PolyForm Noncommercial 1.0.0](https://img.shields.io/badge/license-PolyForm%20Noncommercial%201.0.0-blue.svg)](./LICENSE)
[![Commercial license available](https://img.shields.io/badge/commercial%20license-available-success.svg)](./COMMERCIAL-LICENSE.md)
[![Latest release](https://img.shields.io/github/v/release/simbataisa/agent-skill-plugin?label=release&color=informational)](https://github.com/simbataisa/agent-skill-plugin/releases)
[![GitHub stars](https://img.shields.io/github/stars/simbataisa/agent-skill-plugin?style=social)](https://github.com/simbataisa/agent-skill-plugin/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/simbataisa/agent-skill-plugin?style=social)](https://github.com/simbataisa/agent-skill-plugin/network/members)
[![Open issues](https://img.shields.io/github/issues/simbataisa/agent-skill-plugin.svg)](https://github.com/simbataisa/agent-skill-plugin/issues)
[![Open pull requests](https://img.shields.io/github/issues-pr/simbataisa/agent-skill-plugin.svg)](https://github.com/simbataisa/agent-skill-plugin/pulls)
[![Last commit](https://img.shields.io/github/last-commit/simbataisa/agent-skill-plugin.svg)](https://github.com/simbataisa/agent-skill-plugin/commits)

---

**BMAD** (Breakthrough Method of Agile AI-Driven Development) is an enterprise methodology for delivering software through a cross-functional squad of **13 specialized AI agents** (12 role-specific agents plus a `bmad` orchestrator). This repository implements the **two-layer architecture**: a global layer with reusable agent skills and shared resources, plus a project layer with context files checked into each project repo.

Install the global layer once across all your AI coding tools, then scaffold `.bmad/` context files into each project. Agents dynamically load project-specific knowledge from `.bmad/` combined with shared resources, creating a cohesive, context-aware squad.

---

## Why BMAD

- **Roles, not prompts.** PO, BA, EA, UX, SA, InfoSec, DevSecOps, TL, BE, FE, ME, TQE — each agent loads its own `SKILL.md` with scope boundaries, agent rules, and a completion protocol.
- **Two layers.** A reusable global layer installs once across all your AI tools; a project layer (`.bmad/`) pins context, tech-stack, and conventions per repo.
- **Governed by design.** Karpathy-derived engineering principles, inline Agent Rules, ADR lock per sprint, A2UI advisory, sentinel-file orchestration, and a productivity dashboard built in.
- **Parallel by default.** Tech Lead orchestrates real parallel BE ∥ FE ∥ ME against isolated git worktrees, with first-merge-wins conflict ownership.
- **One playbook · 11 tools.** Native installers for Claude Code, Cowork, Cursor, Windsurf, Trae IDE, GitHub Copilot, Codex CLI, Gemini CLI, Kiro, OpenCode, Aider — pick the tool the team is already using.

---

## At a glance

|                            |                                                                                                                                       |
| -------------------------- | ------------------------------------------------------------------------------------------------------------------------------------- |
| **Specialized AI agents**  | 13                                                                                                                                    |
| **Tools supported**        | 11                                                                                                                                    |
| **Workflow types**         | 5 (new project · feature · bug · hotfix · backlog)                                                                                    |
| **Plan + Execute waves**   | 7 plan + 3 execute                                                                                                                    |
| **Engineering principles** | 4 — Think before coding · Simplicity first · Surgical changes · Goal-driven execution                                                 |
| **License**                | [PolyForm Noncommercial 1.0.0](./LICENSE) (free for non-commercial) · [Commercial license](./COMMERCIAL-LICENSE.md) for organizations |

---

## Quick start (3 steps)

```bash
# 1. Install the global layer once per machine
bash scripts/install-global.sh
# Windows: powershell -ExecutionPolicy Bypass -File .\scripts\install-global.ps1

# 2. Scaffold a project — run from the project root
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project Name"

# 3. Fill in .bmad/PROJECT-CONTEXT.md and .bmad/tech-stack.md, then start coding.
```

Full setup walkthroughs per tool live in [`docs/tooling.md`](docs/tooling.md). The first command to run inside any session is **`/<agent-name>:brainstorm`** — every agent has one.

---

## The squad

| Phase              | Agents                                                                         |
| ------------------ | ------------------------------------------------------------------------------ |
| **Analysis**       | Product Owner · Business Analyst                                               |
| **Solutioning**    | Enterprise Architect · UX/UI Designer · Solution Architect · InfoSec Architect |
| **Implementation** | Backend Engineer · Frontend Engineer · Mobile Engineer                         |
| **All phases**     | DevSecOps Engineer · Tech Lead · Tester & QE · BMAD Orchestrator               |

Full roster, role descriptions, and skill-file paths in [`docs/agents.md`](docs/agents.md).

---

## End-to-end flow

```
Product Owner → Business Analyst → Enterprise Architect ∥ UX Designer
   → Solution Architect → Tech Lead → Backend ∥ Frontend ∥ Mobile → Tester & QE
```

Each role hands off to the next via `.bmad/signals/*` sentinel files. Plan phase runs 7 waves; execute phase runs 3 waves per sprint. Engineers in Wave E2 run in **true parallel** against isolated git worktrees.

---

## Documentation

The detailed reference is split across five focused docs:

- **[docs/agents.md](docs/agents.md)** — full agent roster, BMAD phase mapping, skill-file paths.
- **[docs/architecture.md](docs/architecture.md)** — two-layer architecture, progressive disclosure, agent intelligence (quick mode, autonomous task detection, parallel waves), EA vs SA decision matrix, autonomous orchestration, tool capability matrix, file organization.
- **[docs/workflows.md](docs/workflows.md)** — five workflow diagrams (new project / feature / bug fix / hotfix / backlog), design tool integration (11 wireframe modes), `docs/ux/DESIGN.md` design system contract, worktree close-out protocol, conversational brainstorm protocol.
- **[docs/tooling.md](docs/tooling.md)** — wiring `.bmad/` auto-loading per tool, full setup guide for all 11 supported tools, install paths reference, sample prompts, full squad-prompt scripts.
- **[docs/adoption.md](docs/adoption.md)** — quick start details, project scaffold files, integration guide, common workflows, productivity evaluation framework, FAQ, support & contributing.

---

## Engineering discipline

Every agent's `SKILL.md` opens with a restatement of the four **Karpathy-derived engineering principles** — installed once per tool under [`shared/karpathy-principles/`](shared/karpathy-principles/README.md):

1. **Think before coding** — `brainstorm.md` is a conversation, one question per turn.
2. **Simplicity first** — prefer the smallest change that meets the goal.
3. **Surgical changes** — every code-writing agent works in an isolated git worktree on a dedicated branch.
4. **Goal-driven execution** — every agent resolves which deliverable, against which acceptance criterion, by which signal.

---

## License

BMAD SDLC Agents is **dual-licensed**:

- **[PolyForm Noncommercial 1.0.0](./LICENSE)** — free for individuals, hobby projects, academic research, charitable organizations, educational institutions, public research organizations, and government bodies.
- **[Commercial License](./COMMERCIAL-LICENSE.md)** — required for any **for-profit organization**, or any use in support of a commercial product or service. Pricing is per organization, per year, sized to the number of developers using BMAD-installed agents. Educational, nonprofit, and open-source organizations are eligible for a free commercial license.

If you are unsure which license applies, see the eligibility matrix in [`COMMERCIAL-LICENSE.md`](./COMMERCIAL-LICENSE.md) or contact `licensing@dennisdao.com`.

---

## Support & contributing

For issues, enhancements, or new agents, open an issue. To contribute an agent or template, see the contribution guidelines in `CONTRIBUTING.md`. Detailed contributor docs live in [`docs/adoption.md`](docs/adoption.md).

---

## Star history

[![Star History Chart](https://api.star-history.com/svg?repos=simbataisa/bmad-sdlc-agents&type=Date)](https://www.star-history.com/#simbataisa/bmad-sdlc-agents&Date)

---

**BMAD Version:** 2.4 (PO→BA→EA∥UX→SA→TL Flow + Responsibility Boundaries + Design Tool Integration + Read-Only Pencil/Figma MCP for All Agents)
**Last updated:** 2026-04-29
