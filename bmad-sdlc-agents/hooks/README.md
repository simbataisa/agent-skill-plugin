# BMAD Claude Code Hooks

This directory contains global and project-level hooks for the BMAD SDLC agent suite, integrating with Claude Code's hook system to enforce conventions, validate paths, and track artifact handoffs.

## Overview

### Global Hooks (`hooks/global/`)
Applied to **all projects** using BMAD. Located in `~/.claude/hooks/`.

- **validate-bmad-paths.sh**: Warns when writing outside allowed BMAD directories (docs/, src/, tests/, .bmad/)
- **check-direct-db.sh**: Warns against direct database mutations; recommends migration files instead
- **notify-doc-written.sh**: Logs artifacts written to docs/ for visibility

### Project Hooks (`hooks/project/`)
Applied to the **current project only**. Located in `.claude/hooks/` in your project root.

- **enforce-conventions.sh**: Validates test file naming (.test.ts, _test.go, test_.py) and migration file patterns (V{N}__{desc}.sql)
- **check-bmad-context.sh**: Ensures PROJECT-CONTEXT.md exists and is initialized
- **auto-handoff-log.sh**: Auto-appends to handoff-log.md when key artifacts are written
- **session-summary.sh**: Prints a summary of files modified during the session when Claude stops

## Installation

### Global Installation

1. Create the hooks directory:
   ```bash
   mkdir -p ~/.claude/hooks
   ```

2. Copy global hook scripts:
   ```bash
   cp hooks/global/scripts/*.sh ~/.claude/hooks/
   chmod +x ~/.claude/hooks/*.sh
   ```

3. Copy global settings to Claude Code config:
   ```bash
   cp hooks/global/settings.json ~/.claude/settings.json
   ```

### Project Installation

1. In your project root, create `.claude/hooks/`:
   ```bash
   mkdir -p .claude/hooks
   ```

2. Copy project hook scripts:
   ```bash
   cp hooks/project/scripts/*.sh .claude/hooks/
   chmod +x .claude/hooks/*.sh
   ```

3. Copy project settings:
   ```bash
   cp hooks/project/settings.json .claude/settings.json
   ```

## Hook Environment Variables

Claude Code provides these variables to hook scripts:

- `$CLAUDE_TOOL_INPUT_PATH`: Path being written or modified (for Write/Edit/MultiEdit)
- `$CLAUDE_TOOL_INPUT_CONTENT`: Content being written (for Write)
- `$CLAUDE_TOOL_INPUT_COMMAND`: Command being executed (for Bash)
- `$CLAUDE_HOOKS_DIR`: Global hooks directory (default: ~/.claude/hooks/)

## Making Scripts Executable

All hook scripts must be executable:

```bash
chmod +x ~/.claude/hooks/*.sh
chmod +x .claude/hooks/*.sh
```

## How Hooks Work

1. **PreToolUse**: Runs before a tool is executed. Can warn or block (exit with non-zero).
2. **PostToolUse**: Runs after a tool completes successfully.
3. **Stop**: Runs when Claude stops (end of conversation).

All hooks in this suite exit with code 0 (non-blocking), allowing warnings without preventing tool execution.

## Examples

### Example: Global Path Validation

When writing to a BMAD project, the global validator checks the path:

```
Claude writes to: config/legacy/settings.json
Output: ⚠️  BMAD: Writing to 'config/legacy/settings.json' — ensure this is intentional. BMAD artifacts should go in docs/
```

### Example: Direct DB Mutation Warning

```bash
# Command:
psql -d mydb -c "INSERT INTO users VALUES (1, 'test');"

# Output:
⚠️  BMAD: Direct DB mutation detected. Use migration files (Flyway/Liquibase/golang-migrate) instead of running SQL directly.
```

### Example: Session Summary

```
📋 BMAD Session Summary: 3 files written. Check .bmad/handoff-log.md for details.
```

## Customization

To customize hooks:

1. Edit the script files directly
2. Add new matchers to settings.json for different tool types
3. Use grep, regex, or bash logic to refine validation rules

For global changes, edit `~/.claude/hooks/` and `~/.claude/settings.json`.
For project-specific rules, edit `.claude/hooks/` and `.claude/settings.json` in your project.
