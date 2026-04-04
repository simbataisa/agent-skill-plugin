# Template: Coding Standards Document

Create in `docs/coding-standards.md` during Planning phase:

```markdown
# Coding Standards

## Language: [e.g., TypeScript]

### Naming Conventions
- **Classes:** PascalCase (`UserService`, `OrderProcessor`)
- **Functions:** camelCase (`getUserById`, `processPayment`)
- **Constants:** UPPER_SNAKE_CASE (`MAX_RETRY_ATTEMPTS`, `DEFAULT_TIMEOUT`)
- **Files:** kebab-case for exports (`user-service.ts`, `payment-processor.ts`)
- **Directories:** lowercase, plural (`services/`, `repositories/`, `controllers/`)

### Code Structure & Patterns
- **Dependency Injection:** Use framework DI container (e.g., NestJS, Spring)
- **Repository Pattern:** All database access through repositories
- **Error Handling:** Custom error classes; distinguish user errors from system errors
- **Logging:** Structured logging with context (correlation IDs for distributed tracing)
- **Configuration:** Environment variables + config service; never hardcode secrets

### Code Quality Requirements
- **Type Safety:** 100% TypeScript strict mode; no `any`
- **Null Safety:** Null checks or optional types; avoid NPE-like errors
- **Immutability:** Prefer `const` and immutable data structures
- **Function Purity:** Avoid side effects; document stateful operations
- **Complexity:** Cyclomatic complexity < 10 per function; break down complex logic

### Testing Standards
- **Unit Tests:** Every business logic function (service, repository)
- **Coverage Target:** >80% overall; >90% for critical paths
- **Test Organization:** Mirror source structure; `__tests__/` directories
- **Naming:** Descriptive test names; `test.describe` + `test.it` format
- **Test Data:** Use factories or fixtures; avoid magic numbers

### Documentation
- **JSDoc/TSDoc:** Public APIs documented with types and examples
- **README:** Service README in service root; setup, running, testing instructions
- **ADRs:** Significant decisions documented in `docs/architecture/adr/`
- **Inline Comments:** Explain "why," not "what" (code shows what)

### API Design
- **REST:** Standardized endpoints (e.g., `GET /api/v1/users/{id}`)
- **Versioning:** API version in URL path (`/v1/`, `/v2/`)
- **Error Responses:** Consistent error format with code, message, details
- **Pagination:** Cursor-based or offset-based; document in API spec
- **Rate Limiting:** Header-based; document limits in response headers

### Performance & Scalability
- **Database Queries:** No N+1 queries; use eager loading or batch queries
- **Caching:** Cache headers set; consider Redis for hot data
- **Async/Concurrency:** Async/await (don't block threads); manage connection pools
- **Monitoring:** Instrument critical paths; log latency metrics

### Security
- **Input Validation:** All user input validated; use schema validators
- **Authorization:** Enforce role-based access control (RBAC) on all endpoints
- **Secrets Management:** Never commit secrets; use secrets manager
- **HTTPS:** All communication encrypted; enforce in tests
- **SQL Injection:** Use parameterized queries (never string interpolation)

### Git & Version Control
- **Commit Messages:** Descriptive; reference story IDs (e.g., "FEAT: Implement order cancellation [STORY-123]")
- **Branch Naming:** Feature branches: `feature/story-123-short-desc`; fix branches: `fix/bug-456`
- **PR Reviews:** Minimum 1 approval; squash merges to main

### Dependency Management
- **Updates:** Regular updates to minor/patch versions; review major updates
- **Security Scanning:** Snyk or similar scans all dependencies
- **Compatibility:** Compatibility matrix for critical dependencies

### Linting & Formatting
- **Linter:** ESLint (or similar)
- **Formatter:** Prettier with 2-space indentation
- **Enforcement:** Pre-commit hooks; CI fails on lint errors
- **Rules:** [Link to ESLint config or attach rules file]

---

**Approved By:** [Tech Lead]
**Date:** [YYYY-MM-DD]
**Review Date:** [YYYY-MM-DD + 6 months]

Any deviations from these standards require Tech Lead approval and documentation.
```

