# Conversational Brainstorm Protocol

> **One canonical playbook for every BMAD agent's `brainstorm.md` sub-command.** When this file is referenced, follow it verbatim — do not ask questions in any other style.

## The rule

**Ask one question per turn. Wait for the human's answer. Then ask the next.**

Never dump a multi-section questionnaire. Never ask three or four questions in one message. Never present an unprioritized list. The brainstorm session is a conversation, not a survey.

The only exception: if the human voluntarily answers several questions in one reply (e.g. "let me dump everything I know"), accept it gracefully — but go back to one-at-a-time for the *next* question.

## Why one at a time

- A questionnaire of 12 questions is overwhelming and gets answered shallowly. A conversation of 12 exchanges builds context that's actually usable.
- Each answer **reshapes the rest of the question list**. A good first answer often makes three later questions redundant. You can't take advantage of that if you've already shown them.
- The human can stop the brainstorm at any point. Mid-questionnaire is awkward; mid-conversation is fine.
- The agent learns faster — each turn is a small bet, not a long monologue.

## How to run a brainstorm

### Step 1 — Build the question bank silently

Read the role-specific question bank in your `brainstorm.md` (the categorical lists under "Phase 2"). Treat it as a **prioritised pool**, not a checklist. From the bank, internally rank questions by:

1. **Decision-blocking** first — questions whose answers gate the next-step output (PRD, architecture, sprint plan, etc.).
2. **High-uncertainty** next — areas the project context files don't already answer.
3. **Nice-to-have** last — questions that refine but don't unblock.

Skip every question that's already answered by the context files (`.bmad/PROJECT-CONTEXT.md`, `docs/prd.md`, `docs/architecture/*.md`, etc.). Don't waste turns asking what's on disk.

### Step 2 — Ask the single most-impactful question

Open with a one-sentence orientation, then **one question** (with 2–3 concrete options + a recommended default if the answer space is bounded; open-ended only when truly unbounded).

Format:

```
[Brief one-line context — what you're trying to learn from this question.]

[Question?]
  Option A — [concrete answer] (recommended, because [reason from context])
  Option B — [concrete answer]
  Option C — [concrete answer]
```

Or for unbounded questions, name the missing context: *"I can't propose options here — could you share [the missing artefact] or describe [the unbounded space] in your own words?"*

### Step 3 — Wait for the answer

Stop. Do not pre-emptively ask the next question, do not list "while we're at it…", do not predict the answer. Wait.

If the user replies with a non-answer (e.g. "you decide", "no preference", "skip"), record `<no preference>` for that question and move on; do not re-ask.

### Step 4 — Capture, then re-prioritise

After each answer:

- Append it to your running running brief (a private structured list — see **Brief format** below).
- Re-rank the remaining bank. Many answers eliminate or reshape later questions.
- Decide: ask the next question, or do you already have enough to consolidate?

### Step 5 — Stop early when you have enough

You **do not** need to drain the bank. Stop asking when **any** of these is true:

- The next-step deliverable (PRD section, ADR, sprint kickoff, screen spec, etc.) can be written with the answers you have.
- The user signals they're done ("that's all I have", "skip the rest", "just write it up").
- You've asked **5–7 questions** and remaining bank items are nice-to-have.

A good brainstorm runs **3–7 turns**. More than 10 turns is usually a sign you're asking nice-to-haves; cut.

### Step 6 — Consolidate

Before any "Think Out Loud" or "Confirm Understanding" phase, **read the answers back** as a single structured brief. The human should see exactly what you captured, and have one chance to correct any misinterpretation before you start drafting the deliverable.

Format the consolidation as a quoted block-list:

```
> 📋 Brainstorm brief — <feature / topic>
>
> Captured answers:
>   - [Topic 1]: [user's answer, paraphrased tightly]
>   - [Topic 2]: [user's answer]
>   - [Topic 3]: [user's answer]
>   - …
>
> Open / unaddressed: [list any bank items you skipped that the human might still want to weigh in on]
> Tensions / contradictions: [any answers that conflict with each other or with project files]
> Inferred defaults: [places where the user said "you decide" — list what you defaulted to]

Reply 'ok' to lock in this brief and proceed to drafting, or 'edit: <correction>' to adjust before I start.
```

The brief is what the rest of the role's protocol consumes — it replaces the raw conversation as the input to the deliverable. Save it (verbatim) into `.bmad/brainstorms/<role>-<topic>.md` so it's auditable.

### Step 7 — Confirm and act

Standard 4-phase brainstorm flow continues from here:

- **Confirm Understanding** — restate the brief one more time as a one-paragraph plan-of-record.
- **Suggest Next Step** — name the specific BMAD command / artefact this should produce next.
- **Act on confirmation** — only after the human says "yes" / "ok" / "go".

## Brief format (the running structure you maintain privately)

While the conversation is in progress, maintain a private structured brief. It's a flat key/value list with the role's standard topics:

```
project: <name>
topic: <feature or seed>
asked-and-answered:
  <topic>: <answer>
  <topic>: <answer>
  …
skipped-already-on-disk:
  <topic>: <source-file>
  …
inferred-defaults:
  <topic>: <default> (because <reason>)
  …
open:
  - <topic>
```

When you consolidate (Step 6), this private structure becomes the public brief. Persist it.

## Tool-specific addenda

### Claude Code / Cowork — AskUserQuestion

When the AskUserQuestion tool is available, use it for every multi-choice question (Options A/B/C). It renders a tappable picker for the human, eliminates parsing ambiguity, and shows the recommended default visually. Reserve free-text prompts for genuinely unbounded questions only.

### Codex CLI / Cursor / Windsurf / Trae / Gemini CLI / Aider

No structured-question UI. Use plain text with the Option A/B/C format above. Wait for the human's reply in the chat stream.

### Kiro

Kiro has its own multi-choice picker — use it when available; otherwise fall back to plain text.

## Anti-patterns (do not do)

- ❌ **The wall-of-questions opener.** "Before we start, I have a few questions: 1. … 2. … 3. … 4. … 5. … 6. …" — never. Even if the user is technical and senior, the conversational ramp gets better answers.
- ❌ **Stacked clarifications.** Asking question N + a follow-up to question N − 1 in the same message. Pick one.
- ❌ **Asking what's already on disk.** Reading `.bmad/PROJECT-CONTEXT.md` first should eliminate ~30% of bank questions.
- ❌ **Confirming the obvious.** "So you want a login screen?" after the user said "build a login screen" is a wasted turn.
- ❌ **Performative consolidation.** A consolidation that just paraphrases the conversation back without surfacing tensions / inferred defaults / open items is theatre. The point is for the user to *catch your misinterpretations*.
- ❌ **Bypassing the consolidation.** Even on a 3-turn brainstorm, summarise before drafting. The human's chance to correct you is the most valuable moment in the whole flow.
