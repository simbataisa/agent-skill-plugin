---
description: Create a Business Requirements Document (BRD) from stakeholder input. Produces docs/brd.md with business context, stakeholders, constraints, and success criteria.
argument-hint: "[project name or domain]"
---

Create a Business Requirements Document that captures the business vision, stakeholder landscape, constraints, and success metrics.

## Steps

1. Parse $ARGUMENTS to extract the project name or domain. If not provided, ask: "What is the project name or business domain?"

2. Check if `docs/brd.md` already exists. If it does, ask: "A BRD already exists. Would you like to (A) update it or (B) start fresh?"

3. Read `../../agents/product-owner/templates/brd-template.md` to get the template structure.

4. Read `.bmad/PROJECT-CONTEXT.md` if it exists to understand existing business context.

5. Ask the user for the following information (all at once, not one-by-one):
   - "What is the core business problem we're solving?"
   - "Who are the primary stakeholders? (list names/roles)"
   - "What are the target users or customer segments?"
   - "What constraints must we work within? (budget, timeline, regulatory, technical, market)"
   - "What does success look like? (2-3 measurable outcomes)"
   - "Are there any regulatory or compliance requirements? (GDPR, HIPAA, SOC2, etc.)"
   - "What is the target market/geography?"

6. Fill the BRD template with the user's input, organizing into sections: Executive Summary, Business Problem, Stakeholder Map, Target Users, Success Metrics, Constraints, Regulatory Requirements, Out of Scope.

7. Save to `docs/brd.md`.

8. Confirm: "BRD created → `docs/brd.md`. Next, run `/create-prd` to define the product requirements."
