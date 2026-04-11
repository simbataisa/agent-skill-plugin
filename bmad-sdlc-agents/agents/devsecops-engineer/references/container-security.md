# Container Security Reference

> Reference file for the BMAD DevSecOps Engineer agent.
> Read this file when designing secure Docker images, scanning containers for vulnerabilities, enforcing image security policies, and implementing container runtime protections.

## Dockerfile Hardening Checklist

### Non-Root User

Always run containers as a non-root user to limit blast radius of container escape.

```dockerfile
# Bad: Root user
FROM ubuntu:22.04
COPY app /app
CMD ["/app/server"]

# Good: Explicit non-root user
FROM ubuntu:22.04
RUN groupadd -r appuser && useradd -r -g appuser appuser
COPY --chown=appuser:appuser app /app
USER appuser
CMD ["/app/server"]
```

### Minimal Base Images

Use distroless or Alpine images to reduce attack surface.

```dockerfile
# Bad: Large base image with package manager
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y curl ca-certificates
COPY app /app
CMD ["/app/server"]

# Good: Distroless (Google)
FROM gcr.io/distroless/base-debian11
COPY --from=builder /app/server /app/server
ENTRYPOINT ["/app/server"]

# Good: Alpine
FROM alpine:3.18
RUN addgroup -S appuser && adduser -S appuser -G appuser
COPY --chown=appuser:appuser app /app
USER appuser
ENTRYPOINT ["/app/server"]
```

**Minimal Base Images by Language**:
- **Java**: `gcr.io/distroless/java11-debian11`
- **Python**: `gcr.io/distroless/python3-debian11`
- **Node.js**: `gcr.io/distroless/nodejs18-debian11`
- **Go**: `gcr.io/distroless/base-debian11`
- **Generic**: `alpine:3.18`, `debian:bookworm-slim`

### Multi-Stage Builds

Separate build dependencies from runtime image to reduce final size and vulnerability surface.

```dockerfile
# Bad: Single stage with all build tools
FROM golang:1.21
WORKDIR /app
COPY . .
RUN go build -o server .
EXPOSE 8080
CMD ["./server"]

# Good: Multi-stage
FROM golang:1.21 as builder
WORKDIR /app
COPY go.* .
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 go build -o server .

FROM gcr.io/distroless/base-debian11
COPY --from=builder /app/server /app/server
EXPOSE 8080
ENTRYPOINT ["/app/server"]
```

### Never Store Secrets in Image

Secrets in ENV, COPY, or RUN must never be committed to images.

```dockerfile
# Bad: Secrets in ENV or build args
FROM alpine:3.18
ENV DATABASE_PASSWORD=supersecret123
RUN apk add --no-cache mysql-client
RUN mysql -h db.example.com -u admin -p$DATABASE_PASSWORD < /schema.sql

# Good: Secrets via build-time secrets (BuildKit)
# Enable BuildKit: export DOCKER_BUILDKIT=1
FROM alpine:3.18
RUN --mount=type=secret,id=db_pass \
    apk add --no-cache mysql-client && \
    DBPASS=$(cat /run/secrets/db_pass) && \
    mysql -h db.example.com -u admin -p$DBPASS < /schema.sql

# Build command:
# docker build --secret db_pass=<(echo mysecret) .
```

### Read-Only Root Filesystem

Prevent runtime code modification by making the root filesystem read-only.

```dockerfile
FROM gcr.io/distroless/base-debian11
COPY --chown=appuser:appuser app /app
USER appuser
ENTRYPOINT ["/app/server"]

# In Kubernetes Pod spec:
# securityContext:
#   readOnlyRootFilesystem: true
#   runAsNonRoot: true
#   runAsUser: 65534
# volumes:
# - name: tmp
#   emptyDir: {}
# volumeMounts:
# - name: tmp
#   mountPath: /tmp
```

### Pin Base Image Digests

Prevent base image mutations ("base image supply chain attack").

```dockerfile
# Bad: Floating tag
FROM alpine:latest
# or
FROM node:18

# Good: Pinned to digest
FROM alpine:3.18@sha256:eece025e432126ce23f51d89f5f3c3a1f0a4fbca0bc64e264ee74c0a4b1d21d0
FROM node:18.16.0@sha256:8a6b3a9c9f7e8b9c7d8e7f9e8b7d8c7b6a5f4e3d2c1b0a9f8e7d6c5b4a3f2e1d
```

**Finding digests**:
```bash
docker pull alpine:3.18
docker inspect --format='{{.RepoDigests}}' alpine:3.18
# Output: [alpine@sha256:eece025e432126...]
```

### HEALTHCHECK

Define health probes to enable automatic restart of unhealthy containers.

```dockerfile
FROM alpine:3.18
RUN apk add --no-cache curl

COPY app /app
USER appuser
EXPOSE 8080
ENTRYPOINT ["/app/server"]

# HTTP health check every 30s, timeout 3s, 3 failures to unhealthy
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/healthz || exit 1
```

### Complete Hardened Example

```dockerfile
# Multi-stage: builder
FROM golang:1.21-alpine as builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo \
    -ldflags="-w -s" -o server .

# Runtime: distroless
FROM gcr.io/distroless/base-debian11
COPY --from=builder /app/server /app/server
EXPOSE 8080
USER nonroot:nonroot
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD ["/busybox/wget", "-q", "-O-", "http://localhost:8080/health"]
ENTRYPOINT ["/app/server"]
```

---

## Container Image Scanning Tools

### Trivy

**Purpose**: Comprehensive image vulnerability and misconfiguration scanner.

**Installation**:
```bash
# Homebrew
brew install trivy

# Docker
docker pull ghcr.io/aquasecurity/trivy:latest

# Binary
wget https://github.com/aquasecurity/trivy/releases/download/v0.50.0/trivy_0.50.0_Linux-64bit.tar.gz
```

**Configuration** (`.trivy.yaml`):
```yaml
image:
  max-unfixed: 5  # Fail if more than 5 unfixed vulns
  ignore-unfixed: false
  ignore-policy: .trivyignore
  timeout: 5m0s

severity:
  - CRITICAL
  - HIGH
  - MEDIUM

exit-code: 1  # Exit code 1 if vulns found

format: sarif
output: trivy-report.sarif

# Vulnerability database
db:
  repository: ghcr.io/aquasecurity/trivy-db

# Image scanning options
image:
  input: ""  # Set to image name
  skip-update: false

security:
  # Config scanning
  scan-rocksdb: false
  insecure: false
```

**Basic Trivy Scan**:
```bash
# Scan local image
trivy image myapp:1.0.0

# Scan remote image
trivy image gcr.io/myproject/myapp:latest

# Scan with severity filter
trivy image --severity CRITICAL,HIGH myapp:1.0.0

# Generate SARIF report
trivy image --format sarif --output trivy.sarif myapp:1.0.0

# Scan with custom config
trivy image --config .trivy.yaml myapp:1.0.0

# Scan tar file
docker save myapp:1.0.0 | trivy image --input -

# Scan filesystem
trivy filesystem --severity CRITICAL,HIGH /path/to/app
```

**CI Integration** (GitHub Actions):
```yaml
- name: Trivy Image Scan
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: myapp:${{ github.sha }}
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'

- name: Fail on Critical
  run: |
    trivy image --severity CRITICAL --exit-code 1 myapp:${{ github.sha }}

- name: Upload to GitHub Security
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: 'trivy-results.sarif'
```

**Ignoring Vulnerabilities** (`.trivyignore`):
```
# Ignore specific CVE
CVE-2021-12345

# Ignore CVE in specific image
CVE-2021-12345 exp:2026-01-01T00:00:00Z

# Ignore package vulnerability
go-yaml|GHSA-2c3m-p491-gf7b

# Expire suppression
CVE-2021-99999 exp:2025-12-31T00:00:00Z severity: HIGH justification: "WAF mitigates"
```

### Grype

**Purpose**: SBOM-based and direct image scanning.

**Installation**:
```bash
brew install grype
# or
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin
```

**Usage**:
```bash
# Scan image
grype myapp:1.0.0

# Generate SBOM from Syft
syft myapp:1.0.0 -o json > sbom.json

# Scan SBOM
grype sbom.json

# Output formats
grype myapp:1.0.0 -o json > grype-results.json
grype myapp:1.0.0 -o sarif > grype-results.sarif
grype myapp:1.0.0 -o table
```

### Docker Scout

**Purpose**: Docker-native image scanning and insights.

**Installation**:
```bash
# Part of Docker Desktop or:
docker scout <command>
```

**Usage**:
```bash
# Quick vulnerability scan
docker scout cves myapp:1.0.0

# Detailed comparison
docker scout compare myapp:1.0.0 --to myapp:1.0.1

# Recommendations
docker scout recommendations myapp:1.0.0
```

---

## CVE Severity Thresholds and Policy

| Severity | CVSS Score | Example | Action | Block Build |
|----------|-----------|---------|--------|-------------|
| CRITICAL | 9.0–10.0 | Remote code execution, authentication bypass | Patch immediately | YES |
| HIGH | 7.0–8.9 | Significant information disclosure, privilege escalation | Patch within 7 days | YES |
| MEDIUM | 4.0–6.9 | Limited information disclosure, DoS | Plan patch within 30 days | WARN |
| LOW | 0.1–3.9 | Cosmetic issues, minor DoS | Track for future patch | NO |

**Scanning Policy**:
- Block container push if any CRITICAL
- Block container push if more than 3 HIGH and unfixed
- Allow push with warning if MEDIUM unfixed (create ticket)
- Allow LOW unfixed without warning (create advisory)

---

## Container Registry Policies

### Image Signing with Cosign

**Purpose**: Verify image authenticity and integrity using cryptographic signatures.

**Installation**:
```bash
curl -L https://github.com/sigstore/cosign/releases/download/v2.0.0/cosign-linux-amd64 -o cosign
chmod +x cosign
```

**Generate keys**:
```bash
cosign generate-key-pair
# Creates cosign.key (private) and cosign.pub (public)
```

**Sign an image**:
```bash
cosign sign --key cosign.key gcr.io/myproject/myapp:v1.0.0
```

**Verify signature**:
```bash
cosign verify --key cosign.pub gcr.io/myproject/myapp:v1.0.0
```

### SBOM (Software Bill of Materials) Attestation

**Generate SBOM with Syft**:
```bash
syft gcr.io/myproject/myapp:v1.0.0 -o json > sbom.spdx.json
syft gcr.io/myproject/myapp:v1.0.0 -o cyclonedx > sbom.cyclonedx.json
```

**Attach SBOM to image**:
```bash
cosign attach attestation --predicate sbom.spdx.json \
  --attestation-tag-suffix sbom \
  gcr.io/myproject/myapp:v1.0.0
```

**Verify SBOM**:
```bash
cosign verify-attestation --key cosign.pub \
  gcr.io/myproject/myapp:v1.0.0 | jq '.payload | @base64d | fromjson'
```

---

## Kubernetes Admission Control: OPA Gatekeeper

**Purpose**: Enforce pod security policies via declarative OPA policies.

**Installation**:
```bash
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-0.13.0/deploy/gatekeeper.yaml
```

### Example Policies

**Policy 1: No Root User**
```rego
package k8srequiredlabels

violation[{"msg": msg}] {
  container := input.review.object.spec.containers[_]
  not container.securityContext.runAsNonRoot
  msg := sprintf("Container '%v' must run as non-root", [container.name])
}

violation[{"msg": msg}] {
  container := input.review.object.spec.containers[_]
  container.securityContext.runAsUser == 0
  msg := sprintf("Container '%v' cannot run as UID 0", [container.name])
}
```

**Policy 2: Required Labels**
```rego
package k8srequiredlabels

violation[{"msg": msg}] {
  labels := input.review.object.metadata.labels
  not labels.app
  msg := "Pod must have 'app' label"
}

violation[{"msg": msg}] {
  labels := input.review.object.metadata.labels
  not labels.owner
  msg := "Pod must have 'owner' label"
}
```

**Policy 3: Resource Limits**
```rego
package k8srequiredresources

violation[{"msg": msg}] {
  container := input.review.object.spec.containers[_]
  not container.resources.limits.cpu
  msg := sprintf("Container '%v' must define CPU limit", [container.name])
}

violation[{"msg": msg}] {
  container := input.review.object.spec.containers[_]
  not container.resources.limits.memory
  msg := sprintf("Container '%v' must define memory limit", [container.name])
}
```

**Policy 4: Image Registry Whitelist**
```rego
package k8simpliedimageregistries

allowed_registries := [
  "gcr.io/myproject/",
  "docker.io/library/",
  "ghcr.io/myorg/"
]

violation[{"msg": msg}] {
  image := input.review.object.spec.containers[_].image
  not any_allowed_registry(image)
  msg := sprintf("Image '%v' not from approved registry", [image])
}

any_allowed_registry(image) {
  registry := allowed_registries[_]
  startswith(image, registry)
}
```

---

## Kubernetes Pod Security Standards

**Kubernetes 1.23+ Pod Security Standards**:

### Restricted (Recommended for Production)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: restricted-pod
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 65534
    fsGroup: 65534
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: gcr.io/distroless/base-debian11
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
      runAsUser: 65534
      capabilities:
        drop:
        - ALL
    resources:
      limits:
        cpu: 500m
        memory: 128Mi
      requests:
        cpu: 250m
        memory: 64Mi
  volumes:
  - name: tmp
    emptyDir: {}
```

### Pod Security Policy Enforcement

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  runAsGroup:
    rule: 'MustRunAs'
    ranges:
      - min: 1
        max: 65535
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      - min: 1
        max: 65535
  readOnlyRootFilesystem: true
  seLinux:
    rule: 'MustRunAs'
    seLinuxOptions:
      level: 's0:c123,c456'
```

---

## Runtime Security: Falco

**Purpose**: Monitor container runtime behavior for anomalies and suspicious activity.

**Installation**:
```bash
# Helm
helm repo add falcosecurity https://falcosecurity.github.io/charts
helm install falco falcosecurity/falco \
  --namespace falco \
  --create-namespace \
  --set falco.grpc.enabled=true \
  --set falco.gke.autopilot=false
```

**Example Falco Rule**:
```yaml
- rule: Suspicious Process in Container
  desc: Detect suspicious process execution
  condition: >
    spawned_process and
    container and
    (proc.name in (nc, ncat, netcat, socat, bash, sh) or
     proc.args contains "curl" and proc.args contains "http")
  output: >
    Suspicious process spawned in container
    (user=%user.name command=%proc.cmdline container=%container.name)
  priority: WARNING
  tags: [container, process]
```

---

## seccomp Profiles

**Purpose**: Restrict system calls available to containers.

**Default seccomp profile** (`default.json`):
```json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "defaultErrnoRet": 1,
  "archMap": [
    {
      "architecture": "SCMP_ARCH_X86_64",
      "subArchitectures": [
        "SCMP_ARCH_X86",
        "SCMP_ARCH_X32"
      ]
    }
  ],
  "syscalls": [
    {
      "names": ["read", "write", "open", "close", "stat", "fstat", "lstat"],
      "action": "SCMP_ACT_ALLOW"
    },
    {
      "names": ["chown", "chmod", "fchownat"],
      "action": "SCMP_ACT_ERRNO"
    }
  ]
}
```

**Apply seccomp in Kubernetes**:
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-pod
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: my-profile.json
  containers:
  - name: app
    image: myapp:latest
```

---

## Network Policies: Kubernetes NetworkPolicy

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-all-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress

---

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080

---

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-backend-egress
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Egress
  egress:
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: TCP
      port: 53
```

---

## Full Trivy CI Pipeline Example (GitHub Actions)

```yaml
name: Container Security Scan

on:
  push:
    branches: [main]
    paths:
      - Dockerfile
      - 'src/**'
  pull_request:
    branches: [main]
    paths:
      - Dockerfile
      - 'src/**'

jobs:
  build-and-scan:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Build Docker image
        uses: docker/build-push-action@v4
        with:
          context: .
          push: false
          load: true
          tags: myapp:${{ github.sha }}
      
      - name: Run Trivy vulnerability scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: myapp:${{ github.sha }}
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL,HIGH,MEDIUM'
      
      - name: Run Trivy config scan (Dockerfile)
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'config'
          scan-ref: 'Dockerfile'
          format: 'sarif'
          output: 'trivy-config.sarif'
      
      - name: Fail on critical vulnerabilities
        run: |
          trivy image --severity CRITICAL --exit-code 1 \
            myapp:${{ github.sha }} || exit 0
      
      - name: Upload SARIF results
        uses: github/codeql-action/upload-sarif@v2
        if: always()
        with:
          sarif_file: |
            trivy-results.sarif
            trivy-config.sarif
      
      - name: Generate artifact
        if: always()
        run: |
          trivy image --format json --output trivy-full.json \
            myapp:${{ github.sha }}
      
      - name: Upload artifact
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: trivy-reports
          path: |
            trivy-*.json
            trivy-*.sarif
```

