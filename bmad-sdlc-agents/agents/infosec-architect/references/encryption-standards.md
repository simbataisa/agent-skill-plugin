# Encryption Standards Reference

> Reference file for the BMAD InfoSec Architect agent.
> Read this file when designing encryption strategies, selecting cryptographic algorithms, and planning cryptographic transitions.

---

## TLS Configuration

### Minimum TLS Version

**Requirement**: TLS 1.2 minimum (TLS 1.3 preferred)

**Why?**
- TLS 1.0, 1.1: Deprecated, known attacks (BEAST, POODLE)
- TLS 1.2: Industry standard, widely supported
- TLS 1.3: Latest, faster, removes weak options

**Configuration** (nginx):
```nginx
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
```

**Configuration** (Go):
```go
&tls.Config{
  MinVersion: tls.VersionTLS12,
  MaxVersion: tls.VersionTLS13,
  CipherSuites: []uint16{
    tls.TLS_AES_256_GCM_SHA384,
    tls.TLS_CHACHA20_POLY1305_SHA256,
  },
}
```

### Cipher Suite Selection

**Strong Ciphers** (use these):
- `TLS_AES_256_GCM_SHA384` (TLS 1.3, preferred)
- `TLS_CHACHA20_POLY1305_SHA256` (TLS 1.3, mobile-friendly)
- `ECDHE-RSA-AES256-GCM-SHA384` (TLS 1.2)
- `ECDHE-ECDSA-AES256-GCM-SHA384` (TLS 1.2)

**Disabled Ciphers** (never use):
- `RC4` (broken cipher, fast on paper but cryptographically weak)
- `DES`, `3DES` (too short keys, brute-forceable)
- `MD5` (hash broken)
- `SHA1` (hash deprecated for signatures)
- `NULL` (no encryption)
- `EXPORT` (deliberately weakened)
- `aNULL`, `eNULL`, `aDSS` (no authentication)

### Security Headers

```
Strict-Transport-Security: max-age=31536000; includeSubDomains; preload
├─ Enforces HTTPS for all subdomains
├─ max-age: 1 year
└─ preload: Submit to HSTS preload list

X-Frame-Options: DENY
└─ Prevent clickjacking (embedding in frames)

X-Content-Type-Options: nosniff
└─ Prevent MIME sniffing (browser must respect Content-Type)

Content-Security-Policy: default-src 'self'; script-src 'self'
└─ Prevent XSS (only allow scripts from same origin)

X-XSS-Protection: 1; mode=block
└─ Legacy header (deprecated), rely on CSP instead
```

### Certificate Pinning

```
Scenario: Ensure client always uses YOUR certificate (prevent MITM)

1. Pin certificate public key (not entire cert)
2. Store pin in mobile app
3. On each TLS handshake:
   - Validate cert signature (standard TLS)
   - Extract cert public key
   - Compare against pinned key
   - If mismatch: reject connection

Pins stored: Allows certificate rotation without app update
Backup pins: 2–3 pins stored (current + next)

Risk: If all pins wrong, app cannot connect (DoS)
Mitigation: Include backup pin, pin public key (survives cert rotation)
```

---

## At-Rest Encryption

### AES-256-GCM

**Standard**: NIST-approved symmetric encryption

**GCM** (Galois/Counter Mode):
- **AEAD** (Authenticated Encryption with Associated Data)
- Encrypts AND authenticates (prevents tampering)
- Nonce-based (IV required, 12 bytes typical)
- High performance

**Example** (Python):
```python
from cryptography.hazmat.primitives.ciphers.aead import AESGCM
import os

# Key: 32 bytes (256 bits)
key = os.urandom(32)

# Plaintext
plaintext = b"secret message"

# Nonce: 12 bytes (recommended for GCM)
nonce = os.urandom(12)

# Associated authenticated data (optional)
aad = b"header_not_encrypted"

# Encrypt
cipher = AESGCM(key)
ciphertext = cipher.encrypt(nonce, plaintext, aad)

# Decrypt
recovered = cipher.decrypt(nonce, ciphertext, aad)
assert recovered == plaintext
```

### Envelope Encryption

**Problem**: Encrypt terabytes of data with KMS → slow, expensive

**Solution**: Use KMS only for encrypting keys

```
┌─────────────────────────────────────────┐
│ Master Key (in KMS, highly protected)   │
│ - Cached locally (limited time)         │
│ - Rotated annually                      │
└────────────────┬────────────────────────┘
                 │
                 ↓ (wraps/unwraps)
┌─────────────────────────────────────────┐
│ Data Encryption Key (DEK)               │
│ - Per-record or per-user                │
│ - Random, different each time           │
└────────────────┬────────────────────────┘
                 │
                 ↓ (encrypts)
┌─────────────────────────────────────────┐
│ Plaintext Data                          │
│ - Millions of records                   │
│ - Encrypted locally (fast)              │
└─────────────────────────────────────────┘

Result: KMS called only once per DEK generation
```

### Database Encryption (TDE)

**Transparent Data Encryption** (built-in):

**PostgreSQL**:
```sql
-- pgcrypto extension for column-level encryption
CREATE EXTENSION pgcrypto;

-- Encrypt sensitive column
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255),
  ssn TEXT ENCRYPTED WITH (
    algorithm = 'aes-256-cbc'
  ),
  encrypted_ssn BYTEA
);

-- Insert encrypted
INSERT INTO users (id, name, encrypted_ssn)
VALUES (1, 'Alice', pgp_sym_encrypt('123-45-6789', 'key_123'));

-- Query decrypted
SELECT id, name, pgp_sym_decrypt(encrypted_ssn, 'key_123')
FROM users
WHERE id = 1;
```

**AWS RDS Encryption**:
```bash
# Enable encryption at launch (cannot enable after)
aws rds create-db-instance \
  --db-instance-identifier prod-postgres \
  --engine postgres \
  --storage-encrypted \  # Enable TDE
  --kms-key-id arn:aws:kms:region:account:key/id
```

---

## Hashing

### Password Hashing: bcrypt, Argon2id

**bcrypt**:
```python
import bcrypt

password = "my_secure_password_123"

# Hash with automatic salt generation
hashed = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))
# Example: b'$2b$12$...'

# Verify
if bcrypt.checkpw(password.encode(), hashed):
    print("Password correct")
```

**Argon2id** (newer, stronger):
```python
from argon2 import PasswordHasher

hasher = PasswordHasher()

# Hash
hashed = hasher.hash("my_secure_password_123")
# Example: $argon2id$v=19$m=102400,t=2,p=8$...

# Verify
try:
    hasher.verify(hashed, "my_secure_password_123")
    print("Password correct")
except VerifyMismatchError:
    print("Wrong password")
```

**Never Use**:
- MD5: Cryptographically broken
- SHA1: Deprecated, fast (bad for passwords)
- SHA256 unsalted: Vulnerable to rainbow tables

### Data Integrity: HMAC-SHA256

```python
import hmac
import hashlib

key = b"secret_key"
data = b"important_message"

# Compute HMAC
signature = hmac.new(key, data, hashlib.sha256).digest()

# Verify (later)
expected = hmac.new(key, data, hashlib.sha256).digest()
if hmac.compare_digest(signature, expected):
    print("Data integrity verified")
```

---

## Asymmetric Cryptography

### RSA

**Key Size Requirements**:
- 2048-bit minimum (acceptable for next 5 years)
- 3072-bit preferred
- 4096-bit for long-term archival (20+ years)

**Never**:
- RSA-1024 (breakable today)

**Example** (Python):
```python
from cryptography.hazmat.primitives.asymmetric import rsa
from cryptography.hazmat.primitives import serialization

# Generate RSA key pair
private_key = rsa.generate_private_key(
    public_exponent=65537,
    key_size=2048,
)
public_key = private_key.public_key()

# Serialize for storage
private_pem = private_key.private_bytes(
    encoding=serialization.Encoding.PEM,
    format=serialization.PrivateFormat.PKCS8,
    encryption_algorithm=serialization.BestAvailableEncryption(b'password')
)
```

### ECDSA (Elliptic Curve)

**Advantages**:
- Smaller keys: EC P-256 ≈ RSA 3072
- Faster: Better for signing/verification

**Curves**:
- P-256 (NIST): Widely supported, acceptable
- P-384: Recommended
- P-521: High security
- Curve25519 (Bernstein): Modern, faster, not NIST

### EdDSA (Ed25519)

**Modern alternative** to ECDSA:
```python
from cryptography.hazmat.primitives.asymmetric import ed25519

# Generate key
private_key = ed25519.Ed25519PrivateKey.generate()
public_key = private_key.public_key()

# Sign
message = b"document to sign"
signature = private_key.sign(message)

# Verify
public_key.verify(signature, message)
```

**Why Ed25519**:
- Faster than ECDSA
- Simpler (less room for implementation errors)
- Resistant to side-channel attacks
- Recommended for new systems

---

## Deprecated Algorithms (Migration Required)

| Algorithm | Status | Reason | Migration |
|-----------|--------|--------|-----------|
| MD5 | DO NOT USE | Cryptographically broken | Use SHA-256 |
| SHA1 | DEPRECATED | Collision attacks known | Use SHA-256/512 |
| DES | DO NOT USE | 56-bit key (breakable) | Use AES-256 |
| 3DES | DEPRECATED | Slow, small key | Use AES-256 |
| RC4 | DO NOT USE | Biased keystream | Use AES |
| RSA-1024 | DO NOT USE | Factorizable | Use RSA-2048+ |
| PSS | DEPRECATED | Weak padding | Use OAEP |

### Migration Path Example: MD5 → SHA-256

**Phase 1: Dual-Support** (6 months)
```python
def hash_password(password):
    # Accept both old MD5 and new SHA-256
    # But only produce new SHA-256
    new_hash = sha256(password)
    return new_hash

def verify_password(password, stored_hash):
    # Try new hash first
    if sha256(password) == stored_hash:
        return True
    # Fall back to old hash (allows login)
    if md5(password) == stored_hash:
        # Rehash with new algorithm
        update_hash(password, sha256(password))
        return True
    return False
```

**Phase 2: Force Rehashing** (after 6 months)
```python
def verify_password(password, stored_hash):
    if sha256(password) != stored_hash:
        return False
    # Force password reset if still MD5 hash
    return True
```

**Phase 3: Remove Old Hash** (after 12 months)
```python
# Only SHA-256 hashes accepted
def verify_password(password, stored_hash):
    return sha256(password) == stored_hash
```

---

## mTLS (Mutual TLS)

**Purpose**: Service-to-service authentication (both client and server verify each other)

### mTLS Setup

```
┌──────────────────────┐
│ Internal CA          │
│ (offline root)       │
└──────────┬───────────┘
           │
           ├─ Issue Service A cert
           │  └─ Signed by Internal CA
           │     └─ Common Name: service-a.internal
           │
           └─ Issue Service B cert
              └─ Signed by Internal CA
                 └─ Common Name: service-b.internal
```

### Certificate Validation

**Service A → Service B**:
```
1. Service A connects to Service B:443
2. Presents certificate signed by Internal CA
3. Service B validates:
   - Certificate signature (using CA cert)
   - Common Name: service-a.internal
   - Not expired
   - CRL check (revoked?)
4. Service B sends its certificate
5. Service A validates:
   - Certificate signature
   - Common Name: service-b.internal
   - Not expired
6. If all valid: establish encrypted channel
7. If invalid: reject connection (no fallback)

Result: Both services authenticated to each other
```

### cert-manager (Kubernetes)

```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: internal-ca
spec:
  ca:
    secretRef:
      name: internal-ca-key-pair

---
apiVersion: cert-manager.io/v1
kind: Certificate
metadata:
  name: service-a-cert
  namespace: production
spec:
  secretName: service-a-tls
  issuerRef:
    name: internal-ca
  commonName: service-a.svc.cluster.local
  dnsNames:
  - service-a
  - service-a.production.svc.cluster.local
  duration: 8760h  # 1 year
  renewBefore: 720h  # Renew 30 days before expiry
```

---

## Quantum-Readiness

### NIST Post-Quantum Cryptography

**Status** (2024): NIST standardized first algorithms:
- **CRYSTALS-Kyber** (key encapsulation)
- **CRYSTALS-Dilithium** (digital signatures)
- **FALCON** (digital signatures, alternative)
- **SPHINCS+** (hash-based signatures)

### Migration Timeline

```
2024-2025: Trial deployment (hybrid classical + PQC)
2026-2028: Transition to PQC-primary systems
2030+: PQC-only systems recommended

Harvest Now, Decrypt Later Risk:
- Attacker records encrypted traffic today
- Breaks RSA/ECDSA with quantum computer (2030+)
- Decrypts historical data

Defense: Use hybrid approach now
├─ TLS certificate: RSA (classical) + Dilithium (PQC)
├─ Key exchange: ECDH (classical) + Kyber (PQC)
└─ Signature: RSA-PSS (classical) + Dilithium (PQC)
```

### Cryptographic Agility Requirement

Design systems that allow algorithm swaps without re-architecture:

```
DO NOT hardcode:
  cipher = "AES-256-GCM"  # Fixed forever

DO use configuration:
  config.encryption_algorithm = "AES-256-GCM"  # Can change
  cipher = get_cipher(config.encryption_algorithm)
```

