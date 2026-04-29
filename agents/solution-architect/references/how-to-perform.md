# How to Perform Solution Architecture Work

> Load this reference for the step-by-step workflow from PRD intake through handoff to Enterprise Architect.

### Step 1: Read the PRD
Retrieve `docs/prd.md` and understand:
- Functional requirements (features, user flows)
- Non-functional requirements (traffic, SLAs, compliance, scalability)
- Constraints (budget, team size, timeline, existing systems)

### Step 2: Identify Key Architectural Questions
Ask yourself (and BA/PM if needed):
- Which features are independent (can become separate services)?
- What's the critical path for revenue/users (order processing for e-commerce)?
- What data consistency requirements (strong vs. eventual)?
- Scaling bottlenecks (we can scale X independently from Y)?
- Compliance constraints (PCI-DSS for payments, GDPR for user data)?

### Step 3: Design Service Boundaries
Use domain-driven design. Each service owns a bounded context:
- Identify entities and aggregates from the domain
- Services own their data; no cross-service direct DB queries
- Communication via APIs (sync) or events (async)

**Document in architecture.md:**
```markdown
## Service Inventory
| Service | Domain | Primary Responsibility | Data Owner |
|---------|--------|------------------------|------------|
| User Service | Identity | User profiles, auth | user_db |
| Order Service | Sales | Orders, fulfillment | orders_db |
| Inventory Service | Warehouse | Stock, reservations | inventory_db |
```

### Step 4: Design APIs
For each service:
- List endpoints (GET /resource, POST /resource, etc.)
- Request/response schemas
- Error codes and messages
- Rate limits and timeouts
- Authentication requirements

**Document in tech-specs/api-spec.md as OpenAPI YAML**

### Step 5: Design Data Models
For each service:
- Entity-relationship diagram (tables, columns, constraints)
- Justify database choice (SQL vs. NoSQL)
- Identify hot paths and caching points
- Backup and retention requirements

**Document in tech-specs/data-model.md**

### Step 6: Design Integration Patterns
How do services communicate?
- Synchronous (REST, gRPC) for queries/commands requiring immediate response
- Asynchronous (Kafka, queues) for events, notifications, analytics
- Specify saga pattern for distributed transactions

**Document in tech-specs/integration-spec.md**

### Step 7: Select Technology Stack
For each tier:
- Language & framework (justify trade-offs)
- Database (SQL, NoSQL, cache)
- Message queue / event stream
- Infrastructure (K8s, serverless, VMs)

**Create decision matrix showing alternatives rejected**

### Step 8: Create ADRs
For each major decision:
- What decision? Why this one? What were alternatives?
- What are the consequences (trade-offs)?
- When will we revisit this decision?

**Store in docs/architecture/adr/ADR-NNN-*.md**

### Step 9: Draw Diagrams
Create mermaid diagrams:
- **Component diagram** — Services and external systems
- **Sequence diagram** — Critical request flows (order creation, payment)
- **Data flow** — Where data moves between services
- **Deployment** — K8s architecture (if applicable)

**Embed diagrams in architecture.md**

### Step 10: Write the Solution Architecture Document
Synthesize everything into `docs/architecture/solution-architecture.md`:
- Executive summary (what, why, key decisions)
- Architecture overview diagram
- Service specifications (per service: responsibility, API, data, scaling)
- Integration patterns and workflows
- Technology selections with justifications
- Performance and scalability design
- Security architecture
- Operational considerations (monitoring, logging)
- ADR references
- Risk analysis and mitigations

### Step 11: Handoff to Enterprise Architect
Log the handoff in `.bmad/handoff-log.md`:
```markdown
