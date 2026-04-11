# Risk Assessment Methodology Reference

> Reference file for the BMAD InfoSec Architect agent.
> Read this file when quantifying security risks, prioritizing remediation, and managing organizational risk appetite.

---

## CVSS v3.1 Scoring (Industry Standard)

**Purpose**: Standardized vulnerability severity metric (0–10 scale)

### Base Score Metrics

**AV (Attack Vector)**: How is the vulnerability exploited?
- **N** (Network) = 8.8 (can be exploited remotely)
- **A** (Adjacent) = 6.5 (same network segment)
- **L** (Local) = 5.3 (requires local access)
- **P** (Physical) = 2.0 (requires physical presence)

**AC (Attack Complexity)**: How hard is it to exploit?
- **L** (Low) = default (standard techniques)
- **H** (High) = 0.62× (requires specialized knowledge, timing)

**PR (Privileges Required)**: Does attacker need existing access?
- **N** (None) = default (no existing access needed)
- **L** (Low) = 0.68× (low-privilege account)
- **H** (High) = 0.27× (admin account needed)

**UI (User Interaction)**: Does a user need to take action?
- **N** (None) = default (no user action needed)
- **R** (Required) = 0.85× (user must click link, open file, etc.)

**S (Scope)**: Does impact extend beyond the vulnerable component?
- **U** (Unchanged) = default (impact limited to component)
- **C** (Changed) = 1.08× (impact affects other components)

**CIA (Confidentiality, Integrity, Availability)**:
Each rated as:
- **N** (None) = 0
- **L** (Low) = 0.22
- **H** (High) = 0.56

### Example: SQL Injection in Web App

```
Vulnerability: Unvalidated user input in SQL query

Metrics:
- AV:N (exploitable over internet) = 8.8
- AC:L (standard SQL injection techniques) = 1.0
- PR:N (no login required) = 1.0
- UI:N (no user interaction) = 1.0
- S:C (compromised database is different from app) = 1.08
- C:H (data breach, confidentiality lost) = 0.56
- I:H (attacker modifies data) = 0.56
- A:H (attacker deletes data, availability lost) = 0.56

Base Score = min(10, (8.8 × 1.0 × 1.0 × 1.0 × 1.08)) × (0.56 + 0.56 + 0.56 - (0.56 × 0.56 × 0.56))
           = min(10, 9.5) × (1.68 - 0.176)
           = 9.5 × 1.504
           = 9.5 (after rounding)

Severity: CRITICAL
```

### CVSS Severity Ratings

| Base Score | Rating | CVSS Vector Example |
|-----------|--------|-------------------|
| 9.0–10.0 | CRITICAL | CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:C/C:H/I:H/A:H |
| 7.0–8.9 | HIGH | CVSS:3.1/AV:N/AC:L/PR:L/UI:N/S:C/C:H/I:N/A:N |
| 4.0–6.9 | MEDIUM | CVSS:3.1/AV:N/AC:H/PR:L/UI:R/S:U/C:L/I:L/A:N |
| 0.1–3.9 | LOW | CVSS:3.1/AV:L/AC:L/PR:H/UI:R/S:U/C:L/I:N/A:N |

---

## Likelihood × Impact Matrix

**5×5 grid** for qualitative risk scoring (when CVSS not applicable)

### Likelihood Scale

| Level | Definition | Examples |
|-------|-----------|----------|
| **Rare** (1) | <1% annual probability | Requires multiple system failures + human error |
| **Unlikely** (2) | 1–10% annual probability | Sophisticated attack needed, some defense evasion |
| **Possible** (3) | 10–50% annual probability | Moderately difficult, known techniques |
| **Likely** (4) | 50–90% annual probability | Common attack, weak defenses |
| **Almost Certain** (5) | >90% annual probability | Trivial attack, no defense |

### Impact Scale

| Level | Definition | Examples |
|-------|-----------|----------|
| **Negligible** (1) | No loss | Demo system, no real data |
| **Minor** (2) | Small impact | One user's data leaked, brief outage |
| **Moderate** (3) | Significant impact | Department's data leaked, 1–4 hour outage |
| **Major** (4) | Severe impact | Customer data breach, significant financial loss |
| **Critical** (5) | Catastrophic | Complete service loss, massive breach, IPO impact |

### Risk Matrix

```
Impact
5 │ MEDIUM  MEDIUM  HIGH    CRITICAL CRITICAL
  │ (5)     (10)    (15)    (20)     (25)
4 │ LOW     MEDIUM  MEDIUM  HIGH     CRITICAL
  │ (4)     (8)     (12)    (16)     (20)
3 │ LOW     LOW     MEDIUM  HIGH     CRITICAL
  │ (3)     (6)     (9)     (12)     (15)
2 │ LOW     LOW     MEDIUM  MEDIUM   HIGH
  │ (2)     (4)     (6)     (8)      (10)
1 │ LOW     LOW     LOW     LOW      MEDIUM
  │ (1)     (2)     (3)     (4)      (5)
  └─────────────────────────────────────────
    Rare  Unlikely Possible Likely  Almost
          (1)     (2)      (3)     (4)   Certain
                                        (5)
  Likelihood
```

**Risk = Likelihood × Impact**

Example: SQL Injection (Likely 4 × Major impact 4 = 16 HIGH)

---

## Risk Register Template

| ID | Threat | Asset | L | I | Score | Controls | Res. L | Res. I | Res. Risk | Owner | Status |
|----|--------|-------|---|---|-------|----------|--------|--------|-----------|-------|--------|
| R1 | SQL Injection | Orders DB | 4 | 4 | 16 HIGH | Input validation, prepared statements, SAST | 2 | 4 | 8 MEDIUM | DevLead | Mitigating |
| R2 | DDoS attack | API gateway | 3 | 5 | 15 CRITICAL | Rate limiting, CDN, AWS Shield | 3 | 5 | 15 (no change) | DevOps | Accepted |
| R3 | Insider threat | Financial data | 2 | 5 | 10 HIGH | Access logging, anomaly detection, least privilege | 1 | 5 | 5 LOW | SecLead | Accepted |
| R4 | Third-party breach | Customer DB | 2 | 4 | 8 MEDIUM | Vendor SLA, incident response plan, MFA | 2 | 4 | 8 (no change) | Product | Monitoring |

---

## Risk Acceptance Workflow

**Risk Acceptance**: Documented decision to not remediate (within defined timeline)

### Approval Authority

| Residual Risk | Authority | Approval Time | Justification |
|---------------|-----------|---------------|--------------|
| CRITICAL | CISO + Board | Next meeting | Rare, business case required |
| HIGH | CISO + VP Eng | Next week | Documented threat assessment |
| MEDIUM | Security Lead | Immediate | Risk owner identified |
| LOW | Team Lead | N/A | Advisory only |

### Risk Acceptance Form

```
Risk ID: R2-DDoS-2025
Threat: DDoS on customer-facing API
Severity: CRITICAL (15/25)

Why Accept?
- DDoS protection: CloudFlare + AWS Shield in place
- Redundancy: Multi-region deployment
- Recovery: RTO 15 minutes acceptable per SLA
- Cost: Mitigation ($500k/year) exceeds risk impact ($50k max)

Residual Risk: MEDIUM (mitigated by controls above)
Review Date: 2026-04-11 (annual reassessment)

Approval:
- Risk Owner: Alice Chen (VP Engineering)
- Security Lead: Bob Martinez
- CISO: Carol Singh
- Date: 2025-04-11
- Expiration: 2026-04-11 (auto-escalate if not remediated)
```

---

## Risk Treatment Options

| Option | Definition | Timeline | Cost |
|--------|-----------|----------|------|
| **Mitigate** | Reduce likelihood or impact | 3–6 months | Medium |
| **Avoid** | Eliminate risk (change design) | 1–2 months | High |
| **Accept** | Live with risk (documented) | Immediate | Low |
| **Transfer** | Shift to third party (insurance, SaaS) | 1 month | Medium |

### Decision Criteria

**MITIGATE**:
- Risk is > residual risk cost
- Feasible solution exists
- Timeline allows remediation

**ACCEPT**:
- Residual risk ≤ business impact
- Compensating controls in place
- Documented justification

**AVOID**:
- Risk is critical
- No cost-effective mitigation
- Example: Don't support legacy TLS (remove support entirely)

**TRANSFER**:
- Vendor can manage risk better
- Insurance covers the risk
- Example: Use Stripe for payments (transfer PCI-DSS risk)

---

## Risk Metrics & Reporting

### Risk Appetite Statement

```
RISK APPETITE: Moderate

Finance:
- Acceptable max financial loss: $10 million/year
- Maximum uninsured loss: $1 million
- Insurance covers >$1M breaches

Compliance:
- Acceptable max violations: 0 (critical), 2 (medium)
- SLA uptime: 99.9% (max 43 minutes/month downtime)
- Maximum number of open HIGH/CRITICAL findings: 5
  (must remediate within 30 days)

Reputational:
- Acceptable: Isolated incidents disclosed transparently
- Unacceptable: Ransomware attack, major customer data breach

Operational:
- Maximum percentage of critical systems down: 10%
  (fail-over/redundancy accepted)
```

### Executive Dashboard

```
Risk Summary (as of 2026-04-11):

CRITICAL Risks: 2 (vs. target: 0)
├─ DDoS vulnerability (accepted, expiring 2026-06-11)
└─ Unpatched legacy system (mitigation in progress)

HIGH Risks: 8 (vs. target: <5)
├─ 3 open CRITICAL CVEs (patch pending)
├─ 5 MEDIUM findings (SLA 30 days)

Risk Trend:
2026-04-11: 2 CRITICAL, 8 HIGH (total: 10)
2026-03-11: 2 CRITICAL, 12 HIGH (total: 14) ← Improving
2026-02-11: 3 CRITICAL, 15 HIGH (total: 18)

Velocity: -4 high-risk findings/month (good)
Projected: 0 CRITICAL, 2 HIGH by 2026-07-11 (on track)
```

---

## Third-Party Risk Assessment

**Vendor Security Questionnaire** (for SaaS, cloud providers):

### Tier 1 (High Risk - Customer Data Access)

Required:
- [ ] SOC2 Type II report (current)
- [ ] Penetration test report (annual)
- [ ] Business continuity plan + RTO/RPO
- [ ] Incident response plan
- [ ] Data encryption (at rest + in transit)
- [ ] MFA on admin accounts
- [ ] Disaster recovery tested

### Tier 2 (Medium Risk - Limited Data)

Required:
- [ ] SOC2 Type I or self-assessment
- [ ] Annual vulnerability scan
- [ ] Data retention policy
- [ ] Basic encryption

### Tier 3 (Low Risk - No Sensitive Data)

Minimal:
- [ ] Company website + documentation
- [ ] Liability insurance

### SIG Lite (Standardized Assessment)

SANS Institute maintained questionnaire:
- 77 questions across 8 domains
- 1–5 risk rating per vendor
- Shared results (vendors benefit from completing)

### Risk Review Triggers

**Re-assess vendor when**:
- SOC2/ISO certification expires
- Major incident disclosed
- Ownership/leadership change
- New feature added (increased data access)
- Customer complaint about vendor security
- Annual review scheduled

---

## Risk Register Lifecycle

```
1. Identify Risk
   ↓
2. Assess (CVSS or likelihood×impact)
   ↓
3. Approve Risk Score
   ├─ CRITICAL → Fast track to mitigation
   ├─ HIGH → Mitigation planned (30 days)
   ├─ MEDIUM → Backlog
   └─ LOW → Advisory
   ↓
4. Assign Owner + Schedule
   ↓
5. Execute Mitigation / Acceptance
   ├─ Mitigate: Apply controls, test
   ├─ Accept: Document justification, get approval
   ├─ Avoid: Architectural change, disable feature
   └─ Transfer: Purchase insurance or use SaaS
   ↓
6. Verify + Close
   └─ Re-test, confirm residual risk acceptable
   ↓
7. Monitor (for accepted risks)
   └─ Annual review, trigger reassessment if threshold crossed
```

