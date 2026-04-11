# Dependency Scanning and Supply Chain Security Reference

> Reference file for the BMAD DevSecOps Engineer agent.
> Read this file when scanning dependencies for vulnerabilities, managing license compliance, tracking software composition, and preventing supply chain attacks.

## SBOM (Software Bill of Materials) Generation and Scanning

**Purpose**: Create machine-readable dependency inventory and scan for vulnerabilities.

### CycloneDX Format (Recommended)

CycloneDX is the industry standard, used by NTIA and CISA.

```xml
<?xml version="1.0" encoding="UTF-8"?>
<bom xmlns="http://cyclonedx.org/schema/bom/1.4" version="1">
  <metadata>
    <timestamp>2026-04-11T10:30:00Z</timestamp>
    <tools>
      <tool>
        <vendor>CycloneDX</vendor>
        <name>syft</name>
        <version>0.68.0</version>
      </tool>
    </tools>
    <component>
      <name>myapp</name>
      <version>1.0.0</version>
      <type>application</type>
    </component>
  </metadata>
  <components>
    <component type="library">
      <name>requests</name>
      <version>2.28.1</version>
      <purl>pkg:pypi/requests@2.28.1</purl>
      <licenses>
        <license>
          <name>Apache-2.0</name>
        </license>
      </licenses>
    </component>
    <component type="library">
      <name>django</name>
      <version>4.2.0</version>
      <purl>pkg:pypi/django@4.2.0</purl>
      <vulnerabilities>
        <vulnerability ref="CVE-2023-12345">
          <source>NVD</source>
          <ratings>
            <rating>
              <score>
                <base>7.5</base>
                <vector>CVSS:3.1/AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N</vector>
              </score>
            </rating>
          </ratings>
        </vulnerability>
      </vulnerabilities>
    </component>
  </components>
</bom>
```

### SPDX Format

SPDX is the ISO/IEC standard for software bill of materials.

```json
{
  "SPDXID": "SPDXRef-DOCUMENT",
  "spdxVersion": "SPDX-2.3",
  "creationInfo": {
    "created": "2026-04-11T10:30:00Z",
    "creators": ["Tool: syft-0.68.0"]
  },
  "name": "myapp",
  "dataLicense": "CC0-1.0",
  "documentNamespace": "https://syft.dev/spdxdocs/myapp-1.0.0",
  "packages": [
    {
      "SPDXID": "SPDXRef-Package-requests",
      "name": "requests",
      "versionInfo": "2.28.1",
      "downloadLocation": "NOASSERTION",
      "filesAnalyzed": false,
      "externalRefs": [
        {
          "referenceCategory": "PACKAGE-MANAGER",
          "referenceType": "purl",
          "referenceLocator": "pkg:pypi/requests@2.28.1"
        }
      ]
    }
  ]
}
```

### Syft: SBOM Generation

**Installation**:
```bash
# Homebrew
brew install syft

# Go
go install github.com/anchore/syft/cmd/syft@latest

# Docker
docker pull ghcr.io/anchore/syft:latest
```

**Usage**:
```bash
# Generate SBOM from image
syft ghcr.io/myorg/myapp:v1.0.0 -o json > sbom.json

# Generate CycloneDX
syft ghcr.io/myorg/myapp:v1.0.0 -o cyclonedx > sbom.xml

# Generate SPDX
syft ghcr.io/myorg/myapp:v1.0.0 -o spdx-json > sbom-spdx.json

# Scan filesystem
syft /path/to/app -o json > app-sbom.json

# Scan tar file
syft tar:/path/to/archive.tar -o json

# Output human-readable table
syft ghcr.io/myorg/myapp:v1.0.0 -o table

# Include license information
syft ghcr.io/myorg/myapp:v1.0.0 -o cyclonedx-with-license > sbom-with-licenses.xml
```

### Grype: SBOM Vulnerability Scanning

**Installation**:
```bash
brew install grype
# or
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

**Scan SBOM**:
```bash
# Scan existing SBOM
grype sbom.json -o json > vulnerability-scan.json

# Scan image directly
grype ghcr.io/myorg/myapp:v1.0.0 -o json

# Generate SARIF
grype sbom.json -o sarif > grype.sarif

# Show only critical/high
grype sbom.json --fail-on high

# Generate human-readable report
grype sbom.json -o table
```

---

## OWASP Dependency-Check

**Purpose**: Identify known vulnerabilities in dependencies.

**Installation**:
```bash
# Download binary
wget https://github.com/jeremylong/DependencyCheck_Home/releases/download/v8.4.0/dependency-check-8.4.0-release.zip
unzip dependency-check-8.4.0-release.zip
export PATH=$PATH:$(pwd)/dependency-check/bin

# Homebrew
brew install dependency-check

# Docker
docker pull ghcr.io/jeremylong/dependencycheck:latest
```

**Configuration** (`.dependencycheck.properties`):
```properties
# NVD API key (speeds up scanning)
nvd.api.key=YOUR_API_KEY

# Data directory
data.directory=./dependency-check-data

# Suppress known false positives
suppression.file=.dependencycheck-suppressions.xml

# Report format
format=ALL  # HTML, JSON, XML, CSV
report.directory=./dependency-check-reports
```

**Usage**:
```bash
# Scan project
dependency-check.sh --project myapp --scan .

# Scan specific directory
dependency-check.sh --project myapp --scan ./src --scan ./lib

# Generate JSON report
dependency-check.sh --project myapp --scan . --format JSON --report ./reports

# Use NVD API for faster updates
dependency-check.sh --project myapp --scan . --nvdApiKey YOUR_API_KEY

# Generate HTML report
dependency-check.sh --project myapp --scan . --format HTML --report ./reports

# Fail on high severity
dependency-check.sh --project myapp --scan . --failOnCVSS 7.0
```

**Suppression File** (`.dependencycheck-suppressions.xml`):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<suppressions xmlns="https://jeremylong.github.io/DependencyCheck/dependency-suppression.1.4.xsd">
  <suppress until="2026-12-31">
    <notes><![CDATA[This vulnerability is not exploitable in our usage of the library.]]></notes>
    <cve>CVE-2021-12345</cve>
    <package regex="true">log4j:log4j.*</package>
  </suppress>
  
  <suppress>
    <notes><![CDATA[False positive: our safe wrapper mitigates risk]]></notes>
    <cve>CVE-2022-67890</cve>
    <cpe>cpe:/a:vendor:product:1.0.0</cpe>
  </suppress>
</suppressions>
```

---

## Snyk

**Purpose**: Developer-friendly vulnerability and license scanning with fix PR generation.

**Installation**:
```bash
npm install -g snyk

# Authenticate
snyk auth

# Or use environment variable
export SNYK_TOKEN=your_token
```

**Configuration** (`.snyk`):
```yaml
# Snyk policy file
version: v1.19.0
ignore:
  SNYK-JS-MINIMIST-2088859:
    - '*':
        reason: Acceptable risk
        expires: 2025-12-31
  SNYK-PYTHON-DJANGORESTFRAMEWORK-3113181:
    - '*':
        reason: Mitigated by WAF
        expires: 2026-06-30

patch: {}
vulnerability-threshold: high
```

**CLI Usage**:
```bash
# Test for vulnerabilities
snyk test

# Test with JSON output
snyk test --json > snyk-results.json

# Test with severity filter
snyk test --severity-threshold=high

# Test specific project file
snyk test --file=package.json

# Test multiple ecosystems
snyk test --file=package.json --file=requirements.txt

# Generate SBOM
snyk sbom --format=cyclonedx > sbom.xml

# Monitor for new vulnerabilities
snyk monitor
# Creates snapshot in Snyk dashboard

# Auto-generate fix PR
snyk fix --dry-run
snyk fix  # Creates PR with dependency updates
```

**GitHub Actions Integration**:
```yaml
- uses: snyk/actions/setup@master

- name: Snyk Security Test
  run: snyk test --json > snyk-results.json

- name: Generate fix PR
  run: snyk fix --skip-unresolved

- name: Monitor
  run: snyk monitor
```

---

## Language-Specific Dependency Audits

### npm audit (Node.js)

```bash
# Audit installed dependencies
npm audit

# Generate JSON report
npm audit --json > npm-audit.json

# Fix vulnerabilities (updates package.json)
npm audit fix

# Fix only high/critical
npm audit fix --audit-level=high

# Exclude dev dependencies
npm audit --omit=dev
```

**`.npmrc` configuration**:
```
audit-level=high
# Fail npm install if audit fails
```

### pip audit (Python)

**Installation**:
```bash
pip install pip-audit
```

**Usage**:
```bash
# Audit installed packages
pip-audit

# Generate JSON report
pip-audit --format json > pip-audit.json

# Scan requirements file
pip-audit --requirement requirements.txt

# Skip dependencies
pip-audit --skip CVE-2021-12345

# List discovered vulnerabilities
pip-audit --show-full
```

### mvn dependency-check (Java)

**Maven Configuration** (`pom.xml`):
```xml
<plugin>
  <groupId>org.owasp</groupId>
  <artifactId>dependency-check-maven</artifactId>
  <version>8.4.0</version>
  <configuration>
    <failBuildOnCVSS>7.0</failBuildOnCVSS>
    <skipDependencyTree>false</skipDependencyTree>
    <suppressionFiles>
      <suppressionFile>.dependencycheck-suppressions.xml</suppressionFile>
    </suppressionFiles>
  </configuration>
  <executions>
    <execution>
      <goals>
        <goal>check</goal>
      </goals>
    </execution>
  </executions>
</plugin>
```

**Run**:
```bash
mvn dependency-check:check

# Generate report
mvn dependency-check:check -Ddependency-check.format=ALL
```

### govulncheck (Go)

```bash
# Check for known vulnerabilities
go run golang.org/x/vuln/cmd/govulncheck@latest ./...

# JSON output
go run golang.org/x/vuln/cmd/govulncheck@latest -json ./... > vulns.json

# Scan specific module
go run golang.org/x/vuln/cmd/govulncheck@latest -tags linux,amd64 ./...
```

### bundle audit (Ruby)

```bash
# Install bundler-audit plugin
gem install bundler-audit

# Audit Gemfile.lock
bundle audit

# Generate JSON report
bundle audit --format=json > bundle-audit.json

# Update advisory database
bundle audit update

# Ignore specific advisories
bundle audit ignore CVE-2021-12345 --expire=2025-12-31
```

---

## License Compliance Scanning

### Tools Overview

| Tool | Best For | Output | Integration |
|------|----------|--------|-------------|
| FOSSA | Multi-ecosystem + compliance | HTML, JSON, PDF | CI, Jira |
| Black Duck (Synopsys) | Enterprise policy + risk | Dashboard | CI, enterprise tools |
| Licensefinder | Ruby/Python/Node clarity | CSV, JSON | CI-agnostic |
| SPDX-sbom-to-csv | Simple SBOM analysis | CSV | Lightweight |
| Snyk | Dev workflows | Dashboard | GitHub, GitLab |

### License Categories

**Approved** (generally safe for commercial):
- MIT
- Apache-2.0
- BSD (2-Clause, 3-Clause)
- ISC
- MPL-2.0

**Restricted/Copyleft** (require compliance):
- GPL-2.0, GPL-3.0 (must open-source derivative works)
- AGPL-3.0 (must open-source SaaS services)
- LGPL-2.1, LGPL-3.0

**Proprietary** (case-by-case):
- Unlicensed
- Custom licenses
- Evaluation licenses

### License Policy File

**`license-policy.yaml`**:
```yaml
approved_licenses:
  - MIT
  - Apache-2.0
  - BSD-2-Clause
  - BSD-3-Clause
  - ISC
  - MPL-2.0

restricted_licenses:
  - GPL-2.0
  - GPL-3.0
  - AGPL-3.0

prohibited_licenses:
  - SSPL  # Server-Side Public License
  - proprietary

overrides:
  "requests@2.28.1":
    license: Apache-2.0
    reason: Override detected license
  "legacy-lib@1.0.0":
    license: MIT
    approved: true
    expires: 2026-12-31
    justification: Approved by legal for legacy project
```

### Licensefinder (Ruby Example)

```bash
# Install
gem install license_finder

# Scan project
license_finder

# Generate CSV report
license_finder report --format csv > licenses.csv

# Generate JSON
license_finder report --format json > licenses.json

# Approve license
license_finder license add "MIT" "my-lib" "1.0.0"

# Exclude dependency
license_finder license exclude "MIT" --group development
```

---

## CVE Triage and Remediation Workflow

### Triage Decision Matrix

| CVSS Score | Exploitability | Exposure | Action | SLA |
|-----------|-----------------|----------|--------|-----|
| 9.0–10.0 | Active/PoC | Internet-facing | Patch immediately | 24h |
| 7.0–8.9 | Active | Internet-facing | Patch within 7 days | 7d |
| 7.0–8.9 | No PoC | Internal only | Plan patch within 30 days | 30d |
| 4.0–6.9 | Low | Any | Include in sprint | 90d |
| 0.1–3.9 | N/A | Any | Advisory/defer | No deadline |

### Triage Checklist

- [ ] **Identify**: Vulnerable package, version affected, CVE ID
- [ ] **Scope**: Which applications depend on this package?
- [ ] **Impact**: Is the vulnerable code path used in our app?
- [ ] **Exploitability**: Public exploit? Active exploitation?
- [ ] **Assess risk**: CVSS + exposure = residual risk
- [ ] **Decide**: Patch, accept, or mitigate
- [ ] **Execute**: Update dependency, test, deploy
- [ ] **Verify**: Confirm fix in production
- [ ] **Document**: Record decision and timeline

### False Positive Handling

**Questions to ask**:
1. Does our code actually execute the vulnerable path?
2. Is the vulnerability only in a context we don't use?
3. Is there a WAF/API Gateway that mitigates?
4. Is authentication required (blocking external exposure)?
5. Are there compensating controls?

**If false positive**:
```bash
# Document in suppression file with expiry
snyk ignore SNYK-JS-MOMENT-1026986 --until=2025-12-31 --reason="Only used for internal logging"

# Verify with code review
# Get security team sign-off
# Create reminder to re-assess on expiry date
```

---

## Supply Chain Attack Prevention

### Typosquatting Detection

**Common attacks**:
- `requets` instead of `requests`
- `django-rest-frameowrk` instead of `djangorestframework`
- `aws-cli-2` instead of `awscli`

**Prevention**:
```bash
# Verify exact package name before adding
npm search requests  # Check typos in results

# Pin exact versions
npm install requests@2.28.1 --save-exact

# Use lock file (package-lock.json, requirements.lock, Gemfile.lock)
# Enable lock file verification in CI

# Private package registry whitelist
# Only allow packages from verified registry
```

### Package Provenance Verification

**SLSA Levels** (Software Supply Chain Levels for Artifacts):

| Level | Requirements | Example |
|-------|-------------|---------|
| SLSA 0 | None | Random npm package |
| SLSA 1 | Version control + build system | Published from GitHub Actions |
| SLSA 2 | Provenance attestation | Signed, timestamped build metadata |
| SLSA 3 | Hermetic builds + access controls | Reproducible builds, restricted access |
| SLSA 4 | Hermetic + 2-person review | Requires 2 approvals for release |

**Verify artifact signature** (Node.js example):
```bash
# npm package signatures (npm 8.0+)
npm config set audit-level high

# Verify published package
npm view requests@2.28.1 --json | jq '.dist.integrity'

# For signed packages, verify signature
npm verify-store
```

**SLSA Provenance Attestation** (GitHub Actions):
```yaml
- uses: slsa-framework/slsa-github-generator/.github/workflows/builder_go_slsa3.yml@v1.9.0
  with:
    go-version: "1.20"
    provenance-filename: provenance.intoto.jsonl
```

---

## Dependency Update Automation

### Dependabot Configuration

**GitHub** (`.github/dependabot.yml`):
```yaml
version: 2
updates:
  # npm
  - package-ecosystem: npm
    directory: "/"
    schedule:
      interval: weekly
      day: monday
      time: "03:00"
    open-pull-requests-limit: 5
    reviewers:
      - security-team
    labels:
      - security
    commit-message:
      prefix: "chore(deps):"
    pull-request-branch-name:
      separator: "/"
  
  # Python
  - package-ecosystem: pip
    directory: "/"
    schedule:
      interval: weekly
    reviewers:
      - security-team
    groups:
      development:
        dependency-type: "development"
      production:
        dependency-type: "production"
  
  # GitHub Actions
  - package-ecosystem: github-actions
    directory: "/"
    schedule:
      interval: weekly
  
  # Dockerfile
  - package-ecosystem: docker
    directory: "/"
    schedule:
      interval: monthly
```

### Renovate Bot Configuration

**`renovate.json`**:
```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["config:base"],
  "schedule": ["before 3am on Monday"],
  "automerge": false,
  "reviewers": ["security-team"],
  "labels": ["dependencies", "security"],
  
  "groupName": "All dependencies",
  "groupSlug": "all",
  
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true,
      "automergeType": "pr"
    },
    {
      "matchDatasources": ["npm"],
      "matchUpdateTypes": ["major"],
      "labels": ["breaking-change"],
      "automerge": false
    },
    {
      "matchDatasources": ["docker"],
      "schedule": ["before 3am on Sunday"]
    }
  ]
}
```

---

## Full Dependency Scanning Pipeline (GitHub Actions)

```yaml
name: Dependency Security Scanning

on:
  push:
    branches: [main, develop]
    paths:
      - 'package.json'
      - 'requirements.txt'
      - 'Gemfile'
      - 'go.mod'
      - 'pom.xml'
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 2 * * 0'  # Weekly Sunday 2am

jobs:
  sbom-generation:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Generate SBOM with Syft
      uses: anchore/sbom-action@v0
      with:
        format: spdx-json
        output-file: sbom.spdx.json
    
    - name: Generate CycloneDX SBOM
      uses: anchore/sbom-action@v0
      with:
        format: cyclonedx
        output-file: sbom.xml
    
    - name: Upload SBOM artifacts
      uses: actions/upload-artifact@v3
      with:
        name: sbom
        path: sbom.*

  dependency-check:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run OWASP Dependency-Check
      uses: dependency-check/Dependency-Check_Action@main
      with:
        project: myapp
        path: '.'
        format: 'JSON'
        args: >
          --enableExperimental
          --fail-on-cvss 7.0

    - name: Upload Dependency-Check results
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'reports/dependency-check-report.sarif'

  npm-audit:
    runs-on: ubuntu-latest
    if: hashFiles('package.json') != ''
    
    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-node@v3
      with:
        node-version: '18'
    
    - name: npm audit
      run: npm audit --json > npm-audit.json || true
    
    - name: Check for critical/high
      run: |
        CRITICAL=$(jq '[.vulnerabilities[] | select(.severity=="critical" or .severity=="high")] | length' npm-audit.json)
        if [ $CRITICAL -gt 0 ]; then
          echo "Found $CRITICAL critical/high vulnerabilities"
          exit 1
        fi
    
    - name: Upload npm audit
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: npm-audit
        path: npm-audit.json

  snyk-test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    - uses: snyk/actions/setup@master
    
    - name: Snyk test
      env:
        SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      run: |
        snyk test --severity-threshold=high --json > snyk-report.json || true
    
    - name: Fail on high/critical
      run: |
        ISSUES=$(jq '[.runs[0].results[] | select(.level=="error" or .level=="warning")] | length' snyk-report.json)
        if [ $ISSUES -gt 0 ]; then
          echo "Found $ISSUES high/critical issues"
          exit 1
        fi
    
    - name: Upload Snyk results
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: snyk-results
        path: snyk-report.json

  license-compliance:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Check licenses
      run: |
        # Extract licenses from SBOM
        jq -r '.metadata.component.licenses[]?.license.name' sbom.spdx.json | sort -u > detected-licenses.txt
        
        # Check against policy
        python3 - <<'EOF'
        import json
        
        approved = {'MIT', 'Apache-2.0', 'BSD-2-Clause', 'BSD-3-Clause', 'ISC', 'MPL-2.0'}
        prohibited = {'SSPL'}
        
        with open('detected-licenses.txt') as f:
          licenses = set(line.strip() for line in f if line.strip())
        
        violations = licenses & prohibited
        unapproved = licenses - approved - prohibited
        
        if violations:
          print(f"PROHIBITED: {violations}")
          exit(1)
        if unapproved:
          print(f"UNAPPROVED (review): {unapproved}")

        EOF
    
    - name: Generate license report
      run: |
        jq '[.packages[] | {name: .name, version: .versionInfo, license: .licenses[0]?.license.name}]' \
          sbom.spdx.json > license-report.json
    
    - name: Upload license report
      uses: actions/upload-artifact@v3
      with:
        name: license-report
        path: license-report.json

  summary-report:
    runs-on: ubuntu-latest
    if: always()
    needs: [sbom-generation, dependency-check, npm-audit, snyk-test, license-compliance]
    
    steps:
    - name: Download all reports
      uses: actions/download-artifact@v3
    
    - name: Create summary
      run: |
        echo "## Dependency Security Summary" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "- SBOM generated (SPDX & CycloneDX)" >> $GITHUB_STEP_SUMMARY
        echo "- OWASP Dependency-Check: ✓" >> $GITHUB_STEP_SUMMARY
        echo "- npm audit: ✓" >> $GITHUB_STEP_SUMMARY
        echo "- Snyk: ✓" >> $GITHUB_STEP_SUMMARY
        echo "- License compliance: ✓" >> $GITHUB_STEP_SUMMARY
```

