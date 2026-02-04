# Validation and Error Handling Guide

Comprehensive validation system for Nixernetes configurations with detailed error messages and helpful suggestions.

## Overview

Nixernetes provides multi-level validation to catch errors early:

1. **File Validation** - Check file existence, permissions, syntax
2. **Configuration Validation** - Verify required fields and types
3. **Deployment Validation** - Check deployment specifications
4. **Nix Evaluation** - Run nix flake checks

## Validation Modes

### Basic Validation

```bash
nixernetes validate
```

Checks for critical errors only. Warnings are displayed but don't fail validation.

### Strict Validation

```bash
nixernetes validate --strict
```

Treats all warnings as errors. Useful for production deployments.

### Detailed Validation

```bash
nixernetes validate --detailed
```

Shows extensive information about validation steps, including context and suggestions.

## Error Codes

### E001: CONFIG_NOT_FOUND

**Message:** Configuration file not found

**Causes:**
- Wrong file path
- File was deleted
- Typo in filename

**Solutions:**
```bash
# Verify file exists
ls -la config/main.nix

# Use absolute path
nixernetes validate --config $(pwd)/config/main.nix

# Create new config
nixernetes init my-project
```

### E002: INVALID_CONFIG

**Message:** Configuration format is invalid

**Causes:**
- Wrong file extension
- Malformed configuration
- Missing required fields

**Solutions:**
```bash
# Check file extension
ls -la config/*.nix

# Validate syntax
nixernetes validate --detailed

# Review example
cat docs/EXAMPLES/example-simple-web.md
```

### E003: SYNTAX_ERROR

**Message:** Configuration contains syntax errors

**Causes:**
- Unclosed quotes or braces
- Missing semicolons
- Invalid Nix syntax

**Solutions:**
```bash
# Check syntax carefully
nixernetes validate --detailed --strict

# Review Nix syntax documentation
man nix-language

# Use strict validation
nixernetes validate --strict
```

### E004: VALIDATION_FAILED

**Message:** Configuration validation failed

**Causes:**
- Missing required fields
- Invalid field values
- Type mismatches

**Solutions:**
```bash
# Run detailed validation
nixernetes validate --detailed

# Review module documentation
nixernetes docs BATCH_PROCESSING

# Check example configuration
cat starters/simple-web/config.nix
```

### E005: DEPLOYMENT_FAILED

**Message:** Deployment to Kubernetes failed

**Causes:**
- Cluster unreachable
- Invalid resources
- Insufficient permissions

**Solutions:**
```bash
# Check cluster connection
kubectl cluster-info

# Verify authentication
kubectl auth can-i create deployments

# Run dry-run first
nixernetes deploy --dry-run

# Check cluster status
kubectl get nodes
```

### E006: NETWORK_ERROR

**Message:** Network communication failed

**Causes:**
- Kubernetes cluster offline
- Network timeout
- DNS resolution failed

**Solutions:**
```bash
# Check Kubernetes cluster
kubectl cluster-info dump

# Verify network
ping kubernetes.default.svc.cluster.local

# Check connectivity
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
```

### E007: PERMISSION_DENIED

**Message:** Permission denied accessing resource

**Causes:**
- File not readable
- Insufficient cluster permissions
- Directory access denied

**Solutions:**
```bash
# Fix file permissions
chmod 644 config/main.nix

# Check Kubernetes RBAC
kubectl auth can-i create deployments

# Fix directory permissions
chmod 755 config/
```

### E008: RESOURCE_CONFLICT

**Message:** Resource already exists or conflicts with existing resource

**Causes:**
- Duplicate resource names
- Resource already deployed
- Conflicting configurations

**Solutions:**
```bash
# Check existing resources
kubectl get all

# Remove conflicting resource
kubectl delete deployment my-app

# Use different name
sed -i 's/my-app/my-app-v2/g' config/main.nix
```

### E009: TIMEOUT

**Message:** Operation timed out

**Causes:**
- Slow network
- Cluster overloaded
- Long deployment time

**Solutions:**
```bash
# Increase timeout
nixernetes deploy --timeout 600

# Check cluster resources
kubectl top nodes

# Monitor deployment
kubectl rollout status deployment/my-app
```

### E999: UNKNOWN_ERROR

**Message:** Unexpected error occurred

**Causes:**
- Unexpected condition
- Software bug
- System error

**Solutions:**
```bash
# Run with debug information
nixernetes validate --debug

# Check logs
journalctl -u nixernetes

# Report issue
https://github.com/anomalyco/nixernetes/issues/new
```

## Error Messages

Each error includes:

1. **Error Code** - Unique identifier (E001, E002, etc.)
2. **Message** - Clear description of the problem
3. **Location** - File, line, and column if applicable
4. **Context** - Code snippet showing the issue
5. **Suggestion** - How to fix the problem

### Example Error Output

```
✗ E004: Validation failed: missing required field 'image'
  at config/main.nix:45:3

  Context:
    containers = [{
      ports = [{ containerPort = 8080; }];
    }];

  Suggestion:
    Add the 'image' field to each container:
    
    containers = [{
      image = "myrepo/app:latest";  # Add this line
      ports = [{ containerPort = 8080; }];
    }];
```

## Validation API

### Python

```python
from src.validation import ConfigurationValidator, ErrorLevel

# Create validator
validator = ConfigurationValidator(strict=True)

# Validate file
is_valid = validator.validate_file("config/main.nix")

# Get results
print(validator.report())

# Check errors
for error in validator.errors:
    print(f"Error: {error.message}")
    print(f"Location: {error.file}:{error.line}")
    if error.suggestion:
        print(f"Fix: {error.suggestion}")
```

### Command Line

```bash
# Basic validation
nixernetes validate

# With options
nixernetes validate \
  --strict \
  --detailed \
  --config config/production.nix

# JSON output
nixernetes validate --format json > validation-report.json
```

## Best Practices

### 1. Validate Early and Often

```bash
# After each change
nixernetes validate

# Before deployment
nixernetes validate --strict
```

### 2. Use Strict Mode for Production

```bash
# Development - basic validation
nixernetes validate

# Production - strict validation
nixernetes validate --strict --detailed
```

### 3. Review Error Suggestions

Every error includes actionable suggestions. Follow them to fix issues quickly.

### 4. Use Examples as Reference

```bash
# Find example similar to your use case
ls docs/EXAMPLES/

# Review the example
cat docs/EXAMPLES/example-3-nodejs-microservices.md

# Use starter kit
nixernetes template create microservices my-app
```

### 5. Check Cluster State

Before deploying, verify the cluster is ready:

```bash
# Check nodes
kubectl get nodes

# Check resources
kubectl top nodes

# Check existing resources
kubectl get all --all-namespaces
```

## Troubleshooting

### Validation hangs

```bash
# Cancel with Ctrl+C
# Then try again with timeout
timeout 30 nixernetes validate
```

### Cryptic error messages

```bash
# Get more details
nixernetes validate --detailed --debug

# Check specific file
nixernetes validate --config config/main.nix --detailed
```

### Nix evaluation errors

```bash
# Test nix evaluation directly
nix eval ./config/main.nix --json

# Check flake
nix flake check

# Check specific module
nix eval ./src/lib/kubernetes-core.nix
```

## Getting Help

- **Detailed output:** `nixernetes validate --detailed`
- **Debug mode:** `nixernetes validate --debug`
- **Documentation:** `nixernetes docs BATCH_PROCESSING`
- **Examples:** `ls docs/EXAMPLES/`
- **Issues:** [GitHub Issues](https://github.com/anomalyco/nixernetes/issues)
- **Discussions:** [GitHub Discussions](https://github.com/anomalyco/nixernetes/discussions)
