# IAM Design Document Template

> Template file for the BMAD InfoSec Architect agent.
> Use this template to design identity, authentication, and authorization strategies.

---

## Document Header

**Organization**: MyCompany  
**System**: Platform IAM  
**Version**: 1.0  
**Date**: 2026-04-11  
**Owner**: Alice Chen (Identity Architect)  
**Review Date**: 2026-10-11  

---

## Identity Provider Architecture

```
┌─────────────────────────────────────────────────┐
│            Identity Providers                   │
├─────────────────────────────────────────────────┤
│                                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────┐ │
│  │ Okta/Keycloak│  │ Active Dir.  │  │ AWS  │ │
│  │ (OIDC/SAML)  │  │ (LDAP)       │  │ IAM  │ │
│  └──────┬───────┘  └──────┬───────┘  └──┬───┘ │
└─────────┼───────────────────┼─────────────┼──────┘
          │                   │             │
      ┌───┴───┬───────────────┴─────────────┴──┐
      │       │                                 │
      ↓       ↓                                 ↓
  ┌─────────────────┐                   ┌─────────────┐
  │ Internal Apps   │                   │ AWS Services│
  │ ├─ Jira         │                   │ ├─ EC2      │
  │ ├─ Confluence   │                   │ ├─ S3       │
  │ ├─ GitLab       │                   │ └─ RDS      │
  │ └─ Slack        │                   └─────────────┘
  └─────────────────┘
```

---

## User Populations

| Population | Count | Authentication | MFA | Use Case |
|-----------|-------|-----------------|-----|----------|
| **Internal Staff** | 150 | Okta OIDC | Required | Employees, contractors |
| **Customers** | 10,000 | OAuth 2.0 | Optional | SaaS users |
| **Service Accounts** | 50 | Vault AppRole | N/A | Microservices, CI/CD |
| **CI/CD Pipeline** | 20 | GitHub Actions OIDC | N/A | Automated deployments |
| **Third-Party Integrations** | 10 | OAuth 2.0 + API keys | N/A | Partner APIs |

---

## Role Definitions

| Role | Responsibilities | Permissions | MFA Required | Max Session | Assigned To |
|------|------------------|-----------|--------------|-------------|------------|
| **Admin** | Full system management | All actions | YES (FIDO2) | 1 hour | 3 people |
| **Security Lead** | Audit, policy, incident | View all logs, manage keys | YES (TOTP) | 4 hours | 5 people |
| **DevOps Engineer** | Infrastructure, deployment | Deploy, manage servers | YES (TOTP) | 8 hours | 10 people |
| **Developer** | Write code, view logs | Deploy to staging, view logs | Optional | 8 hours | 40 people |
| **Product Manager** | Roadmap, customer issues | Read-only dashboards | Optional | 24 hours | 15 people |
| **Viewer** | Stakeholders, executives | Read-only reports | Optional | 24 hours | 30 people |

---

## RBAC Permission Matrix

| Action | Admin | SecLead | DevOps | Dev | PM | Viewer |
|--------|-------|---------|--------|-----|----|----- |
| **Create user** | ✓ | — | — | — | — | — |
| **Delete user** | ✓ | ✓ | — | — | — | — |
| **Deploy to prod** | ✓ | ✓ | ✓ | — | — | — |
| **Deploy to staging** | ✓ | ✓ | ✓ | ✓ | — | — |
| **View logs (prod)** | ✓ | ✓ | ✓ | ✓ | — | — |
| **View logs (staging)** | ✓ | ✓ | ✓ | ✓ | ✓ | — |
| **Access vault secrets** | ✓ | — | ✓ | ✓ | — | — |
| **Rotate vault keys** | ✓ | ✓ | — | — | — | — |
| **View audit logs** | ✓ | ✓ | — | — | — | — |
| **Read dashboards** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |

---

## ABAC Policies (OPA Rego)

```rego
# Users can access resources in their region
allow {
  input.resource.region == input.user.region
  input.action == "read"
}

# Only admins can delete
allow {
  input.user.role == "admin"
  input.action == "delete"
}

# Managers can access their team's dashboards
allow {
  input.user.team == data.dashboards[input.resource.id].owner
  input.action == "read"
}
```

---

## MFA Policy

| User Type | Required Authenticator | Exemptions | Challenge Frequency |
|-----------|------------------------|-----------|-------------------|
| **Admin** | FIDO2 Hardware Key | NONE | Every session |
| **Security** | FIDO2 or TOTP | On-call (after login OK) | Every session |
| **DevOps** | TOTP (Authenticator app) | CI/CD scripts (API key instead) | Every session |
| **Developer** | Optional (encouraged) | — | N/A |
| **Customer** | Optional | — | N/A |

---

## Service Account Inventory

| Service | Account | Permissions | Rotation | Last Reviewed |
|---------|---------|-----------|----------|----------------|
| **Payment Service** | payment-svc | payments:read, payments:write | 90 days | 2026-04-01 |
| **Data Pipeline** | data-pipeline | s3:read, athena:query | 180 days | 2026-03-15 |
| **Monitoring** | monitoring-svc | logs:read, metrics:read | Annual | 2026-02-01 |
| **Backup** | backup-svc | backup:create, backup:restore | 90 days | 2026-04-08 |
| **CI/CD** | github-actions | deploy:staging, deploy:prod | 90 days | 2026-04-01 |

---

## Token Lifetime Policy

| Token Type | Lifetime | Refresh | Use Case | Rotation |
|-----------|----------|---------|----------|----------|
| **Access Token** | 15 minutes | Yes | API requests | Refresh token |
| **Refresh Token** | 7 days | Yes | Obtain new access token | Rotate on use |
| **Session Cookie** | 1 hour | Yes | Web UI session | Extend on activity |
| **API Key** | No expiry | Manual | Service accounts | Annual rotation |
| **SAML Assertion** | 5 minutes | No | SAML auth | N/A |

---

## Access Review Schedule

| Frequency | Population | Owner | Process |
|-----------|-----------|-------|---------|
| **Quarterly** | Admin, Security | CISO | 1:1 review with manager |
| **Quarterly** | DevOps, Developers | VP Eng | Team lead approval |
| **Semi-annual** | Contractors | HR | Contract review |
| **Annual** | All roles | HR | Comprehensive re-cert |
| **On-demand** | Terminated employees | HR | Immediate revocation |

---

## Okta / Keycloak Configuration

```yaml
# Groups (for RBAC)
groups:
  - name: admin
    members: [alice, bob]
    applications: [all]
  
  - name: developers
    members: [charlie, diana, eve, frank, grace, henry, iris]
    applications: [jira, gitlab, slack, confluence]

# Application integrations
applications:
  - name: jira
    sso_type: SAML
    groups:
      admin:
        roles: [Administrator]
      developers:
        roles: [Developer]
  
  - name: aws
    sso_type: SAML
    groups:
      admin:
        roles: [AdministratorAccess]
      devops:
        roles: [PowerUserAccess]

# MFA policy
mfa_policy:
  global_required: false
  admin_required: true
  admin_authenticators:
    - fido2
  developer_optional:
    - totp
    - fido2
```

---

## Access Review Checklist

**For Each User**:
- [ ] Is user still employed/active?
- [ ] Does user still need these roles?
- [ ] Any role changes since last review?
- [ ] MFA enrollment status?
- [ ] Last access: Within past 30 days?
- [ ] Any policy violations?

**Manager Attestation**:
- [ ] I confirm this user's access is appropriate
- [ ] Manager signature + date

---

## Approvals

- **Prepared By**: Alice Chen (Identity Architect)
- **Reviewed By**: Bob Martinez (Security Lead)
- **Approved By**: Carol Singh (CISO)
- **Date**: 2026-04-11
- **Review Date**: 2026-10-11

