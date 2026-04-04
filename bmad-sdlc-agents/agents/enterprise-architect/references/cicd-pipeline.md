# DevOps & CI/CD Pipeline

> Reference file for the BMAD Enterprise Architect agent.
> Read this file when designing devops & ci/cd pipeline for a project.


### Pipeline Architecture (GitHub Actions)

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  lint-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v3
        with:
          go-version: 1.21

      # Lint
      - run: go fmt ./...
      - run: go vet ./...

      # Unit tests
      - run: go test -v -cover ./...

      # Security scan (SAST)
      - uses: securego/gosec@master
        with:
          args: './...'

      # Code quality
      - uses: golangci/golangci-lint-action@v3

  build-push:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    needs: lint-test
    steps:
      - uses: actions/checkout@v3

      # Build Docker image
      - uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            ${{ secrets.ECR_REGISTRY }}/order-service:${{ github.sha }}
            ${{ secrets.ECR_REGISTRY }}/order-service:latest
          registry: ${{ secrets.ECR_REGISTRY }}

      # Scan image for vulnerabilities
      - run: |
          trivy image ${{ secrets.ECR_REGISTRY }}/order-service:${{ github.sha }}

  deploy-staging:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    needs: build-push
    steps:
      - uses: actions/checkout@v3

      - name: Update image in staging cluster
        run: |
          kubectl set image deployment/order-service \
            order-service=${{ secrets.ECR_REGISTRY }}/order-service:${{ github.sha }} \
            -n staging

      - name: Wait for rollout
        run: |
          kubectl rollout status deployment/order-service -n staging --timeout=5m

      - name: Run smoke tests
        run: |
          curl -f https://staging.company.com/api/health
          pytest tests/smoke_tests.py

  deploy-prod-canary:
    if: github.event_name == 'push' && github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    needs: deploy-staging
    environment: production  # Requires manual approval
    steps:
      - name: Canary deployment (5% traffic)
        run: |
          kubectl set image deployment/order-service \
            order-service=${{ secrets.ECR_REGISTRY }}/order-service:${{ github.sha }} \
            -n prod

          # 5% canary via traffic split (Flagger)
          kubectl patch virtualservice order-service-vs -p '{"spec":{"hosts":[{"name":"order-service","subsets":[{"name":"v1","labels":{"version":"v1"}},{"name":"v2","labels":{"version":"v2"}}]}]}}' -n prod
          # Route 5% traffic to new version

      - name: Monitor canary (5 minutes)
        run: |
          for i in {1..30}; do
            ERROR_RATE=$(curl https://prometheus.company.com/api/v1/query?query=order_service_errors_5m)
            if [ $ERROR_RATE -gt 5 ]; then
              echo "ERROR: Canary error rate too high ($ERROR_RATE%)"
              exit 1
            fi
            sleep 10
          done

      - name: Promote to 100% if canary succeeds
        run: |
          # Automatic if no errors after 5 minutes
          kubectl patch virtualservice order-service-vs -p '{"spec":{"http":[{"route":[{"destination":{"host":"order-service","subset":"v2"},"weight":100}]}]}}' -n prod

  rollback-on-failure:
    if: failure()
    runs-on: ubuntu-latest
    steps:
      - name: Automatic rollback
        run: |
          kubectl rollout undo deployment/order-service -n prod
          kubectl rollout status deployment/order-service -n prod --timeout=5m
```

### Deployment Strategy: Canary
**How it works**:
1. New version deployed alongside old version (both running)
2. 5% of traffic routed to new version for 5 minutes
3. Monitor error rate, latency, business metrics
4. If healthy: 50% → 100% (automatic)
5. If unhealthy: Automatic rollback (old version gets 100%)

**Advantages over blue-green**:
- Gradual traffic shift allows catching issues with small blast radius
- Easy rollback (just shift traffic back)
- No need to keep 2x capacity (cost-effective)

### Rollback Automation
**Automatic rollback triggers**:
- Error rate jumps > 5% within 1 minute
- P99 latency > 2x baseline (sudden spike)
- Pod crash rate > 10%
- Custom business metric (orders/sec drops 50%)

**Execution**:
```bash
kubectl rollout undo deployment/order-service -n prod
# Reverts to previous image, kills new pods, restarts old version
# Time: 30 seconds
```

### Pipeline Security
**Secrets in CI**:
- Never in code or Git (`.gitignore` enforces)
- GitHub Secrets encrypted storage
- Injected as env vars at runtime only
- Audit log: What secrets accessed when, by whom

**Who can deploy to prod**:
- Only team leads (require GitHub branch protection)
- Staging deploy: automatic (any commit to main)
- Prod deploy: manual approval (requires `environment: production` confirmation)

**Image scanning**:
- Trivy: Scans for CVEs in base images and dependencies
- Fails build if critical vuln found
- Registry scan: Re-scans images daily (updates if new vulns discovered)
```

---

