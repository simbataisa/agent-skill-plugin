# Observability Architecture

> Reference file for the BMAD Enterprise Architect agent.
> Read this file when designing observability architecture for a project.

---

## Observability Philosophy

Observability is the ability to understand what a system is doing internally by examining its external outputs. The three pillars are **Metrics, Logs, and Traces** — but they are only useful when **correlated** via a shared context: `trace_id`, `span_id`, and `service.name`.

**OpenTelemetry (OTel) is the standard.** All new services MUST use the OTel SDK for instrumentation. OTel provides a single, vendor-neutral API for all three signals. The OTel Collector acts as the central gateway: services emit to the Collector; the Collector fans out to backends (Prometheus, Loki/Elasticsearch, Tempo/Jaeger).

```
Services
  │  (OTLP/gRPC or OTLP/HTTP)
  ▼
OTel Collector (agent sidecar or gateway deployment)
  ├── Metrics  ──→  Prometheus / Mimir (remote write)
  ├── Logs     ──→  Loki / Elasticsearch
  └── Traces   ──→  Tempo / Jaeger
                         │
                    Grafana (unified UI — query all three signals in one place)
```

**Key principle:** A single `trace_id` MUST appear in logs, metrics exemplars, and trace spans for the same request. This is what enables "click on a metric spike → find the trace → open the logs for that trace" in one workflow.

---

## 1. OpenTelemetry Setup & Instrumentation

### SDK Initialisation (per language)

#### Java (Spring Boot)
```xml
<!-- pom.xml -->
<dependency>
  <groupId>io.opentelemetry.instrumentation</groupId>
  <artifactId>opentelemetry-spring-boot-starter</artifactId>
</dependency>
```
```yaml
# application.yaml
otel:
  service:
    name: order-service                    # MUST match service.name in all signals
  exporter:
    otlp:
      endpoint: http://otel-collector:4317 # gRPC endpoint
      protocol: grpc
  traces:
    sampler: parentbased_traceidratio
    sampler-arg: "0.1"                     # 10% in prod; 100% in staging (see sampling section)
  logs:
    exporter: otlp                         # Export logs via OTel too (not just traces)
  metrics:
    exporter: otlp
```

#### Go
```go
// main.go
import (
  "go.opentelemetry.io/otel"
  "go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc"
  sdktrace "go.opentelemetry.io/otel/sdk/trace"
)

func initOtel(ctx context.Context) *sdktrace.TracerProvider {
  exp, _ := otlptracegrpc.New(ctx,
    otlptracegrpc.WithEndpoint("otel-collector:4317"),
    otlptracegrpc.WithInsecure(),
  )
  tp := sdktrace.NewTracerProvider(
    sdktrace.WithBatcher(exp),
    sdktrace.WithResource(resource.NewWithAttributes(
      semconv.SchemaURL,
      semconv.ServiceName("order-service"),
      semconv.ServiceVersion("1.4.2"),
      attribute.String("deployment.environment", "production"),
    )),
    sdktrace.WithSampler(sdktrace.ParentBased(sdktrace.TraceIDRatioBased(0.1))),
  )
  otel.SetTracerProvider(tp)
  otel.SetTextMapPropagator(propagation.NewCompositeTextMapPropagator(
    propagation.TraceContext{}, // W3C TraceContext (preferred)
    propagation.Baggage{},
  ))
  return tp
}
```

#### Python (FastAPI)
```python
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

provider = TracerProvider(resource=Resource.create({
    SERVICE_NAME: "analytics-service",
    "deployment.environment": "production",
}))
provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint="otel-collector:4317")))
trace.set_tracer_provider(provider)
FastAPIInstrumentor.instrument_app(app)  # auto-instruments all routes
```

### OTel Collector Configuration
```yaml
# otel-collector-config.yaml
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318

processors:
  batch:
    timeout: 1s
    send_batch_size: 1024
  memory_limiter:
    check_interval: 1s
    limit_mib: 512
  resource:                          # Enrich all signals with common attributes
    attributes:
      - action: upsert
        key: cluster.name
        value: "prod-eks-us-east-1"
  filter/drop_health:                # Drop noisy health-check spans
    traces:
      span:
        - 'attributes["http.target"] == "/health"'
        - 'attributes["http.target"] == "/readyz"'

exporters:
  prometheusremotewrite:
    endpoint: "http://prometheus:9090/api/v1/write"
    add_metric_suffixes: false
  loki:
    endpoint: "http://loki:3100/loki/api/v1/push"
    default_labels_enabled:
      exporter: false
      job: true
    labels:
      resource:
        service.name: "service_name"
        deployment.environment: "env"
  otlp/tempo:
    endpoint: "tempo:4317"
    tls:
      insecure: true

service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, filter/drop_health, batch, resource]
      exporters: [otlp/tempo]
    metrics:
      receivers: [otlp]
      processors: [memory_limiter, batch, resource]
      exporters: [prometheusremotewrite]
    logs:
      receivers: [otlp]
      processors: [memory_limiter, batch, resource]
      exporters: [loki]
```

### Context Propagation (W3C TraceContext)
All HTTP requests between services MUST propagate the `traceparent` header (W3C Trace Context standard). OTel SDKs do this automatically when auto-instrumentation is active.

```
traceparent: 00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01
             ^^  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ ^^^^^^^^^^^^^^^^ ^^
             version   trace-id (128-bit)         span-id (64-bit) flags
```

For async messaging (Kafka, AMQP), inject the TraceContext into message headers:
```java
// Kafka producer — inject trace context into headers
OtlpKafkaHeadersInjector.inject(tracer.currentSpan().context(), record.headers());

// Kafka consumer — extract and resume the trace
SpanContext parentCtx = OtlpKafkaHeadersExtractor.extract(record.headers());
try (Scope scope = tracer.withSpan(tracer.spanBuilder("consume-order-event")
    .setParent(Context.current().with(Span.wrap(parentCtx)))
    .startSpan())) {
  // process message — this span is linked to the producer's trace
}
```

---

## 2. Structured Logging — OTel Log Pattern

### Mandatory Log Format (JSON)

Every log line MUST be structured JSON. Free-text logs are not permitted in production services. The following fields are REQUIRED in every log record:

```json
{
  "timestamp":   "2026-04-11T09:15:32.847Z",    // ISO-8601 UTC — use OTel TimeUnixNano internally
  "severity":    "INFO",                          // TRACE | DEBUG | INFO | WARN | ERROR | FATAL
  "severity_number": 9,                           // OTel SeverityNumber (INFO=9, WARN=13, ERROR=17)
  "service.name": "order-service",               // OTel Resource attribute — MUST match SDK config
  "service.version": "1.4.2",                    // Deployed artifact version
  "deployment.environment": "production",         // production | staging | dev
  "trace_id":    "4bf92f3577b34da6a3ce929d0e0e4736",  // OTel trace_id — links log to trace
  "span_id":     "00f067aa0ba902b7",              // OTel span_id — pinpoints the exact span
  "trace_flags": "01",                            // 01 = sampled
  "body":        "Order created successfully",    // Human-readable message — concise, no PII
  "attributes": {                                 // Domain-specific context — structured, searchable
    "user.id":       "usr-7f3a9c",               // hashed/pseudonymised — never raw PII
    "order.id":      "ord-00419827",
    "order.total":   99.99,
    "order.currency":"USD",
    "http.method":   "POST",
    "http.route":    "/api/v2/orders",
    "http.status_code": 201,
    "latency_ms":    47,
    "db.system":     "postgresql",               // if DB call was involved
    "db.operation":  "INSERT",
    "messaging.system": "kafka",                 // if message was published
    "messaging.destination": "orders.created"
  }
}
```

### Severity Levels — When to Use

| Level | Severity # | When to Use | Action Required |
|-------|-----------|-------------|-----------------|
| `TRACE` | 1–4 | Extremely verbose — step-by-step internal state. **Never in prod.** | None |
| `DEBUG` | 5–8 | Development/staging only — variable values, branch decisions. Disable in prod by default. | None |
| `INFO` | 9–12 | Normal operational events — request received, order created, payment processed, job started/finished. | None |
| `WARN` | 13–16 | Unexpected but recoverable — retry triggered, degraded dependency, config value fallback used, queue lag building. | Monitor; alert if sustained |
| `ERROR` | 17–20 | Operation failed — exception caught, request could not be fulfilled, data inconsistency detected. Include stack trace and full context. | Alert on-call if rate > threshold |
| `FATAL` | 21–24 | Service is about to crash — unrecoverable state. Always followed by process exit. | Immediate page |

### Log Pattern Rules

**Rule 1 — trace_id is mandatory for all request-scoped logs.**
Logs without `trace_id` cannot be correlated to a trace. The OTel SDK injects `trace_id` and `span_id` automatically into the MDC (Java: Logback/Log4j2) or context vars (Python, Go). Never log without extracting the current span context.

```java
// Java — Logback with OTel agent auto-injects trace_id into MDC
// In logback-spring.xml pattern:
// %X{trace_id} %X{span_id} automatically populated by OTel Logback appender
import io.opentelemetry.api.trace.Span;

log.info("Order created", Map.of(
    "order.id", order.getId(),
    "user.id", user.getAnonymisedId(),   // NEVER raw email/name/SSN
    "order.total", order.getTotal()
));
// trace_id and span_id injected automatically by OTel Logback appender
```

```go
// Go — extract span from context and add to logger fields
span := trace.SpanFromContext(ctx)
logger.InfoContext(ctx, "order created",
    slog.String("trace_id", span.SpanContext().TraceID().String()),
    slog.String("span_id",  span.SpanContext().SpanID().String()),
    slog.String("order.id", order.ID),
    slog.Float64("order.total", order.Total),
)
```

```python
# Python — structlog + OTel
import structlog
from opentelemetry import trace

def get_trace_ctx():
    span = trace.get_current_span()
    ctx = span.get_span_context()
    return {
        "trace_id": format(ctx.trace_id, "032x") if ctx.is_valid else "",
        "span_id":  format(ctx.span_id,  "016x") if ctx.is_valid else "",
    }

log = structlog.get_logger()
log.info("order.created", **get_trace_ctx(),
         order_id=order.id, total=order.total)
```

**Rule 2 — No PII in log bodies or attributes.**
User email, full name, phone, address, payment card numbers MUST NOT appear in logs. Use:
- Hashed/pseudonymised user IDs: `usr-7f3a9c` not `jane.doe@example.com`
- Truncated/masked values: `card: ****4242` not the full PAN
- Log the *fact* of an action, not the sensitive *content*: `"message": "Password reset email sent"` not `"email": "jane@example.com"`

**Rule 3 — Errors MUST include exception detail and context.**
```json
{
  "severity": "ERROR",
  "body": "Failed to process payment",
  "attributes": {
    "order.id": "ord-00419827",
    "payment.provider": "stripe",
    "error.type": "StripeApiException",
    "error.message": "Your card was declined.",
    "error.stack_trace": "com.example.PaymentService.charge(PaymentService.java:142)\n...",
    "http.status_code": 402,
    "retry.attempt": 2,
    "retry.max": 3
  },
  "trace_id": "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id":  "00f067aa0ba902b7"
}
```

**Rule 4 — Attribute naming follows OTel Semantic Conventions.**
Use standard attribute names so backends can auto-interpret them:
```
http.method, http.route, http.status_code, http.url
db.system, db.name, db.operation, db.statement (sanitised — no param values)
messaging.system, messaging.destination, messaging.operation
rpc.system, rpc.service, rpc.method
user.id (hashed), session.id
exception.type, exception.message, exception.stacktrace
```
Custom domain attributes use `<domain>.<attribute>` namespacing: `order.id`, `payment.provider`, `inventory.sku`.

**Rule 5 — Never log inside a tight loop.**
Log at the boundary (start/end of the operation), not per-iteration. Use metrics (counters/histograms) to track per-item statistics.

**Rule 6 — Structured log appender config (Java Logback example)**
```xml
<!-- logback-spring.xml -->
<appender name="OTLP" class="io.opentelemetry.instrumentation.logback.appender.v1_0.OpenTelemetryAppender">
  <captureCodeAttributes>true</captureCodeAttributes>
  <captureMarkerAttribute>true</captureMarkerAttribute>
</appender>
<appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
  <encoder class="net.logstash.logback.encoder.LogstashEncoder">
    <!-- Adds trace_id / span_id from MDC automatically -->
    <includeMdcKeyName>trace_id</includeMdcKeyName>
    <includeMdcKeyName>span_id</includeMdcKeyName>
    <includeMdcKeyName>trace_flags</includeMdcKeyName>
  </encoder>
</appender>
<root level="INFO">
  <appender-ref ref="OTLP"/>   <!-- ship to OTel Collector -->
  <appender-ref ref="STDOUT"/> <!-- local/container stdout for kubectl logs -->
</root>
```

---

## 3. Metrics — RED + USE + Business Signals

### Instrumentation Layers

#### Layer 1 — RED Metrics (per service, auto-instrumented by OTel)
```
Rate:     http_server_request_total{service, method, route, status_code}
Errors:   http_server_request_total{status_code=~"5.."}
Duration: http_server_request_duration_seconds{service, method, route} — histogram (P50/P95/P99)
```

#### Layer 2 — USE Metrics (per resource — infrastructure)
```
Utilisation:  container_cpu_usage_seconds_total, container_memory_working_set_bytes
Saturation:   kube_node_status_condition{condition="MemoryPressure"}, kubelet_running_pods
Errors:        container_oom_events_total, kube_pod_container_status_restarts_total
```

#### Layer 3 — Database Metrics
```
pg_stat_statements_mean_exec_time_ms   — query latency per statement
pg_replication_lag_seconds             — replication delay (alert if > 30s)
pg_stat_activity_count                 — active connections
pg_database_size_bytes                 — storage growth
redis_connected_clients                — connection pool health
redis_keyspace_hits_total / redis_keyspace_misses_total  — cache hit rate
```

#### Layer 4 — Messaging Metrics
```
kafka_consumer_lag_sum{group, topic}   — consumer group lag (alert if > 10K)
kafka_producer_request_rate            — producer throughput
kafka_consumer_fetch_rate              — consumer throughput
```

---

## 4. Business Metrics Monitoring

Business metrics measure outcomes that matter to the organisation — not just whether the system is up, but whether it is delivering value. They bridge the gap between technical SLOs and business health.

### Why Business Metrics in Observability?

Correlated with traces and logs, business metrics can answer:
- "Did the P99 latency spike at 14:00 cause a drop in checkout completions?"
- "When we deployed v2.3, did conversion rate improve or degrade?"
- "Is this data inconsistency causing revenue to be miscounted?"

### Business Metric Categories

#### Commerce / Transactional
| Metric | Description | Alert Condition |
|--------|-------------|-----------------|
| `orders_created_total` | Count of orders placed. Rate tracked per minute/hour. | Rate drops > 30% vs 7-day baseline |
| `orders_failed_total` | Orders that failed to complete (by reason: payment, inventory, timeout). | Failure rate > 2% |
| `revenue_processed_usd_total` | Gross revenue flowing through the system. | Drops > 20% vs 1h moving avg |
| `checkout_started_total` | Sessions that initiated checkout. | — |
| `checkout_completed_total` | Sessions that completed checkout. Conversion = completed/started. | Conversion < 60% of baseline |
| `cart_abandonment_rate` | `1 - (checkout_completed / checkout_started)`. | Spike > 10% above baseline |
| `refunds_initiated_total` | Refund volume — early signal of product/fulfilment issues. | Rate > 1% of orders |

#### User Engagement
| Metric | Description | Alert Condition |
|--------|-------------|-----------------|
| `active_users_total{window="1h"}` | Unique active users per time window. | Drop > 25% vs same hour prior week |
| `feature_usage_total{feature}` | Events per feature (e.g., `feature="bulk-export"`). | — (trend analysis) |
| `session_duration_seconds` | Histogram of user session lengths. | P50 drops > 30% |
| `new_registrations_total` | User sign-ups per period. | — |
| `login_failures_total` | Failed login attempts (security + UX signal). | Rate > 5% of attempts → alert security |

#### SLA / SLO Business Signals
| Metric | Description | SLO Target |
|--------|-------------|-----------|
| `slo_availability_ratio{service}` | `(successful_requests / total_requests)` over rolling window. | ≥ 99.9% (3 nines) |
| `slo_latency_p99_seconds{service}` | P99 request latency. | ≤ 0.5s |
| `error_budget_remaining_ratio` | `1 - (error_rate / (1 - slo_target))`. | Alert when < 20% remaining in window |

#### Financial / Billing
| Metric | Description |
|--------|-------------|
| `payments_processed_total{provider, status}` | Payment attempts, successes, failures per provider. |
| `payment_gateway_latency_seconds` | Histogram — latency to payment provider (Stripe, Adyen). |
| `subscription_renewals_total{plan}` | Subscription renewal successes/failures per plan tier. |
| `invoice_generation_total{status}` | Invoicing pipeline health. |

### Defining Business Metrics in Code

Business metrics MUST carry the same OTel context so they can be correlated with traces:

```java
// Java — Spring Boot with OTel Metrics + Micrometer
@Service
public class OrderService {
    private final Counter ordersCreated;
    private final Counter ordersFailed;
    private final DistributionSummary orderValue;

    public OrderService(MeterRegistry registry) {
        this.ordersCreated = Counter.builder("orders.created.total")
            .description("Total orders successfully created")
            .tag("currency", "USD")
            .register(registry);

        this.ordersFailed = Counter.builder("orders.failed.total")
            .description("Total orders that failed to complete")
            .register(registry);

        this.orderValue = DistributionSummary.builder("order.value.usd")
            .description("Order value distribution")
            .baseUnit("usd")
            .publishPercentiles(0.5, 0.95, 0.99)
            .register(registry);
    }

    public Order createOrder(CreateOrderRequest req) {
        Span span = tracer.spanBuilder("order.create")
            .setAttribute("order.currency", req.getCurrency())
            .startSpan();
        try (Scope scope = span.makeCurrent()) {
            Order order = processOrder(req);
            ordersCreated.increment();
            orderValue.record(order.getTotalUsd());
            span.setAttribute("order.id", order.getId());
            span.setAttribute("order.total", order.getTotalUsd());
            return order;
        } catch (Exception e) {
            ordersFailed.increment(Tags.of("reason", e.getClass().getSimpleName()));
            span.recordException(e).setStatus(StatusCode.ERROR);
            throw e;
        } finally {
            span.end();
        }
    }
}
```

```go
// Go — OTel Metrics API
import "go.opentelemetry.io/otel/metric"

var (
    ordersCreated, _ = meter.Int64Counter("orders.created.total",
        metric.WithDescription("Total orders successfully created"))
    ordersRevenue, _ = meter.Float64Histogram("order.value.usd",
        metric.WithDescription("Order value in USD"),
        metric.WithExplicitBucketBoundaries(1, 5, 10, 25, 50, 100, 500, 1000))
)

func (s *OrderService) CreateOrder(ctx context.Context, req *CreateOrderRequest) (*Order, error) {
    ctx, span := tracer.Start(ctx, "order.create",
        trace.WithAttributes(attribute.String("order.currency", req.Currency)))
    defer span.End()

    order, err := s.process(ctx, req)
    if err != nil {
        ordersCreated.Add(ctx, 1, metric.WithAttributes(attribute.String("status", "failed")))
        span.RecordError(err)
        span.SetStatus(codes.Error, err.Error())
        return nil, err
    }

    ordersCreated.Add(ctx, 1, metric.WithAttributes(attribute.String("status", "success")))
    ordersRevenue.Record(ctx, order.TotalUSD,
        metric.WithAttributes(attribute.String("payment.method", order.PaymentMethod)))
    span.SetAttributes(attribute.String("order.id", order.ID), attribute.Float64("order.total", order.TotalUSD))
    return order, nil
}
```

### Business Metrics Dashboards

**Business Health Dashboard** (product owners, executives — refresh every 5 minutes):
```
Row 1 — Revenue & Orders
  ├─ Orders/min (current vs 7-day avg)      [time series]
  ├─ Revenue/hour (current vs 7-day avg)    [time series]
  ├─ Checkout conversion rate               [gauge + sparkline]
  └─ Cart abandonment rate                  [gauge]

Row 2 — User Activity
  ├─ Active users (1h window)              [stat panel]
  ├─ New registrations today               [stat panel]
  ├─ Feature usage breakdown               [bar chart by feature]
  └─ Session duration P50/P95              [histogram]

Row 3 — Payment Health
  ├─ Payment success rate by provider      [table: Stripe, Adyen, ...]
  ├─ Payment gateway P99 latency           [time series]
  └─ Refund rate (% of orders)             [time series + alert band]

Row 4 — SLO / Error Budget
  ├─ Availability SLO (30-day rolling)     [gauge — green/yellow/red]
  ├─ Latency SLO (P99 < 500ms)            [gauge]
  └─ Error budget remaining (%)            [gauge — alert < 20%]
```

**Business Alerting Rules** (notify product channel, not on-call pager):
```yaml
# prometheus/rules/business.yaml
groups:
  - name: business
    rules:
      - alert: OrderRateDrop
        expr: |
          rate(orders_created_total[5m])
          < 0.7 * avg_over_time(rate(orders_created_total[5m])[1d:5m])
        for: 5m
        labels:
          severity: warning
          team: product
        annotations:
          summary: "Order rate dropped >30% vs 24h average"
          runbook: "https://wiki/runbooks/order-rate-drop"

      - alert: CheckoutConversionDrop
        expr: |
          (
            rate(checkout_completed_total[15m]) /
            rate(checkout_started_total[15m])
          ) < 0.55
        for: 10m
        labels:
          severity: warning
          team: product
        annotations:
          summary: "Checkout conversion below 55%"

      - alert: PaymentFailureRateHigh
        expr: |
          rate(payments_processed_total{status="failed"}[5m]) /
          rate(payments_processed_total[5m]) > 0.03
        for: 3m
        labels:
          severity: critical
          team: payments
        annotations:
          summary: "Payment failure rate > 3%"

      - alert: ErrorBudgetLow
        expr: error_budget_remaining_ratio < 0.20
        for: 0m
        labels:
          severity: warning
          team: platform
        annotations:
          summary: "SLO error budget below 20% — deployment freeze recommended"
```

---

## 5. Distributed Tracing

### Trace Sampling Strategy

| Environment | Strategy | Config |
|-------------|----------|--------|
| Development | Always-on | `OTEL_TRACES_SAMPLER=always_on` |
| Staging | Always-on | `OTEL_TRACES_SAMPLER=always_on` |
| Production | Parent-based + ratio | `OTEL_TRACES_SAMPLER=parentbased_traceidratio` + `OTEL_TRACES_SAMPLER_ARG=0.05` (5%) |
| Production — critical paths | Head-based always-on | Force sample via baggage flag `sampling.priority=1` set at entry point (API gateway) |
| Production — errors | Tail-based (in Collector) | OTel Collector `tailsamplingprocessor` — always keep traces with ERROR spans |

**Tail-based sampling in Collector (recommended for prod):**
```yaml
# collector config — keep all error traces, sample happy paths at 5%
processors:
  tail_sampling:
    decision_wait: 10s
    policies:
      - name: error-traces
        type: status_code
        status_code: { status_codes: [ERROR] }
      - name: high-latency
        type: latency
        latency: { threshold_ms: 2000 }
      - name: happy-path-sample
        type: probabilistic
        probabilistic: { sampling_percentage: 5 }
```

### Span Design Rules

1. **One span per meaningful operation** — a DB query, a downstream service call, a Kafka produce/consume, a complex computation. Not one span per line of code.
2. **Span names should be low-cardinality** — `"order.create"` not `"create order ord-00419827"`. Put high-cardinality values in span attributes.
3. **Always record exceptions on spans** — `span.recordException(e)` + `span.setStatus(StatusCode.ERROR, e.getMessage())`.
4. **Propagate context across async boundaries** — Kafka headers, job queues, async threads must carry the `traceparent`.

### Example Trace — Order Creation
```
POST /api/v2/orders  [api-gateway, 134ms]
  trace_id: 4bf92f3577b34da6a3ce929d0e0e4736
  │
  ├─ order.validate [order-service, 8ms]
  │    attributes: user.id=usr-7f3a9c, items.count=3
  │
  ├─ inventory.check [order-service → inventory-service, gRPC, 22ms]
  │    ├─ db.query SELECT stock [inventory-service → PostgreSQL, 18ms]
  │    └─ cache.get  [inventory-service → Redis, 1ms]  ← cache miss
  │
  ├─ payment.authorise [order-service → payment-service, 65ms]
  │    ├─ stripe.charge [payment-service → Stripe API, 58ms]
  │    └─ db.insert payment_record [payment-service → PostgreSQL, 4ms]
  │
  ├─ db.insert order [order-service → PostgreSQL, 11ms]
  │
  └─ kafka.produce orders.created [order-service → Kafka, 3ms]
       messagingsystem: kafka
       messaging.destination: orders.created
```

---

## 6. Correlation Workflow — Metrics → Traces → Logs

The following workflow enables "click-to-investigate" in Grafana across all three signals:

### Step 1 — Spot anomaly on metric dashboard
A spike on `http_server_request_duration_seconds p99` for `order-service` at 14:23 UTC.

### Step 2 — Click metric exemplar → jump to trace
Prometheus histograms support **exemplars** — each histogram bucket stores a sample `trace_id` from a real request in that bucket. Click the exemplar data point in Grafana → opens Tempo trace viewer.

```java
// Java — recording a metric with an exemplar (auto-done by OTel Micrometer bridge)
// The OTel SDK automatically attaches trace_id to histogram observations
// when a span is active. No extra code required.
```

### Step 3 — Inspect the trace
Identify which span was slow (e.g., `stripe.charge` took 2.1s). See all span attributes: `payment.provider=stripe`, `order.id=ord-00419827`, `user.id=usr-7f3a9c`.

### Step 4 — Jump to logs for that trace
Grafana Loki or Elasticsearch: query `{trace_id="4bf92f3577b34da6a3ce929d0e0e4736"}` → see all log lines emitted during that exact request, in chronological order, from every service involved.

### Step 5 — Correlate with business metric
Check the business dashboard: during the same 14:20–14:30 window, was there a checkout conversion dip? Does the `stripe.charge` slowness pattern match the stripe payment failure alert?

---

## 7. Alerting — Full Rule Set

### Critical Alerts (page on-call immediately)
```yaml
- Error rate > 5% (5-min window)
- P99 latency > 1000ms (5-min window)
- API Gateway / load balancer unreachable
- Database replication lag > 30s
- Disk space < 10% free on any node
- Pod crash-looping: restarts > 5 in 5 minutes
- Kafka consumer lag > 100K messages sustained 10 min
- Error budget remaining < 5% (emergency freeze)
```

### Warning Alerts (Slack notification — do not page)
```yaml
- Error rate > 2% (10-min window)
- P95 latency > 500ms
- Memory usage > 80% per container
- Cache hit rate < 75%
- Kafka consumer lag > 10K messages
- Error budget remaining < 20%
- Certificate expiry < 30 days
- Deployment rollout stalled > 10 minutes
```

### Business Alerts (product Slack channel — do not page engineering)
```yaml
- Order rate drop > 30% vs 24h baseline (5-min window)
- Checkout conversion < 55% (15-min window)
- Payment failure rate > 3% (3-min window)
- Revenue/hour drop > 20% vs moving average
- New user registration drop > 40% vs weekly baseline
```

### Escalation Policy
```
Critical alert fires
  → Page primary on-call (PagerDuty / OpsGenie)
  → Unacknowledged after 5 min → page secondary on-call
  → Unacknowledged after 15 min → page engineering manager
  → All critical alerts auto-link to runbook in annotation
```

---

## 8. Dashboards

### Operations Dashboard (on-call engineer — real-time, 1-min refresh)
- Error rate & P99 latency per service (heatmap)
- Pod count, node health, OOM events
- Database replication status, connection pool saturation
- Kafka consumer lag per consumer group
- Active incidents + alert status

### Service Dashboard (per-service, dev team — 5-min refresh)
- RED metrics: requests/sec, error rate, latency P50/P95/P99
- Dependency health: downstream services, DB, cache, message queues
- Recent deployments (annotation overlay on all graphs)
- JVM / Go runtime metrics (GC pause, goroutine count, heap usage)

### Business Dashboard (product owners / execs — 5-min refresh)
- Orders/min and revenue/hour vs 7-day trend
- Checkout conversion funnel
- Payment success rate by provider
- Active users and feature adoption
- SLO availability gauge + error budget remaining

### SLO / Error Budget Dashboard (platform team — 1-hour refresh)
- 30-day rolling availability per service
- Error budget burn rate (fast burn = urgent investigation)
- Historical SLO compliance per quarter

---

## 9. Retention Policy

| Signal | Production | Staging | Dev |
|--------|-----------|---------|-----|
| Metrics (raw) | 15 days | 7 days | 1 day |
| Metrics (downsampled 5m) | 90 days | 14 days | — |
| Metrics (downsampled 1h) | 2 years | — | — |
| Logs | 30 days | 7 days | 1 day |
| Audit logs | 7 years (compliance) | 30 days | 7 days |
| Traces | 72 hours | 24 hours | 1 hour |

Audit logs (security events, admin actions, data access) are shipped to an **immutable log store** (AWS S3 Object Lock, or Worm-protected Elasticsearch index) and retained per regulatory requirement (SOC2: 1 year; PCI-DSS: 1 year; GDPR audit trail: varies).

---

## 10. Quick Reference — OTel Instrumentation Checklist

Every new service MUST satisfy all items before going to production:

- [ ] OTel SDK initialised with `service.name`, `service.version`, `deployment.environment`
- [ ] OTLP exporter configured → OTel Collector endpoint
- [ ] W3C TraceContext propagation enabled (HTTP headers + Kafka message headers)
- [ ] Auto-instrumentation active for HTTP server, HTTP client, DB driver, messaging
- [ ] Structured JSON logging with `trace_id` and `span_id` injected per log record
- [ ] No PII in log bodies or span attributes
- [ ] RED metrics instrumented: request rate, error rate, duration histogram
- [ ] Business metrics instrumented: at least one counter for primary business event (order created, payment processed, user registered, etc.)
- [ ] Business metric alerts configured in Prometheus rules
- [ ] Exemplars enabled on histograms (links metric spike → trace)
- [ ] Tail-sampling policy reviewed — errors and high-latency spans always retained
- [ ] Service dashboard created in Grafana with RED metrics + dependency health
- [ ] Runbook linked in all critical alert annotations
- [ ] Log retention verified in Loki / Elasticsearch index policy
