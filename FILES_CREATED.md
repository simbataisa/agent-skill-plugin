# BMAD SDLC Agent Suite - Files Created

**Date:** 2026-03-18  
**Total Files:** 8  
**Base Path:** `/sessions/upbeat-gracious-fermi/mnt/agent-skill-plugin/bmad-sdlc-agents/`

## Files Created

### 1. Project Scaffold Templates (5 files)

#### `project-scaffold/.bmad/PROJECT-CONTEXT.md` (45 lines)
Project-level orientation document filled in at kickoff. Agents read this first on every invocation.
- What We're Building (2-3 sentence overview)
- Current Phase tracking (4 checkboxes)
- Last Handoff (from/to/date/summary)
- Key Constraints (integration, deployment, compliance, team size, go-live date)
- Confirmed Decisions (architecture pattern, cloud provider)
- Artifacts Index (with location and status tracking)
- Stakeholders table (name, role, availability)

#### `project-scaffold/.bmad/tech-stack.md` (88 lines)
Technology decisions tracker populated during Phase 3 by architects.
- Decision Status Legend (✅ Confirmed, 🔄 Under review, ❌ Rejected)
- Application Layer:
  - Backend (language, framework, API style)
  - Frontend (framework, component library, state management, CSS)
  - Mobile (approach, framework)
  - Data (database, cache, search, message queue)
  - Integration (API gateway, auth/identity, workflow engine)
- Platform Layer:
  - Infrastructure (cloud, container orchestration, service mesh, CI/CD)
  - Observability (metrics, logging, tracing, alerting)
  - Data Platform (data lake/warehouse, BI/visualization)
- Rejected Technologies table
- Architecture Decision Records index

#### `project-scaffold/.bmad/team-conventions.md` (49 lines)
Coding and process standards maintained by Tech Lead.
- Version Control (branch strategy, naming, commit format, PR size, reviewers)
- Code Style (formatter, linter, naming conventions, max file/function lengths)
- API Conventions (REST/gRPC/GraphQL, URL format, error format, auth, pagination)
- Testing (coverage target, test naming, file location, test data)
- Database (migration tool, migration naming, repository pattern)
- Documentation (OpenAPI docs, inline comments, ADRs)
- Sprint / Process (sprint length, story points, Definition of Done, story size limits)

#### `project-scaffold/.bmad/domain-glossary.md` (40 lines)
Business domain terminology maintained by Business Analyst.
- Core Domain Terms (with definition, aliases, terms to avoid)
- Entity Names Canonical (with description and related entities)
- Process Terms (trigger and outcome)
- Status / State Values (allowed transitions)
- Abbreviations (full form and context)
- Ubiquitous Language Rules (enforces consistent terminology)

#### `project-scaffold/.bmad/handoff-log.md` (39 lines)
Running log of agent handoffs during project lifecycle.
- Template for each handoff entry:
  - From/To agents and phase
  - Completed Deliverables
  - Key Decisions Made
  - Open Questions for Next Agent
  - Risks / Watch-outs
  - Next Agent's Starting Point
- Log section for entries as work progresses

### 2. Installation & Project Scripts (3 files)

#### `scripts/install-global.sh` (377 lines, executable)
Production-quality global installation script with color output and error handling.

**Features:**
- Auto-detects 8 AI coding tools
- Supports: Claude Code, Cowork, Cursor, Windsurf, GitHub Copilot, Gemini CLI, OpenCode, Aider
- Color-coded output with ✓/✗ indicators
- `--dry-run` flag for testing
- Shared context prepending for Cursor/Windsurf
- Summary report of installed tools
- Comprehensive error handling

**Installation Paths by Tool:**
- Claude Code → `~/.claude/skills/`
- Cowork → `~/.skills/skills/`
- Cursor → `~/.cursor/rules/` (shared context prepended)
- Windsurf → `~/.windsurf/rules/` (shared context prepended)
- GitHub Copilot → `~/.github/copilot-instructions.md`
- Gemini CLI → `~/.gemini/GEMINI.md`
- OpenCode → `~/.opencode/instructions.md`
- Aider → `~/.aider.conventions.md`

#### `scripts/scaffold-project.sh` (235 lines, executable)
Creates new project with complete BMAD structure and templates.

**Features:**
- Accepts project name as argument
- Creates `.bmad/` with all template files
- Creates `docs/` directory structure (architecture/adr/, ux/)
- Creates `tests/fixtures/` directory
- Replaces `[Project Name]` placeholders
- Auto-detects AI tool and installs project-level skills
- `--force` flag to overwrite existing `.bmad/`
- Clear step-by-step output
- Final summary with next steps

**Usage:**
```bash
./scripts/scaffold-project.sh my-project [--force]
```

#### `scripts/update.sh` (309 lines, executable)
Updates globally installed BMAD agents from source with version tracking.

**Features:**
- Auto-detects installed tools (or accepts `--tools` flag)
- MD5 checksum comparison with previous install
- `--check-only` flag to preview updates
- `--tools` flag to update specific tools
- Tracks version history in `~/.bmad-version`
- Records: install timestamp, checksum, git commit hash
- Prevents redundant updates
- Color-coded output
- Comprehensive summary

**Usage:**
```bash
./scripts/update.sh [--tools tool1,tool2] [--check-only]
```

## Production Qualities

All scripts include:
- ✓ Shebang (`#!/bin/bash`)
- ✓ Color output (RED, GREEN, YELLOW, BLUE, CYAN)
- ✓ Error handling (`set -e`)
- ✓ Clear documentation headers and usage examples
- ✓ Detailed progress output with echo statements
- ✓ Proper variable scoping
- ✓ Directory creation with `mkdir -p`
- ✓ File existence checks
- ✓ Summary tables at end
- ✓ Proper exit codes (0 for success, 1 for errors)
- ✓ Production-quality error messages
- ✓ Permissions set to executable (chmod +x)

## Directory Structure

```
bmad-sdlc-agents/
├── project-scaffold/
│   └── .bmad/
│       ├── PROJECT-CONTEXT.md        (45 lines)
│       ├── tech-stack.md             (88 lines)
│       ├── team-conventions.md       (49 lines)
│       ├── domain-glossary.md        (40 lines)
│       └── handoff-log.md            (39 lines)
│
└── scripts/
    ├── install-global.sh             (377 lines, executable)
    ├── scaffold-project.sh           (235 lines, executable)
    └── update.sh                     (309 lines, executable)
```

**Total Lines:** 1,182  
**Total Files:** 8

## Usage Workflow

### 1. Install Globally
```bash
cd /sessions/upbeat-gracious-fermi/mnt/agent-skill-plugin/bmad-sdlc-agents
./scripts/install-global.sh
```
Detects all installed AI tools and deploys agents to their respective global directories.

### 2. Scaffold New Project
```bash
cd /path/to/new/project
/path/to/bmad-sdlc-agents/scripts/scaffold-project.sh "My Project Name"
```
Creates complete `.bmad/` structure with all templates and placeholder docs.

### 3. Fill In Project Details
Teams edit files in `.bmad/` directory to specify:
- Project context and phase
- Technology decisions
- Team conventions
- Domain terminology
- Track handoffs in handoff log

### 4. Update Global Installation
```bash
./scripts/update.sh
```
Re-runs installation for all tools, automatically detects changes, tracks version history.

## Key Design Decisions

1. **Template Format:** Markdown for readability and version control compatibility
2. **Placeholder System:** `[Project Name]` tokens replaced during scaffolding
3. **Tool Detection:** Auto-detection with fallback to explicit tool lists
4. **Color Output:** Visual feedback for debugging and user experience
5. **Version Tracking:** MD5 checksums and git commits for auditing
6. **Modular Agents:** Each AI tool gets appropriate installation method
7. **Dry-run Capabilities:** Testing without side effects
8. **Production Quality:** Error handling, validation, comprehensive logging

## Notes

- All scripts follow bash best practices and are POSIX-compatible
- Templates are designed to be edited by teams post-scaffolding
- Shared context (BMAD-SHARED-CONTEXT.md) prepended where appropriate
- Version file stored in `~/.bmad-version` tracks all installations
- No dependencies beyond standard POSIX utilities (bash, sed, mkdir, cp, etc.)
