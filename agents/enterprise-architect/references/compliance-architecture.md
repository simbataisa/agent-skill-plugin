# Compliance & Regulatory Architecture

> Reference file for the BMAD Enterprise Architect agent.
> Read this file when designing compliance & regulatory architecture for a project.


### Applicability
- **SOC2 Type II**: Customer requirement for SaaS businesses; covers security, availability, processing integrity
- **GDPR**: EU user data must be handled per EU regulations
- **CCPA**: California user data has privacy rights
- **PCI-DSS**: Not applicable (we don't handle credit cards directly; Stripe does)

### Data Classification & Access Control

#### PII (Personally Identifiable Information)
**Data**: Email, phone, address, name, order history
**Access**:
- User Service: Read/write (owns data)
- Order Service: Read (orders belong to users)
- Support Team: Read-only (customer support needs to see orders)
- Analytics Team: None (data is anonymized before analytics)

**Enforcement**:
- Database-level: Role-based access control (RBAC) in PostgreSQL
- Application-level: AuthZ checks (user can only view their own data)
- Audit logging: Every access to PII is logged with user, timestamp, action

#### Sensitive (Financial, Health, Legal)
**Data**: Credit card last 4 digits, medical records (if applicable), legal agreements
**Access**:
- Limited to necessary teams
- Encrypted in database
- Logs are redacted (never appear in plaintext)
- Deletion triggers compliance check (user can request "right to be forgotten")

#### Internal-Only
**Data**: API keys, employee records, cost analysis
**Access**: Employees only, restricted to function (no cross-functional visibility)

### Audit Logging (SOC2)

**What is logged**:
1. **Authentication events**: Login, logout, token issuance, auth failures
2. **Authorization events**: Permission grants, access denials
3. **Data access**: PII reads/writes (not every request, but PII-specific ones)
4. **Sensitive operations**: Password changes, API key rotations, config changes
5. **Administrative actions**: Database backups, user provisioning, role changes
6. **Security events**: Failed encryption validation, suspicious patterns

**Audit Log Schema**:
```json
{
  "timestamp": "2026-02-26T10:30:00Z",
  "event_type": "pii_access",
  "actor": {
    "user_id": "user-123",
    "role": "support_agent",
    "ip_address": "203.0.113.42"
  },
  "action": "read",
  "resource": {
    "type": "user_profile",
    "id": "user-456",
    "data_classification": "pii"
  },
  "result": "success",
  "context": {
    "reason": "Customer support ticket #789",
    "session_id": "sess-xyz"
  }
}
```

**Storage & Retention**:
- Audit logs stored in append-only S3 bucket (no deletion allowed)
- Retention: 7 years (compliance requirement)
- Access: Restricted to compliance officer, auditors (via signed URLs)

### Data Residency (GDPR)
- **EU User Data**: Must remain in EU
  - User Service + Order Service + supporting DBs: Deployed in eu-west-1 (Ireland)
  - Read-only replicas: Can be in us-east-1 for analytics (GDPR allows if not identifiable)

- **US User Data**: Flexible
  - Deployed in us-east-1
  - Replicas for HA in us-west-2

- **Encryption Keys**: Always in customer's region
  - US data encrypted with us-east-1 KMS key
  - EU data encrypted with eu-west-1 KMS key
  - No cross-region key access

### User Rights (GDPR "Right to Be Forgotten")
- **User requests deletion**: Compliance team gets request
- **Deletion process**:
  1. Legal review (10 business days)
  2. Mark user record as deleted (pseudonymization, not hard delete)
  3. Remove from active systems (User Service, CRM)
  4. Keep in audit logs (immutable, required for compliance)
  5. Confirm deletion to user
- **Edge case**: If user has active orders (disputes), delay deletion until orders closed
```

### 6. Disaster Recovery & Business Continuity
Design recovery procedures for catastrophic failures.

**What you produce:**
- **Recovery objectives** — RTO (Recovery Time Objective: how fast to recover?), RPO (Recovery Point Objective: acceptable data loss?)
- **Backup strategy** — Frequency, geographic distribution, tested restores
- **Failover procedures** — How to switch to backup systems (automated or manual?)
- **Runbooks** — Step-by-step recovery instructions for on-call engineers
- **Testing cadence** — How often to rehearse disaster scenarios (quarterly minimum)

**Why:** When disaster strikes (regional outage, data corruption, ransomware), you need a plan. Plans without testing fail spectacularly.

**Example output:**

```markdown
