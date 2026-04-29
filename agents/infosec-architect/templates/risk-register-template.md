# Risk Register Template

> Template file for the BMAD InfoSec Architect agent.
> Use this template to document and track security risks across your organization.

---

## Document Header

**Organization**: MyCompany  
**Review Period**: Q2 2026 (Apr–Jun)  
**Owner**: Bob Martinez (CISO)  
**Last Updated**: 2026-04-11  
**Next Review**: 2026-07-11 (Quarterly)  

---

## Risk Appetite Statement

**Strategic**: Accept moderate risks to achieve innovation  
**Financial**: Acceptable max loss per incident: $1 million  
**Compliance**: Zero critical violations (mandatory controls)  
**Operational**: 99.9% uptime acceptable (43 min/month downtime)  
**Reputational**: Transparent disclosure of breaches

---

## Risk Register

| ID | Threat | Asset | Likelihood | Impact | Inherent Score | Existing Controls | Residual L | Residual I | Residual Score | Risk Owner | Treatment | Remediation Date | Status |
|----|--------|-------|-----------|--------|--------|------------------|-----------|-----------|--------|--------|-----------|-----------------|--------|
| R001 | SQL Injection in Orders API | Customer DB | 4 (Likely) | 5 (Crit) | 20 CRITICAL | Input validation, parameterized queries, SAST | 2 | 5 | 10 HIGH | API Lead | Mitigate | 2026-05-11 | Open |
| R002 | DDoS on Payment Endpoint | Service Availability | 3 (Poss) | 5 (Crit) | 15 CRITICAL | Rate limiting, CDN, AWS Shield | 3 | 5 | 15 (Accepted) | DevOps Lead | Accept | Ongoing | Accepted |
| R003 | Insider Data Exfiltration | Customer Data | 2 (Unlik) | 5 (Crit) | 10 HIGH | DLP, access logging, anomaly detection | 1 | 5 | 5 LOW | Security Lead | Mitigate | 2026-06-30 | In Progress |
| R004 | Unpatched Third-Party Lib | All Services | 3 (Poss) | 4 (Major) | 12 HIGH | Dependency scanning, auto-updates, SLA | 2 | 4 | 8 MEDIUM | DevSecOps | Mitigate | Ongoing | Managed |
| R005 | Cloud Account Compromise | AWS Infrastructure | 2 (Unlik) | 5 (Crit) | 10 HIGH | MFA, access auditing, CloudTrail | 1 | 4 | 4 LOW | Cloud Arch | Mitigate | Completed | Mitigated ✓ |
| R006 | Certificate Expiry (PKI) | TLS/mTLS | 2 (Unlik) | 4 (Major) | 8 MEDIUM | cert-manager, monitoring alerts | 1 | 4 | 4 LOW | DevOps | Mitigate | Completed | Mitigated ✓ |
| R007 | Authentication System Down | All Services | 2 (Unlik) | 5 (Crit) | 10 HIGH | HA setup, backup IdP, incident plan | 1 | 5 | 5 LOW | Auth Lead | Mitigate | Completed | Mitigated ✓ |
| R008 | Ransomware (Backup) | Database | 1 (Rare) | 5 (Crit) | 5 LOW | Immutable backups, WORM, air-gapped | 1 | 5 | 5 LOW | DevOps | Mitigate | Completed | Mitigated ✓ |
| R009 | Supply Chain Attack | Dependencies | 2 (Unlik) | 4 (Major) | 8 MEDIUM | SBOM, SLA requirements, audits | 2 | 4 | 8 (Accepted) | Security | Accept | Ongoing | Accepted |
| R010 | Credential Leak (GitHub) | Source Code | 3 (Poss) | 3 (Mod) | 9 MEDIUM | Gitleaks, pre-commit hooks, remediation | 1 | 3 | 3 LOW | DevSecOps | Mitigate | 2026-04-30 | In Progress |
| R011 | Kubernetes Misconfiguration | Infrastructure | 2 (Unlik) | 4 (Major) | 8 MEDIUM | OPA Gatekeeper, network policies, scanning | 1 | 4 | 4 LOW | Platform | Mitigate | Completed | Mitigated ✓ |
| R012 | Zero-Day Vulnerability | Any Component | 1 (Rare) | 5 (Crit) | 5 LOW | Incident response plan, vendor SLA, isolation | 1 | 5 | 5 (Accepted) | CISO | Accept | Ongoing | Accepted |
| R013 | Phishing Attack (Credentials) | Users | 4 (Likely) | 3 (Mod) | 12 HIGH | MFA, security training, email filtering | 2 | 3 | 6 MEDIUM | HR + Security | Mitigate | Ongoing | Managed |
| R014 | Compliance Audit Failure | Certification | 1 (Rare) | 4 (Major) | 4 LOW | Documentation, controls, evidence | 1 | 4 | 4 LOW | Security | Mitigate | Completed | Mitigated ✓ |
| R015 | Data Retention Violation | Customer Data | 2 (Unlik) | 4 (Major) | 8 MEDIUM | Data retention policy, automation, audits | 1 | 4 | 4 LOW | Legal + Data | Mitigate | Completed | Mitigated ✓ |

---

## Treatment Plan

### High-Risk Items (Action Required)

**R001 - SQL Injection**
- **Current Status**: Medium priority, SQL parameterization deployed
- **Owner**: API Team Lead (Alice Chen)
- **Deadline**: 2026-05-11
- **Actions**:
  1. [ ] Complete SAST remediation (3 remaining findings)
  2. [ ] Run penetration test on API
  3. [ ] Deploy to production
  4. [ ] Verify with ZAP DAST scan

**R003 - Insider Exfiltration**
- **Current Status**: DLP pilot in staging
- **Owner**: Security Lead (Bob Martinez)
- **Deadline**: 2026-06-30
- **Actions**:
  1. [ ] Complete DLP policy configuration
  2. [ ] Deploy to production
  3. [ ] Train team on incident response
  4. [ ] Validate with test exfiltration

**R013 - Phishing Attacks**
- **Current Status**: Ongoing, MFA at 98% enrollment
- **Owner**: CISO + HR
- **Actions**:
  1. [ ] Quarterly phishing simulations (next: May)
  2. [ ] Security awareness training (annual refresh due July)
  3. [ ] Email filtering review (June)
  4. [ ] Monitor and track metrics

---

## Risk Scoring Definitions

**Likelihood Scale**:
- 1 (Rare): <1% annual probability
- 2 (Unlikely): 1–10%
- 3 (Possible): 10–50%
- 4 (Likely): 50–90%
- 5 (Almost Certain): >90%

**Impact Scale**:
- 1 (Negligible): No financial loss
- 2 (Minor): <$100K loss
- 3 (Moderate): $100K–$1M loss
- 4 (Major): $1M–$10M loss
- 5 (Critical): >$10M loss, regulatory, reputational

**Risk Score**: Likelihood × Impact
- **20–25**: CRITICAL (immediate action)
- **12–15**: HIGH (within 30 days)
- **6–11**: MEDIUM (within 90 days)
- **1–5**: LOW (backlog/monitor)

---

## Approvals

- **Prepared By**: Alice Chen (Security Architect)  
- **Reviewed By**: Bob Martinez (CISO)  
- **Approved By**: Carol Singh (VP Engineering)  
- **Date**: 2026-04-11  
- **Next Review**: 2026-07-11  

