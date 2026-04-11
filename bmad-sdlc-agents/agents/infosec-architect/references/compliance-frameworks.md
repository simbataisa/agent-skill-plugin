# Compliance Frameworks Reference

> Reference file for the BMAD InfoSec Architect agent.
> Read this file when designing systems to meet SOC2, GDPR, HIPAA, PCI-DSS, and ISO 27001 requirements.

---

## SOC2 Type II (Service Organization Control)

**Scope**: Control environment, security, availability, processing integrity, confidentiality, privacy  
**Audit Timeline**: 12-month observation period + report  
**Audience**: Service providers (SaaS, cloud infrastructure)

### Trust Services Criteria (TSC)

**CC (Common Criteria)**:
- CC1–CC9: Control Environment & Risk Management
- **CC6**: Logical and Physical Access Controls
- **CC7**: System Operations
- **CC8**: Change Management
- **CC9**: Risk Mitigation

**Key Control Families**:

| Control | Requirement | Evidence |
|---------|-------------|----------|
| CC6.1 | Implement logical access controls | RBAC policy, access matrix, role definitions |
| CC6.2 | Restrict access to data | Encryption, field-level controls, encryption keys |
| CC6.3 | Restrict access to system assets | Firewall rules, security groups, network segmentation |
| CC6.4 | Manage user credentials | MFA policy, password policy, credential rotation |
| CC6.5 | Disable access promptly | Offboarding checklist, account disable procedures |
| CC7.1 | Monitor system operations | Logging, monitoring, alerting rules |
| CC7.2 | Monitor system boundaries | IDS/IPS, WAF logs, ingress/egress monitoring |
| CC7.3 | Detect unauthorized changes | File integrity monitoring, audit logs, change logs |
| CC8.1 | Authorize changes | Change approval process, documented changes |
| CC8.2 | Test changes | UAT environment, regression testing, security testing |

### Evidence Collection

**CC6.1 Logical Access**:
- RBAC policy document
- Role definitions spreadsheet
- IAM configuration screenshots
- Access review documentation (quarterly)

**CC6.2 Data Confidentiality**:
- Encryption policy (at rest, in transit)
- KMS key rotation logs
- Data classification policy
- Encryption algorithm documentation

**CC7 Operations Monitoring**:
- Monitoring dashboard screenshots
- Alert rule definitions
- Alert history (detections, false positives)
- Incident response logs

---

## GDPR (General Data Protection Regulation)

**Jurisdiction**: EU residents, any processor/controller  
**Scope**: Personal data processing (any data that identifies individual)  
**Penalties**: Up to 4% of global revenue or 20 million EUR

### Lawful Basis for Processing

Choose **ONE**:
1. **Consent** (user must explicitly opt-in)
   - Example: Marketing emails (explicit checkbox)
   - Must be revocable (user can withdraw)
2. **Contract** (processing necessary to fulfill contract)
   - Example: Customer name + address for shipping
3. **Legal Obligation** (law requires processing)
   - Example: Tax reporting requires employee info
4. **Vital Interest** (protect someone's health/life)
   - Example: Medical emergency → access health records
5. **Public Task** (government function)
   - Example: Census, tax authority
6. **Legitimate Interest** (organization's interest, balanced against data subject)
   - Example: Fraud detection, security

### Data Subject Rights

| Right | Implementation |
|-------|----------------|
| **Access** | Provide all personal data in machine-readable format (REST API) |
| **Rectification** | Allow user to correct inaccurate data |
| **Erasure** ("Right to be Forgotten") | Delete personal data (unless legal hold) |
| **Portability** | Export data in standard format (JSON, CSV) |
| **Restriction** | Limit processing (e.g., "no marketing") |
| **Objection** | Opt-out of processing |
| **Not Automated Decision** | No purely automated decisions (e.g., credit denial) |

### GDPR Compliance Checklist

- [ ] **Lawful Basis Documented**: For each data processing activity
- [ ] **Privacy Policy Clear**: In plain language (not legal jargon)
- [ ] **Consent Mechanism**: Explicit opt-in (if consent-based)
- [ ] **Data Inventory**: Catalog all personal data collected
- [ ] **Data Protection Impact Assessment (DPIA)**: For high-risk processing
- [ ] **Data Processing Agreement (DPA)**: With all processors
- [ ] **Data Retention Policy**: Delete data when no longer needed
- [ ] **Breach Notification**: Notify users within 72 hours of breach discovery
- [ ] **Privacy by Design**: Security from project start (not added later)

### Breach Notification

**Timeline**: 72 hours from discovery (not from breach occurrence)

**Notification Content**:
- What data was breached (user names, not full dataset)
- Likely consequences for data subjects
- Measures taken to mitigate harm
- Contact person for questions

---

## HIPAA (Health Insurance Portability and Accountability Act)

**Scope**: US healthcare entities + business associates  
**Protected Health Information (PHI)**: Medical records, health insurance info, mental health records  
**Penalties**: Up to 1.5 million USD per violation

### HIPAA Safeguards

**Administrative**:
- Security officer appointed
- Workforce security plan (access policies)
- Training annual
- Incident response plan

**Physical**:
- Facility access controls (ID badges, visitors logged)
- Workstation security (lock screens, clean desk)
- Device/media controls (encrypted USB drives)
- Audit controls (monitor server room)

**Technical**:
- Access controls (passwords, MFA, encryption)
- Audit logs (who accessed what PHI, when)
- Integrity controls (prevent unauthorized modification)
- Transmission security (TLS, encryption)

### Security Rule Control Mapping

| HIPAA Requirement | Implementation |
|------------------|----------------|
| Access Control | MFA + RBAC + audit logging |
| Encryption | AES-256 at rest, TLS in transit |
| Audit Controls | CloudTrail + immutable logging |
| Integrity Controls | HMAC signatures on records |
| Transmission Security | TLS 1.2+ for all ePHI |

---

## PCI-DSS v4.0 (Payment Card Industry Data Security Standard)

**Scope**: Organizations handling credit card data  
**Levels**: 1 (largest) to 4 (small merchants)  
**Validation**: Annual audit (QSA) or self-assessment (SAQ)

### 12 Key Requirements

| Req | Description | Implementation |
|-----|-------------|-----------------|
| 1 | Install & maintain firewall | Stateful firewall, DMZ, egress filtering |
| 2 | Don't rely on defaults | Change default passwords, disable unneeded services |
| 3 | Protect stored data | Encryption at rest, tokenization, avoid storing CVV/PIN |
| 4 | Encrypt in transit | TLS 1.2+ for all cardholder data |
| 5 | Antivirus/malware | EDR, endpoint detection |
| 6 | Secure development | SAST/DAST, security testing, code review |
| 7 | Least privilege | Minimal access by role |
| 8 | Identify & authenticate | MFA for admin, strong passwords |
| 9 | Restrict physical access | Badge access, visitor logs, surveillance |
| 10 | Logging & monitoring | Audit logs, real-time alerts, 1-year retention |
| 11 | Penetration testing | Annual external + internal pen test |
| 12 | Incident response | Documented plan, annual testing |

### Cardholder Data Environment (CDE) Scoping

**In Scope** (stricter controls):
- Credit card numbers (PAN)
- Expiration date
- CVC/CVV

**Out of Scope** (less strict):
- Tokenized card (e.g., "Stripe token")
- If handled by PCI-compliant processor

**Strategy**: Use third-party payment processor (Stripe, Square) to minimize in-scope systems

### Level 1 Compliance (Large Merchant)

**Requirements**:
- Annual external audit by Qualified Security Assessor (QSA)
- Quarterly network scan by Approved Scanning Vendor (ASV)
- Enterprise-grade controls (encryption, HSM, segmentation)
- Multi-layer fraud detection

---

## ISO 27001:2022 (Information Security Management System)

**Scope**: Any organization wanting certified ISMS  
**Standard**: 14 Annex A control families (93 controls)  
**Certification**: Third-party auditor validates compliance

### Annex A Control Families

| Family | Focus |
|--------|-------|
| A.5 | Organizational Controls (governance, risk) |
| A.6 | People Controls (HR, training) |
| A.7 | Physical Controls (facilities, devices) |
| A.8 | Technological Controls (crypto, access, malware) |

### Mandatory Documents

1. **Scope Document**: What systems/data are covered
2. **Information Security Policy**: High-level security commitment
3. **Risk Assessment**: Identify and score risks
4. **Risk Treatment Plan**: How risks are treated (mitigate/accept/avoid)
5. **Statement of Applicability (SoA)**: Which controls are applicable + why
6. **Treatment Plan Execution**: Evidence controls are working

### Certification Audit Process

**Stage 1** (Initial assessment):
- Review documentation
- Confirm readiness

**Stage 2** (Implementation audit):
- Verify controls are operating
- Inspect evidence
- Interview staff

**Certification Valid**: 3 years (annual surveillance audits)

---

## Control Mapping Matrix

**One control satisfies multiple frameworks**:

| Control | SOC2 | GDPR | HIPAA | PCI-DSS | ISO 27001 |
|---------|------|------|-------|---------|-----------|
| MFA on all accounts | CC6.1 | A.32 | AC-2 | 8.2 | A.8.2.3 |
| Encryption at rest (AES-256) | CC6.2 | A.32 | §164.312(a)(2)(ii) | 3 | A.8.1.1 |
| TLS in transit | CC6.2 | A.32 | §164.312(a)(2)(ii) | 4 | A.8.1.1 |
| Annual risk assessment | N/A | A.35 | §164.308(a)(1)(ii) | 11 | A.5.1 |
| Incident response plan | PI1 | A.33 | §164.308(a)(6) | 12 | A.5.2.1 |
| Annual security training | N/A | A.32 | §164.308(a)(5) | 12 | A.6.2.2 |
| Access logging/audit | CC7.1 | A.32 | §164.312(b) | 10 | A.8.1.1 |
| Vendor risk assessment | N/A | A.28 | §164.308(b)(3) | N/A | A.5.1 |

---

## Evidence Collection Guide

### Typical Audit Request: "Show MFA is enforced"

**What to provide**:
1. **Policy Document**
   - "All users must use MFA (TOTP, FIDO2, or push notification)"
   - "Exceptions documented and approved"

2. **Implementation Evidence**
   - Screenshots of IAM configuration (AWS IAM, Okta, etc.)
   - Policy rules showing MFA requirement

3. **Monitoring Evidence**
   - Dashboard showing MFA enrollment rate (e.g., 100%)
   - Logs of MFA failures and successes (sample)

4. **Testing Evidence**
   - Test user account enrollment process
   - Screenshots of MFA challenges

5. **Training Evidence**
   - Security training slides on MFA
   - Training attendance records

### Document Organization

**Compliance Folder Structure**:
```
compliance/
├─ policies/
│  ├─ information-security-policy.pdf
│  ├─ access-control-policy.pdf
│  ├─ encryption-policy.pdf
│  └─ incident-response-plan.pdf
├─ procedures/
│  ├─ mfa-enrollment.md
│  ├─ access-review-process.md
│  └─ offboarding-checklist.md
├─ evidence/
│  ├─ soc2/
│  │  ├─ cc6.1-access-matrix.xlsx
│  │  ├─ cc7.1-logs-sample.csv
│  │  └─ annual-access-review-2025.pdf
│  ├─ gdpr/
│  │  ├─ dpia-results.pdf
│  │  ├─ dpa-agreements/
│  │  └─ breach-logs.csv
│  └─ pci-dss/
│     ├─ network-diagram.pdf
│     └─ penetration-test-report-2025.pdf
├─ assessments/
│  ├─ risk-register.xlsx
│  ├─ control-gap-analysis.xlsx
│  └─ audit-findings-2024.pdf
└─ certifications/
   ├─ soc2-type2-report-2024.pdf
   ├─ iso27001-certificate-2024.pdf
   └─ pci-dss-compliance-letter-2024.pdf
```

---

## Compliance Roadmap Example (12 Months)

**Q1**: Build foundation
- [ ] Appoint security officer + compliance lead
- [ ] Document current state (systems, data flows)
- [ ] Create information security policy
- [ ] Risk assessment (high-level)
- [ ] Choose frameworks to pursue (SOC2? GDPR? PCI-DSS?)

**Q2**: Implement controls
- [ ] MFA deployment
- [ ] Encryption at rest + in transit
- [ ] Access control policy + RBAC implementation
- [ ] Logging/monitoring setup
- [ ] Data classification

**Q3**: Testing & refinement
- [ ] Penetration testing
- [ ] Access review (verify RBAC works)
- [ ] Incident response plan testing
- [ ] DPIA (GDPR)
- [ ] Security training rollout

**Q4**: Audit preparation
- [ ] Fill evidence gaps
- [ ] Audit readiness assessment
- [ ] Mock audit with internal team
- [ ] External audit (if pursuing certification)
- [ ] Remediate findings

