# Running Nixernetes Tests in CI/CD

This guide explains how to integrate Nixernetes testing into your CI/CD pipeline.

## Quick Reference

```bash
# Run all tests
nix flake check

# Run specific test
nix build .#checks.x86_64-linux.yaml-validation

# Run tests in dev shell
nix develop -c bash tests/run-tests.sh
```

## GitHub Actions

Create `.github/workflows/test.yml`:

```yaml
name: Nixernetes Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Required for git-based tests
      
      - uses: cachix/install-nix-action@v25
        with:
          nix_path: nixpkgs=channel:nixos-unstable
      
      - uses: cachix/cachix-action@v12
        with:
          name: nixernetes
          authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
      
      - name: Run tests
        run: |
          nix flake check --print-build-logs
      
      - name: Build example app
        run: |
          nix build .#example-app
```

## GitLab CI

Create `.gitlab-ci.yml`:

```yaml
test:
  image: nixos/nix:latest
  script:
    - nix flake check --print-build-logs
  cache:
    paths:
      - .cache

build:
  image: nixos/nix:latest
  script:
    - nix build .#example-app
  artifacts:
    paths:
      - result/
```

## Jenkins

Create a `Jenkinsfile`:

```groovy
pipeline {
  agent any
  
  stages {
    stage('Test') {
      steps {
        sh 'nix flake check'
      }
    }
    
    stage('Build') {
      steps {
        sh 'nix build .#example-app'
      }
    }
  }
  
  post {
    always {
      archiveArtifacts artifacts: 'result/**/*'
    }
  }
}
```

## Local Development

### Pre-commit Hook

Save as `.git/hooks/pre-commit`:

```bash
#!/bin/bash
set -e

echo "Running Nixernetes tests..."
nix flake check

echo "✓ All tests passed!"
```

Make it executable:
```bash
chmod +x .git/hooks/pre-commit
```

### Makefile

```makefile
.PHONY: test
test:
	@echo "Running Nixernetes tests..."
	nix flake check

.PHONY: dev
dev:
	nix develop

.PHONY: fmt
fmt:
	nix fmt

.PHONY: build
build:
	nix build .#example-app

.PHONY: clean
clean:
	rm -rf result/
```

Usage:
```bash
make test    # Run tests
make fmt     # Format code
make build   # Build example
make dev     # Enter dev shell
```

## Docker-based CI

Create `Dockerfile.test`:

```dockerfile
FROM nixos/nix:latest

WORKDIR /app
COPY . .

RUN nix flake check
RUN nix build .#example-app

CMD ["nix", "flake", "check"]
```

Build and run:
```bash
docker build -f Dockerfile.test -t nixernetes-test .
docker run nixernetes-test
```

## Test Parallelization

By default, `nix flake check` runs checks sequentially. To parallelize:

```bash
# Use multiple cores (adjust -j to match CPU count)
nix flake check --max-jobs 4

# Let Nix auto-detect
nix flake check --max-jobs auto
```

## Performance Tips

1. **Enable Binary Cache**
   ```bash
   nix flake check --builders 'ssh-ng://builder@remote'
   ```

2. **Skip Certain Checks During Development**
   ```bash
   # Run only YAML validation
   nix build .#checks.x86_64-linux.yaml-validation
   ```

3. **Commit Changes Before Testing**
   - Tests require files to be in git
   ```bash
   git add .
   git commit -m "feat: add feature"
   nix flake check
   ```

## Troubleshooting CI Failures

### "path does not exist"
**Cause**: Test files not committed to git
**Fix**: `git add tests/ && git commit -m "Add tests"`

### "ModuleNotFoundError: yaml"
**Cause**: Python dependencies missing
**Fix**: Ensure dev shell includes `python3Packages.pyyaml`

### Timeout during checks
**Cause**: Limited resources
**Fix**: Run with `--max-jobs 1` or increase timeout

### Cache misses
**Cause**: Using different Nix version or system
**Fix**: Set up binary cache or use `nix flake update`

## Viewing Test Results

### Summary
```bash
nix flake check 2>&1 | grep -E "(✓|✗|passed|failed)"
```

### Detailed Output
```bash
nix flake check --print-build-logs
```

### Save to File
```bash
nix flake check 2>&1 | tee test-results.log
```

## Running Specific Test Suites

```bash
# Only YAML validation
nix build .#checks.x86_64-linux.yaml-validation -L

# Only module tests
nix build .#checks.x86_64-linux.module-tests -L

# Only integration tests
nix build .#checks.x86_64-linux.integration-tests -L

# Only example build
nix build .#checks.x86_64-linux.example-app-build -L
```

## Environment Variables

Set these to customize test behavior:

```bash
# Increase logging
export NIX_LOG_FD=2
nix flake check

# Show what's being built
export VERBOSE=1
nix flake check

# Skip format check
export SKIP_FORMAT=1
nix flake check
```

## Integration with Package Managers

### Terraform Testing (Future)
```bash
# Validate that generated Kubernetes manifests work
terraform plan -out=tfplan
nix flake check
terraform apply tfplan
```

### Helm Testing (Future)
```bash
# Generate Helm charts and validate
helm lint generated-charts/
nix flake check
helm install test generated-charts/
```

## Next Steps

1. **Set up CI/CD** - Choose your platform above and implement
2. **Configure caching** - Speed up builds with binary cache
3. **Monitor results** - Track test metrics over time
4. **Expand tests** - Add domain-specific tests

## Support Resources

- [Nix Flakes Documentation](https://nixos.wiki/wiki/Flakes)
- [GitHub Actions + Nix](https://github.com/cachix/install-nix-action)
- [GitLab CI + Nix](https://docs.gitlab.com/ee/ci/)
- [Cachix Binary Cache](https://cachix.org/)

## Questions?

For issues with CI/CD integration:
1. Check the `docs/TESTING.md` for test suite details
2. Review your CI logs for specific errors
3. Test locally with `nix flake check` first
4. Verify files are committed to git
