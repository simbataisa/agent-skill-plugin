# How to Perform Enterprise Architecture Work

> Load this reference for the 13-step workflow: from reading the SA document through final handoff to Tech Lead for story creation.

### Step 1: Read the Solution Architecture Document
Retrieve `docs/architecture/solution-architecture.md` and understand:
- Service boundaries and responsibilities
- API contracts and data models
- Technology selections and justifications
- Performance targets and scaling model

### Step 2: Evaluate Enterprise Requirements
Ask yourself (and stakeholders if needed):
- What cloud provider(s) do we use?
- What compliance requirements apply (SOC2, GDPR, HIPAA)?
- What's our target SLA (99.9%? 99.99%)?
- What's the acceptable data loss window (RPO)?
- How quickly must we recover from regional outage (RTO)?
- What's the ops team's experience level (Kubernetes? AWS?)?
- What's the annual cloud budget?

### Step 3: Design Cloud Infrastructure
For the chosen provider (AWS primary focus):
- Define regions, availability zones, VPCs
- Design Kubernetes cluster topology (if using K8s)
- Specify database architecture (Multi-AZ, read replicas)
- Design load balancing and failover
- Create architecture diagrams (network topology, deployment)

**Document in architecture/deployment-topology.md (or similar)**

### Step 4: Define Multi-Environment Strategy
Create dev, staging, prod environments with clear purposes:
- Infrastructure sizing (nodes, database instances)
- Data sources (synthetic, anonymized, real)
- Promotion pipeline (how code flows through environments)
- Configuration management (secrets, feature flags)
- Rollback procedures

**Document in architecture/deployment-topology.md**

### Step 5: Design Disaster Recovery Plan
For each critical component:
- RTO (how fast to recover?)
- RPO (acceptable data loss?)
- Backup strategy (frequency, location, tested restores)
- Failover procedures (automated or manual?)
- Runbooks for on-call engineers

**Document in architecture/disaster-recovery-plan.md**

### Step 6: Address Compliance Requirements
For applicable regulations:
- Which regulations apply (SOC2, GDPR, etc.)?
- Data classification (PII, sensitive, internal)
- Access controls (who can read/write data?)
- Audit logging (what events must be logged?)
- Data residency (where data must live?)
- Encryption (in transit, at rest)
- Data retention (how long to keep? deletion audit?)

**Document in architecture/compliance-framework.md**

### Step 7: Design Observability
Specify what to monitor:
- Metrics (RED: rate, errors, duration; resources: CPU, memory, disk)
- Logging (what, where, how long to keep)
- Tracing (distributed request flows)
- Alerting (when to notify on-call)
- Dashboards (what teams see)

**Document in architecture/observability-design.md**

### Step 8: Plan Cost Optimization
Analyze and reduce cloud costs:
- Current baseline (what does infra cost today?)
- Cost drivers (which services cost most?)
- Optimization opportunities (reserved instances, spot, auto-scaling, right-sizing)
- Cost monitoring (budgets, alerts, chargeback)
- Cost forecasting (project costs as system grows)

**Document in architecture/cost-optimization-plan.md**

### Step 9: Design CI/CD Pipeline
Specify build, test, and deployment automation:
- Pipeline stages (lint, test, build, scan, deploy-staging, smoke-test, manual-approve, deploy-prod)
- Promotion gates (what must pass before prod?)
- Deployment strategy (canary, rolling, blue-green)
- Automatic rollback (what triggers it?)
- Secrets management (how are secrets handled in CI?)

**Document in architecture/ci-cd-pipeline.md (or similar)**

### Step 10: Document Cross-System Integration
If this system integrates with legacy or external systems:
- What systems does it integrate with?
- How does data flow (synchronous APIs, async events, ETL)?
- How are failures handled (retry, queue, fallback)?
- Data consistency guarantees (strong, eventual)

**Document in architecture/enterprise-architecture.md**

### Step 11: Create Enterprise Architecture Document
Synthesize everything into `docs/architecture/enterprise-architecture.md`:
- Executive summary (cloud strategy, compliance posture, SLA targets)
- Cloud infrastructure (provider, regions, VPCs, Kubernetes)
- Multi-environment strategy (dev, staging, prod)
- Disaster recovery (RTO, RPO, backup, failover)
- Compliance framework (regulations, data classification, access control)
- Observability (metrics, logging, tracing, alerting)
- Cost optimization (baseline, drivers, opportunities)
- CI/CD pipeline (build, test, deploy, rollback automation)
- Cross-system integration (legacy systems, third-party APIs)
- Operational runbooks (playbooks for common issues)
- Technology radar (approved, trial, assess, hold)
- Platform engineering (shared services, self-service infrastructure)

### Step 12: Create Supporting Artifacts
Create detailed sub-documents as needed:
- `architecture/deployment-topology.md` — Infrastructure diagrams, cluster topology
- `architecture/disaster-recovery-plan.md` — RTO/RPO, backup strategy, runbooks
- `architecture/compliance-framework.md` — Regulations, data classification, audit logging
- `architecture/observability-design.md` — Metrics, logging, tracing, dashboards
- `architecture/cost-optimization-plan.md` — Cost baseline, opportunities, forecasts
- `architecture/ci-cd-pipeline.md` — Pipeline stages, deployment strategy, promotion gates
- `ci-cd-pipeline.yaml` (or `.github/workflows/ci-cd.yml`) — Executable pipeline definition

### Step 13: Handoff to Tech Lead (for story creation)
Log the handoff in `.bmad/handoff-log.md`:
```markdown
