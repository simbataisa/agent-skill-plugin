# Cost Optimization & FinOps

> Reference file for the BMAD Enterprise Architect agent.
> Read this file when designing cost optimization & finops for a project.


### Current Cost Baseline (Monthly, Steady-State)
```
| Service | Cost | % of Total |
|---------|------|-----------|
| EKS Compute (EC2 instances) | $12,000 | 45% |
| RDS PostgreSQL | $4,500 | 17% |
| Redis/Elasticache | $2,000 | 8% |
| Kafka/MSK | $1,800 | 7% |
| S3 Storage (backups, logs) | $800 | 3% |
| Data Transfer (inter-AZ, to internet) | $1,200 | 5% |
| Load Balancers, NAT | $1,500 | 6% |
| KMS, Secrets Manager, misc | $600 | 2% |
| **Total** | **$24,400** | **100%** |
```

### Cost Optimization Opportunities

#### 1. Compute (EKS) — $12,000/month → $9,000/month (save 25%)
**Current**: On-demand EC2 instances (m5.2xlarge @ $0.384/hour)
**Optimization**:
- **Reserved Instances (RI)**: Commit 1-year for 30% discount
  - Cost: $0.268/hour (vs. $0.384 on-demand)
  - Savings: $2,640/month for 50 instances
  - Downside: Commitment (but 1-year is acceptable for predictable workload)

- **Spot Instances** (non-critical services): 70% discount
  - Order Service can tolerate interruption (fault-tolerant design)
  - 20% of nodes as Spot instances
  - Additional savings: $960/month
  - Risk: Pods evicted without notice (mitigated by pod disruption budgets)

- **Auto-scaling**: Right-size node count (currently over-provisioned for peak load)
  - Reduce baseline from 50 → 35 nodes (still enough for normal load)
  - Additional savings: $720/month

**Total opportunity**: $4,320/month savings (capture through RI + Spot + rightsizing)

#### 2. RDS Database — $4,500/month → $3,000/month (save 33%)
**Current**: r5.4xlarge instance
**Optimization**:
- **Reserved Instance (1-year)**: 35% discount = $2,925/month
- **Storage optimization**: Current 1TB; actual usage 300GB (over-allocated)
  - Downsize to 500GB gp3: Saves $200/month
- **Read replica**: us-west-2 replica is warm standby but used minimally
  - Make it on-demand instead of always-running
  - Savings: $375/month (bring online only during failover)

**Total opportunity**: $1,500/month savings

#### 3. Data Transfer — $1,200/month → $400/month (save 67%)
**Current**: High inter-AZ traffic (services frequently calling between zones)
**Optimization**:
- **Service co-location**: Schedule pods to same AZ when possible (locality)
  - Use Kubernetes pod affinity rules (Kubernetes scheduler respects)
  - Reduces cross-AZ calls by 40%
  - Savings: $480/month
- **Caching**: Services cache responses from other services
  - Reduces redundant calls by 20%
  - Savings: $240/month
- **HTTP/2 compression**: Reduce payload sizes
  - Savings: $80/month

**Total opportunity**: $800/month savings

### Cost Monitoring & Budgets
- **AWS Budgets**: Set alerts at 80% of monthly budget ($19,500)
  - Alert daily if overspend predicted
  - Alert ops and finance teams
- **Tagging**: Tag all resources by cost center (Product, Platform, Data)
  - Allows chargeback to teams
  - Example: `cost-center: product-team`, `team: order-service`
- **Cost anomaly detection**: ML-based alerts if spending deviates > 20% from expected

### Cost Forecasting
**Assumptions**:
- Traffic grows 50% YoY (scale database, compute)
- Data storage grows 100 GB/month (logs, analytics)
- Per-unit costs decrease 5% YoY (AWS pricing trends)

**Projected costs**:
- 2026 YoY: $300,000 (current baseline: $24,400 × 12 = $292,800)
- 2027 YoY: $450,000 (50% growth, offset by optimization and cost reduction)
- Cost per customer: $1.50/month (assuming 10K customers now, 15K in 2027)
```

### 8. Platform Engineering & Shared Services
Define reusable infrastructure components and developer experience.

**What you produce:**
- **Developer experience (DX) goals** — How easy should it be to deploy, debug, monitor?
- **Shared services** — API gateway, auth, logging, monitoring, secret management
- **Internal APIs** — Services used by all teams (e.g., feature flags, observability SDK)
- **Self-service infrastructure** — Can developers provision environments without ops?
- **Developer documentation** — Getting started, deployment, debugging

**Why:** Without shared infrastructure and good DX, teams build duplicate solutions. 20% of dev time is wasted on reinvention.

**Example output:**

```markdown
