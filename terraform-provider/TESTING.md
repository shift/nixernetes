# Testing Guide for Terraform Provider for Nixernetes

This guide covers testing strategies for the Terraform provider for Nixernetes.

## Testing Structure

The provider includes three types of tests:

1. **Unit Tests** - Test individual functions and components
2. **Acceptance Tests** - Test full resource lifecycle against a real or mock API
3. **Example Tests** - Verify example Terraform configurations work correctly

## Unit Tests

Unit tests verify individual functions in isolation using mock servers.

### Running Unit Tests

```bash
# Run all unit tests
make test

# Run specific test
go test -v -run TestPostRequest

# Run with coverage
go test -v -cover ./...
```

### Client Unit Tests (`client_test.go`)

Tests for the HTTP client implementation:

- `TestPostRequest` - Verify POST requests work with correct headers and auth
- `TestGetRequest` - Verify GET requests function properly
- `TestPutRequest` - Verify PUT requests handle updates
- `TestDeleteRequest` - Verify DELETE requests work
- `TestErrorHandling` - Verify error responses are handled correctly
- `TestAuthenticationFailure` - Verify auth errors are caught
- `TestContextCancellation` - Verify context cancellation is respected

Example:
```go
func TestPostRequest(t *testing.T) {
    // Create mock server
    server := httptest.NewServer(...)
    defer server.Close()
    
    // Create client
    client := &NixernetesClient{
        Endpoint: server.URL,
        Username: "testuser",
        Password: "testpass",
    }
    
    // Make request
    result, err := client.Post(context.Background(), "/configs", body)
    
    // Assert results
    if err != nil {
        t.Fatalf("Unexpected error: %v", err)
    }
}
```

## Acceptance Tests

Acceptance tests perform full create/read/update/delete cycles against the API.

### Prerequisites

Before running acceptance tests:

1. Start a Nixernetes API server or mock server
2. Set environment variables:
   ```bash
   export NIXERNETES_ENDPOINT="https://localhost:8080"
   export NIXERNETES_USERNAME="admin"
   export NIXERNETES_PASSWORD="password"
   ```

### Running Acceptance Tests

```bash
# Run all acceptance tests
make testacc

# Run specific acceptance test
TF_ACC=1 go test -v -run TestAccConfigResource

# Run with timeout
TF_ACC=1 go test -v -timeout=10m ./...
```

### Test Cases

#### TestAccConfigResource

Tests the complete lifecycle of a configuration resource:

1. **Create** - Creates a new configuration with Nix content
2. **Read** - Verifies the configuration is readable
3. **Update** - Updates the environment from development to staging
4. **Delete** - Verifies deletion works

```hcl
resource "nixernetes_config" "test" {
  name          = "test-config"
  configuration = file("./config.nix")
  environment   = "development"
}
```

Assertions:
- ID is set
- Name matches input
- created_at timestamp exists
- updated_at timestamp updates on change

#### TestAccModuleResource

Tests the complete lifecycle of a module resource:

1. **Create** - Creates a module with 2 replicas
2. **Read** - Verifies the module is readable
3. **Update** - Scales to 3 replicas
4. **Delete** - Verifies deletion works

```hcl
resource "nixernetes_module" "test" {
  name      = "test-module"
  image     = "nginx:latest"
  replicas  = 2
  namespace = "default"
}
```

Assertions:
- ID is set
- Replica count updates
- Image is preserved
- Namespace is set correctly

#### TestAccProjectResource

Tests the complete lifecycle of a project resource:

1. **Create** - Creates a new project
2. **Read** - Verifies the project is readable
3. **Update** - Updates the description
4. **Delete** - Verifies deletion works

```hcl
resource "nixernetes_project" "test" {
  name        = "test-project"
  description = "Test project"
}
```

Assertions:
- ID is set
- Name and description are preserved
- Status is set
- Timestamps are created

#### TestAccModulesDataSource

Tests the modules data source:

```hcl
data "nixernetes_modules" "test" {}
```

Assertions:
- Returns a list of modules
- Each module has id, name, description, version

#### TestAccProjectsDataSource

Tests the projects data source:

```hcl
data "nixernetes_projects" "test" {}
```

Assertions:
- Returns a list of projects
- Each project has id, name, status

## Example Tests

Example configurations demonstrate proper usage and serve as test fixtures.

### Complete Example (`examples/complete.tf`)

A comprehensive example showing:

- Configuration deployment
- Multiple module instances
- Project creation
- Resource dependencies
- Output definitions

Run with:
```bash
cd terraform-provider/examples
terraform plan -var-file=test.tfvars
terraform apply -var-file=test.tfvars
```

## Mock API Server

For testing without a real API, use the built-in mock server:

```go
import "net/http/httptest"

server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
    // Handle requests
    json.NewEncoder(w).Encode(response)
}))
defer server.Close()

client := &NixernetesClient{
    Endpoint: server.URL,
    Username: "test",
    Password: "test",
}
```

## Continuous Integration

Tests run automatically on GitHub Actions:

1. **Unit Tests** - Run on every push and pull request
2. **Acceptance Tests** - Run on main branch (requires API credentials)
3. **Linting** - Format and static analysis checks

See `.github/workflows/test.yml` for the full CI configuration.

## Common Test Issues

### Authentication Failures

If tests fail with 401 Unauthorized:

```bash
# Verify credentials
echo $NIXERNETES_USERNAME
echo $NIXERNETES_PASSWORD

# Check API is running
curl -u $NIXERNETES_USERNAME:$NIXERNETES_PASSWORD $NIXERNETES_ENDPOINT/modules
```

### Timeout Issues

If tests timeout:

```bash
# Increase timeout
TF_ACC=1 go test -v -timeout=15m ./...

# Check API latency
time curl $NIXERNETES_ENDPOINT/health
```

### State Conflicts

If tests fail with state conflicts:

```bash
# Clean up test artifacts
rm -rf .terraform
rm -rf .terraform.lock.hcl
```

## Performance Testing

To benchmark provider performance:

```bash
go test -bench=. -benchmem ./...
```

## Code Coverage

Generate coverage reports:

```bash
# Generate coverage
go test -v -coverprofile=coverage.out ./...

# View coverage
go tool cover -html=coverage.out

# Check specific package coverage
go test -coverprofile=coverage.out ./client
go tool cover -html=coverage.out
```

### Coverage Goals

- Unit tests: 80% minimum
- Acceptance tests: Cover all resource CRUD operations
- Overall: 75% minimum across provider

## Testing Checklist

Before submitting a PR:

- [ ] All unit tests pass: `make test`
- [ ] Code is formatted: `make fmt`
- [ ] Linting passes: `make lint`
- [ ] Acceptance tests pass (if applicable): `make testacc`
- [ ] Coverage is adequate: `go test -cover ./...`
- [ ] Example configurations work: `terraform validate examples/`
- [ ] Documentation is updated

## Debugging Tests

Enable verbose logging:

```bash
# Enable terraform logging
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log

# Run tests
TF_ACC=1 go test -v -run TestAccConfigResource

# View logs
tail -f terraform.log
```

Enable go test verbose mode:

```bash
go test -v -run TestPostRequest ./...
```

Use print debugging in tests:

```go
t.Logf("Debug info: %+v", variable)
```

## Resources

- [Terraform Plugin Framework Testing](https://developer.hashicorp.com/terraform/plugin/framework/testing)
- [Go Testing Package](https://golang.org/pkg/testing/)
- [Terraform Acceptance Testing](https://developer.hashicorp.com/terraform/plugin/sdkv2/testing/acceptance-testing)
- [httptest Package](https://golang.org/pkg/net/http/httptest/)

## Support

For testing issues:

1. Check the [Testing Checklist](#testing-checklist)
2. Enable debug logging
3. Review test examples
4. Open an issue on GitHub with logs and reproduction steps
