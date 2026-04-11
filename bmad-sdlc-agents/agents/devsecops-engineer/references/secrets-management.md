# Secrets Management Reference

> Reference file for the BMAD DevSecOps Engineer agent.
> Read this file when designing secret storage, preventing secret leaks, automating secret rotation, and implementing secure secret injection patterns.

## Why Secrets Must Never Be Exposed

### Real-World Breach Examples

**GitHub Token Leaked in Public Repo**: A developer accidentally committed a GitHub Personal Access Token (PAT) to a public repository. The token had full repo access. Within hours, attackers cloned private repositories, exfiltrated source code, and created backdoors via commits. Root cause: no pre-commit secret detection.

**AWS Access Keys in Docker Image**: AWS access keys were hardcoded in a Dockerfile ENV variable. The image was pushed to Docker Hub public registry. Attackers found the keys, provisioned hundreds of EC2 instances for cryptocurrency mining, resulting in $9,000 in unexpected charges. Root cause: no image scanning before push.

**Stripe API Key in Code**: A Python library accidentally included a test Stripe API key in source control. Attackers found it via GitHub search, charged $50,000 to test merchant accounts before the key was rotated. Root cause: insufficient access control on API keys (should be environment-specific, not committed).

**Database Password in Env File**: `.env` file containing database password was committed to version control, then appeared in CI logs. Attackers accessed the staging database, exfiltrated customer PII (100K records). Root cause: shared `.env` file not properly excluded from git.

---

## Pre-Commit Secret Detection

### Gitleaks

**Purpose**: Detect hardcoded secrets in git history and commits.

**Installation**:
```bash
# Homebrew
brew install gitleaks

# Docker
docker pull ghcr.io/gitleaks/gitleaks:latest

# Go
go install github.com/gitleaks/gitleaks/v8@latest
```

**Configuration** (`.gitleaks.toml`):
```toml
title = "Gitleaks config"

[extend]
useDefault = true

# Additional patterns
[[rules]]
id = "company-custom-api-key"
description = "Company internal API key"
regex = '''companyapikey[_-]?(?i)(test|prod)[_-]?[0-9a-f]{32}'''
keywords = ["companyapikey"]
severity = "MEDIUM"

# Allowlist
[[allowlist]]
description = "Allowlist fake credentials"
regex = '''(?i)password[\s]*[:=][\s]*["']?(12345|test|demo)["']?'''
path = '''test_.*\.py|mock.*\.json'''

# Entropy rules
[rules.entropy]
Shannon = 3.5
Base64 = 3.5
Hex = 2.5
```

**CLI Usage**:
```bash
# Scan local repository
gitleaks detect --source . -v

# Scan commit history
gitleaks detect --source . --verbose --redact

# Generate JSON report
gitleaks detect --source . -r gitleaks-report.json -f json

# Pre-commit hook
gitleaks detect --source . --exit-code 1 || exit $?

# Scan specific commit
gitleaks detect --source . --log-opts=-1 --commit abc123def

# Scan staging area (pre-commit)
git diff --cached | gitleaks detect --source stdin
```

**Pre-Commit Integration** (`.pre-commit-config.yaml`):
```yaml
repos:
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.2
    hooks:
      - id: gitleaks
        stages: [commit]
        args: ['--verbose', '--redact']
```

**GitHub Actions Integration**:
```yaml
- name: Gitleaks Secret Scan
  uses: gitleaks/gitleaks-action@v2
  with:
    source: .
    verbose: true
    redact: true
    config: .gitleaks.toml
```

### TruffleHog

**Purpose**: Search for high-entropy strings and patterns indicative of secrets.

**Installation**:
```bash
pip install trufflehog
# or
brew install truffleHog
```

**Usage**:
```bash
# Scan local filesystem
truffleHog filesystem . --json > trufflehog-report.json

# Scan git repository
truffleHog git . --json

# Scan GitHub repository
truffleHog github --repo https://github.com/user/repo --json

# Scan with verification
truffleHog filesystem . --verify --json
```

### git-secrets

**Purpose**: AWS-provided tool to prevent committing secrets.

**Installation**:
```bash
brew install git-secrets
# or
git clone https://github.com/awslabs/git-secrets.git
cd git-secrets && make install
```

**Setup**:
```bash
# Install patterns globally
git secrets --install ~/.git-secrets/hooks
git secrets --register-aws --global

# Per-repository setup
cd /path/to/repo
git secrets --install
git secrets --register-aws
```

**Custom Patterns**:
```bash
# Add pattern for company secrets
git secrets --add --global '(COMPANYKEY|INTERNAL_TOKEN)[\s]*=[\s]*[0-9a-f]{32}'

# Add pattern for private keys
git secrets --add --global 'BEGIN RSA PRIVATE KEY'
git secrets --add --global 'BEGIN OPENSSH PRIVATE KEY'
```

---

## HashiCorp Vault

**Purpose**: Centralized secrets management with encryption, audit logging, and dynamic credentials.

### Architecture

**Development Setup**:
```bash
# Start Vault in dev mode (no persistence, one root token)
vault server -dev

# Set address and token
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='s.xxxxxxxxxxxxxxxx'  # From server output
```

**Production Setup**:
- Use HA backend (Consul, Raft, cloud storage)
- Enable TLS (mTLS required for clients)
- Use cloud authentication (AWS IAM, GCP, Azure)
- Enable audit logging to syslog/file
- Use Vault Enterprise for advanced features

### Secret Engines

#### KV V2 (Key-Value Secrets)
```bash
# Enable KV v2 secrets engine
vault secrets enable -version=2 -path=secret kv

# Write a secret
vault kv put secret/myapp/database \
  username=admin \
  password=supersecret \
  host=db.example.com

# Read a secret
vault kv get secret/myapp/database

# Read JSON output
vault kv get -format=json secret/myapp/database

# List secrets
vault kv list secret/myapp/

# Get specific version
vault kv get -version=1 secret/myapp/database

# Delete secret
vault kv delete secret/myapp/database

# Permanently destroy
vault kv destroy -versions=1 secret/myapp/database
```

#### PKI (Certificate Authority)
```bash
# Enable PKI
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki

# Generate root CA
vault write -field=certificate pki/root/generate/internal \
  common_name=example.com \
  ttl=87600h > ca.crt

# Generate intermediate CA
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
vault write -format=json pki_int/intermediate/generate/csr \
  common_name="example.com Intermediate Authority" > pki_int.csr
vault write -format=json pki/root/sign-intermediate \
  csr=@pki_int.csr format=pem ttl=43800h > intermediate.cert.json
```

#### Database Secrets
```bash
# Enable database secrets engine
vault secrets enable database

# Configure PostgreSQL connection
vault write database/config/mydb \
  plugin_name=postgresql-database-plugin \
  allowed_roles="readonly" \
  connection_url="postgresql://{{username}}:{{password}}@db.example.com:5432/postgres" \
  username=vault \
  password=vaultpassword

# Create role with automatic credential generation
vault write database/roles/readonly \
  db_name=mydb \
  creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}';" \
  default_ttl="1h" \
  max_ttl="24h"

# Request temporary credentials
vault read database/creds/readonly
# Returns ephemeral username and password, valid for 1h
```

### Authentication Methods

#### AppRole
```bash
# Enable AppRole auth
vault auth enable approle

# Create role
vault write auth/approle/role/myapp \
  token_ttl=1h \
  token_max_ttl=4h \
  secret_id_ttl=24h

# Get role ID (long-lived, public)
vault read auth/approle/role/myapp/role-id

# Get secret ID (short-lived, private)
vault write -f auth/approle/role/myapp/secret-id

# Authenticate
vault write auth/approle/login \
  role_id=ROLE_ID \
  secret_id=SECRET_ID
```

#### Kubernetes Auth
```bash
# Enable Kubernetes auth
vault auth enable kubernetes

# Configure with K8s API
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_SERVICE_PORT" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  token_reviewer_jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token

# Create role bound to ServiceAccount
vault write auth/kubernetes/role/myapp \
  bound_service_account_names=myapp-sa \
  bound_service_account_namespaces=production \
  policies=myapp-policy \
  ttl=24h
```

### Vault Policies

**Policy Example** (`myapp-policy.hcl`):
```hcl
# Read database credentials
path "database/creds/readonly" {
  capabilities = ["read"]
}

# Read application secrets
path "secret/data/myapp/*" {
  capabilities = ["read"]
}

# List secrets (optional)
path "secret/metadata/myapp/*" {
  capabilities = ["list"]
}

# Deny sensitive paths
path "secret/data/admin/*" {
  capabilities = ["deny"]
}

# Request limited PKI certificates
path "pki_int/issue/myapp" {
  capabilities = ["create", "update"]
}

# Renew tokens
path "auth/token/renew-self" {
  capabilities = ["update"]
}
```

**Write policy**:
```bash
vault policy write myapp-policy myapp-policy.hcl
vault policy list
vault policy read myapp-policy
```

### Lease Renewal

Vault credentials have TTLs. Applications must renew leases before expiration:

```bash
# Get lease info
vault lease lookup database/creds/readonly/LEASE_ID

# Renew lease
vault lease renew database/creds/readonly/LEASE_ID

# Set auto-renewal (Vault Agent handles this)
# Configure in agent config file
```

---

## AWS Secrets Manager

**Purpose**: AWS-native secrets management with encryption, rotation, and audit logging.

### Basic Operations

```bash
# Create secret
aws secretsmanager create-secret \
  --name myapp/database-password \
  --secret-string '{"username":"admin","password":"secrethere"}' \
  --tags Key=Environment,Value=production

# Retrieve secret
aws secretsmanager get-secret-value --secret-id myapp/database-password

# Retrieve as JSON
aws secretsmanager get-secret-value \
  --secret-id myapp/database-password \
  --query 'SecretString' \
  --output text | jq .

# Update secret
aws secretsmanager update-secret \
  --secret-id myapp/database-password \
  --secret-string '{"username":"admin","password":"newsecret"}'

# Delete secret (30-day grace period)
aws secretsmanager delete-secret \
  --secret-id myapp/database-password \
  --recovery-window-in-days 7
```

### Automatic Rotation

**Lambda Rotation Function** (`rotate_secret.py`):
```python
import boto3
import json
import pymysql

secrets_client = boto3.client('secretsmanager')
rds_client = boto3.client('rds')

def lambda_handler(event, context):
    secret_id = event['SecretId']
    token = event['ClientRequestToken']
    step = event['Step']
    
    metadata = secrets_client.describe_secret(SecretId=secret_id)
    if not metadata['RotationEnabled']:
        raise ValueError(f"Secret {secret_id} is not enabled for rotation")
    
    if step == "create":
        create_new_secret(secret_id, token)
    elif step == "set":
        set_secret(secret_id, token)
    elif step == "test":
        test_secret(secret_id, token)
    elif step == "finish":
        finish_secret(secret_id, token)
    else:
        raise ValueError(f"Invalid step: {step}")

def create_new_secret(secret_id, token):
    current = secrets_client.get_secret_value(
        SecretId=secret_id,
        VersionId=token,
        VersionStage='AWSPENDING'
    )
    # Generate new password
    new_password = generate_random_password()
    # Store new version
    secrets_client.put_secret_value(
        SecretId=secret_id,
        VersionId=token,
        VersionStages=['AWSPENDING'],
        SecretString=json.dumps({
            'username': json.loads(current['SecretString'])['username'],
            'password': new_password
        })
    )

def set_secret(secret_id, token):
    new_secret = secrets_client.get_secret_value(
        SecretId=secret_id,
        VersionId=token,
        VersionStage='AWSPENDING'
    )
    conn = pymysql.connect(
        host=HOST,
        user=USER,
        password=PASSWORD
    )
    cursor = conn.cursor()
    cursor.execute(f"SET PASSWORD FOR 'admin'@'%' = PASSWORD('{new_password}')")
    conn.commit()

def test_secret(secret_id, token):
    # Try connecting with new credentials
    pass

def finish_secret(secret_id, token):
    # Mark new version as current
    secrets_client.update_secret_version_stage(
        SecretId=secret_id,
        VersionStage='AWSCURRENT',
        MoveToVersionId=token
    )
```

**Enable Rotation** (via AWS Console or CLI):
```bash
aws secretsmanager rotate-secret \
  --secret-id myapp/database-password \
  --rotation-rules AutomaticallyAfterDays=30 \
  --rotation-lambda-arn arn:aws:lambda:region:account:function:rotate-db-password
```

### Cross-Account Access

**IAM Policy** (allow account B to read account A's secret):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::ACCOUNT_B:role/MyAppRole"
      },
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:region:ACCOUNT_A:secret:myapp/*"
    }
  ]
}
```

---

## SOPS (Secrets Operations)

**Purpose**: Encrypt secrets in-place in YAML/JSON with age or KMS, integrates with git/Helm.

### Installation

```bash
# Homebrew
brew install sops

# Go
go install github.com/mozilla/sops/v3/cmd/sops@latest
```

### Configuration (`.sops.yaml`)

```yaml
creation_rules:
  - path_regex: secrets/.*\.yaml$
    kms: arn:aws:kms:us-west-2:123456789012:key/12345678-1234-1234-1234-123456789012
    gcp_kms: projects/myproject/locations/global/keyRings/myring/cryptoKeys/mykey
    azure_kv: https://myvault.vault.azure.net/keys/mykey/version
    age: age1ufvzqg69nj2twynwdvs37nzxypcrdyf6yy7uprzqlnlw69qzxhcqs28qvg

  - path_regex: config/.*\.json$
    kms: arn:aws:kms:us-west-2:123456789012:key/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
    age: age1ufvzqg69nj2twynwdvs37nzxypcrdyf6yy7uprzqlnlw69qzxhcqsexample

# Exclude from encryption
unencrypted_regex: '^(apiVersion|kind|metadata|labels)'
```

### Basic Usage

```bash
# Create encrypted file
sops secrets.yaml
# Editor opens, SOPS encrypts on save

# Edit encrypted file
sops secrets.yaml
# SOPS decrypts, you edit, re-encrypts on save

# Encrypt existing file
sops -e -i config.yaml
# File is now encrypted

# Decrypt to stdout
sops -d secrets.yaml

# Rotate keys (re-encrypt with new key)
sops -r secrets.yaml
# Re-encrypts with key from .sops.yaml

# View encrypted content
sops -i --show-master-keys secrets.yaml
```

### Helm Integration

**Helm Secrets Plugin**:
```bash
# Install plugin
helm plugin install https://github.com/jkroepke/helm-secrets

# Create encrypted values
helm secrets create values-prod.yaml

# Deploy with encrypted values
helm secrets upgrade release myapp ./chart \
  -f values-prod.yaml

# View decrypted values
helm secrets view values-prod.yaml
```

---

## Kubernetes Sealed Secrets

**Purpose**: Encrypt secrets in git with cluster-specific key.

### Installation

```bash
# Install controller
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# Install CLI
brew install sealed-secrets
# or
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
```

### Workflow

```bash
# Create plain secret
kubectl create secret generic mysecret \
  --from-literal=password=secretvalue \
  --dry-run=client -o yaml > mysecret.yaml

# Seal it (encrypted for this cluster)
kubeseal -f mysecret.yaml -w mysecret-sealed.yaml

# Apply sealed secret to cluster
kubectl apply -f mysecret-sealed.yaml

# Controller automatically decrypts
kubectl get secret mysecret

# Check encryption key
kubeseal key | grep sealed-secrets-key

# Back up encryption key (for disaster recovery)
kubectl get secret -n kube-system sealed-secrets-key \
  -o yaml > sealed-secrets-key-backup.yaml
```

---

## Secret Injection Patterns

### Pattern 1: Init Container

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-init-secret
spec:
  serviceAccountName: myapp-sa
  initContainers:
  - name: fetch-secrets
    image: vault:latest
    env:
    - name: VAULT_ADDR
      value: "https://vault.example.com"
    - name: VAULT_ROLE
      value: "myapp"
    volumeMounts:
    - name: vault-token
      mountPath: /var/run/secrets/vault
    - name: secrets-volume
      mountPath: /secrets
    command:
    - sh
    - -c
    - |
      TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
      VAULT_TOKEN=$(curl -s -X POST \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d role=myapp \
        -d jwt=$TOKEN \
        $VAULT_ADDR/v1/auth/kubernetes/login | jq -r '.auth.client_token')
      
      curl -s -H "X-Vault-Token: $VAULT_TOKEN" \
        $VAULT_ADDR/v1/secret/data/myapp/database | \
        jq -r '.data.data | to_entries | .[] | "\(.key)=\(.value)"' > /secrets/.env
  
  containers:
  - name: app
    image: myapp:latest
    envFrom:
    - secretRef:
        name: mysecret
    volumeMounts:
    - name: secrets-volume
      mountPath: /secrets
      readOnly: true
  
  volumes:
  - name: vault-token
    projected:
      sources:
      - serviceAccountToken:
          path: vault-token
  - name: secrets-volume
    emptyDir: {}
```

### Pattern 2: Sidecar (Vault Agent)

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: vault-agent-config
data:
  vault-agent.hcl: |
    vault {
      address = "https://vault.example.com"
    }
    
    auto_auth {
      method {
        type = "kubernetes"
        
        config = {
          role = "myapp"
        }
      }
      
      sink {
        type = "file"
        config = {
          path = "/vault/secrets/.vault-token"
          mode = 0640
        }
      }
    }
    
    template {
      source = "/vault/config/database.tpl"
      destination = "/vault/secrets/database.env"
      command = "kill -HUP $PPID"
    }

---
apiVersion: v1
kind: Pod
metadata:
  name: app-with-vault-agent
spec:
  serviceAccountName: myapp-sa
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: vault-secrets
      mountPath: /vault/secrets
      readOnly: true
  
  - name: vault-agent
    image: vault:latest
    args: ["agent", "-config=/vault/config/vault-agent.hcl"]
    volumeMounts:
    - name: vault-config
      mountPath: /vault/config
    - name: vault-secrets
      mountPath: /vault/secrets
  
  volumes:
  - name: vault-config
    configMap:
      name: vault-agent-config
  - name: vault-secrets
    emptyDir:
      medium: Memory
```

### Pattern 3: CSI Driver (Secrets Store)

```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: myapp-vault-secrets
spec:
  provider: vault
  parameters:
    vaultAddress: "https://vault.example.com"
    vaultAuthPath: "auth/kubernetes"
    vaultRole: "myapp"
    secretPath: "secret/data/myapp"
    secretObjects: |
      - secretKey: database-password
        objectName: "database-password"
        objectType: secret
        objectAlias: DATABASE_PASSWORD

---
apiVersion: v1
kind: Pod
metadata:
  name: app-with-csi-secrets
spec:
  serviceAccountName: myapp-sa
  containers:
  - name: app
    image: myapp:latest
    env:
    - name: DATABASE_PASSWORD_FILE
      value: /mnt/secrets-store/database-password
    volumeMounts:
    - name: secrets-store
      mountPath: /mnt/secrets-store
      readOnly: true
  
  volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: myapp-vault-secrets
```

---

## Secret Rotation Policy

### Schedule by Type

| Secret Type | Rotation Period | Frequency | Automation |
|-------------|-----------------|-----------|-----------|
| Database password | 90 days | Quarterly | AWS Secrets Manager Lambda |
| API key (internal) | 180 days | Semi-annual | Manual or scheduled task |
| API key (third-party) | 365 days | Annual | Manual reminder |
| SSH/TLS certificates | 1 year | Annual | cert-manager (K8s) |
| AWS access keys | 90 days | Quarterly | IAM credential report + manual |
| OAuth refresh token | 30 days | Monthly | Application-side refresh |

### Rotation Testing Checklist

- [ ] Generate new credential
- [ ] Update application config without downtime
- [ ] Verify all services can connect with new credential
- [ ] Test credential is actually being used (check logs)
- [ ] Keep old credential for 7 days as fallback
- [ ] Revoke old credential after grace period
- [ ] Document rotation in audit log

### Emergency Rotation Runbook

1. **Detection**: Alert from monitoring, customer report, or security investigation
2. **Assess**: Determine scope (which systems, data, timeframe exposed)
3. **Revoke immediately**: Delete credential, block API calls
4. **Generate new**: Create replacement credential
5. **Deploy**: Update all services with new credential
6. **Verify**: Test connectivity, check logs
7. **Communicate**: Notify security team, affected customers (if breach)
8. **Investigate**: Log access during exposure period
9. **Document**: Root cause, timeline, preventive measures

---

## Compliance: Secrets per Framework

| Framework | Requirement | Implementation |
|-----------|-------------|-----------------|
| **PCI-DSS 3.4** | Render passwords unreadable | AES-256-GCM encryption at rest |
| **PCI-DSS 3.5** | Restrict access | RBAC + audit logging (CloudTrail) |
| **SOC2 CC6.1** | Logical access control | MFA + role-based access + change log |
| **GDPR Article 32** | Technical measures | Encryption + integrity checks + monitoring |
| **HIPAA Technical Safeguard** | Encryption | NIST-approved cipher (AES-256), key rotation |
| **ISO 27001 A.10.1** | Authentication | Strong credential storage (bcrypt/Argon2) |

---

## Secret Scanning in CI/CD

**GitHub Actions Integration**:
```yaml
name: Secret Detection

on: [push, pull_request]

jobs:
  detect-secrets:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0  # Full history for git log scanning
    
    - name: Gitleaks
      run: |
        wget https://github.com/gitleaks/gitleaks/releases/download/v8.18.0/gitleaks_8.18.0_linux_x64.tar.gz
        tar xzf gitleaks_8.18.0_linux_x64.tar.gz
        ./gitleaks detect --source . --exit-code 1
    
    - name: TruffleHog
      run: |
        pip install truffleHog
        truffleHog filesystem . --json || true
    
    - name: Fail if secrets found
      run: |
        [ $? -eq 0 ] || (echo "Secrets detected" && exit 1)
```

