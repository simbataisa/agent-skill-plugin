# Platform Engineering & Shared Services

> Reference file for the BMAD Enterprise Architect agent.
> Read this file when designing platform engineering & shared services for a project.


### Developer Experience Goals
- **Onboarding time**: New service deployed to staging within 1 day (currently 3 days)
- **Debugging**: Logs/traces searchable and linked within 10 seconds (currently 2 minutes)
- **Deployment**: Self-service (no ops approval for non-prod)
- **Local development**: `docker-compose up` replicates production within 5 minutes

### Shared Services (Platform Team)

#### API Gateway (Kong)
**What it does**: Central entry point, auth, rate limiting, request logging
**API**: `/api/*` routes to backend services
**Authentication**: JWT token validation (delegates to Auth Service)
**Rate Limiting**: 100 req/s per user, 10,000 req/s global
**Self-service**: Teams can register new routes (via Kubernetes Ingress CRD)

#### Auth Service
**What it does**: User login, token issuance, session management
**APIs**:
- POST /auth/login (email + password)
- POST /auth/refresh (refresh token)
- GET /auth/verify (validate JWT)
**Shared library**: Go, Java, Python SDKs available (validates tokens locally for speed)

#### Observability SDK
**What it does**: Structured logging, metrics, distributed tracing (one library)
**Initialization**:
```go
import "github.com/company/observability"

observability.Init(serviceName: "order-service", version: "1.2.3")
// Automatically logs to ELK, metrics to Prometheus, traces to Jaeger
```
**Usage**:
```go
logger := observability.Logger()
logger.WithFields("userId", "user-123").Info("Order created")

observability.RecordMetric("orders.created", 1)

span := observability.StartSpan("process_order")
// ... business logic
span.End()
```

#### Feature Flags Service
**What it does**: Feature toggles for gradual rollout, A/B testing
**Init**:
```go
flags := feature.NewClient("feature-flag-service-url")

if flags.Enabled("new_checkout_flow", userId) {
  // Use new code
} else {
  // Use legacy code
}
```

#### Secrets Injector
**What it does**: Injects AWS Secrets Manager secrets into pods at startup
**Setup**: Add annotation to pod:
```yaml
metadata:
  annotations:
    secrets.platform.company/inject: "true"
    secrets.platform.company/secret-names: "db-password,api-key"
spec:
  containers:
    - name: order-service
      env:
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-secret
              key: password
```
**How it works**: Init container runs before app container, fetches secrets, injects as env vars
**Advantage**: Secrets never in code, Git, or images

### Self-Service Infrastructure
**New service deployment**: Developers use template:
```bash
./scripts/create-service.sh \
  --name my-service \
  --language go \
  --template microservice
```

**This generates**:
- GitHub repo with skeleton code, Dockerfile, Kubernetes manifests
- CI/CD pipeline (GitHub Actions) for tests, build, deploy
- Observability setup (logging, metrics, tracing pre-wired)
- Pre-registered with API Gateway (can receive traffic immediately)
- Pre-configured with secrets injection

**Deployment to prod**: Self-service via GitOps
```bash
git push origin feature-branch
# GitHub Actions tests code
# Open PR → review → merge
# Merge to main → automatic deploy to staging
# Ops team (human) approves canary to prod (1% traffic)
# If no errors after 5 minutes, auto-escalate to 100%
```

### Developer Documentation
- **Getting Started**: Create new service, run locally, deploy to staging (10 minutes)
- **Debugging**: How to find logs, traces, metrics for a customer issue
- **Common tasks**: How to add a new API endpoint, write a test, emit metrics
- **Troubleshooting**: "My pod won't start" → follow runbook
- **SLAs**: What are our latency targets, error budgets, scale limits?
```

### 9. Observability Architecture
Design comprehensive monitoring, logging, and tracing to operate the system.

**What you produce:**
- **Monitoring strategy** — What metrics to collect, alerting thresholds
- **Logging strategy** — What to log, where, how long to keep
- **Tracing strategy** — Distributed tracing for request flows
- **Alerting rules** — When to page on-call engineer
- **Dashboards** — Real-time visibility for ops, business metrics
- **Incident response** — Playbook for handling alerts

**Why:** You can't operate what you can't observe. Blind systems fail silently. Good observability catches problems before customers notice.

**Example output:**

```markdown
