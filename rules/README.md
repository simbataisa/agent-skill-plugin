# BMAD Rules Framework

This directory contains rule files for various AI coding assistants, configured to work with the BMAD SDLC framework.

## Overview

BMAD organizes software delivery through four phases and specialized agent roles. **Rules** provide always-on context to your coding assistant, while **agents** (in `agents/` directory) are invoked for specific tasks.

### Rules vs. Agents

- **Rules**: Always-on context loaded by your coding assistant globally or per-project
- **Agents**: Specific skills invoked when you ask to "act as" a particular role

## Tool-Specific Rules

### Cursor

Cursor uses `.mdc` (Markdown with Code) files with YAML frontmatter for rules.

| Level | File | Location | Purpose |
|---|---|---|---|
| Global | `000-bmad-framework.mdc` | `rules/cursor/global/` | BMAD overview, agent roster, context loading order |
| Project | `001-project-context.mdc` | `rules/cursor/project/` | Project-specific status, current phase, team info |
| Project | `002-tech-stack.mdc` | `rules/cursor/project/` | Confirmed tech decisions and coding standards |

**How to install Cursor rules**:
1. Place global rules in `~/.cursor/rules/`
2. Place project rules in `<project-root>/.cursor/rules/`
3. Cursor automatically loads all `.mdc` files in these directories

### Windsurf

Windsurf uses plain Markdown files for rules.

| Level | File | Location | Purpose |
|---|---|---|---|
| Global | `bmad-framework.md` | `rules/windsurf/global/` | BMAD overview and agent roster |
| Project | `project-context.md` | `rules/windsurf/project/` | Project-specific context |

**How to install Windsurf rules**:
1. Place global rules in `~/.windsurf/rules/`
2. Place project rules in `<project-root>/.windsurf/rules/`
3. Windsurf automatically loads all `.md` files in these directories

### GitHub Copilot

Copilot reads instructions from `~/.github/copilot-instructions.md` (global) and `.github/copilot-instructions.md` (project).

| Level | File | Location | Purpose |
|---|---|---|---|
| Global | `copilot-instructions.md` | `rules/copilot/global/` | BMAD overview, agent roster, conventions |
| Project | `copilot-instructions.md` | `rules/copilot/project/` | Project context, tech stack, domain terms |

**How to install Copilot rules**:
1. Global: Copy to `~/.github/copilot-instructions.md`
2. Project: Copy to `.github/copilot-instructions.md` in project root

### Gemini CLI

Gemini uses Markdown files read from `~/.gemini/GEMINI.md` (global) and `.gemini/GEMINI.md` (project).

| Level | File | Location | Purpose |
|---|---|---|---|
| Global | `GEMINI.md` | `rules/gemini/global/` | BMAD overview and agent roster |
| Project | `GEMINI.md` | `rules/gemini/project/` | Project context and configuration |

**How to install Gemini rules**:
1. Global: Copy to `~/.gemini/GEMINI.md`
2. Project: Copy to `.gemini/GEMINI.md` in project root

### OpenCode

OpenCode reads from `~/.opencode/instructions.md` (global) and `AGENTS.md` (project root).

| Level | File | Location | Purpose |
|---|---|---|---|
| Global | `instructions.md` | `rules/opencode/global/` | BMAD overview and agent roster |
| Project | `AGENTS.md` | `rules/opencode/project/` | Project configuration |

**How to install OpenCode rules**:
1. Global: Copy to `~/.opencode/instructions.md`
2. Project: Copy to `AGENTS.md` in project root

### Aider

Aider reads from `~/.aider.conventions.md`.

| Level | File | Location | Purpose |
|---|---|---|---|
| Global | `conventions.md` | `rules/aider/global/` | BMAD conventions and best practices |

**How to install Aider rules**:
- Copy to `~/.aider.conventions.md`

---

## Installation Instructions

### Quick Setup

1. **Copy global rules** to your home directory:
   ```bash
   cp rules/cursor/global/*.mdc ~/.cursor/rules/
   cp rules/windsurf/global/*.md ~/.windsurf/rules/
   cp rules/copilot/global/*.md ~/.github/copilot-instructions.md
   cp rules/gemini/global/*.md ~/.gemini/GEMINI.md
   cp rules/opencode/global/*.md ~/.opencode/instructions.md
   cp rules/aider/global/*.md ~/.aider.conventions.md
   ```

2. **Copy project rules** to your project root:
   ```bash
   mkdir -p .cursor/rules .windsurf/rules .github .gemini
   cp rules/cursor/project/*.mdc <project>/.cursor/rules/
   cp rules/windsurf/project/*.md <project>/.windsurf/rules/
   cp rules/copilot/project/*.md <project>/.github/copilot-instructions.md
   cp rules/gemini/project/*.md <project>/.gemini/GEMINI.md
   cp rules/opencode/project/AGENTS.md <project>/AGENTS.md
   ```

3. **Customize project rules** with your project-specific information (tech stack, phase, team, constraints)

### Tool Compatibility Matrix

| Tool | Global Support | Project Support | File Type | Config Format |
|---|---|---|---|---|
| Cursor | ✓ | ✓ | `.mdc` (YAML + Markdown) | File-based |
| Windsurf | ✓ | ✓ | `.md` (Markdown) | File-based |
| GitHub Copilot | ✓ | ✓ | `.md` (Markdown) | File-based |
| Gemini CLI | ✓ | ✓ | `.md` (Markdown) | File-based |
| OpenCode | ✓ | ✓ | `.md` (Markdown) | File-based |
| Aider | ✓ | — | `.md` (Markdown) | File-based |

---

## How to Customize Project Rules

1. Open the project-level rule file (e.g., `001-project-context.mdc`)
2. Find all `[FILL IN ...]` placeholders
3. Replace with your project-specific values:
   - Project name and description
   - Current BMAD phase (Business, Machine, Assembly, or Delivery)
   - Tech stack decisions
   - Key constraints
   - Domain terminology
   - Team information

Example:
```markdown
[FILL IN - e.g., "Customer Portal V2"]
```
Replace with:
```markdown
Authentication Service v2.0
```

---

## Project Context Files

Each project should also maintain these files in `.bmad/`:
- **PROJECT-CONTEXT.md** – Current project status, phase, and constraints
- **tech-stack.md** – Confirmed technology decisions with rationale
- **team-conventions.md** – Project-specific coding conventions

These are loaded in order by all rules and provide the ultimate source of truth for your project.

---

## Key Concepts

### BMAD Phases

1. **Business (B)**: Define requirements, gather stories, identify constraints
2. **Machine (M)**: Design architecture, choose tech stack, define API contracts
3. **Assembly (A)**: Implement features, review code, build software
4. **Delivery (D)**: Test, document, deploy, monitor

### Agent Roster

Each BMAD phase involves specific agent roles. When you ask to "act as [role]", the assistant should:
1. Read `agents/<role>/SKILL.md` first
2. Follow the agent's mandate and constraints
3. Coordinate with other agents as needed

### Context Loading Order

All assistants should load context in this sequence:
1. `.bmad/PROJECT-CONTEXT.md` (project-specific status)
2. `.bmad/tech-stack.md` (technology decisions)
3. `.bmad/team-conventions.md` (coding standards)
4. `shared/BMAD-SHARED-CONTEXT.md` (organization standards, if available)

---

## Troubleshooting

### Rules not loading in Cursor?
- Check that `.mdc` files are in `~/.cursor/rules/` (global) or `.cursor/rules/` (project)
- Reload Cursor or restart the application
- Check Cursor's rule settings in the UI

### Copilot not using instructions?
- Confirm `~/.github/copilot-instructions.md` exists and is readable
- For project-specific rules, ensure `.github/copilot-instructions.md` is committed to the repo
- Run `gh copilot --version` to confirm Copilot CLI is installed

### Windsurf not loading rules?
- Check file locations: `~/.windsurf/rules/` (global) and `.windsurf/rules/` (project)
- Ensure files have `.md` extension
- Restart Windsurf

---

## Related Documentation

- **Agent Skills**: See `agents/` directory for individual agent skill files
- **MCP Configurations**: See `mcp-configs/` for Model Context Protocol configurations
- **BMAD Framework**: Full framework documentation in global rules
