# Infrastructure as Code (IaC) Security Scanning Reference

> Reference file for the BMAD DevSecOps Engineer agent.
> Read this file when scanning Terraform, CloudFormation, Kubernetes manifests, and Helm charts for misconfigurations and security violations.

## Checkov: Comprehensive IaC Scanning

**Purpose**: Multi-cloud, multi-framework static analysis for infrastructure misconfigurations.

### Installation

```bash
# pip
pip install checkov

# Homebrew
brew install checkov

# Docker
docker pull bridgecrewio/checkov:latest
```

### Configuration (`.checkov.yaml`)

```yaml
framework:
  - terraform
  - cloudformation
  - kubernetes
  - helm
  - dockerfile

check:
  # Run specific checks
  id:
    - CKV_AWS_1
    - CKV_AZURE_2
  
  # Run checks by severity
  skip-check: []
  skip-framework: []

# Suppress checks in code
skip: false

# Baseline for existing resources
baseline: baseline.json

# Output
output: sarif
output-file: checkov-report.sarif

# Excluded directories
exclude-paths:
  - "**/test"
  - "**/node_modules"
  - "vendor/"

# External checks
external-checks-dir:
  - ./custom-checks

# Report
report:
  include-check-details: true
  print-framework: true
  compact: false
```

### Basic Usage

```bash
# Scan Terraform directory
checkov -d . -f terraform

# Scan CloudFormation template
checkov -f template.yaml -f cloudformation

# Scan Kubernetes manifests
checkov -d ./k8s -f kubernetes

# Scan multiple frameworks
checkov -d . --framework terraform,cloudformation,kubernetes

# Generate SARIF
checkov -d . -o sarif -o cli > checkov.sarif

# Generate JSON report
checkov -d . -o json > checkov-report.json

# Generate HTML report
checkov -d . -o html > checkov-report.html

# Run specific check
checkov -d . --check CKV_AWS_1

# Run all except specific checks
checkov -d . --skip-check CKV_AWS_1,CKV_AWS_2

# Exit code: 0 = pass, 1 = check failure, 2 = parse error
```

### Custom Checks

**Custom Check Example** (`custom-checks/s3_encryption.py`):
```python
from checkov.terraform.checks.resource.base_resource_check import BaseResourceCheck
from checkov.common.models.enums import CheckResult, CheckCategories

class S3PublicACL(BaseResourceCheck):
    name = "Ensure S3 bucket is not public"
    id = "CKV_AWS_CUSTOM_1"
    supported_resources = ['aws_s3_bucket']
    categories = [CheckCategories.NETWORKING]
    
    def scan_resource_conf(self, conf):
        """
        Looks for public access on S3 bucket
        """
        if 'acl' in conf:
            acl = conf['acl'][0]
            if acl in ['public-read', 'public-read-write', 'authenticated-read']:
                return CheckResult.FAILED
        
        # Check block_public_access
        if 'server_side_encryption_configuration' not in conf:
            return CheckResult.FAILED
        
        return CheckResult.PASSED

check = S3PublicACL()
```

### Checkov Configuration File Suppression

**`.checkov.yaml` example**:
```yaml
checks:
  CKV_AWS_1:  # Check ID
    suppress_on_resource:
      - aws_s3_bucket.legacy_bucket  # Resource to suppress
    suppress_comment: "Legacy bucket, encryption not required"
    suppress_until: "2025-12-31"
```

### GitHub Actions Integration

```yaml
- name: Run Checkov
  uses: bridgecrewio/checkov-action@master
  with:
    framework: terraform,cloudformation,kubernetes
    directory: .
    skip-check: CKV_AWS_1,CKV_AWS_2
    output-format: sarif
    output-file-path: checkov.sarif
    soft-fail: false  # fail if violations found

- name: Upload SARIF
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: checkov.sarif
```

---

## tfsec: Terraform-Specific Security Scanner

**Purpose**: Fast, Terraform-native vulnerability detection.

### Installation

```bash
# Homebrew
brew install tfsec

# Go
go install github.com/aquasecurity/tfsec/v1/cmd/tfsec@latest

# Docker
docker pull ghcr.io/aquasecurity/tfsec:latest
```

### Configuration

**`.tfsec.yaml`**:
```yaml
minimum_severity: WARNING
format: sarif
exclude:
  - '**/test/**'
  - '**/examples/**'

rules:
  - aws-s3-enable-versioning
  - aws-rds-enable-encryption
  - aws-ec2-require-security-group-descriptions

ignore-rules:
  - aws-iam-no-inline-policies  # We use inline for simplicity

custom-checks:
  - namespace: mycompany
    name: enforce-tags
    description: All resources must have env and team tags
    severity: WARNING
```

### Usage

```bash
# Scan Terraform directory
tfsec . -f sarif -o tfsec.sarif

# Run specific checks
tfsec . --include-rules aws-s3-enable-versioning,aws-rds-enable-encryption

# Exclude checks
tfsec . --exclude-rules aws-iam-no-inline-policies

# Run in minimal mode (fast, fewer rules)
tfsec . --minimum-severity HIGH

# Generate JSON report
tfsec . --format json > tfsec-report.json

# Check specific file
tfsec main.tf
```

### Inline Suppression

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
  acl    = "public-read"  # tfsec:ignore=aws-s3-block-public-acl
}

# Or block level
#tfsec:ignore=aws-s3-block-public-acl,aws-s3-block-public-policy
resource "aws_s3_bucket" "legacy" {
  bucket = "legacy-bucket"
}
```

---

## KICS (Keeping Infrastructure as Code Secure)

**Purpose**: Broad IaC format support (Terraform, CloudFormation, Helm, Docker, Dockerfile, K8s, etc.).

### Installation

```bash
# Homebrew
brew install kics

# Docker
docker pull checkmarx/kics:latest

# Binary
wget https://github.com/Checkmarx/kics/releases/download/v2.0.0/kics_linux_x64.zip
```

### Usage

```bash
# Scan directory
kics scan -p . -f json --output-name kics-report

# Run specific queries
kics scan -p . --queries query-id=123

# Exclude paths
kics scan -p . --exclude-paths "vendor/,test/" -f sarif

# Offline mode (no internet)
kics scan -p . --type terraform --docker false

# Generate SARIF
kics scan -p . -o sarif > kics.sarif
```

---

## Common IaC Misconfigurations

### AWS Security Groups: Open to 0.0.0.0/0

**Misconfiguration**:
```hcl
resource "aws_security_group" "bad" {
  name = "allow-all"
  
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # CRITICAL: open to internet
  }
}
```

**Remediation**:
```hcl
resource "aws_security_group" "good" {
  name = "restricted"
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/24"]  # Specific CIDR
  }
  
  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]  # From ALB only
  }
}
```

### S3 Bucket: Public Read Access

**Misconfiguration**:
```hcl
resource "aws_s3_bucket" "public_data" {
  bucket = "my-public-data"
  acl    = "public-read"  # CRITICAL
}
```

**Remediation**:
```hcl
resource "aws_s3_bucket" "private_data" {
  bucket = "my-private-data"
}

resource "aws_s3_bucket_acl" "private" {
  bucket = aws_s3_bucket.private_data.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "strict" {
  bucket = aws_s3_bucket.private_data.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### RDS: Unencrypted Storage

**Misconfiguration**:
```hcl
resource "aws_db_instance" "unencrypted" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = random_password.db.result
  # Missing: storage_encrypted = true
}
```

**Remediation**:
```hcl
resource "aws_db_instance" "encrypted" {
  allocated_storage    = 20
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t3.micro"
  username             = "admin"
  password             = random_password.db.result
  storage_encrypted    = true
  kms_key_id           = aws_kms_key.rds.arn
  backup_retention_period = 30
}
```

### EBS: Unencrypted Volume

**Misconfiguration**:
```hcl
resource "aws_ebs_volume" "bad" {
  availability_zone = "us-east-1a"
  size              = 100
  # Missing: encrypted = true
}
```

**Remediation**:
```hcl
resource "aws_ebs_volume" "good" {
  availability_zone = "us-east-1a"
  size              = 100
  encrypted         = true
  kms_key_id        = aws_kms_key.ebs.arn
}
```

### CloudTrail: Not Enabled

**Misconfiguration**:
```hcl
# No CloudTrail configured - AWS account not logging API calls
```

**Remediation**:
```hcl
resource "aws_cloudtrail" "main" {
  name           = "audit-trail"
  s3_bucket_name = aws_s3_bucket.trail.id
  
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  depends_on                    = [aws_s3_bucket_policy.trail]
}

resource "aws_s3_bucket" "trail" {
  bucket = "audit-trail-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_versioning" "trail" {
  bucket = aws_s3_bucket.trail.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "trail" {
  bucket = aws_s3_bucket.trail.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "trail" {
  bucket                  = aws_s3_bucket.trail.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
```

### IAM: Overly Permissive Policy

**Misconfiguration**:
```hcl
resource "aws_iam_role_policy" "bad" {
  name = "admin-policy"
  role = aws_iam_role.app.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"  # CRITICAL: allow everything
      Resource = "*"
    }]
  })
}
```

**Remediation**:
```hcl
resource "aws_iam_role_policy" "good" {
  name = "app-policy"
  role = aws_iam_role.app.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::my-bucket/app/*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/my-function*"
      }
    ]
  })
}
```

### Kubernetes: Missing Resource Limits

**Misconfiguration**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: bad-app
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest
        # Missing: resources section
```

**Remediation**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: good-app
spec:
  template:
    spec:
      securityContext:
        runAsNonRoot: true
        fsGroup: 65534
      containers:
      - name: app
        image: myapp:latest
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          capabilities:
            drop:
            - ALL
```

---

## Terraform Security Best Practices

### Remote State with Encryption

```hcl
terraform {
  required_version = ">= 1.0"
  
  backend "s3" {
    bucket         = "terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true  # Enable server-side encryption
    dynamodb_table = "terraform-locks"  # State locking
  }
}
```

### State Locking (DynamoDB)

```hcl
resource "aws_dynamodb_table" "terraform_locks" {
  name           = "terraform-locks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  tags = {
    Name = "Terraform Lock Table"
  }
}
```

### Workspace Isolation

```hcl
terraform {
  backend "s3" {
    bucket = "terraform-state"
    key    = "${terraform.workspace}/terraform.tfstate"
  }
}

locals {
  env = terraform.workspace
}

resource "aws_instance" "app" {
  instance_type = local.env == "prod" ? "t3.large" : "t3.micro"
  tags = {
    Environment = local.env
  }
}
```

### Module Pinning

```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"  # Pin major version
  
  name = "my-vpc"
  cidr = "10.0.0.0/16"
}

# Good: exact version
module "security_group" {
  source = "terraform-aws-modules/security-group/aws"
  version = "5.1.0"
  
  name = "app-sg"
}

# Good: git with tag
module "custom" {
  source = "git::https://github.com/myorg/terraform-modules.git//modules/app?ref=v1.0.0"
}
```

---

## Helm Chart Security

### Chart Values Schema Validation

**`values.schema.json`**:
```json
{
  "$schema": "https://json-schema.org/draft-07/schema#",
  "title": "MyApp Chart",
  "type": "object",
  "required": ["image"],
  "properties": {
    "image": {
      "type": "object",
      "required": ["repository", "tag"],
      "properties": {
        "repository": {
          "type": "string",
          "pattern": "^[a-z0-9-./]+$"
        },
        "tag": {
          "type": "string",
          "enum": ["v1.0.0", "v1.1.0", "v2.0.0"]
        },
        "pullPolicy": {
          "type": "string",
          "enum": ["Always", "IfNotPresent", "Never"]
        }
      }
    },
    "securityContext": {
      "type": "object",
      "properties": {
        "runAsNonRoot": {
          "type": "boolean",
          "const": true
        },
        "allowPrivilegeEscalation": {
          "type": "boolean",
          "const": false
        }
      },
      "required": ["runAsNonRoot", "allowPrivilegeEscalation"]
    }
  }
}
```

### OPA Policy for Helm Charts

```rego
package helm_security

deny[msg] {
  input.kind == "Pod"
  not input.spec.securityContext.runAsNonRoot
  msg = "Pods must run as non-root"
}

deny[msg] {
  input.kind == "Deployment"
  input.spec.template.spec.containers[_].securityContext.allowPrivilegeEscalation == true
  msg = "Containers cannot allow privilege escalation"
}

deny[msg] {
  input.kind == "Deployment"
  not input.spec.template.spec.containers[_].resources.limits.cpu
  msg = "Containers must define CPU limits"
}
```

---

## GitHub Actions Security

### Pinned Action Versions

**Bad**:
```yaml
- uses: actions/checkout@main  # Floating tag
- uses: docker/build-push-action@latest  # Unpredictable
```

**Good**:
```yaml
- uses: actions/checkout@c85c95e3d7251135ab7dc9d195f6300e1fc4d3b9  # SHA commit hash (best)
- uses: actions/checkout@v3  # or minor version tag
```

### OIDC Instead of Long-Lived Credentials

**Bad** (long-lived PAT):
```yaml
- uses: actions/checkout@v3
  with:
    token: ${{ secrets.GITHUB_TOKEN }}  # Personal access token stored as secret
```

**Good** (OIDC):
```yaml
- uses: actions/checkout@v3

- name: Configure AWS credentials
  uses: aws-actions/configure-aws-credentials@v2
  with:
    aws-region: us-east-1
    role-to-assume: arn:aws:iam::123456789012:role/github-oidc-role
    # No credentials stored, uses OIDC token from GitHub
```

### Minimal Permissions

```yaml
permissions:
  contents: read  # Default: if workflow needs to checkout code
  packages: write  # Only if pushing to container registry

jobs:
  build:
    permissions:
      contents: read
      packages: write
```

---

## CI Integration Example: GitHub Actions

```yaml
name: IaC Security Scan

on:
  push:
    branches: [main, develop]
    paths:
      - 'terraform/**'
      - 'k8s/**'
      - 'helm/**'
  pull_request:
    branches: [main]
    paths:
      - 'terraform/**'
      - 'k8s/**'
      - 'helm/**'

jobs:
  checkov:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      security-events: write
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run Checkov
      uses: bridgecrewio/checkov-action@master
      with:
        framework: terraform,kubernetes,helm
        directory: .
        output-format: sarif
        output-file-path: checkov.sarif
        soft-fail: false
    
    - name: Upload Checkov SARIF
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: checkov.sarif
  
  tfsec:
    runs-on: ubuntu-latest
    if: contains(github.event.pull_request.files, 'terraform')
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run tfsec
      uses: aquasecurity/tfsec-action@v1
      with:
        working_directory: terraform
        scan_directory: .
        format: sarif
        output_file: tfsec.sarif
    
    - name: Upload tfsec SARIF
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: tfsec.sarif
  
  kics:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Run KICS
      run: |
        docker run --rm -v ${{ github.workspace }}:/app checkmarx/kics:latest \
          scan -p /app -f sarif -o /app/kics-results
    
    - name: Upload KICS SARIF
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: kics-results/results.sarif

  helm-lint:
    runs-on: ubuntu-latest
    if: contains(github.event.pull_request.files, 'helm')
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Lint Helm charts
      run: |
        helm lint helm/myapp --strict --values helm/myapp/values.yaml
        helm lint helm/myapp --strict --values helm/myapp/values-prod.yaml
```

