---
description: "[Product Owner] Create a Product Requirements Document (PRD) from the BRD. Defines features, user requirements, MVP scope, and RICE prioritisation."
argument-hint: "[feature area or 'full' for complete PRD]"
---

Create a Product Requirements Document that translates business requirements into product features, user requirements, and MVP scope.

## Steps

1. Read `docs/brd.md` (required — fail with: "BRD not found. Run `/create-brd` first.").

2. Parse $ARGUMENTS. If empty or 'full', scope is the complete PRD. If a feature name is provided, scope is that feature area only.

3. Read `../../agents/product-owner/templates/prd-template.md` to get the template.

4. Read `.bmad/tech-stack.md` if it exists to understand technology constraints.

5. Ask the user for PRD details (all at once):
   - "What are the core product features? (list with brief descriptions)"
   - "How do users interact with each feature? (user workflows)"
   - "What is the MVP scope? (features in v1.0)"
   - "What features are post-MVP? (v1.1+)"
   - "What metrics will we use to measure product success?"
   - "Are there competitor products we should differentiate from?"

6. For each feature, assign a RICE score:
   - Reach: how many users will this impact (1-10)?
   - Impact: how much value per user (1-3: high, medium, low)?
   - Confidence: how confident are we (1-100%)?
   - Effort: how many person-weeks (1-10)?
   - RICE = (Reach × Impact × Confidence) / Effort

7. Fill the PRD template with: Product Overview, Target Users, Features (with RICE scores), MVP Definition, Success Metrics, Out of Scope.

8. Save to `docs/prd.md`.

9. Confirm: "PRD created → `docs/prd.md`. Next, run `/create-requirements` to perform deep requirements analysis."
