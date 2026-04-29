# Worktree Close-out, Merge & Conflict-Resolution Protocol

This is the canonical end-of-job procedure for **every** BMAD agent that works in a git worktree (created via the **Git Worktree Workflow** section at the top of each SKILL.md). It covers the three stages: **request review → merge to main → clean up the worktree**, plus the **multi-agent conflict-resolution protocol** that runs when a peer agent has already merged to main while you were working.

> **Scope.** This reference applies whenever `.git` exists in the project root. If the project has no git, skip every step in this file — you have nothing to merge or clean.

---

## Stage 1 — Request human review (before merging anything)

After Step 4 ("Print the review summary") of your Completion Protocol, **stop and wait** for explicit human approval before merging. Your review request must include enough information for the human to make a decision without opening the worktree:

```
🟢 Ready for review — <agent-role>
   Branch:     <role>/<sprint-or-feature>          # e.g. be/sprint-3
   Worktree:   ../bmad-<role>-work                  # e.g. ../bmad-be-work
   Diff:       <files changed>, +<additions> / -<deletions>
   Top files:  <up to 5 most-changed paths>
   Commits:    <count> commit(s) since branch point
   Tests:      <pass/fail/skipped> (or "not applicable")
```

Include the diffstat in your review summary so the human can scan it. Generate it with:

```bash
git -C ../bmad-<role>-work --no-pager diff --stat $(git -C ../bmad-<role>-work merge-base HEAD main)
git -C ../bmad-<role>-work --no-pager log --oneline $(git -C ../bmad-<role>-work merge-base HEAD main)..HEAD
```

The human's reply maps to one of three actions:

| Reply              | Action                                                                                       |
|--------------------|----------------------------------------------------------------------------------------------|
| `approve` / `next` | Proceed to **Stage 2 — Merge**. (Both words map to the same action — `next` is legacy.)      |
| `refine: <notes>`  | Apply the feedback in your worktree, re-run quality gate, re-print the review summary.       |
| `defer`            | Leave the worktree open and stop. Useful when the human wants to come back later or another peer agent is still running and a coordinated merge is preferred. |

**Autonomous-mode short-circuit.** If `.bmad/signals/autonomous-mode` exists on disk, treat the request as auto-approved and proceed directly to Stage 2 *unless* you produced a `🚨` or `⚠️ blocker` flag in your review summary — those still require explicit human ack.

---

## Stage 2 — Merge to main

Run this from the project root (NOT from inside the worktree). The worktree path stays `../bmad-<role>-work` throughout.

### Step 2.1 — Refresh main

```bash
# Fetch the latest from origin (if a remote exists) and update local main
git fetch origin --quiet 2>/dev/null || true
git checkout main
git pull --ff-only origin main 2>/dev/null || true
```

### Step 2.2 — Detect concurrent-merge state

Check whether main has moved since your branch was created. **This is the multi-agent fork point** — if another agent (BE, FE, ME, etc.) already merged their parallel work, you'll need to rebase or resolve conflicts.

```bash
branch="<role>/<sprint-or-feature>"
worktree_dir="../bmad-<role>-work"

# Number of commits on main since the branch point
behind=$(git -C "$worktree_dir" rev-list --count HEAD..main)

if [ "$behind" -eq 0 ]; then
  echo "✓ Main is unchanged since branch — fast-forward merge will succeed."
else
  echo "⚠ Main has $behind new commit(s) since branch point — concurrent merge detected."
  echo "  Recent main commits:"
  git --no-pager log --oneline HEAD~"$behind"..HEAD
fi
```

### Step 2.3 — Try the merge

**If main is unchanged** (`$behind == 0`):

```bash
git merge --no-ff "$branch" -m "Merge $branch — <one-line summary of work>"
```

This always succeeds.

**If main has moved** (`$behind > 0`): rebase your branch onto the new main first, then fast-forward:

```bash
# Inside the worktree, rebase onto the updated main
git -C "$worktree_dir" fetch origin --quiet 2>/dev/null || true
git -C "$worktree_dir" rebase main
```

If `git rebase` exits with code 0 → no conflicts → continue:

```bash
git merge --ff-only "$branch"
```

If `git rebase` reports conflicts → enter the **Conflict Resolution Protocol** (Stage 3) below.

### Step 2.4 — Push (if a remote exists and the human's project pushes from agents)

```bash
# Only if origin/main is configured and the project policy allows agent pushes.
# Safe to skip; the human will push at their next sync.
git push origin main 2>/dev/null || true
```

Never `--force` push. If the push is non-fast-forward, that means main moved again *during* your merge — go back to Step 2.1.

### Step 2.5 — Tag (optional, if your role is the integration agent)

Tech Lead and Tester-QE may tag releases at sprint close-out. Other roles never tag.

---

## Stage 3 — Conflict Resolution Protocol (multi-agent)

You only enter this stage if Stage 2.3 reported merge conflicts. The conflicts arose because a peer agent's branch already landed on main and your changes overlap.

### Step 3.1 — Categorize every conflicting file

For each `<<<<<<<`-marked file, classify it using the matrix below. **Use the role's published file scope** from each agent's SKILL.md to decide:

| Conflict location                                  | Category                | Confidence to resolve solo |
|----------------------------------------------------|-------------------------|----------------------------|
| Files exclusively in *your* role's scope           | **My-domain**           | High — resolve and continue |
| Files exclusively in *another* role's scope        | **Their-domain**        | Low — request review (Step 3.3) |
| Shared files (build config, lockfiles, OpenAPI specs, shared types, integration tests, root README) | **Cross-domain**        | Medium — try, then verify (Step 3.4) |
| Migration files (DB schema migrations, infra IaC)  | **Sequenced**           | Never resolve solo — escalate to Tech Lead |

Role file-scope quick reference (extend per project):

| Role               | Owned scope (writes)                                                                 |
|--------------------|--------------------------------------------------------------------------------------|
| Backend Engineer   | `api/`, `services/`, `db/`, `migrations/`, `tests/api/`, `tests/integration/api/`     |
| Frontend Engineer  | `web/`, `apps/web/`, `components/`, `tests/web/`, `public/`, `*.css`, `*.tsx`         |
| Mobile Engineer    | `mobile/`, `ios/`, `android/`, `apps/mobile/`, `tests/mobile/`                        |
| UX Designer        | `docs/ux/`, `docs/ux/wireframes/`, `docs/ux/DESIGN.md`, `docs/ux/DESIGN.html`         |
| Tech Lead          | `docs/architecture/sprint-*-kickoff.md`, `.bmad/signals/`, root config audits         |
| Tester & QE        | `tests/e2e/`, `docs/testing/`, `playwright.config.*`                                  |
| Solution Architect | `docs/architecture/`, `docs/api-specs/openapi.yaml`                                   |
| Enterprise Arch.   | `docs/architecture/enterprise-*.md`, `docs/architecture/adr/`                         |
| InfoSec Architect  | `docs/security/`, `tests/security/`                                                   |
| DevSecOps          | `.github/workflows/`, `infra/`, `Dockerfile`, `pipelines/`, IaC                       |
| Product Owner      | `docs/prd.md`, `docs/project-brief.md`, `docs/stories/`                               |
| Business Analyst   | `docs/analysis/`, `docs/stories/*/acceptance-criteria.md`                             |

### Step 3.2 — Resolve my-domain conflicts (high-confidence)

For files in *your* owned scope only:

1. Open each conflicted file. Read both halves of every `<<<<<<<` … `=======` … `>>>>>>>` block.
2. Prefer **additive merges** when both intents are compatible (e.g. you added a function, the peer renamed an unrelated import — keep both). When the changes are mutually exclusive, prefer your version unless the peer's commit message clearly supersedes yours.
3. Run the relevant tests for the resolved file (your role's test suite) **before** marking the conflict resolved. If tests fail, the resolution is wrong — escalate (Step 3.3).
4. `git add <file>` once tests pass.

### Step 3.3 — Request peer review for their-domain or shared conflicts

For files in another role's scope, OR cross-domain files where you are not confident:

1. **Do NOT commit yet.** Stash the merge state but keep the conflicted files visible:
   ```bash
   git -C "$worktree_dir" status > /tmp/<role>-conflict-status.txt
   git -C "$worktree_dir" --no-pager diff --diff-filter=U > /tmp/<role>-conflict-diff.txt
   ```

2. **Write a sentinel** at `.bmad/signals/conflict-<my-role>-needs-<their-role>-review` containing:
   ```
   from: <my-role>
   to:   <their-role>
   branch: <role>/<sprint-or-feature>
   conflicting-files:
     - <path>
     - <path>
   proposed-resolution: <one-line summary>
   diff-snapshot: /tmp/<role>-conflict-diff.txt
   status-snapshot: /tmp/<role>-conflict-status.txt
   ```

3. **Print a structured peer-review request** to the human:
   ```
   🤝 Cross-domain conflict — needs <their-role> review
      My role:        <my-role>
      Their role:     <their-role>  (because conflict touches their owned scope)
      Conflicting:    <files>
      Proposal:       <one-line summary of how I would resolve>
      Sentinel:       .bmad/signals/conflict-<my-role>-needs-<their-role>-review

      Please run:
        /<their-role>     # they'll detect the sentinel and either approve or
                          # propose an alternative resolution
   ```

4. **In autonomous mode** (`.bmad/signals/autonomous-mode` exists), use the Agent tool (Claude Code / Kiro only) to spawn the peer agent directly — pass them the sentinel path and your proposed resolution. Wait for their response before completing the merge.

5. **On peer approval** (peer writes `.bmad/signals/conflict-resolved-<my-role>`): apply the agreed resolution, run all affected tests, `git add`, continue to Step 3.5.

6. **On peer disagreement**: stop. Hand both proposals to the human and ask them to choose. Do not merge until the human responds.

### Step 3.4 — Resolve cross-domain conflicts cautiously

Common cross-domain hotspots and how to handle them:

| Conflict file pattern                         | Strategy                                                                                  |
|-----------------------------------------------|-------------------------------------------------------------------------------------------|
| `package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `Cargo.lock` | **Don't hand-merge.** Delete the conflicted lockfile, run the package manager's install (`npm install` / `pnpm install` / `cargo build`) to regenerate, commit. |
| `package.json`, `pyproject.toml`, `Cargo.toml` (dependency lists) | Manually merge each section — combine all `dependencies` entries, take the higher version when two versions conflict. Run install + tests. |
| `docs/api-specs/openapi.yaml`                 | Both roles touched the API contract. Hand to **Solution Architect** via Step 3.3 sentinel. SA owns the contract. |
| `tsconfig.json`, `tailwind.config.*`, build config | Take both sets of additions. If options conflict, prefer the more permissive value and add a TODO for follow-up. |
| `docs/ux/DESIGN.md`                           | Hand to **UX Designer**. The design system is single-author. |
| Database migrations with conflicting numbers  | **Sequenced.** Don't auto-resolve. Escalate to Tech Lead — migrations need ordering. |
| Integration tests touching both halves        | Run the full integration suite after merging. If anything red, re-open the merge as a `refine:` request. |

### Step 3.5 — Complete the merge

Once all conflicts are resolved (whether solo or via peer review):

```bash
git -C "$worktree_dir" rebase --continue        # or: git rebase --skip / --abort
# then back at project root:
git checkout main
git merge --ff-only "$branch"
```

Run the full test suite one more time. If anything fails, hard-revert the merge and re-open the work as a `refine:` request:

```bash
git reset --hard HEAD~1   # (only if the merge commit is the last commit on main and tests are red)
```

> **Never** `git push --force` to main. If the push fails because main moved again, return to Stage 2.1.

---

## Stage 4 — Clean up the worktree

After a successful merge to main (or after `defer` if the human chose to leave it open — in which case skip this stage):

```bash
# Remove the working tree
git worktree remove ../bmad-<role>-work

# Delete the local branch
git branch -d "<role>/<sprint-or-feature>"

# (Optional) delete the remote-tracking branch if it was pushed
git push origin --delete "<role>/<sprint-or-feature>" 2>/dev/null || true
```

If `git worktree remove` errors because the worktree has untracked files, run:

```bash
git worktree remove --force ../bmad-<role>-work
```

…but only after confirming there are no unsaved changes (`git -C ../bmad-<role>-work status`). Force-removing a dirty worktree silently deletes uncommitted work.

Print the cleanup summary:

```
🧹 Worktree merged & cleaned
   Branch:    <role>/<sprint-or-feature>  → merged into main (commit <sha>)
   Worktree:  ../bmad-<role>-work          → removed
   Conflicts: <none | resolved solo | resolved with <other-role> review>
```

---

## Complete close-out checklist

Before printing the cleanup summary, verify each of these:

- [ ] Stage 1: human replied `approve` (or autonomous-mode short-circuit triggered with no blockers).
- [ ] Stage 2.2: concurrent-merge state checked; rebase onto latest main if needed.
- [ ] Stage 2.3: merge succeeded — either fast-forward or with all conflicts resolved.
- [ ] Stage 3 (if conflicts): every file categorised; my-domain resolved solo; their-domain / shared files reviewed by the relevant peer agent or the human.
- [ ] All affected tests pass on main after the merge.
- [ ] `.bmad/signals/conflict-*` sentinels related to this branch are deleted.
- [ ] `.bmad/handoff-log.md` records the merge with the merge SHA and any cross-agent-review notes.
- [ ] Stage 4: worktree removed; branch deleted; cleanup summary printed.

---

## Tool-specific addenda

### Claude Code / Kiro (with Agent tool)

If autonomous mode is on AND the conflict is their-domain, use the Agent tool to spawn the peer for an inline review without waiting for the human:

```
Agent({
  subagent_type: "<their-role>",
  description: "Cross-domain merge-conflict review",
  prompt: "I'm <my-role> merging branch <my-branch> to main. Conflicts touch your owned scope: <files>. My proposed resolution is at /tmp/<my-role>-conflict-diff.txt. Please review and reply 'approve' or 'propose-alternative: <details>'. Do NOT modify the working tree — read-only review only."
})
```

The peer's response feeds back into Step 3.3.5 / 3.3.6.

### Codex CLI / Gemini CLI / Cursor / Windsurf / Trae / Aider

Agent-spawning isn't available — always go through the human for cross-agent review. Print the request as a plain instruction:
```
🤝 Run /<their-role> next so they can review the conflict before I merge.
```

### GitHub Copilot

Use the Coding Agent's PR-scale workflow: open a PR for the role branch instead of merging directly to main, request review from the relevant peer's "agent persona" via PR comment, and only squash-merge after approval.
