# Cross-System Integration Strategy

> Reference file for the BMAD Enterprise Architect agent.
> Read this file when designing cross-system integration strategy for a project.


### Integration Inventory

| System | Type | Direction | Protocol | SLA |
|--------|------|-----------|----------|-----|
| Billing Platform (NetSuite) | External | Order Service → NetSuite | REST API | Async, nightly batch, 24-hour tolerance |
| Warehouse Management | Internal (legacy) | Inventory Service ↔ WMS | SFTP + message queue | Sync, < 5 sec latency required |
| CRM (Salesforce) | External | User Service → Salesforce | REST API, webhooks | Async, 1-hour batch + webhooks for high-priority events |
| Payment Gateway (Stripe) | External | Order Service → Stripe | REST API | Sync, timeout 10s, fallback queue |
| Analytics (Segment) | Internal | All services → Segment | Event API | Async, fire-and-forget, some data loss acceptable |
| Email Service (Sendgrid) | External | Notification Service → Sendgrid | SMTP + REST | Async, 30-minute queue before retry exhaustion |

### Data Synchronization Patterns

#### Order → Billing Platform (NetSuite)
- **Pattern**: Event-driven ETL (Kafka → Lambda → NetSuite API)
- **Trigger**: Order Service publishes `OrderConfirmed` event
- **Flow**:
  1. Event consumed by ETL Lambda (runs every 5 minutes)
  2. Transform Order data to NetSuite invoice format
  3. POST to NetSuite API
  4. If failure (network timeout, 5xx error): Retry with exponential backoff (5s, 25s, 125s)
  5. If exhausted: Log to DLQ, alert ops team for manual remediation
- **Idempotency**: NetSuite API call includes unique `orderId` as idempotency key

#### Inventory ↔ Warehouse Management System (WMS)
- **Pattern**: Bidirectional sync (2 APIs, change data capture)
- **Inventory → WMS**: Stock reservation published as event; WMS API polled every 10s for updates
- **WMS → Inventory**: Webhook from WMS on stock receipt; fallback: poll WMS API every 5 minutes
- **Conflict resolution**: Inventory Service is source of truth; WMS is cache (can be rebuilt from Inventory API)

#### User Events → Salesforce CRM
- **Pattern**: Batch + realtime
- **Realtime**: High-priority events (new user signup, VIP purchase)
  - User Service publishes `UserCreated` event
  - Lambda transforms and creates Contact in Salesforce immediately
- **Batch**: Low-priority events (profile updates)
  - Daily job exports all user updates from past 24 hours
  - Upsert into Salesforce (keyed by email address)
- **Handling drift**: Weekly reconciliation job (count records in each system, alert if > 5% mismatch)

### Handling External API Failures
**Stripe Payment Failure Scenario**:
- POST to Stripe times out (network issue, Stripe down)
- Order Service: Retry queue (exponential backoff up to 3 retries over 5 minutes)
- After 3 retries: Mark order as `payment_pending`, publish `PaymentRetrying` event
- Notification Service: Send customer email "Payment processing may take 10 minutes"
- Reconciliation job (runs hourly): Check Stripe API for any pending charges, update order status

**Salesforce API Rate Limit**:
- Salesforce allows 10,000 API calls per hour
- Rate limiting strategy:
  - Batch updates: Collect 100 updates per call (vs. 1 update per call)
  - Async queue: Limit to 100 calls/minute (distributes throughout day)
  - Alert: If queue depth exceeds 1000 (indicates we're hitting limit)
```

### 4. Technology Radar & Standardization
Define the enterprise's approved technology choices and evolution path.

**What you produce:**
- **Technology radar** — Adopt, trial, assess, hold (why each technology is in each ring)
- **Language standardization** — Approved languages, team distribution
- **Approved frameworks/libraries** — What should new projects use?
- **Deprecated technologies** — What we're moving away from and timeline
- **Architectural patterns** — Approved: microservices, event-driven; Discouraged: monoliths, monolithic databases

**Why:** Without standardization, teams pick different databases, languages, and frameworks. This fragments knowledge and operational expertise.

**Example output:**

```markdown
