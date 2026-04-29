#!/bin/bash

# BMAD Global Install Script
# Deploys BMAD agents to all detected AI coding tools
# Usage: ./scripts/install-global.sh [--dry-run]

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DRY_RUN=false
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
SHARED_CONTEXT="$BASE_DIR/shared/BMAD-SHARED-CONTEXT.md"
AGENTS_DIR="$BASE_DIR/agents"
HOOKS_DIR="$BASE_DIR/hooks/global"
COMMANDS_DIR="$BASE_DIR/commands"
RULES_DIR="$BASE_DIR/rules"
MCP_CONFIGS_DIR="$BASE_DIR/mcp-configs/global"

# Parse arguments
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Track results
INSTALLED_TOOLS=()
SKIPPED_TOOLS=()

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  BMAD Global Agent Installer${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Validate source files
if [[ ! -f "$SHARED_CONTEXT" ]]; then
    echo -e "${RED}✗ Error: Shared context not found at $SHARED_CONTEXT${NC}"
    exit 1
fi

if [[ ! -d "$AGENTS_DIR" ]]; then
    echo -e "${RED}✗ Error: Agents directory not found at $AGENTS_DIR${NC}"
    exit 1
fi

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}[DRY RUN MODE]${NC}"
    echo ""
fi

# Function to copy file
copy_file() {
    local src="$1"
    local dst="$2"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] cp $src -> $dst"
    else
        mkdir -p "$(dirname "$dst")"
        cp "$src" "$dst"
    fi
}

# Function to write file
write_file() {
    local content="$1"
    local dst="$2"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] write -> $dst"
    else
        mkdir -p "$(dirname "$dst")"
        echo "$content" > "$dst"
    fi
}

# Function to append file
append_file() {
    local src="$1"
    local dst="$2"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] append $src -> $dst"
    else
        mkdir -p "$(dirname "$dst")"
        if [[ ! -f "$dst" ]]; then
            cp "$src" "$dst"
        else
            cat "$src" >> "$dst"
        fi
    fi
}

# ============================================================
# Sub-agent namespace helpers
# ============================================================
# Sub-agents live as sibling .md files alongside SKILL.md in each agent folder
# (mirrors the superpowers pattern: skills/<name>/SKILL.md + sibling cmd files):
#   agents/<agent>/SKILL.md          ← main skill (uppercase, skipped by walker)
#   agents/<agent>/<cmd>.md          ← sub-agent commands (lowercase siblings)
#   agents/<agent>/references/       ← supporting reference docs
#   agents/<agent>/templates/        ← output templates
#
# This creates the <agent>:<sub-command> namespace across all AI coders:
#   Claude Code  → /agent:cmd        (native subdir commands)
#   Gemini CLI   → skills/<agent>/   (folder copy via contextFileName)
#   Codex        → skills/<agent>/<cmd>.md
#   Cursor/Windsurf/Trae/Kiro/Others → adapted per tool

# Walk agents/<agent>/<cmd>.md (non-SKILL.md siblings) and call a handler for each.
# Handler receives: agent_name  cmd_name  src_file  [extra_args...]
# Usage: walk_sub_agents <handler_fn> [extra_args...]
walk_sub_agents() {
    local handler="$1"
    shift
    for agent_dir in "$AGENTS_DIR"/*/; do
        if [[ -d "$agent_dir" ]]; then
            local agent_name="$(basename "$agent_dir")"
            for cmd_file in "$agent_dir"/*.md; do
                if [[ -f "$cmd_file" ]]; then
                    local cmd_name="$(basename "$cmd_file" .md)"
                    [[ "$cmd_name" == "SKILL" ]] && continue   # skip main skill file
                    "$handler" "$agent_name" "$cmd_name" "$cmd_file" "$@"
                fi
            done
        fi
    done
}

# ============================================================
# Command format adapters
# ============================================================
# Claude Code commands use YAML frontmatter (description, argument-hint) + markdown.
# These adapters transform that canonical format for other tools.

# Strip YAML frontmatter, return only the markdown body.
# Uses awk for BSD/macOS + GNU/Linux compatibility (sed semicolons after } fail on BSD).
strip_frontmatter() {
    local file="$1"
    # Count --- delimiters: skip lines where the delimiter count is exactly 1
    # f==0 → before any ---  (print)
    # f==1 → inside frontmatter (skip)
    # f>=2 → after closing --- (print)
    awk '/^---$/{f++; next} f!=1{print}' "$file"
}

# Extract a YAML frontmatter field value.
# Uses awk for BSD/macOS + GNU/Linux compatibility.
extract_frontmatter_field() {
    local file="$1"
    local field="$2"
    awk -v field="${field}:" '
        /^---$/ { fm++; next }
        fm==1 && index($0, field)==1 {
            sub("^" field "[[:space:]]*", "")
            gsub(/^["'"'"']|["'"'"']$/, "")
            print
        }
    ' "$file"
}

# ── Adapter signatures ────────────────────────────────────────────────────────
# All adapters receive:  agent_name  cmd_name  src_file  dest_base_dir
# They build the namespaced destination path internally.
# Invocation shorthand (via walk_sub_agents):
#   walk_sub_agents adapt_for_cursor  "$CURSOR_COMMANDS"
# ─────────────────────────────────────────────────────────────────────────────

# Claude Code / Cowork / OpenCode / GitHub Copilot:
# Native YAML frontmatter. Preserve subdirectory → /agent:cmd namespace.
# dest: <base>/<agent>/<cmd>.md  →  Claude Code reads as /agent:cmd
install_native() {
    local agent="$1" cmd="$2" src="$3" base="$4"
    local dst="$base/$agent/$cmd.md"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] /$agent:$cmd -> $dst"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
}

# Codex CLI: YAML-compatible, replace $ARGUMENTS -> $1
install_codex() {
    local agent="$1" cmd="$2" src="$3" base="$4"
    local dst="$base/$agent/$cmd.md"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] codex /$agent:$cmd -> $dst"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    sed 's/\$ARGUMENTS/$1/g' "$src" > "$dst"
}

# Cursor: strip YAML frontmatter, add # /agent:cmd header
adapt_for_cursor() {
    local agent="$1" cmd="$2" src="$3" base="$4"
    local dst="$base/$agent/$cmd.md"
    local description arg_hint
    description="$(extract_frontmatter_field "$src" "description")"
    arg_hint="$(extract_frontmatter_field "$src" "argument-hint")"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] cursor /$agent:$cmd -> $dst"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    {
        echo "# /${agent}:${cmd}"
        [[ -n "$description" ]] && echo "" && echo "$description"
        [[ -n "$arg_hint"    ]] && echo "" && echo "**Usage:** \`/${agent}:${cmd} ${arg_hint}\`"
        echo ""
        strip_frontmatter "$src"
    } > "$dst"
}

# Windsurf: rules format, one file per command under bmad-commands/<agent>/
adapt_for_windsurf() {
    local agent="$1" cmd="$2" src="$3" base="$4"
    local dst="$base/$agent/$cmd.md"
    local description arg_hint
    description="$(extract_frontmatter_field "$src" "description")"
    arg_hint="$(extract_frontmatter_field "$src" "argument-hint")"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] windsurf /$agent:$cmd -> $dst"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    {
        echo "# Rule: ${agent}:${cmd}"
        echo ""
        echo "**Trigger:** When the user asks to run \`${agent}:${cmd}\` or \"${cmd//-/ }\"."
        [[ -n "$description" ]] && echo "" && echo "$description"
        [[ -n "$arg_hint"    ]] && echo "" && echo "**Arguments:** ${arg_hint}"
        echo ""
        strip_frontmatter "$src"
    } > "$dst"
}

# Trae IDE: same rules-based paradigm as Windsurf; one file per command under bmad-commands/<agent>/
# Trae reads markdown under ~/.trae/rules/ (user) and .trae/rules/ (project) as always-on guidelines.
adapt_for_trae() {
    local agent="$1" cmd="$2" src="$3" base="$4"
    local dst="$base/$agent/$cmd.md"
    local description arg_hint
    description="$(extract_frontmatter_field "$src" "description")"
    arg_hint="$(extract_frontmatter_field "$src" "argument-hint")"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] trae /$agent:$cmd -> $dst"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    {
        echo "# Rule: ${agent}:${cmd}"
        echo ""
        echo "**Trigger:** When the user asks to run \`${agent}:${cmd}\` or \"${cmd//-/ }\"."
        [[ -n "$description" ]] && echo "" && echo "$description"
        [[ -n "$arg_hint"    ]] && echo "" && echo "**Arguments:** ${arg_hint}"
        echo ""
        strip_frontmatter "$src"
    } > "$dst"
}

# Gemini CLI: strip frontmatter, replace $ARGUMENTS -> {{input}}
# Goes into extension's commands/<agent>/<cmd>.md  →  /bmad-sdlc:<agent>-<cmd>
# (Gemini flattens the namespace: extension:command, not extension:agent:command)
adapt_for_gemini() {
    local agent="$1" cmd="$2" src="$3" base="$4"
    local dst="$base/${agent}-${cmd}.md"   # flat file: agent-cmd (Gemini uses ext:name)
    local description arg_hint
    description="$(extract_frontmatter_field "$src" "description")"
    arg_hint="$(extract_frontmatter_field "$src" "argument-hint")"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] gemini /bmad-sdlc:${agent}-${cmd} -> $dst"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    {
        echo "# ${agent}:${cmd}"
        [[ -n "$description" ]] && echo "" && echo "$description"
        [[ -n "$arg_hint"    ]] && echo "" && echo "**Arguments:** ${arg_hint}"
        echo ""
        strip_frontmatter "$src" | sed 's/\$ARGUMENTS/{{input}}/g'
    } > "$dst"
}

# Kiro: write a skill folder with correct name: frontmatter (name must match folder name)
# Kiro does NOT support nested skill folders — all skills must be flat under ~/.kiro/skills/
write_kiro_skill() {
    local skill_name="$1" src="$2" skills_dir="$3"
    local skill_dir="$skills_dir/$skill_name"
    local description
    description="$(extract_frontmatter_field "$src" "description")"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] /kiro $skill_name  ->  $skill_dir/SKILL.md"
        return
    fi
    mkdir -p "$skill_dir"
    # Double-quote the description to prevent YAML parse errors from [Bracket] prefixes
    local safe_desc="${description:-BMAD ${skill_name}}"
    safe_desc="${safe_desc//\"/\\\"}"   # escape any internal double-quotes
    {
        echo "---"
        echo "name: ${skill_name}"
        echo "description: \"${safe_desc}\""
        echo "---"
        echo ""
        strip_frontmatter "$src"
    } > "$skill_dir/SKILL.md"
}

# Aider: no native commands; embed as ## Workflow: agent:cmd sections in conventions
adapt_for_aider() {
    local agent="$1" cmd="$2" src="$3" conv_file="$4"
    local description
    description="$(extract_frontmatter_field "$src" "description")"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] aider /${agent}:${cmd} -> $conv_file"
        return
    fi
    mkdir -p "$(dirname "$conv_file")"
    {
        echo ""
        echo "---"
        echo ""
        echo "## Workflow: ${agent}:${cmd}"
        [[ -n "$description" ]] && echo "" && echo "$description"
        echo ""
        strip_frontmatter "$src" | sed 's/\$ARGUMENTS/the user-provided arguments/g'
    } >> "$conv_file"
}

# Merge BMAD hooks into an existing settings.json, backing up first.
# Usage: merge_settings_json <bmad_source.json> <target_settings.json>
merge_settings_json() {
    local src="$1"
    local dst="$2"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] merge $src -> $dst"
        return
    fi

    if [[ ! -f "$dst" ]]; then
        mkdir -p "$(dirname "$dst")"
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
        cp "$backup" "$dst"
        echo -e "  ${RED}✗ Merge failed — restored from backup. Manually merge: $src${NC}"
    fi
}

# Function to prepend shared context
prepend_shared_context() {
    local agent_file="$1"
    local output_file="$2"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] prepend shared context + $agent_file -> $output_file"
    else
        mkdir -p "$(dirname "$output_file")"
        {
            cat "$SHARED_CONTEXT"
            echo ""
            cat "$agent_file"
        } > "$output_file"
    fi
}

echo -e "${BLUE}Checking for installed AI tools...${NC}"
echo ""

# ============================================================
# Claude Code
# ============================================================
if [[ -d "$HOME/.claude" ]] || command -v claude &> /dev/null; then
    echo -e "${GREEN}✓ Claude Code${NC} found"
    CLAUDE_SKILLS="$HOME/.claude/skills"
    CLAUDE_COMMANDS="$HOME/.claude/commands"
    CLAUDE_AGENTS="$HOME/.claude/agents"
    CLAUDE_HOOKS_DIR="$HOME/.claude"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$CLAUDE_SKILLS"
        mkdir -p "$CLAUDE_COMMANDS"
        mkdir -p "$CLAUDE_AGENTS"
    fi

    # Copy shared context to ~/.claude/
    copy_file "$SHARED_CONTEXT" "$HOME/.claude/BMAD-SHARED-CONTEXT.md"

    # Remove legacy installs (flat .md files and bmad-* prefixed folders from older versions)
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] remove legacy flat skill files and bmad-* folders from $CLAUDE_SKILLS/"
    else
        # Remove old flat .md skill files (e.g. tech-lead.md, backend-engineer.md)
        for agent_dir in "$AGENTS_DIR"/*; do
            if [[ -d "$agent_dir" ]]; then
                agent_name="$(basename "$agent_dir")"
                flat_file="$CLAUDE_SKILLS/${agent_name}.md"
                if [[ -f "$flat_file" ]]; then
                    rm -f "$flat_file"
                    echo "  ✓ Removed legacy flat file: ${agent_name}.md"
                fi
            fi
        done
        # Remove old bmad-* prefixed skill folders
        for legacy in "$CLAUDE_SKILLS"/bmad-*/; do
            if [[ -d "$legacy" ]]; then
                rm -rf "$legacy"
                echo "  ✓ Removed legacy skill folder: $(basename "$legacy")"
            fi
        done
    fi

    # Copy all agents to ~/.claude/skills/<agent-name>/SKILL.md (folder format required by Claude Code)
    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [DRY] mkdir + cp $agent_dir/SKILL.md -> $CLAUDE_SKILLS/$agent_name/SKILL.md"
            else
                mkdir -p "$CLAUDE_SKILLS/$agent_name"
                cp "$agent_dir/SKILL.md" "$CLAUDE_SKILLS/$agent_name/SKILL.md"
                if [[ -d "$agent_dir/references" ]]; then
                    cp -r "$agent_dir/references" "$CLAUDE_SKILLS/$agent_name/"
                fi
                if [[ -d "$agent_dir/templates" ]]; then
                    cp -r "$agent_dir/templates" "$CLAUDE_SKILLS/$agent_name/"
                fi
                echo "  ✓ Installed skill: $agent_name"
            fi
        fi
    done

    # Deploy Claude Code subagent definitions to ~/.claude/agents/
    # These YAML-frontmatter .md files register the 13 BMAD roles as Task-tool
    # subagents (e.g. tech-lead can spawn backend-engineer). Without them, Claude
    # Code errors with "Agent type 'backend-engineer' not found".
    if [[ -d "$RULES_DIR/claude/agents" ]]; then
        for agent_file in "$RULES_DIR/claude/agents"/*.md; do
            [[ -f "$agent_file" ]] || continue
            agent_name="$(basename "$agent_file" .md)"
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [DRY] cp $agent_file -> $CLAUDE_AGENTS/${agent_name}.md"
            else
                cp "$agent_file" "$CLAUDE_AGENTS/${agent_name}.md"
                echo "  ✓ Installed subagent: $agent_name"
            fi
        done
    fi

    # Copy slash commands to ~/.claude/commands/
    # Install commands preserving agent/cmd subdirectory structure → /agent:cmd
    walk_sub_agents install_native "$CLAUDE_COMMANDS"

    # Merge global hooks into ~/.claude/settings.json (backs up first)
    if [[ -f "$HOOKS_DIR/settings.json" ]]; then
        merge_settings_json "$HOOKS_DIR/settings.json" "$CLAUDE_HOOKS_DIR/settings.json"
        # Remove any duplicates introduced by previous merges
        python3 "$SCRIPT_DIR/clean-duplicate-hooks.py" "$CLAUDE_HOOKS_DIR/settings.json" 2>/dev/null || true
    fi

    # Copy hook scripts to ~/.claude/hooks/
    if [[ -d "$HOOKS_DIR/scripts" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [DRY] copy $HOOKS_DIR/scripts/ -> $CLAUDE_HOOKS_DIR/hooks/"
        else
            mkdir -p "$CLAUDE_HOOKS_DIR/hooks"
            cp -r "$HOOKS_DIR/scripts/." "$CLAUDE_HOOKS_DIR/hooks/"
            chmod +x "$CLAUDE_HOOKS_DIR/hooks/"*.sh 2>/dev/null || true
        fi
    fi

    echo "  Skills:    $CLAUDE_SKILLS/"
    echo "  Subagents: $CLAUDE_AGENTS/"
    echo "  Commands:  $CLAUDE_COMMANDS/"
    echo "  Hooks:     $CLAUDE_HOOKS_DIR/hooks/"
    INSTALLED_TOOLS+=("Claude Code")
    echo ""
fi

# ============================================================
# Cowork
# ============================================================
if [[ -d "$HOME/.skills" ]]; then
    echo -e "${GREEN}✓ Cowork${NC} found"
    COWORK_SKILLS="$HOME/.skills/skills"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$COWORK_SKILLS"
    fi

    # Remove legacy installs (flat .md files and bmad-* prefixed folders)
    if [[ "$DRY_RUN" == false ]]; then
        for agent_dir in "$AGENTS_DIR"/*; do
            if [[ -d "$agent_dir" ]]; then
                agent_name="$(basename "$agent_dir")"
                flat_file="$COWORK_SKILLS/${agent_name}.md"
                if [[ -f "$flat_file" ]]; then
                    rm -f "$flat_file"
                    echo "  ✓ Removed legacy flat file: ${agent_name}.md"
                fi
            fi
        done
        for legacy in "$COWORK_SKILLS"/bmad-*/; do
            if [[ -d "$legacy" ]]; then
                rm -rf "$legacy"
                echo "  ✓ Removed legacy skill folder: $(basename "$legacy")"
            fi
        done
    fi

    # Copy all agents to ~/.skills/skills/<agent-name>/SKILL.md (folder format)
    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [DRY] mkdir + cp $agent_dir/SKILL.md -> $COWORK_SKILLS/$agent_name/SKILL.md"
            else
                mkdir -p "$COWORK_SKILLS/$agent_name"
                cp "$agent_dir/SKILL.md" "$COWORK_SKILLS/$agent_name/SKILL.md"
                if [[ -d "$agent_dir/references" ]]; then
                    cp -r "$agent_dir/references" "$COWORK_SKILLS/$agent_name/"
                fi
                if [[ -d "$agent_dir/templates" ]]; then
                    cp -r "$agent_dir/templates" "$COWORK_SKILLS/$agent_name/"
                fi
                echo "  ✓ Installed skill: $agent_name"
            fi
        fi
    done

    # Copy shared context
    copy_file "$SHARED_CONTEXT" "$HOME/.skills/BMAD-SHARED-CONTEXT.md"

    # Copy slash commands to ~/.skills/commands/ (Cowork uses commands/ like Claude Code)
    COWORK_COMMANDS="$HOME/.skills/commands"
    walk_sub_agents install_native "$COWORK_COMMANDS"

    echo "  Skills:   $COWORK_SKILLS/"
    echo "  Commands: $COWORK_COMMANDS/"
    INSTALLED_TOOLS+=("Cowork")
    echo ""
fi

# ============================================================
# Codex CLI (OpenAI)
# ============================================================
if [[ -d "$HOME/.codex" ]] || command -v codex &> /dev/null; then
    echo -e "${GREEN}✓ Codex CLI${NC} found"
    CODEX_SKILLS="$HOME/.codex/skills"
    CODEX_PROMPTS="$HOME/.codex/prompts"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$CODEX_SKILLS"
        mkdir -p "$CODEX_PROMPTS"
    fi

    # Wipe all existing bmad skills for a clean install
    if [[ "$DRY_RUN" == false ]]; then
        rm -rf "$CODEX_SKILLS"
        mkdir -p "$CODEX_SKILLS"
    fi

    # Copy shared context
    copy_file "$SHARED_CONTEXT" "$HOME/.codex/BMAD-SHARED-CONTEXT.md"

    # Deploy 43 flat skill folders under ~/.codex/skills/:
    #   Agent persona  → skills/<agent-name>/SKILL.md
    #   Agent command  → skills/<agent-name>-<cmd>/SKILL.md
    #
    #   ~/.codex/skills/tech-lead/SKILL.md
    #   ~/.codex/skills/tech-lead-code-review/SKILL.md
    #   ~/.codex/skills/tech-lead-sprint-plan/SKILL.md
    n_skills=0
    for agent_dir in "$AGENTS_DIR"/*/; do
        [[ -d "$agent_dir" ]] || continue
        agent_name="$(basename "$agent_dir")"

        # Persona skill
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [DRY] $CODEX_SKILLS/$agent_name/SKILL.md  (persona)"
        else
            mkdir -p "$CODEX_SKILLS/$agent_name"
            cp "$agent_dir/SKILL.md" "$CODEX_SKILLS/$agent_name/SKILL.md"
        fi
        (( n_skills++ )) || true

        # Command skills: <agent-name>-<cmd>/SKILL.md
        for cmd_file in "$agent_dir"/*.md; do
            [[ -f "$cmd_file" ]] || continue
            cmd_name="$(basename "$cmd_file" .md)"
            [[ "$cmd_name" == "SKILL" ]] && continue
            skill_dir="$CODEX_SKILLS/${agent_name}-${cmd_name}"
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [DRY] $skill_dir/SKILL.md"
            else
                mkdir -p "$skill_dir"
                cp "$cmd_file" "$skill_dir/SKILL.md"
            fi
            (( n_skills++ )) || true
        done
    done

    echo "  Skills:   $CODEX_SKILLS/  ($n_skills flat skill folders)"
    echo "  Layout:   skills/<agent>/SKILL.md  +  skills/<agent>-<cmd>/SKILL.md"
    INSTALLED_TOOLS+=("Codex CLI")
    echo ""
fi

# ============================================================
# Kiro (AWS)
# 43 flat skill folders — Kiro does NOT support nested skill dirs.
#
# ~/.kiro/skills/
#   tech-lead/SKILL.md                    → /tech-lead       (persona)
#   tech-lead-code-review/SKILL.md        → /tech-lead-code-review
#   tech-lead-sprint-plan/SKILL.md        → /tech-lead-sprint-plan
#   ...
#
# ~/.kiro/steering/bmad-shared-context.md  inclusion: always
# ============================================================
if [[ -d "$HOME/.kiro" ]] || command -v kiro &> /dev/null; then
    echo -e "${GREEN}✓ Kiro${NC} found"
    KIRO_SKILLS="$HOME/.kiro/skills"
    KIRO_STEERING="$HOME/.kiro/steering"

    # Wipe all existing BMAD skills and legacy steering files for a clean install
    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$KIRO_STEERING"
        # Remove all agent-named and agent-prefixed skill folders
        for agent_dir in "$AGENTS_DIR"/*/; do
            [[ -d "$agent_dir" ]] || continue
            agent_name="$(basename "$agent_dir")"
            for skill_dir in "$KIRO_SKILLS"/"${agent_name}"/ "$KIRO_SKILLS"/"${agent_name}"-*/; do
                [[ -d "$skill_dir" ]] && rm -rf "$skill_dir"
            done
            # Remove legacy steering files: old installer put commands as <agent>-<cmd>.md in steering
            for steer_file in "$KIRO_STEERING"/"${agent_name}"-*.md; do
                [[ -f "$steer_file" ]] && rm -f "$steer_file" && echo "  ✓ Removed legacy steering: $(basename "$steer_file")"
            done
        done
        mkdir -p "$KIRO_SKILLS"
    fi

    # Shared context as always-included steering file
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] $KIRO_STEERING/bmad-shared-context.md  (inclusion: always)"
    else
        {
            echo "---"
            echo "inclusion: always"
            echo "description: BMAD shared context — organization standards and conventions"
            echo "---"
            echo ""
            cat "$SHARED_CONTEXT"
        } > "$KIRO_STEERING/bmad-shared-context.md"
    fi

    # Deploy 43 flat skill folders:
    #   Agent persona  → skills/<agent-name>/SKILL.md       (/agent-name)
    #   Agent command  → skills/<agent-name>-<cmd>/SKILL.md (/agent-name-cmd)
    n_kiro=0
    for agent_dir in "$AGENTS_DIR"/*/; do
        [[ -d "$agent_dir" ]] || continue
        agent_name="$(basename "$agent_dir")"

        # Persona skill
        write_kiro_skill "$agent_name" "$agent_dir/SKILL.md" "$KIRO_SKILLS"
        (( n_kiro++ )) || true

        # Command skills
        for cmd_file in "$agent_dir"/*.md; do
            [[ -f "$cmd_file" ]] || continue
            cmd_name="$(basename "$cmd_file" .md)"
            [[ "$cmd_name" == "SKILL" ]] && continue
            write_kiro_skill "${agent_name}-${cmd_name}" "$cmd_file" "$KIRO_SKILLS"
            (( n_kiro++ )) || true
        done
    done

    echo "  Skills:   $KIRO_SKILLS/  ($n_kiro flat skill folders)"
    echo "  Steering: $KIRO_STEERING/bmad-shared-context.md  (inclusion: always)"
    echo "  Invoke:   /tech-lead,  /tech-lead-code-review,  /product-owner-create-brd,  etc."
    INSTALLED_TOOLS+=("Kiro")
    echo ""
fi

# ============================================================
# Cursor
# ============================================================
if [[ -d "$HOME/.cursor" ]] || command -v cursor &> /dev/null; then
    echo -e "${GREEN}✓ Cursor${NC} found"
    CURSOR_RULES="$HOME/.cursor/rules"
    CURSOR_SKILLS="$HOME/.cursor/skills"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$CURSOR_RULES"
        mkdir -p "$CURSOR_SKILLS"
    fi

    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            prepend_shared_context "$agent_dir/SKILL.md" "$CURSOR_RULES/${agent_name}.md"
            # Copy references/ and templates/ so agents can read them via relative paths
            if [[ "$DRY_RUN" == false ]]; then
                mkdir -p "$CURSOR_SKILLS/$agent_name"
                if [[ -d "$agent_dir/references" ]]; then
                    cp -r "$agent_dir/references" "$CURSOR_SKILLS/$agent_name/"
                fi
                if [[ -d "$agent_dir/templates" ]]; then
                    cp -r "$agent_dir/templates" "$CURSOR_SKILLS/$agent_name/"
                fi
            fi
        fi
    done

    # Adapt commands for Cursor: strip frontmatter, add /agent:cmd header
    CURSOR_COMMANDS="$HOME/.cursor/commands"
    walk_sub_agents adapt_for_cursor "$CURSOR_COMMANDS"

    # Copy Cursor-specific global rules (.mdc files)
    if [[ -d "$RULES_DIR/cursor/global" ]]; then
        for rule_file in "$RULES_DIR/cursor/global"/*.mdc; do
            if [[ -f "$rule_file" ]]; then
                copy_file "$rule_file" "$CURSOR_RULES/$(basename "$rule_file")"
            fi
        done
    fi

    # Copy Cursor-specific global rules (.mdc files)
    if [[ -d "$RULES_DIR/cursor/global" ]]; then
        for rule_file in "$RULES_DIR/cursor/global"/*.mdc; do
            if [[ -f "$rule_file" ]]; then
                copy_file "$rule_file" "$CURSOR_RULES/$(basename "$rule_file")"
            fi
        done
    fi

    # Register the repo's .cursor-plugin/plugin.json with Cursor's plugin registry
    # Cursor discovers plugins via ~/.cursor/plugins/<name>/plugin.json
    CURSOR_PLUGIN_DIR="$HOME/.cursor/plugins/bmad-sdlc"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] register plugin -> $CURSOR_PLUGIN_DIR/plugin.json"
    else
        mkdir -p "$CURSOR_PLUGIN_DIR"
        cp "$BASE_DIR/.cursor-plugin/plugin.json" "$CURSOR_PLUGIN_DIR/plugin.json"
        # Patch the paths in the copied plugin.json to point at the source repo
        sed -i.bak \
            "s|\"./agents/\"|\"$AGENTS_DIR/\"|g; \
             s|\"./commands/\"|\"$COMMANDS_DIR/\"|g; \
             s|\"./hooks/global/settings.json\"|\"$BASE_DIR/hooks/global/settings.json\"|g" \
            "$CURSOR_PLUGIN_DIR/plugin.json"
        rm -f "$CURSOR_PLUGIN_DIR/plugin.json.bak"
    fi

    echo "  Rules:    $CURSOR_RULES/"
    echo "  Skills:   $CURSOR_SKILLS/"
    echo "  Commands: $CURSOR_COMMANDS/"
    echo "  Plugin:   $CURSOR_PLUGIN_DIR/plugin.json"
    INSTALLED_TOOLS+=("Cursor")
    echo ""
fi

# ============================================================
# Windsurf
# ============================================================
if [[ -d "$HOME/.windsurf" ]]; then
    echo -e "${GREEN}✓ Windsurf${NC} found"
    WINDSURF_RULES="$HOME/.windsurf/rules"
    WINDSURF_SKILLS="$HOME/.windsurf/skills"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$WINDSURF_RULES"
        mkdir -p "$WINDSURF_SKILLS"
    fi

    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            prepend_shared_context "$agent_dir/SKILL.md" "$WINDSURF_RULES/${agent_name}.md"
            # Copy references/ and templates/ so agents can read them
            if [[ "$DRY_RUN" == false ]]; then
                mkdir -p "$WINDSURF_SKILLS/$agent_name"
                if [[ -d "$agent_dir/references" ]]; then
                    cp -r "$agent_dir/references" "$WINDSURF_SKILLS/$agent_name/"
                fi
                if [[ -d "$agent_dir/templates" ]]; then
                    cp -r "$agent_dir/templates" "$WINDSURF_SKILLS/$agent_name/"
                fi
            fi
        fi
    done

    # Copy Windsurf global rules
    if [[ -d "$RULES_DIR/windsurf/global" ]]; then
        for rule_file in "$RULES_DIR/windsurf/global"/*.md; do
            if [[ -f "$rule_file" ]]; then
                copy_file "$rule_file" "$WINDSURF_RULES/$(basename "$rule_file")"
            fi
        done
    fi

    # Adapt commands for Windsurf rules format
    WINDSURF_COMMANDS="$HOME/.windsurf/rules/bmad-commands"
    walk_sub_agents adapt_for_windsurf "$WINDSURF_COMMANDS"

    echo "  Rules:    $WINDSURF_RULES/"
    echo "  Skills:   $WINDSURF_SKILLS/"
    echo "  Commands: $WINDSURF_COMMANDS/"
    INSTALLED_TOOLS+=("Windsurf")
    echo ""
fi

# ============================================================
# Trae IDE (ByteDance) — rules-based, same paradigm as Windsurf/Cursor.
# User rules: ~/.trae/rules/ (markdown files auto-loaded as always-on guidelines)
# Trae installs user_rules.md by default but will pick up other .md files in ~/.trae/rules/
# as well. We deploy each BMAD agent as its own rule file, plus the framework overview.
# ============================================================
if [[ -d "$HOME/.trae" ]] || command -v trae &> /dev/null; then
    echo -e "${GREEN}✓ Trae IDE${NC} found"
    TRAE_RULES="$HOME/.trae/rules"
    TRAE_SKILLS="$HOME/.trae/skills"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$TRAE_RULES"
        mkdir -p "$TRAE_SKILLS"
    fi

    # Copy shared context to ~/.trae/ for fallback loading
    copy_file "$SHARED_CONTEXT" "$HOME/.trae/BMAD-SHARED-CONTEXT.md"

    # Deploy each BMAD agent as a rule file with shared context prepended
    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            prepend_shared_context "$agent_dir/SKILL.md" "$TRAE_RULES/${agent_name}.md"
            # Copy references/ and templates/ so agents can read them via relative paths
            if [[ "$DRY_RUN" == false ]]; then
                mkdir -p "$TRAE_SKILLS/$agent_name"
                if [[ -d "$agent_dir/references" ]]; then
                    cp -r "$agent_dir/references" "$TRAE_SKILLS/$agent_name/"
                fi
                if [[ -d "$agent_dir/templates" ]]; then
                    cp -r "$agent_dir/templates" "$TRAE_SKILLS/$agent_name/"
                fi
            fi
        fi
    done

    # Copy Trae-specific global rules (framework overview)
    # Deployed twice: (1) user_rules.md — the path Trae auto-loads in every version,
    # (2) 000-bmad-framework.md — sorts first for Trae versions that read the whole rules/ dir.
    if [[ -d "$RULES_DIR/trae/global" ]]; then
        for rule_file in "$RULES_DIR/trae/global"/*.md; do
            if [[ -f "$rule_file" ]]; then
                copy_file "$rule_file" "$TRAE_RULES/000-$(basename "$rule_file")"
                # Also install the framework as user_rules.md (Trae's canonical user-rules path)
                if [[ "$(basename "$rule_file")" == "bmad-framework.md" ]]; then
                    copy_file "$rule_file" "$TRAE_RULES/user_rules.md"
                fi
            fi
        done
    fi

    # Adapt commands for Trae rules format (same adapter shape as Windsurf)
    TRAE_COMMANDS="$HOME/.trae/rules/bmad-commands"
    walk_sub_agents adapt_for_trae "$TRAE_COMMANDS"

    echo "  Rules:    $TRAE_RULES/"
    echo "  Skills:   $TRAE_SKILLS/"
    echo "  Commands: $TRAE_COMMANDS/"
    INSTALLED_TOOLS+=("Trae IDE")
    echo ""
fi

# ============================================================
# GitHub Copilot
# ============================================================
if [[ -d "$HOME/.github" ]]; then
    echo -e "${GREEN}✓ GitHub Copilot${NC} found"
    COPILOT_INSTRUCTIONS="$HOME/.github/copilot-instructions.md"
    COPILOT_SKILLS="$HOME/.github/bmad-skills"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] append all agents -> $COPILOT_INSTRUCTIONS"
        if [[ -d "$RULES_DIR/copilot/global" ]]; then
            echo "  [DRY] append copilot global rules -> $COPILOT_INSTRUCTIONS"
        fi
    else
        mkdir -p "$(dirname "$COPILOT_INSTRUCTIONS")"
        mkdir -p "$COPILOT_SKILLS"
        {
            if [[ -f "$COPILOT_INSTRUCTIONS" ]]; then
                cat "$COPILOT_INSTRUCTIONS"
                echo ""
            fi
            cat "$SHARED_CONTEXT"
            for agent_dir in "$AGENTS_DIR"/*; do
                if [[ -d "$agent_dir" ]]; then
                    echo ""
                    cat "$agent_dir/SKILL.md"
                fi
            done
            # Append copilot global rules
            if [[ -d "$RULES_DIR/copilot/global" ]]; then
                for rule_file in "$RULES_DIR/copilot/global"/*.md; do
                    if [[ -f "$rule_file" ]]; then
                        echo ""
                        cat "$rule_file"
                    fi
                done
            fi
        } > "$COPILOT_INSTRUCTIONS"

        # Copy references/ and templates/ to a parallel skills directory for Copilot
        for agent_dir in "$AGENTS_DIR"/*; do
            if [[ -d "$agent_dir" ]]; then
                agent_name="$(basename "$agent_dir")"
                mkdir -p "$COPILOT_SKILLS/$agent_name"
                if [[ -d "$agent_dir/references" ]]; then
                    cp -r "$agent_dir/references" "$COPILOT_SKILLS/$agent_name/"
                fi
                if [[ -d "$agent_dir/templates" ]]; then
                    cp -r "$agent_dir/templates" "$COPILOT_SKILLS/$agent_name/"
                fi
            fi
        done
    fi

    # Copy commands natively (Copilot supports YAML frontmatter)
    COPILOT_COMMANDS="$HOME/.github/bmad-commands"
    walk_sub_agents install_native "$COPILOT_COMMANDS"

    echo "  Instructions: $COPILOT_INSTRUCTIONS"
    echo "  Skills:       $COPILOT_SKILLS/"
    echo "  Commands:     $COPILOT_COMMANDS/"
    INSTALLED_TOOLS+=("GitHub Copilot")
    echo ""
fi

# ============================================================
# Gemini CLI
# ============================================================
# 13 extensions, one per BMAD agent: /bmad-<agent>:<cmd>
#
# ~/.gemini/extensions/bmad-product-owner/
#   gemini-extension.json   name: "bmad-product-owner"
#   GEMINI.md               @./skills/create-brd/SKILL.md ...
#   skills/
#     create-brd/SKILL.md   → /bmad-product-owner:create-brd
#     create-prd/SKILL.md   → /bmad-product-owner:create-prd
#     new-epic/SKILL.md     → /bmad-product-owner:new-epic
#     new-story/SKILL.md    → /bmad-product-owner:new-story
#
# No root SKILL.md, no shared/, no references/ at root — pure skills/ only.
# Extension dir wiped clean on each install (prevents nested dir accumulation).
# ============================================================
if [[ -d "$HOME/.gemini" ]] || command -v gemini &> /dev/null; then
    echo -e "${GREEN}✓ Gemini CLI${NC} found"
    GEMINI_EXTENSIONS_DIR="$HOME/.gemini/extensions"

    # Remove ALL legacy installs from previous versions
    if [[ "$DRY_RUN" == false ]]; then
        for legacy in \
            "$HOME/.gemini/skills/bmad-"* \
            "$HOME/.gemini/BMAD-SHARED-CONTEXT.md" \
            "$GEMINI_EXTENSIONS_DIR/bmad-sdlc" \
            "$GEMINI_EXTENSIONS_DIR/bmad"; do
            [[ -e "$legacy" ]] && rm -rf "$legacy" && echo "  ✓ Removed legacy: $(basename "$legacy")"
        done
        for agent_dir in "$AGENTS_DIR"/*/; do
            legacy="$HOME/.gemini/skills/$(basename "$agent_dir")"
            [[ -e "$legacy" ]] && rm -rf "$legacy" && echo "  ✓ Removed legacy skill: $(basename "$legacy")"
        done
    fi

    # Deploy one extension per agent (skip the bmad orchestrator — not a user-facing agent)
    for agent_dir in "$AGENTS_DIR"/*/; do
        [[ -d "$agent_dir" ]] || continue
        agent_name="$(basename "$agent_dir")"
        [[ "$agent_name" == "bmad" ]] && continue
        ext_name="bmad-${agent_name}"
        ext_dir="$GEMINI_EXTENSIONS_DIR/${ext_name}"

        if [[ "$DRY_RUN" == true ]]; then
            echo "  [DRY] /${ext_name}:"
            echo "  [DRY]   :${agent_name}  →  skills/${agent_name}/SKILL.md  (persona)"
            for cmd_file in "$agent_dir"/*.md; do
                [[ -f "$cmd_file" ]] || continue
                cmd_name="$(basename "$cmd_file" .md)"
                [[ "$cmd_name" == "SKILL" ]] && continue
                echo "  [DRY]   :${cmd_name}  →  skills/${cmd_name}/SKILL.md"
            done
        else
            # Wipe clean on each install — prevents nested dir accumulation from re-runs
            rm -rf "$ext_dir"
            mkdir -p "$ext_dir/skills"

            # Write gemini-extension.json
            description="$(extract_frontmatter_field "$agent_dir/SKILL.md" description)"
            cat > "$ext_dir/gemini-extension.json" <<EXTEOF
{
  "name": "${ext_name}",
  "description": "${description}",
  "version": "1.0.0",
  "contextFileName": "GEMINI.md"
}
EXTEOF

            # Agent persona → skills/<agent-name>/SKILL.md  (/bmad-<agent>:<agent-name>)
            mkdir -p "$ext_dir/skills/$agent_name"
            cp "$agent_dir/SKILL.md" "$ext_dir/skills/$agent_name/SKILL.md"

            # Each sibling cmd .md → skills/<cmd>/SKILL.md  (/bmad-<agent>:<cmd>)
            for cmd_file in "$agent_dir"/*.md; do
                [[ -f "$cmd_file" ]] || continue
                cmd_name="$(basename "$cmd_file" .md)"
                [[ "$cmd_name" == "SKILL" ]] && continue
                mkdir -p "$ext_dir/skills/$cmd_name"
                cp "$cmd_file" "$ext_dir/skills/$cmd_name/SKILL.md"
            done

            # Build GEMINI.md: pure @imports only (matching superpowers pattern)
            # Persona first, then commands — all invocable via /<ext>:<skill-name>
            {
                echo "@./skills/${agent_name}/SKILL.md"
                for cmd_file in "$agent_dir"/*.md; do
                    [[ -f "$cmd_file" ]] || continue
                    cmd_name="$(basename "$cmd_file" .md)"
                    [[ "$cmd_name" == "SKILL" ]] && continue
                    echo "@./skills/${cmd_name}/SKILL.md"
                done
            } > "$ext_dir/GEMINI.md"
            if [[ -d "$RULES_DIR/gemini/global" ]]; then
                for rule_file in "$RULES_DIR/gemini/global"/*.md; do
                    [[ -f "$rule_file" ]] && { echo ""; cat "$rule_file"; } >> "$ext_dir/GEMINI.md"
                done
            fi

            n_cmds=$(ls "$ext_dir/skills" | wc -l | tr -d ' ')
            echo "  ✓ /${ext_name}  ($n_cmds commands)"
        fi
    done

    echo "  Extensions:  $GEMINI_EXTENSIONS_DIR/bmad-*/"
    echo "  Invoke:      /bmad-product-owner:create-brd,  /bmad-tech-lead:code-review,  etc."
    echo "  Register:    for ext in ~/.gemini/extensions/bmad-*/; do gemini extensions install \"\$ext\"; done"

    # --------------------------------------------------------
    # Gemini CLI subagents (native subagent feature)
    # --------------------------------------------------------
    # Deploys 13 markdown-defined subagents to ~/.gemini/agents/.
    # Each file has YAML frontmatter (name, description, tools, temperature,
    # max_turns, timeout_mins) and a system-prompt body that references the
    # installed skill files above. The main Gemini session can now delegate
    # to them either automatically ("Gemini's main agent is instructed to use
    # specialised subagents when a task matches their expertise") or
    # explicitly via @<name> syntax, e.g.
    #   @backend-engineer implement story BE-001
    # Each subagent runs in an isolated context window — they save tokens in
    # the main conversation but cannot call other subagents.
    GEMINI_SUBAGENTS_SRC="$RULES_DIR/gemini/agents"
    GEMINI_SUBAGENTS_DST="$HOME/.gemini/agents"
    if [[ -d "$GEMINI_SUBAGENTS_SRC" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            for f in "$GEMINI_SUBAGENTS_SRC"/*.md; do
                [[ -f "$f" ]] || continue
                echo "  [DRY] subagent $(basename "$f") -> $GEMINI_SUBAGENTS_DST/"
            done
        else
            mkdir -p "$GEMINI_SUBAGENTS_DST"
            n_sub=0
            for f in "$GEMINI_SUBAGENTS_SRC"/*.md; do
                [[ -f "$f" ]] || continue
                cp "$f" "$GEMINI_SUBAGENTS_DST/$(basename "$f")"
                n_sub=$((n_sub + 1))
            done
            echo "  ✓ Subagents:  $GEMINI_SUBAGENTS_DST/  ($n_sub files)"
            echo "  Invoke:       @backend-engineer …, @tech-lead …, @product-owner …"
            echo "  Manage:       /agents  (inside gemini)"
        fi
    fi

    INSTALLED_TOOLS+=("Gemini CLI")
    echo ""
fi

# ============================================================
# OpenCode
# ============================================================
if [[ -d "$HOME/.opencode" ]] || command -v opencode &> /dev/null; then
    echo -e "${GREEN}✓ OpenCode${NC} found"
    OPENCODE_INSTRUCTIONS="$HOME/.opencode/instructions.md"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] create with shared context + all agents -> $OPENCODE_INSTRUCTIONS"
    else
        mkdir -p "$(dirname "$OPENCODE_INSTRUCTIONS")"
        {
            cat "$SHARED_CONTEXT"
            for agent_dir in "$AGENTS_DIR"/*; do
                if [[ -d "$agent_dir" ]]; then
                    echo ""
                    cat "$agent_dir/SKILL.md"
                fi
            done
            if [[ -d "$RULES_DIR/opencode/global" ]]; then
                for rule_file in "$RULES_DIR/opencode/global"/*.md; do
                    if [[ -f "$rule_file" ]]; then
                        echo ""
                        cat "$rule_file"
                    fi
                done
            fi
        } > "$OPENCODE_INSTRUCTIONS"
    fi

    # Copy references and templates to ~/.opencode/bmad-skills/<agent>/
    OPENCODE_SKILLS="$HOME/.opencode/bmad-skills"
    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [DRY] copy refs/templates -> $OPENCODE_SKILLS/$agent_name/"
            else
                mkdir -p "$OPENCODE_SKILLS/$agent_name"
                if [[ -d "$agent_dir/references" ]]; then
                    cp -r "$agent_dir/references" "$OPENCODE_SKILLS/$agent_name/"
                fi
                if [[ -d "$agent_dir/templates" ]]; then
                    cp -r "$agent_dir/templates" "$OPENCODE_SKILLS/$agent_name/"
                fi
            fi
        fi
    done

    # Install commands natively (OpenCode supports same format as Claude Code)
    OPENCODE_COMMANDS="$HOME/.opencode/commands"
    walk_sub_agents install_native "$OPENCODE_COMMANDS"

    echo "  Instructions: $OPENCODE_INSTRUCTIONS"
    echo "  Skills:       $OPENCODE_SKILLS/"
    echo "  Commands:     $OPENCODE_COMMANDS/"
    INSTALLED_TOOLS+=("OpenCode")
    echo ""
fi

# ============================================================
# Aider
# ============================================================
if [[ -d "$HOME/.aider" ]] || command -v aider &> /dev/null; then
    echo -e "${GREEN}✓ Aider${NC} found"
    AIDER_CONVENTIONS="$HOME/.aider.conventions.md"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] append shared context to $AIDER_CONVENTIONS"
    else
        mkdir -p "$(dirname "$AIDER_CONVENTIONS")"
        if [[ ! -f "$AIDER_CONVENTIONS" ]]; then
            cp "$SHARED_CONTEXT" "$AIDER_CONVENTIONS"
        else
            echo "" >> "$AIDER_CONVENTIONS"
            cat "$SHARED_CONTEXT" >> "$AIDER_CONVENTIONS"
        fi
        if [[ -d "$RULES_DIR/aider/global" ]]; then
            for rule_file in "$RULES_DIR/aider/global"/*.md; do
                if [[ -f "$rule_file" ]]; then
                    echo "" >> "$AIDER_CONVENTIONS"
                    cat "$rule_file" >> "$AIDER_CONVENTIONS"
                fi
            done
        fi
    fi

    # Copy references and templates to ~/.aider/bmad-skills/<agent>/
    AIDER_SKILLS="$HOME/.aider/bmad-skills"
    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [DRY] copy refs/templates -> $AIDER_SKILLS/$agent_name/"
            else
                mkdir -p "$AIDER_SKILLS/$agent_name"
                if [[ -d "$agent_dir/references" ]]; then
                    cp -r "$agent_dir/references" "$AIDER_SKILLS/$agent_name/"
                fi
                if [[ -d "$agent_dir/templates" ]]; then
                    cp -r "$agent_dir/templates" "$AIDER_SKILLS/$agent_name/"
                fi
            fi
        fi
    done

    # Embed commands as ## Workflow sections in the conventions file
    walk_sub_agents adapt_for_aider "$AIDER_CONVENTIONS"

    echo "  Conventions:  $AIDER_CONVENTIONS"
    echo "  Skills:       $AIDER_SKILLS/"
    INSTALLED_TOOLS+=("Aider")
    echo ""
fi

# ============================================================
# Karpathy-Style Coding Principles — deploy per detected tool
# ============================================================
# Tool-tailored adaptations of the four behavioral principles
# (Think Before Coding, Simplicity First, Surgical Changes, Goal-Driven
# Execution) from forrestchang/andrej-karpathy-skills. Source files live in
# shared/karpathy-principles/ alongside BMAD-SHARED-CONTEXT.md. See
# shared/karpathy-principles/README.md for per-tool tailoring notes.
# ============================================================
KARPATHY_DIR="$BASE_DIR/shared/karpathy-principles"

# Idempotent append: only cat $src onto $dst if $marker isn't already there.
# Usage: append_karpathy <src> <dst> <marker-regex>
append_karpathy() {
    local src="$1" dst="$2" marker="$3"
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] append $src -> $dst"
        return
    fi
    mkdir -p "$(dirname "$dst")"
    if [[ -f "$dst" ]] && grep -q "$marker" "$dst" 2>/dev/null; then
        return  # already installed
    fi
    [[ -f "$dst" ]] && echo "" >> "$dst"
    cat "$src" >> "$dst"
}

if [[ -d "$KARPATHY_DIR" ]]; then
    echo -e "${BLUE}Installing Karpathy-style coding principles...${NC}"

    # Claude Code — standalone file next to shared context
    if [[ -d "$HOME/.claude" ]] || command -v claude &> /dev/null; then
        copy_file "$KARPATHY_DIR/claude-code.md" "$HOME/.claude/KARPATHY-PRINCIPLES.md"
        echo -e "  ${GREEN}✓${NC} Claude Code    → ~/.claude/KARPATHY-PRINCIPLES.md"
    fi

    # Cowork
    if [[ -d "$HOME/.skills" ]]; then
        copy_file "$KARPATHY_DIR/cowork.md" "$HOME/.skills/KARPATHY-PRINCIPLES.md"
        echo -e "  ${GREEN}✓${NC} Cowork         → ~/.skills/KARPATHY-PRINCIPLES.md"
    fi

    # Codex CLI
    if [[ -d "$HOME/.codex" ]] || command -v codex &> /dev/null; then
        copy_file "$KARPATHY_DIR/codex-cli.md" "$HOME/.codex/KARPATHY-PRINCIPLES.md"
        echo -e "  ${GREEN}✓${NC} Codex CLI      → ~/.codex/KARPATHY-PRINCIPLES.md"
    fi

    # Kiro — steering file (source already has inclusion: always frontmatter)
    if [[ -d "$HOME/.kiro" ]] || command -v kiro &> /dev/null; then
        copy_file "$KARPATHY_DIR/kiro.md" "$HOME/.kiro/steering/karpathy-principles.md"
        echo -e "  ${GREEN}✓${NC} Kiro           → ~/.kiro/steering/karpathy-principles.md"
    fi

    # Cursor — .mdc rule file (source already has alwaysApply: true frontmatter)
    if [[ -d "$HOME/.cursor" ]] || command -v cursor &> /dev/null; then
        copy_file "$KARPATHY_DIR/cursor.mdc" "$HOME/.cursor/rules/001-karpathy-principles.mdc"
        echo -e "  ${GREEN}✓${NC} Cursor         → ~/.cursor/rules/001-karpathy-principles.mdc"
    fi

    # Windsurf — rule file
    if [[ -d "$HOME/.windsurf" ]]; then
        copy_file "$KARPATHY_DIR/windsurf.md" "$HOME/.windsurf/rules/001-karpathy-principles.md"
        echo -e "  ${GREEN}✓${NC} Windsurf       → ~/.windsurf/rules/001-karpathy-principles.md"
    fi

    # Trae IDE — rule file (windsurf format works identically)
    if [[ -d "$HOME/.trae" ]] || command -v trae &> /dev/null; then
        copy_file "$KARPATHY_DIR/windsurf.md" "$HOME/.trae/rules/001-karpathy-principles.md"
        echo -e "  ${GREEN}✓${NC} Trae IDE       → ~/.trae/rules/001-karpathy-principles.md"
    fi

    # GitHub Copilot — append to copilot-instructions.md (idempotent)
    if [[ -d "$HOME/.github" ]]; then
        append_karpathy "$KARPATHY_DIR/copilot-instructions.md" \
                        "$HOME/.github/copilot-instructions.md" \
                        "^# GitHub Copilot — Coding Principles (Karpathy-style)"
        echo -e "  ${GREEN}✓${NC} GitHub Copilot → ~/.github/copilot-instructions.md (appended)"
    fi

    # Gemini CLI — standalone file in ~/.gemini/ (reference from your own GEMINI.md)
    if [[ -d "$HOME/.gemini" ]] || command -v gemini &> /dev/null; then
        copy_file "$KARPATHY_DIR/gemini-cli.md" "$HOME/.gemini/KARPATHY-PRINCIPLES.md"
        echo -e "  ${GREEN}✓${NC} Gemini CLI     → ~/.gemini/KARPATHY-PRINCIPLES.md"
    fi

    # OpenCode — append to instructions.md (idempotent)
    if [[ -d "$HOME/.opencode" ]] || command -v opencode &> /dev/null; then
        append_karpathy "$KARPATHY_DIR/opencode.md" \
                        "$HOME/.opencode/instructions.md" \
                        "^# OpenCode — Coding Principles (Karpathy-style)"
        echo -e "  ${GREEN}✓${NC} OpenCode       → ~/.opencode/instructions.md (appended)"
    fi

    # Aider — append to conventions file (idempotent)
    if [[ -d "$HOME/.aider" ]] || command -v aider &> /dev/null; then
        append_karpathy "$KARPATHY_DIR/aider.md" \
                        "$HOME/.aider.conventions.md" \
                        "^# Aider — Coding Conventions (Karpathy-style)"
        echo -e "  ${GREEN}✓${NC} Aider          → ~/.aider.conventions.md (appended)"
    fi

    echo "  Source:  $KARPATHY_DIR/"
    echo ""
fi

# ============================================================
# A2UI Reference — deploy per detected tool
# ============================================================
# Shared authoring reference for agent-driven UIs (A2UI v0.10 protocol).
# All tools get the same file — agents pull it in via explicit links from
# their SKILL.md / brainstorm.md. See shared/a2ui-reference.md for contents.
# ============================================================
A2UI_REF="$BASE_DIR/shared/a2ui-reference.md"

if [[ -f "$A2UI_REF" ]]; then
    echo -e "${BLUE}Installing A2UI reference...${NC}"

    # Claude Code
    if [[ -d "$HOME/.claude" ]] || command -v claude &> /dev/null; then
        copy_file "$A2UI_REF" "$HOME/.claude/A2UI-REFERENCE.md"
        echo -e "  ${GREEN}✓${NC} Claude Code    → ~/.claude/A2UI-REFERENCE.md"
    fi

    # Cowork
    if [[ -d "$HOME/.skills" ]]; then
        copy_file "$A2UI_REF" "$HOME/.skills/A2UI-REFERENCE.md"
        echo -e "  ${GREEN}✓${NC} Cowork         → ~/.skills/A2UI-REFERENCE.md"
    fi

    # Codex CLI
    if [[ -d "$HOME/.codex" ]] || command -v codex &> /dev/null; then
        copy_file "$A2UI_REF" "$HOME/.codex/A2UI-REFERENCE.md"
        echo -e "  ${GREEN}✓${NC} Codex CLI      → ~/.codex/A2UI-REFERENCE.md"
    fi

    # Kiro — steering file
    if [[ -d "$HOME/.kiro" ]] || command -v kiro &> /dev/null; then
        copy_file "$A2UI_REF" "$HOME/.kiro/steering/a2ui-reference.md"
        echo -e "  ${GREEN}✓${NC} Kiro           → ~/.kiro/steering/a2ui-reference.md"
    fi

    # Cursor — rule file
    if [[ -d "$HOME/.cursor" ]] || command -v cursor &> /dev/null; then
        copy_file "$A2UI_REF" "$HOME/.cursor/rules/002-a2ui-reference.md"
        echo -e "  ${GREEN}✓${NC} Cursor         → ~/.cursor/rules/002-a2ui-reference.md"
    fi

    # Windsurf — rule file
    if [[ -d "$HOME/.windsurf" ]]; then
        copy_file "$A2UI_REF" "$HOME/.windsurf/rules/002-a2ui-reference.md"
        echo -e "  ${GREEN}✓${NC} Windsurf       → ~/.windsurf/rules/002-a2ui-reference.md"
    fi

    # Trae IDE — rule file
    if [[ -d "$HOME/.trae" ]] || command -v trae &> /dev/null; then
        copy_file "$A2UI_REF" "$HOME/.trae/rules/002-a2ui-reference.md"
        echo -e "  ${GREEN}✓${NC} Trae IDE       → ~/.trae/rules/002-a2ui-reference.md"
    fi

    # Gemini CLI
    if [[ -d "$HOME/.gemini" ]] || command -v gemini &> /dev/null; then
        copy_file "$A2UI_REF" "$HOME/.gemini/A2UI-REFERENCE.md"
        echo -e "  ${GREEN}✓${NC} Gemini CLI     → ~/.gemini/A2UI-REFERENCE.md"
    fi

    # OpenCode
    if [[ -d "$HOME/.opencode" ]] || command -v opencode &> /dev/null; then
        copy_file "$A2UI_REF" "$HOME/.opencode/A2UI-REFERENCE.md"
        echo -e "  ${GREEN}✓${NC} OpenCode       → ~/.opencode/A2UI-REFERENCE.md"
    fi

    # Aider
    if [[ -d "$HOME/.aider" ]] || command -v aider &> /dev/null; then
        copy_file "$A2UI_REF" "$HOME/.aider/A2UI-REFERENCE.md"
        echo -e "  ${GREEN}✓${NC} Aider          → ~/.aider/A2UI-REFERENCE.md"
    fi

    echo "  Source:  $A2UI_REF"
    echo ""
fi

# ============================================================
# Eval Dashboard — deploy to ~/.bmad/eval/
# ============================================================
EVAL_DIR="$BASE_DIR/eval"
BMAD_HOME="$HOME/.bmad"

if [[ -d "$EVAL_DIR" ]]; then
    echo -e "${BLUE}Installing BMAD Eval Dashboard...${NC}"
    for eval_file in "$EVAL_DIR"/*; do
        if [[ -f "$eval_file" ]]; then
            copy_file "$eval_file" "$BMAD_HOME/eval/$(basename "$eval_file")"
            echo -e "  ${GREEN}✓${NC} $(basename "$eval_file") → $BMAD_HOME/eval/"
        fi
    done
    echo "  Open $BMAD_HOME/eval/bmad-agent-eval-dashboard.html in a browser to view."
    echo ""
fi

# ============================================================
# BMAD Diagnostic Scripts — deploy to ~/.bmad/scripts/
# ============================================================
# Agent-invokable diagnostics (currently: Playwright environment check).
# Deployed to a stable $HOME path so globally-installed agents can call them
# without depending on the BMAD repo being present on disk.
SCRIPTS_SRC_DIR="$BASE_DIR/scripts"
BMAD_SCRIPTS_DIR="$BMAD_HOME/scripts"
DIAGNOSTIC_SCRIPTS=(check-playwright-env.sh render-design-md.py bmad-eval-run.sh)
SHARED_SCRIPTS_SRC_DIR="$BASE_DIR/shared/scripts"
SHARED_SCRIPTS=(bmad-metrics-lib.sh)

# Only proceed if at least one diagnostic script exists in source
_has_diag_script="false"
for s in "${DIAGNOSTIC_SCRIPTS[@]}"; do
    [[ -f "$SCRIPTS_SRC_DIR/$s" ]] && _has_diag_script="true"
done
for s in "${SHARED_SCRIPTS[@]}"; do
    [[ -f "$SHARED_SCRIPTS_SRC_DIR/$s" ]] && _has_diag_script="true"
done

if [[ "$_has_diag_script" == "true" ]]; then
    echo -e "${BLUE}Installing BMAD diagnostic + metrics scripts...${NC}"
    for s in "${DIAGNOSTIC_SCRIPTS[@]}"; do
        src="$SCRIPTS_SRC_DIR/$s"
        dest="$BMAD_SCRIPTS_DIR/$s"
        if [[ -f "$src" ]]; then
            copy_file "$src" "$dest"
            if [[ "$DRY_RUN" != "true" ]]; then
                chmod +x "$dest" 2>/dev/null || true
            fi
            echo -e "  ${GREEN}✓${NC} $s → $BMAD_SCRIPTS_DIR/"
        fi
    done
    # Shared metrics lib — sourced by /bmad:eval, /bmad:status, and the
    # auto-eval hooks. Lives at ~/.bmad/scripts/bmad-metrics-lib.sh after install.
    for s in "${SHARED_SCRIPTS[@]}"; do
        src="$SHARED_SCRIPTS_SRC_DIR/$s"
        dest="$BMAD_SCRIPTS_DIR/$s"
        if [[ -f "$src" ]]; then
            copy_file "$src" "$dest"
            if [[ "$DRY_RUN" != "true" ]]; then
                chmod +x "$dest" 2>/dev/null || true
            fi
            echo -e "  ${GREEN}✓${NC} $s → $BMAD_SCRIPTS_DIR/  (shared/scripts)"
        fi
    done
    echo "  Invoke from any project:"
    echo "    bash   $BMAD_SCRIPTS_DIR/check-playwright-env.sh"
    echo "    python $BMAD_SCRIPTS_DIR/render-design-md.py --input docs/ux/DESIGN.md"
    echo "    bash   $BMAD_SCRIPTS_DIR/bmad-eval-run.sh --trigger=manual --verbose"
    echo ""
fi

# ============================================================
# MCP Configs — display guidance (not auto-installed)
# ============================================================
if [[ -d "$MCP_CONFIGS_DIR" ]]; then
    echo -e "${BLUE}MCP Server Configs available:${NC}"
    echo "  Source: $MCP_CONFIGS_DIR/"
    echo ""
    echo "  Merge the configs you need into your tool's MCP settings:"
    echo ""
    for cfg_file in "$MCP_CONFIGS_DIR"/*.json; do
        if [[ -f "$cfg_file" ]]; then
            echo "    • $(basename "$cfg_file")"
        fi
    done
    echo ""
    echo "  Claude Code:  ~/.claude/claude_desktop_config.json"
    echo "  Codex CLI:    ~/.codex/config.toml  (mcp_servers section)"
    echo "  Kiro:         ~/.kiro/settings/mcp.json"
    echo "  Cursor:       ~/.cursor/mcp.json"
    echo "  Windsurf:     ~/.windsurf/mcp_config.json"
    echo "  Trae IDE:     ~/.trae/mcp.json          (Settings → MCP & Agents, or edit the file)"
    echo "  Gemini CLI:   ~/.gemini/settings.json  (tools section)"
    echo ""
    echo "  See $BASE_DIR/mcp-configs/README.md for merge instructions."
    echo ""
fi

# ============================================================
# Tools not found
# ============================================================
echo -e "${BLUE}Tools not found:${NC}"
if ! [[ -d "$HOME/.claude" ]] && ! command -v claude &> /dev/null; then
    echo -e "${RED}✗ Claude Code${NC} — not installed"
    SKIPPED_TOOLS+=("Claude Code")
fi

if ! [[ -d "$HOME/.codex" ]] && ! command -v codex &> /dev/null; then
    echo -e "${RED}✗ Codex CLI${NC} — not installed"
    SKIPPED_TOOLS+=("Codex CLI")
fi

if ! [[ -d "$HOME/.kiro" ]] && ! command -v kiro &> /dev/null; then
    echo -e "${RED}✗ Kiro${NC} — not installed"
    SKIPPED_TOOLS+=("Kiro")
fi

if ! [[ -d "$HOME/.cursor" ]] && ! command -v cursor &> /dev/null; then
    echo -e "${RED}✗ Cursor${NC} — not installed"
    SKIPPED_TOOLS+=("Cursor")
fi

if ! [[ -d "$HOME/.windsurf" ]]; then
    echo -e "${RED}✗ Windsurf${NC} — not installed"
    SKIPPED_TOOLS+=("Windsurf")
fi

if ! [[ -d "$HOME/.trae" ]] && ! command -v trae &> /dev/null; then
    echo -e "${RED}✗ Trae IDE${NC} — not installed"
    SKIPPED_TOOLS+=("Trae IDE")
fi

if ! [[ -d "$HOME/.github" ]]; then
    echo -e "${RED}✗ GitHub Copilot${NC} — config directory not found"
    SKIPPED_TOOLS+=("GitHub Copilot")
fi

if ! [[ -d "$HOME/.gemini" ]] && ! command -v gemini &> /dev/null; then
    echo -e "${RED}✗ Gemini CLI${NC} — not installed"
    SKIPPED_TOOLS+=("Gemini CLI")
fi

if ! [[ -d "$HOME/.opencode" ]] && ! command -v opencode &> /dev/null; then
    echo -e "${RED}✗ OpenCode${NC} — not installed"
    SKIPPED_TOOLS+=("OpenCode")
fi

if ! [[ -d "$HOME/.aider" ]] && ! command -v aider &> /dev/null; then
    echo -e "${RED}✗ Aider${NC} — not installed"
    SKIPPED_TOOLS+=("Aider")
fi

if [[ -d "$HOME/.skills" ]]; then
    : # Cowork already listed above
else
    echo -e "${RED}✗ Cowork${NC} — not installed"
    SKIPPED_TOOLS+=("Cowork")
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}DRY RUN MODE - No files were actually written${NC}"
    echo ""
fi

echo -e "${GREEN}Installed to ${#INSTALLED_TOOLS[@]} tools:${NC}"
for tool in "${INSTALLED_TOOLS[@]}"; do
    echo "  • $tool"
done

echo ""
echo -e "${RED}Skipped ${#SKIPPED_TOOLS[@]} tools:${NC}"
for tool in "${SKIPPED_TOOLS[@]}"; do
    echo "  • $tool"
done

echo ""
echo "Next steps:"
echo "  1. Review installed agent configurations"
echo "  2. Review MCP configs in $BASE_DIR/mcp-configs/ and merge as needed"
echo "  3. Run: ./scripts/scaffold-project.sh <project-name>"
echo "  4. Teams fill in .bmad/*.md files in the project root"
echo "  5. Open $BMAD_HOME/eval/bmad-agent-eval-dashboard.html to track productivity"
echo ""

exit 0
