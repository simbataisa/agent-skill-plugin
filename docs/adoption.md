# Adoption, Productivity & FAQ

Quick start, project scaffold layout, integration guide, common workflows, productivity evaluation framework, FAQ, and how to contribute.

## Table of Contents

- [Quick Start (3 Steps)](#quick-start-3-steps)
- [Project Scaffold Files](#project-scaffold-files)
- [Integration Guide](#integration-guide)
- [Common Workflows](#common-workflows)
- [Productivity Evaluation](#productivity-evaluation)
- [FAQ](#faq)
- [Support & Contributing](#support--contributing)

---

## Quick Start (3 Steps)

### Step 1: Install Global Layer

**macOS / Linux / WSL / Git Bash:**

```bash
bash scripts/install-global.sh
# Add --dry-run to preview without writing files
```

**Windows 11 (PowerShell 5.1+ or PowerShell 7+):**

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-global.ps1
# or, with -DryRun to preview
.\scripts\install-global.ps1 -DryRun
```

Copies all agent skills, subagents, commands, hooks, and shared resources to tool-specific global directories. Runs once per machine. The PowerShell version is feature-for-feature equivalent with the bash version — no python3 required (hook-settings merges use native PowerShell JSON cmdlets) and UTF-8 output is written without BOM to stay byte-compatible with the bash-generated files.

### Step 2: Scaffold New Project

**Bash:**

```bash
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project Name"
# Add --force to overwrite an existing .bmad/ directory
```

**PowerShell (Windows 11):**

```powershell
& "C:\path\to\bmad-sdlc-agents\scripts\scaffold-project.ps1" "My Project Name"
# -Force to overwrite an existing .bmad/ directory
```

Creates `.bmad/` context files, installs project-level agents, and generates a tool-specific instruction file (e.g. `CLAUDE.md`) that tells your AI tool to auto-load `.bmad/` at the start of every session.

### Step 3: Fill Project Context

Edit `.bmad/PROJECT-CONTEXT.md` and `.bmad/tech-stack.md` with your project details. The instruction file and all agents will pick these up automatically on the next session.

---

## Project Scaffold Files

After running `scaffold-project.sh`, the `.bmad/` directory contains:

| File                  | When to Fill In               | Purpose                                                                          |
| --------------------- | ----------------------------- | -------------------------------------------------------------------------------- |
| `PROJECT-CONTEXT.md`  | Before first sprint           | Project vision, goals, stakeholders, constraints, timeline                       |
| `tech-stack.md`       | Before architecture decisions | Languages, frameworks, databases, cloud platform, CI/CD                          |
| `team-conventions.md` | Before first code review      | Code style, naming conventions, architecture patterns, PR process                |
| `domain-glossary.md`  | During analysis phase         | Business domain terminology, entities, relationships                             |
| `handoff-log.md`      | Ongoing                       | Record of work handed off between agents or to humans                            |
| `ux-design-master.md` | After first UX Designer run   | Design tool choice (ASCII / Pencil / Figma), master file path/ID, and page index |
| `signals/`            | Automatically by agents       | Sentinel files for inter-agent coordination and autonomous mode                  |

**Tip:** Fill `PROJECT-CONTEXT.md` and `tech-stack.md` first. Other files populate based on these.

---

## Integration Guide

### How Agents Use Context

When you invoke an agent in any tool, it automatically:

1. **Detects** `.bmad/PROJECT-CONTEXT.md` in the current project
2. **Loads** its skill from `agents/<agent-name>/SKILL.md`
3. **Reads** `.bmad/tech-stack.md` and `.bmad/team-conventions.md` for project specifics
4. **Falls back** to `shared/BMAD-SHARED-CONTEXT.md` for company standards
5. **Applies** context to your prompt and generates project-aware responses

### Continuous Integration

The `scripts/update.sh` pulls the latest agent skills and shared resources, then:

- Rebuilds global tool directories
- Refreshes all project `.bmad/` symlinks
- Preserves project-specific overrides

### Version Control

- **Commit to git:** `.bmad/` directory (context files are project-specific)
- **Commit to git:** `docs/` directory (all artifacts)
- **Do not commit:** Global `~/.claude/`, `~/.codex/`, `~/.kiro/`, `~/.skills/`, `~/.cursor/`, etc. (manage with `install-global.sh`)
- **Do not commit:** Tool-specific config files unless project-managed

---

## Common Workflows

### Onboarding a New Team Member

```bash
# Clone project repo (includes .bmad/)
git clone <project-repo>

# Install global agents (once per machine)
bash /path/to/bmad-sdlc-agents/scripts/install-global.sh

# New team member can now:
# - Load agents in their favorite tool
# - Access project context from .bmad/
# - Collaborate with squad prompts
```

### Starting a New Project

```bash
# Scaffold the project
bash /path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "New Platform"

# Add to your project repo
git add .bmad/ docs/ .claude/ .cursor/ # (as needed per tool)
git commit -m "Add BMAD project scaffold"

# Fill in context files
# Edit: .bmad/PROJECT-CONTEXT.md, .bmad/tech-stack.md
```

### Running Full Squad Analysis

Use the **Squad Prompt** section above as a session script. For Claude Code, run one agent per turn using its slash command. Do not paste the whole squad prompt as one message — invoke each agent explicitly.

### Continuing to the Next Sprint

After each sprint the Tester-QE agent prints a `✅` review summary and waits. Once you've reviewed and type `next`, here's how to continue:

**Claude Code / Codex CLI** — invoke each agent individually with the Sprint Continuation prompts from the Squad Prompt section. The sprint plan (produced by Tech Lead in Turn 6) already contains all sprint batches, so you only need to pull the next batch from it.

**Cursor / Windsurf / Trae / Kiro** — paste **Prompt C** (Sprint N+1 Continuation) from the Squad Prompt section, replacing `N` with the completed sprint number.

The key steps for every sprint boundary are the same regardless of tool:

1. Type `next` to accept the Tester-QE review (closes Sprint N)
2. (No action needed — the post-merge / sprint-results hooks record `/bmad:eval --auto` for you. Run `/bmad:eval` manually for an interactive snapshot if you want a richer record.)
3. Invoke **Tech Lead** — read `sprint-N-results.md`, confirm carry-overs, produce `sprint-N+1-kickoff.md`
4. Invoke **Backend / Frontend / Mobile** engineers with Sprint N+1 story lists from the kickoff doc
5. Invoke **Tester-QE** — test Sprint N+1, save `sprint-N+1-results.md`
6. Repeat from step 1

> The sprint plan is written once (Turn 6) and covers all sprints. You never need to re-plan unless scope changes — in that case, re-invoke Tech Lead with a `// SCOPE CHANGE:` note.

### Updating Agents Across All Projects

```bash
# Pull latest agents and shared resources
bash /path/to/bmad-sdlc-agents/scripts/update.sh

# All projects instantly have access to updated agents
# Project context files are preserved
```

---

## Productivity Evaluation

BMAD includes a framework for measuring AI-assisted productivity gains, specifically designed for Enterprise Architect (EA) and Solution Architect (SA) roles.

### Three Dimensions × Nine Metrics

| Dimension    | Metrics                                                          | Weight |
| ------------ | ---------------------------------------------------------------- | ------ |
| **Speed**    | Time-to-First-Draft, Time-to-Approval, Iteration Turnaround      | 35%    |
| **Quality**  | First-Pass Review Rate, NFR Coverage Score, Arch Debt Introduced | 35%    |
| **Coverage** | Alternatives Evaluated, Risks Identified, Stakeholder Scenarios  | 30%    |

**Composite Score** = `0.35 × Speed + 0.35 × Quality + 0.30 × Coverage` (normalized 0–100)

### The `/bmad:eval` Command

Run `/bmad:eval` inside any BMAD project to record a productivity snapshot. The command auto-collects everything it can from `.bmad/` artifacts, git history, and architecture docs, then asks the practitioner only for fields that can't be derived. It runs in two modes:

| Mode | Trigger | Practitioner interview | Output |
|---|---|---|---|
| **Interactive** | `/bmad:eval` | One question per turn (7 questions, "skip" to bypass) | Verbose chat report |
| **Auto** | `/bmad:eval --auto` (or any of the auto-trigger hooks) | Skipped — uses env defaults | Silent unless `--verbose` |

**What gets auto-derived** (no manual input needed):

- NFR coverage (ratio of NFR sections present as headings in the solution architecture)
- Alternatives evaluated (count of `### Option` headings under `## Options Considered` across ADRs)
- Risks (entries inside `## Risks` sections / risk-register tables)
- Scenarios (Gherkin `Scenario:` lines + `## Use Case` / `## User Journey` headings)
- Architecture debt (count of ADRs whose status is Deferred / Deprecated / Superseded)
- DEVIATION / FIX / HOTFIX markers — both stock (current count) and flow (added in last 7 days)
- Iteration turnaround (mean Δ in hours between consecutive commits on each artifact)
- First-pass review rate (derived via `gh pr list` when GitHub CLI is available)
- Sprint velocity (planned vs completed stories from sprint-N-kickoff/results)

**What's still manual** (asked sequentially in interactive mode, `null` in auto mode):

1. Practitioner ID & name
2. Phase (`baseline` vs `assisted`)
3. Time-to-artifact (hours)
4. Time-to-first-draft (hours)
5. First-pass review rate — only if `gh` derivation failed
6. Rules compliance rating (1–5)
7. Iteration turnaround — only if no inter-commit Δ available

Every numeric metric carries a `confidence` tag (`manual` | `derived` | `fuzzy` | `missing`) so the dashboard can dim values that need human verification.

### Storage layout — per-project log + global mirror

Each `/bmad:eval` run does a **dual-write** via the shared library:

| Path | Content | Lifecycle |
|---|---|---|
| `<project>/.bmad/eval/eval-log.jsonl` | Authoritative project log | Per-project; can be checked into git |
| `~/.bmad/eval/global-log.jsonl` | Machine-wide rollup across all your projects | Auto-mirrored unless `BMAD_NO_GLOBAL_MIRROR=1` |

Records are deduped by `(project, practitioner, role, week)` — re-running in the same week overwrites the prior snapshot, so back-to-back hook invocations don't pile up duplicates. Set `--debounce=N` (default 30 minutes) to suppress runs that come too soon after the last one.

Every record carries `schemaVersion: 2` and a flat metric shape that the dashboard reads directly.

### Auto-triggers — eval on workflow completion

Three events fire `/bmad:eval --auto` automatically when the per-repo hooks are installed:

| Event | Hook | Mechanism |
|---|---|---|
| `git pull` / `git merge` / `git rebase` lands locally | `.git/hooks/post-merge` | Fire-and-forget background run |
| Sprint results file written (`docs/testing/sprint-*-results.md`) | Claude Code PostToolUse hook on `Write` | Synchronous, debounced 15min |
| Yolo harness session wrap-up (worktree cleanup) | `hooks/yolo-harness/hooks/post-cleanup-eval.sh` | Synchronous, tagged `worktree-cleanup` |

**Install per repo:**

```bash
cd /path/to/your/project
bash /path/to/bmad-sdlc-agents/hooks/install-project-hooks.sh
```

The installer is idempotent and uses a `BMAD-MANAGED` sentinel comment so it never clobbers existing user-written hooks (use `--force` to override).

### Practitioner identity for hook-driven runs

Set these once in `~/.bmadrc` so auto-triggered runs attribute correctly:

```bash
# ~/.bmadrc
export BMAD_PRACTITIONER_ID="TL-01"
export BMAD_PRACTITIONER_NAME="Your Name"
export BMAD_PRACTITIONER_ROLE="TL"
export BMAD_PHASE="assisted"   # or "baseline" while running comparisons
```

Then source it from your shell rc (`echo 'source ~/.bmadrc' >> ~/.bashrc`).

### Interactive Dashboard

The dashboard ships as `eval/bmad-agent-eval-dashboard.html` in this repo. After install:

- **Per-project:** `.bmad/eval/bmad-agent-eval-dashboard.html` — scaffolded automatically by `scaffold-project.sh`
- **Global reference:** `~/.bmad/eval/bmad-agent-eval-dashboard.html` — copied by `install-global.sh`

Self-contained HTML (Chart.js, no server required). Visualizes:

- KPI cards with baseline → assisted deltas
- Weekly composite trend (bar chart)
- Per-dimension breakdowns (Speed, Quality, Coverage)
- EA vs SA radar comparison
- Two-sample t-test statistical significance table
- Sortable practitioner detail table

**Loading your real data — the Import flow:**

1. Open the dashboard.
2. Click the **Import JSONL** button in the toolbar (or drag `~/.bmad/eval/global-log.jsonl` directly onto the page).
3. Pick one or more files — per-project logs or the global rollup, in any combination.
4. The first import replaces the synthetic demo data; subsequent imports merge with `(project, practitioner, role, week)` dedupe (latest `_collectedAt` wins).
5. A **Project** filter dropdown auto-appears once ≥2 projects are loaded, so you can drill into one project or compare across them.
6. Click **Reset to demo** any time to swap back to the simulated dataset.

`null` metrics (confidence: `missing`) are excluded from the affected charts but still contribute to other metrics on the same row — so partial records remain useful.

**Statistical significance:** With ≥4 baseline weeks and ≥4 assisted weeks per practitioner, the t-test table becomes meaningful. Set `BMAD_PHASE=baseline` for the initial 4-week stretch (no AI), then `BMAD_PHASE=assisted` once you start using BMAD.

---

## FAQ

**Q: Where do agents live?**
A: Source files live in `agents/` in this repo. After running `install-global.sh` they are deployed to your tool (e.g. `~/.claude/skills/` for Claude Code). You invoke them with a slash command (`/solution-architect`) or by addressing the agent by role — no file paths needed.

**Q: Where does project context live?**
A: In `.bmad/` (per project, checked into git). Each project has its own `.bmad/PROJECT-CONTEXT.md`, `tech-stack.md`, etc.

**Q: Do I need to install globally?**
A: Yes, once per machine. Then scaffold each project. Agents find `.bmad/` files automatically.

**Q: Can I customize agents per project?**
A: Yes. Copy an agent skill to `.claude/skills/` or `.cursor/rules/` and edit it for project-specific tweaks.

**Q: How do I version agents?**
A: Keep `agents/` in the BMAD repository. Use `scripts/update.sh` to refresh. Project context (`.bmad/`) versions with your project.

**Q: Can multiple teams use different tech stacks?**
A: Absolutely. Each project has its own `tech-stack.md`, so agents adapt to TypeScript, Python, Kotlin, etc.

**Q: Another plugin (e.g. superpowers) keeps taking over my BMAD session. How do I stop it?**
A: There are two layers to this conflict:

1. **Hook injection** — Plugins with `PostToolUse` or `Stop` hooks can inject follow-up instructions _after every tool call_, below the skill-matching layer. Even an explicit slash command like `/business-analyst` can be overridden this way. The only fix is to **disable the conflicting plugin** in Claude Code → Settings → Plugins before running a BMAD session. You can re-enable it afterward for non-BMAD projects.

2. **Skill-matching** — If you send a large prose prompt ("plan and design my project…"), Claude Code fuzzy-matches across all installed skills. A broad planning/analysis plugin wins because its triggers are wider. The fix is to **always start each message with the slash command** (`/business-analyst`, `/solution-architect`, etc.) — slash commands are explicit file lookups, not fuzzy matches, so they bypass skill competition.

**Q: Can I run BMAD alongside other plugins?**
A: Yes, but not in the same session. Disable broad planning plugins (superpowers, etc.) at the start of a BMAD session, do your BMAD work, then re-enable them. For per-project isolation, note that Claude Code doesn't support per-project plugin enable/disable today — it's global. The cleanest workflow is: keep BMAD enabled globally, disable competing plugins when doing structured BMAD sessions.

---

## Support & Contributing

For issues, enhancements, or new agents, open an issue in the BMAD repository.

To contribute an agent or template, see the contribution guidelines in `CONTRIBUTING.md`.

---

[← Back to README](../README.md)  ·  [Agents](agents.md)  ·  [Architecture](architecture.md)  ·  [Workflows](workflows.md)  ·  [Tooling](tooling.md)  ·  [Adoption](adoption.md)
