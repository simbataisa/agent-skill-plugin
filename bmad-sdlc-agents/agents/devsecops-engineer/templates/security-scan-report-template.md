# Security Scan Report Template

> Template file for the BMAD DevSecOps Engineer agent.
> Use this template to generate consolidated security scan reports for stakeholder review and sign-off.

---

## Report Metadata

**Report ID**: SR-2026-04-001  
**Project**: MyApp Payment Service  
**Version Scanned**: v2.1.0  
**Scan Date**: 2026-04-11  
**Reporting Engineer**: Alice Chen (DevSecOps)  
**Report Owner**: Bob Martinez (Security Lead)  

**Scanner Versions**:
- Semgrep: 1.45.0
- Trivy: 0.50.0
- OWASP Dependency-Check: 8.4.0
- Checkov: 2.2.105
- OWASP ZAP: 2.14.0

**Scope**:
- Source code: All files in `main` branch
- Container: `myapp:v2.1.0`
- Infrastructure: Terraform modules in `terraform/prod`
- Dependencies: npm, Python, Go modules as of 2026-04-11

---

## Executive Summary

| Status | Finding |
|--------|---------|
| **Gate Result** | ⚠️ CONDITIONAL PASS |
| **Critical Issues** | 0 |
| **High Issues** | 2 (both accepted) |
| **Medium Issues** | 8 (create tickets) |
| **Low Issues** | 24 (track) |
| **Recommendation** | ✅ **APPROVED FOR RELEASE** |

**Key Metrics**:
- Code Coverage: 82% (target: >80%)
- OWASP Top 10 Compliance: 9/10 (A07 compensated by MFA)
- Zero known critical CVEs in dependencies
- 98% of findings resolved or accepted since last release

**Sign-Off Status**: ⏳ Pending security lead approval (due 2026-04-13)

---

## SAST Findings (Semgrep + SonarQube)

### Critical Findings: 0

**None detected.**

### High Findings: 2

| ID | CWE | Severity | File:Line | Description | Status | Remediation |
|----|----|----------|-----------|-------------|--------|-------------|
| SAST-001 | CWE-327 | HIGH | `src/crypto.py:45` | Weak cryptographic algorithm (MD5) used for password hashing | **FIXED** | Replaced with bcrypt in commit `a3f4b2c` |
| SAST-002 | CWE-295 | HIGH | `src/api/client.py:123` | TLS certificate validation disabled (insecure) | **FIXED** | Re-enabled SSL verification in commit `f1e8d9c` |

### Medium Findings: 8

| ID | CWE | Severity | File:Line | Description | Status | Risk Accept | Notes |
|----|----|----|-----------|-------------|--------|-------------|-------|
| SAST-003 | CWE-79 | MEDIUM | `src/views/admin.html:67` | Potential XSS via template injection | OPEN | JIRA-4521 | Will patch in v2.2 (low-risk page) |
| SAST-004 | CWE-434 | MEDIUM | `src/upload.py:89` | File upload without MIME type validation | OPEN | JIRA-4522 | Added to backlog |
| SAST-005 | CWE-400 | MEDIUM | `src/parser.py:156` | Uncontrolled resource consumption (XML bomb risk) | OPEN | N/A | Blocked at API gateway layer |
| SAST-006 | CWE-548 | MEDIUM | `config.yaml` | World-readable configuration file permissions | FIXED | N/A | File permissions updated |
| SAST-007 | CWE-208 | MEDIUM | `src/auth.py:34` | Observable timing differences in password comparison | OPEN | JIRA-4523 | Non-critical (constant-time pending) |
| SAST-008 | CWE-798 | MEDIUM | `src/db.py:12` | Hardcoded database host in test only | FIXED | N/A | Moved to environment variable |
| SAST-009 | CWE-611 | MEDIUM | `src/xml_parse.py:45` | XXE attack vector not mitigated | OPEN | JIRA-4524 | Feature rarely used, WAF blocks known patterns |
| SAST-010 | CWE-295 | MEDIUM | `src/webhook.py:67` | Missing SSL pinning for external API calls | OPEN | JIRA-4525 | Roadmap for v2.3 |

---

## DAST Findings (OWASP ZAP)

**Scan Date**: 2026-04-11 (Staging environment)  
**Baseline Comparison**: vs. v2.0.0 scan

### Critical Findings: 0

**None detected.**

### High Findings: 1

| ID | OWASP Top 10 | Severity | Endpoint | Description | Status | Mitigation |
|----|-------------|----------|----------|-------------|--------|-----------|
| DAST-001 | A05:CORS | HIGH | `POST /api/user/profile` | Cross-Origin Resource Sharing (CORS) policy too permissive | FIXED | Restricted to `https://trusted-domain.com` |

### Medium Findings: 5

| ID | OWASP | Endpoint | Description | Status | Owner |
|----|-------|----------|-------------|--------|-------|
| DAST-002 | A01 | `GET /api/users` | Missing rate limiting on user search endpoint | OPEN | API Team (JIRA-4526) |
| DAST-003 | A05 | `POST /api/webhook` | Webhook URL validation insufficient | OPEN | Integrations Team (JIRA-4527) |
| DAST-004 | A04 | `/admin` | Missing HTTP security headers (X-Frame-Options, CSP) | OPEN | Frontend Team (JIRA-4528) |
| DAST-005 | A03 | `POST /api/search` | Partial parameter validation (SQLi-like pattern detected) | FIXED | Query parameterization added |
| DAST-006 | A07 | `GET /health` | Endpoint exposes internal system version details | OPEN | DevOps Team (JIRA-4529) |

---

## Container Scan Findings (Trivy)

**Image**: `myapp:v2.1.0`  
**Base Image**: `gcr.io/distroless/python3-debian11@sha256:abc123...`

### Critical Findings: 0

**None detected.**

### High Findings: 0

**None detected.**

### Medium Findings: 2

| CVE ID | Severity | Package | Current Version | Fixed Version | Status |
|--------|----------|---------|-----------------|---------------|--------|
| CVE-2024-5632 | MEDIUM | openssl | 1.1.1w | 1.1.1x | FIXED (base image updated) |
| CVE-2024-1234 | MEDIUM | zlib | 1.2.11 | 1.2.13 | FIXED (base image updated) |

### Low Findings: 3

| CVE ID | Severity | Package | Current Version | Fixed Version | Status |
|--------|----------|---------|-----------------|---------------|--------|
| CVE-2024-9999 | LOW | libxml2 | 2.9.10 | 2.9.13 | TRACKING |
| CVE-2024-8888 | LOW | curl | 7.68.0 | 7.68.1 | TRACKING |
| CVE-2024-7777 | LOW | gcc-lib | 9.3.0 | 9.3.0-patch1 | TRACKING |

---

## Infrastructure as Code Scan (Checkov)

**Scope**: Terraform modules in `terraform/prod/`

### Critical Findings: 0

**None detected.**

### High Findings: 2

| Check ID | Severity | Resource | Issue | Status | Remediation |
|----------|----------|----------|-------|--------|------------|
| CKV_AWS_1 | HIGH | `aws_s3_bucket.backup` | S3 bucket missing ACL restriction | FIXED | Updated to `private` ACL |
| CKV_AWS_20 | HIGH | `aws_rds_cluster.postgres` | RDS backup encryption not enabled | FIXED | Added `backup_retention_enabled = true` + KMS key |

### Medium Findings: 5

| Check ID | Resource | Issue | Status | Owner |
|----------|----------|-------|--------|-------|
| CKV_AWS_18 | `aws_security_group.app` | Missing egress restrictions | OPEN | NetSecOps (plan next quarter) |
| CKV_AZURE_33 | `azurerm_app_service.web` | HTTPS not enforced | OPEN | Cloud Team (JIRA-4530) |
| CKV_K8S_1 | `k8s/deployment.yaml` | Container running as root | FIXED | Added `securityContext.runAsNonRoot: true` |
| CKV_TF_1 | `terraform/main.tf` | Resource tagging incomplete | OPEN | JIRA-4531 (low priority) |
| CKV_AWS_62 | `aws_elbv2.lb` | ALB access logs disabled | FIXED | Enabled to S3 bucket with 30-day retention |

---

## Dependency Scan Findings (OWASP Dependency-Check + Snyk)

**Scanned**: `package.json`, `requirements.txt`, `go.mod`

### Critical CVEs: 0

**None detected.**

### High CVEs: 2

| CVE ID | Package | Current Version | Fixed Version | Severity | Status | Mitigation |
|--------|---------|-----------------|---------------|----------|--------|-----------|
| CVE-2024-12345 | requests | 2.28.1 | 2.31.0 | HIGH | FIXED | Upgraded in commit `e4c5d6f` |
| CVE-2024-67890 | django | 4.2.0 | 4.2.8 | HIGH | FIXED | Patched in minor release |

### Medium CVEs: 8

| CVE ID | Package | Current | Fixed | Days Old | Status | Owner |
|--------|---------|---------|-------|----------|--------|-------|
| CVE-2024-11111 | numpy | 1.24.0 | 1.26.0 | 45 | OPEN | Data Team (JIRA-4532) |
| CVE-2024-22222 | pillow | 9.0.0 | 10.0.0 | 30 | OPEN | Backend Team (JIRA-4533) |
| CVE-2024-33333 | lodash | 4.17.21 | 4.17.21.1 | 20 | FIXED | Updated |
| CVE-2024-44444 | moment | 2.29.1 | 2.29.4 | 10 | DEFERRED | Only used internally, low-risk |
| CVE-2024-55555 | underscore | 1.13.0 | 1.13.6 | 60 | OPEN | Scheduled for v2.2 (JIRA-4534) |
| CVE-2024-66666 | handlebars | 4.7.6 | 4.7.8 | 35 | FIXED | Bumped version |
| CVE-2024-77777 | jsonwebtoken | 8.5.1 | 9.1.0 | 25 | OPEN | Auth Team (JIRA-4535) |
| CVE-2024-88888 | pg | 8.7.1 | 8.11.0 | 50 | DEFERRED | Risk-accepted by DBA |

### License Compliance: ✅ PASS

- **Approved Licenses**: 127 packages (MIT, Apache-2.0, BSD, ISC)
- **Restricted (requires approval)**: 0 GPL-licensed packages
- **Prohibited**: 0 SSPL or unknown-license packages
- **Status**: All dependencies in approved list

---

## Secrets Detection (Gitleaks)

**Scan Coverage**: All commits in `main` branch (last 30 days)

**Result**: ✅ **CLEAN - No secrets detected**

**Detections by Pattern** (cumulative):
- API Keys: 0
- Private Keys: 0
- Passwords: 0
- Database Credentials: 0
- Tokens: 0

**Pre-commit Hooks**: Enabled on 98% of developer machines (verified by config audit)

---

## Risk Acceptance Log

| Finding ID | Severity | Component | Owner | Justification | Remediation Date | Expires |
|-----------|----------|-----------|-------|---------------|------------------|---------|
| SAST-005 | MEDIUM | XML Parser | Platform Lead | API Gateway rate limiting + input size limits mitigate risk | 2026-06-30 | 2026-12-31 |
| DAST-002 | MEDIUM | User Search API | API Lead | Cached query results reduce impact; rate limit roadmap | 2026-05-31 | 2026-12-31 |
| CVE-2024-44444 (moment) | MEDIUM | Logging | DevOps | Only used for internal log timestamps; no network exposure | None | 2026-12-31 |
| CVE-2024-88888 (pg) | MEDIUM | Database | DBA | Connection pooling + least-privilege DB user mitigate; evaluating upgrade | 2026-08-31 | 2026-12-31 |

**Acceptance Authority**:
- Alice Chen (DevSecOps Engineer): 4 findings
- Bob Martinez (Security Lead): Reviewed + approved
- Carol Singh (CISO): Noted (none Critical)

---

## Summary by Severity

| Severity | SAST | DAST | Container | IaC | Dependencies | **Total** |
|----------|------|------|-----------|-----|--------------|---------|
| CRITICAL | 0 | 0 | 0 | 0 | 0 | **0** ✅ |
| HIGH | 2→0 | 1→0 | 0 | 2→0 | 2→0 | **2→0** ✅ |
| MEDIUM | 8 | 5 | 2 | 5 | 8 | **28** (tracked) |
| LOW | — | — | 3 | — | — | **3** (advisory) |
| **TOTAL** | **10** | **6** | **5** | **7** | **10** | **38** |

---

## Comparison to Previous Release (v2.0.0)

| Category | v2.0.0 | v2.1.0 | Trend |
|----------|--------|--------|-------|
| Total Findings | 42 | 38 | ✅ Improved |
| Critical | 0 | 0 | — |
| High | 4 | 0 | ✅ Resolved |
| Medium | 30 | 28 | ✅ Slight improvement |
| False Positives | 8 | 6 | ✅ Better tuning |
| Risk-Accepted | 5 | 4 | ✅ Reduced backlog |
| Open JIRA Tickets | 18 | 12 | ✅ Resolved 6 |

---

## Recommendations

### Immediate Actions (Before Release)
- [ ] Bob Martinez to sign-off on risk acceptances by 2026-04-13
- [ ] Verify all HIGH findings are indeed resolved in v2.1.0 binary
- [ ] Run DAST scan 1x more on staging to confirm fixes

### Short-term (v2.1.1 patch, 2 weeks)
- [ ] Merge PRs for SAST-003, SAST-007, SAST-009 (XSS, XXE, timing)
- [ ] Add rate limiting to user search endpoint (DAST-002)
- [ ] Implement HTTP security headers (DAST-004)

### Medium-term (v2.2, 4 weeks)
- [ ] Upgrade numpy, pillow, underscore, jsonwebtoken
- [ ] Implement SSL pinning for external API calls
- [ ] Complete egress security group restrictions

### Long-term (v2.3+, 8+ weeks)
- [ ] Evaluate TLS 1.3 enforcement (currently 1.2+ acceptable)
- [ ] Implement API endpoint versioning for backward compatibility
- [ ] Annual external penetration test

---

## Audit Trail

| Date | Action | Engineer | Notes |
|------|--------|----------|-------|
| 2026-04-11 09:00 | Scan initiated | Alice Chen | Full pipeline triggered |
| 2026-04-11 10:30 | Semgrep completed | (automated) | 10 findings (2 new fixes) |
| 2026-04-11 11:15 | Container scan completed | (automated) | 5 findings (all medium/low) |
| 2026-04-11 12:00 | Dependency scan completed | (automated) | 10 findings (2 critical resolved) |
| 2026-04-11 13:00 | DAST staging scan completed | (automated) | 6 findings (1 critical fixed) |
| 2026-04-11 14:30 | Report compiled | Alice Chen | Initial draft |
| 2026-04-11 15:00 | Risk acceptance review | Bob Martinez | 4 findings approved for acceptance |
| 2026-04-11 16:00 | Report finalized | Alice Chen | Ready for sign-off |

---

## Sign-Off Block

**Security Team Lead**: _____________________________ Date: ___________  
Name (print): Bob Martinez  
Signature authorizes release of v2.1.0 to production.

**CISO (if CRITICAL findings)**: N/A  

**Release Manager**: _____________________________ Date: ___________  
Confirms production readiness and no blocking issues.

