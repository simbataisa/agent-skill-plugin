#!/bin/bash

# BMAD Project Scaffolder
# Initializes a new project with BMAD structure and templates
# Usage: ./scripts/scaffold-project.sh <project-name> [--force]

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

FORCE=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
SCAFFOLD_DIR="$BASE_DIR/project-scaffold"
HOOKS_PROJECT_DIR="$BASE_DIR/hooks/project"
RULES_DIR_SRC="$BASE_DIR/rules"
MCP_PROJECT_DIR="$BASE_DIR/mcp-configs/project"
COMMANDS_DIR="$BASE_DIR/commands"

# Parse arguments
PROJECT_NAME="${1:-}"

if [[ "$2" == "--force" ]]; then
    FORCE=true
fi

# Validate input
if [[ -z "$PROJECT_NAME" ]]; then
    echo -e "${RED}Error: Project name required${NC}"
    echo "Usage: ./scripts/scaffold-project.sh <project-name> [--force]"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  BMAD Project Scaffolder${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Project name: ${GREEN}$PROJECT_NAME${NC}"
echo ""

# Validate scaffold source exists
if [[ ! -d "$SCAFFOLD_DIR/.bmad" ]]; then
    echo -e "${RED}Error: Scaffold templates not found at $SCAFFOLD_DIR/.bmad${NC}"
    exit 1
fi

# Check if .bmad already exists
if [[ -d ".bmad" ]] && [[ "$FORCE" != true ]]; then
    echo -e "${YELLOW}⚠ Warning: .bmad directory already exists${NC}"
    echo "Use --force to overwrite, or choose a different project directory"
    exit 1
fi

if [[ "$FORCE" == true ]] && [[ -d ".bmad" ]]; then
    echo -e "${YELLOW}Removing existing .bmad directory...${NC}"
    rm -rf ".bmad"
fi

# ============================================================
# Create directory structure
# ============================================================
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p ".bmad/handoffs"
mkdir -p "docs/architecture/adr"
mkdir -p "docs/analysis"
mkdir -p "docs/stories"
mkdir -p "docs/testing"
mkdir -p "docs/ux"
mkdir -p "tests/fixtures"

echo "  ✓ .bmad/"
echo "  ✓ .bmad/handoffs/"
echo "  ✓ docs/architecture/adr"
echo "  ✓ docs/analysis/"
echo "  ✓ docs/stories/"
echo "  ✓ docs/testing/"
echo "  ✓ docs/ux/"
echo "  ✓ tests/fixtures/"
echo ""

# Merge BMAD hooks into an existing settings.json, backing up first.
# Usage: merge_settings_json <bmad_source.json> <target_settings.json>
merge_settings_json() {
    local src="$1"
    local dst="$2"

    if [[ ! -f "$dst" ]]; then
        cp "$src" "$dst"
        echo "  ✓ Created $(basename "$dst")"
        return
    fi

    # Back up the existing file
    local backup="${dst}.bak"
    cp "$dst" "$backup"
    echo "  ✓ Backed up existing $(basename "$dst") → $(basename "$backup")"

    # Merge hook arrays using Python
    python3 - "$src" "$dst" << 'PYEOF'
import json, sys

src_path, dst_path = sys.argv[1], sys.argv[2]

with open(src_path) as f:
    src = json.load(f)
with open(dst_path) as f:
    dst = json.load(f)

src_hooks = src.get("hooks", {})
dst_hooks = dst.setdefault("hooks", {})

for event, entries in src_hooks.items():
    if event not in dst_hooks:
        dst_hooks[event] = entries
    else:
        # Append only entries whose commands aren't already present
        existing_cmds = {
            h.get("command", "")
            for block in dst_hooks[event]
            for h in block.get("hooks", [])
        }
        for entry in entries:
            new_cmds = {h.get("command", "") for h in entry.get("hooks", [])}
            if not new_cmds.issubset(existing_cmds):
                dst_hooks[event].append(entry)

with open(dst_path, "w") as f:
    json.dump(dst, f, indent=2)
    f.write("\n")
PYEOF

    if [[ $? -eq 0 ]]; then
        echo "  ✓ Merged hooks into $(basename "$dst")"
    else
        # Restore backup on failure
        cp "$backup" "$dst"
        echo -e "  ${RED}✗ Merge failed — restored from backup. Manually merge: $src${NC}"
    fi
}

# Function to replace placeholder
replace_placeholder() {
    local file="$1"
    sed -i.bak "s/\[Project Name\]/$PROJECT_NAME/g" "$file"
    rm -f "${file}.bak"
}

# ============================================================
# Copy and customize .bmad template files
# ============================================================
echo -e "${BLUE}Scaffolding .bmad templates...${NC}"

for template_file in "$SCAFFOLD_DIR/.bmad"/*.md; do
    filename="$(basename "$template_file")"
    dest_file=".bmad/$filename"
    cp "$template_file" "$dest_file"
    replace_placeholder "$dest_file"
    echo "  ✓ $filename"
done

# Copy handoff template into handoffs/ subdirectory
if [[ -f "$SCAFFOLD_DIR/.bmad/handoffs/_template.md" ]]; then
    cp "$SCAFFOLD_DIR/.bmad/handoffs/_template.md" ".bmad/handoffs/_template.md"
    echo "  ✓ handoffs/_template.md"
fi

# Copy eval dashboard into .bmad/eval/
EVAL_SOURCE="$BASE_DIR/eval/bmad-agent-eval-dashboard.html"
if [[ -f "$EVAL_SOURCE" ]]; then
    mkdir -p ".bmad/eval"
    cp "$EVAL_SOURCE" ".bmad/eval/bmad-agent-eval-dashboard.html"
    echo "  ✓ .bmad/eval/bmad-agent-eval-dashboard.html"
fi

echo ""

# ============================================================
# Detect current AI tool
# ============================================================
echo -e "${BLUE}Detecting AI coding tool...${NC}"

DETECTED_TOOL=""

if [[ -d "$HOME/.claude" ]] || command -v claude &> /dev/null; then
    DETECTED_TOOL="claude"
    echo -e "${GREEN}✓ Claude Code detected${NC}"
elif [[ -d "$HOME/.codex" ]] || command -v codex &> /dev/null; then
    DETECTED_TOOL="codex"
    echo -e "${GREEN}✓ Codex CLI detected${NC}"
elif [[ -d "$HOME/.kiro" ]] || command -v kiro &> /dev/null; then
    DETECTED_TOOL="kiro"
    echo -e "${GREEN}✓ Kiro detected${NC}"
elif [[ -d "$HOME/.cursor" ]] || command -v cursor &> /dev/null; then
    DETECTED_TOOL="cursor"
    echo -e "${GREEN}✓ Cursor detected${NC}"
elif [[ -d "$HOME/.windsurf" ]]; then
    DETECTED_TOOL="windsurf"
    echo -e "${GREEN}✓ Windsurf detected${NC}"
elif [[ -d "$HOME/.skills" ]]; then
    DETECTED_TOOL="cowork"
    echo -e "${GREEN}✓ Cowork detected${NC}"
else
    echo -e "${YELLOW}⚠ No AI tool detected${NC}"
    DETECTED_TOOL="none"
fi

echo ""

# ============================================================
# Install project-level agent skills/rules
# ============================================================
if [[ "$DETECTED_TOOL" != "none" ]]; then
    echo -e "${BLUE}Installing project-level agents...${NC}"

    case "$DETECTED_TOOL" in
        claude)
            PROJECT_SKILLS=".claude/skills"
            PROJECT_COMMANDS=".claude/commands"
            mkdir -p "$PROJECT_SKILLS"
            mkdir -p "$PROJECT_COMMANDS"

            # Remove legacy installs (flat .md files and bmad-* prefixed folders)
            for agent_dir in "$BASE_DIR/agents"/*; do
                if [[ -d "$agent_dir" ]]; then
                    agent_name="$(basename "$agent_dir")"
                    flat_file="$PROJECT_SKILLS/${agent_name}.md"
                    if [[ -f "$flat_file" ]]; then
                        rm -f "$flat_file"
                        echo "  ✓ Removed legacy flat file: ${agent_name}.md"
                    fi
                fi
            done
            for legacy in "$PROJECT_SKILLS"/bmad-*/; do
                if [[ -d "$legacy" ]]; then
                    rm -rf "$legacy"
                    echo "  ✓ Removed legacy skill folder: $(basename "$legacy")"
                fi
            done

            # Copy agents as folder-based skills: .claude/skills/<name>/SKILL.md
            for agent_dir in "$BASE_DIR/agents"/*; do
                if [[ -d "$agent_dir" ]]; then
                    agent_name="$(basename "$agent_dir")"
                    mkdir -p "$PROJECT_SKILLS/$agent_name"
                    cp "$agent_dir/SKILL.md" "$PROJECT_SKILLS/$agent_name/SKILL.md"
                    echo "  ✓ agent: $agent_name"
                fi
            done

            # Copy slash commands
            if [[ -d "$COMMANDS_DIR" ]]; then
                for cmd_file in "$COMMANDS_DIR"/*.md; do
                    if [[ -f "$cmd_file" ]]; then
                        cp "$cmd_file" "$PROJECT_COMMANDS/$(basename "$cmd_file")"
                        echo "  ✓ command: $(basename "$cmd_file" .md)"
                    fi
                done
            fi

            echo "  Agents:   $PROJECT_SKILLS/"
            echo "  Commands: $PROJECT_COMMANDS/"
            ;;

        codex)
            PROJECT_SKILLS=".codex/skills"
            PROJECT_PROMPTS=".codex/prompts"
            mkdir -p "$PROJECT_SKILLS"
            mkdir -p "$PROJECT_PROMPTS"

            # Remove legacy bmad-* prefixed skill folders
            for legacy in "$PROJECT_SKILLS"/bmad-*/; do
                if [[ -d "$legacy" ]]; then
                    rm -rf "$legacy"
                    echo "  ✓ Removed legacy skill folder: $(basename "$legacy")"
                fi
            done

            # Codex skills are folder-based: .codex/skills/<name>/SKILL.md
            for agent_dir in "$BASE_DIR/agents"/*; do
                if [[ -d "$agent_dir" ]]; then
                    agent_name="$(basename "$agent_dir")"
                    mkdir -p "$PROJECT_SKILLS/$agent_name"
                    cp "$agent_dir/SKILL.md" "$PROJECT_SKILLS/$agent_name/SKILL.md"
                    # Copy references/ and templates/ if they exist
                    if [[ -d "$agent_dir/references" ]]; then
                        cp -r "$agent_dir/references" "$PROJECT_SKILLS/$agent_name/"
                    fi
                    if [[ -d "$agent_dir/templates" ]]; then
                        cp -r "$agent_dir/templates" "$PROJECT_SKILLS/$agent_name/"
                    fi
                    echo "  ✓ skill: $agent_name"
                fi
            done

            # Copy slash commands to .codex/prompts/
            if [[ -d "$COMMANDS_DIR" ]]; then
                for cmd_file in "$COMMANDS_DIR"/*.md; do
                    if [[ -f "$cmd_file" ]]; then
                        cp "$cmd_file" "$PROJECT_PROMPTS/$(basename "$cmd_file")"
                        echo "  ✓ prompt: $(basename "$cmd_file" .md)"
                    fi
                done
            fi

            echo "  Skills:  $PROJECT_SKILLS/"
            echo "  Prompts: $PROJECT_PROMPTS/"
            ;;

        kiro)
            PROJECT_SKILLS=".kiro/skills"
            PROJECT_STEERING=".kiro/steering"
            mkdir -p "$PROJECT_SKILLS"
            mkdir -p "$PROJECT_STEERING"

            # Remove legacy bmad-* prefixed skill folders
            for legacy in "$PROJECT_SKILLS"/bmad-*/; do
                if [[ -d "$legacy" ]]; then
                    rm -rf "$legacy"
                    echo "  ✓ Removed legacy skill folder: $(basename "$legacy")"
                fi
            done

            # Skills are folder-based: .kiro/skills/<name>/SKILL.md
            for agent_dir in "$BASE_DIR/agents"/*; do
                if [[ -d "$agent_dir" ]]; then
                    agent_name="$(basename "$agent_dir")"
                    mkdir -p "$PROJECT_SKILLS/$agent_name"
                    cp "$agent_dir/SKILL.md" "$PROJECT_SKILLS/$agent_name/SKILL.md"
                    if [[ -d "$agent_dir/references" ]]; then
                        cp -r "$agent_dir/references" "$PROJECT_SKILLS/$agent_name/"
                    fi
                    if [[ -d "$agent_dir/templates" ]]; then
                        cp -r "$agent_dir/templates" "$PROJECT_SKILLS/$agent_name/"
                    fi
                    echo "  ✓ skill: $agent_name"
                fi
            done

            # Commands → steering files with inclusion: manual (become /slash-commands)
            if [[ -d "$COMMANDS_DIR" ]]; then
                for cmd_file in "$COMMANDS_DIR"/*.md; do
                    if [[ -f "$cmd_file" ]]; then
                        cmd_name="$(basename "$cmd_file" .md)"
                        desc=$(head -5 "$cmd_file" | grep "^description:" | sed 's/^description: *//')
                        {
                            echo "---"
                            echo "description: ${desc:-BMAD command: $cmd_name}"
                            echo "inclusion: manual"
                            echo "---"
                            echo ""
                            awk '/^---$/{n++} n>=2{if(n==2 && /^---$/){n++;next}; print}' "$cmd_file"
                        } > "$PROJECT_STEERING/$cmd_name.md"
                        echo "  ✓ command: $cmd_name (→ /$cmd_name)"
                    fi
                done
            fi

            echo "  Skills:   $PROJECT_SKILLS/"
            echo "  Steering: $PROJECT_STEERING/"
            ;;

        cursor)
            PROJECT_RULES=".cursor/rules"
            mkdir -p "$PROJECT_RULES"

            for agent_dir in "$BASE_DIR/agents"/*; do
                if [[ -d "$agent_dir" ]]; then
                    agent_name="$(basename "$agent_dir")"
                    {
                        cat "$BASE_DIR/shared/BMAD-SHARED-CONTEXT.md"
                        echo ""
                        cat "$agent_dir/SKILL.md"
                    } > "$PROJECT_RULES/${agent_name}.md"
                    echo "  ✓ agent: $agent_name"
                fi
            done

            # Copy Cursor project-specific .mdc rules
            if [[ -d "$RULES_DIR_SRC/cursor/project" ]]; then
                for rule_file in "$RULES_DIR_SRC/cursor/project"/*.mdc; do
                    if [[ -f "$rule_file" ]]; then
                        cp "$rule_file" "$PROJECT_RULES/$(basename "$rule_file")"
                        echo "  ✓ rule: $(basename "$rule_file")"
                    fi
                done
            fi

            echo "  Rules: $PROJECT_RULES/"
            ;;

        windsurf)
            PROJECT_RULES=".windsurf/rules"
            mkdir -p "$PROJECT_RULES"

            for agent_dir in "$BASE_DIR/agents"/*; do
                if [[ -d "$agent_dir" ]]; then
                    agent_name="$(basename "$agent_dir")"
                    {
                        cat "$BASE_DIR/shared/BMAD-SHARED-CONTEXT.md"
                        echo ""
                        cat "$agent_dir/SKILL.md"
                    } > "$PROJECT_RULES/${agent_name}.md"
                    echo "  ✓ agent: $agent_name"
                fi
            done

            # Copy Windsurf project rules
            if [[ -d "$RULES_DIR_SRC/windsurf/project" ]]; then
                for rule_file in "$RULES_DIR_SRC/windsurf/project"/*.md; do
                    if [[ -f "$rule_file" ]]; then
                        cp "$rule_file" "$PROJECT_RULES/$(basename "$rule_file")"
                        echo "  ✓ rule: $(basename "$rule_file")"
                    fi
                done
            fi

            echo "  Rules: $PROJECT_RULES/"
            ;;

        cowork)
            PROJECT_SKILLS=".skills/skills"
            mkdir -p "$PROJECT_SKILLS"

            # Remove legacy installs (flat .md files and bmad-* prefixed folders)
            for agent_dir in "$BASE_DIR/agents"/*; do
                if [[ -d "$agent_dir" ]]; then
                    agent_name="$(basename "$agent_dir")"
                    flat_file="$PROJECT_SKILLS/${agent_name}.md"
                    if [[ -f "$flat_file" ]]; then
                        rm -f "$flat_file"
                        echo "  ✓ Removed legacy flat file: ${agent_name}.md"
                    fi
                fi
            done
            for legacy in "$PROJECT_SKILLS"/bmad-*/; do
                if [[ -d "$legacy" ]]; then
                    rm -rf "$legacy"
                    echo "  ✓ Removed legacy skill folder: $(basename "$legacy")"
                fi
            done

            # Copy agents as folder-based skills: .skills/skills/<name>/SKILL.md
            for agent_dir in "$BASE_DIR/agents"/*; do
                if [[ -d "$agent_dir" ]]; then
                    agent_name="$(basename "$agent_dir")"
                    mkdir -p "$PROJECT_SKILLS/$agent_name"
                    cp "$agent_dir/SKILL.md" "$PROJECT_SKILLS/$agent_name/SKILL.md"
                    echo "  ✓ agent: $agent_name"
                fi
            done

            echo "  Skills: $PROJECT_SKILLS/"
            ;;
    esac

    echo ""
fi

# ============================================================
# Install project-level hooks (Claude Code only)
# ============================================================
if [[ "$DETECTED_TOOL" == "claude" ]] && [[ -d "$HOOKS_PROJECT_DIR" ]]; then
    echo -e "${BLUE}Installing project-level hooks...${NC}"

    PROJ_HOOKS_DEST=".claude"
    mkdir -p "$PROJ_HOOKS_DEST/hooks"

    # Merge project hooks into .claude/settings.json (backs up first)
    if [[ -f "$HOOKS_PROJECT_DIR/settings.json" ]]; then
        merge_settings_json "$HOOKS_PROJECT_DIR/settings.json" "$PROJ_HOOKS_DEST/settings.json"
        # Remove any duplicates introduced by previous merges
        python3 "$SCRIPT_DIR/clean-duplicate-hooks.py" "$PROJ_HOOKS_DEST/settings.json" 2>/dev/null || true
    fi

    # Copy hook scripts
    if [[ -d "$HOOKS_PROJECT_DIR/scripts" ]]; then
        cp -r "$HOOKS_PROJECT_DIR/scripts/." "$PROJ_HOOKS_DEST/hooks/"
        chmod +x "$PROJ_HOOKS_DEST/hooks/"*.sh 2>/dev/null || true
        echo "  ✓ .claude/hooks/ (project scripts)"
    fi

    echo "  Hooks: $PROJ_HOOKS_DEST/hooks/"
    echo ""
fi

# ============================================================
# Copy project MCP config template
# ============================================================
if [[ -d "$MCP_PROJECT_DIR" ]]; then
    echo -e "${BLUE}MCP project configs available:${NC}"
    echo "  Source: $MCP_PROJECT_DIR/"
    echo ""
    echo "  Review and add to your project's MCP settings:"
    for cfg_file in "$MCP_PROJECT_DIR"/*.json; do
        if [[ -f "$cfg_file" ]]; then
            echo "    • $(basename "$cfg_file")"
        fi
    done
    echo ""
    echo "  See $BASE_DIR/mcp-configs/README.md for merge instructions."
    echo ""
fi

# ============================================================
# Generate tool-specific auto-load instruction file
# ============================================================
echo -e "${BLUE}Generating BMAD context auto-load instruction file...${NC}"

BMAD_CONTEXT_BLOCK="## Active Methodology: BMAD SDLC

This project uses the **BMAD (Breakthrough Method of Agile AI-Driven Development)** methodology.
BMAD agents are the authoritative source of truth for all analysis, design, and implementation work.

**When multiple skills or agents are installed:**
- Always prefer BMAD agents invoked via slash commands (\`/business-analyst\`, \`/solution-architect\`, etc.)
- BMAD artifacts belong **only** in the paths defined in \`.bmad/PROJECT-CONTEXT.md\` (Artifacts Index section)
- Do NOT use non-BMAD skills (e.g. superpowers, personas, generic planners) for this project's deliverables
- Use \`/handoff\` to log agent transitions — this creates a numbered child file in \`.bmad/handoffs/\`
- Use \`/bmad-status\` to check project phase and artifact status

## BMAD Project Context

At the start of every conversation, read these files to understand this project:

- \`.bmad/PROJECT-CONTEXT.md\` — vision, goals, stakeholders, constraints
- \`.bmad/tech-stack.md\` — technology stack, versions, dependencies
- \`.bmad/team-conventions.md\` — code style, naming conventions, patterns
- \`.bmad/domain-glossary.md\` — business domain terminology
- \`.bmad/handoff-log.md\` — agent handoff index (full records in \`.bmad/handoffs/\`)

Apply all conventions from \`.bmad/team-conventions.md\` when writing or reviewing code."

case "$DETECTED_TOOL" in
    claude)
        INSTRUCTION_FILE="CLAUDE.md"
        AGENT_TABLE="
## Available BMAD Agents (slash commands)

| Command | Role |
|---------|------|
| \`/business-analyst\` | Discovery, stakeholder analysis, project brief |
| \`/product-owner\` | PRD, backlog, user stories |
| \`/solution-architect\` | System design, APIs, ADRs |
| \`/enterprise-architect\` | Cloud infra, compliance, CI/CD |
| \`/ux-designer\` | Wireframes, design system, accessibility |
| \`/tech-lead\` | Orchestration, code review, risk |
| \`/tester-qe\` | Test strategy, quality gates |
| \`/backend-engineer\` | APIs, services, data layers |
| \`/frontend-engineer\` | React/TypeScript, components, a11y |
| \`/mobile-engineer\` | iOS/Android, native architecture |"

        if [[ -f "$INSTRUCTION_FILE" ]]; then
            # Append to existing CLAUDE.md
            {
                echo ""
                echo "$BMAD_CONTEXT_BLOCK"
                echo "$AGENT_TABLE"
            } >> "$INSTRUCTION_FILE"
            echo "  ✓ Appended to existing $INSTRUCTION_FILE"
        else
            {
                echo "# $PROJECT_NAME"
                echo ""
                echo "$BMAD_CONTEXT_BLOCK"
                echo "$AGENT_TABLE"
            } > "$INSTRUCTION_FILE"
            echo "  ✓ Created $INSTRUCTION_FILE"
        fi
        ;;

    codex)
        INSTRUCTION_FILE="AGENTS.md"
        AGENT_TABLE="
## Available BMAD Agents (Codex skills)

| Skill (\$ invoke) | Role |
|-------------------|------|
| \`\$business-analyst\` | Discovery, stakeholder analysis, project brief |
| \`\$product-owner\` | PRD, backlog, user stories |
| \`\$solution-architect\` | System design, APIs, ADRs |
| \`\$enterprise-architect\` | Cloud infra, compliance, CI/CD |
| \`\$ux-designer\` | Wireframes, design system, accessibility |
| \`\$tech-lead\` | Orchestration, code review, risk |
| \`\$tester-qe\` | Test strategy, quality gates |
| \`\$backend-engineer\` | APIs, services, data layers |
| \`\$frontend-engineer\` | React/TypeScript, components, a11y |
| \`\$mobile-engineer\` | iOS/Android, native architecture |

## Available BMAD Commands (slash commands)

| Command | Role |
|---------|------|
| \`/bmad-status\` | Show project phase & artifact status |
| \`/handoff\` | Log an agent handoff |
| \`/new-story\` | Create a new user story |
| \`/new-adr\` | Record an architecture decision |
| \`/new-epic\` | Plan a full 4-phase epic |
| \`/sprint-plan\` | Generate a capacity-matched sprint |"

        if [[ -f "$INSTRUCTION_FILE" ]]; then
            {
                echo ""
                echo "$BMAD_CONTEXT_BLOCK"
                echo "$AGENT_TABLE"
            } >> "$INSTRUCTION_FILE"
            echo "  ✓ Appended to existing $INSTRUCTION_FILE"
        else
            {
                echo "# $PROJECT_NAME"
                echo ""
                echo "$BMAD_CONTEXT_BLOCK"
                echo "$AGENT_TABLE"
            } > "$INSTRUCTION_FILE"
            echo "  ✓ Created $INSTRUCTION_FILE"
        fi
        ;;

    kiro)
        # Kiro reads AGENTS.md natively AND .kiro/steering/ files
        # Generate both: AGENTS.md at project root + auto-included steering file
        INSTRUCTION_FILE="AGENTS.md"
        AGENT_TABLE="
## Available BMAD Agents (Kiro skills)

Skills activate by description match. You can also invoke commands with / prefix:

| Skill | Role |
|-------|------|
| business-analyst | Discovery, stakeholder analysis, project brief |
| product-owner | PRD, backlog, user stories |
| solution-architect | System design, APIs, ADRs |
| enterprise-architect | Cloud infra, compliance, CI/CD |
| ux-designer | Wireframes, design system, accessibility |
| tech-lead | Orchestration, code review, risk |
| tester-qe | Test strategy, quality gates |
| backend-engineer | APIs, services, data layers |
| frontend-engineer | React/TypeScript, components, a11y |
| mobile-engineer | iOS/Android, native architecture |

## Available BMAD Commands (/ slash commands)

| Command | Role |
|---------|------|
| \`/bmad-status\` | Show project phase & artifact status |
| \`/handoff\` | Log an agent handoff |
| \`/new-story\` | Create a new user story |
| \`/new-adr\` | Record an architecture decision |
| \`/new-epic\` | Plan a full 4-phase epic |
| \`/sprint-plan\` | Generate a capacity-matched sprint |"

        # Create AGENTS.md at project root (Kiro reads this natively)
        if [[ -f "$INSTRUCTION_FILE" ]]; then
            {
                echo ""
                echo "$BMAD_CONTEXT_BLOCK"
                echo "$AGENT_TABLE"
            } >> "$INSTRUCTION_FILE"
            echo "  ✓ Appended to existing $INSTRUCTION_FILE"
        else
            {
                echo "# $PROJECT_NAME"
                echo ""
                echo "$BMAD_CONTEXT_BLOCK"
                echo "$AGENT_TABLE"
            } > "$INSTRUCTION_FILE"
            echo "  ✓ Created $INSTRUCTION_FILE"
        fi

        # Also create auto-included steering file for belt-and-suspenders
        mkdir -p ".kiro/steering"
        {
            echo "---"
            echo "description: BMAD project context — auto-loaded at session start"
            echo "inclusion: auto"
            echo "---"
            echo ""
            echo "$BMAD_CONTEXT_BLOCK"
        } > ".kiro/steering/bmad-project-context.md"
        echo "  ✓ Created .kiro/steering/bmad-project-context.md"
        ;;

    cursor)
        INSTRUCTION_FILE=".cursor/rules/001-project-context.mdc"
        mkdir -p ".cursor/rules"
        {
            echo "---"
            echo "description: BMAD project context — load at the start of every conversation"
            echo "alwaysApply: true"
            echo "---"
            echo ""
            echo "$BMAD_CONTEXT_BLOCK"
        } > "$INSTRUCTION_FILE"
        echo "  ✓ Created $INSTRUCTION_FILE"
        ;;

    windsurf)
        INSTRUCTION_FILE=".windsurfrules"
        if [[ -f "$INSTRUCTION_FILE" ]]; then
            {
                echo ""
                echo "$BMAD_CONTEXT_BLOCK"
            } >> "$INSTRUCTION_FILE"
            echo "  ✓ Appended to existing $INSTRUCTION_FILE"
        else
            echo "$BMAD_CONTEXT_BLOCK" > "$INSTRUCTION_FILE"
            echo "  ✓ Created $INSTRUCTION_FILE"
        fi
        ;;

    cowork)
        # Cowork reads CLAUDE.md when present
        INSTRUCTION_FILE="CLAUDE.md"
        if [[ -f "$INSTRUCTION_FILE" ]]; then
            {
                echo ""
                echo "$BMAD_CONTEXT_BLOCK"
            } >> "$INSTRUCTION_FILE"
            echo "  ✓ Appended to existing $INSTRUCTION_FILE"
        else
            {
                echo "# $PROJECT_NAME"
                echo ""
                echo "$BMAD_CONTEXT_BLOCK"
            } > "$INSTRUCTION_FILE"
            echo "  ✓ Created $INSTRUCTION_FILE"
        fi
        ;;

    none)
        # Create all instruction files so the user can commit whichever they need
        echo "  Creating all tool instruction files (no tool detected)..."
        mkdir -p ".cursor/rules" ".github"

        # CLAUDE.md
        {
            echo "# $PROJECT_NAME"
            echo ""
            echo "$BMAD_CONTEXT_BLOCK"
        } > "CLAUDE.md"
        echo "  ✓ CLAUDE.md"

        # .cursor/rules/001-project-context.mdc
        {
            echo "---"
            echo "description: BMAD project context — load at the start of every conversation"
            echo "alwaysApply: true"
            echo "---"
            echo ""
            echo "$BMAD_CONTEXT_BLOCK"
        } > ".cursor/rules/001-project-context.mdc"
        echo "  ✓ .cursor/rules/001-project-context.mdc"

        # .windsurfrules
        echo "$BMAD_CONTEXT_BLOCK" > ".windsurfrules"
        echo "  ✓ .windsurfrules"

        # .github/copilot-instructions.md
        echo "$BMAD_CONTEXT_BLOCK" > ".github/copilot-instructions.md"
        echo "  ✓ .github/copilot-instructions.md"

        # GEMINI.md
        echo "$BMAD_CONTEXT_BLOCK" > "GEMINI.md"
        echo "  ✓ GEMINI.md"

        # AGENTS.md (OpenCode + Codex CLI)
        echo "$BMAD_CONTEXT_BLOCK" > "AGENTS.md"
        echo "  ✓ AGENTS.md"
        ;;
esac

echo ""

# ============================================================
# Create placeholder documentation files
# ============================================================
echo -e "${BLUE}Creating placeholder documentation...${NC}"

touch "docs/project-brief.md"
echo "  ✓ docs/project-brief.md"

touch "docs/prd.md"
echo "  ✓ docs/prd.md"

touch "docs/architecture/solution-architecture.md"
echo "  ✓ docs/architecture/solution-architecture.md"

touch "docs/architecture/enterprise-architecture.md"
echo "  ✓ docs/architecture/enterprise-architecture.md"

touch "docs/ux/design-system.md"
echo "  ✓ docs/ux/design-system.md"

touch "docs/architecture/adr/ADR-INDEX.md"
echo "  ✓ docs/architecture/adr/ADR-INDEX.md"

touch "docs/analysis/.gitkeep"
echo "  ✓ docs/analysis/ (BA impact & requirements analyses)"

mkdir -p "docs/testing/bugs"
touch "docs/testing/bugs/.gitkeep"
echo "  ✓ docs/testing/bugs/"

mkdir -p "docs/testing/hotfixes"
touch "docs/testing/hotfixes/.gitkeep"
echo "  ✓ docs/testing/hotfixes/"

echo ""

# ============================================================
# Summary
# ============================================================
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Scaffolding Complete${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo "Created files and directories:"
echo "  • .bmad/PROJECT-CONTEXT.md     — project orientation"
echo "  • .bmad/tech-stack.md          — technology decisions"
echo "  • .bmad/team-conventions.md    — coding standards"
echo "  • .bmad/domain-glossary.md     — domain terminology"
echo "  • .bmad/handoff-log.md         — agent handoff tracking"
echo "  • .bmad/eval/bmad-agent-eval-dashboard.html — productivity evaluation dashboard"
echo "  • docs/analysis/               — BA feature impact & requirements analyses"
echo "  • docs/                        — documentation structure"
if [[ "$DETECTED_TOOL" != "none" ]]; then
    echo "  • Project-level agent configurations"
fi
if [[ "$DETECTED_TOOL" == "claude" ]] && [[ -d "$HOOKS_PROJECT_DIR" ]]; then
    echo "  • .claude/hooks/               — project-level hooks"
fi
case "$DETECTED_TOOL" in
    claude|cowork) echo "  • CLAUDE.md                    — auto-loads .bmad/ context on session start" ;;
    codex)         echo "  • AGENTS.md                    — auto-loads .bmad/ context on session start" ;;
    kiro)          echo "  • AGENTS.md + .kiro/steering/  — auto-loads .bmad/ context on session start" ;;
    cursor)        echo "  • .cursor/rules/001-project-context.mdc — auto-loads .bmad/ context" ;;
    windsurf)      echo "  • .windsurfrules               — auto-loads .bmad/ context on session start" ;;
    none)          echo "  • CLAUDE.md / AGENTS.md / .windsurfrules / .cursor/rules/ / GEMINI.md — all tool instruction files" ;;
esac
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "  1. Edit .bmad/PROJECT-CONTEXT.md to fill in project details"
echo "  2. Edit .bmad/tech-stack.md with your stack decisions"
echo "  3. Commit all .bmad/, .claude/, .codex/, and instruction files to version control"
echo "     (CLAUDE.md / AGENTS.md / .windsurfrules / .cursor/rules/ — whichever your team uses)"
echo "  4. Teams review .bmad/*.md files before starting work"
echo ""
case "$DETECTED_TOOL" in
    codex)
        echo "Useful commands (Codex CLI):"
        echo "  \$business-analyst — invoke Business Analyst skill"
        echo "  \$solution-architect — invoke Solution Architect skill"
        echo "  /bmad-status     — show project phase & artifact status"
        echo "  /handoff         — log an agent handoff"
        echo "  /new-story       — create a new user story"
        echo "  /new-adr         — record an architecture decision"
        ;;
    kiro)
        echo "Useful commands (Kiro):"
        echo "  Skills activate by description match (e.g. ask for a 'project brief')"
        echo "  /bmad-status     — show project phase & artifact status"
        echo "  /handoff         — log an agent handoff"
        echo "  /new-story       — create a new user story"
        echo "  /new-adr         — record an architecture decision"
        ;;
    *)
        echo "Useful slash commands (Claude Code):"
        echo "  /bmad-status    — show project phase & artifact status"
        echo "  /new-story      — create a new user story"
        echo "  /new-adr        — record an architecture decision"
        echo "  /handoff        — log an agent handoff"
        echo "  /new-epic       — plan a full 4-phase epic"
        echo "  /sprint-plan    — generate a capacity-matched sprint"
        ;;
esac
echo ""
echo "For more info, see:"
echo "  • .bmad/PROJECT-CONTEXT.md (orientation)"
echo "  • .bmad/handoff-log.md (track agent work)"
echo "  • $BASE_DIR/README.md (full documentation)"
echo ""

exit 0
