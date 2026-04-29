# Template: Product Requirements Document (PRD)

A structured template for the Product Owner to define product features and MVP scope from the Business Requirements Document. The PRD describes WHAT the product must do in business terms — not HOW it will be built.

---

```markdown
# Product Requirements Document — [Product Name]

## Document Information

| Field | Value |
|---|---|
| **Product / Feature Name** | |
| **Version** | v1.0 |
| **Date** | [YYYY-MM-DD] |
| **Product Owner** | [Name] |
| **Input Document** | BRD v[X] dated [date] |
| **Status** | Draft / Under Review / Approved |

---

## Product Overview

[2–3 sentences: What is this product? Who uses it? What problem does it solve in user terms? Written for a business audience — no implementation details.]

---

## Objectives & Outcomes

| Objective | Success Metric | Target | Source (BRQ-#) |
|---|---|---|---|
| [e.g., Empower field reps to submit orders on mobile] | [e.g., % orders submitted via mobile] | [e.g., > 80% within 60 days] | BRQ-001 |
| [e.g., Eliminate manual invoicing] | [e.g., Finance team hours saved/week] | [e.g., 10 hrs/week recovered] | BRQ-003 |

---

## User Personas

| Persona | Description | Primary Goal | Key Pain Today |
|---|---|---|---|
| **[Persona 1 Name]** | [e.g., Field Sales Rep — uses iPhone in the field, 5–15 min windows between meetings] | [e.g., Submit orders quickly without going back to the office] | [e.g., Paper order forms; lost orders; delays in processing] |
| **[Persona 2 Name]** | [e.g., Finance Manager — processes invoices and reconciles orders daily] | [e.g., Receive accurate invoices automatically, zero manual entry] | [e.g., Re-keying orders from paper forms; errors; 2-hour daily task] |
| **[Persona 3 Name]** | [e.g., Sales Manager — monitors team pipeline and approves discounts] | [e.g., Real-time visibility on team orders] | [e.g., Reports are 24 hours stale; discount approvals via email] |

---

## Epic Overview

High-level capability groupings. Each epic maps to one or more BRD requirements. Business Analyst will decompose each epic into user stories.

| Epic ID | Epic Title | Description | Business Goal | MoSCoW | Target Release |
|---|---|---|---|---|---|
| EP-001 | [e.g., Mobile Order Submission] | [Field reps submit and track orders from mobile] | [Eliminate paper forms; real-time order visibility] | Must | MVP |
| EP-002 | [e.g., CRM Integration] | [Bi-directional sync with Salesforce] | [Eliminate duplicate data entry] | Must | MVP |
| EP-003 | [e.g., Automated Invoicing] | [Invoice auto-generated on order completion] | [Remove manual finance processing] | Must | MVP |
| EP-004 | [e.g., Manager Dashboard] | [Pipeline view, approval workflows, team metrics] | [Real-time sales visibility for managers] | Should | MVP |
| EP-005 | [e.g., Multi-Currency Support] | [Support EUR, GBP, JPY in addition to USD] | [Enable APAC expansion] | Could | v2 |
| EP-006 | [e.g., Recurring Orders] | [Schedule repeat orders for predictable customers] | [Reduce rep effort for regular accounts] | Could | v2 |

---

## Feature Catalogue

For each epic, define the features it contains. Written in business terms — no implementation details.

### EP-001: Mobile Order Submission

**Business Goal:** Enable field reps to submit orders from their smartphones in under 5 minutes, with no paper forms or offline reconciliation needed.

**User Persona:** Field Sales Rep

| Feature ID | Feature | Business Value | MoSCoW | Success Criteria |
|---|---|---|---|---|
| F-001 | New order creation on mobile | Core capability — eliminates paper forms | Must | Rep can complete an order in < 5 minutes on iOS/Android |
| F-002 | Product search & selection | Reps need to find products quickly | Must | Search returns results in < 2 seconds; supports product name and SKU |
| F-003 | Customer lookup & auto-fill | Reduces entry time; prevents errors | Must | Customer details auto-populate from CRM on name selection |
| F-004 | Photo capture for supporting docs | Some orders require signed docs | Should | Rep can attach up to 5 photos per order |
| F-005 | Order history view | Reps track their own submissions | Should | Last 90 days of orders visible in the app |
| F-006 | Offline mode | Field reps may have no signal | Could | Orders drafted offline sync automatically when connection restored |

### EP-002: CRM Integration

[Repeat pattern above for each epic]

---

## MVP Scope Definition

**Explicit agreement on what is IN and OUT of the first release.**

### ✅ In Scope — MVP

Everything a field rep and finance manager need to replace the current paper process end-to-end:

- EP-001: Mobile Order Submission (all Must features: F-001 through F-003)
- EP-002: CRM Integration (Salesforce bi-directional sync)
- EP-003: Automated Invoicing (auto-generation on order completion; PDF email to customer)
- EP-004: Manager Dashboard (read-only pipeline view; discount approval workflow)
- Role-based access control (Rep / Manager / Finance / Admin roles)
- User authentication (SSO via existing corporate identity provider)
- Basic email notifications (order submitted, order approved, invoice sent)

### ❌ Out of Scope — Deferred

| Item | Reason for Deferral | Target Version |
|---|---|---|
| EP-005: Multi-currency | APAC expansion not until Q4; no immediate user base | v2 |
| EP-006: Recurring orders | Low frequency; manual workaround acceptable | v2 |
| F-006: Offline mode | Network coverage acceptable for initial market; revisit based on feedback | v2 |
| Advanced analytics | Phase 2 roadmap item; basic manager dashboard covers MVP needs | v2 |
| Mobile push notifications | Email sufficient for MVP; push adds complexity | v2 |
| Third-party API marketplace | Future integration platform; not MVP | v3 |

---

## Non-Functional Requirements (Business Level)

Business expectations that constrain technical design. Enterprise Architect will derive infrastructure NFRs from these.

| Category | Requirement | Rationale |
|---|---|---|
| **Availability** | 99.9% uptime (< 8.7 hrs downtime/year) | Field reps work evenings and weekends; global time zones |
| **Performance** | Order submission completes in < 10 seconds end-to-end | Reps use app between meetings; no time for slow systems |
| **Scalability** | Must support 500 concurrent users at launch; 5,000 within 3 years | Company plans aggressive headcount growth |
| **Data Retention** | Orders retained for 7 years (legal requirement) | Financial record-keeping obligation |
| **Security** | Role-based access; no rep can view another rep's customer data | Confidentiality of account relationships |
| **Compliance** | GDPR for EU customers; SOX for financial records | Legal obligation; see BRD data classification |
| **Accessibility** | WCAG 2.1 AA for web components | Company accessibility policy |
| **Mobile Support** | iOS 16+ and Android 13+ | Matches company device management policy |

---

## Out-of-Scope Explicit List

Items that stakeholders have raised but are explicitly NOT part of this product:

- **Inventory management** — handled by existing ERP (SAP); this product reads product data only, does not manage stock
- **Pricing engine** — prices come from SAP; this product does not calculate or override pricing
- **Customer onboarding** — new customer creation is handled by Sales Ops team in CRM; this product only reads existing customers
- **Contract management** — handled by DocuSign; out of scope entirely
- **Commissions calculation** — handled by HR system; order data may feed it but calculation is not our responsibility

---

## Roadmap Overview

| Release | Target Date | Key Capabilities | Success Gate |
|---|---|---|---|
| **MVP** | [date] | Core order flow, CRM sync, auto-invoicing, manager view | Field reps submit 80%+ of orders via app; zero paper forms |
| **v2** | [date +3 months] | Offline mode, multi-currency, recurring orders | APAC teams onboarded; satisfaction > 4.0 |
| **v3** | [date +6 months] | Advanced analytics, API marketplace, push notifications | [TBD based on v1/v2 learnings] |

---

## Assumptions

- [e.g., Users have iOS 16+ or Android 13+ smartphones provided by the company]
- [e.g., Salesforce is the system of record for customers and products; data quality is acceptable]
- [e.g., SSO is available via existing corporate identity provider (Okta)]
- [e.g., Finance team will adopt automated invoicing workflow without major retraining overhead]

---

## Open Questions

| Question | Impact on Scope | Owner | Target Resolution |
|---|---|---|---|
| [e.g., Should order approvals above $10k require manager sign-off in the app?] | [e.g., Adds approval workflow to EP-001] | [e.g., VP Sales] | [date] |
| [e.g., Does the invoice need to match a specific template per customer?] | [e.g., Adds complexity to EP-003 invoicing] | [e.g., Finance] | [date] |

---

## Stakeholder Sign-Off

| Stakeholder | Title | Date | Status | Comments |
|---|---|---|---|---|
| [Name] | Executive Sponsor | | ☐ Pending / ✓ Approved | |
| [Name] | VP [Department] | | ☐ Pending / ✓ Approved | |
| [Name] | IT / Security | | ☐ Pending / ✓ Approved | |

**Overall Status:** DRAFT / UNDER REVIEW / APPROVED

---

> **Handoff Note:** This PRD is the Product Owner's final artifact. Hand off to Business Analyst, who will decompose each epic into detailed user stories with acceptance criteria and produce the Requirements Analysis document. Do not write user stories in this document — that is the BA's responsibility.
```
