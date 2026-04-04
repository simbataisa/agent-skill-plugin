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
    CLAUDE_HOOKS_DIR="$HOME/.claude"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$CLAUDE_SKILLS"
        mkdir -p "$CLAUDE_COMMANDS"
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

    # Copy slash commands to ~/.claude/commands/
    if [[ -d "$COMMANDS_DIR" ]]; then
        for cmd_file in "$COMMANDS_DIR"/*.md; do
            if [[ -f "$cmd_file" ]]; then
                copy_file "$cmd_file" "$CLAUDE_COMMANDS/$(basename "$cmd_file")"
            fi
        done
    fi

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

    echo "  Agents:   $CLAUDE_SKILLS/"
    echo "  Commands: $CLAUDE_COMMANDS/"
    echo "  Hooks:    $CLAUDE_HOOKS_DIR/hooks/"
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

    echo "  Install path: $COWORK_SKILLS/"
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

    # Remove legacy bmad-* prefixed skill folders
    if [[ "$DRY_RUN" == false ]]; then
        for legacy in "$CODEX_SKILLS"/bmad-*/; do
            if [[ -d "$legacy" ]]; then
                rm -rf "$legacy"
                echo "  ✓ Removed legacy skill folder: $(basename "$legacy")"
            fi
        done
    fi

    # Copy shared context
    copy_file "$SHARED_CONTEXT" "$HOME/.codex/BMAD-SHARED-CONTEXT.md"

    # Copy all agents to ~/.codex/skills/<agent-name>/SKILL.md (folder-based)
    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [DRY] mkdir + cp $agent_dir/SKILL.md -> $CODEX_SKILLS/$agent_name/SKILL.md"
            else
                mkdir -p "$CODEX_SKILLS/$agent_name"
                cp "$agent_dir/SKILL.md" "$CODEX_SKILLS/$agent_name/SKILL.md"
                # Copy references/ and templates/ if they exist
                if [[ -d "$agent_dir/references" ]]; then
                    cp -r "$agent_dir/references" "$CODEX_SKILLS/$agent_name/"
                fi
                if [[ -d "$agent_dir/templates" ]]; then
                    cp -r "$agent_dir/templates" "$CODEX_SKILLS/$agent_name/"
                fi
            fi
        fi
    done

    # Copy slash commands to ~/.codex/prompts/ (Codex uses prompts/ not commands/)
    if [[ -d "$COMMANDS_DIR" ]]; then
        for cmd_file in "$COMMANDS_DIR"/*.md; do
            if [[ -f "$cmd_file" ]]; then
                copy_file "$cmd_file" "$CODEX_PROMPTS/$(basename "$cmd_file")"
            fi
        done
    fi

    echo "  Skills:  $CODEX_SKILLS/"
    echo "  Prompts: $CODEX_PROMPTS/"
    echo "  Invoke agents:  \$business-analyst, \$solution-architect, etc."
    echo "  Invoke commands: /bmad-status, /handoff, etc."
    INSTALLED_TOOLS+=("Codex CLI")
    echo ""
fi

# ============================================================
# Kiro (AWS)
# ============================================================
if [[ -d "$HOME/.kiro" ]] || command -v kiro &> /dev/null; then
    echo -e "${GREEN}✓ Kiro${NC} found"
    KIRO_SKILLS="$HOME/.kiro/skills"
    KIRO_STEERING="$HOME/.kiro/steering"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$KIRO_SKILLS"
        mkdir -p "$KIRO_STEERING"
    fi

    # Remove legacy bmad-* prefixed skill folders
    if [[ "$DRY_RUN" == false ]]; then
        for legacy in "$KIRO_SKILLS"/bmad-*/; do
            if [[ -d "$legacy" ]]; then
                rm -rf "$legacy"
                echo "  ✓ Removed legacy skill folder: $(basename "$legacy")"
            fi
        done
    fi

    # Copy shared context as auto-included steering file
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] write bmad-shared-context steering file -> $KIRO_STEERING/"
    else
        {
            echo "---"
            echo "description: BMAD shared context — organization standards and conventions"
            echo "inclusion: auto"
            echo "---"
            echo ""
            cat "$SHARED_CONTEXT"
        } > "$KIRO_STEERING/bmad-shared-context.md"
    fi

    # Copy all agents as folder-based skills to ~/.kiro/skills/<name>/SKILL.md
    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [DRY] mkdir + cp $agent_dir/SKILL.md -> $KIRO_SKILLS/$agent_name/SKILL.md"
            else
                mkdir -p "$KIRO_SKILLS/$agent_name"
                cp "$agent_dir/SKILL.md" "$KIRO_SKILLS/$agent_name/SKILL.md"
                if [[ -d "$agent_dir/references" ]]; then
                    cp -r "$agent_dir/references" "$KIRO_SKILLS/$agent_name/"
                fi
                if [[ -d "$agent_dir/templates" ]]; then
                    cp -r "$agent_dir/templates" "$KIRO_SKILLS/$agent_name/"
                fi
            fi
        fi
    done

    # Copy commands as manual-inclusion steering files (become /slash-commands in Kiro)
    if [[ -d "$COMMANDS_DIR" ]]; then
        for cmd_file in "$COMMANDS_DIR"/*.md; do
            if [[ -f "$cmd_file" ]]; then
                cmd_name="$(basename "$cmd_file" .md)"
                if [[ "$DRY_RUN" == true ]]; then
                    echo "  [DRY] transform command -> $KIRO_STEERING/$cmd_name.md"
                else
                    # Read existing frontmatter description, wrap with Kiro's inclusion: manual
                    desc=$(head -5 "$cmd_file" | grep "^description:" | sed 's/^description: *//')
                    {
                        echo "---"
                        echo "description: ${desc:-BMAD command: $cmd_name}"
                        echo "inclusion: manual"
                        echo "---"
                        echo ""
                        # Skip original frontmatter, keep body
                        awk '/^---$/{n++} n>=2{if(n==2 && /^---$/){n++;next}; print}' "$cmd_file"
                    } > "$KIRO_STEERING/$cmd_name.md"
                fi
            fi
        done
    fi

    echo "  Skills:   $KIRO_SKILLS/"
    echo "  Steering: $KIRO_STEERING/"
    echo "  Invoke skills by description match, commands with / prefix"
    INSTALLED_TOOLS+=("Kiro")
    echo ""
fi

# ============================================================
# Cursor
# ============================================================
if [[ -d "$HOME/.cursor" ]] || command -v cursor &> /dev/null; then
    echo -e "${GREEN}✓ Cursor${NC} found"
    CURSOR_RULES="$HOME/.cursor/rules"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$CURSOR_RULES"
    fi

    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            prepend_shared_context "$agent_dir/SKILL.md" "$CURSOR_RULES/${agent_name}.md"
        fi
    done

    # Copy Cursor-specific global rules (.mdc files)
    if [[ -d "$RULES_DIR/cursor/global" ]]; then
        for rule_file in "$RULES_DIR/cursor/global"/*.mdc; do
            if [[ -f "$rule_file" ]]; then
                copy_file "$rule_file" "$CURSOR_RULES/$(basename "$rule_file")"
            fi
        done
    fi

    echo "  Install path: $CURSOR_RULES/"
    INSTALLED_TOOLS+=("Cursor")
    echo ""
fi

# ============================================================
# Windsurf
# ============================================================
if [[ -d "$HOME/.windsurf" ]]; then
    echo -e "${GREEN}✓ Windsurf${NC} found"
    WINDSURF_RULES="$HOME/.windsurf/rules"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$WINDSURF_RULES"
    fi

    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            prepend_shared_context "$agent_dir/SKILL.md" "$WINDSURF_RULES/${agent_name}.md"
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

    echo "  Install path: $WINDSURF_RULES/"
    INSTALLED_TOOLS+=("Windsurf")
    echo ""
fi

# ============================================================
# GitHub Copilot
# ============================================================
if [[ -d "$HOME/.github" ]]; then
    echo -e "${GREEN}✓ GitHub Copilot${NC} found"
    COPILOT_INSTRUCTIONS="$HOME/.github/copilot-instructions.md"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] append all agents -> $COPILOT_INSTRUCTIONS"
        if [[ -d "$RULES_DIR/copilot/global" ]]; then
            echo "  [DRY] append copilot global rules -> $COPILOT_INSTRUCTIONS"
        fi
    else
        mkdir -p "$(dirname "$COPILOT_INSTRUCTIONS")"
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
    fi

    echo "  Install path: $COPILOT_INSTRUCTIONS"
    INSTALLED_TOOLS+=("GitHub Copilot")
    echo ""
fi

# ============================================================
# Gemini CLI
# ============================================================
if [[ -d "$HOME/.gemini" ]] || command -v gemini &> /dev/null; then
    echo -e "${GREEN}✓ Gemini CLI${NC} found"
    GEMINI_SKILLS="$HOME/.gemini/skills"
    GEMINI_INSTRUCTIONS="$HOME/.gemini/GEMINI.md"

    if [[ "$DRY_RUN" == false ]]; then
        mkdir -p "$GEMINI_SKILLS"
    fi

    # Remove legacy flat GEMINI.md if it exists (replaced by skills/ folder approach)
    if [[ "$DRY_RUN" == false ]] && [[ -f "$GEMINI_INSTRUCTIONS" ]]; then
        rm -f "$GEMINI_INSTRUCTIONS"
        echo "  ✓ Removed legacy GEMINI.md (replaced by skills/ folders)"
    fi

    # Remove legacy bmad-* prefixed skill folders
    if [[ "$DRY_RUN" == false ]]; then
        for legacy in "$GEMINI_SKILLS"/bmad-*/; do
            if [[ -d "$legacy" ]]; then
                rm -rf "$legacy"
                echo "  ✓ Removed legacy skill folder: $(basename "$legacy")"
            fi
        done
    fi

    # Copy shared context to ~/.gemini/
    copy_file "$SHARED_CONTEXT" "$HOME/.gemini/BMAD-SHARED-CONTEXT.md"

    # Copy all agents to ~/.gemini/skills/<agent-name>/SKILL.md (folder-based, same as Claude Code)
    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            if [[ "$DRY_RUN" == true ]]; then
                echo "  [DRY] mkdir + cp $agent_dir/SKILL.md -> $GEMINI_SKILLS/$agent_name/SKILL.md"
            else
                mkdir -p "$GEMINI_SKILLS/$agent_name"
                cp "$agent_dir/SKILL.md" "$GEMINI_SKILLS/$agent_name/SKILL.md"
                if [[ -d "$agent_dir/references" ]]; then
                    cp -r "$agent_dir/references" "$GEMINI_SKILLS/$agent_name/"
                fi
                if [[ -d "$agent_dir/templates" ]]; then
                    cp -r "$agent_dir/templates" "$GEMINI_SKILLS/$agent_name/"
                fi
                echo "  ✓ Installed skill: $agent_name"
            fi
        fi
    done

    # Copy Gemini-specific global rules into GEMINI.md if present
    if [[ -d "$RULES_DIR/gemini/global" ]]; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [DRY] write gemini global rules -> $GEMINI_INSTRUCTIONS"
        else
            {
                for rule_file in "$RULES_DIR/gemini/global"/*.md; do
                    if [[ -f "$rule_file" ]]; then
                        cat "$rule_file"
                        echo ""
                    fi
                done
            } > "$GEMINI_INSTRUCTIONS"
        fi
    fi

    echo "  Skills: $GEMINI_SKILLS/"
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

    echo "  Install path: $OPENCODE_INSTRUCTIONS"
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

    echo "  Install path: $AIDER_CONVENTIONS"
    INSTALLED_TOOLS+=("Aider")
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
