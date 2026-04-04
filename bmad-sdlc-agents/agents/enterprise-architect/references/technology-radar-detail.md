# Technology Radar

> Reference file for the BMAD Enterprise Architect agent.
> Read this file when designing technology radar for a project.


### Adopt (Production-ready, standardized across enterprise)
- **Languages**: Go (microservices), Java (enterprise workflows), Python (data/ML)
- **Frameworks**: Gin (Go), Spring Boot (Java), FastAPI (Python)
- **Databases**: PostgreSQL (relational), DynamoDB (serverless key-value), Elasticsearch (search/logging)
- **Message Queue**: Apache Kafka (event streaming), AWS SQS (simple queuing)
- **Container Orchestration**: Kubernetes on EKS
- **Observability**: Prometheus (metrics), ELK Stack (logs), Jaeger (traces)
- **API**: REST + OpenAPI spec (synchronous), AsyncAPI (asynchronous)
- **Infrastructure-as-Code**: Terraform (we're now AWS-focused)

### Trial (Promising, use in controlled projects)
- **gRPC**: High-throughput inter-service communication (pilot in Order Service)
- **GraphQL**: Gateway for specific use cases (not replacing REST API)
- **Serverless (Lambda)**: For async/batch workloads, not critical-path APIs
- **Service Mesh (Istio)**: Advanced traffic management, still learning ops complexity

### Assess (Interesting, evaluate for future)
- **Rust**: Systems programming, candidate for performance-critical paths (cache layer, crypto)
- **Event Sourcing**: Alternative data persistence model (reduces CRUD complexity but adds operational overhead)
- **Machine Learning (ML Ops)**: Recommendation engine for e-commerce (assess cost/benefit)

### Hold (Deprecated, migrate away)
- **Node.js/JavaScript**: Legacy systems only; no new services (lack of type safety, ops team unfamiliar)
- **MongoDB**: Eventual consistency issues in banking; migrate legacy apps to PostgreSQL
- **Cassandra**: Operational complexity outweighs benefits; consolidate to PostgreSQL + Redis
- **VM-based deployment**: Kubernetes is default; no new VMs
- **Monolithic architecture**: Greenfield projects use microservices from start

### Language Team Distribution
| Language | Teams | Rationale |
|----------|-------|-----------|
| Go | Platform, Backend (3 teams) | High throughput, fast startup, ops team has expertise |
| Java | Enterprise (2 teams) | Rich ecosystem, mature libraries, team seniority |
| Python | Data/ML, Analytics (1 team) | ML frameworks, team skills |
```

### 5. Compliance & Regulatory Architecture
Design systems and processes to meet legal and regulatory requirements.

**What you produce:**
- **Compliance framework** — What regulations apply (SOC2, GDPR, HIPAA, PCI-DSS)?
- **Data classification** — Which data is PII, sensitive, internal-only?
- **Access controls** — Who can read/modify sensitive data?
- **Audit logging** — What events are logged for compliance review?
- **Data residency** — Where data must live (GDPR: EU data in EU)
- **Data retention & deletion** — How long is data kept? How is deletion audited?
- **Encryption** — Data in transit and at rest
- **Vendor compliance** — Are third-party services compliant?

**Why:** Compliance breaches lead to fines (GDPR: €20M or 4% revenue, whichever is higher), lawsuits, and reputation damage. Non-compliance is unacceptable.

**Example output (SOC2 Type II focus):**

```markdown
