# Technology Radar — Enterprise Architect Reference

> Reference file for the BMAD Enterprise Architect agent.
> Read this file when evaluating, recommending, or governing technology choices.
> Organised into: Radar Rings → then deep-dive sections per domain.

---

## Radar Rings

### Adopt (Production-ready, standardised across enterprise)
- **Languages**: Go (microservices), Java (enterprise workflows), Python (data/ML), TypeScript (frontend/BFF)
- **Frameworks**: Gin (Go), Spring Boot (Java), FastAPI (Python), React (frontend)
- **Databases**: PostgreSQL (relational OLTP), DynamoDB (serverless key-value), Elasticsearch (search/logging), Redis (cache/sessions)
- **Message Queue**: Apache Kafka (event streaming), AWS SQS (simple queuing), RabbitMQ (AMQP workloads)
- **Container Orchestration**: Kubernetes on EKS / GKE / AKS
- **Observability**: Prometheus + Grafana (metrics), OpenTelemetry (instrumentation), ELK Stack (logs), Jaeger / Tempo (traces)
- **API Style**: REST + OpenAPI 3.x (synchronous external APIs)
- **Infrastructure-as-Code**: Terraform (cloud), Helm (Kubernetes manifests)
- **DB Migration**: Flyway (Java/Spring Boot projects), Liquibase (complex multi-DB or enterprise governance)
- **Auth/N (Identity)**: Keycloak (self-hosted IdP, OIDC/SAML/OAuth 2.0)
- **AuthZ (Access Control)**: RBAC (role-based access control — default model)
- **Frontend Build**: Vite (default bundler/dev-server for all new frontend projects)
- **Frontend State**: Zustand (lightweight global state), React Query / TanStack Query (server state)
- **Frontend UI**: shadcn/ui (accessible, unstyled component library over Radix UI)
- **Mobile**: React Native (cross-platform iOS + Android)

### Trial (Promising — use in new projects with team alignment)
- **GraphQL**: API gateway / BFF layer for complex, client-driven queries (not a REST replacement; use Apollo Server or Pothos)
- **AsyncAPI 3.x**: Describe and document event-driven APIs (Kafka, AMQP) — pairs with REST/OpenAPI for full API surface
- **YugabyteDB**: Distributed SQL (PostgreSQL-compatible) for global-scale OLTP needing horizontal write scaling and multi-region active-active
- **ScyllaDB**: Extreme-throughput wide-column store (Cassandra-compatible) for time-series, IoT telemetry, leaderboards — C++ rewrite of Cassandra with lower latency tail
- **SAGA Pattern (Choreography)**: Distributed transaction coordination via domain events — preferred over 2PC for long-running business processes
- **CQRS + Event Sourcing**: Separate read/write models backed by immutable event log — use when audit trail, temporal queries, or high read/write ratio asymmetry are primary requirements
- **Apache Camel**: Enterprise Integration Pattern (EIP) engine for data routing, transformation, and protocol mediation between heterogeneous systems
- **Authentik**: Open-source self-hosted IdP (alternative to Keycloak) with modern UI and simpler ops — trial for greenfield or smaller teams
- **ABAC (Attribute-Based Access Control)**: Fine-grained policy engine (OPA / Casbin) for multi-tenant or data-level access rules beyond RBAC roles
- **Preact**: Drop-in React replacement (3 kB) for performance-critical or embedded UI with tight bundle budgets
- **DuckDB (WASM)**: In-browser / in-process analytical queries over Parquet/CSV — trial for data-heavy dashboards that should avoid a dedicated analytics backend

### Assess (Interesting — evaluate for future adoption)
- **TigerBeetle**: Purpose-built double-entry financial ledger database designed for safety and throughput in accounting/payments workloads — assess when building a payment platform or general ledger from scratch
- **gRPC / Connect**: High-throughput, typed inter-service communication — assess for internal service mesh where REST overhead is measurable
- **SEATA**: Alibaba's distributed transaction framework (AT / TCC / SAGA / XA modes) for Java microservices — assess when migrating existing Spring/Dubbo monoliths with complex DB transactions
- **TCC (Try-Confirm/Cancel)**: Two-phase business-level transaction pattern — assess over SAGA when strong rollback guarantees and tight latency SLAs coexist
- **WSO2 Micro Integrator / Ballerina**: Full ESB/iPaaS suite — assess for regulated enterprises (banking, telco) that need a governed integration platform with built-in monitoring and policy enforcement
- **Spring Integration**: Lightweight EIP framework embedded in Spring apps — assess when Apache Camel is too heavy and the integration logic lives within a single Spring Boot service
- **Authelia**: Lightweight self-hosted SSO + 2FA proxy (OIDC/LDAP) — assess for internal apps and dev environments needing auth without full IdP complexity
- **React Motion / Framer Motion**: Physics-based animation library — assess for products where animation quality is a differentiator (marketing, consumer apps)
- **Event-Driven Architecture (full EDA)**: All inter-domain communication via async events only — assess for domains where decoupling and resilience outweigh operational complexity of event choreography

### Hold (Deprecated — migrate away, no new usage)
- **Node.js/JavaScript (untyped)**: Legacy systems only; all new JS/TS code must be TypeScript
- **MongoDB**: Eventual-consistency issues in transactional workloads; migrate to PostgreSQL
- **Cassandra (self-managed)**: Operational burden; prefer ScyllaDB if wide-column is needed, otherwise consolidate to PostgreSQL
- **VM-based deployment**: Kubernetes is default; no new VMs
- **Monolithic architecture**: Greenfield projects start microservices or modular monolith
- **SOAP/WS-***: Legacy integrations only; new integrations use REST, GraphQL, or AsyncAPI
- **2PC / XA distributed transactions**: Avoid in microservices — use SAGA or TCC instead; XA only if running inside a single managed DB cluster

---

## Domain Deep-Dives

---

### 1. Database Selection Guide

#### Relational / SQL
| Database | When to Use | Avoid When |
|----------|-------------|------------|
| **PostgreSQL** | Default for transactional workloads, complex queries, foreign keys, JSONB columns, PostGIS (geo). Strong ACID. | Write throughput > 100k TPS on a single node without sharding |
| **YugabyteDB** | PostgreSQL-compatible distributed SQL. Global active-active multi-region, horizontal write scale, zero-downtime topology changes. Use when you outgrow single-node Postgres and need distributed SQL, not NoSQL. | Simple single-region apps — adds operational overhead |
| **TigerBeetle** | Purpose-built double-entry financial ledger. Designed from first principles for safety (no corruption), deterministic performance, and 1M+ TPS accounting operations. Use for payment rails, general ledger, fintech core. | General-purpose OLTP — it is not a general DB |

#### Wide-Column / NoSQL
| Database | When to Use | Avoid When |
|----------|-------------|------------|
| **ScyllaDB** | Extreme-throughput time-series, IoT telemetry, audit logs, leaderboards, write-heavy workloads. C++ reimplementation of Cassandra — lower p99 latency, better hardware utilisation. Cassandra-compatible (use existing CQL tooling). | Complex relational queries, strong consistency requirements, small data sets |
| **DynamoDB** | Serverless key-value / document at massive scale. Managed, no ops, predictable latency, pay-per-request. Good for session stores, user profiles, product catalogues. | Complex query patterns beyond partition+sort key (costly GSIs), cost-sensitive high-volume writes |

#### Caching / Session
| Database | When to Use |
|----------|-------------|
| **Redis** | Session storage, rate limiting, pub/sub, leaderboards, distributed locks, cache-aside pattern |

#### Search / Analytics
| Database | When to Use |
|----------|-------------|
| **Elasticsearch / OpenSearch** | Full-text search, log aggregation, faceted search. Not a primary store. |
| **DuckDB** | In-process OLAP — query Parquet/CSV files directly. Embed in Python data pipelines or WASM in browser dashboards. Not a server DB. |

---

### 2. API Style Selection Guide

#### RESTful (REST + OpenAPI 3.x) — **Default**
- **Use when**: External public APIs, mobile/browser clients, CRUD-heavy resources, third-party integration, team is broad and diverse.
- **Strengths**: Universal tooling (Postman, Swagger UI, code generators), cacheable (HTTP semantics), simple mental model.
- **Weaknesses**: Over-fetching / under-fetching for complex client needs, multiple round trips for related data, versioning friction.
- **Governance**: Every REST API must have an OpenAPI 3.x spec committed to the repo. Use API-first design (spec before code).

#### GraphQL — **Trial (BFF / Gateway layer only)**
- **Use when**: Client-driven data fetching (mobile apps, complex dashboards), multiple front-end clients with divergent data needs, BFF (Backend-for-Frontend) consolidation, federation of multiple backend services (Apollo Federation).
- **Strengths**: Single request for complex nested data, self-documenting schema, strong typing, great developer experience for front-end teams.
- **Weaknesses**: Complex caching (no HTTP cache semantics by default), N+1 query problem (requires DataLoader), learning curve for backend teams, security surface (query depth/cost limits required), poor fit for simple CRUD.
- **Do NOT use**: As a direct replacement for all REST services; for file upload-heavy APIs; for simple public APIs where OpenAPI docs and cacheability matter.
- **Governance**: Always set query depth limits, cost analysis, and persisted queries in production. Use Apollo Server, Pothos (TypeScript), or graphql-java.

#### AsyncAPI 3.x — **Adopt (event-driven API documentation)**
- **Use when**: Documenting Kafka topics, AMQP queues, WebSocket channels, or any asynchronous event contract between services.
- **Strengths**: Complements OpenAPI — together they describe the full API surface (sync + async). Machine-readable; generates client/server stubs.
- **Governance**: Every event-driven service must maintain an AsyncAPI spec for its published topics. Store in the repo alongside OpenAPI specs. Use the AsyncAPI Studio or CLI for validation.

#### Decision Matrix
| Criterion | REST | GraphQL | AsyncAPI / Event-Driven |
|-----------|------|---------|------------------------|
| External public API | ✅ First choice | ⚠️ Only with strong team | ❌ Not applicable |
| Mobile BFF | ✅ Works | ✅ Excellent | ❌ |
| Dashboard / data-heavy UI | ✅ With care | ✅ Preferred | ❌ |
| Inter-service (sync) | ✅ | ⚠️ Avoid | ❌ |
| Inter-service (async) | ❌ | ❌ | ✅ First choice |
| Webhook / notification | ✅ | ❌ | ✅ |
| File transfer | ✅ | ❌ | ❌ |

---

### 3. Distributed Transaction Patterns

Microservices cannot use database-level 2PC across service boundaries. Choose the right distributed transaction pattern based on your consistency, latency, and complexity needs.

#### SAGA Pattern
- **Type**: Long-running business transaction decomposed into a sequence of local transactions, each publishing an event or message that triggers the next step. Failed steps trigger compensating transactions.
- **Variants**:
  - **Choreography SAGA** — Services react to events autonomously. No central coordinator. Decoupled but harder to trace the overall flow. Prefer for simple, linear flows.
  - **Orchestration SAGA** — A central orchestrator (state machine / workflow engine) tells each service what to do. Easier to observe and test. Prefer for complex, branching, or long-running flows (use Temporal, Conductor, or Camunda).
- **Use when**: Order management, booking flows, multi-step checkout, any long-running business process spanning multiple services where eventual consistency is acceptable.
- **Avoid when**: Tight latency SLA + strong isolation is mandatory (bank ledger credit/debit) — use TCC instead.

#### TCC (Try-Confirm/Cancel)
- **Type**: Two-phase business-level protocol. Phase 1 (Try): each service tentatively reserves resources. Phase 2 (Confirm or Cancel): coordinator confirms all or cancels all.
- **Strengths**: Stronger isolation than SAGA (resources are locked during Try phase), deterministic rollback.
- **Weaknesses**: All services must implement Try/Confirm/Cancel interfaces — significant contract overhead.
- **Use when**: Financial transfers, inventory reservation, ticketing — anywhere you need near-ACID semantics across services without a distributed DB.

#### SEATA (Simple Extensible Autonomous Transaction Architecture)
- **Type**: Java/Go distributed transaction framework by Alibaba supporting AT (automatic transaction), TCC, SAGA, and XA modes.
- **AT Mode**: Intercepts SQL via JDBC proxy; auto-generates undo log for rollback — minimal code change, works with existing Spring/MyBatis code. Best for migrating a monolith to microservices where DB tables are still co-located or accessible.
- **Use when**: Java/Spring microservices ecosystem, migrating existing Dubbo/Spring Cloud monoliths, teams that need AT mode (minimal code change) or need a centralized transaction coordinator with a management console.
- **Avoid when**: Polyglot stack (not Java-centric), greenfield cloud-native — prefer SAGA/TCC pattern without a framework.

#### Event Sourcing + CQRS
- **Event Sourcing**: Instead of storing current state, store an append-only log of all events that led to the current state. State is rebuilt by replaying events.
- **CQRS (Command Query Responsibility Segregation)**: Separate the write model (commands → events) from the read model (projections / materialised views).
- **Use together when**: Audit trail is a hard requirement (finance, compliance, healthcare), temporal queries ("what was the state at time T?"), high read/write ratio asymmetry (many readers, few writers), complex domain logic (DDD aggregate patterns).
- **Avoid when**: Simple CRUD, small teams, tight time-to-market — Event Sourcing adds significant operational and cognitive overhead (event schema evolution, projection rebuilds).
- **Tooling**: Axon Framework (Java), EventStoreDB, Marten (.NET), custom Kafka-backed implementation.

#### Pattern Selection Matrix
| Scenario | Recommended Pattern |
|----------|-------------------|
| Simple sequential multi-service flow, eventual consistency OK | Choreography SAGA |
| Complex branching long-running workflow | Orchestration SAGA (Temporal / Camunda) |
| Financial transfer needing near-ACID isolation | TCC |
| Migrating Java monolith, minimal code change | SEATA AT mode |
| Audit trail + temporal queries required | Event Sourcing + CQRS |
| High read/write asymmetry, DDD aggregates | CQRS (with or without Event Sourcing) |
| Decoupled domain events, loose coupling | Event-Driven Architecture (async events) |

---

### 4. Enterprise Integration Patterns (EIP) & Integration Platforms

When services need to talk to each other across protocols, formats, or data models, choose the right integration layer.

#### Apache Camel — **Trial**
- **What**: Open-source EIP framework implementing 65+ patterns from the *Enterprise Integration Patterns* book (Hohpe & Woolf). Routes data between 300+ components (Kafka, HTTP, S3, SFTP, databases, SaaS APIs, etc.).
- **Use when**: Complex routing, transformation, and mediation logic between heterogeneous systems; ETL pipelines; protocol bridging (e.g., SFTP → Kafka → REST); message enrichment and content-based routing.
- **Deployment**: Embeds in Spring Boot (`camel-spring-boot-starter`) or runs standalone (Camel K on Kubernetes).
- **Strengths**: Massive connector library, testable routes (CamelTest), battle-tested in enterprise.
- **Weaknesses**: DSL learning curve (Java, XML, YAML flavours), can become complex to trace without good observability.

#### Spring Integration — **Assess**
- **What**: Lightweight EIP framework from the Spring ecosystem. Implements messaging channels, transformers, filters, routers, service activators as Spring beans.
- **Use when**: Integration logic is confined to a single Spring Boot service and you want a lighter touch than Camel — e.g., polling a database table and publishing to Kafka, or consuming an AMQP queue and enriching messages before forwarding.
- **Avoid when**: Cross-system integration with many disparate protocols — Camel is better equipped.

#### WSO2 Micro Integrator / Ballerina — **Assess**
- **What**: Full enterprise integration platform (ESB, API gateway, streaming analytics, identity) with a management console, governed API marketplace, and centralised policy enforcement.
- **Use when**: Regulated enterprises (banking, telco, healthcare) that need a governed integration bus with centralised monitoring, SLA enforcement, and a business-level API marketplace. WSO2 Ballerina is a programming language designed specifically for integration (first-class network types, data transformation, concurrency).
- **Avoid when**: Cloud-native microservices teams that favour lightweight, code-first integration — Camel or Spring Integration will be more familiar and operationally simpler.

#### Choosing Your Integration Approach
| Scenario | Recommended |
|----------|-------------|
| Integration logic inside one Spring Boot service | Spring Integration |
| Cross-system routing / protocol mediation / ETL | Apache Camel |
| Enterprise API marketplace + governance + ESB | WSO2 Micro Integrator |
| Cloud-native event routing | Kafka + SAGA / AsyncAPI |
| B2B / EDI / legacy mainframe integration | Apache Camel (EDI components) |

---

### 5. Database Migration — Java Ecosystem

Both tools manage database schema versioning via versioned migration scripts. Use one per project — never mix.

#### Flyway — **Adopt**
- **Philosophy**: Convention over configuration. SQL-first (or Java-based migrations for complex logic). Migrations are numbered, immutable once applied.
- **Use when**: Spring Boot projects (auto-configured with `spring.flyway.*`), PostgreSQL / MySQL / Oracle / SQL Server, teams that prefer plain SQL migrations, CI/CD pipelines that apply schema on startup.
- **Key features**: Ordered versioned migrations (V1__, V2__), repeatable migrations (R__), undo (paid Flyway Teams), schema history table (`flyway_schema_history`).
- **Integration**: `spring-boot-starter-flyway` — Flyway runs automatically on application startup.

#### Liquibase — **Adopt**
- **Philosophy**: Database-agnostic changelog with multiple format support (XML, YAML, JSON, SQL). Supports rollback natively in the open-source edition.
- **Use when**: Multi-database targets from a single changelog, enterprise governance requiring rollback scripts, complex migrations with preconditions and contexts (dev vs. prod), organisations that want database-neutral changelogs.
- **Key features**: Changeset with author + id (not just version numbers), contexts and labels, `rollback` command, diff + changelog generation from existing DB, Liquibase Hub.
- **Integration**: `spring-boot-starter-liquibase`.

#### Flyway vs Liquibase Decision
| Factor | Flyway | Liquibase |
|--------|--------|-----------|
| Default for Spring Boot greenfield | ✅ Preferred | ✅ Also good |
| Rollback support (OSS) | ❌ (paid) | ✅ Built-in |
| Multi-DB changelog format | SQL or Java only | XML / YAML / JSON / SQL |
| Simplicity | ✅ Simpler mental model | ⚠️ More concepts (changeset, author) |
| Enterprise governance | ⚠️ | ✅ Better fit |
| Existing DB reverse-engineer | ✅ | ✅ (better tooling) |

---

### 6. Frontend Technology Stack

#### Core Framework
| Technology | Role | When to Use |
|------------|------|-------------|
| **React 18+** | UI framework | Default for all web SPAs and complex UIs. Large ecosystem, concurrent rendering, Server Components (Next.js). |
| **React Native** | Cross-platform mobile | iOS + Android from a single TypeScript codebase. Use Expo for managed workflow. Share logic (hooks, stores) with web React. |
| **Preact** | React alternative | Drop-in React replacement (3 kB). Use when bundle size is critical (embedded widgets, progressive enhancement, very performance-sensitive marketing pages). Not for large apps with complex DevTools needs. |

#### Build Tooling
| Technology | Role | When to Use |
|------------|------|-------------|
| **Vite** | Dev server + bundler | **Default** for all new frontend projects. Native ESM, instant HMR, Rollup-based production builds, supports React, Vue, Svelte, Preact. Replaces Create React App and Webpack. |

#### UI Component Library
| Technology | Role | When to Use |
|------------|------|-------------|
| **shadcn/ui** | Component library | **Preferred** for design systems. Accessible, unstyled-first (Radix UI primitives + Tailwind CSS). Components are copied into your repo (you own the code). Pairs with Tailwind CSS. |

#### State Management
| Technology | Role | When to Use |
|------------|------|-------------|
| **Zustand** | Global client state | Lightweight (~1 kB), boilerplate-free, hook-based. Preferred over Redux for new projects. Use for UI state, user preferences, app-level state that is NOT server data. |
| **TanStack Query (React Query)** | Server / async state | Fetching, caching, synchronising server data. Replaces manual `useEffect` + `useState` for API calls. Use alongside Zustand (complementary, not competing). |

#### Animation
| Technology | Role | When to Use |
|------------|------|-------------|
| **Framer Motion** | Production animation | Declarative, physics-based animations for React. Preferred for gesture-driven UIs, layout animations, page transitions. More actively maintained than React Motion. |
| **React Motion** | Legacy animation | Older spring-physics library. Assess Framer Motion first for new projects; React Motion only for existing codebases that already depend on it. |

#### In-Browser Analytics
| Technology | Role | When to Use |
|------------|------|-------------|
| **DuckDB WASM** | In-browser OLAP | Query large Parquet/CSV data directly in the browser without a backend. Use for data-heavy dashboards and analytics tools where shipping data to a server is undesirable or expensive. Not a persistence store. |

#### Frontend Decision Guide
```
New web app?
  → React + Vite + shadcn/ui + Zustand + TanStack Query

Cross-platform mobile?
  → React Native (Expo) — share hooks and stores with web

Bundle size critical / embedded widget?
  → Preact + Vite

Complex animations / gestures?
  → Framer Motion

In-browser data exploration / no backend OLAP?
  → DuckDB WASM
```

---

### 7. Authentication & Identity (AuthN)

#### Keycloak — **Adopt**
- **What**: Open-source, self-hosted Identity and Access Management (IAM) platform. Supports OIDC, OAuth 2.0, SAML 2.0, LDAP/AD federation, social login, MFA, and fine-grained admin.
- **Use when**: Enterprise deployments requiring a full-featured, self-hosted IdP with admin UI, federation to corporate AD/LDAP, and support for multiple protocols. Default choice for on-premises or regulated cloud environments.
- **Key features**: Realm isolation (multi-tenant), client scopes, user federation (LDAP/AD), identity brokering (social + enterprise IdPs), event listeners, custom SPI extensions.
- **Ops note**: Requires proper JVM sizing, PostgreSQL backend for HA, and careful realm/client configuration. Use the Operator for Kubernetes deployments.

#### Authentik — **Trial**
- **What**: Modern, self-hosted open-source IdP. Python/Go stack, Docker-friendly, excellent UI, strong automation API.
- **Use when**: Smaller teams or greenfield projects that find Keycloak's operational complexity disproportionate. Good fit for internal apps, developer platforms, and SaaS startups. Supports OIDC, SAML, LDAP, SCIM, proxy authentication.
- **Strengths**: Simpler setup and upgrades than Keycloak, built-in outpost proxy (no code changes to legacy apps), powerful flow engine for custom auth logic.
- **Weaknesses**: Smaller community than Keycloak, fewer enterprise integrations, Python runtime (Keycloak is Java).

#### Authelia — **Assess**
- **What**: Lightweight self-hosted SSO + MFA reverse-proxy authentication server. Acts as a forward-auth middleware (Nginx / Traefik / Caddy).
- **Use when**: Protecting internal tools, dashboards, or dev environments that lack built-in auth (Grafana, Kibana, internal apps) without full IdP complexity. Very low resource footprint.
- **Limitations**: Not a full IdP — no SAML, no user federation, limited OIDC provider capabilities. Not suitable as the primary enterprise IdP.

#### Choosing Your Auth Solution
| Scenario | Recommended |
|----------|-------------|
| Enterprise SSO, LDAP/AD federation, SAML + OIDC | Keycloak |
| Greenfield / startup needing modern self-hosted IdP | Authentik |
| Protect internal tools with MFA, no full IdP needed | Authelia |
| Cloud-managed (no self-hosting) | AWS Cognito / Auth0 / Azure AD B2C |

---

### 8. Authorisation Models (AuthZ)

#### RBAC (Role-Based Access Control) — **Adopt (default)**
- **What**: Users are assigned roles; roles are granted permissions. Simple, well-understood model.
- **Use when**: Most applications. Roles map to job functions (admin, editor, viewer, support-agent). Easy to audit and explain to compliance teams.
- **Implementation**: Encode roles in JWT claims (`roles: ["admin", "editor"]`). Check roles in API middleware / service layer. Store role assignments in your IdP (Keycloak roles, Authentik groups).
- **Limitation**: Coarse-grained — cannot express "user can edit only their own records" or "manager can approve only requests from their department".

#### ABAC (Attribute-Based Access Control) — **Trial**
- **What**: Policies evaluate attributes of the subject (user), resource, action, and environment. Enables fine-grained, context-aware access decisions.
- **Use when**: Multi-tenant SaaS (tenant isolation), data-level row security ("see only your org's records"), regulatory requirements for fine-grained access (HIPAA minimum necessary, GDPR data minimisation), or when RBAC roles proliferate beyond maintainability.
- **Implementation options**:
  - **OPA (Open Policy Agent)**: Policy-as-code (Rego language). Decoupled policy engine called from your service. Best for complex, frequently-changing policies audited separately from application code.
  - **Casbin**: Multi-model access control library (RBAC, ABAC, ACL) embedded in-process (Go, Java, Node.js, Python). Lower operational overhead than OPA for simpler scenarios.
  - **Database-level RLS (Row-Level Security)**: PostgreSQL RLS policies for data-layer enforcement — defence-in-depth.
- **Governance**: Policies must be version-controlled, tested, and reviewed by a security team. Never implement ABAC as ad-hoc if/else logic in application code.

#### ReBAC (Relationship-Based Access Control) — **Assess**
- **What**: Access decisions based on graph relationships between users and resources (Google Zanzibar model). "Can user X read document Y?" resolved by traversing a relationship graph.
- **Use when**: Google Docs-style sharing, hierarchical org structures, content ownership models. Implemented by SpiceDB (Authzed), OpenFGA (Auth0/Okta open-source).

#### AuthZ Decision Guide
| Access Pattern | Model | Tooling |
|---------------|-------|---------|
| Role-based (admin/editor/viewer) | RBAC | JWT roles + middleware |
| Fine-grained data/resource policies | ABAC | OPA or Casbin |
| "Can user see their own data only?" | ABAC + DB RLS | Casbin + PostgreSQL RLS |
| Google Docs-style sharing | ReBAC | SpiceDB / OpenFGA |
| Compliance audit trail for access decisions | ABAC | OPA (policy as code, logged) |

---

### 9. Language Team Distribution

| Language | Teams | Rationale |
|----------|-------|-----------|
| Go | Platform, Backend performance-critical (3 teams) | High throughput, fast startup, small binaries, strong concurrency |
| Java / Kotlin | Enterprise workflows, integration (2 teams) | Rich ecosystem, Spring Boot, Camel/SEATA maturity, team seniority |
| Python | Data/ML, Analytics, scripting (1 team) | ML frameworks, pandas/numpy, FastAPI for lightweight APIs |
| TypeScript | Frontend, BFF, CLI tooling | Type-safe JS, React ecosystem, shared types between FE and Node BFF |

---

### 10. Quick Reference — Common Architecture Decisions

| Question | Default Answer | When to Deviate |
|----------|---------------|-----------------|
| Sync API between services? | REST + OpenAPI | gRPC if measurable latency problem |
| Async API between services? | Kafka + AsyncAPI spec | SQS if no ordering/replay needed |
| Distributed transaction? | Choreography SAGA | TCC if near-ACID needed; SEATA if Java monolith migration |
| Complex branching workflow? | Orchestration SAGA (Temporal) | Simple flow → choreography SAGA |
| Full audit trail required? | Event Sourcing + CQRS | Only if team can support operational overhead |
| Integration between systems? | Apache Camel | Spring Integration (simpler, same service); WSO2 (enterprise governed) |
| Primary OLTP database? | PostgreSQL | YugabyteDB (global scale); TigerBeetle (financial ledger) |
| High-throughput time-series / IoT? | ScyllaDB | PostgreSQL + TimescaleDB (if SQL queries needed) |
| DB migration (Java)? | Flyway | Liquibase (multi-DB, rollback, enterprise governance) |
| Frontend framework? | React + Vite | Preact (bundle size critical) |
| Frontend state? | Zustand + TanStack Query | Redux (large existing codebase only) |
| Component library? | shadcn/ui + Tailwind | MUI / Ant Design (if team already invested) |
| Cross-platform mobile? | React Native (Expo) | Flutter (if team has Dart expertise) |
| Self-hosted IdP? | Keycloak | Authentik (simpler ops); Authelia (internal tools only) |
| Access control model? | RBAC | ABAC/OPA (fine-grained multi-tenant); ReBAC (sharing graphs) |
