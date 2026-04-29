---
description: "[Enterprise Architect] Evaluate a technology against the radar (Adopt / Trial / Assess / Hold). Produces an ADR if the decision changes the stack."
argument-hint: "[technology name, e.g. 'ScyllaDB' or 'GraphQL']"
---

Evaluate a technology for placement on the BMAD technology radar and create an ADR if adopting it.

## Steps

1. Parse $ARGUMENTS to extract the technology name. If empty, ask: "What technology would you like to evaluate?"

2. Read `../../agents/enterprise-architect/references/technology-radar-detail.md` to understand the radar criteria and current placements.

3. Read `.bmad/tech-stack.md` if it exists to see the current approved stack.

4. Search the technology radar for the named technology.

5. If the technology is already on the radar:
   - Present its current ring (Adopt/Trial/Assess/Hold), rationale, and when-to-use guidance.
   - Ask: "Should I update its position or remove it from the radar?"

6. If the technology is NOT yet on the radar:
   - Assess the technology against these criteria:
     - **Maturity**: is it production-ready? (release cycle, stability)
     - **Team Expertise**: does the team have skills, or is there a learning curve?
     - **Operational Cost**: licensing, infrastructure, support, maintenance?
     - **Ecosystem**: community size, tooling, integrations, documentation quality?
     - **Differentiation**: does it solve a problem better than alternatives?
   - Recommend a ring: Adopt (preferred, proven), Trial (experimental, promising), Assess (monitoring), or Hold (not recommended).

7. Ask: "Based on this assessment, should I create an ADR to formally adopt/trial/assess this technology?"

8. If yes:
   - Run the `/new-adr` command with context: "Technology evaluation: [name], recommendation: [ring], rationale: [summary]".
   - Include the full assessment in the ADR Decision and Rationale sections.

9. If adopting or trialing, confirm: "Technology [name] added to radar as [ring]. ADR created → [file]."
