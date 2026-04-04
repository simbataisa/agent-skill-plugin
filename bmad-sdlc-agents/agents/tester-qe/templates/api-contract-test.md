# Template: API Contract Test

Create in `docs/test-plans/api-contract-tests.md`:

```markdown
# API Contract Tests — Microservice Boundaries

## Service A → Service B (Order Service → Inventory Service)

### Request Contract
```
POST /api/v1/inventory/reserve
Content-Type: application/json

{
  "orderId": "string (UUID)",
  "items": [
    {
      "sku": "string",
      "quantity": "integer (>0)"
    }
  ],
  "requestedAt": "ISO 8601 timestamp"
}
```

### Response Contract (Success)
```
HTTP 200 OK
{
  "reservationId": "string (UUID)",
  "status": "RESERVED|PARTIALLY_RESERVED",
  "reservedItems": [
    {
      "sku": "string",
      "reserved": "integer",
      "requested": "integer"
    }
  ]
}
```

### Response Contract (Failure)
- `400 Bad Request` — Validation error
- `409 Conflict` — Insufficient inventory
- `503 Service Unavailable` — Transient failure

### Contract Test Code (Pact Example)
```javascript
describe('Order → Inventory Contract', () => {
  it('should reserve inventory successfully', async () => {
    const expectedRequest = {
      orderId: expect.stringMatching(/^[0-9a-f-]+$/i),
      items: expect.arrayContaining([
        expect.objectContaining({ sku: expect.any(String), quantity: expect.any(Number) })
      ])
    };
    // Verify Service B can handle this request shape
  });
});
```

### Breaking Change Detection
- Contract version: 1.0
- Last modified: [Date]
- Changes from v0.9: [List breaking vs. non-breaking changes]
```

