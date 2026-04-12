---
description: Create an OpenAPI 3.x or AsyncAPI 3.x specification from the solution architecture.
argument-hint: "[service name] [style: 'rest' | 'graphql' | 'async']"
---

Create a formal API specification (OpenAPI, GraphQL SDL, or AsyncAPI) from the solution architecture.

## Steps

1. Read `docs/architecture/solution-architecture.md` (required).

2. Parse $ARGUMENTS to extract:
   - Service name (required)
   - API style: 'rest' (OpenAPI 3.0), 'graphql' (GraphQL SDL), or 'async' (AsyncAPI 3.0)

3. If $ARGUMENTS is incomplete, ask:
   - "Which service's API are you specifying?"
   - "What API style? (REST, GraphQL, AsyncAPI)"

4. For **REST / OpenAPI 3.0**:
   - Identify all endpoints from the solution architecture for this service.
   - For each endpoint: HTTP method, path, request schema, response schema, status codes, authentication.
   - Generate OpenAPI 3.0 YAML with:
     - Info: title, version, description
     - Servers: base URL(s)
     - Paths: endpoint definitions with operationId, parameters, requestBody, responses
     - Components: reusable schemas, securitySchemes, headers
     - Error responses: 4xx and 5xx with error schema
   - Save to `docs/tech-specs/api-spec-[service].yaml`

5. For **GraphQL / SDL**:
   - Identify queries, mutations, subscriptions from the solution architecture.
   - Define types and their fields.
   - Generate GraphQL SDL (.graphql file) with:
     - Scalar types (ID, String, Int, Float, Boolean, custom)
     - Object types with fields and descriptions
     - Query type (read operations)
     - Mutation type (write operations)
     - Subscription type (real-time updates, if applicable)
   - Save to `docs/tech-specs/api-spec-[service].graphql`

6. For **AsyncAPI 3.0**:
   - Identify channels (topics, queues) and message types.
   - Generate AsyncAPI 3.0 YAML with:
     - Info: title, version, description
     - Servers: broker URLs (Kafka, RabbitMQ, etc.)
     - Channels: topic/queue definitions with subscribe/publish
     - Messages: message schemas and payloads
     - Components: reusable schemas
   - Save to `docs/tech-specs/api-spec-[service].yaml`

7. Confirm: "API specification created → [file]. [N] endpoints/types defined."
