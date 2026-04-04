# Multi-Environment Strategy

> Reference file for the BMAD Enterprise Architect agent.
> Read this file when designing multi-environment strategy for a project.


| Aspect | Dev | Staging | Production |
|--------|-----|---------|------------|
| **Purpose** | Developer experimentation, fast iteration | Pre-release validation, performance testing | Customer traffic, SLA-bound |
| **Cluster** | Single EKS cluster, 3 small nodes | Single EKS cluster (same size as prod), 3 medium nodes | Multi-AZ EKS (primary + failover) |
| **Database** | PostgreSQL dev instance (t3.small), daily snapshot from staging | PostgreSQL staging (r5.2xlarge), weekly snapshot from prod anonymized copy | PostgreSQL prod (r5.4xlarge Multi-AZ), encrypted, 30-day backups |
| **Data** | Synthetic data (faker), no PII | Anonymized prod snapshot (PII redacted), reset weekly | Real customer data |
| **Replicas** | N/A (single replica per service) | 2 replicas per service (load testing) | 5-50 replicas per service (auto-scaling) |
| **Feature Flags** | All flags enabled, fast default | Mix of enabled/disabled (test feature rollout) | Gradual rollout (1% → 10% → 100%) |
| **Logs Retention** | 7 days (cost savings) | 30 days | 90 days (compliance) |
| **Backup Frequency** | Never (not needed) | Daily | Hourly (RTO 60 min) |
| **Disaster Recovery** | Best-effort (acceptable data loss) | Rehearse monthly | Production runbooks, practiced quarterly |

### Promotion Pipeline

```
Developer commits code → Git PR
                           │
                           v
GitHub Actions: Unit tests, linting, SAST
                           │
                           v (on approval)
Build: Docker image, scan for vulnerabilities, push to ECR
                           │
                           v
Deploy to Dev: Kubernetes rollout, run smoke tests
                           │
                           v (manual trigger)
Deploy to Staging: Kubernetes rolling update, run full test suite, performance tests
                           │
                           v (if staging passes)
Prod Deployment Approval: Team review, compliance check
                           │
                           v (scheduled window, manual trigger)
Deploy to Prod: Canary deployment (5% traffic → 50% → 100%), monitor error rates
```

### Configuration Management
- **Secrets** (API keys, DB passwords, JWT keys):
  - Stored in AWS Secrets Manager
  - Rotated every 90 days (automated)
  - Injected as environment variables or volume mounts at pod startup
  - Never logged or stored in Git

- **Feature Flags** (enable/disable features without deployment):
  - LaunchDarkly or similar service
  - Evaluated in-app at runtime
  - Allows A/B testing, gradual rollout, instant rollback

- **Environment-specific Config** (service endpoints, timeouts, batch sizes):
  - Kubernetes ConfigMaps per environment
  - Example: dev uses 100-item batch; prod uses 1000-item batch for Kafka consumers

### Rollback Strategy
**Automatic rollback** if:
- Error rate > 5% (vs. baseline 1%)
- P95 latency > 500ms (vs. baseline 200ms)
- Pod crash rate > 10%

**Rollback execution**:
```bash
# Kubernetes native: revert to previous image
kubectl rollout undo deployment/order-service -n prod

# Terraform (infrastructure): `terraform destroy` specific resources (rare)

# Database (if schema changed): Point-in-time restore from backup (manual, lead-time 30 minutes)
```
```

### 3. Cross-System Integration Strategy
Design how this system integrates with legacy systems, third-party APIs, and other enterprise platforms.

**What you produce:**
- **Integration inventory** — What systems does this integrate with (CRM, billing, warehouse)?
- **Data synchronization** — How data flows between systems (ETL, CDC, webhooks)
- **API contracts** — Do external systems consume our APIs? Rate limiting, authentication
- **Legacy system bridging** — If migrating from monolith, how is traffic shifted?
- **Third-party API management** — Vendor lock-in analysis, fallback strategies

**Why:** Modern systems rarely exist in isolation. Poor integration causes cascading failures or data inconsistencies across the enterprise.

**Example output:**

```markdown
