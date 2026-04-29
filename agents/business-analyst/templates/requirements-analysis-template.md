# Template: Requirements Analysis

The Business Analyst's primary output document. Produced after deep analysis of the Product Owner's BRD and PRD. This document is the primary input for the Enterprise Architect and UX Designer, who run in parallel from it.

---

```markdown
# Requirements Analysis — [Project / Feature Name]

## Document Information

| Field | Value |
|---|---|
| **Project / Feature** | |
| **Version** | v1.0 |
| **Date** | [YYYY-MM-DD] |
| **Business Analyst** | [Name] |
| **Input: BRD** | BRD v[X] dated [date] |
| **Input: PRD** | PRD v[X] dated [date] |
| **Status** | Draft / Under Review / Approved — Ready for EA + UX |

---

## Executive Summary

[2–3 paragraphs: What did the analysis find? What are the key insights, constraints, or risks that EA and UX must be aware of? Any significant gaps or unresolved questions the PO needs to address before architecture begins?]

**Key findings:**
1. [e.g., The Salesforce integration is more complex than stated in BRD — it requires both REST API and streaming for real-time sync]
2. [e.g., GDPR applies to more data entities than BRD captured — specifically, search query history must be treated as personal data]
3. [e.g., Offline mode requirement from a key stakeholder interview was not captured in the PRD — recommend adding to MVP scope]

---

## Stakeholder Analysis (Expanded)

[Deeper than the BRD stakeholder register. Includes conflict analysis, decision authority, and stakeholder-specific requirements.]

### Stakeholder Map

| Stakeholder | Role | Power | Interest | Primary Need | Key Concern | Critical Requirement |
|---|---|---|---|---|---|---|
| [Name] | [e.g., VP Sales] | High | High | [Real-time pipeline] | [Adoption resistance from reps] | [Dashboard must show live data, not T+1] |
| [Name] | [e.g., Field Rep] | Low | High | [Speed of order entry] | [Change from current process] | [Order submission < 5 minutes] |
| [Name] | [e.g., IT Security] | High | Medium | [Compliance posture] | [Data exposure via mobile] | [Data must never be stored on device unencrypted] |

### Stakeholder Conflicts

| Conflict | Stakeholder A | Stakeholder B | Description | Resolution / Recommendation |
|---|---|---|---|---|
| [e.g., Offline vs. Security] | Field Rep | IT Security | Reps want offline; Security concerned about device data exposure | Recommend encrypted local storage with remote wipe; flag for EA |
| [e.g., Speed vs. Approval gate] | Field Rep | Finance | Reps want instant submission; Finance wants all orders > $10k reviewed | Implement approval workflow: instant submission, async finance review |

---

## Requirements Decomposition

### Functional Requirements (Detailed)

Derived from PO's PRD features. These are specific, testable, and traceable to a BRD requirement.

| REQ-ID | Requirement | Source (BRQ-#) | Epic | Priority | Acceptance Test |
|---|---|---|---|---|---|
| REQ-001 | System shall allow a field rep to create a new order from a mobile device in < 5 minutes | BRQ-001 | EP-001 | Must | Timed usability test: 5 reps complete order in < 5 minutes on first use |
| REQ-002 | System shall auto-populate customer details when rep selects customer by name or ID | BRQ-001 | EP-001 | Must | Customer details (address, account number, discount tier) pre-filled within 2 seconds |
| REQ-003 | System shall sync order data bi-directionally with Salesforce within 30 seconds of submission | BRQ-002 | EP-002 | Must | Order appears in Salesforce opportunity within 30 seconds (tested via API polling) |
| REQ-004 | System shall generate a PDF invoice and email it to the customer within 1 minute of order approval | BRQ-003 | EP-003 | Must | Invoice PDF received by customer email within 60 seconds; format matches approved template |
| REQ-005 | Orders exceeding $10,000 shall require manager approval before confirmation is sent to customer | Sales Policy | EP-001 | Must | Orders > $10k status = "Pending Approval"; rep cannot confirm until manager approves |

### Non-Functional Requirements (Refined)

Derived from BRD business expectations. These are the specifications EA and SA will design to.

| NFR-ID | Category | Requirement | Source | Rationale |
|---|---|---|---|---|
| NFR-001 | Performance | API response for order submission ≤ 2 seconds at P95, 500 concurrent users | PRD | Reps use app between meetings; unacceptable to wait |
| NFR-002 | Availability | System availability ≥ 99.9% (excluding scheduled maintenance windows of max 2 hours/month) | PRD | Field reps work weekends and evenings across time zones |
| NFR-003 | Security | All data in transit encrypted with TLS 1.3; data at rest encrypted AES-256 | IT Security (interview) | Mobile device risk; corporate security policy |
| NFR-004 | Security | No customer order data stored in plaintext on the mobile device at any time | IT Security | Remote wipe scenario; regulatory obligation |
| NFR-005 | Data Retention | Order records retained for 7 years; user PII deletable on request within 30 days | GDPR + Legal | Regulatory obligation confirmed with Legal |
| NFR-006 | Scalability | System must support 500 concurrent users at launch and 5,000 within 36 months (10x headroom) | PRD | Company growth plan; avoid costly re-architecture |
| NFR-007 | Accessibility | All web-based components must meet WCAG 2.1 AA | Company Policy | Company-wide accessibility mandate |

---

## Gap Analysis

Gaps between what the PO defined and what analysis uncovered. Each gap is a decision point.

| GAP-ID | Gap Description | Discovered Via | Impact | Recommendation | Owner | Status |
|---|---|---|---|---|---|---|
| GAP-001 | Offline mode not in MVP PRD, but 3 of 5 interviewed field reps operate in no-signal areas daily | Stakeholder interviews | High — reps may reject adoption | Recommend adding offline-first capability to MVP; escalate to PO | PO | ☐ Open |
| GAP-002 | BRD mentions "Salesforce integration" but does not specify which Salesforce objects and sync direction | BRD review | High — EA cannot design integration without this | BA has drafted integration spec below; PO to confirm with Sales Ops | BA/PO | ☐ Open |
| GAP-003 | GDPR scope in BRD is limited to "customer PII" but search query history is also personal data under GDPR Art. 4 | Compliance review | Medium — compliance risk | EA must include search query log deletion in data retention design | EA | ☐ For EA |

---

## Business Rules Catalogue

All rules that govern business logic. Engineers must implement these — they are not suggestions.

| BR-ID | Rule | Category | Source | Impact |
|---|---|---|---|---|
| BR-001 | Orders exceeding $10,000 USD require manager approval before order is confirmed | Approval Policy | VP Sales (interview) | Approval workflow required in EP-001 |
| BR-002 | A rep may only view and edit orders for customers within their assigned territory | Territory Policy | Sales Ops | Row-level access control required; enforced server-side |
| BR-003 | Out-of-stock products must not be orderable — system blocks submission | Inventory Policy | Product Manager | Integration with inventory service required; real-time stock check |
| BR-004 | Discounts > 15% require manager approval in addition to standard order approval | Pricing Policy | Finance | Discount field triggers separate approval gate |
| BR-005 | All orders placed after 3:00 PM local warehouse time are processed the next business day | Operations Policy | Warehouse Ops | Order timestamp logic must account for warehouse timezone |
| BR-006 | Customer accounts on credit hold cannot have new orders submitted until hold is lifted | Credit Policy | Finance | Credit check required before submission; error must explain situation |
| BR-007 | Invoice currency must match the customer's account currency, regardless of rep's local currency | Finance Policy | Finance | Currency conversion handled by ERP (SAP), not by this system |

---

## Use Case Index

All use cases authored as part of this analysis. Full use case documents in `docs/analysis/use-cases/`.

| UC-ID | Title | Primary Actor | Priority | Epic | Related Stories |
|---|---|---|---|---|---|
| UC-001 | Submit New Order | Field Sales Rep | Must | EP-001 | US-1001, US-1002, US-1005, US-1006 |
| UC-002 | Approve High-Value Order | Sales Manager | Must | EP-001 | US-1003 |
| UC-003 | View Order History | Field Sales Rep | Should | EP-001 | US-1004 |
| UC-004 | Sync Order to Salesforce | System (automated) | Must | EP-002 | US-2001 |
| UC-005 | Generate and Send Invoice | System (automated) | Must | EP-003 | US-3001, US-3002 |
| UC-006 | Manager Pipeline Dashboard | Sales Manager | Should | EP-004 | US-4001 |

---

## User Story Index

All stories authored from this analysis. Full story documents in `docs/stories/`.

| Story ID | Title | Epic | MoSCoW | Phase | Complexity | Status |
|---|---|---|---|---|---|---|
| US-1001 | Create new order on mobile | EP-001 | Must | MVP | Complex | ☐ Draft |
| US-1002 | Auto-fill customer details from CRM | EP-001 | Must | MVP | Medium | ☐ Draft |
| US-1003 | Manager approval workflow for high-value orders | EP-001 | Must | MVP | Complex | ☐ Draft |
| US-1004 | View personal order history (last 90 days) | EP-001 | Should | MVP | Simple | ☐ Draft |
| US-2001 | Bi-directional Salesforce sync on order events | EP-002 | Must | MVP | Complex | ☐ Draft |
| US-3001 | Auto-generate PDF invoice on order completion | EP-003 | Must | MVP | Medium | ☐ Draft |
| US-3002 | Email invoice to customer on generation | EP-003 | Must | MVP | Simple | ☐ Draft |
| US-4001 | Manager real-time pipeline dashboard | EP-004 | Should | MVP | Complex | ☐ Draft |

---

## Integration Requirements

Systems this product must integrate with — detailed enough for EA to design the integration architecture.

| System | Integration Type | Direction | Data Exchanged | Trigger | Latency SLA | Owner |
|---|---|---|---|---|---|---|
| Salesforce CRM | REST API | Bi-directional | Customer data (read), Order data (write), Opportunity update (write) | On customer lookup (read); on order submission (write) | < 2 seconds read; < 30 seconds write | Sales Ops |
| SAP ERP | REST API | Outbound | Approved orders (write to SAP order management); Product catalog + stock (read) | On order approval | < 5 minutes | Finance / IT |
| Stripe | REST API | Outbound | Payment token, amount, currency, customer billing details | On order payment step | < 3 seconds | Finance |
| SendGrid | REST API | Outbound | Invoice PDF attachment, recipient email, order summary | On invoice generation | < 1 minute | IT |
| Corporate IdP (Okta) | OAuth 2.0 / OIDC | Inbound | User identity, roles, territory assignment | On login | < 1 second | IT Security |

---

## Data Dictionary

Data entities this system creates or consumes. Used by SA for data model design, EA for compliance design.

| Entity | Description | Classification | Regulatory Flag | Retention |
|---|---|---|---|---|
| Order | Core transaction record — rep, customer, products, amounts, status | Internal | SOX (financial record) | 7 years |
| Customer | Account details — company, address, account manager, credit status | Confidential | GDPR (business entity contact data) | While active + 3 years |
| Product | SKU, name, price, stock level, category | Internal | None | While active |
| Invoice | PDF document — order summary, amounts, customer billing details | Restricted | SOX; GDPR | 7 years |
| SearchQuery | Rep's search terms in product catalog | Confidential | GDPR (personal data per Art. 4) | 90 days; must be deletable on request |
| AuditLog | System event log — who did what, when, from which device | Restricted | SOX; GDPR | 7 years |

---

## Feasibility Assessment

| Dimension | Status | Key Findings |
|---|---|---|
| **Technical** | 🟡 YELLOW | Offline-first is achievable but adds complexity; Salesforce streaming API requires enterprise license (confirm with IT) |
| **Timeline** | 🟡 YELLOW | MVP scope is tight for [proposed date]; GAP-001 (offline) decision must be made in 1 week or timeline extends |
| **Budget** | 🟢 GREEN | Estimated within $500k budget; EA cost model needed to validate cloud infrastructure costs |
| **Organizational** | 🟡 YELLOW | Finance team will need 2-week training on new invoice workflow; plan ahead |

**Overall Risk Level:** MEDIUM

---

## Risk Register

| Risk ID | Risk | Category | Likelihood | Impact | Score | Mitigation |
|---|---|---|---|---|---|---|
| RSK-001 | Salesforce API rate limits block real-time sync during peak (all reps submitting at end of day) | Technical | Medium | High | 8 | EA to design retry queue + exponential backoff; test load at 500 concurrent submissions |
| RSK-002 | Field reps resist adoption — current paper process feels faster for simple orders | Change Management | High | High | 9 | PO to include rep champions in UAT; UX Designer to prioritize speed and simplicity |
| RSK-003 | GAP-001 (offline mode) not resolved before architecture begins — EA designs online-only; expensive to retrofit | Scope | Medium | High | 8 | Escalate GAP-001 to PO for decision within 1 week |
| RSK-004 | GDPR search query deletion not designed in from the start — compliance gap discovered in audit | Compliance | Low | Critical | 7 | EA must include search log TTL and deletion job in compliance framework |

---

## Assumptions

- [e.g., All field reps have company-issued smartphones (iOS 16+ or Android 13+) with MDM enrolled]
- [e.g., Salesforce Enterprise or Unlimited license is available — required for Streaming API]
- [e.g., Corporate Okta identity provider is available and IT will provide OAuth app registration]
- [e.g., BA-validated: all customers in Salesforce have complete address records (no data quality cleanup needed)]

---

## Unknowns — Research Needed

| Unknown | Why It Matters | Who Must Answer | Deadline |
|---|---|---|---|
| [e.g., Does Salesforce org have Streaming API enabled?] | [Affects real-time sync design for EA] | [IT / Sales Ops] | [date] |
| [e.g., What is the credit hold check API in SAP?] | [Affects BR-006 implementation — SA needs API spec] | [SAP team / Finance] | [date] |

---

## Handoff Notes

### For Enterprise Architect (EA)

**Priority items EA must know:**
1. **GAP-001 (offline mode)** — Decision pending with PO. Design online-first but keep offline as a seam; avoid patterns that make offline impossible to retrofit.
2. **NFR-004 (no plaintext on device)** — Encrypted local storage required if offline is approved. Platform-level key management needed.
3. **Integration with Salesforce** — May require Streaming API (Enterprise license); confirm with IT before finalizing integration architecture.
4. **GDPR search query log** — 90-day TTL and user-deletable. Must be in compliance framework from day one.
5. **SOX controls** — Order and invoice records are financial records. Audit log must be immutable and retained 7 years.

### For UX Designer

**Priority items UX must know:**
1. **Speed is the #1 user priority** — All 5 reps interviewed said current process is too slow. Every extra tap is a risk to adoption.
2. **Approval workflow is a key flow** — Manager approval for high-value orders must be frictionless; managers are mobile too and can't tolerate complex approval UI.
3. **Error messaging matters** — Reps are not technical. Credit hold errors, approval gates, and submission failures must be explained in plain business language.
4. **Offline state indication** — Whether or not offline mode is in MVP, the app must clearly show network status (online/offline indicator).
5. **Personas for deep dives:** Field Rep + Sales Manager are the two primary personas. Finance Manager uses web only.

---

**Sign-off:** Business Analyst — [Name]
**Date:** [YYYY-MM-DD]
**Status:** ☐ Draft | ☐ Under Review | ☐ Approved — Ready for EA + UX handoff
```
