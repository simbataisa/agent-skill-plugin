#!/bin/bash

# BMAD Update Script
# Updates globally installed BMAD agents from source
# Usage: ./scripts/update.sh [--tools <tool1,tool2>] [--check-only]

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"
SHARED_CONTEXT="$BASE_DIR/shared/BMAD-SHARED-CONTEXT.md"
AGENTS_DIR="$BASE_DIR/agents"
VERSION_FILE="$HOME/.bmad-version"
CHECK_ONLY=false
SPECIFIED_TOOLS=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --tools)
            SPECIFIED_TOOLS="$2"
            shift 2
            ;;
        --check-only)
            CHECK_ONLY=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: ./scripts/update.sh [--tools <tool1,tool2>] [--check-only]"
            exit 1
            ;;
    esac
done

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  BMAD Update Script${NC}"
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

# Function to get source checksum
get_source_checksum() {
    (
        cat "$SHARED_CONTEXT"
        find "$AGENTS_DIR" -name "SKILL.md" -exec cat {} \;
    ) | md5sum | awk '{print $1}'
}

# Function to get git commit hash
get_commit_hash() {
    if git -C "$BASE_DIR" rev-parse HEAD &> /dev/null; then
        git -C "$BASE_DIR" rev-parse HEAD
    else
        echo "unknown"
    fi
}

# Get current source info
CURRENT_CHECKSUM="$(get_source_checksum)"
CURRENT_COMMIT="$(get_commit_hash)"
CURRENT_TIMESTAMP="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"

echo -e "${CYAN}Current source:${NC}"
echo "  Checksum: $CURRENT_CHECKSUM"
echo "  Commit: $CURRENT_COMMIT"
echo "  Time: $CURRENT_TIMESTAMP"
echo ""

# Get previous version info
if [[ -f "$VERSION_FILE" ]]; then
    echo -e "${CYAN}Previous installed version:${NC}"
    cat "$VERSION_FILE" | grep -v "^$" | sed 's/^/  /'
    echo ""

    PREV_CHECKSUM=$(grep "CHECKSUM=" "$VERSION_FILE" 2>/dev/null | cut -d= -f2 || echo "")

    if [[ "$PREV_CHECKSUM" == "$CURRENT_CHECKSUM" ]]; then
        echo -e "${GREEN}✓ Already up to date${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠ Updates available${NC}"
        echo ""
    fi
else
    echo -e "${YELLOW}No previous version found - fresh install${NC}"
    echo ""
fi

if [[ "$CHECK_ONLY" == true ]]; then
    echo "Use: ./scripts/update.sh (without --check-only) to install updates"
    exit 0
fi

# Determine which tools to update
if [[ -z "$SPECIFIED_TOOLS" ]]; then
    # Auto-detect all installed tools
    TOOLS_TO_UPDATE=()

    [[ -d "$HOME/.claude" ]] || command -v claude &> /dev/null && TOOLS_TO_UPDATE+=("claude")
    [[ -d "$HOME/.cursor" ]] || command -v cursor &> /dev/null && TOOLS_TO_UPDATE+=("cursor")
    [[ -d "$HOME/.windsurf" ]] && TOOLS_TO_UPDATE+=("windsurf")
    [[ -d "$HOME/.github" ]] && TOOLS_TO_UPDATE+=("copilot")
    [[ -d "$HOME/.gemini" ]] || command -v gemini &> /dev/null && TOOLS_TO_UPDATE+=("gemini")
    [[ -d "$HOME/.opencode" ]] || command -v opencode &> /dev/null && TOOLS_TO_UPDATE+=("opencode")
    [[ -d "$HOME/.aider" ]] || command -v aider &> /dev/null && TOOLS_TO_UPDATE+=("aider")
    [[ -d "$HOME/.skills" ]] && TOOLS_TO_UPDATE+=("cowork")
else
    # Parse comma-separated tool list
    IFS=',' read -ra TOOLS_TO_UPDATE <<< "$SPECIFIED_TOOLS"
fi

if [[ ${#TOOLS_TO_UPDATE[@]} -eq 0 ]]; then
    echo -e "${RED}✗ No tools found to update${NC}"
    exit 1
fi

echo -e "${BLUE}Updating ${#TOOLS_TO_UPDATE[@]} tools...${NC}"
echo ""

UPDATED_COUNT=0

# Update function for each tool
update_tool() {
    local tool="$1"

    case "$tool" in
        claude)
            echo -e "${CYAN}Claude Code${NC}"
            CLAUDE_SKILLS="$HOME/.claude/skills"
            mkdir -p "$CLAUDE_SKILLS"
            cp "$SHARED_CONTEXT" "$HOME/.claude/BMAD-SHARED-CONTEXT.md"
            for agent_dir in "$AGENTS_DIR"/*; do
                if [[ -d "$agent_dir" ]]; then
                    agent_name="$(basename "$agent_dir")"
                    cp "$agent_dir/SKILL.md" "$CLAUDE_SKILLS/${agent_name}.md"
                fi
            done
            echo "  ✓ Updated"
            ((UPDATED_COUNT++))
            ;;
        cursor)
            echo -e "${CYAN}Cursor${NC}"
            CURSOR_RULES="$HOME/.cursor/rules"
            mkdir -p "$CURSOR_RULES"
            for agent_dir in "$AGENTS_DIR"/*; do
                if [[ -d "$agent_dir" ]]; then
                    agent_name="$(basename "$agent_dir")"
                    {
                        cat "$SHARED_CONTEXT"
                        echo ""
                        cat "$agent_dir/SKILL.md"
                    } > "$CURSOR_RULES/${agent_name}.md"
                fi
            done
            echo "  ✓ Updated"
            ((UPDATED_COUNT++))
            ;;
        windsurf)
            echo -e "${CYAN}Windsurf${NC}"
            WINDSURF_RULES="$HOME/.windsurf/rules"
            mkdir -p "$WINDSURF_RULES"
            for agent_dir in "$AGENTS_DIR"/*; do
                if [[ -d "$agent_dir" ]]; then
                    agent_name="$(basename "$agent_dir")"
                    {
                        cat "$SHARED_CONTEXT"
                        echo ""
                        cat "$agent_dir/SKILL.md"
                    } > "$WINDSURF_RULES/${agent_name}.md"
                fi
            done
            echo "  ✓ Updated"
            ((UPDATED_COUNT++))
            ;;
        copilot)
            echo -e "${CYAN}GitHub Copilot${NC}"
            COPILOT_INSTRUCTIONS="$HOME/.github/copilot-instructions.md"
            mkdir -p "$(dirname "$COPILOT_INSTRUCTIONS")"
            {
                cat "$SHARED_CONTEXT"
                for agent_dir in "$AGENTS_DIR"/*; do
                    if [[ -d "$agent_dir" ]]; then
                        echo ""
                        cat "$agent_dir/SKILL.md"
                    fi
                done
            } > "$COPILOT_INSTRUCTIONS"
            echo "  ✓ Updated"
            ((UPDATED_COUNT++))
            ;;
        gemini)
            echo -e "${CYAN}Gemini CLI${NC}"
            GEMINI_INSTRUCTIONS="$HOME/.gemini/GEMINI.md"
            mkdir -p "$(dirname "$GEMINI_INSTRUCTIONS")"
            {
                cat "$SHARED_CONTEXT"
                for agent_dir in "$AGENTS_DIR"/*; do
                    if [[ -d "$agent_dir" ]]; then
                        echo ""
                        cat "$agent_dir/SKILL.md"
                    fi
                done
            } > "$GEMINI_INSTRUCTIONS"
            echo "  ✓ Updated"
            ((UPDATED_COUNT++))
            ;;
        opencode)
            echo -e "${CYAN}OpenCode${NC}"
            OPENCODE_INSTRUCTIONS="$HOME/.opencode/instructions.md"
            mkdir -p "$(dirname "$OPENCODE_INSTRUCTIONS")"
            {
                cat "$SHARED_CONTEXT"
                for agent_dir in "$AGENTS_DIR"/*; do
                    if [[ -d "$agent_dir" ]]; then
                        echo ""
                        cat "$agent_dir/SKILL.md"
                    fi
                done
            } > "$OPENCODE_INSTRUCTIONS"
            echo "  ✓ Updated"
            ((UPDATED_COUNT++))
            ;;
        aider)
            echo -e "${CYAN}Aider${NC}"
            AIDER_CONVENTIONS="$HOME/.aider.conventions.md"
            mkdir -p "$(dirname "$AIDER_CONVENTIONS")"
            if [[ ! -f "$AIDER_CONVENTIONS" ]]; then
                cp "$SHARED_CONTEXT" "$AIDER_CONVENTIONS"
            else
                {
                    cat "$AIDER_CONVENTIONS"
                    echo ""
                    cat "$SHARED_CONTEXT"
                } > "$AIDER_CONVENTIONS.tmp"
                mv "$AIDER_CONVENTIONS.tmp" "$AIDER_CONVENTIONS"
            fi
            echo "  ✓ Updated"
            ((UPDATED_COUNT++))
            ;;
        cowork)
            echo -e "${CYAN}Cowork${NC}"
            COWORK_SKILLS="$HOME/.skills/skills"
            mkdir -p "$COWORK_SKILLS"
            for agent_dir in "$AGENTS_DIR"/*; do
                if [[ -d "$agent_dir" ]]; then
                    agent_name="$(basename "$agent_dir")"
                    cp "$agent_dir/SKILL.md" "$COWORK_SKILLS/${agent_name}.md"
                fi
            done
            echo "  ✓ Updated"
            ((UPDATED_COUNT++))
            ;;
        *)
            echo -e "${RED}✗ Unknown tool: $tool${NC}"
            ;;
    esac
}

# Update each tool
for tool in "${TOOLS_TO_UPDATE[@]}"; do
    update_tool "$tool"
done

echo ""

# Update version file
mkdir -p "$(dirname "$VERSION_FILE")"
{
    echo "# BMAD Installation Version"
    echo "INSTALLED=$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
    echo "CHECKSUM=$CURRENT_CHECKSUM"
    echo "COMMIT=$CURRENT_COMMIT"
    echo "SOURCE=$BASE_DIR"
} > "$VERSION_FILE"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Update Summary${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}Successfully updated ${UPDATED_COUNT} tools${NC}"
echo ""
echo "Updated tools:"
for tool in "${TOOLS_TO_UPDATE[@]}"; do
    echo "  • $tool"
done
echo ""
echo "Version info saved to: $VERSION_FILE"
echo ""

exit 0
