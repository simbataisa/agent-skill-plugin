# Template: Performance Test Plan

Create in `docs/test-plans/performance-test-plan.md`:

```markdown
# Performance Testing Plan

## Non-Functional Requirements (from PRD)
- Response time (P95): < 200ms for typical requests
- Throughput: 1000 req/sec sustained
- Error rate: < 0.1% under load
- Database query time: < 50ms
- Cache hit rate: > 90% for read-heavy operations

## Test Scenarios

### Scenario 1: Steady-State Load
- Ramp: 0 → 1000 req/sec over 5 minutes
- Duration: 30 minutes at steady state
- Assertion: P95 < 200ms, error rate < 0.1%

### Scenario 2: Spike Test
- Baseline: 500 req/sec
- Spike: Jump to 2000 req/sec for 2 minutes
- Assertion: No cascading failures, recovery within 5 min

### Scenario 3: Soak Test
- Load: 500 req/sec
- Duration: 24 hours
- Assertion: No memory leaks, latency doesn't degrade

### Scenario 4: Stress Test
- Ramp: 1000 → 5000 req/sec
- Duration: 10 minutes
- Assertion: Identify breaking point and graceful degradation

## Test Environment
- Isolated staging cluster (production-like)
- Representative data volume
- External service mocks (to isolate infrastructure)
- Monitoring: CPU, memory, disk, network, JVM (if applicable)

## Tools & Execution
- Load test tool: k6, JMeter, or Gatling
- CI/CD integration: Run nightly before release
- Baseline: [Previous release metrics for comparison]

## Success Criteria
- All scenarios meet latency targets
- No error rate spikes above threshold
- Resource utilization reasonable (CPU < 80%)
- Database doesn't become bottleneck
```

