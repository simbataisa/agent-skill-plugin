# Observability Architecture

> Reference file for the BMAD Enterprise Architect agent.
> Read this file when designing observability architecture for a project.


### Metrics (Prometheus)
**What to collect**:
- **RED metrics** (per service):
  - Rate: Requests/sec (broken down by endpoint, status code)
  - Errors: Error rate (5xx / total)
  - Duration: P50/P95/P99 latencies

- **Resource metrics**:
  - CPU, memory, disk usage (per pod, per node)
  - Network I/O (bytes in/out per pod)

- **Business metrics**:
  - Orders/sec (orders created)
  - Revenue/hour
  - Customer growth rate
  - Feature usage (which checkout flow, which shipping method)

- **Database metrics**:
  - Query latency (P50/P95/P99)
  - Connection count
  - Replication lag
  - Slow query count

- **Cache metrics** (Redis):
  - Hit rate
  - Eviction rate
  - Memory usage

**Retention**: 15 days (cost/space trade-off; older data compressed/archived)
**Scrape interval**: Every 30 seconds
**Storage**: Prometheus server (3 replicas, 100GB SSD per replica)

### Logging (ELK Stack)
**What to log**:
- Application logs: Info (requests), Warn (retries), Error (exceptions)
- Audit logs: User actions, admin operations, security events
- Infrastructure logs: Kubernetes events, Node status, Container startup/shutdown

**Format (JSON structured logging)**:
```json
{
  "@timestamp": "2026-02-26T10:30:00Z",
  "level": "info",
  "service": "order-service",
  "trace_id": "abc123def456",
  "span_id": "span789",
  "request_id": "req-xyz",
  "message": "Order created successfully",
  "fields": {
    "user_id": "user-456",
    "order_id": "order-789",
    "total_amount": 99.99,
    "latency_ms": 45
  }
}
```

**Retention**: 30 days (prod), 7 days (staging), 1 day (dev)
**Storage**: Elasticsearch cluster (3 data nodes, 500GB storage)

### Tracing (Jaeger)
**What to trace**: Every external API request + important internal operations
**Sampling**: 100% sampling in staging, 1% in prod (reduces cost; captures issues)
**Data collected per span**:
- Service name, operation name
- Start time, duration
- Status (success/failure/error)
- Logs (errors, important context)
- Tags (user_id, order_id, etc.)
- Parent span (call chain)

**Example trace** (order creation):
```
GET /api/orders (api-gateway) — 120ms
├─ Order Service: Create order — 80ms
│  ├─ Validate order — 5ms
│  ├─ Check inventory (gRPC) — 20ms
│  │  └─ Inventory Service: Reserve stock — 18ms
│  └─ Save to database — 45ms
│     └─ PostgreSQL query — 40ms
└─ Return response — 2ms
```

**Retention**: 72 hours (sufficient to investigate incidents after they occur)

### Alerting Rules
**Critical Alerts** (page on-call engineer immediately):
```
- Error rate > 5% (vs. baseline 1%)
- P99 latency > 500ms (vs. baseline 150ms)
- API Gateway unavailable
- Database replication lag > 30s
- Disk space < 10% free
- Pod crash looping (restarts > 5x in 5 min)
```

**Warning Alerts** (create Slack notification, don't page):
```
- Error rate > 2%
- P95 latency > 250ms
- Memory usage > 80%
- Cache hit rate < 80%
- Message queue lag > 10K messages
```

**Escalation**: If critical alert unacknowledged for 5 minutes, page backup on-call

### Dashboards
**Ops Dashboard** (for on-call engineer):
- Error rate & latency (per service)
- Pod count, node health
- Database replication status
- Alert status + recent incidents

**Service Dashboard** (for dev team):
- Requests/sec, error rate, latencies
- Dependency health (downstream services)
- Recent deployments, version running

**Business Dashboard** (for product/exec):
- Orders/sec, revenue
- Customer growth
- Feature adoption
- SLA compliance (uptime %)

### Incident Response Playbook
**When critical alert fires**:
1. Slack notification includes runbook link
2. On-call acknowledges (stops escalation)
3. Follow runbook:
   - Is it a known issue? (runbook suggests solutions)
   - Gather data (logs, metrics, traces)
   - Determine root cause
   - Implement fix or rollback
4. Post-incident: Update runbook with lessons learned
```

### 10. DevOps & CI/CD Pipeline
Design automated build, test, and deployment processes.

**What you produce:**
- **CI/CD architecture** — What triggers builds, tests, deployments?
- **Pipeline stages** — Lint, unit test, security scan, build image, push to registry, deploy staging, smoke tests, manual approval, deploy prod
- **Promotion gates** — What must pass before code reaches prod?
- **Deployment strategy** — Rolling updates, canary deployments, blue-green
- **Rollback automation** — How to revert failed deployments automatically
- **Pipeline security** — Who can deploy? How are secrets managed in CI?

**Why:** Manual deployments are error-prone and slow. CI/CD pipelines ensure consistency, enable fast iteration, and catch issues early.

**Example output:**

```markdown
