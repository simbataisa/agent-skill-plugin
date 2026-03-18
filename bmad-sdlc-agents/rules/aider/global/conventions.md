# BMAD Coding Conventions for Aider

Global conventions file for Aider code generation. Place at `~/.aider.conventions.md`.

## BMAD Framework Overview

BMAD delivers software through four phases: Business Planning (B), Machine/Architecture (M), Assembly (A), and Delivery (D). Each phase involves specialized agent roles that coordinate across teams.

## Coding Conventions from BMAD Perspective

### Test Naming

- Tests should follow the naming convention: `test_<function_or_feature>_<scenario>`
- Example: `test_user_authentication_with_valid_credentials`
- Test files placed in `tests/` or `__tests__/` directories at project root
- Follow naming conventions specified in `.bmad/team-conventions.md` if it exists

### Database Migrations

- All schema changes must use migration files (never raw SQL in code)
- Migration file naming: `YYYYMMDDHHMMSS_<description>.sql` or language-specific format
- Store migrations in `migrations/` directory
- Example: `20240315120000_create_users_table.sql`
- Tools: Flyway, Alembic, golang-migrate, or equivalent per tech stack

### API Conventions

- Follow the API style defined in `.bmad/tech-stack.md` (REST, gRPC, or GraphQL)
- REST: Use standard HTTP methods and status codes, path-based versioning (e.g., `/api/v1/...`)
- Document all endpoints with OpenAPI/Swagger or equivalent
- Request/response format consistency (e.g., camelCase, snake_case)

### Code Structure

- Organize code by feature/domain, not by technical layer
- Example structure:
  ```
  src/
    /features
      /auth
        /controllers
        /services
        /models
      /users
        /controllers
        /services
        /models
  ```

### Dependency Management

- Pin dependency versions in lock files (package-lock.json, poetry.lock, go.sum, etc.)
- Regular security audits for dependencies
- Document any custom/forked dependencies

## BMAD Agent Integration

If `.bmad/team-conventions.md` exists in the project, it takes precedence over these general conventions.

When a task aligns with a BMAD agent role, reference `agents/<role>/SKILL.md` to understand agent-specific constraints and best practices.

## Important Notes

- Always follow `.bmad/team-conventions.md` if it exists in the project — it supersedes these global conventions
- Migrations are non-negotiable for all schema changes
- API documentation is required for all new endpoints
- Tests are expected for all new features
