# Template: Security Test Checklist

Create in `docs/test-plans/security-test-checklist.md`:

```markdown
# Security Testing Checklist

## OWASP Top 10 (2021)

### A01:2021 – Broken Access Control
- [ ] User cannot access resources belonging to other users
- [ ] Role-based access enforced (user ≠ admin)
- [ ] API endpoints validate authorization headers
- [ ] User cannot escalate privileges
- [ ] API rate limiting prevents brute force attacks

### A02:2021 – Cryptographic Failures
- [ ] All sensitive data encrypted in transit (HTTPS)
- [ ] Passwords hashed with bcrypt/scrypt/Argon2
- [ ] API keys not logged or exposed in errors
- [ ] Database credentials rotated securely

### A03:2021 – Injection
- [ ] SQL injection tests: Parameterized queries used
- [ ] Command injection: No shell execution of user input
- [ ] Template injection: Input sanitized before rendering

### A04:2021 – Insecure Design
- [ ] Authentication enforced on all protected endpoints
- [ ] Default credentials removed
- [ ] Security headers set (HSTS, CSP, X-Frame-Options)

### A05:2021 – Security Misconfiguration
- [ ] Debug mode disabled in production
- [ ] Unnecessary services/ports closed
- [ ] Default error messages don't leak system info

### A06:2021 – Vulnerable Components
- [ ] Dependency scan: No known CVEs in production
- [ ] Third-party libraries kept up-to-date
- [ ] Supply chain: Artifacts from trusted registries

### A07:2021 – Authentication Failures
- [ ] Password policy: Complexity + expiry requirements
- [ ] Multi-factor authentication available
- [ ] Session timeout configured
- [ ] Failed login attempts logged

### A08:2021 – Software/Data Integrity Failures
- [ ] Code signed or verified before deployment
- [ ] CI/CD pipeline access controlled
- [ ] Artifact registry authenticated

### A09:2021 – Logging & Monitoring Failures
- [ ] Security events logged (auth, privilege changes)
- [ ] Logs tamper-evident (immutable or SIEM)
- [ ] Alerts configured for suspicious activity

### A10:2021 – SSRF
- [ ] User input not used to construct URLs to internal resources
- [ ] Outbound API calls validated against allowlist

## Compliance Requirements
- **PCI-DSS:** Payment card data encrypted, access logged
- **HIPAA:** Patient data encrypted, audit trail maintained
- **SOC 2:** Access controls, incident response procedures
- **GDPR:** Data deletion capability, consent tracking

## Test Execution
- Tool: [SAST/DAST tool, e.g., OWASP ZAP, Snyk]
- Schedule: [On every release, weekly scans, etc.]
- Owner: [Security team, QE, etc.]
```

