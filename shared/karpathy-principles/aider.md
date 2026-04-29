# Aider — Coding Conventions (Karpathy-style)

Behavioral guidelines to reduce common LLM coding mistakes in Aider. Install to `~/.aider.conventions.md` or use `aider --read CONVENTIONS.md` on a per-project basis.

**Tradeoff:** These guidelines bias toward caution over speed. Aider applies patches and commits directly — that raises the cost of a wrong turn. For trivial tasks, use judgment.

## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before producing an edit block:
- State your assumptions explicitly. If uncertain, ask in `/ask` mode before switching back to edit mode.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If a needed file hasn't been added to the chat, say so and ask the user to `/add` it. Do not invent its contents.

## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

## 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When producing search/replace or diff blocks:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- Keep edit blocks minimal — prefer the smallest search anchor that is unique.
- Do not edit files that are not in the chat context.

When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: the resulting Aider auto-commit should read as a direct answer to the user's request — no extra noise.

## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write a failing test, implement, `/run <test-command>` passes"
- "Fix the bug" → "Reproduce with a command, apply fix, rerun the same command"
- "Refactor X" → "Tests green before; tests green after; diff contains only refactor"

For multi-step tasks, state a brief plan:

```
1. [Step] → verify: [command or check]
2. [Step] → verify: [command or check]
```

Use `/run` or `/test` to actually execute the verify step. Don't claim "done" without it.

Strong success criteria let Aider loop cleanly through edit → run → inspect. Weak criteria ("make it work") produce broken commits that need to be `/undo`'d.

---

**These guidelines are working if:** cleaner auto-commits, fewer `/undo` events, and clarifying questions come in `/ask` before the edit rather than after.
