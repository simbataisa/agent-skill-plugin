# BMAD SDLC Agents — Developer Guide

This repo is the **source of truth** for the BMAD agent squad. You develop agents here and the install script deploys them to all AI coding tools on your machine. Do not edit files directly inside `~/.claude/`, `~/.codex/`, `~/.kiro/`, or `~/.gemini/` — those are generated outputs.

---

## Key Commands

```bash
# Install all agents to every detected tool
bash scripts/install-global.sh

# Dry-run — preview what would be installed without writing anything
bash scripts/install-global.sh --dry-run

# Scaffold .bmad/ project context into a new project
bash scripts/scaffold-project.sh <project-name>

# Pull latest agent updates (git pull + reinstall)
bash scripts/update.sh
```

---

## Repository Structure

```
agents/                         ← Agent source files — edit here, never in ~/.claude etc.
  <agent-name>/
    SKILL.md                    ← Agent persona (uppercase — always present)
    brainstorm.md               ← Brainstorm & clarify before acting (every agent has one)
    <command>.md                ← Invocable commands (lowercase)
    references/                 ← Deep-dive guides loaded on demand
    templates/                  ← Output templates (BRD, PRD, ADR, etc.)

shared/
  BMAD-SHARED-CONTEXT.md        ← Org-wide conventions loaded by all agents
  references/                   ← Shared reference docs (technology radar, etc.)
  templates/                    ← Shared output templates

scripts/
  install-global.sh             ← Main installer — deploys to all detected tools
  scaffold-project.sh           ← Scaffolds .bmad/ into a project repo
  update.sh                     ← git pull + reinstall in one step

rules/                          ← Tool-specific rule/context files
  cursor/   gemini/   copilot/   windsurf/   aider/   opencode/

hooks/
  global/                       ← Hooks installed globally (PostToolUse, Stop)
  project/                      ← Hooks scaffolded per project
  yolo-harness/                 ← Yolo parallel execution harness

mcp-configs/
  global/                       ← MCP server config stubs (merge into tool settings)

eval/
  bmad-agent-eval-dashboard.html ← Standalone productivity dashboard
```

---

## Agent File Conventions

### SKILL.md (agent persona)

Required frontmatter fields:

```yaml
---
name: tech-lead                  # lowercase, matches folder name
description: "..."               # invocation description — be specific about WHEN to use
compatibility: "..."             # which tools support full vs. sequential mode
allowed-tools: "..."             # comma-separated tool list
metadata:
  version: "1.0.0"
---
```

### Command files (e.g. `code-review.md`)

Required frontmatter fields:

```yaml
---
description: "[Agent Name] What this command does and when to use it."
argument-hint: "[what to pass as $ARGUMENTS]"
---
```

- Use `$ARGUMENTS` in the body where the user's input should be substituted.
- Keep commands under 150 lines. Move detail into `references/` and load on demand.
- Every agent must have a `brainstorm.md` command — it is the entry point for open-ended work.

---

## Adding a New Command to an Existing Agent

1. Create `agents/<agent-name>/<command>.md` with the required frontmatter.
2. Run `bash scripts/install-global.sh --dry-run` to verify it's picked up.
3. Run `bash scripts/install-global.sh` to deploy.

The installer automatically discovers all `*.md` files in each agent folder (skipping `SKILL.md`) — no changes to `install-global.sh` needed.

**Tool invocations after install:**

| Tool | Invocation |
|------|-----------|
| Claude Code | `/tech-lead:code-review` |
| Codex | `tech-lead-code-review` skill |
| Kiro | `/tech-lead-code-review` |
| Gemini | `/bmad-tech-lead:code-review` |

---

## Adding a New Agent

1. Create `agents/<agent-name>/` directory.
2. Add `SKILL.md` with full frontmatter (name, description, compatibility, allowed-tools, metadata).
3. Add `brainstorm.md` — every agent must have one.
4. Add command files as needed.
5. Optionally add `references/` and `templates/` subdirectories.
6. Run `bash scripts/install-global.sh --dry-run` to verify.
7. Run `bash scripts/install-global.sh` to deploy.

**Naming rules:**
- Folder name: `kebab-case` (e.g. `data-engineer`)
- `name:` in SKILL.md frontmatter must exactly match the folder name
- Command files: `kebab-case.md` (e.g. `build-pipeline.md`)

---

## How the Installer Works

`scripts/install-global.sh` detects each tool by checking for its config directory or binary, then deploys agents in the tool's native format:

| Tool | Detection | Deploy format |
|------|-----------|--------------|
| Claude Code | `~/.claude/` exists | `~/.claude/commands/<agent>/<cmd>.md` (slash commands) |
| Codex | `~/.codex/` exists | `~/.codex/skills/<agent>-<cmd>/SKILL.md` (43 flat skill folders) |
| Kiro | `~/.kiro/` exists | `~/.kiro/skills/<agent>-<cmd>/SKILL.md` + `name:` frontmatter |
| Gemini | `~/.gemini/` exists | `~/.gemini/extensions/bmad-<agent>/skills/<cmd>/SKILL.md` |
| Cursor | `~/.cursor/` exists | `~/.cursor/rules/bmad-<agent>-<cmd>.mdc` |
| Windsurf | `~/.windsurf/` exists | `~/.windsurf/memories/bmad-<agent>-<cmd>.md` |
| Aider | `~/.aider/` exists | `~/.aider/conventions.md` (appended sections) |

**Kiro-specific:** `name:` frontmatter must match the folder name and must not contain YAML-special characters. Descriptions with `[brackets]` are automatically double-quoted.

**Gemini-specific:** One extension per agent (`bmad-<agent-name>`). `GEMINI.md` contains pure `@import` directives only — no inline content. Agent persona goes in `skills/<agent-name>/SKILL.md` so it's invocable as `/bmad-tech-lead:tech-lead`.

---

## Agents & Their Commands

| Agent | Commands |
|-------|---------|
| `product-owner` | `brainstorm`, `create-brd`, `create-prd`, `new-epic`, `new-story` |
| `business-analyst` | `brainstorm`, `create-requirements`, `create-user-story` |
| `enterprise-architect` | `brainstorm`, `architecture-review`, `new-adr`, `tech-radar-update` |
| `solution-architect` | `brainstorm`, `create-api-spec`, `create-solution-arch` |
| `ux-designer` | `brainstorm`, `accessibility-audit`, `create-wireframe` |
| `infosec-architect` | `brainstorm`, `compliance-map`, `risk-register`, `threat-model` |
| `tech-lead` | `brainstorm`, `code-review`, `release-check`, `sprint-plan` |
| `devsecops-engineer` | `brainstorm`, `security-gate`, `security-scan` |
| `backend-engineer` | `brainstorm`, `implement-story` |
| `frontend-engineer` | `brainstorm`, `create-component`, `implement-story` |
| `mobile-engineer` | `brainstorm`, `implement-story` |
| `tester-qe` | `brainstorm`, `create-test-plan`, `run-quality-gate` |
| `bmad` | `brainstorm`, `eval`, `handoff`, `status` |

---

## BMAD Flow

```
Product Owner → Business Analyst → Enterprise Architect ∥ UX Designer
    → Solution Architect → Tech Lead → Engineers (BE/FE/ME) → Tester/QE
```

**Start every session with `/brainstorm`** on the relevant agent to clarify scope before producing any artifact.

---

## Project Context (per project)

After install, scaffold `.bmad/` into each project:

```bash
bash scripts/scaffold-project.sh <project-name>
```

Agents load project context automatically:
1. `shared/BMAD-SHARED-CONTEXT.md`
2. `.bmad/PROJECT-CONTEXT.md`
3. `.bmad/tech-stack.md`
4. `.bmad/team-conventions.md`

---

## Troubleshooting

**Skill not appearing after install**
→ Re-run `bash scripts/install-global.sh`. For Gemini, re-register: `for ext in ~/.gemini/extensions/bmad-*/; do gemini extensions install "$ext"; done`

**Kiro: "Invalid SKILL.md frontmatter"**
→ The `name:` field must be lowercase, letters/numbers/hyphens only, and match the folder name exactly.

**Gemini: skills showing persona only, not commands**
→ Ensure `GEMINI.md` uses pure `@import` lines only. Run `cat ~/.gemini/extensions/bmad-tech-lead/GEMINI.md` to verify.

**Codex: skills folder empty after install**
→ The install script wipes `~/.codex/skills/` then repopulates. Run the installer again — if it's still empty, check for errors in the output.

**Plugin conflict (another plugin overrides BMAD)**
→ Disable the conflicting plugin in Claude Code → Settings → Plugins before starting a BMAD session. Always prefix your message with the slash command (e.g. `/tech-lead:brainstorm`) to bypass fuzzy skill matching.
