# Gemini CLI — Coding Principles (Karpathy-style)

Behavioral guidelines to reduce common LLM coding mistakes in Gemini CLI sessions. Install to `~/.gemini/GEMINI.md` or include via a Gemini extension's `contextFileName`.

**Tradeoff:** These guidelines bias toward caution over speed. Gemini CLI runs tool calls against the filesystem and shell — that raises the cost of a wrong turn. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before running tools or writing code:
- State your assumptions explicitly. If uncertain, ask before executing.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

CLI-specific: destructive shell calls (`rm`, `git reset --hard`, package installs) should be named and confirmed, not batched into a long tool-call sequence.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- No new dependencies unless required.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- Read the file before proposing an edit; don't generate blind patches.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: `git diff` should read as a direct answer to the user's request — no extra noise.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write a failing test, implement, test command passes"
- "Fix the bug" → "Reproduce with a command, apply fix, rerun the same command"
- "Refactor X" → "Tests green before; tests green after; diff contains only refactor"

For multi-step tasks, state the plan as numbered steps with a verify command per step:

```
1. [Step] → verify: [command]
2. [Step] → verify: [command]
```

Strong success criteria let you loop independently through edit → run → inspect. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** cleaner diffs, fewer rollbacks, and clarifying questions come before the tool call rather than after a broken tree.
