# Template: Business Requirements Document (BRD)

A structured template for the Product Owner to document high-level business requirements before handing off to the Business Analyst for deep-dive analysis.

---

```markdown
# Business Requirements Document — [Project Name]

## Document Information

| Field | Value |
|---|---|
| **Project Name** | |
| **Version** | v1.0 |
| **Date** | [YYYY-MM-DD] |
| **Prepared By (Product Owner)** | [Name] |
| **Sponsor / Executive Champion** | [Name, Title] |
| **Status** | Draft / Under Review / Approved |

---

## Executive Summary

[1–2 paragraphs: What is this project? What business problem does it solve? What is the expected business outcome? Written for a C-suite audience — no technical jargon.]

---

## Business Objectives

What the business needs to achieve. Link each objective to a measurable outcome.

| # | Objective | KPI / Metric | Target | Timeframe |
|---|-----------|---|---|---|
| 1 | [e.g., Reduce customer churn] | [e.g., Monthly churn rate] | [e.g., < 5%] | [e.g., Q3 2025] |
| 2 | | | | |
| 3 | | | | |

---

## Problem Statement

**What business problem are we solving?**

[2–4 sentences describing the problem clearly. Quantify where possible: revenue lost, time wasted, compliance risk, customer pain.]

**Quantified Impact of the Problem:**
- [e.g., 15% of support tickets relate to X, costing $200k/year in support time]
- [e.g., Manual process takes 4 hours per transaction; target is < 15 minutes]
- [e.g., Regulatory deadline of [date] — non-compliance fines of $X]

---

## Stakeholder Register

Key stakeholders whose needs this system must address. Business Analyst will expand this during analysis.

| Stakeholder | Title / Role | Power | Interest | Primary Need | Key Concern |
|---|---|---|---|---|---|
| [Name] | [e.g., VP Sales] | High | High | [e.g., Real-time pipeline visibility] | [e.g., Data accuracy] |
| [Name] | [e.g., Field Rep] | Low | High | [e.g., Mobile access] | [e.g., Extra data entry burden] |
| [Name] | [e.g., IT Security] | High | Medium | [e.g., SOC 2 compliance] | [e.g., Data exposure] |
| [Name] | [e.g., CFO] | High | Low | [e.g., ROI visibility] | [e.g., Budget overrun] |

**Primary User Persona(s):**
[Who will use this system day-to-day? 1–2 sentences per persona. BA will define full personas during analysis.]

---

## High-Level Business Requirements

What the business needs the solution to do. Written in business language — NOT technical specifications.

### Functional Needs

| # | Requirement | Business Driver | Priority (MoSCoW) |
|---|---|---|---|
| BRQ-001 | [e.g., System must allow field reps to submit orders from mobile devices] | [e.g., 60% of orders are placed in the field; reps currently use paper] | Must |
| BRQ-002 | [e.g., System must integrate with Salesforce CRM] | [e.g., Sales team lives in Salesforce; duplicate entry is a current pain point] | Must |
| BRQ-003 | [e.g., System must generate invoice automatically on order completion] | [e.g., Finance team currently spends 2 hours/day on manual invoicing] | Must |
| BRQ-004 | [e.g., System should support multi-currency transactions] | [e.g., APAC expansion planned for Q4] | Should |
| BRQ-005 | [e.g., System could support recurring order scheduling] | [e.g., 30% of customers have predictable order patterns] | Could |

### Non-Functional Needs (Business Level)

[High-level expectations — EA and SA will derive technical NFRs from these.]

| Category | Business Expectation |
|---|---|
| **Availability** | [e.g., System must be available 24/7; field reps work across time zones] |
| **Performance** | [e.g., Orders must process in real time; no delay acceptable for field reps] |
| **Scalability** | [e.g., Must support 500 concurrent field reps at peak; 10x growth expected in 3 years] |
| **Security** | [e.g., Customer order data is confidential; access control by role required] |
| **Compliance** | [e.g., Must comply with GDPR for EU customers; SOX controls for financial data] |

---

## Data Classification

What data will this system handle? Used by EA to design compliant infrastructure.

| Data Category | Examples | Sensitivity Level | Regulatory Flag |
|---|---|---|---|
| [e.g., Customer PII] | [e.g., Name, email, address] | Confidential | GDPR |
| [e.g., Financial records] | [e.g., Order amounts, invoices] | Restricted | SOX |
| [e.g., Product catalog] | [e.g., SKUs, pricing] | Internal | None |
| [e.g., Employee data] | [e.g., Rep name, territory] | Confidential | GDPR |

**Sensitivity Levels:** Public / Internal / Confidential / Restricted

---

## Regulatory & Compliance Requirements

| Regulation | Scope | Requirement Summary | Risk of Non-Compliance |
|---|---|---|---|
| [e.g., GDPR] | [e.g., EU customer data] | [e.g., Right to deletion, data processing consent] | [e.g., Fines up to 4% of global revenue] |
| [e.g., SOX] | [e.g., Financial data] | [e.g., Audit trail, access controls] | [e.g., Executive liability] |
| [e.g., PCI-DSS] | [e.g., Payment processing] | [e.g., Card data never stored] | [e.g., Loss of payment processing rights] |

If no regulatory requirements apply, state explicitly: *"No regulatory requirements identified for this project."*

---

## Known Integration Requirements

Systems this solution must connect with. EA will design the integration architecture.

| System | Type | Direction | Business Owner | Priority |
|---|---|---|---|---|
| [e.g., Salesforce CRM] | [e.g., SaaS API] | [e.g., Bi-directional] | [e.g., Sales Ops] | Must |
| [e.g., SAP ERP] | [e.g., On-premise] | [e.g., Order → SAP] | [e.g., Finance] | Must |
| [e.g., Stripe] | [e.g., Payment gateway] | [e.g., Outbound] | [e.g., Finance] | Must |
| [e.g., SendGrid] | [e.g., Email service] | [e.g., Outbound notifications] | [e.g., IT] | Should |

---

## Business Constraints

Hard limits the solution must work within.

| Constraint | Description | Impact |
|---|---|---|
| **Budget** | [e.g., $500k total budget for build + 1 year ops] | [e.g., No custom hardware; cloud-only] |
| **Timeline** | [e.g., Must go live by [date] — regulatory deadline] | [e.g., Fixed; cannot be extended] |
| **Technology** | [e.g., Must integrate with existing Salesforce org; cannot replace] | [e.g., SA must design within Salesforce constraints] |
| **Team** | [e.g., Internal team of 4 engineers; no external contractors] | [e.g., Scope must be realistic for team size] |
| **Geography** | [e.g., Data must reside in EU for GDPR compliance] | [e.g., EA must select EU cloud region] |

---

## MVP Scope Indication

High-level sense of what must be in the first release vs what is deferred. Business Analyst will refine this into a detailed requirements analysis; Solution Architect will translate to epics/stories.

### Must Be in MVP (v1)

- [e.g., Mobile order submission for field reps]
- [e.g., Salesforce CRM integration]
- [e.g., Automated invoice generation]
- [e.g., Role-based access control]

### Deferred (v2 or later)

- [e.g., Multi-currency support — APAC expansion Q4]
- [e.g., Recurring order scheduling — nice to have]
- [e.g., Advanced analytics dashboard — Phase 2]

---

## Business Success Criteria

How will we know this project succeeded? Measurable, with a timeline.

| Metric | Baseline | Target | Measurement Method | Timeframe |
|---|---|---|---|---|
| [e.g., Order processing time] | [e.g., 4 hours] | [e.g., < 15 minutes] | [e.g., System log timestamps] | [e.g., 30 days post-launch] |
| [e.g., Support tickets re: ordering] | [e.g., 80/month] | [e.g., < 20/month] | [e.g., Support ticket system] | [e.g., 60 days post-launch] |
| [e.g., Field rep satisfaction] | [e.g., 3.1/5 CSAT] | [e.g., > 4.0/5] | [e.g., Quarterly survey] | [e.g., 90 days post-launch] |

---

## Assumptions

What we believe to be true without formal verification. Business Analyst will validate during analysis.

- [e.g., Salesforce API is available and IT will provide sandbox access]
- [e.g., Field reps have smartphones capable of running modern mobile apps]
- [e.g., Finance team will adopt the automated invoice workflow]
- [e.g., Budget is approved and available at project kickoff]

---

## Open Questions / Decisions Needed

| Question | Impact | Owner | Target Date |
|---|---|---|---|
| [e.g., Which payment gateway? Stripe vs. Adyen?] | [e.g., Affects SA's integration design] | [e.g., CFO + CTO] | [e.g., 2025-04-15] |
| [e.g., Do field reps need offline mode?] | [e.g., Significant additional complexity] | [e.g., VP Sales] | [e.g., 2025-04-20] |

---

## Stakeholder Sign-Off

| Stakeholder | Title | Date | Status | Comments |
|---|---|---|---|---|
| [Name] | Executive Sponsor | | ☐ Pending / ✓ Approved | |
| [Name] | VP [Department] | | ☐ Pending / ✓ Approved | |
| [Name] | IT / Security | | ☐ Pending / ✓ Approved | |

**Overall Status:** DRAFT / UNDER REVIEW / APPROVED
```
