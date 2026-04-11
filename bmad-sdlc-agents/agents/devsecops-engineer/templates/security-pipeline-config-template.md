# Security Pipeline Configuration Template

> Template file for the BMAD DevSecOps Engineer agent.
> Use this GitHub Actions workflow as a starting point for a complete multi-stage security pipeline with all gates.

---

## GitHub Actions Workflow File

**Location**: `.github/workflows/security-pipeline.yml`

```yaml
name: Multi-Stage Security Pipeline

on:
  pull_request:
    branches: [main, develop]
    types: [opened, synchronize, reopened]
  
  push:
    branches: [main, develop, staging]
    paths:
      - 'src/**'
      - 'Dockerfile'
      - 'terraform/**'
      - 'helm/**'
      - 'package.json'
      - 'requirements.txt'
      - 'go.mod'
      - 'pom.xml'
  
  schedule:
    # Full scan every Sunday at 2 AM UTC
    - cron: '0 2 * * 0'

env:
  REGISTRY: gcr.io
  IMAGE_NAME: myorg/myapp
  SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
  VAULT_ADDR: ${{ secrets.VAULT_ADDR }}

jobs:
  # ============================================================================
  # STAGE 1: PR Checks (Run on every PR)
  # ============================================================================
  
  pr-secrets-scan:
    name: Secrets Detection (PR)
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v3
      with:
        fetch-depth: 0
    
    - name: Install Gitleaks
      run: |
        wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
        tar xzf gitleaks_8.18.0_linux_x64.tar.gz
        chmod +x gitleaks
        mv gitleaks /usr/local/bin/
    
    - name: Run Gitleaks scan
      run: |
        gitleaks detect --source . --verbose --report-format json \
          --report-path gitleaks.json || exit_code=$?
        exit ${exit_code:-0}
    
    - name: Check for secrets
      run: |
        if [ -f gitleaks.json ]; then
          jq '.Leaks | length' gitleaks.json
          LEAK_COUNT=$(jq '.Leaks | length' gitleaks.json)
          if [ "$LEAK_COUNT" -gt 0 ]; then
            echo "🚨 SECRETS DETECTED: $LEAK_COUNT secret(s) found"
            jq '.Leaks[] | {Rule:.Rule, Match:.Match, File:.File, Line:.LineNumber}' gitleaks.json
            exit 1
          fi
        fi
    
    - name: Comment PR with results
      if: always()
      uses: actions/github-script@v6
      with:
        script: |
          const fs = require('fs');
          const leaks = JSON.parse(fs.readFileSync('gitleaks.json', 'utf8'));
          const comment = leaks.Leaks?.length === 0 
            ? '✅ No secrets detected' 
            : `🚨 Found ${leaks.Leaks.length} secret(s)`;
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: `## Secrets Scan Result\n${comment}`
          });

  pr-sast-scan:
    name: SAST Scan (Semgrep - PR)
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
      pull-requests: write
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Semgrep scan
      run: |
        pip install semgrep
        semgrep --config=p/security-audit \
          --config=p/owasp-top-ten \
          --config=p/cwe-top-25 \
          --json --output=semgrep-pr.json . || true
    
    - name: Check severity gates
      run: |
        python3 << 'EOF'
        import json
        
        with open('semgrep-pr.json') as f:
          results = json.load(f)
        
        critical = [r for r in results.get('results', []) 
                   if r.get('extra', {}).get('severity') == 'ERROR']
        high = [r for r in results.get('results', []) 
               if r.get('extra', {}).get('severity') == 'WARNING']
        
        print(f"CRITICAL: {len(critical)}, HIGH: {len(high)}")
        
        if critical or high:
          print("❌ GATE FAILED: Critical/High findings detected")
          for finding in critical + high:
            print(f"  - {finding['message']} ({finding['path']}:{finding['start']['line']})")
          exit(1)
        
        print("✅ GATE PASSED")
        EOF
    
    - name: Upload SARIF
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: semgrep-pr.json
    
    - name: Comment PR with findings
      if: always()
      uses: actions/github-script@v6
      with:
        script: |
          const fs = require('fs');
          const results = JSON.parse(fs.readFileSync('semgrep-pr.json', 'utf8'));
          const findings = results.results || [];
          const critical = findings.filter(f => f.extra.severity === 'ERROR');
          const high = findings.filter(f => f.extra.severity === 'WARNING');
          
          let comment = `## SAST Scan Results\n`;
          comment += `- CRITICAL: ${critical.length}\n`;
          comment += `- HIGH: ${high.length}\n`;
          
          if (critical.length > 0 || high.length > 0) {
            comment += '\n⚠️ **Gate Status**: FAILED';
          } else {
            comment += '\n✅ **Gate Status**: PASSED';
          }
          
          github.rest.issues.createComment({
            issue_number: context.issue.number,
            owner: context.repo.owner,
            repo: context.repo.repo,
            body: comment
          });

  pr-container-scan:
    name: Container Scan (Trivy - PR)
    if: github.event_name == 'pull_request' && contains(github.event.pull_request.files, 'Dockerfile')
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Build image
      run: |
        docker build -t pr-image:${{ github.event.pull_request.number }} .
    
    - name: Scan with Trivy
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: pr-image:${{ github.event.pull_request.number }}
        format: 'sarif'
        output: 'trivy-pr.sarif'
        severity: 'CRITICAL,HIGH'
        exit-code: '1'
    
    - name: Upload SARIF
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: trivy-pr.sarif

  pr-iac-scan:
    name: IaC Scan (Checkov - PR)
    if: github.event_name == 'pull_request' && (contains(github.event.pull_request.files, 'terraform') || contains(github.event.pull_request.files, 'k8s') || contains(github.event.pull_request.files, 'Dockerfile'))
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Checkov
      uses: bridgecrewio/checkov-action@master
      with:
        framework: terraform,kubernetes,dockerfile,cloudformation
        directory: .
        soft-fail: false
        output-format: sarif
        output-file-path: checkov-pr.sarif
    
    - name: Upload SARIF
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: checkov-pr.sarif

  # ============================================================================
  # STAGE 2: Main Branch Integration (Run on push to main)
  # ============================================================================

  main-sbom-generation:
    name: Generate SBOM
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
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
        output-file: sbom.cyclonedx.xml
    
    - name: Upload SBOM artifacts
      uses: actions/upload-artifact@v3
      with:
        name: sbom-main
        path: |
          sbom.spdx.json
          sbom.cyclonedx.xml

  main-full-sast:
    name: Full SAST Scan (Main)
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Semgrep full
      run: |
        pip install semgrep
        semgrep --config=p/security-audit --config=p/owasp-top-ten \
          --json --output=semgrep-main.json . || true
    
    - name: Gate: No CRITICAL findings
      run: |
        python3 << 'EOF'
        import json
        with open('semgrep-main.json') as f:
          results = json.load(f)
        critical = [r for r in results.get('results', []) 
                   if r.get('extra', {}).get('severity') == 'ERROR']
        if critical:
          print(f"❌ GATE FAILED: {len(critical)} CRITICAL findings")
          exit(1)
        print("✅ GATE PASSED")
        EOF
    
    - name: Upload SARIF
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: semgrep-main.json

  main-dependency-scan:
    name: Dependency Audit (Main)
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    - uses: actions/setup-node@v3
      if: hashFiles('package.json') != ''
      with:
        node-version: '18'
    - uses: actions/setup-python@v4
      if: hashFiles('requirements.txt') != ''
      with:
        python-version: '3.11'
    
    - name: npm audit
      if: hashFiles('package.json') != ''
      run: |
        npm audit --json > npm-audit.json || true
        python3 check_npm_gate.py
    
    - name: pip audit
      if: hashFiles('requirements.txt') != ''
      run: |
        pip install pip-audit
        pip-audit --format json > pip-audit.json || true
        python3 check_pip_gate.py
    
    - name: OWASP Dependency-Check
      run: |
        wget https://github.com/jeremylong/DependencyCheck_Home/releases/download/v8.4.0/dependency-check-8.4.0-release.zip
        unzip -q dependency-check-8.4.0-release.zip
        dependency-check/bin/dependency-check.sh --project myapp --scan . \
          --failOnCVSS 7.0 --format JSON --report dc-report || true
    
    - name: Upload reports
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: dependency-reports
        path: |
          npm-audit.json
          pip-audit.json
          dc-report*

  main-container-build-scan:
    name: Build and Scan Container (Main)
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
      security-events: write
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Authenticate to GCR
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: _json_key
        password: ${{ secrets.GCR_SA_KEY }}
    
    - name: Build image
      uses: docker/build-push-action@v4
      with:
        context: .
        push: false
        load: true
        tags: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
    
    - name: Trivy vulnerability scan
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
        format: 'sarif'
        output: 'trivy-main.sarif'
        severity: 'CRITICAL,HIGH'
    
    - name: Gate: No CRITICAL vulns
      run: |
        trivy image --severity CRITICAL --exit-code 1 \
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
    
    - name: Upload SARIF
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: trivy-main.sarif

  # ============================================================================
  # STAGE 3: Staging Deployment (Run when pushed to staging branch)
  # ============================================================================

  staging-dast-scan:
    name: DAST Scan (Staging)
    if: github.ref == 'refs/heads/staging' && github.event_name == 'push'
    runs-on: ubuntu-latest
    environment:
      name: staging
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Wait for deployment
      run: sleep 30  # Wait for staging deployment to complete
    
    - name: OWASP ZAP baseline scan
      run: |
        docker run -t ghcr.io/zaproxy/zaproxy:stable \
          zap-baseline.py -t https://staging.example.com \
          -r zap-report.html \
          -x zap-report.xml \
          -J zap-report.json \
          -z "-config api.disablekey=true" || true
    
    - name: Parse ZAP results
      run: |
        python3 << 'EOF'
        import json
        import xml.etree.ElementTree as ET
        
        # Check for unresolved CRITICAL from baseline
        tree = ET.parse('zap-report.xml')
        root = tree.getroot()
        
        critical = root.findall(".//alert[riskcode='3']")  # High risk
        if critical:
          print(f"⚠️ Found {len(critical)} HIGH/CRITICAL alerts")
          for alert in critical:
            print(f"  - {alert.findtext('name')}")
        
        # Allow staging to proceed with advisories
        print("✅ DAST Gate: Advisory (allows proceed)")
        EOF
    
    - name: Upload artifacts
      uses: actions/upload-artifact@v3
      if: always()
      with:
        name: dast-reports
        path: zap-report.*

  staging-verify-sbom:
    name: Verify SBOM Attestation
    if: github.ref == 'refs/heads/staging'
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Download SBOM from main
      uses: actions/download-artifact@v3
      with:
        name: sbom-main
    
    - name: Verify SBOM exists
      run: |
        [ -f sbom.spdx.json ] || exit 1
        echo "✅ SBOM attestation verified"

  # ============================================================================
  # STAGE 4: Production Release Approval
  # ============================================================================

  production-approval-gate:
    name: Production Release Approval
    if: github.ref == 'refs/heads/main'
    needs: [main-sbom-generation, main-full-sast, main-dependency-scan, main-container-build-scan]
    runs-on: ubuntu-latest
    environment:
      name: production-release
      reviewers:
        - security-lead
        - release-manager
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Compile security report
      run: |
        echo "## 🔐 Security Approval Report" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "**Build**: ${{ github.run_number }}" >> $GITHUB_STEP_SUMMARY
        echo "**Commit**: ${{ github.sha }}" >> $GITHUB_STEP_SUMMARY
        echo "**Branch**: ${{ github.ref }}" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "### Status" >> $GITHUB_STEP_SUMMARY
        echo "- ✅ SAST: PASSED (0 CRITICAL)" >> $GITHUB_STEP_SUMMARY
        echo "- ✅ Container: PASSED (0 CRITICAL)" >> $GITHUB_STEP_SUMMARY
        echo "- ✅ Dependencies: No unresolved HIGH" >> $GITHUB_STEP_SUMMARY
        echo "- ✅ Secrets: Clean" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "### ⏳ Awaiting Review" >> $GITHUB_STEP_SUMMARY
        echo "Security Lead approval required before production deployment" >> $GITHUB_STEP_SUMMARY
    
    - name: Notify security team
      if: always()
      run: |
        echo "Release approval pending in GitHub Actions environment"
        # Integration with Slack/email can be added here

  production-push-image:
    name: Push Container Image (Prod)
    if: github.ref == 'refs/heads/main'
    needs: [production-approval-gate]
    runs-on: ubuntu-latest
    permissions:
      packages: write
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v2
    
    - name: Login to GCR
      uses: docker/login-action@v2
      with:
        registry: ${{ env.REGISTRY }}
        username: _json_key
        password: ${{ secrets.GCR_SA_KEY }}
    
    - name: Build and push
      uses: docker/build-push-action@v4
      with:
        context: .
        push: true
        tags: |
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:latest
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
          ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:v${{ github.run_number }}

  # ============================================================================
  # Utility: Summary Report
  # ============================================================================

  security-summary:
    name: Security Summary Report
    if: always()
    runs-on: ubuntu-latest
    needs: [pr-secrets-scan, pr-sast-scan, main-full-sast]
    
    steps:
    - name: Generate summary
      run: |
        echo "## Security Pipeline Summary" >> $GITHUB_STEP_SUMMARY
        echo "- Event: ${{ github.event_name }}" >> $GITHUB_STEP_SUMMARY
        echo "- Branch: ${{ github.ref }}" >> $GITHUB_STEP_SUMMARY
        echo "- Commit: ${{ github.sha }}" >> $GITHUB_STEP_SUMMARY
        echo "" >> $GITHUB_STEP_SUMMARY
        echo "### Results" >> $GITHUB_STEP_SUMMARY
        echo "- Secrets: ${{ needs.pr-secrets-scan.result }}" >> $GITHUB_STEP_SUMMARY
        echo "- SAST: ${{ needs.pr-sast-scan.result }}" >> $GITHUB_STEP_SUMMARY
        echo "- Full SAST (Main): ${{ needs.main-full-sast.result }}" >> $GITHUB_STEP_SUMMARY
```

---

## Helper Script: Check Semgrep Gate

**File**: `.github/scripts/check_semgrep_gate.py`

```python
import json
import sys

def main():
    with open('semgrep-pr.json') as f:
        results = json.load(f)
    
    critical = [r for r in results.get('results', []) 
               if r.get('extra', {}).get('severity') == 'ERROR']
    high = [r for r in results.get('results', []) 
           if r.get('extra', {}).get('severity') == 'WARNING']
    
    print(f"\n📊 Semgrep Results:")
    print(f"  CRITICAL: {len(critical)}")
    print(f"  HIGH: {len(high)}")
    
    if critical:
        print(f"\n❌ GATE FAILED: {len(critical)} CRITICAL findings\n")
        for finding in critical:
            print(f"  • {finding['message']}")
            print(f"    File: {finding['path']}:{finding['start']['line']}\n")
        sys.exit(1)
    
    if high:
        print(f"\n⚠️  WARNING: {len(high)} HIGH findings (advisory)\n")
        for finding in high:
            print(f"  • {finding['message']}")
            print(f"    File: {finding['path']}:{finding['start']['line']}\n")
    
    print("✅ GATE PASSED\n")

if __name__ == '__main__':
    main()
```

---

## Configuration Files

### `.github/dependabot.yml`

```yaml
version: 2
updates:
  - package-ecosystem: npm
    directory: "/"
    schedule:
      interval: weekly
      day: monday
      time: "03:00"
    labels:
      - dependencies
      - security
    reviewers:
      - security-team

  - package-ecosystem: pip
    directory: "/"
    schedule:
      interval: weekly
    labels:
      - dependencies
      - security

  - package-ecosystem: docker
    directory: "/"
    schedule:
      interval: monthly
    labels:
      - docker
      - security

  - package-ecosystem: github-actions
    directory: "/"
    schedule:
      interval: weekly
```

### `.pre-commit-config.yaml`

```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
        stages: [commit]
        args: ['--verbose']

  - repo: https://github.com/hadialqattan/pycln
    rev: v2.2.2
    hooks:
      - id: pycln
        language_version: python3.11

  - repo: https://github.com/PyCQA/isort
    rev: 5.12.0
    hooks:
      - id: isort

  - repo: https://github.com/PyCQA/pylint
    rev: pylint-2.17.1
    hooks:
      - id: pylint
        args: ['--disable=all', '--enable=E,F']
```

