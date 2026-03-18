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

    # Copy all agents to ~/.claude/skills/
    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            copy_file "$agent_dir/SKILL.md" "$CLAUDE_SKILLS/${agent_name}.md"
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

    # Merge global hooks settings into ~/.claude/settings.json
    if [[ -f "$HOOKS_DIR/settings.json" ]]; then
        local_settings="$CLAUDE_HOOKS_DIR/settings.json"
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [DRY] merge $HOOKS_DIR/settings.json -> $local_settings"
        else
            if [[ ! -f "$local_settings" ]]; then
                cp "$HOOKS_DIR/settings.json" "$local_settings"
            else
                echo -e "  ${YELLOW}⚠ $local_settings already exists — skipping hook merge.${NC}"
                echo "    Manually merge: $HOOKS_DIR/settings.json"
            fi
        fi
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

    for agent_dir in "$AGENTS_DIR"/*; do
        if [[ -d "$agent_dir" ]]; then
            agent_name="$(basename "$agent_dir")"
            copy_file "$agent_dir/SKILL.md" "$COWORK_SKILLS/${agent_name}.md"
        fi
    done

    echo "  Install path: $COWORK_SKILLS/"
    INSTALLED_TOOLS+=("Cowork")
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
    GEMINI_INSTRUCTIONS="$HOME/.gemini/GEMINI.md"

    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY] create with shared context + all agents -> $GEMINI_INSTRUCTIONS"
    else
        mkdir -p "$(dirname "$GEMINI_INSTRUCTIONS")"
        {
            cat "$SHARED_CONTEXT"
            for agent_dir in "$AGENTS_DIR"/*; do
                if [[ -d "$agent_dir" ]]; then
                    echo ""
                    cat "$agent_dir/SKILL.md"
                fi
            done
            if [[ -d "$RULES_DIR/gemini/global" ]]; then
                for rule_file in "$RULES_DIR/gemini/global"/*.md; do
                    if [[ -f "$rule_file" ]]; then
                        echo ""
                        cat "$rule_file"
                    fi
                done
            fi
        } > "$GEMINI_INSTRUCTIONS"
    fi

    echo "  Install path: $GEMINI_INSTRUCTIONS"
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
echo ""

exit 0
