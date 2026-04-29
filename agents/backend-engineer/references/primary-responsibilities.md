# Backend Engineer Primary Responsibilities

> Load this reference for detailed patterns across each responsibility area.

### 1. Implement Services and APIs

**Mandate:** Transform story requirements into working API implementations.

- Read implementation stories from `docs/stories/` to understand requirements, acceptance criteria, and dependencies
- Reference the **Solution Architecture** (`docs/architecture/solution-architecture.md`) to understand service topology and boundaries
- Implement API endpoints following the **OpenAPI contract** defined in `docs/tech-specs/api-spec.md`
- Use consistent request/response schemas, error codes, and HTTP semantics
- Implement proper HTTP status codes (200, 201, 400, 401, 403, 404, 409, 422, 500, 503)
- Include detailed error responses with problem statement bodies (RFC 7807)

**Example workflow:**
1. Pick a story from the backlog (e.g., "User Registration Service")
2. Check solution architecture for service boundaries and dependencies
3. Read the story for functional requirements and acceptance criteria
4. Implement the service with all required endpoints
5. Add unit and integration tests
6. Document in implementation notes

### 2. Data Layer and Persistence

**Mandate:** Design and implement robust, scalable data access patterns.

- Review `docs/tech-specs/data-model.md` for entity definitions, relationships, and constraints
- Implement database migrations using version-controlled migration scripts
- Use ORM patterns (or query builders) consistently across the service
- Implement repository/data access layer abstractions
- Handle transactions correctly for multi-step operations
- Implement soft deletes, audit trails, and temporal data patterns where required
- Optimize queries and add database indexes for performance-critical paths
- Document complex queries and business logic in comments

**Data layer checklist:**
- [ ] Migrations are idempotent and reversible
- [ ] Entity relationships model business rules correctly
- [ ] Indexes exist on frequently queried fields
- [ ] N+1 query problems are avoided
- [ ] Transactions ensure consistency for multi-step operations
- [ ] Audit trails capture who changed what and when

### 3. Authentication & Authorization

**Mandate:** Implement secure identity and access control following enterprise standards.

- Implement JWT-based authentication or OAuth 2.0 flows as specified in tech specs
- Validate tokens and propagate identity context through request lifecycle
- Implement role-based access control (RBAC) or attribute-based access control (ABAC)
- Use middleware to enforce authorization on protected endpoints
- Hash passwords using industry-standard algorithms (bcrypt, scrypt, or Argon2)
- Implement token refresh, revocation, and expiration logic
- Log security-relevant events (failed logins, privilege escalations)
- Document authentication/authorization architecture in implementation notes

**Security requirements:**
- Never store plaintext passwords
- Validate all user inputs
- Use HTTPS in all environments
- Implement rate limiting on authentication endpoints
- Follow the principle of least privilege

### 4. Message Queues and Event-Driven Patterns

**Mandate:** Implement asynchronous communication and event-driven architecture.

- Review `docs/tech-specs/integration-spec.md` for event contracts and queue definitions
- Implement event producers (publish domain events)
- Implement event consumers (subscribe and handle events)
- Use message brokers (RabbitMQ, Apache Kafka, AWS SQS/SNS) as specified
- Handle message ordering, idempotency, and replay semantics
- Implement dead-letter queues for failed messages
- Add monitoring and alerting for queue depths and processing latency
- Document event schemas and choreography flows

**Event-driven checklist:**
- [ ] Events are immutable, well-versioned records of facts
- [ ] Consumers are idempotent (can handle duplicate messages)
- [ ] Dead-letter queue handling prevents message loss
- [ ] Schema versioning supports forward/backward compatibility
- [ ] Consumer lag is monitored and alerted

### 5. Logging, Observability, and Monitoring

**Mandate:** Instrument code for production observability.

- Use structured logging (JSON format) consistently across all services
- Log at appropriate levels: DEBUG, INFO, WARN, ERROR
- Include request IDs and correlation IDs in all logs for traceability
- Implement distributed tracing (OpenTelemetry, Jaeger) integration
- Add business metrics (counters, histograms, gauges) for domain events
- Implement health checks and liveness probes for container orchestration
- Document what metrics and logs are emitted and why

**Observability pattern:**
```
Request enters → Assign correlation ID → Log entry point (INFO)
  → Trace through service → Log key decisions (DEBUG)
  → Record metrics (counter, latency)
  → Log any errors with context (ERROR)
  → Return response → Log exit (INFO)
```

### 6. Error Handling and Resilience

**Mandate:** Build reliable services that degrade gracefully.

- Use typed exceptions/errors and catch only what you can handle
- Wrap errors with context; never lose the root cause
- Implement retry logic with exponential backoff for transient failures
- Implement circuit breakers for calls to external services
- Use timeouts on all network calls (database, HTTP, message queue)
- Implement bulkheads to isolate failure domains
- Return appropriate error responses to callers (not internal stack traces)
- Log errors with sufficient context for diagnosis

**Resilience pattern:**
```go
// Example pseudocode
func CallExternalService(ctx context.Context) (*Response, error) {
  // 1. Check circuit breaker
  if !circuitBreaker.AllowRequest() {
    return nil, ErrServiceUnavailable
  }

  // 2. Add timeout
  ctx, cancel := context.WithTimeout(ctx, 5*time.Second)
  defer cancel()

  // 3. Attempt with retry
  var lastErr error
  for attempt := 0; attempt < 3; attempt++ {
    resp, err := http.Do(req.WithContext(ctx))
    if err == nil {
      circuitBreaker.RecordSuccess()
      return resp, nil
    }
    lastErr = err
    if attempt < 2 {
      time.Sleep(time.Duration(math.Pow(2, float64(attempt))) * time.Second)
    }
  }

  circuitBreaker.RecordFailure()
  return nil, fmt.Errorf("service call failed after retries: %w", lastErr)
}
```

### 7. Testing Strategy

**Mandate:** Ensure code quality through comprehensive testing.

**Unit Tests:**
- Test individual functions/methods in isolation
- Mock external dependencies (databases, HTTP clients, message queues)
- Aim for >80% code coverage on business logic
- Test both happy path and error cases
- Use table-driven tests for multiple scenarios

**Integration Tests:**
- Test service behavior with real or containerized dependencies (e.g., PostgreSQL, Redis)
- Test API contract compliance (status codes, response schemas)
- Test data persistence and retrieval
- Test message queue producer/consumer flows

**Contract Tests:**
- Verify API compliance with OpenAPI spec
- Test request/response validation against schemas
- Verify error response formats

**Testing checklist:**
- [ ] Unit test coverage >80% for business logic
- [ ] Integration tests verify database operations
- [ ] API contract tests validate OpenAPI compliance
- [ ] Error paths are tested
- [ ] Concurrent operations are tested where applicable
- [ ] Tests are deterministic and isolated

### 8. Performance Optimization

**Mandate:** Deliver services that scale efficiently.

- Profile and identify bottlenecks (database, CPU, memory, I/O)
- Optimize hot paths: database queries, serialization, loop iterations
- Implement caching strategies (in-process, Redis) with appropriate TTLs
- Use connection pooling for database and HTTP connections
- Batch operations where possible (e.g., bulk inserts)
- Avoid N+1 query problems; use joins and eager loading
- Monitor memory usage and garbage collection
- Document performance-critical decisions in implementation notes

**Performance checklist:**
- [ ] Database queries have been profiled and indexes added
- [ ] Connection pooling is configured correctly
- [ ] Caching is implemented for frequently accessed data
- [ ] Large operations are batched
- [ ] Response latency meets SLA requirements

