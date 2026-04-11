# SAST and DAST Tools Reference

> Reference file for the BMAD DevSecOps Engineer agent.
> Read this file when selecting, configuring, and integrating static and dynamic application security testing tools into the CI/CD pipeline.

## Overview

Static Application Security Testing (SAST) identifies vulnerabilities in source code and binaries without running the application. Dynamic Application Security Testing (DAST) finds security issues in running applications by simulating attacks. Together, they provide complementary coverage of the OWASP Top 10 and CWE vulnerabilities.

---

## SAST Tools by Language

### Java

#### SpotBugs
**Purpose**: Find bugs and potential security issues in Java bytecode.
**Installation**: Download from spotbugs.readthedocs.io or install via Maven/Gradle.

**Maven Configuration** (`pom.xml`):
```xml
<plugin>
  <groupId>com.github.spotbugs</groupId>
  <artifactId>spotbugs-maven-plugin</artifactId>
  <version>4.8.1.0</version>
  <configuration>
    <effort>max</effort>
    <threshold>medium</threshold>
    <failOnError>true</failOnError>
    <excludeFilterFile>spotbugs-exclude.xml</excludeFilterFile>
    <plugins>
      <plugin>
        <groupId>com.h3xstream.findsecbugs</groupId>
        <artifactId>findsecbugs-plugin</artifactId>
        <version>1.12.0</version>
      </plugin>
    </plugins>
  </configuration>
</plugin>
```

**Gradle Configuration** (`build.gradle`):
```gradle
plugins {
  id 'com.github.spotbugs' version '6.0.0'
}

spotbugs {
  effort = 'max'
  reportLevel = 'medium'
  excludeFilter = file('spotbugs-exclude.xml')
}
```

#### SonarQube
**Purpose**: Multi-language static analysis with security focus, quality gates, and project history.
**Edition**: Community (free, single branch) or Developer/Enterprise (for full CI/CD integration).

**SonarQube Scanner Setup** (GitHub Actions):
```yaml
- name: SonarQube Scan
  uses: SonarSource/sonarqube-scan-action@master
  env:
    SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
    SONAR_LOGIN: ${{ secrets.SONAR_TOKEN }}
  with:
    args: >
      -Dsonar.projectKey=myapp
      -Dsonar.sources=src/main
      -Dsonar.tests=src/test
```

**Quality Gate Configuration** (`sonar-project.properties`):
```properties
sonar.projectKey=myapp
sonar.projectName=My Application
sonar.sources=src/main
sonar.qualitygate=Sonar way Security
# Security-focused gate conditions:
# - Vulnerabilities >= 0 → condition fails
# - Security Hotspots reviewed < 80% → condition fails
# - Blocker issues >= 1 → condition fails
```

#### Semgrep (Java)
**Purpose**: Fast, lightweight, language-agnostic static analysis.

**Semgrep Configuration** (`.semgrep.yml`):
```yaml
rules:
  - id: java-sql-injection
    patterns:
      - pattern-either:
          - pattern: $QUERY = "... " + $USER_INPUT + " ..."
          - pattern: "Statement.execute($USER_INPUT)"
    message: "SQL injection vulnerability detected"
    languages: [java]
    severity: ERROR
    cwe: CWE-89

  - id: java-hardcoded-password
    patterns:
      - pattern-either:
          - pattern: "password = \"...\""
          - pattern: "apiKey = \"...\""
    message: "Hardcoded credentials found"
    languages: [java]
    severity: ERROR
    cwe: CWE-798
```

---

### Go

#### gosec
**Purpose**: Dedicated Go security scanner checking for common vulnerabilities.

**Configuration** (`.gosec.json`):
```json
{
  "global": {
    "nosec": false,
    "audit": false
  },
  "severity": "HIGH",
  "confidence": "HIGH",
  "exclude-dir": ["test", "vendor"],
  "rules": {
    "G101": { "passphrases": ["password", "secret", "key", "token"] },
    "G102": { "exclude": [] },
    "G201": { "exclude": [] }
  }
}
```

**CLI Usage**:
```bash
gosec -conf .gosec.json -fmt json -out gosec-report.json ./...
gosec -fmt sarif -out gosec.sarif ./...
```

**GitHub Actions Integration**:
```yaml
- name: gosec Security Scanner
  uses: securego/gosec@master
  with:
    args: '-fmt json -out gosec-report.json ./...'
    
- name: Upload gosec results
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: gosec.sarif
```

#### staticcheck
**Purpose**: High-accuracy linter for Go with security and correctness checks.

**Installation**:
```bash
go install honnef.co/go/tools/cmd/staticcheck@latest
```

**Configuration** (`.staticcheck.conf`):
```
checks = ["all", "-ST1000", "-ST1003"]
# Report all checks except style-related ones
```

---

### Python

#### Bandit
**Purpose**: Security-focused linter for Python identifying hardcoded secrets, SQL injection, insecure deserialization.

**Configuration** (`.bandit`):
```yaml
exclude_dirs:
  - /test
  - /venv
tests:
  - B101  # assert_used
  - B102  # exec_used
  - B103  # set_bad_file_permissions
  - B201  # flask_debug_true
  - B301  # pickle
  - B302  # marshal
  - B303  # md5
  - B304  # ciphers
  - B305  # cipher_modes
  - B306  # mktemp_q
  - B307  # eval
  - B308  # mark_safe
  - B309  # httpsconnection
  - B310  # urllib_urlopen
  - B311  # random
  - B312  # telnetlib
  - B313  # xml_bad_etree
  - B314  # xml_bad_expat
  - B315  # xml_bad_sax
  - B316  # xml_bad_pulldom
  - B317  # xml_bad_etree_iterparse
  - B318  # xml_bad_etree_parse
  - B319  # xml_bad_etree_iterparse
  - B320  # xml_bad_elementtree
  - B321  # ftplib
  - B322  # unverified_context
  - B323  # unverified_pickle
  - B324  # hashlib
```

**CLI Usage**:
```bash
bandit -r src/ -f json -o bandit-report.json
bandit -r src/ -ll  # Only medium and high severity
```

#### Semgrep (Python)
**Configuration** (`.semgrep.yml`):
```yaml
rules:
  - id: python-hardcoded-secret
    patterns:
      - pattern-either:
          - pattern: "password = \"...\""
          - pattern: "api_key = '...'"
          - pattern: "SECRET = '...'"
    message: "Hardcoded secret detected"
    languages: [python]
    severity: ERROR

  - id: python-sql-injection
    patterns:
      - pattern: "execute($QUERY)"
      - metavariable-pattern:
          metavariable: $QUERY
          pattern-either:
            - pattern: "f\"...\""
            - pattern: "\"...\" + ..."
    message: "SQL injection risk"
    languages: [python]
    severity: ERROR
```

---

### JavaScript/TypeScript

#### ESLint with Security Plugin

**Installation**:
```bash
npm install --save-dev eslint eslint-plugin-security eslint-plugin-security-node
```

**Configuration** (`.eslintrc.json`):
```json
{
  "extends": [
    "eslint:recommended",
    "plugin:security/recommended",
    "plugin:security-node/recommended"
  ],
  "parserOptions": {
    "ecmaVersion": 2020,
    "sourceType": "module"
  },
  "env": {
    "node": true,
    "es2020": true
  },
  "rules": {
    "security/detect-object-injection": "warn",
    "security/detect-non-literal-regexp": "warn",
    "security/detect-unsafe-regex": "error",
    "security/detect-buffer-noassert": "error",
    "security/detect-child-process": "error",
    "security/detect-no-csrf-before-method-override": "error",
    "security/detect-non-literal-fs-filename": "warn",
    "security/detect-non-literal-require": "warn",
    "security/detect-possible-timing-attacks": "warn",
    "security/detect-eval-with-expr": "error",
    "security/detect-no-csrf-before-method-override": "error"
  }
}
```

**CLI Usage**:
```bash
eslint --ext .js,.ts src/ --format json --output-file eslint-report.json
```

#### Semgrep (JavaScript/TypeScript)
**Configuration** (`.semgrep.yml`):
```yaml
rules:
  - id: js-hardcoded-api-key
    patterns:
      - pattern-either:
          - pattern: "const API_KEY = \"...\""
          - pattern: "const token = '...'"
    message: "Hardcoded API key detected"
    languages: [javascript, typescript]
    severity: ERROR

  - id: ts-dangerous-eval
    patterns:
      - pattern: "eval($CODE)"
    message: "Use of eval() is dangerous"
    languages: [typescript]
    severity: ERROR
```

---

## Unified Cross-Language SAST with Semgrep

**Why Semgrep**: Single tool across all languages, fast local scanning, custom rules, easy CI integration.

### Semgrep Installation and Setup

```bash
# Install via pip
pip install semgrep

# Or via Homebrew
brew install semgrep
```

### Ruleset Selection

Semgrep provides pre-built rulesets:

```bash
# Run all security rules
semgrep --config=p/security-audit src/

# Run OWASP Top 10 specific rules
semgrep --config=p/owasp-top-ten src/

# Run CWE rules
semgrep --config=p/cwe-top-25 src/

# Run language-specific security
semgrep --config=p/python --config=p/javascript src/

# Combine multiple rulesets
semgrep --config=p/security-audit --config=p/owasp-top-ten src/
```

### Custom Rules

**Create a custom rule** (`.semgrep/custom-rules.yml`):
```yaml
rules:
  - id: company-banned-library
    pattern-either:
      - pattern: "import insecure_lib"
      - pattern: "require('insecure_lib')"
    message: "Banned library detected per company policy"
    languages: [python, javascript]
    severity: ERROR
    
  - id: missing-input-validation
    patterns:
      - pattern: "user_input = request.args.get(...)"
      - pattern-not: "validate($USER_INPUT)"
    message: "User input not validated"
    languages: [python]
    severity: HIGH
```

### Semgrep CI Integration (GitHub Actions)

```yaml
name: Semgrep Security Scan

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  semgrep:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run Semgrep
        uses: returntocorp/semgrep-action@v1
        with:
          config: >-
            p/security-audit
            p/owasp-top-ten
            .semgrep/custom-rules.yml
          generateSarif: true
          
      - name: Upload SARIF results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: semgrep.sarif
          
      - name: Fail on Critical findings
        if: ${{ always() }}
        run: |
          semgrep --config=p/security-audit --json --output=semgrep-full.json src/ || true
          python3 - <<'EOF'
          import json
          with open('semgrep-full.json') as f:
            results = json.load(f)
          critical_count = sum(1 for r in results.get('results', []) if r.get('extra', {}).get('severity') == 'ERROR')
          if critical_count > 0:
            print(f"Found {critical_count} CRITICAL findings")
            exit(1)
          EOF
```

### Suppression

**Semgrep .semgrepignore**:
```
# Ignore test directories
tests/
test_*.py
*.test.js

# Ignore specific vulnerability in safe context
src/legacy/parser.py  # Known safe SQL construction

# Ignore by comment
# nosemgrep: id-unsafe-pattern
```

---

## DAST Tools

### OWASP ZAP (Zed Attack Proxy)

**Purpose**: Find vulnerabilities in running web applications through active and passive scanning.

**Installation**:
```bash
# Docker
docker pull ghcr.io/zaproxy/zaproxy:stable

# Homebrew (macOS)
brew install zaproxy
```

**Configuration** (`zap-config.yaml`):
```yaml
contexts:
  - name: Default Context
    urls:
      - https://app.example.com
    excludedUrls:
      - https://app.example.com/logout
      - https://app.example.com/admin

authentication:
  manual: false
  autodetect: true

scanner:
  maxRuleDurationInMins: 0
  delayInMs: 0
  handleODataParametersVisited: false
  targetParamsEnabledRPC: []
  targetParamsEnabledJSON: []
  maxAlertsPerRule: 10
  mergeRelatedAlerts: true

policies:
  - name: API-Scan
    rules:
      - id: 40016
        threshold: MEDIUM
      - id: 40017
        threshold: HIGH
```

**GitHub Actions Integration**:
```yaml
- name: Run OWASP ZAP Scan
  run: |
    docker run -t ghcr.io/zaproxy/zaproxy:stable \
      zap-baseline.py \
      -t https://app-staging.example.com \
      -r zap-report.html \
      -x zap-report.xml \
      -J zap-report.json \
      -z "-config api.disablekey=true"

- name: Parse ZAP results
  run: |
    python3 parse_zap.py zap-report.json || exit 1

- name: Upload ZAP artifact
  if: always()
  uses: actions/upload-artifact@v3
  with:
    name: zap-report
    path: zap-report.html
```

**ZAP Rules by Severity**:
- **Critical (40018, 90011)**: SQL Injection, RCE, Authentication bypass
- **High (40016, 40017, 40027)**: Cross-site scripting (XSS), CSRF, Insecure deserialization
- **Medium (10010, 10015, 10021)**: Missing security headers, insecure cookies, unencrypted transmission
- **Low (10002, 10009, 10023)**: Information disclosure, weak authentication, outdated frameworks

---

### Burp Suite Enterprise

**Purpose**: Commercial dynamic scanner with advanced context, guided scanning, and integrations.

**Strengths**:
- Macro recording for complex authentication flows
- Active scanning with tight feedback loop
- Integration with upstream tools (SIEM, Slack, Jira)
- Saved scans and baseline comparisons

**Typical Workflow**:
1. Configure authentication macro
2. Define scan scope (target URLs, parameter exclusions)
3. Run guided scan or custom audit
4. Export findings in SARIF/JSON
5. Integrate with CI/CD or ticketing system

---

### Nuclei Templates

**Purpose**: Community-driven vulnerability and misconfiguration scanning with custom templates.

**Installation**:
```bash
go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest
```

**Template Example** (`http-open-redirect.yaml`):
```yaml
id: http-open-redirect

info:
  name: HTTP Open Redirect
  author: pdteam
  severity: medium
  description: HTTP open redirect vulnerability allows attackers to redirect users to malicious sites

requests:
  - method: GET
    path:
      - "{{RootURL}}/?redirect={{BaseURL}}"
      - "{{RootURL}}/redirect?url={{BaseURL}}"
      - "{{RootURL}}/next={{BaseURL}}"
    matchers:
      - type: status
        status:
          - 301
          - 302
          - 307
      - type: regex
        regex:
          - '(?i)(location|refresh)\s*:\s*http'
        headers:
          Location: '{{BaseURL}}'
```

**GitHub Actions Integration**:
```yaml
- name: Nuclei Scan
  run: |
    nuclei -l targets.txt \
      -templates ~/nuclei-templates \
      -severity critical,high \
      -json -o nuclei-results.json \
      -timeout 10
```

---

## SonarQube Quality Gate Configuration

**Security-Focused Quality Gate**:

| Condition | Operator | Value | Status |
|-----------|----------|-------|--------|
| Vulnerabilities | >= | 0 | FAIL |
| Security Hotspots Reviewed | < | 80% | FAIL |
| Blocker Issues | >= | 1 | FAIL |
| Critical Issues | >= | 5 | FAIL |
| Code Coverage | < | 75% | FAIL |
| Duplication | > | 5% | WARN |

---

## OWASP Top 10 to Scanner Mapping

| OWASP Top 10 | CWE | SAST Detection | DAST Detection |
|--------------|-----|----------------|----------------|
| A01:Broken Access Control | CWE-639 | Limited (code review) | DAST (auth bypass, path traversal) |
| A02:Cryptographic Failures | CWE-327, CWE-328 | SAST (weak ciphers, hardcoded keys) | DAST (unencrypted transmission) |
| A03:Injection | CWE-89, CWE-79, CWE-90 | SAST (SQL, template, LDAP injection) | DAST (injection payloads) |
| A04:Insecure Design | CWE-434, CWE-754 | Limited | Threat modeling, manual review |
| A05:Security Misconfiguration | CWE-16 | IaC scanning (Checkov) | DAST (missing headers, weak configs) |
| A06:Vulnerable Components | CWE-1104 | Dependency scanning (Snyk, OWASP DC) | Env-dependent |
| A07:Identification Auth | CWE-287, CWE-640 | Limited | DAST (weak auth, session mgmt) |
| A08:Software Data Integrity | CWE-434, CWE-502 | SAST (deserialization, insecure updates) | DAST (upload, XXE) |
| A09:Logging Monitoring Failures | CWE-778 | Code review, config validation | Manual verification |
| A10:SSRF | CWE-918 | SAST (URL construction) | DAST (SSRF probes) |

---

## Severity Classification and Build Impact

| Severity | CVSS Range | SAST Action | DAST Action | Build Impact |
|----------|------------|-------------|-------------|--------------|
| Critical | 9.0–10.0 | Break build | Break build | FAIL |
| High | 7.0–8.9 | Break build on PR | Break build | FAIL |
| Medium | 4.0–6.9 | Create ticket | Create ticket | WARN/Advisory |
| Low | 0.1–3.9 | Log as advisory | Log as advisory | ADVISORY |

---

## CI Integration Best Practices

1. **Gate on Critical/High severity**: Break build, prevent merge
2. **Trend tracking**: Store results over time, alert on regressions
3. **False positive suppression**: Maintain suppression files with expiry
4. **Artifact retention**: Archive scan reports for audit trail
5. **Notification**: Slack/email notifications for new critical findings
6. **Remediation SLAs**: Critical 24h, High 7d, Medium 30d, Low 90d
7. **Baseline comparison**: Compare PR scan to main branch
8. **Skip scans on vendor/third-party code**: Use exclusion lists
9. **Regular updates**: Update scanner rules and definitions monthly
10. **Tool maintenance**: Test scanner performance monthly, optimize noisy rules

