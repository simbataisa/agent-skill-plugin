# Template: User Story with Acceptance Criteria

A template for the Business Analyst to author detailed user stories with full acceptance criteria, business rules, and implementation context. Each story traces back to an epic (PO-owned) and a use case (BA-owned).

---

```markdown
# User Story: [US-XXX] — [Descriptive Title]

## Story Header

| Field | Value |
|---|---|
| **Story ID** | US-XXX |
| **Epic ID** | EP-XXX — [Epic Title] |
| **Related Use Case** | UC-XXX — [Use Case Title] |
| **Priority (MoSCoW)** | Must / Should / Could / Won't |
| **Complexity** | Simple / Medium / Complex |
| **Likely Engineering Owner** | Backend / Frontend / Mobile / Full-Stack |
| **Status** | Draft / Under Review / Approved / In Development / Done |
| **Author (BA)** | [Name] |
| **Date** | [YYYY-MM-DD] |

---

## Story Statement

**As a** [persona / role — be specific, not generic: "Busy field sales rep using iPhone in the field" not just "user"]
**I want** [specific capability or action they want to perform]
**So that** [the business value or outcome they receive — why they care]

**Example:**
> As a **field sales rep in a low-connectivity area**,
> I want to **draft an order offline and have it submit automatically when I reconnect**,
> so that **I don't lose orders when working in areas with poor signal**.

---

## Context & Background

[1–2 paragraphs explaining WHY this story exists. What is the current pain? How does this story fit within the epic? What business rule or stakeholder need drives it? This context helps engineers build the right thing, not just a technically correct thing.]

**Current state:** [How does the user do this today? What is painful about it?]

**Desired state:** [After this story is done, what is different for the user?]

**Dependencies on this story:** [What other stories or systems does this depend on, or what depends on this?]

---

## Acceptance Criteria

> Written in Given–When–Then (GWT) format. Each criterion must be independently testable by the Tester-QE without ambiguity.

### Happy Path (core flow must work)

- [ ] **AC-1:** Given [precondition], when [action], then [expected result]
  - Example: *Given the rep has an active session and a stable connection, when they submit a completed order, then the system saves the order and displays a confirmation with the order ID within 5 seconds.*

- [ ] **AC-2:** Given [precondition], when [action], then [expected result]

- [ ] **AC-3:** Given [precondition], when [action], then [expected result]

### Edge Cases (boundary conditions)

- [ ] **AC-4:** Given [edge condition], when [action], then [expected result]
  - Example: *Given the rep has drafted an order offline, when the device reconnects to the internet, then the draft automatically submits and the rep receives a push notification confirming submission.*

- [ ] **AC-5:** Given [edge condition], when [action], then [expected result]

### Error Cases (failure scenarios)

- [ ] **AC-6:** Given [failure condition], when [action], then [graceful error handling]
  - Example: *Given the payment gateway returns a timeout error, when the rep submits an order, then the system shows the message "Payment processing timed out. Your order draft has been saved — please try again." and the draft remains accessible.*

- [ ] **AC-7:** Given [failure condition], when [action], then [graceful error handling]

---

## Non-Functional Criteria

| Category | Requirement |
|---|---|
| **Performance** | [e.g., Response time < 2 seconds at P95 under normal load] |
| **Security** | [e.g., User can only view/edit their own orders; role enforcement server-side] |
| **Accessibility** | [e.g., All form fields have accessible labels; keyboard navigable; WCAG 2.1 AA] |
| **Data** | [e.g., Order ID generated server-side — not client-side; idempotent submission] |
| **Offline** | [e.g., If applicable — draft survives app restart; sync on reconnect] |

---

## Business Rules

Rules that govern the behaviour of this story. Must be enforced — not optional.

| Rule ID | Rule Description | Source / Owner |
|---|---|---|
| BR-001 | [e.g., Orders with total > $10,000 require manager approval before submission] | [e.g., Sales Policy v3.2] |
| BR-002 | [e.g., A rep may not place an order for a customer assigned to another rep's territory] | [e.g., Territory Management Policy] |
| BR-003 | [e.g., Order items must not exceed warehouse stock levels — out-of-stock items are blocked] | [e.g., Inventory System Integration] |

---

## Data Requirements

### Inputs (what the user provides or the system reads)

| Field | Type | Required? | Validation | Source |
|---|---|---|---|---|
| [e.g., Customer ID] | String (UUID) | Yes | Must exist in CRM | CRM lookup |
| [e.g., Product SKU] | String | Yes | Must match active product catalog | Product DB |
| [e.g., Quantity] | Integer | Yes | Min 1, Max 1000 | User input |
| [e.g., Delivery date] | Date | No | Must be >= today + 2 business days | User input |

### Outputs (what the system produces or persists)

| Output | Description |
|---|---|
| [e.g., Order ID] | Unique server-generated identifier (UUID v4); returned in confirmation response |
| [e.g., Order record] | Persisted in Orders table with status = "Submitted" |
| [e.g., Confirmation notification] | Email sent to rep + customer; Salesforce opportunity updated |
| [e.g., Audit log entry] | Written to audit_log table: who, what, when, from which IP |

---

## Dependencies

| Type | ID / Name | Description |
|---|---|---|
| **Depends On (must be done first)** | US-XXX | [e.g., Customer lookup API must exist before order submission] |
| **Blocks (cannot start until this is done)** | US-YYY | [e.g., Order confirmation screen depends on order ID being returned here] |
| **External System** | [e.g., Salesforce API] | [e.g., Customer data and opportunity update depend on Salesforce API access] |
| **ADR Reference** | [ADR-XXX] | [e.g., If this story touches an architectural decision, reference the ADR] |

---

## UI / UX Notes

[Any relevant UX context the BA wants to share with engineers. NOT a design spec — that comes from UX Designer. Just business-level UX intent.]

- [e.g., The confirmation message must display the order ID prominently — reps reference it when calling customers]
- [e.g., The error message must be in plain language — reps are not technical]
- [e.g., Refer to UX Designer's wireframe: `docs/ux/checkout-flow-v2.fig` — screen 4 shows the confirmation state]

---

## Test Hints for Tester-QE

[Optional — guidance to help TQE write tests efficiently. Not a test plan — just BA context.]

- [e.g., Test with a customer who has no previous orders — edge case for empty order history display]
- [e.g., Test simultaneous submission from two devices — check idempotency (same order not submitted twice)]
- [e.g., Test with a product that becomes out-of-stock between draft creation and submission]
- [e.g., Test with all required fields empty — verify each field shows a distinct error, not a generic one]

---

## Definition of Done

This story is done when ALL of the following are satisfied:

- [ ] All acceptance criteria verified and passing (BA or TQE sign-off)
- [ ] Code reviewed and approved by Tech Lead
- [ ] Unit tests written and passing (coverage ≥ 80% for new code)
- [ ] All business rules enforced server-side (not just client-side)
- [ ] Non-functional criteria met (performance, security, accessibility checked)
- [ ] No open P0 or P1 bugs
- [ ] Relevant documentation updated (API docs, runbooks if applicable)
- [ ] Story status updated in tracking system

---

## Open Questions

| Question | Impact | Owner | Resolved? |
|---|---|---|---|
| [e.g., Should the rep receive a copy of the order by email automatically?] | [Affects notification design] | [VP Sales] | ☐ No |
| [e.g., What happens if the customer account is on credit hold at submission time?] | [Affects validation logic] | [Finance] | ☐ No |
```
