# Security Architecture Patterns Reference

> Reference file for the BMAD InfoSec Architect agent.
> Read this file when designing defense-in-depth strategies, implementing Zero Trust principles, and selecting appropriate security patterns.

---

## Zero Trust Architecture (ZTA)

**Core Principle**: Never trust, always verify. All access (internal or external) requires authentication and authorization.

### ZTA Pillars

1. **Identity**: Every user and device has a verified identity
2. **Device**: Only trusted/compliant devices can connect
3. **Network**: Assume network is hostile (mTLS, encryption)
4. **Application**: App-level auth/authz, not network-based
5. **Data**: Encrypt, classify, monitor access

### Implementation Layers

```
┌──────────────────────────────────────────────────────┐
│ Application Layer (API, mTLS enforcement)            │
├──────────────────────────────────────────────────────┤
│ Service Mesh (Istio, Linkerd: mTLS, authz)         │
├──────────────────────────────────────────────────────┤
│ Network Layer (Microsegmentation, firewalls)        │
├──────────────────────────────────────────────────────┤
│ Device Layer (MDM, endpoint detection)              │
├──────────────────────────────────────────────────────┤
│ Identity Layer (OIDC, MFA, PKI)                     │
└──────────────────────────────────────────────────────┘
```

### ZTA Policy Decision Point

```python
# Pseudocode for policy engine
def can_access(user, resource, action, context):
    # 1. Verify identity
    if not verify_mfa_status(user):
        return deny("MFA required")
    
    # 2. Verify device
    if not device_compliant(user.device_id):
        return deny("Device non-compliant")
    
    # 3. Verify access rights
    if not has_permission(user.role, resource, action):
        return deny("Insufficient permissions")
    
    # 4. Context-based additional checks
    if anomalous_access_pattern(user, context):
        return challenge("Additional verification needed")
    
    return allow("All checks passed")
```

---

## Defence-in-Depth Architecture

Layered approach: multiple security controls at each layer.

### Layer 1: Perimeter

**Controls**:
- Firewall (stateful, blocks unauthorized traffic)
- DDoS protection (rate limiting, IP reputation)
- WAF (blocks malicious HTTP requests)

**Technology**: AWS Security Groups, WAF, CloudFlare, Cloudflare

### Layer 2: Network

**Controls**:
- Intrusion detection/prevention (IDS/IPS)
- VPN/VPC isolation
- Network segmentation (subnets, VLANs)
- Encrypted tunnels (IPSec, TLS)

**Technology**: VPC, Security Groups, NACLs, VPN, Service Mesh (mTLS)

### Layer 3: Host/Container

**Controls**:
- Antivirus/anti-malware
- Host-based firewall (iptables, Windows Defender)
- File integrity monitoring
- Vulnerability scanning

**Technology**: Falco, SELinux, AppArmor, Trivy, Syft

### Layer 4: Application

**Controls**:
- Input validation
- Output encoding
- Authentication & authorization
- Rate limiting
- Security logging

**Technology**: WAF, API gateway, OWASP Top 10 controls

### Layer 5: Data

**Controls**:
- Encryption at rest (AES-256-GCM)
- Encryption in transit (TLS 1.3)
- Access controls (RBAC, ABAC)
- Data classification
- PII masking

**Technology**: KMS, TDE, encrypted databases, field-level encryption

### Example: SQL Injection Defense-in-Depth

```
1. Perimeter: WAF rule detects SQL keywords in requests → block
2. Network: TLS encryption prevents MITM injection
3. Application: Input validation (whitelist allowed characters)
4. Application: ORM/Prepared statements (parameterization)
5. Data: Least-privilege DB user (cannot DROP TABLE)
6. Data: Row-level security policies
7. Logging: Query logging for anomaly detection

Result: Attacker needs to defeat ALL layers to succeed
```

---

## Micro-Segmentation (Zero Trust Network)

Breaking network into small zones, requiring authentication at every zone boundary.

### Traditional Network Model

```
Internet → Firewall → DMZ → Internal Network
                               ├─ All servers trusted once inside
                               └─ Flat network, no internal firewalls
                               
Attack scenario: Attacker compromises one server → access all servers
```

### Micro-Segmentation Model

```
Internet → FW → API Gateway → Service A
                            (mTLS)
                               ↓
                             Service B
                            (mTLS, authz)
                               ↓
                             Database
                            (encryption)
                            
Each boundary requires:
- Authentication (verified identity)
- Authorization (proper permissions)
- Encryption (TLS/mTLS)
- Monitoring (audit logs)
```

### Kubernetes NetworkPolicy Example

```yaml
# Deny all traffic by default
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress

---

# Allow specific service-to-service traffic
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-api-to-db
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api-server
    ports:
    - protocol: TCP
      port: 5432
```

---

## API Security Pattern

### API Gateway Architecture

```
┌──────────────┐
│   Client     │
└──────┬───────┘
       │ HTTP
       ↓
┌──────────────────────────────┐
│   API Gateway                │
│ ├─ TLS termination           │
│ ├─ Request validation        │
│ ├─ Rate limiting             │
│ ├─ Authentication check      │
│ ├─ Token validation          │
│ └─ Request routing           │
└──────────┬────────────────────┘
           │ mTLS (internal)
    ┌──────┴──────┐
    │             │
    ↓             ↓
┌─────────┐  ┌─────────┐
│Service A│  │Service B│
└─────────┘  └─────────┘
```

### mTLS for Service-to-Service

```
Client Cert ──→ TLS Handshake ←── Server Cert
(issued by     (verify each other's  (issued by
CA cert)        identity)             CA cert)
    │                ↓                   │
    └────────────────────────────────────┘
             Encrypted channel
```

**Certificate Issuance**: Vault PKI or cert-manager (Kubernetes)

```bash
# Vault: Issue certificate for service-a
vault write pki_int/issue/service-a \
  common_name=service-a.internal.example.com \
  alt_names="service-a,service-a.default.svc.cluster.local"

# Returns: cert.pem, key.pem, ca-chain.pem
```

### JWT Token Validation

```
┌──────────────────────────────────────┐
│ Client sends JWT in Authorization   │
│ Bearer token in request header       │
└──────────────┬───────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│ API Gateway verifies JWT:            │
│ 1. Signature valid (check against    │
│    issuer's public key)              │
│ 2. Not expired (check 'exp' claim)   │
│ 3. Correct audience (check 'aud')    │
│ 4. Required claims present           │
└──────────────┬───────────────────────┘
               │
        ┌──────┴──────┐
        ↓             ↓
   VALID         INVALID
  (route)       (reject 401)
```

---

## Secure by Default Pattern

**Principle**: Default configuration is secure; developers must opt-in to less-secure options.

### Examples

**Bad** (insecure default):
```python
# Default: no authentication required
@app.route('/api/users')
def get_users():
    return User.query.all()
```

**Good** (secure default):
```python
# Default: authentication required
@app.route('/api/users')
@require_auth(roles=['admin'])
def get_users():
    return User.query.all()
```

### Infrastructure as Secure by Default

```hcl
# Bad: Default open S3 bucket
resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
  # Missing: acl, encryption, versioning, logging
}

# Good: Defaults to private, encrypted, logged
resource "aws_s3_bucket" "data" {
  bucket = "my-data-bucket"
  tags   = { Name = "secure-bucket" }
}

resource "aws_s3_bucket_acl" "private" {
  bucket = aws_s3_bucket.data.id
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.data.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "enable" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Enabled"
  }
}
```

---

## Secret Zero Problem

**Challenge**: How do you securely initialize a system when you don't yet have any credentials?

### Bootstrapping Trust for First Credential

**Option 1: Out-of-Band Channel**
```
1. Admin creates first root token via console
2. Root token never stored/logged
3. Root token used only to create service accounts
4. Service accounts get their own credentials (less privileged)
```

**Option 2: Cloud Metadata Service (AWS)**
```
1. EC2 instance has IAM role (assigned by infrastructure)
2. Instance retrieves temporary credentials from metadata service
3. Uses credentials to access Vault / Secrets Manager
4. Application never needs permanent credentials
```

**Option 3: Kubernetes ServiceAccount Token**
```
1. Pod gets ServiceAccount token (mounted by kubelet)
2. Token used to authenticate to Vault Kubernetes auth
3. Vault issues temporary credentials
4. Credentials rotated on lease expiry
```

---

## Cryptographic Agility

**Principle**: Design systems so cryptographic algorithms can be swapped without re-architecture.

### Bad (Algorithm Hardcoded)

```python
import hashlib

def hash_password(password):
    # MD5 hardcoded, cannot change
    return hashlib.md5(password.encode()).hexdigest()
```

**Problem**: If MD5 breaks, entire system must be redesigned.

### Good (Algorithm Configurable)

```python
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2

def hash_password(password, algorithm=None):
    if algorithm is None:
        algorithm = hashes.SHA256()  # Current best practice
    
    kdf = PBKDF2(
        algorithm=algorithm,
        length=32,
        salt=b'16-byte-salt',
        iterations=100_000,
    )
    return kdf.derive(password.encode())

# Can switch to SHA512 or Argon2 later
hash_password(pwd, algorithm=hashes.SHA512())
```

### Cryptographic Algorithm Lifecycle

```
1. New algorithm introduced (SHA-256, AES-256)
2. Become standard (years of validation)
3. Deprecation announced (e.g., MD5, DES)
4. Graceful transition period (support both old + new)
5. Sunset date (old algorithm removed)

Timeline: 10–20 years between introduction and removal
```

---

## Security Logging Architecture

**What to Log**:
- Authentication events (login, logout, MFA success/fail)
- Authorization decisions (access denied, privilege escalation)
- Data access (who accessed what, when)
- Configuration changes (who changed what, from what to what)
- Security events (alerts, detections, incidents)

**What NOT to Log**:
- Passwords, API keys, tokens (never)
- Full payment card numbers (PCI-DSS violation)
- Private keys, encryption keys
- Biometric data

### Security Logging Workflow

```
┌─────────────────────────────────────┐
│ Application logs security event     │
│ (auth, authz, data access, config)  │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│ Log aggregation (ELK, Splunk)       │
│ - Parse logs into structured format │
│ - Normalize field names             │
│ - Enrich with context (IP lookup)   │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│ SIEM (Splunk, Datadog)              │
│ - Correlation (link related events) │
│ - Alerting (rule-based detection)   │
│ - Dashboard (visibility)            │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│ Archive (S3, immutable storage)     │
│ - Long-term retention (7+ years)    │
│ - Compliance (audit requirements)   │
│ - Incident investigation            │
└─────────────────────────────────────┘
```

### Log Integrity Patterns

**Append-Only Logs**: Once written, cannot be modified
- Technology: AWS CloudTrail (immutable by design)
- Technology: Splunk (immutable indexes)
- Technology: Custom: Git commits (signed), blockchain

**Signed Logs**: Each log entry cryptographically signed
```
Log Entry: "2026-04-11 10:30 User alice accessed order#123"
Signature: "HMAC-SHA256(log_entry + secret_key)"
Verify:    Recompute signature, compare to stored signature
```

**Log Encryption**: Logs encrypted at rest + in transit
- Encryption: AES-256-GCM (encryption) + HMAC-SHA256 (integrity)
- Access: Decryption key stored separately (Vault)

---

## PKI (Public Key Infrastructure) Design

### Internal CA for Certificates

```
┌──────────────────────────────┐
│ Root CA (offline)            │
│ - Self-signed               │
│ - Kept in vault             │
│ - Never used to sign certs  │
│ - Lifespan: 20+ years       │
└──────────────┬───────────────┘
               │ (create)
               ↓
┌──────────────────────────────┐
│ Intermediate CA (online)     │
│ - Signed by Root CA         │
│ - Used to sign user/server  │
│ - Lifespan: 5–10 years      │
└──────────────┬───────────────┘
               │ (create)
       ┌───────┴────────┐
       ↓                ↓
┌─────────────┐  ┌─────────────┐
│ User Cert   │  │ Server Cert │
│ (1 year)    │  │ (1 year)    │
└─────────────┘  └─────────────┘
```

### mTLS Certificate Lifecycle

```
1. Service registers with Vault
2. Vault generates CSR (certificate signing request)
3. CSR signed by Intermediate CA → certificate + key
4. Certificate stored (1-year TTL)
5. Service renews certificate before expiry (90 days before)
6. Automated renewal via cert-manager (Kubernetes)
7. Service restarts to use new certificate

Result: Zero-touch certificate rotation
```

### Certificate Transparency (CT)

**Purpose**: Public log of all issued certificates (prevents mis-issuance).

**How**:
1. CA signs certificate
2. CA submits to CT logs
3. CT log returns SCT (Signed Certificate Timestamp)
4. Certificate must include SCT(s) to be valid
5. Browsers validate SCT(s) during TLS handshake

**Benefit**: Detect certificate mis-issuance within hours (not months)

