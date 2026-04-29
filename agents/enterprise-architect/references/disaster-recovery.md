# Disaster Recovery & Business Continuity

> Reference file for the BMAD Enterprise Architect agent.
> Read this file when designing disaster recovery & business continuity for a project.


### Recovery Objectives
| Objective | Target | Rationale |
|-----------|--------|-----------|
| **RTO** (Recovery Time) | 4 hours (non-critical), 15 min (critical services) | Customer SLA: 99.95% uptime; acceptable planned downtime |
| **RPO** (Data Loss) | 1 hour (orders), 24 hours (analytics) | Orders are revenue; acceptable to lose 1 hour in catastrophic failure |
| **Backup Cadence** | Hourly snapshots (prod); daily (staging) | Enables 1-hour RPO |

### Backup Strategy

#### PostgreSQL Backups
- **Automated backups**: Daily snapshot, 30-day retention (AWS RDS)
- **Point-in-time recovery**: Binary logs kept for 7 days; can restore to any second within 7 days
- **Cross-region**: Snapshots replicated to secondary region (us-west-2) automatically
- **Tested restore**: Monthly restore to test environment to verify integrity
- **Recovery process**:
  ```bash
  aws rds restore-db-instance-from-db-snapshot \
    --db-instance-identifier prod-db-restore \
    --db-snapshot-identifier prod-db-snapshot-2026-02-26-03-00
  # Restore time: 5-15 minutes depending on database size
  ```

#### Kafka Event Log Backups
- **Replication**: Each topic has replication factor 3 (3 copies across brokers)
- **Retention policy**: 7-day retention (allows replay if service crashes)
- **Snapshot backup**: Hourly snapshot to S3 (Kafka's MirrorMaker tool)
  - Enables rebuild of Kafka cluster if all 3 brokers lost (rare)
  - Recovery time: 30 minutes to ingest backups into new Kafka cluster
- **Tested recover**: Quarterly rehearsal on non-prod cluster

#### Redis Cache Backups
- **RDB snapshots**: Hourly snapshots (point-in-time)
- **AOF persistence**: Append-only file (every write appended, durability guaranteed)
- **Backup location**: S3 encrypted bucket
- **Recovery**: Reload from snapshot (< 1 minute)
- **Note**: Cache loss is acceptable (data is authoritative in PostgreSQL); just causes performance blip

### Failover Procedures

#### Regional Failover (AWS us-east-1 → us-west-2)
**Trigger**: Entire us-east-1 region becomes unreachable (estimated probability: 0.01% per year)

**Manual failover process**:
1. On-call engineer confirms us-east-1 outage (pings Route 53 health checks, AWS status dashboard)
2. Declare incident (Slack #incident-response)
3. Engineering lead approves failover (2-minute decision window)
4. Execute failover runbook:
   ```bash
   # 1. Promote read replica in us-west-2 to primary
   aws rds promote-read-replica --db-instance-identifier prod-db-uswest2
   # Time: 2 minutes

   # 2. Update Route 53 to route all traffic to us-west-2 ALB
   aws route53 change-resource-record-sets \
     --hosted-zone-id Z123456 \
     --change-batch file://failover-routing.json
   # Time: 30 seconds (TTL: 60 seconds for clients to notice)

   # 3. Verify: Check error logs, latency metrics in CloudWatch
   # Time: 5 minutes
   ```
5. **Total failover time**: 7 minutes (RTO target: 15 minutes)
6. **Data loss**: Orders committed in last 5 minutes may not have replicated to secondary region (RPO: 1 hour, so acceptable)

#### Service-Level Failover (Single service crashes)
**Automatic**: Kubernetes automatically restarts pods
- **Detection**: Health check fails for pod; kubelet marks unhealthy
- **Action**: Pod is replaced (new pod scheduled on healthy node)
- **Time**: 30 seconds (acceptable for non-critical services)

**Circuit breaker** (cascading failures):
- If Inventory Service > 20% requests failing, downstream services (Order Service) stop calling it
- Fallback: Return cached response or reject order with "Unable to process right now; please retry"
- Recovery: Manual or automatic (after 5 minutes of success, circuit opens)

### Runbooks (On-Call References)

#### Runbook: Database Replication Lag > 5 seconds
1. Check replica status:
   ```bash
   aws rds describe-db-instances --query 'DBInstances[0].StatusInfos'
   ```
2. If replica shows "available" but lag is high, check network:
   ```bash
   # Check security groups allow communication between primary and replica
   aws ec2 describe-security-groups --group-ids sg-12345
   ```
3. If network is healthy, restart replica:
   ```bash
   aws rds reboot-db-instance --db-instance-identifier prod-db-replica
   ```
4. Monitor for 5 minutes to ensure lag returns to < 1 second
5. If lag remains high, escalate to DBA (off-call backup on-call)

#### Runbook: Kubernetes Cluster Node Failure
1. Observe failed node:
   ```bash
   kubectl get nodes | grep NotReady
   ```
2. Drain node gracefully:
   ```bash
   kubectl drain node-name --ignore-daemonsets --delete-emptydir-data
   ```
3. System automatically schedules pods on healthy nodes (30-60 seconds)
4. AWS auto-scaling replaces node (2-3 minutes)
5. Monitor: Check pod restart count, error rates
6. If recovery fails, escalate to Kubernetes SME

### Testing Schedule
- **Monthly**: Restore PostgreSQL backup to test environment, verify data integrity
- **Quarterly**:
  - Full regional failover drill (non-prod cluster, pre-announced maintenance window)
  - Service circuit breaker failure scenarios
  - Kafka rebuild from backups
- **Annually**: Table-top exercise with full ops team (what-if scenarios, discussion)
```

### 7. Cost Optimization & FinOps
Manage cloud costs and design for efficiency.

**What you produce:**
- **Cost baseline** — How much does current infrastructure cost per month?
- **Cost drivers** — Which services consume the most? (usually compute > database > storage)
- **Optimization opportunities** — Reserved instances, spot instances, auto-scaling, right-sizing
- **Cost monitoring** — Budgets, alerts, chargeback to teams
- **Cost forecasting** — Project costs as system grows

**Why:** Cloud costs grow silently. Without monitoring, bills surprise executives. Optimization can reduce costs by 30-50% without sacrificing performance.

**Example output:**

```markdown
