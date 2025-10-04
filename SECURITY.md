# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 3.0.x   | :white_check_mark: |
| 2.0.x   | :x:                |
| 1.0.x   | :x:                |

## Reporting a Vulnerability

If you discover a security vulnerability within this project, please send an email to security@example.com. All security vulnerabilities will be promptly addressed.

Please do not open a public issue for security vulnerabilities.

## Security Best Practices

### API Token Management

1. **Never hardcode API tokens** in your Terraform files
2. Use environment variables or secure secret management systems
3. Rotate API tokens regularly
4. Use least-privilege principle for token permissions

### Terraform Security

```hcl
# Good - Using variable
variable "cloudflare_api_token" {
  type      = string
  sensitive = true
}

# Bad - Hardcoded token
cloudflare_api_token = "abc123..." # NEVER DO THIS
```

### Required Cloudflare API Token Permissions

Minimum required permissions:
- `Account.Workers Scripts:Edit`
- `Zone.Workers Routes:Edit`
- `Zone.DNS:Edit` (if using DNS features)
- `Zone.Firewall Services:Edit` (if using IP allowlisting)

### State File Security

1. **Never commit state files** to version control
2. Use remote backend with encryption
3. Enable state locking to prevent concurrent modifications

```hcl
terraform {
  backend "s3" {
    encrypt = true
    # ... other config
  }
}
```

### Worker Security Features

This module implements several security features:

1. **Security Headers**: Automatically applied to all responses
   - `X-Frame-Options: DENY`
   - `X-Content-Type-Options: nosniff`
   - `Content-Security-Policy`
   - `Strict-Transport-Security`
   - `Permissions-Policy`

2. **Input Validation**: All inputs are validated
   - API key validation
   - IP address format validation
   - ISO date format validation

3. **Rate Limiting**: (Coming in v3.1.0)

4. **API Authentication**: Required for all API endpoints

### Secrets Management

#### Environment Variables

```bash
export TF_VAR_cloudflare_api_token="your-token-here"
export TF_VAR_api_key="your-api-key-here"
```

#### Terraform Cloud

Use sensitive workspace variables in Terraform Cloud.

#### AWS Secrets Manager

```hcl
data "aws_secretsmanager_secret_version" "cloudflare" {
  secret_id = "cloudflare/api-token"
}

module "maintenance" {
  source = "..."
  cloudflare_api_token = data.aws_secretsmanager_secret_version.cloudflare.secret_string
}
```

#### HashiCorp Vault

```hcl
data "vault_generic_secret" "cloudflare" {
  path = "secret/cloudflare"
}

module "maintenance" {
  source = "..."
  cloudflare_api_token = data.vault_generic_secret.cloudflare.data["api_token"]
}
```

### Network Security

#### IP Allowlisting

Always validate IP addresses:

```hcl
variable "allowed_ips" {
  type = list(string)
  validation {
    condition = alltrue([
      for ip in var.allowed_ips : can(regex("^\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}$", ip))
    ])
    error_message = "All IPs must be valid IPv4 addresses."
  }
}
```

#### CIDR Range Validation

```hcl
variable "allowed_ip_ranges" {
  type = list(string)
  validation {
    condition = alltrue([
      for cidr in var.allowed_ip_ranges : can(cidrnetmask(cidr))
    ])
    error_message = "All ranges must be valid CIDR notation."
  }
}
```

### Audit Logging

Enable Cloudflare audit logs and stream to your SIEM:

```hcl
resource "cloudflare_logpush_job" "maintenance" {
  account_id       = var.cloudflare_account_id
  name             = "maintenance-audit-logs"
  destination_conf = "s3://your-bucket/logs"
  dataset          = "audit_logs"
  frequency        = "high"
}
```

### Compliance

This module supports compliance with:

- **GDPR**: No personal data is logged by default
- **SOC2**: All changes are tracked via Terraform
- **PCI DSS**: No payment card data is processed
- **HIPAA**: Can be configured for healthcare environments

### Security Checklist

Before deploying to production:

- [ ] API tokens stored securely (not in code)
- [ ] State files encrypted and stored remotely
- [ ] IP allowlist configured for admin access
- [ ] Security headers enabled
- [ ] API authentication configured
- [ ] Audit logging enabled
- [ ] Regular token rotation scheduled
- [ ] Least-privilege IAM policies
- [ ] Network segmentation configured
- [ ] Monitoring and alerting setup

## Security Updates

Security updates are released as patch versions. Subscribe to GitHub releases to be notified of updates.

## Contact

- Security issues: security@example.com
- General support: support@example.com
- GitHub Security Advisories: [Enable notifications](https://github.com/thomasvincent/terraform-cloudflare-maintenance/security/advisories)