# Threat Model Template

> Template file for the BMAD InfoSec Architect agent.
> Use this template to document a complete threat modeling exercise for a system.

---

## Document Header

**System Name**: Payment Processing Microservice  
**Version**: 1.0  
**Date**: 2026-04-11  
**Author**: Alice Chen (Security Architect)  
**Approved By**: Bob Martinez (CISO)  
**Review Date**: 2026-10-11 (6-month review)  

---

## 1. System Overview and Scope

### Description
Payment Processing Microservice handles credit card processing, order confirmation, and payment reporting for e-commerce platform. Service receives orders from API Gateway, processes via Stripe, and logs to data warehouse.

### In Scope
- REST API endpoints (/api/v1/payments/*)
- Stripe integration (card processing)
- PostgreSQL database (orders, transactions)
- Redis cache (transaction state)
- Internal logging (CloudWatch)

### Out of Scope
- Stripe infrastructure (managed by third party)
- API Gateway (separate threat model)
- Customer web interface (separate threat model)
- Historical reporting system (separate data warehouse)

### Assumptions
- All network traffic encrypted (TLS 1.2+)
- All users authenticated (OAuth 2.0 OIDC)
- Database access restricted to service IP range
- Monitoring and logging enabled on all systems

---

## 2. Data Flow Diagram

### ASCII DFD

```
┌────────────────────────────────────────────────┐
│           EXTERNAL ENTITIES                    │
│                                                │
│  User Client    Stripe API     DW Logging     │
└────────┬──────────────────┬────────────┬───────┘
         │                  │            │
         │ (1) POST order   │ (5) Charge │
         ↓                  ↓ response   ↓
     ┌──────────────────────────────────────┐
     │     Trust Boundary: Internet          │
     │  ┌────────────────────────────────┐  │
     │  │  API Gateway (auth + TLS)      │  │
     │  └────────────────┬───────────────┘  │
     │                   │ (2) /payments    │
     │                   ↓                  │
     │  ┌────────────────────────────────┐  │
     │  │ Payment Service (Node.js)      │  │
     │  │ ├─ Validate request            │  │
     │  │ ├─ Check fraud rules           │  │
     │  │ ├─ Tokenize card               │  │
     │  │ └─ Call Stripe                 │  │
     │  └──┬─────────────────────────────┘  │
     └─────┼──────────────────────────────────┘
           │ (6) Response + status
           │
     ┌─────┼──────────────────────────────────┐
     │     │ Trust Boundary: Internal Network │
     │     │                                  │
     │     ├──────────────┬──────────────┐    │
     │     ↓              ↓              ↓    │
     │  ┌────────┐  ┌──────────┐  ┌──────┐   │
     │  │Database│  │  Cache   │  │Queue │   │
     │  │(orders)│  │(Redis)   │  │(RMQ) │   │
     │  └────────┘  └──────────┘  └──────┘   │
     │     │ (3)       (4)          (7)      │
     └─────┴──────────────────────────────────┘
```

### Data Flows

| # | From | To | Data | Encryption | Authentication |
|---|------|----|------|-----------|-----------------|
| 1 | User | API GW | Order + Card | TLS 1.3 | OAuth JWT |
| 2 | API GW | Payment Service | Order + Card | mTLS | Service cert |
| 3 | Payment Service | Database | Transaction | TLS | DB user role |
| 4 | Payment Service | Cache | Status | mTLS | Service cert |
| 5 | Payment Service | Stripe | Tokenized card | TLS 1.3 | API key |
| 6 | Stripe | Payment Service | Charge response | TLS 1.3 | API key |
| 7 | Payment Service | Queue | Log event | mTLS | Service cert |

---

## 3. Assets Inventory

### Data Assets
- **Credit Card Numbers (PAN)**: In transit only (tokenized before storage)
- **Customer Name + Email**: Stored in DB (encrypted column)
- **Transaction History**: Stored in DB (encrypted column)
- **API Keys (Stripe)**: Stored in Vault (KMS encrypted)

### System Assets
- **Payment Service**: Process handling payments (no failover, critical)
- **PostgreSQL Database**: Stores orders (daily backup, replication)
- **Redis Cache**: Transaction state (ephemeral, non-critical)
- **Stripe API**: Third-party (SLA 99.9%)

### Integrity Assets
- **Audit Logs**: Immutable CloudWatch logs
- **Transaction Receipts**: Signed digital receipts

---

## 4. Trust Boundaries

```
                    INTERNET
                      │
    ┌─────────────────┴─────────────────┐
    │                                   │
    │  [Boundary: TLS encryption]       │
    │                                   │
    ├─ API Gateway (public IP)          │
    └────────────┬──────────────────────┘
                 │ mTLS
    ┌────────────┴──────────────────────┐
    │   INTERNAL NETWORK                │
    │   (K8s cluster, private VPC)      │
    │                                   │
    │  [Boundary: Network policies]     │
    │  [Boundary: mTLS cert validation] │
    │                                   │
    ├─ Payment Service (Pod)            │
    ├─ PostgreSQL Database (RDS)        │
    ├─ Redis Cache (ElastiCache)        │
    └────────────────────────────────────┘
```

**Critical Boundaries**:
1. Internet ↔ API Gateway: Encrypted + authenticated
2. Payment Service ↔ Database: mTLS + role-based access
3. Service ↔ Stripe: Encrypted + API key

---

## 5. STRIDE Threat Analysis

### S: Spoofing (Authentication)

| Threat | Component | Likelihood | Impact | CVSS | Control | Status |
|--------|-----------|-----------|--------|------|---------|--------|
| Attacker impersonates client | API Gateway | Low | High | 6.5 | JWT validation, MFA | Implemented ✓ |
| Attacker impersonates service | mTLS | Low | Critical | 9.0 | Certificate pinning | Implemented ✓ |
| Attacker forges payment receipt | Service | Medium | Medium | 6.0 | Digital signature | In Progress ⚠ |

### T: Tampering (Integrity)

| Threat | Component | Likelihood | Impact | CVSS | Control | Status |
|--------|-----------|-----------|--------|------|---------|--------|
| Attacker modifies payment amount | Service | Low | High | 7.0 | Server-side calculation | Implemented ✓ |
| Attacker tampers with auth token | Network | Low | Critical | 9.0 | Token signing (RS256) | Implemented ✓ |
| Attacker modifies DB record | Database | Very Low | Critical | 8.5 | Row-level audit triggers | Implemented ✓ |

### R: Repudiation (Non-Repudiation)

| Threat | Component | Likelihood | Impact | CVSS | Control | Status |
|--------|-----------|-----------|--------|------|---------|--------|
| Customer denies making purchase | Service | Medium | Medium | 5.0 | Immutable audit log | Implemented ✓ |
| Admin denies deleting transaction | Database | Low | High | 7.0 | CloudTrail logging | Implemented ✓ |

### I: Information Disclosure (Confidentiality)

| Threat | Component | Likelihood | Impact | CVSS | Control | Status |
|--------|-----------|-----------|--------|------|---------|--------|
| Card data leaked (PCI breach) | Service | Low | Critical | 9.0 | Tokenization, encryption | Implemented ✓ |
| Customer PII exfiltration | Database | Low | High | 8.0 | Column encryption, DLP | Partial ⚠ |
| API key leaked in logs | Logging | Medium | High | 7.5 | Secrets scanning, masking | Implemented ✓ |

### D: Denial of Service (Availability)

| Threat | Component | Likelihood | Impact | CVSS | Control | Status |
|--------|-----------|-----------|--------|------|---------|--------|
| DDoS on payment endpoint | API | Medium | High | 7.5 | Rate limiting, CDN | Implemented ✓ |
| Resource exhaustion (memory) | Service | Low | Medium | 5.0 | Memory limits, health check | Implemented ✓ |
| Database connection pool exhausted | Database | Low | High | 7.0 | Connection pooling | Implemented ✓ |

### E: Elevation of Privilege (Authorization)

| Threat | Component | Likelihood | Impact | CVSS | Control | Status |
|--------|-----------|-----------|--------|------|---------|--------|
| User accesses other user's orders | Service | Low | High | 7.5 | RBAC, row-level security | Implemented ✓ |
| Service gains root in container | Container | Very Low | Critical | 9.5 | Non-root user, seccomp | Implemented ✓ |
| Attacker escalates to admin | Database | Low | Critical | 8.5 | Least-privilege DB user | Implemented ✓ |

---

## 6. Summary & Recommendations

### Current Posture
- **Threat Count**: 18 total
  - CRITICAL: 2
  - HIGH: 6
  - MEDIUM: 10
- **Controlled**: 14/18 (78%)
- **In Progress**: 2/18
- **Risk Level**: MEDIUM

### Recommended Actions (Priority)

1. **Implement Digital Signatures** (Repudiation)
   - Timeline: 2 weeks
   - Owner: Backend Team
   
2. **Complete DLP Implementation** (Information Disclosure)
   - Timeline: 1 month
   - Owner: Security Team

3. **Annual Penetration Test** (Validation)
   - Timeline: Q2 2026
   - Owner: Security + External firm

### Approval
- [ ] Architecture Review Board approved this threat model
- [ ] Security Lead sign-off
- [ ] Next review: 2026-10-11
