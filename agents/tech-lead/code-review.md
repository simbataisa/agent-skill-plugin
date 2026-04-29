---
description: "[Tech Lead] Run a structured code review using the TL Code Review Checklist against a branch or set of files. Uses git worktree for isolation."
argument-hint: "[branch name or file paths]"
---

Execute a structured code review using the Tech Lead Code Review Checklist.

## Steps

1. Parse $ARGUMENTS to determine the target:
   - If it's a git branch name: identify it (e.g., 'feature/user-auth')
   - If it's file paths: use them directly (relative to project root)

2. If target is a branch:
   - Run: `git worktree add .bmad/worktrees/review [branch-name]`
   - If the worktree already exists, reuse it: `git worktree list`

3. Read `../../agents/tech-lead/templates/code-review-checklist.md` for the 12-item checklist.

4. For each item in the checklist, evaluate the code:
   - **Code Correctness**: logic sound, no obvious bugs, error cases handled
   - **Architecture Conformance**: follows the solution architecture, service boundaries respected
   - **Error Handling**: exceptions caught, error messages user-friendly, no silent failures
   - **Security**: no hardcoded secrets, no injection vulnerabilities, input validated, auth/authz correct
   - **Test Coverage**: unit tests written, coverage > 80%, happy path and edge cases covered
   - **Performance**: no obvious N+1 queries, no blocking operations, caching used appropriately
   - **Naming Conventions**: variables/functions/classes follow team conventions, descriptive names
   - **Documentation**: complex logic explained, public APIs documented, comments justify "why" not "what"
   - **Dependency Management**: no unnecessary dependencies, no security vulnerabilities in deps, versions pinned
   - **Code Duplication**: no repeated patterns (DRY principle)
   - **Code Readability**: single responsibility, testable, readable (functions < 25 lines preferred)
   - **Logging**: appropriate log levels, no logging sensitive data, structured logging used

5. For each item: mark as ✅ Pass, ⚠️ Warning, or ❌ Fail. Document line-specific findings.

6. Save the structured review to `docs/reviews/code-review-[branch-or-date].md` with format: Checklist (pass/warning/fail), Detailed Findings (by item, with code references), Verdict (APPROVED / CHANGES REQUESTED).

7. If using a worktree, clean up: `git worktree remove .bmad/worktrees/review`

8. Confirm: "Code review completed → [file]. Verdict: APPROVED / CHANGES REQUESTED. [N] issues found."
