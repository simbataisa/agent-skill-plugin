# Threat Modeling Guide

> Reference file for the BMAD InfoSec Architect agent.
> Read this file when conducting threat modeling exercises, building data flow diagrams, and identifying attack vectors.

---

## When to Threat Model

**Mandatory Threat Modeling**:
- New system or service launch
- Significant architectural changes (moving to cloud, adding authentication, new integrations)
- Annual security review (even for existing systems)
- Major feature addition that changes data handling
- Infrastructure migration (on-prem to cloud)
- Before security audit or compliance review

**Optional but Recommended**:
- Database schema changes
- Third-party integration
- Major UI changes affecting authentication/authorization
- Performance optimizations that might affect security

---

## STRIDE Methodology

STRIDE is a threat classification framework developed by Microsoft. Each category represents a class of attacks.

### S: Spoofing (Authentication)

**Definition**: Attacker impersonates a legitimate user or system.

**Example Attacks**:
- Man-in-the-middle (MITM) intercepts credentials
- Weak password allows account takeover
- Forged JWT token grants unauthorized access
- DNS spoofing redirects to attacker's server

**Mitigation Patterns**:
- Strong password policy + MFA
- Certificate pinning for API calls
- TLS 1.3 with certificate validation
- Digital signatures on tokens
- Hardware security keys for privileged accounts

### T: Tampering (Integrity)

**Definition**: Attacker modifies data in transit or at rest.

**Example Attacks**:
- Unencrypted HTTP allows traffic modification
- Database update without change validation
- Cache poisoning via unvalidated input
- Git commit history manipulation (if not signed)

**Mitigation Patterns**:
- Encryption in transit (TLS) + at rest (AES-256-GCM)
- Integrity checks (HMAC, digital signatures)
- Immutable audit logs
- Git commit signing (GPG)
- Code review and change approval

### R: Repudiation (Non-Repudiation)

**Definition**: Attacker denies having performed an action.

**Example Attacks**:
- User claims they didn't initiate a transaction
- Admin denies deleting critical data
- Service doesn't log who made changes

**Mitigation Patterns**:
- Comprehensive audit logging (who, what, when, where)
- Immutable logs (append-only, timestamped, signed)
- Digital signatures proving authenticity
- Timestamped log entries
- Multi-factor confirmations for critical actions

### I: Information Disclosure (Confidentiality)

**Definition**: Attacker gains unauthorized access to sensitive data.

**Example Attacks**:
- SQL injection extracts customer data
- Unencrypted S3 bucket exposes PHI
- Error messages reveal system internals
- Logs written with debug info containing secrets

**Mitigation Patterns**:
- Encryption at rest + in transit
- Access controls (least privilege)
- Input validation (prevent injection)
- Error handling (generic error messages)
- Secrets management (no hardcoded credentials)
- Data classification and retention policies

### D: Denial of Service (Availability)

**Definition**: Attacker prevents legitimate users from accessing the service.

**Example Attacks**:
- Network DoS (volumetric attack, floods network)
- Application DoS (algorithmic complexity, resource exhaustion)
- Ransomware encrypts database, making service unavailable
- DDoS via botnet

**Mitigation Patterns**:
- Rate limiting + request throttling
- Load balancing + auto-scaling
- DDoS protection (CloudFlare, AWS Shield)
- Resource limits (timeouts, max connections)
- Redundancy and failover
- Chaos engineering (resilience testing)

### E: Elevation of Privilege (Authorization)

**Definition**: Attacker gains higher permissions than authorized.

**Example Attacks**:
- Privilege escalation via kernel vulnerability
- Broken access control allows user to access admin endpoint
- Insecure direct object reference (IDOR) accesses another user's data
- JWT token forgery grants admin claims

**Mitigation Patterns**:
- Role-based access control (RBAC) + attribute-based (ABAC)
- Least privilege (minimal permissions by default)
- Access control checks on every endpoint
- Token validation with signing keys
- Segregation of duties
- Regular access reviews

---

## Data Flow Diagram (DFD) Construction

### Level 0: Context Diagram

Shows the system as a single box with external entities and data flows.

```
                    ┌──────────────────┐
        User ─────→ │   MyApp System   │ ← Stripe (Payment)
                    └──────────────────┘
                           │
                           ↓
                    Email Service
                           │
                           ↓
                    Database Server
```

**Elements**:
- **External Entity** (rectangle): User, third-party service, admin
- **System** (circle or rectangle): The application being modeled
- **Data Flow** (arrow): How data moves between entities
- **Data Store** (parallel lines): Where data is persisted

### Level 1: System DFD

Shows major components and how data flows between them.

```
┌──────────────────────────────────────────────────────┐
│              MyApp Payment Service                   │
│                                                      │
│  ┌──────────────┐        ┌──────────────┐          │
│  │   Web UI     │        │  API Server  │          │
│  └──────┬───────┘        └──────┬───────┘          │
│         │ (1) Login             │ (2) User data    │
│         │                       ↓                   │
│         │              ┌──────────────┐            │
│         │              │  Auth Service│            │
│         │              └──────┬───────┘            │
│         │                     │ (3) Auth token    │
│         └─────────────────────┼────────────────┐  │
│                               │                 │  │
│                  ┌────────────┴──────────┐     │  │
│                  ↓                       ↓     │  │
│         ┌──────────────────┐   ┌──────────────┘  │
│         │   Order Service  │   │  (4) Process   │
│         └────────┬─────────┘   │    Payment     │
│                  │ (5) Update  │                │
│         ┌────────↓─────────┐   │                │
│         │   Database       │   │                │
│         │   (user orders)  │   │                │
│         └──────────────────┘   │                │
│                                 ↓                │
│                        ┌──────────────┐        │
│                        │Stripe (ext)  │        │
│                        └──────────────┘        │
│                                                │
└──────────────────────────────────────────────────┘
```

### Level 2: Detailed Component DFD

Breaks down specific components further (e.g., API server into endpoints).

**DFD Notation**:
- **Circle** (or rounded rectangle): Process (e.g., "Validate user input")
- **Rectangle**: External entity
- **Parallel lines**: Data store
- **Arrow**: Data flow with description
- **Dashed line**: Trust boundary

### Trust Boundaries

Mark the perimeter of your system and areas requiring authentication.

```
                   ┌──────────────────────────────────────┐
                   │     Trust Boundary: Internet          │
   ┌──────┐        │  ┌────────────────────────────────┐ │
   │ User │───────→│  │  API Gateway (TLS, Auth check) │ │
   └──────┘        │  └────────────────────────────────┘ │
                   │              │                      │
                   └──────────────┼──────────────────────┘
                                  │
                   ┌──────────────┴──────────────────────┐
                   │  Trust Boundary: Internal Network   │
                   │                                     │
                   │  ┌──────────────────────────────┐  │
                   │  │ Microservices (mTLS enabled) │  │
                   │  │ ├─ Auth Service              │  │
                   │  │ ├─ Order Service             │  │
                   │  │ ├─ Payment Service           │  │
                   │  └──────────────────────────────┘  │
                   │                                     │
                   │  ┌──────────────────────────────┐  │
                   │  │  Database (encrypted at rest)│  │
                   │  └──────────────────────────────┘  │
                   └─────────────────────────────────────┘
```

**Critical Trust Boundaries**:
1. Internet to Internal Network
2. Application to Database
3. Service to Service (if different security domains)
4. User space to Kernel
5. Web app to Third-party APIs

---

## PASTA (Process for Attack Simulation and Threat Analysis)

**When to use**: Complex architectures, high-stakes systems, mature organizations

### 7 Stages

1. **Define Objectives**: What are we protecting? Why?
2. **Define Technical Scope**: What systems are in scope?
3. **Application Decomposition**: Break down into components
4. **Threat Analysis**: What attacks are possible?
5. **Vulnerability Analysis**: What weaknesses enable attacks?
6. **Attack Modeling**: How would attacks play out?
7. **Risk Analysis & Countermeasures**: What to do about it?

**PASTA vs STRIDE**:
- STRIDE: Threat-centric (start with threats, find risks)
- PASTA: Risk-centric (start with business objectives, assess impact)

Use PASTA for strategic planning, STRIDE for tactical security.

---

## Attack Trees

Hierarchical representation of attack paths. Root = overall goal, leaves = atomic attacks.

### Example: Authentication Bypass Attack Tree

```
                    Bypass Authentication ← Goal
                          │
                ┌─────────┼─────────┐
                │         │         │
           Phishing    Brute-Force  Exploit
           (Social     (Technical)  (System)
            Eng)              │
                    ┌────────┼────────┐
                    │        │        │
              Weak Pass   Default   Attack
              Policy      Creds     2FA
                │
            ┌───┴───┐
            │       │
       No Min    No Special
       Length    Chars
```

**AND/OR Nodes**:
- **OR** (default): Any single path succeeds
- **AND**: All paths needed (e.g., both weak password AND network access)

### Probability Calculation

```
Brute-Force Attack Success:
├─ Network access (0.8 probability)
├─ AND Weak password policy (0.6 probability)
└─ Probability of Brute-Force = 0.8 × 0.6 = 0.48 (48%)

Defense: Implement MFA (reduces to 0.05 probability)
```

---

## Threat Scoring: DREAD vs CVSS

### CVSS v3.1 (Industry Standard)

**Base Score Components**:
- **AV** (Attack Vector): Network, Adjacent, Local, Physical
- **AC** (Attack Complexity): Low, High
- **PR** (Privileges Required): None, Low, High
- **UI** (User Interaction): None, Required
- **S** (Scope): Unchanged, Changed
- **CIA** (Confidentiality, Integrity, Availability): None, Low, High

**Example**: SQL Injection vulnerability
- AV:N (exploitable over network)
- AC:L (low complexity, standard techniques)
- PR:N (no privileges needed)
- UI:N (no user interaction)
- S:U (scope unchanged)
- C:H I:H A:H (all three high impact)

**CVSS Score**: 9.8 (Critical)

### DREAD Framework (Older, less recommended)

| Factor | Score | Description |
|--------|-------|-------------|
| **D** Damage | 1–10 | How bad if exploited? |
| **R** Reproducibility | 1–10 | How easy to trigger? |
| **E** Exploitability | 1–10 | How easy to exploit? |
| **A** Affected Users | 1–10 | How many users affected? |
| **D** Discoverability | 1–10 | How easy to find? |

**Risk = Average(D, R, E, A, D)**

---

## Threat Modeling Worked Example: E-Commerce Order Service

### 1. Define Scope

**System**: Order microservice in e-commerce platform  
**Components**:
- REST API (Node.js, public internet)
- PostgreSQL database (internal network)
- Stripe payment gateway (third-party)
- Redis cache (internal)
- Queue (RabbitMQ, internal)

### 2. Data Flow Diagram

```
User → API Gateway → Order Service → Stripe
                          ↓
                     Database
                          ↓
                      Cache (Redis)
                          ↓
                      Queue (async processing)
```

### 3. STRIDE Analysis

**Spoofing (Authentication)**:
- Threat: User claims order belongs to them
- Control: JWT validation on every API call
- Status: Implemented ✓

**Tampering (Integrity)**:
- Threat: Attacker modifies order amount before payment
- Control: Calculate order total server-side, sign order data
- Status: Implemented ✓

**Repudiation (Non-Repudiation)**:
- Threat: User claims they didn't place order
- Control: Immutable audit log of order creation
- Status: In Progress ⚠️

**Information Disclosure (Confidentiality)**:
- Threat: Order data leaked (PII, payment info)
- Control: Encrypt at rest (AES-256), TLS in transit, mask in logs
- Status: Implemented ✓

**Denial of Service (Availability)**:
- Threat: Attacker floods orders endpoint, crashes service
- Control: Rate limiting, request timeout, auto-scaling
- Status: Rate limit implemented, auto-scaling pending ⚠️

**Elevation of Privilege (Authorization)**:
- Threat: User accesses another user's orders
- Control: RBAC check (verify order.user_id == auth.user_id)
- Status: Implemented ✓

### 4. Threat Table

| ID | Threat | Component | Likelihood | Impact | CVSS | Control | Status |
|----|--------|-----------|------------|--------|------|---------|--------|
| 1 | Weak password → Account takeover | Auth | High | High | 8.1 | MFA enforced | Implemented |
| 2 | IDOR (access other orders) | API | Medium | High | 7.3 | RBAC check | Implemented |
| 3 | Order tampering (amount) | API | Low | Critical | 7.8 | Server-side calc | Implemented |
| 4 | SQL injection | Database | Low | Critical | 9.0 | Prepared statements | Implemented |
| 5 | DDoS on orders endpoint | API | Medium | High | 7.5 | Rate limiting | Partial |
| 6 | Data exfiltration (database) | Database | Low | Critical | 8.9 | Encryption at rest | Implemented |
| 7 | Cache poisoning (Redis) | Cache | Low | Medium | 6.5 | Input validation | Implemented |
| 8 | Unencrypted payment data | API | Low | Critical | 8.8 | Tokenization (Stripe) | Implemented |

---

## Threat Modeling Artifacts

### Deliverables Checklist

- [ ] **DFD** (Levels 0, 1, optionally 2)
- [ ] **Trust Boundaries** (clearly marked)
- [ ] **Threat Table** (STRIDE × components)
- [ ] **Attack Trees** (for high-risk scenarios)
- [ ] **Risk Scoring** (CVSS + likelihood)
- [ ] **Control Mapping** (threat → mitigation)
- [ ] **Out-of-Scope** (what's not covered)
- [ ] **Sign-off** (architect, security lead)

### STRIDE Checklist Template

```markdown
## Spoofing Threats
- [ ] Can users be impersonated?
- [ ] Can services be impersonated?
- [ ] Can devices be spoofed?
Mitigations: ___

## Tampering Threats
- [ ] Can data in transit be modified?
- [ ] Can data at rest be modified?
- [ ] Can configuration be tampered?
Mitigations: ___

## Repudiation Threats
- [ ] Are actions logged?
- [ ] Can logs be altered?
- [ ] Is there non-repudiation?
Mitigations: ___

## Information Disclosure Threats
- [ ] Is data encrypted in transit?
- [ ] Is data encrypted at rest?
- [ ] Are secrets exposed in logs?
Mitigations: ___

## Denial of Service Threats
- [ ] Can the service be overloaded?
- [ ] Are resources limited?
- [ ] Is redundancy in place?
Mitigations: ___

## Elevation of Privilege Threats
- [ ] Can users access admin functions?
- [ ] Are permissions validated?
- [ ] Is least privilege enforced?
Mitigations: ___
```

---

## Common Threat Patterns by Architecture

### Monolithic Application

**High-Risk Threats**:
- Single point of failure (DoS, crashes entire app)
- Large attack surface (more code = more bugs)
- Shared database (one vulnerability exposes everything)

**Mitigations**:
- Segmentation (separate concerns)
- Rate limiting on all endpoints
- Input validation throughout

### Microservices

**High-Risk Threats**:
- Service-to-service communication (mTLS needed)
- Distributed secrets (scaling complexity)
- API gateway is critical (failure cascades)

**Mitigations**:
- Mutual TLS (mTLS) for service-to-service
- API gateway authentication
- Circuit breakers + timeouts
- Service mesh (Istio, Linkerd)

### Serverless (AWS Lambda, GCP Functions)

**High-Risk Threats**:
- Cold start vulnerabilities
- Function isolation (all functions in same account)
- Third-party library vulnerabilities (more deps, less control)

**Mitigations**:
- VPC isolation for sensitive functions
- Input validation (untrusted JSON from API Gateway)
- Minimal dependencies (reduce attack surface)
- Regular dependency updates

### Cloud-Native (Kubernetes)

**High-Risk Threats**:
- Container escape (attacker breaks out to host)
- Pod-to-pod communication (unencrypted by default)
- RBAC misconfiguration (overly permissive)

**Mitigations**:
- Network policies (restrict pod-to-pod traffic)
- Pod security policies (restricted runtime)
- Network encryption (Calico, Cilium)
- Regular security updates (K8s, container runtime)

