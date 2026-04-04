# Cloud Infrastructure Architecture (AWS)

> Reference file for the BMAD Enterprise Architect agent.
> Read this file when designing cloud infrastructure architecture (aws) for a project.


### Provider Selection: AWS
**Rationale:**
- Largest service catalog (100+ services); flexibility for future needs
- EC2 + RDS + Kinesis + Lambda ecosystem mature and battle-tested
- Team has AWS certifications and established practices
- Cost: Competitive with Azure; cheaper than GCP for our workload mix

### Multi-Region Strategy
- **Primary Region**: us-east-1 (N. Virginia) — lowest latency for US customers, most services available
- **Secondary Region (Failover)**: us-west-2 (Oregon) — database read replica, minimal app instances
- **Edge Locations**: CloudFront CDN for static assets in all regions

**Rationale**: 99.95% SLA requires multi-region failover; replicating to just one secondary region is sufficient for e-commerce (5-minute RTO acceptable).

### Compute Architecture: Kubernetes on EKS
**Rationale:**
- Microservices workload requires orchestration (container scheduling, self-healing, rolling updates)
- EKS = fully managed Kubernetes (AWS handles control plane); reduces ops burden
- Alternative: Fargate (serverless containers) rejected due to no guaranteed capacity for peak load

**Cluster Topology:**
- Primary EKS cluster: 3 availability zones, minimum 3 nodes, auto-scaling to 200 nodes (for peak load)
- Node groups:
  - `general-purpose`: m5.2xlarge (Order, User Services) — 50 nodes target
  - `compute-optimized`: c5.2xlarge (Inventory heavy lifting) — 30 nodes target
  - `memory-optimized`: r5.2xlarge (cache warming, analytics) — 10 nodes target
- Secondary EKS cluster (failover): single AZ, 3 nodes (minimal), auto-scale only if primary fails

### Network Architecture
```
┌─────────────────────────────── AWS Account (us-east-1) ───────────────────────────────┐
│                                                                                           │
│  ┌─── Internet Gateway ───┐                                                            │
│  │                        │                                                            │
│  │  ┌──── Route 53 ──────┐                                                            │
│  │  │ DNS geolocation    │                                                            │
│  │  │ (route to primary) │                                                            │
│  │  └─────────────────────┘                                                            │
│  │         │                                                                           │
│  │      [ALB] ← 443 TLS + 80 HTTP redirect                                             │
│  │         │                                                                           │
│  ├─ VPC us-east-1 (10.0.0.0/16) ──────────────────────────────────────┐               │
│  │  │                                                                  │               │
│  │  │  Public Subnet (10.0.1.0/24):  NAT Gateway                      │               │
│  │  │  ├─ Bastion Host (for SSH)                                      │               │
│  │  │                                                                  │               │
│  │  │  Private Subnets (Kubernetes, DBs):                             │               │
│  │  │  ├─ 10.0.10.0/24 (AZ-1): EKS worker nodes                       │               │
│  │  │  ├─ 10.0.20.0/24 (AZ-2): EKS worker nodes                       │               │
│  │  │  ├─ 10.0.30.0/24 (AZ-3): EKS worker nodes                       │               │
│  │  │  │                                                              │               │
│  │  │  ├─ RDS Subnet Group:                                           │               │
│  │  │  │  ├─ 10.0.40.0/24 (AZ-1)                                      │               │
│  │  │  │  ├─ 10.0.41.0/24 (AZ-2)                                      │               │
│  │  │  │  └─ 10.0.42.0/24 (AZ-3)                                      │               │
│  │  │  │                                                              │               │
│  │  │  └─ Redis Subnet Group:                                         │               │
│  │  │     ├─ 10.0.50.0/24 (AZ-1)                                      │               │
│  │  │     ├─ 10.0.51.0/24 (AZ-2)                                      │               │
│  │  │     └─ 10.0.52.0/24 (AZ-3)                                      │               │
│  │  │                                                                  │               │
│  │  ├─ [RDS Multi-AZ PostgreSQL]                                      │               │
│  │  │  ├─ Primary: 10.0.40.10 (AZ-1)                                  │               │
│  │  │  └─ Replica: 10.0.41.10 (AZ-2) — automatic failover             │               │
│  │  │                                                                  │               │
│  │  ├─ [Redis Cluster] 6 nodes across 3 AZs                           │               │
│  │  │  ├─ 3 Primary shards                                            │               │
│  │  │  └─ 3 Read replicas (cross-AZ)                                  │               │
│  │  │                                                                  │               │
│  │  └─ [MSK Kafka Cluster] 3 brokers across 3 AZs                     │               │
│  │     ├─ 10.0.10.50 (AZ-1)                                           │               │
│  │     ├─ 10.0.20.50 (AZ-2)                                           │               │
│  │     └─ 10.0.30.50 (AZ-3)                                           │               │
│  │                                                                    │               │
│  └────────────────────────────────────────────────────────────────────┘               │
│                                                                                        │
│  S3 (Regional for logs, backups, static assets)                                       │
│  KMS (Encryption keys, regional managed service)                                      │
│                                                                                        │
└────────────────────────────────────────────────────────────────────────────────────────┘
```

### Database Architecture
- **Primary Database (us-east-1)**: AWS RDS PostgreSQL, Multi-AZ (automated failover)
  - Instance: db.r5.4xlarge (16 vCPU, 128 GB RAM)
  - Storage: 1 TB gp3 (general purpose, encrypted with KMS)
  - Backups: Automated daily, 30-day retention, encrypted snapshots to secondary region

- **Read Replica (us-west-2)**: Asynchronous replication (5-second lag acceptable for analytics)
  - Reduces latency for west-coast queries
  - Enables read scaling for reporting workloads

- **Connection Pooling**: PgBouncer (3 instances, behind ALB)
  - Prevents connection pool exhaustion on app servers
  - Max 1000 connections to RDS; 10,000 app-side connections pooled

### Load Balancing & Traffic Management
- **CloudFront CDN**: Caches static assets (images, JS, CSS), TTL 1 hour for user-specific data
- **Route 53**: Geolocation routing
  - US queries → us-east-1 ALB
  - EU queries → us-west-2 ALB (failover) if eu-west-1 unavailable
  - Default → us-east-1
- **ALB (Application Load Balancer)**:
  - Health checks: /health endpoint (200 OK required; timeout 5s)
  - Sticky sessions: Disabled (stateless services)
  - Connection draining: 300s (graceful shutdown of connections during deployment)

### High Availability Design
**SLA Target**: 99.95% uptime (< 22 minutes downtime per month)

**Single Points of Failure Eliminated**:
- ALB: Managed service, distributed across 3 AZs by AWS
- RDS: Multi-AZ, automatic failover to replica (< 2 minutes)
- Kafka: 3 brokers across 3 AZs, replication factor 3
- Redis: Cluster mode enabled, 3 shards with replicas across AZs

**Failure Scenarios & Recovery**:
- AZ outage: Traffic redirects to remaining 2 AZs within 30s (ALB health checks)
- Regional outage (< 1% probability): Route 53 fails over to secondary region (manual trigger via runbook)
- Service pod crash: Kubernetes auto-restarts within 10 seconds
- Database failure: RDS Multi-AZ fails over to replica (automatic, < 2 minutes, may drop 1-2 transactions)
```

### 2. Multi-Environment Strategy
Define dev, staging, and production environments with clear purposes and promotion paths.

**What you produce:**
- **Environment definitions** — dev (ephemeral), staging (production-like), prod (hardened)
- **Promotion pipeline** — How code/config flows from dev → staging → prod
- **Configuration management** — Secrets, feature flags, environment-specific overrides
- **Rollback strategy** — How to revert failed deployments
- **Data isolation** — Do staging/dev share prod data (usually not) or have replicas?

**Why:** Environment confusion causes staging bugs to ship to production. Clear environment boundaries prevent this.

**Example output:**

```markdown
