# Team Conventions: [Project Name]

> Agents read this and follow these rules strictly.
> Maintained by Tech Lead.

## Version Control
- **Branch strategy:** [trunk-based / gitflow / github flow]
- **Branch naming:** `[type]/[ticket-id]-[short-description]` e.g. `feat/PROJ-123-user-auth`
- **Commit format:** [conventional commits / other] e.g. `feat(auth): add JWT refresh token`
- **PR size target:** < 400 lines changed
- **Required reviewers:** [N] approvals before merge

## Code Style
- **Formatter:** [Prettier / gofmt / black / spotless] — run on save
- **Linter:** [ESLint / golangci-lint / pylint / SonarQube]
- **Naming — files:** [kebab-case / camelCase / snake_case]
- **Naming — classes/types:** PascalCase
- **Naming — functions/vars:** camelCase (JS/TS) / snake_case (Python/Go) / camelCase (Java/Kotlin)
- **Max file length:** 300 lines (split if longer)
- **Max function length:** 40 lines (extract if longer)

## API Conventions
- **API style:** [REST / gRPC / GraphQL]
- **URL format:** `/api/v{N}/resource/{id}` e.g. `/api/v1/users/123`
- **Error format:** RFC 7807 Problem Details JSON
- **Auth header:** `Authorization: Bearer <token>`
- **Pagination:** `?page=1&limit=25` with `X-Total-Count` header

## Testing
- **Unit test coverage target:** [80]% line coverage
- **Test naming:** `should_[expected]_when_[condition]`
- **Test file location:** co-located alongside source (`*.test.ts` / `_test.go` / `test_*.py`)
- **Test data:** factories/fixtures in `tests/fixtures/`, never hardcoded

## Database
- **Migration tool:** [Flyway / Liquibase / golang-migrate / Alembic / Prisma]
- **Migration naming:** `V{N}__{description}.sql` e.g. `V001__create_users_table.sql`
- **No direct DB access from controllers** — always via repository pattern

## Documentation
- **Public APIs:** must have OpenAPI/Swagger docs
- **Complex logic:** inline comments explaining WHY not WHAT
- **ADRs required for:** any decision that affects >1 service or has long-term consequences

## Sprint / Process
- **Sprint length:** [1 / 2] weeks
- **Story point scale:** Fibonacci (1, 2, 3, 5, 8, 13)
- **Definition of Done:** code reviewed, tests passing, deployed to staging, PO accepted
- **Story size limit:** max 5 points — split if larger
