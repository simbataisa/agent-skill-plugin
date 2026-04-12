---
description: Run a comprehensive security scan (SAST, dependency audit, secrets detection, IaC scan). Produces a consolidated report.
argument-hint: "[scope: 'full' | 'sast' | 'deps' | 'secrets' | 'iac' | 'container']"
---

Run comprehensive security scans across SAST, dependencies, secrets, IaC, and container images.

## Steps

1. Parse $ARGUMENTS to determine scan scope. If empty, default to 'full'.

2. Read `.bmad/tech-stack.md` to determine language stack, frameworks, and container strategy.

3. Read `../../agents/devsecops-engineer/references/sast-dast-tools.md` for tool recommendations by language.

4. For scope 'full' or 'sast':
   - Detect language(s) in the project (Python, Go, Java, JavaScript, etc.)
   - Run appropriate SAST tool:
     - **Go**: `govulncheck ./...`
     - **Python**: `pip install bandit && bandit -r .`
     - **JavaScript/TypeScript**: `npm audit` or `yarn audit`
     - **Java**: `mvn dependency-check:check`
     - **General**: `semgrep scan --config=auto .`
   - Capture output showing vulnerable code patterns, severity, and remediation

5. For scope 'full' or 'deps':
   - Run dependency audit:
     - `npm audit` (Node.js)
     - `pip audit` (Python)
     - `govulncheck ./...` (Go)
     - `mvn dependency-check:check` (Java)
     - Gem Check (Ruby)
   - Parse results: list vulnerable packages, fix versions, severity

6. For scope 'full' or 'secrets':
   - Run: `gitleaks detect --source . --no-color`
   - Detect hardcoded credentials, API keys, tokens in code and git history

7. For scope 'full' or 'iac':
   - If Terraform/Kubernetes files exist:
   - Run: `checkov -d . --framework terraform,kubernetes,helm`
   - Detect infrastructure misconfigurations, policy violations

8. For scope 'full' or 'container':
   - If Dockerfile exists, build image tag: `docker build -t [image] .`
   - Run: `trivy image [image]`
   - Scan for vulnerable base OS packages

9. Parse all output and classify findings:
   - **Critical**: immediate risk, must fix before release
   - **High**: significant risk, should fix before release
   - **Medium**: moderate risk, plan remediation
   - **Low**: minor risk, monitor

10. Fill the security scan report template with: Scan Summary, Findings by Category (SAST/Deps/Secrets/IaC/Container), Severity Distribution, Remediation Plan.

11. Save to `docs/security/sast-dast-report.md`.

12. Confirm: "Security scan completed → `docs/security/sast-dast-report.md`. [C] critical, [H] high findings."
