# Security Pipeline Gates Reference

> Reference file for the BMAD DevSecOps Engineer agent.
> Read this file when designing security quality gates, defining severity thresholds, enforcing risk acceptance workflows, and implementing security metrics in CI/CD pipelines.

## Gate Taxonomy: Blocking vs. Advisory

**Blocking Gates**: Break the build or prevent merge to main
- **Purpose**: Enforce non-negotiable security standards
- **Trigger**: Fail pipeline, block PR merge
- **Typical use**: Critical/High severity findings

**Advisory Gates**: Log findings, create tickets, allow proceed
- **Purpose**: Track risk without stopping development
- **Trigger**: Create JIRA ticket, Slack notification, metric tracking
- **Typical use**: Medium/Low findings, false positives accepted on review

---

## Gate Definitions by Pipeline Stage

### Stage 1: Pull Request (PR Checks)

**Gate 1.1: Secrets Scanning (Gitleaks)**
- **Tool**: Gitleaks
- **Trigger**: Every PR push
- **Blocking**: YES (Critical)
- **Action on fail**: 
  - Fail PR checks
  - Block merge until resolved
  - Notify security team + author
- **Acceptable result**: No secrets detected
- **False positive handling**: Whitelist in `.gitleaks.toml` with expiry

```yaml
# GitHub Actions
- name: Gitleaks PR Check
  run: |
    gitleaks detect --source . --exit-code 1 --report-format json -o gitleaks.json
```

**Gate 1.2: SAST Scan (Semgrep)**
- **Tool**: Semgrep
- **Trigger**: Every PR push
- **Blocking**: If findings >= HIGH severity
- **Severity thresholds**:
  - CRITICAL/ERROR: Block immediately
  - HIGH: Block
  - MEDIUM: Advisory, create ticket
  - LOW: Log only
- **Action on HIGH/CRITICAL fail**:
  - Fail PR checks
  - Comment on PR with findings
  - Assign to author
- **Accepted**: 0 CRITICAL, 0 HIGH

```yaml
- name: Semgrep SAST PR Check
  run: |
    semgrep --config=p/security-audit --json --output=semgrep.json .
    python3 check_semgrep_gate.py semgrep.json
```

**Gate 1.3: Container Image Scan (Trivy)**
- **Tool**: Trivy
- **Trigger**: If Dockerfile changed
- **Blocking**: If CRITICAL vulnerability found
- **Severity thresholds**:
  - CRITICAL: Block
  - HIGH: Advisory (allow with ticket)
- **Action on CRITICAL fail**:
  - Fail PR checks
  - Comment with vulnerable image layers
  - Request patch

```yaml
- name: Trivy Image Scan on PR
  if: contains(github.event.pull_request.files, 'Dockerfile')
  run: |
    docker build -t myapp:pr-${{ github.event.pull_request.number }} .
    trivy image --severity CRITICAL --exit-code 1 myapp:pr-${{ github.event.pull_request.number }}
```

**Gate 1.4: IaC Misconfiguration Scan (Checkov)**
- **Tool**: Checkov
- **Trigger**: If Terraform/K8s/CloudFormation changed
- **Blocking**: If CRITICAL misconfiguration found
- **Severity mapping**:
  - CKV_AWS_1 (high-risk): CRITICAL
  - CKV_AWS_20 (medium-risk): HIGH/MEDIUM
- **Action on fail**: Fail PR, request remediation

```yaml
- name: Checkov IaC Scan on PR
  uses: bridgecrewio/checkov-action@master
  with:
    framework: terraform,kubernetes,cloudformation
    soft-fail: false
    skip-check: CKV_AWS_1  # Exempted via decision
```

### Stage 2: Merge to Main (Integration Tests)

**Gate 2.1: Full SAST + Dependency Scan**
- **Tools**: Semgrep, Snyk, OWASP Dependency-Check
- **Trigger**: On merge to main
- **Blocking**: If unresolved HIGH/CRITICAL from last PR not found
- **Purpose**: Catch regressions, new issues since PR approval
- **Action on fail**:
  - Revert merge
  - Open issue "Security regression detected"
  - Notify security team
- **Accepted**: Only LOW/MEDIUM from documented risk acceptance

```yaml
- name: Full Security Gate on Main
  if: github.ref == 'refs/heads/main'
  run: |
    semgrep --config=p/security-audit --config=p/owasp-top-ten --json .
    snyk test --severity-threshold=high --json
    dependency-check.sh --failOnCVSS 7.0
```

**Gate 2.2: License Compliance Check**
- **Tool**: FOSSA, Licensefinder, or custom script
- **Trigger**: On merge to main
- **Blocking**: If prohibited license detected
- **Prohibited licenses**: SSPL, GPL (without exception), custom proprietary
- **Action on fail**:
  - Require legal review
  - Document approved exception
  - Update dependency
- **Accepted**: All dependencies in approved list

### Stage 3: Staging Deployment

**Gate 3.1: DAST Scan (OWASP ZAP)**
- **Tool**: OWASP ZAP
- **Trigger**: After successful deployment to staging
- **Blocking**: If CRITICAL finding not remediated from previous scan
- **Severity thresholds**:
  - CRITICAL (SQL Injection, RCE): Block deployment
  - HIGH (XSS, CSRF, weak auth): Advisory, create ticket
- **Action on CRITICAL fail**:
  - Rollback staging
  - Investigate finding
  - Remediate + rescan

```yaml
- name: DAST Scan - Staging
  run: |
    docker run -t ghcr.io/zaproxy/zaproxy:stable \
      zap-baseline.py -t https://staging.example.com \
      -r zap-report.html -x zap-report.xml
    python3 parse_zap_gate.py zap-report.xml
```

**Gate 3.2: SBOM Attestation**
- **Purpose**: Verify software composition is documented
- **Blocking**: If SBOM missing or invalid
- **Action**: Require SBOM generation before staging release

```bash
syft staging.example.com:v1.0.0 -o cyclonedx > sbom.xml
# Fail if not present
```

**Gate 3.3: Container Signature Verification**
- **Tool**: Cosign
- **Purpose**: Verify image was built by authorized CI/CD
- **Blocking**: If image not signed
- **Action on fail**: Prevent deployment

```bash
cosign verify --key cosign.pub gcr.io/myproject/staging:v1.0.0
```

### Stage 4: Release Candidate / Production Promotion

**Gate 4.1: Final Security Sign-Off Report**
- **Purpose**: Executive approval of remaining findings
- **Blocking**: Until security team signs off
- **Required fields**:
  - All critical findings resolved
  - All high findings either patched or risk-accepted
  - CVE summary (total count by severity)
  - False positive documentation
  - Third-party dependency audit
  - Pen test results (if applicable)
- **Sign-off template**:
  ```
  Release: myapp-v2.0.0
  Security Team Lead: [Name]
  Approval Date: [Date]
  Finding Summary:
    - CRITICAL: 0 (target: 0)
    - HIGH: 2 (both risk-accepted)
    - MEDIUM: 15 (tracked in backlog)
    - LOW: 42 (deferred)
  
  Risks Accepted:
    1. CVE-2024-12345 in legacy-lib (compensated by WAF)
    2. Hardcoded test key in non-prod path (remediate in v2.1)
  
  Sign-off: [Signature]
  ```

**Gate 4.2: No Unresolved Critical/High Findings**
- **Blocking**: YES
- **Scope**: All scanning tools (SAST, DAST, container, IaC, dependencies)
- **Action on fail**: Delay release until remediated

---

## Severity Classification and Thresholds

### CVSS to Gate Mapping

| CVSS Score | Severity | SAST Action | DAST Action | Container Action | Gate Type |
|-----------|----------|-------------|-------------|------------------|-----------|
| 9.0–10.0 | CRITICAL | Break PR | Break deployment | Break push | BLOCKING |
| 7.0–8.9 | HIGH | Break PR | Break staging | Break push | BLOCKING |
| 4.0–6.9 | MEDIUM | Create ticket | Create ticket | Allow with warning | ADVISORY |
| 0.1–3.9 | LOW | Track in dashboard | Track in dashboard | Log only | ADVISORY |

### Tool-Specific Severity Mapping

**Semgrep**:
- ERROR = CRITICAL (CWE top-25)
- WARNING = HIGH (OWASP Top 10)
- NOTE = MEDIUM (informational)

**Trivy**:
- CRITICAL = CVSS 9.0–10.0
- HIGH = CVSS 7.0–8.9
- MEDIUM = CVSS 4.0–6.9
- LOW = CVSS 0.1–3.9

**Checkov**:
- FAILED (high-risk checks) = CRITICAL (e.g., public S3 bucket)
- FAILED (medium-risk checks) = HIGH (e.g., missing encryption)
- PASSED = No action

**ZAP**:
- Alert High = CRITICAL (exploitable)
- Alert Medium = HIGH (potential impact)
- Alert Low = MEDIUM (informational)

---

## Risk Acceptance Process

### Approval Authority

| Severity | Authority | SLA for Decision | SLA for Remediation |
|----------|-----------|------------------|-------------------|
| CRITICAL | CISO + Engineering Lead | 24h | 7 days |
| HIGH | Security Lead + Product Owner | 48h | 30 days |
| MEDIUM | Engineering Lead | 7 days | 90 days |
| LOW | Team discretion | 14 days | No deadline |

### Risk Acceptance Form

**Required Fields**:
```
Risk ID: [Auto-generated or CVE ID]
Severity: [CRITICAL/HIGH/MEDIUM/LOW]
Finding: [Description]
  - Affected component: [Package/module]
  - CWE: [CWE-###]
  - CVSS Score: [X.X]

Why accept this risk:
  - Compensating control: [WAF rule, network isolation, input validation]
  - Limited exposure: [Internal only, read-only, low-usage code path]
  - Patching impact: [Breaking change, incompatibility, deployment window required]
  - Business justification: [Strategic reason to accept]

Remediation plan:
  - Target remediation date: [Date]
  - Owner: [Name + team]
  - Tracking: [JIRA ticket]

Approval chain:
  - Requestor: [Name + signature] [Date]
  - Security Lead: [Name + signature] [Date]
  - CISO (if CRITICAL): [Name + signature] [Date]

Expiration: [Date - auto-close if not remediated by this date]
```

### Risk Acceptance Workflow

1. **Discovery**: Scanner finds issue, fails gate
2. **Triage**: Team assesses if truly exploitable in context
3. **Decision**: Document risk acceptance or commit to remediation
4. **Approval**: Get required signature(s)
5. **Implementation**: Add to suppression file with expiry
6. **Tracking**: Create JIRA ticket with remediation date
7. **Re-assessment**: Auto-reminder 1 month before expiry
8. **Expiration**: Auto-fail gate if not resolved by expiry

---

## False Positive Management

### Suppression Strategies

**1. Global Suppression** (tool config)
```yaml
# .semgrepignore or .trivyignore
# Ignore entire rule/check ID across all code
CKV_AWS_1  # S3 public access (not used in our arch)
SNYK-JS-MOMENT-1026986  # We only use moment for internal logging
```

**2. File/Path Suppression** (in code)
```hcl
# Terraform: inline comment
resource "aws_s3_bucket" "legacy" {
  acl = "public-read"  # tfsec:ignore=aws-s3-block-public-acl
}

# Python: code comment
# nosemgrep: id-unsafe-pattern
unsafe_function()
```

**3. Time-Limited Suppression** (with expiry)
```yaml
# .trivyignore
CVE-2021-99999 exp:2025-06-30 severity:MEDIUM justification:"WAF mitigates"
```

### Review Cadence

- **Monthly**: Review all active suppressions, update expiry dates
- **Quarterly**: Deep-dive on suppressions nearing expiry
- **Re-assessment**: If suppressed issue appears in new tool/scan
- **Escalation**: If suppression expired and finding still open

---

## Security Debt Tracking

### JIRA Ticket Structure

**Security Finding Ticket Template**:
```
Title: [CRITICAL/HIGH] [Tool] [Vulnerability] in [Component]

Description:
Finding ID: [CVE-2024-xxxxx / CKV_AWS_1 / SNYK-JS-xxxxx]
Tool: [Semgrep / Trivy / ZAP / etc.]
Severity: [CRITICAL/HIGH/MEDIUM/LOW]
CVSS: [Score + vector]
CWE: [CWE-###]

Affected Component: [Package/service/path]
Current Version: [X.Y.Z]
Fixed Version: [X.Y.Z or "N/A"]

Description: [Detailed explanation of vulnerability]

Risk Exposure: [Who/what is affected]

Remediation:
- [ ] Identify fix (patch version or code change)
- [ ] Test in dev
- [ ] Test in staging
- [ ] Deploy to production
- [ ] Verify in prod (monitoring checks)

Target Completion: [Date]
Owner: [Name + team]
Labels: security, technical-debt, blocking
```

### SLA Enforcement

| Severity | P1 SLA | P2 SLA | P3 SLA | P4 SLA |
|----------|--------|--------|--------|--------|
| CRITICAL | 24h | 7d | - | - |
| HIGH | 7d | 30d | - | - |
| MEDIUM | 30d | 90d | - | - |
| LOW | 90d | - | - | - |

**SLA Tracking**:
```bash
# Query Jira for overdue security tickets
jira issue list \
  --status "In Progress,To Do" \
  --label security \
  --jql "created < -7d AND priority >= High"
```

---

## GitHub Actions Complete Pipeline Example

```yaml
name: Multi-Stage Security Pipeline

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [main, develop, staging]
  schedule:
    - cron: '0 2 * * 0'  # Weekly scan

jobs:
  # STAGE 1: PR Checks
  pr-secrets-scan:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0
    
    - name: Gitleaks Secret Scan
      run: |
        wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
        tar xzf gitleaks_8.18.0_linux_x64.tar.gz
        ./gitleaks detect --source . --exit-code 1
    
  pr-sast-scan:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Semgrep SAST Scan
      run: |
        pip install semgrep
        semgrep --config=p/security-audit --config=p/owasp-top-ten \
          --json --output=semgrep.json . || true
        python3 gate_check.py semgrep.json "SAST" 0 0  # Fail on any HIGH/CRITICAL
    
  pr-container-scan:
    if: github.event_name == 'pull_request' && contains(github.event.pull_request.files, 'Dockerfile')
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Build container image
      run: docker build -t pr-scan:${{ github.event.pull_request.number }} .
    
    - name: Trivy vulnerability scan
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: pr-scan:${{ github.event.pull_request.number }}
        format: 'json'
        output: 'trivy-pr.json'
        severity: 'CRITICAL'
        exit-code: '1'
  
  # STAGE 2: Main Branch Integration
  main-full-scan:
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    steps:
    - uses: actions/checkout@v3
    
    - name: Full SAST scan
      run: semgrep --config=p/security-audit --json --output=semgrep-main.json . || true
    
    - name: Dependency audit
      run: |
        pip install pip-audit
        pip-audit --format json > pip-audit.json || true
    
    - name: Check severity gates
      run: |
        python3 - <<'EOF'
        import json
        failed = False
        
        with open('semgrep-main.json') as f:
          results = json.load(f)
          critical = [r for r in results['results'] if r['extra']['severity'] == 'ERROR']
          if critical:
            print(f"FAIL: {len(critical)} CRITICAL findings")
            failed = True
        
        if failed:
          exit(1)
        EOF
  
  # STAGE 3: Staging Deployment Scan
  staging-dast:
    if: github.ref == 'refs/heads/staging' && github.event_name == 'push'
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Wait for staging deployment
      run: sleep 60
    
    - name: DAST scan with ZAP
      run: |
        docker run -t ghcr.io/zaproxy/zaproxy:stable \
          zap-baseline.py -t https://staging.example.com \
          -r zap-report.html -x zap-report.xml
    
    - name: Parse ZAP results
      run: |
        python3 parse_zap.py zap-report.xml
        # Fail if any unresolved CRITICAL from previous scan
  
  # STAGE 4: Release Approval
  production-approval:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    environment:
      name: production-release
      reviewers:
        - security-lead
        - engineering-lead
    steps:
    - uses: actions/checkout@v3
    
    - name: Compile security report
      run: |
        echo "## Security Approval Report" >> $GITHUB_STEP_SUMMARY
        echo "**Build**: ${{ github.run_number }}" >> $GITHUB_STEP_SUMMARY
        echo "**Commit**: ${{ github.sha }}" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "### Findings Summary" >> $GITHUB_STEP_SUMMARY
        # Aggregate all scan results
        jq '.results | length' semgrep-main.json >> $GITHUB_STEP_SUMMARY
```

