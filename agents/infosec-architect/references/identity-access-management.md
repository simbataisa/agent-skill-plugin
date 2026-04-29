# Identity and Access Management (IAM) Reference

> Reference file for the BMAD InfoSec Architect agent.
> Read this file when designing authentication, authorization, identity federation, and privilege access management strategies.

---

## Identity Lifecycle

### Provisioning (Onboarding)

```
1. New employee joins
   ↓
2. HR creates account in directory (AD/LDAP)
   ↓
3. Automated provisioning:
   - Create email account
   - Create git access
   - Add to group (engineers, finance, etc.)
   ↓
4. Manager approves initial access
   ↓
5. Identity stored with attributes:
   - Name, email, department, manager, cost center
   - Groups, roles, clearances
   ↓
6. Access to systems granted based on role
```

### Active (Maintenance)

- Annual access review (verify still need current access)
- Manager re-certification (confirm report access is appropriate)
- Group membership updates (team changes)
- MFA enrollment + enforcement

### Deprovisioning (Offboarding)

```
1. Employee notifies they're leaving
   ↓
2. Exit date: disable account in directory
   ↓
3. Revoke access:
   - Email (disable login)
   - VPN/SSH (revoke keys)
   - AWS IAM (delete access keys)
   - GitHub (remove from org)
   - Third-party SaaS
   ↓
4. Data: transfer ownership, archive files
   ↓
5. Verify: confirm access truly revoked
   ↓
6. Retain: archive identity record for 7 years (audit)
```

---

## Authentication Methods

### Password Policy (If Still Using Passwords)

**Modern password guidance** (NIST SP 800-63B):
- Minimum length: 12 characters (not 8)
- No complexity requirements (uppercase, digits, special) — users choose weak passwords
- No rotation requirements (promotes reuse)
- DO check against breached password database (HaveIBeenPwned)
- DO enforce MFA instead of strong password requirements

**Bad password policy**:
```
- Minimum 8 characters
- Must contain: uppercase, lowercase, digit, special char
- Must change every 90 days
Result: Users write passwords on sticky notes, reuse across systems
```

**Good password policy**:
```
- Minimum 12 characters
- Check against breach database
- No rotation unless suspected compromise
- Enforce MFA (TOTP or FIDO2)
Result: Strong passphrases, defense in depth
```

### MFA (Multi-Factor Authentication)

**TOTP** (Time-based One-Time Password)
- Example: Google Authenticator, Authy
- Pros: Works offline, not reliant on phone number
- Cons: Recovery codes required if phone is lost
- Lifespan: 30-second windows

**FIDO2** / WebAuthn (Hardware Keys)
- Example: YubiKey, Google Titan, platform keys (Windows Hello, Face ID)
- Pros: Strongest (resistant to phishing, MITM)
- Cons: User must carry key, replacement if lost
- Used for: High-risk accounts (admin, security team)

**SMS 2FA** (Not Recommended)
- Vulnerable to SIM swapping, phone number hijacking
- NIST discourages for sensitive systems
- Acceptable for low-risk consumer accounts only

**Push Notifications**
- Example: Microsoft Authenticator, Duo
- Pros: User-friendly, can see what you're approving
- Cons: Approval fatigue (user clicks without checking)

### Passwordless Authentication

**OAuth 2.0 with Social Login**
```
1. User: "Sign up with Google"
2. Redirect to Google login
3. User authenticates to Google (MFA if enrolled)
4. Google redirects to app with authorization code
5. App exchanges code for access token (backend)
6. App creates user account, user is logged in
Result: No password stored in app
```

**OIDC** (OpenID Connect, built on OAuth 2.0)
```
Adds: ID token with user identity information (claims)
OAuth 2.0 only provides authorization (what you can access)
OIDC adds authentication (who you are)
```

---

## OAuth 2.0 Flows

### Authorization Code + PKCE (Web/Mobile)

**Safest flow for browser-based and mobile apps**

```
1. User visits app, clicks "Login"
   ↓
2. App generates:
   - code_verifier (random string)
   - code_challenge = base64url(SHA256(code_verifier))
   ↓
3. Redirect to OAuth provider:
   GET /oauth/authorize?
     client_id=app123
     redirect_uri=https://app.example.com/callback
     code_challenge=xyz
     code_challenge_method=S256
   ↓
4. User authenticates, approves scopes (email, profile)
   ↓
5. Provider redirects to app:
   redirect_uri?code=auth_code_xyz
   ↓
6. App exchanges code (backend):
   POST /oauth/token
     client_id=app123
     client_secret=secret123  (backend only!)
     code=auth_code_xyz
     code_verifier=original_random_string
   ↓
7. Provider validates code_verifier against code_challenge
   ↓
8. Returns: access_token, refresh_token, id_token
   ↓
9. App stores token, user is logged in
```

**Why PKCE?** Without it, an attacker on same network (public WiFi) can:
1. Intercept authorization code
2. Exchange for token (no need for client_secret)
Result: Account hijacking

### Client Credentials (Service-to-Service)

```
Service A needs to access Service B

1. Service A has client_id + client_secret
2. POST to /oauth/token:
   client_id=service-a
   client_secret=secret123
   grant_type=client_credentials
   scope=api:write
   ↓
3. OAuth provider validates credentials
4. Returns: access_token (short-lived, 1 hour)
5. Service A uses token to call Service B API
6. Service B validates token signature
7. Grant access if token is valid + not expired

No user involved, pure service-to-service authentication
```

### Device Code (IoT/CLI)

```
Device (no browser) needs to authenticate

1. Device requests device code:
   POST /oauth/device
   ↓
2. OAuth provider returns:
   - device_code (long, for device)
   - user_code (short, for user to type)
   - verification_uri (https://example.com/device)
   ↓
3. Device displays:
   "Go to https://example.com/device, enter code: ABC123"
   ↓
4. User opens https://example.com/device on phone/laptop
5. User enters code ABC123, authenticates
   ↓
6. Device polls /oauth/token with device_code
7. Once user approves, OAuth provider returns token
8. Device is authenticated

Timeline: 5–10 minutes (user must actively approve)
```

---

## RBAC (Role-Based Access Control)

**Principle**: Users are assigned roles, roles have permissions.

### Design Process

**1. Identify Roles**
```
Role: Admin
- Permissions: Create, read, update, delete (CRUD) all resources
- Users: 2 people (security team lead + CTO)

Role: Developer
- Permissions: CRUD code, read logs, deploy to staging
- Users: 15 engineers

Role: Viewer
- Permissions: Read-only access to dashboards
- Users: 100+ (product managers, executives)
```

**2. Define Permissions**
```
Permission: order:read
- Grants: Read order details, list orders

Permission: order:write
- Grants: Create, update order metadata

Permission: order:delete
- Grants: Delete order (requires approval)

Permission: secret:read
- Grants: Access secrets in Vault

Permission: secret:admin
- Grants: Create, rotate, delete secrets, view audit logs
```

**3. Create Role-Permission Mapping**
```
┌────────────────┬────────────┬────────────┐
│ Role           │ Permission │ Resource   │
├────────────────┼────────────┼────────────┤
│ Admin          │ secret:*   │ secret/*   │
│ Developer      │ order:read │ order/*    │
│ Developer      │ order:write│ order/*    │
│ Viewer         │ order:read │ order/*    │
│ PaymentTeam    │ payment:*  │ payment/*  │
└────────────────┴────────────┴────────────┘
```

### Role Hierarchy

```
┌─────────────┐
│ Super Admin │
└──────┬──────┘
       │ (can do everything)
       ↓
┌─────────────────┐
│ Service Owner   │
└──────┬──────────┘
       │ (can manage their service)
       ├──────────────────┐
       ↓                  ↓
┌────────────┐   ┌──────────────┐
│ Developer  │   │ DevOps Lead  │
└────────────┘   └──────────────┘
```

### Anti-Pattern: Role Explosion

**Problem**: Create too many roles (one per team, one per feature)
```
Wrong:
├─ FinanceTeamAdmin
├─ MarketingTeamAdmin
├─ ProductTeamDeveloper
├─ ProductTeamDevOps
├─ ProductTeamDataAnalyst
... (100+ roles)
```

**Solution**: Use hierarchical roles
```
Right:
├─ Admin (manages all)
├─ TeamLead (manages team)
├─ Developer (writes code)
├─ DataAnalyst (reads data)
├─ DevOps (deploys infrastructure)
```

---

## ABAC (Attribute-Based Access Control)

**Principle**: Grant access based on attributes of user, resource, and context.

### Example: Row-Level Security with ABAC

```
Policy: User can read orders they created OR orders in their region

Policy Engine (OPA Rego):
├─ Input: 
│  ├─ user: {id: alice, department: finance, region: us-east}
│  ├─ resource: order_id=123
│  └─ action: read
├─ Query Database:
│  └─ order.created_by == user.id OR order.region == user.region?
└─ Decision: ALLOW or DENY
```

### OPA Policy Example

```rego
# Allow users to read orders from their region
allow {
  input.action == "read"
  order := data.orders[input.order_id]
  order.region == input.user.region
}

# Allow users to read their own orders
allow {
  input.action == "read"
  order := data.orders[input.order_id]
  order.created_by == input.user.id
}

# Allow admins to read anything
allow {
  input.user.role == "admin"
  input.action == "read"
}
```

---

## Session Management

### Token Lifetime Recommendations

| Token Type | Sensitivity Level | Lifetime | Refresh Policy |
|-----------|------------------|----------|-----------------|
| Access Token | High | 15 minutes | Refresh token renewal |
| Refresh Token | Critical | 7 days | Rotate on each use |
| Session Cookie | Medium | 1 hour | Auto-extend on activity |
| API Key | Critical | No expiry | Rotate annually |
| WebAuthn | High | 30 days | Extend on use |

### Refresh Token Rotation

```
1. User logs in with password
2. Receive: access_token (15 min TTL), refresh_token (7 day TTL)
3. Access_token expires → use refresh_token to get new access_token
4. Refresh returns:
   - New access_token (15 min)
   - New refresh_token (7 day)  ← rotated
   - Invalidate old refresh_token
5. Prevents token replay attacks

If refresh_token is stolen:
- Attacker can request new access_token
- But each use rotates token
- User's legitimate refresh triggers compromise detection
- All tokens revoked
```

### Silent Renew (Web)

```javascript
// Before access token expires, fetch new one in background
const refreshAccessToken = async () => {
  const response = await fetch('/api/refresh', {
    method: 'POST',
    credentials: 'include',  // Send cookies
    headers: { 'Content-Type': 'application/json' }
  });
  
  if (response.ok) {
    // New token issued, user never sees logout
    const { accessToken } = await response.json();
    localStorage.setItem('accessToken', accessToken);
  } else {
    // Refresh failed, redirect to login
    window.location.href = '/login';
  }
};

// Set up timer to refresh 5 minutes before expiry
setInterval(refreshAccessToken, 15 * 60 * 1000);  // Every 15 min
```

---

## Privileged Access Management (PAM)

### Just-In-Time (JIT) Access

```
Admin needs to access production database

1. Admin requests access:
   jit access request --resource db-prod --duration 2h
   ↓
2. Justification required:
   --reason "Emergency production incident investigation"
   ↓
3. PAM system checks:
   - Is user authorized to request?
   - Is business context valid?
   - Does manager need to approve?
   ↓
4. If approved:
   - Generate temporary credentials (valid 2h)
   - Deliver via encrypted channel
   ↓
5. Access is logged (WHO, WHAT, WHEN, WHY)
6. Credentials auto-revoke after 2h
   
Result: Admin can access only when needed, for limited time
```

### Break-Glass (Emergency Access)

```
Scenario: Production database down, regular admin unavailable

1. On-call engineer invokes break-glass
   break-glass activate --resource db-prod --reason "DB unreachable"
   ↓
2. Requires:
   - Approval from 2 security team members (email link)
   - Approval must arrive within 5 minutes
   ↓
3. Once approved:
   - Temporary admin credentials issued
   - Access logged and audited
   ↓
4. After incident:
   - Access revoked
   - Full incident review required
   - Password changed (compromised credential assumed)
   
Purpose: Allow access during true emergency, with oversight
```

### Privileged Session Recording

```
┌─────────────────────────────┐
│ Admin connects to prod DB   │
└────────────┬────────────────┘
             │
             ↓
┌─────────────────────────────┐
│ Session multiplexer (proxy) │
│ - Captures all commands     │
│ - Records to immutable log  │
│ - Alerts on suspicious cmds │
└────────────┬────────────────┘
             │
             ↓
┌─────────────────────────────┐
│ Production Database         │
└─────────────────────────────┘

Session Log:
12:34:56 admin@prod> select * from users;
12:35:01 admin@prod> update users set salary = 999999;
↑ ALERT: Unusual update detected, escalate to security

Result: Full audit trail of privileged actions
```

---

## Identity Federation

### LDAP/Active Directory

```
Organization runs on Windows + Microsoft services

LDAP Directory (central store):
├─ User: alice@example.com (password hash)
├─ User: bob@example.com
├─ Group: Engineers
└─ Group: Finance

Federated Applications:
├─ Outlook (uses LDAP to authenticate)
├─ SharePoint (uses LDAP for access)
└─ Custom app (LDAP bind)

Change password once → updated everywhere
Remove user from directory → access revoked everywhere
```

### OIDC/SAML Federation

```
Application wants to support multiple identity providers

OIDC Discovery:
1. App stores provider list
2. User selects "Login with Google"
3. App queries Google's .well-known/openid-configuration
4. Gets signing keys, token endpoint, user info endpoint
5. Continues OAuth flow (see OAuth section above)

SAML:
1. User: "Login with corporate"
2. Redirect to corporate SAML IdP
3. IdP authenticates user (LDAP, AD, MFA)
4. IdP returns SAML assertion (signed XML)
5. App validates signature (uses IdP public cert)
6. Extract user info from assertion
7. Create session in app

Enterprise: Okta, AzureAD, Ping Identity handle federation
```

---

## Keycloak Configuration Example

```yaml
# Kubernetes manifests for Keycloak deployment
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: keycloak
        image: quay.io/keycloak/keycloak:latest
        ports:
        - containerPort: 8080
        env:
        - name: KEYCLOAK_ADMIN
          valueFrom:
            secretKeyRef:
              name: keycloak
              key: admin-user
        - name: KC_DB
          value: postgres
        - name: KC_DB_URL
          valueFrom:
            secretKeyRef:
              name: keycloak
              key: db-url

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: keycloak-realm
data:
  myapp-realm.json: |
    {
      "realm": "myapp-realm",
      "enabled": true,
      "clients": [
        {
          "clientId": "myapp-web",
          "enabled": true,
          "redirectUris": ["https://app.example.com/*"],
          "protocolMappers": [
            {
              "name": "user-role-mapper",
              "protocolMapper": "oidc-usermodel-roles-mapper",
              "protocol": "openid-connect"
            }
          ]
        }
      ],
      "userFederationProviders": [
        {
          "displayName": "LDAP",
          "providerName": "ldap",
          "config": {
            "connectionUrl": "ldap://ad.example.com:389",
            "usersDn": "ou=users,dc=example,dc=com"
          }
        }
      ]
    }
```

