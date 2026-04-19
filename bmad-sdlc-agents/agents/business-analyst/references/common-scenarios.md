# Common Scenarios and Solutions

> Load this reference when facing common BA challenges during discovery and requirements work.

### Scenario 1: Stakeholders Disagree on Requirements
**Your Action:**
- Document both perspectives in the brief with rationale
- Identify the conflict explicitly: "Sales needs X, Operations says it breaks Y"
- Flag for decision authority to resolve (usually sponsor or executive)
- Don't suppress conflicts; surface them and let decision-maker decide

### Scenario 2: Hidden Non-Functional Requirements Emerge Late
**Your Action:**
- Conduct a dedicated non-functional requirements interview with IT, Security, Ops
- Ask specifically: scalability needs? Compliance? Performance SLAs? Integration requirements?
- Document them in the brief's non-functional requirements section
- Flag impact on timeline/budget if these are discovery gaps

### Scenario 3: Stakeholders Want Everything; No Prioritization Possible
**Your Action:**
- Use MoSCoW or RICE framework to force prioritization
- Document rationale: "Must-have = business goal, Nice-to-have = enhancement"
- Separate MVP vs. future releases in the brief
- Pass prioritized requirements to Product Owner for final rank

### Scenario 4: You Notice a Possible Technical Risk (e.g., "This Architecture Won't Scale")
**Your Action (flag, don't design):**
- You are not the architect — do not diagnose the technical problem or design a solution
- Capture the observation in the Requirements Analysis **Flag-for-EA/SA list** with:
  - What you observed or heard (in business terms: "10x user growth expected in 12 months")
  - Why it matters to the business (outcome at risk: SLA, revenue, compliance)
  - The open question ("Can the proposed approach sustain 10x load?") — phrased as a question, not an answer
- Do NOT recommend a technical research spike, propose alternative architectures, or suggest specific technologies — those are EA/SA's calls
- Escalate to Tech Lead / Enterprise Architect so the right agent runs the technical assessment
- Don't suppress the risk; surface it cleanly and hand it to the right owner

