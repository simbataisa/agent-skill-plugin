# Karpathy-Style Coding Principles — Cross-Tool Index

Tailored adaptations of the four behavioral principles from [forrestchang/andrej-karpathy-skills / CLAUDE.md](https://github.com/forrestchang/andrej-karpathy-skills/blob/main/CLAUDE.md) for every AI coder supported by `scripts/install-global.sh`.

## The Four Principles (shared spirit)

1. **Think Before Coding** — surface assumptions, ask when uncertain, don't silently pick between interpretations.
2. **Simplicity First** — minimum code that solves the problem; no speculative abstractions, flags, or error handling.
3. **Surgical Changes** — touch only what the request requires; don't "improve" adjacent code; clean up orphans you created, not pre-existing dead code.
4. **Goal-Driven Execution** — transform tasks into verifiable success criteria and loop until the verify step passes.

Each file in this folder keeps the same four sections, but tailors tone, examples, and tool-specific guidance (e.g. Cascade changesets for Windsurf, edit blocks for Aider, spec mode for Kiro, inline edits for Cursor).

## File Index

| Tool | File | Recommended install path |
|---|---|---|
| Claude Code | `claude-code.md` | `~/.claude/CLAUDE.md` (append) or project `CLAUDE.md` |
| Cowork | `cowork.md` | `~/.skills/CLAUDE.md` or project skill |
| Codex CLI | `codex-cli.md` | `~/.codex/AGENTS.md` |
| Kiro | `kiro.md` | `~/.kiro/steering/karpathy-principles.md` (has `inclusion: always` frontmatter) |
| Cursor | `cursor.mdc` | `~/.cursor/rules/karpathy-principles.mdc` or project `.cursor/rules/` (has `alwaysApply: true` frontmatter) |
| Windsurf | `windsurf.md` | `~/.windsurf/rules/karpathy-principles.md` or project `.windsurfrules` |
| GitHub Copilot | `copilot-instructions.md` | `.github/copilot-instructions.md` (repo) or `~/.github/copilot-instructions.md` (user) |
| Gemini CLI | `gemini-cli.md` | `~/.gemini/GEMINI.md` (append) or via a Gemini extension's `contextFileName` |
| OpenCode | `opencode.md` | `~/.opencode/instructions.md` or project `AGENTS.md` |
| Aider | `aider.md` | `~/.aider.conventions.md` or per-project `CONVENTIONS.md` with `aider --read` |

## Per-Tool Tailoring Notes

- **Claude Code** — references `TodoWrite` for multi-step plans. Closest to the canonical Karpathy source.
- **Cowork** — reframed for document/file creation (slides, sheets, docs) in addition to code; references `AskUserQuestion` and `TodoWrite`.
- **Codex CLI** — adds explicit caution for destructive shell commands and blind patches; success criteria are shell-verifiable.
- **Kiro** — uses Kiro steering frontmatter (`inclusion: always`); ties Principle 1 to the spec-mode requirements phase and Principle 4 to the tasks file.
- **Cursor** — `.mdc` with `alwaysApply: true`; covers Chat, Inline Edit (Cmd/Ctrl+K), and Agent mode; emphasizes diff-viewer verification and selection-scope discipline.
- **Windsurf** — targets Cascade's multi-file changesets; asks the agent to pause before edits touching >2 files.
- **GitHub Copilot** — covers inline suggestions, Chat, and Copilot Agent; ties success criteria to green PRs.
- **Gemini CLI** — tool-call safety plus `contextFileName` install guidance.
- **OpenCode** — near-verbatim; OpenCode consumes the same format as Claude Code.
- **Aider** — wraps principles in Aider idioms: `/add`, `/ask`, `/run`, `/undo`, edit blocks, auto-commits.

## How to Install (quick recipes)

```bash
SHARED=./bmad-sdlc-agents/shared/karpathy-principles

# Claude Code — append to user CLAUDE.md
cat "$SHARED/claude-code.md" >> ~/.claude/CLAUDE.md

# Cursor — copy as always-applied rule
cp "$SHARED/cursor.mdc" ~/.cursor/rules/000-karpathy-principles.mdc

# Windsurf — copy into rules folder
cp "$SHARED/windsurf.md" ~/.windsurf/rules/000-karpathy-principles.md

# Copilot — merge into user instructions
cat "$SHARED/copilot-instructions.md" >> ~/.github/copilot-instructions.md

# Kiro — copy as always-included steering file
cp "$SHARED/kiro.md" ~/.kiro/steering/karpathy-principles.md

# Codex CLI
cat "$SHARED/codex-cli.md" >> ~/.codex/AGENTS.md

# Gemini CLI
cat "$SHARED/gemini-cli.md" >> ~/.gemini/GEMINI.md

# OpenCode
cat "$SHARED/opencode.md" >> ~/.opencode/instructions.md

# Aider
cat "$SHARED/aider.md" >> ~/.aider.conventions.md

# Cowork
cat "$SHARED/cowork.md" >> ~/.skills/CLAUDE.md
```

## Signal that the Principles Are Working

Across all tools, you should see:

- Fewer unnecessary changes in diffs, changesets, or PRs.
- Fewer rewrites and rollbacks caused by overbuilding.
- Clarifying questions arriving **before** implementation rather than after a mistake.

## Credit

Adapted from Andrej Karpathy's coding-principles CLAUDE.md as collected in [forrestchang/andrej-karpathy-skills](https://github.com/forrestchang/andrej-karpathy-skills). Original four-principle structure preserved; wording tailored per tool.
