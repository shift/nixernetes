# Advanced Features & Validation Guide

## Overview

The Terraform Provider for Nixernetes includes advanced features for robust production deployments:

1. **Input Validation** - Comprehensive validation of all resource inputs
2. **Error Handling** - Sophisticated error classification and handling
3. **Resource Import** - Import existing Nixernetes resources into Terraform state
4. **Logging & Debugging** - Detailed logging for troubleshooting

## Input Validation

### Automatic Validation

All resource inputs are automatically validated before API requests:

```hcl
resource "nixernetes_config" "example" {
  # Name validation:
  # - Required
  # - Max 255 characters
  # - Only alphanumeric, hyphens, underscores
  # - Must start with alphanumeric
  name = "valid-config-123"

  # Configuration validation:
  # - Required
  # - Must contain valid Nix code
  configuration = file("${path.module}/config.nix")

  # Environment validation:
  # - Optional
  # - Must be: development, staging, or production
  environment = "production"
}
```

### Validation Rules by Resource

#### nixernetes_config

| Field | Required | Validation |
|-------|----------|-----------|
| `name` | Yes | 1-255 chars, alphanumeric/hyphen/underscore |
| `configuration` | Yes | Non-empty, valid Nix content |
| `environment` | No | One of: development, staging, production |

#### nixernetes_module

| Field | Required | Validation |
|-------|----------|-----------|
| `name` | Yes | 1-255 chars, alphanumeric/hyphen/underscore |
| `image` | Yes | Valid container image reference |
| `replicas` | No | Integer between 0 and 100 |
| `namespace` | No | Valid Kubernetes namespace (1-63 chars, lowercase, hyphen) |

#### nixernetes_project

| Field | Required | Validation |
|-------|----------|-----------|
| `name` | Yes | 1-255 chars, alphanumeric/hyphen/underscore |
| `description` | No | Max 1000 characters |

### Custom Validation Examples

Validate inputs before applying:

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be development, staging, or production."
  }
}

resource "nixernetes_config" "app" {
  name        = "app-config"
  configuration = file("config.nix")
  environment = var.environment
}
```

Enable strict validation in code:

```hcl
# This will fail validation if name contains invalid characters
resource "nixernetes_module" "api" {
  name  = "api-service@prod"  # Error: @ is invalid
  image = "nginx:latest"
}
```

## Error Handling

### Retryable vs Non-Retryable Errors

Errors are classified automatically:

**Non-Retryable (4xx errors):**
- 400 Bad Request - Invalid input
- 401 Unauthorized - Authentication failed
- 403 Forbidden - Access denied
- 404 Not Found - Resource doesn't exist
- 409 Conflict - Resource conflict

**Retryable (5xx errors):**
- 429 Too Many Requests - Rate limited
- 500 Internal Server Error - Server error
- 502 Bad Gateway - Temporary service issue
- 503 Service Unavailable - Maintenance
- 504 Gateway Timeout - Timeout

### Error Messages

Clear, actionable error messages:

```
Error: Invalid name
  on main.tf line 2, in resource "nixernetes_config" "example":
   2:   name = "config with spaces"

Name must contain only alphanumeric characters, hyphens, and underscores
```

### Handling Errors in Terraform

Terraform automatically handles errors with proper state management:

```bash
# Validation error - state unchanged
$ terraform apply
Error: Invalid name
  on main.tf line 2, in resource "nixernetes_config" "example":
   2:   name = "config!"
...

# API error - Terraform manages rollback
$ terraform apply
Error: Error creating configuration
  on main.tf line 1, in resource "nixernetes_config" "example":
   1:   resource "nixernetes_config" "example"

Could not create configuration, unexpected error: Server error (HTTP 500)
```

## Resource Import

Import existing Nixernetes resources into Terraform state.

### Prerequisites

- Resource must exist in the API
- You need the resource ID
- Provider configuration must be correct

### Import Configuration

```bash
# Prepare Terraform configuration file (without resource values)
cat > main.tf << 'EOF'
terraform {
  required_providers {
    nixernetes = {
      source  = "anomalyco/nixernetes"
      version = "~> 1.0"
    }
  }
}

provider "nixernetes" {
  endpoint = var.api_endpoint
  username = var.api_username
  password = var.api_password
}

resource "nixernetes_config" "imported" {
  # Leave empty - values will be populated from API
}

resource "nixernetes_module" "imported" {
  # Leave empty - values will be populated from API
}

resource "nixernetes_project" "imported" {
  # Leave empty - values will be populated from API
}
EOF
```

### Import Existing Resources

```bash
# Import a configuration
terraform import nixernetes_config.imported config-12345

# Import a module
terraform import nixernetes_module.imported module-67890

# Import a project
terraform import nixernetes_project.imported project-abcde

# Verify import
terraform state list
terraform state show nixernetes_config.imported
```

### Import with Refresh

After import, fetch current values from API:

```bash
terraform refresh
terraform state list
```

### Complete Import Example

```bash
# Step 1: Create Terraform files
mkdir -p terraform
cd terraform

# Step 2: Configure provider
cat > main.tf << 'EOF'
terraform {
  required_providers {
    nixernetes = {
      source = "anomalyco/nixernetes"
    }
  }
}

provider "nixernetes" {
  endpoint = "https://api.nixernetes.example.com"
  username = "admin"
  password = var.api_password
}

resource "nixernetes_config" "prod" {}
resource "nixernetes_module" "web" {}
resource "nixernetes_project" "main" {}
EOF

# Step 3: Import resources
terraform import nixernetes_config.prod config-prod-123
terraform import nixernetes_module.web web-server-456
terraform import nixernetes_project.main main-project-789

# Step 4: Verify and update configuration
terraform state show nixernetes_config.prod
# Copy values back to main.tf

# Step 5: Plan to verify
terraform plan  # Should show no changes
```

## Logging & Debugging

### Enable Provider Logging

```bash
# Set log level
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Run terraform
terraform apply

# View logs
tail -f terraform.log
```

### Log Levels

- `TRACE` - Most verbose, includes all operations
- `DEBUG` - Detailed information for debugging
- `INFO` - Informational messages
- `WARN` - Warning messages
- `ERROR` - Error messages only

### Debug Mode

Run provider in debug mode for development:

```bash
# Build debug binary
cd terraform-provider
go build -o terraform-provider-nixernetes-debug

# Run with debug server
TF_LOG=DEBUG ./terraform-provider-nixernetes-debug -debug

# In another terminal
export TF_REATTACH_PROVIDERS='...'
terraform plan
```

### Common Logging Patterns

```hcl
# Enable debug logging
locals {
  debug = true
}

# Log resource creation
resource "nixernetes_config" "debug" {
  name          = "debug-config"
  configuration = file("config.nix")
}

# Check logs after apply
# grep "Created configuration" terraform.log
```

## Best Practices

### 1. Validation

Always validate inputs early:

```hcl
variable "config_name" {
  type = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]+$", var.config_name))
    error_message = "Config name must be alphanumeric with hyphens/underscores."
  }
}
```

### 2. Error Handling

Implement proper error handling:

```hcl
resource "nixernetes_config" "app" {
  name          = var.config_name
  configuration = var.config_content
  environment   = var.environment

  # Terraform will retry on retryable errors
  # Non-retryable errors will fail immediately
}
```

### 3. Testing

Test validation and error cases:

```bash
# Test invalid input
terraform plan -var="config_name=invalid@name"
# Should fail with clear error

# Test missing required fields
terraform plan -var="config_name=''"
# Should fail with clear error
```

### 4. Logging in Production

```bash
# Keep logs for troubleshooting
export TF_LOG_PATH=/var/log/terraform/provider.log

# Rotate logs regularly
logrotate /etc/logrotate.d/terraform
```

## Troubleshooting

### Validation Failed

```
Error: Invalid name
  Name must contain only alphanumeric characters, hyphens, and underscores
```

Solution: Check resource name for invalid characters.

### Authentication Failed

```
Error: Authentication failed: Invalid credentials
```

Solution: Verify credentials and endpoint:
```bash
curl -u "$NIXERNETES_USERNAME:$NIXERNETES_PASSWORD" \
  "$NIXERNETES_ENDPOINT/modules"
```

### Resource Not Found

```
Error: Error reading configuration
  Could not read configuration config-123: Resource not found
```

Solution: Verify resource ID exists in API.

### Rate Limited

```
Error: Rate limited: Too many requests
```

Solution: Increase request interval or use exponential backoff.

### Server Error

```
Error: Server error: Internal server error
```

Solution: Check server logs and retry later.

## API Response Validation

The provider validates API responses:

```go
// Automatic response validation
response, err := client.Get(ctx, "/configs/123")
if err != nil {
    return nil, fmt.Errorf("failed to read config: %w", err)
}

// Response is validated to contain required fields
if response["id"] == nil {
    return nil, errors.New("API response missing id field")
}
```

## Performance Considerations

Validation is performed client-side before API requests:

- **Fast**: No network calls for validation failures
- **Safe**: Catches errors early in the workflow
- **Clear**: Users get immediate feedback

## Security

### Input Sanitization

All inputs are validated for security:

- Names: Alphanumeric only (prevents injection attacks)
- Images: Special character validation (prevents shell injection)
- Namespaces: Kubernetes rules (prevents invalid namespace injection)

### Authentication

- Credentials stored securely
- Never logged or exposed
- Always transmitted via HTTPS
- Support for environment variables

## Future Enhancements

Planned improvements:

- [ ] Custom validators framework
- [ ] Async validation
- [ ] Validation caching
- [ ] Custom error messages
- [ ] Dry-run mode
- [ ] Cost estimation

## Support

For validation and error handling issues:

1. Enable debug logging
2. Check validation rules for your resource
3. Review error message for guidance
4. Open issue with logs and configuration
