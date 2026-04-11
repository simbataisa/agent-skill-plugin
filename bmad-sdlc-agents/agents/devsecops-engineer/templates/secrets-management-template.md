# Secrets Management Implementation Template

> Template file for the BMAD DevSecOps Engineer agent.
> Use this template to document and implement a complete secrets management strategy for a project.

---

## Project Overview

**Project Name**: MyApp Payment Service  
**Environment**: Production (AWS region us-east-1)  
**Teams**: Platform, Backend, DevOps  
**Document Owner**: Alice Chen (DevSecOps)  
**Last Updated**: 2026-04-11  
**Review Cadence**: Quarterly (or event-triggered)  

---

## Secrets Inventory

| Secret Name | Type | Current Location | Rotation Period | Who Can Access | Renewal Owner | Risk Level |
|-------------|------|-----------------|-----------------|----------------|---------------|-----------|
| `db-prod-password` | Database credential | AWS Secrets Manager | 90 days | Backend pods, Lambda | DBA + DevOps | HIGH |
| `stripe-api-key-prod` | API key (third-party) | HashiCorp Vault | 180 days | Payment service | Payment Lead | CRITICAL |
| `jwt-signing-key` | Cryptographic key | Vault + K8s Sealed Secret | 365 days | Auth service, API gateway | Auth Lead | HIGH |
| `github-token` | VCS token | GitHub Actions secrets | 90 days | CI/CD pipeline | DevOps | CRITICAL |
| `tls-cert-prod` | X.509 certificate | cert-manager (Kubernetes) | 90 days | Ingress controller | DevOps | HIGH |
| `slack-webhook-alerts` | Integration webhook | Vault | 180 days | Monitoring system | DevOps | MEDIUM |
| `datadog-api-key` | Monitoring API key | Vault | 180 days | Logging + APM agents | DevOps | MEDIUM |
| `mailgun-api-key` | Email service API | Vault | 365 days | Email microservice | Backend | MEDIUM |
| `aws-access-key-ci` | AWS credentials | GitHub Actions secrets | 90 days | CI/CD pipeline | DevOps | CRITICAL |
| `postgres-replication-password` | Database credential | AWS Secrets Manager | 90 days | RDS read replicas | DBA | HIGH |
| `elasticsearch-password` | Cluster credential | Vault | 90 days | Search service | Platform | HIGH |
| `redis-password` | Cache credential | Vault | 90 days | Cache clients | Platform | MEDIUM |
| `firebase-service-account` | JSON service account | Vault | 90 days | Notification service | Backend | HIGH |

**Total Secrets**: 13  
**Average Rotation**: 127 days  
**Critical-Risk Secrets**: 3  
**High-Risk Secrets**: 5  

---

## Chosen Secrets Backend

### Decision: HashiCorp Vault (Primary) + AWS Secrets Manager (Secondary)

**Rationale**:
- **Vault**: Cross-platform, multi-environment, supports dynamic credentials, audit logging, auto-renewal
- **AWS Secrets Manager**: AWS-native, tight integration with RDS, Lambdas, and EC2 instances
- **Hybrid approach**: Vault for critical/cross-environment; Secrets Manager for AWS-only services

### Vault Architecture

**Development**:
```
Vault Dev Mode (single node, no persistence)
├─ /secret/dev/* (KV v2 - unencrypted, TTL 1h)
├─ /database/dev/* (dynamic DB credentials)
└─ Used for local development only
```

**Production**:
```
Vault HA (3+ nodes, backend: Raft)
├─ /secret/prod/* (KV v2 - encrypted with Shamir keys)
├─ /database/prod/* (dynamic DB credentials, auto-renewal)
├─ /pki/prod/* (certificate authority)
├─ /auth/kubernetes/* (K8s pod auth)
└─ /auth/approle/* (service-to-service auth)

Encryption: Shamir secret sharing (3 of 5 key fragments)
Audit log: CloudWatch Logs (immutable, 10-year retention)
Backup: Weekly encrypted snapshots → S3 (cross-region replication)
```

### AWS Secrets Manager Architecture

**RDS Rotation**:
```
1. Secret created: db-prod-password
2. Lambda rotation function triggered on schedule
3. Lambda generates new password
4. Lambda updates RDS user with new password
5. Rotation tested via temporary credentials
6. Old secret marked for deletion (7-day grace period)
```

**Secrets Manager Policy**:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/production-pod-role"
      },
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-prod-*"
    }
  ]
}
```

---

## Secret Injection Pattern

### Chosen: CSI Driver (Secrets Store) + Init Container

**Rationale**:
- CSI driver: Pod-native, no sidecar overhead, works with immutable filesystem
- Init container: Ensures secrets available before app starts

### Implementation

**1. Install Secrets Store CSI Driver**:
```bash
helm repo add secrets-store-csi-driver https://raw.githubusercontent.com/kubernetes-sigs/secrets-store-csi-driver/main/charts
helm install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system

# Install Vault provider
helm repo add hashicorp https://helm.releases.hashicorp.com
helm install vault-secrets-operator hashicorp/vault-secrets-operator \
  --namespace vault
```

**2. Create SecretProviderClass**:
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-database-secrets
  namespace: production
spec:
  provider: vault
  parameters:
    vaultAddress: "https://vault.internal.example.com:8200"
    vaultAuthPath: "auth/kubernetes"
    vaultRole: "payment-service"
    secretPath: "secret/data/prod/database"
    objects: |
      - objectName: "db-host"
        secretKey: "host"
        secretPath: "secret/data/prod/database/postgres"
      - objectName: "db-user"
        secretKey: "username"
        secretPath: "secret/data/prod/database/postgres"
      - objectName: "db-password"
        secretKey: "password"
        secretPath: "secret/data/prod/database/postgres"
```

**3. Update Deployment**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: payment-service
  namespace: production
spec:
  replicas: 3
  template:
    spec:
      serviceAccountName: payment-service
      securityContext:
        runAsNonRoot: true
        runAsUser: 65534
      
      # Init container: no longer needed with CSI
      containers:
      - name: app
        image: myapp:v2.1.0
        env:
        - name: DB_HOST
          value: /mnt/secrets/db-host
        - name: DB_USER
          value: /mnt/secrets/db-user
        - name: DB_PASSWORD
          value: /mnt/secrets/db-password
        
        volumeMounts:
        - name: vault-secrets
          mountPath: /mnt/secrets
          readOnly: true
        
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          capabilities:
            drop:
            - ALL
        
        resources:
          limits:
            cpu: 500m
            memory: 512Mi
      
      volumes:
      - name: vault-secrets
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: vault-database-secrets
```

**4. Vault Kubernetes Auth Setup**:
```bash
# Enable K8s auth
vault auth enable kubernetes

# Configure with K8s API
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token

# Create role for payment-service
vault write auth/kubernetes/role/payment-service \
  bound_service_account_names=payment-service \
  bound_service_account_namespaces=production \
  policies=payment-service-policy \
  ttl=24h
```

---

## Rotation Policy by Secret Type

### Database Passwords

**Schedule**: Every 90 days (quarterly)  
**Automation**: AWS Secrets Manager Lambda function  
**Process**:
1. Generate random 32-character password (uppercase, lowercase, digits, special chars)
2. Update RDS user password
3. Test connection with new password
4. Update secret in Secrets Manager
5. Wait 7 days, then revoke old password
6. Log rotation in CloudTrail

**Owner**: DBA + DevOps  
**Verification**: Run connectivity test query

### API Keys (Third-Party)

**Schedule**: Every 180 days (semi-annual)  
**Automation**: Manual with reminder ticket  
**Process**:
1. Generate new API key in Stripe / SendGrid / etc. dashboard
2. Test new key in staging environment
3. Update Vault secret
4. Deploy to production (rolling restart)
5. Wait 7 days, then revoke old key in provider dashboard
6. Create JIRA ticket "API Key Rotation Complete"

**Owner**: Service owner (Payment Lead for Stripe, etc.)  
**Verification**: Test API calls in production logs

### Cryptographic Keys (Signing/Encryption)

**Schedule**: Every 365 days (annual) OR on key compromise  
**Automation**: Manual rotation with code deployment  
**Process**:
1. Generate new key in Vault PKI or locally
2. Deploy code that accepts both old + new key (dual-key period, 30 days)
3. Update secret in Vault
4. Monitor: verify all new signatures use new key
5. After 30 days, retire old key (keep in history for 2 years)

**Owner**: Security Lead + Auth Lead  
**Verification**: Audit logs show 100% new key usage

### TLS Certificates

**Schedule**: Automatic renewal (90 days before expiry)  
**Automation**: cert-manager (Kubernetes) + Let's Encrypt  
**Process**:
1. cert-manager detects cert expiry approaching
2. ACME challenge issued and completed
3. New cert signed
4. Ingress updated automatically
5. Old cert archived

**Owner**: DevOps (fully automated)  
**Verification**: Certificate monitor alerts on upcoming expiry

---

## Emergency Rotation Runbook

**Trigger**: Suspected compromise, unauthorized access, key leaked in code

### Phase 1: Immediate Containment (0–30 minutes)

**Step 1: Declare Incident**
```bash
# Create JIRA ticket
jira issue create --template "Security Incident" \
  --summary "CRITICAL: Secret Compromise - [SECRET_NAME]" \
  --priority CRITICAL

# Notify on-call security lead
pagerduty trigger --incident-key secret-compromise-$(date +%s)
```

**Step 2: Revoke Compromised Secret**
```bash
# AWS Secrets Manager
aws secretsmanager put-secret-value \
  --secret-id db-prod-password \
  --secret-string '{"status":"REVOKED"}'

# Vault
vault kv delete secret/prod/database/postgres
vault write auth/approle/role/myapp/secret-id generate

# GitHub (if token leaked)
gh secret delete SECRET_NAME -R myorg/myapp
```

**Step 3: Prevent Access with Compromised Secret**
```bash
# Revoke database user
# PSQL: ALTER USER app_user NOLOGIN;

# Revoke API key in provider (Stripe, etc.)
# stripe api_keys[...].revoke

# Invalidate all active sessions/tokens
# DELETE FROM sessions WHERE updated < now();
```

### Phase 2: Generate Replacement (30–60 minutes)

**Step 4: Create New Secret**
```bash
# Database: Generate new password
python3 -c "import secrets, string; print(''.join(secrets.choice(string.ascii_letters + string.digits + '!@#$%^&*') for _ in range(32)))"

# Store in AWS Secrets Manager
aws secretsmanager create-secret \
  --name db-prod-password-NEW \
  --secret-string '{"username":"app_user","password":"NewPassword123!@#"}'

# Update Vault
vault kv put secret/prod/database/postgres \
  host="db.internal.example.com" \
  username="app_user" \
  password="NewPassword123!@#"
```

**Step 5: Deploy to All Services**
```bash
# Update all services that use the secret
# Option A: Rolling restart
kubectl rollout restart deployment/payment-service -n production

# Option B: Manual update if services read from Vault agent
# (automatic via sidecar renewal)

# Verify deployment
kubectl logs -n production deployment/payment-service | grep "DB connected"
```

**Step 6: Verify Access**
```bash
# Test database connectivity
psql "postgresql://app_user:NewPassword123!@#@db.internal.example.com/myapp" \
  -c "SELECT NOW()"

# Test API key
curl -H "Authorization: Bearer $(vault kv get -field=password secret/prod/stripe)" \
  https://api.stripe.com/v1/account
```

### Phase 3: Investigation & Documentation (1–4 hours)

**Step 7: Investigate Blast Radius**
```bash
# Check access logs during compromise window
aws logs filter-log-events \
  --log-group-name /aws/rds/instance/prod-postgres/postgresql \
  --start-time $(date -d '30 minutes ago' +%s)000 \
  --filter-pattern "authentication failed"

# Check GitHub audit logs
gh api repos/myorg/myapp/security/audit-logs \
  --jq '.[] | select(.created_at > "2026-04-11T10:00:00Z")'
```

**Step 8: Document Root Cause**
```markdown
# Emergency Rotation Report

**Secret**: db-prod-password  
**Detected**: 2026-04-11 10:15 UTC  
**Contained**: 2026-04-11 10:45 UTC (30 min)  
**New Secret Deployed**: 2026-04-11 11:00 UTC  

## Root Cause
- Developer accidentally committed secret in `.env` file to GitHub
- File was in `.gitignore` but global `.gitignore` was outdated

## Compromise Window
- Secret accessible from 2026-04-10 15:00 to 2026-04-11 10:45 (20 hours)
- Git log inspection shows no unauthorized commits using credential

## Actions Taken
1. Revoked database user (confirmed no new connections)
2. Scanned CloudTrail for API calls with old credentials (NONE found)
3. Updated `.gitignore` globally
4. Added pre-commit Gitleaks hook to prevent future leaks
5. Notified security team
```

**Step 9: Update Incident JIRA**
```
Status: CLOSED
Resolution: FIXED
Root Cause: Code committed secret (process failure)
Preventive Measures: Pre-commit hook, secret scanning in CI
Follow-up: Team training on secrets management best practices
```

---

## Audit & Access Logging Configuration

### Vault Audit Logging

```bash
# Enable file audit
vault audit enable file file_path=/var/log/vault-audit.log

# Enable syslog audit (recommended for prod)
vault audit enable syslog tag="vault"

# Check audit logs
vault audit list
vault audit enable file file_path=/vault/logs/audit.log format=json

# Inspect logs
tail -f /var/log/vault-audit.log | jq '.'
```

**Vault Audit Log Entry Example**:
```json
{
  "type": "response",
  "auth": {
    "client_token": "s.xxx",
    "accessor": "kubernetes.xxx",
    "display_name": "kubernetes-payment-service",
    "policies": ["payment-service-policy"],
    "metadata": {
      "role": "payment-service",
      "service_account_name": "payment-service",
      "service_account_namespace": "production"
    }
  },
  "request": {
    "id": "xxx",
    "operation": "READ",
    "path": "secret/data/prod/database",
    "data": {},
    "remote_address": "10.0.1.42"
  },
  "response": {
    "auth": null,
    "data": {
      "data": {
        "host": "db.internal.example.com",
        "username": "***"
      },
      "metadata": {
        "created_time": "2026-04-01T10:00:00Z",
        "custom_metadata": null
      }
    }
  },
  "timestamp": "2026-04-11T10:30:00Z"
}
```

### AWS Secrets Manager Audit Logging

```bash
# Enable CloudTrail for Secrets Manager
aws cloudtrail create-trail --name secrets-manager-trail \
  --s3-bucket-name cloudtrail-logs

# Events captured:
# - CreateSecret, UpdateSecret, DeleteSecret
# - GetSecretValue (who accessed which secret, when)
# - RotateSecret, PutSecretValue

# Query audit logs
aws logs filter-log-events \
  --log-group-name /aws/secretsmanager/access-logs \
  --filter-pattern "GetSecretValue" \
  --start-time $(date -d '7 days ago' +%s)000
```

### Application Logging

**Do NOT log secret values**:
```python
# Bad
logger.info(f"Connecting with password: {password}")

# Good
logger.info("Database connection established")
logger.debug(f"Connecting to host: {os.environ.get('DB_HOST')}")
# (password omitted)
```

---

## Compliance Requirements

### GDPR (Art. 32 Technical Measures)
- ✅ Encryption at rest (AES-256, KMS)
- ✅ Encryption in transit (TLS 1.3)
- ✅ Access controls (RBAC, authentication)
- ✅ Audit logging (immutable, 3-year retention)
- ✅ Incident response plan (documented above)

### SOC2 CC6 (Logical Access)
- ✅ User authentication (Kubernetes RBAC, Vault OIDC)
- ✅ Access rights management (least privilege policies)
- ✅ Periodic access reviews (quarterly)
- ✅ Segregation of duties (separate approvers)
- ✅ Removal of access (immediate on termination)

### PCI-DSS 3.4 (Encryption of Cardholder Data)
- ✅ Secrets never written to logs
- ✅ Secrets stored in approved KMS/Vault
- ✅ Secrets transmitted via encrypted channels
- ✅ Access restricted to authorized personnel only
- ✅ Regular key rotation (90 days for API keys)

### HIPAA Technical Safeguard
- ✅ Encryption & decryption (AES-256-GCM)
- ✅ Access controls (audit trail, role-based)
- ✅ Audit controls (CloudTrail, Vault audit)
- ✅ Integrity controls (signed JWTs, MACs)

---

## Quarterly Review Checklist

- [ ] Verify all secrets in inventory still needed
- [ ] Check rotation schedules for upcoming expiry
- [ ] Review access logs for unauthorized attempts
- [ ] Test emergency rotation runbook
- [ ] Update team on new secrets or changes
- [ ] Audit pre-commit hooks, gitleaks config
- [ ] Review and update this document
- [ ] Sign-off by Security Lead and Platform Owner

**Last Review**: 2026-04-11 (Alice Chen, Bob Martinez)  
**Next Review**: 2026-07-11

