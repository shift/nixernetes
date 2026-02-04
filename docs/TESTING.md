# Nixernetes Integration Test Suite

This document describes the comprehensive test suite for validating Nixernetes manifests and modules.

## Overview

The integration test suite is composed of:
1. **Python YAML Validation Tests** - Validates generated Kubernetes manifests
2. **Nix Module Interaction Tests** - Tests module functionality and interactions
3. **Automated Test Checks** - Integrated into `nix flake check`

## Running Tests

### Quick Start

```bash
# Enter dev shell
cd /home/shift/code/ideas/nixernetes
nix develop

# Run all checks
nix flake check
```

### Individual Test Suites

#### Python YAML Validation Tests

```bash
# Run YAML validation tests
python3 tests/test_yaml_validation.py

# Expected output:
# ✓ Namespace/example
# ✓ Deployment/web-app
# ✓ Service/web-app
# ✓ NetworkPolicy/web-app-default-deny
# ✓ Resource Ordering: Correct Order: True
```

#### Nix Module Tests

```bash
# Run module syntax checks
nix eval -f src/lib/schema.nix 'getSupportedVersions' > /dev/null

# Run all module tests
nix flake check
```

## Test Coverage

### YAML Validation Tests (`tests/test_yaml_validation.py`)

**Framework**: Python 3 with PyYAML

**Validates**:
- ✅ Basic Kubernetes resource structure (apiVersion, kind, metadata)
- ✅ Label presence and correctness
- ✅ Annotation formatting
- ✅ Compliance labels (framework, level, owner)
- ✅ Traceability annotations (build ID, generated-by)
- ✅ NetworkPolicy structure and rules
- ✅ Kyverno policy specifications
- ✅ RBAC resource requirements
- ✅ Resource ordering for kubectl apply
- ✅ Namespace reference validation

**Key Features**:

1. **KubernetesValidator** - Validates resource structure
   - Checks required fields (apiVersion, kind, metadata)
   - Validates metadata content
   - Ensures proper namespace references

2. **ComplianceValidator** - Validates compliance requirements
   - Checks for required compliance labels
   - Validates framework values (PCI-DSS, HIPAA, SOC2, ISO27001, GDPR, NIST)
   - Validates compliance levels (unrestricted, permissive, standard, strict, restricted)
   - Checks traceability annotations

3. **PolicyValidator** - Validates security policies
   - Validates NetworkPolicy structure
   - Validates Kyverno ClusterPolicy/Policy
   - Validates RBAC resources (Role, RoleBinding, ClusterRole, ClusterRoleBinding)

4. **ManifestAnalyzer** - Comprehensive manifest validation
   - Validates per-resource structure
   - Checks manifest-level consistency
   - Validates resource ordering for kubectl apply

**Example Test Cases**:

```python
# Test 1: Parse and validate complete manifest
analyzer = ManifestAnalyzer()
result = analyzer.validate_manifest(yaml_content)
print(f"Valid: {result['is_valid']}")
print(f"Resource Count: {result['resource_count']}")

# Test 2: Validate specific resource compliance
compliance_validator = ComplianceValidator()
is_valid, errors = compliance_validator.validate_compliance_labels(resource)

# Test 3: Validate resource ordering
ordering = analyzer.validate_resource_ordering(yaml_content)
print(f"Correct Order: {ordering['is_ordered']}")
```

### Nix Module Interaction Tests (`tests/integration-tests.nix`)

**Framework**: Nixpkgs test framework

**Validates**:
- ✅ Compliance label injection and enforcement
- ✅ Traceability annotation injection
- ✅ Network policy generation (default deny)
- ✅ Kyverno policy structure
- ✅ RBAC resource generation
- ✅ Resource ordering
- ✅ Compliance profile selection
- ✅ Schema version resolution
- ✅ Deployment generation
- ✅ Service generation
- ✅ Multi-environment deployments

**Test Cases** (12 total):

1. **testComplianceLabelInjection** - Verify labels are added to resources
2. **testTraceabilityInjection** - Verify traceability annotations exist
3. **testComplianceEnforcementLabels** - Verify enforcement generates correct labels
4. **testDefaultDenyNetworkPolicy** - Verify default deny policy structure
5. **testKyvernoPolicyStructure** - Verify Kyverno policy has required fields
6. **testRBACGeneration** - Verify RBAC resources are created correctly
7. **testResourceOrdering** - Verify resources are in correct kubectl apply order
8. **testComplianceProfileSelection** - Verify environment profiles work
9. **testSchemaVersionResolution** - Verify API version resolution
10. **testDeploymentGeneration** - Verify deployment creation
11. **testServiceGeneration** - Verify service creation
12. **testMultiEnvironmentCompliance** - Verify multi-environment setup

## Automated Test Integration

Tests are automatically run by `nix flake check`:

```bash
nix flake check
```

This runs 4 checks:
- **module-tests** - Verifies all module files are readable
- **yaml-validation** - Runs Python YAML validation suite
- **integration-tests** - Runs Nix module interaction tests
- **example-app-build** - Validates example application

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v20
      - run: nix flake check
```

### GitLab CI Example

```yaml
test:
  image: nixos/nix
  script:
    - nix flake check
```

### Local Pre-commit Hook

```bash
#!/bin/bash
# Save as: .git/hooks/pre-commit
nix flake check || exit 1
```

## Adding New Tests

### Adding a Python YAML Validation Test

```python
# In tests/test_yaml_validation.py

class YourValidator:
    """Validates your specific concern"""
    
    def validate_something(self, resource):
        """Validates specific behavior"""
        errors = []
        
        if "required_field" not in resource:
            errors.append("Missing required_field")
        
        return len(errors) == 0, errors
```

Then update `ManifestAnalyzer.validate_manifest()` to call your validator:

```python
# In ManifestAnalyzer.validate_manifest()
_, your_errors = your_validator.validate_something(resource)
resource_errors.extend(your_errors)
```

### Adding a Nix Module Interaction Test

```nix
# In tests/integration-tests.nix

testYourFeature = {
  name = "your feature description";
  test = 
    let
      result = someModule.someFunction { args = values; };
    in
      # Return boolean (true = pass, false = fail)
      result.expectedField == expectedValue;
  expected = true;
};
```

## Test Output Interpretation

### Successful Output

```
✓ Namespace/example
✓ Deployment/web-app
✓ Service/web-app
✓ NetworkPolicy/web-app-default-deny

Resource Ordering:
  Correct Order: True
```

### Failure Output Example

```
✗ Deployment/web-app
    - Invalid compliance level: custom. Valid levels: [...]
    - metadata.namespace must be a string
```

**How to Fix**:
1. Identify the resource and field in error
2. Check against validation rules in comments
3. Update manifest or module accordingly
4. Re-run tests to verify fix

## Performance Considerations

### Test Execution Time

- **YAML validation**: ~100ms
- **Module tests**: ~200ms
- **Integration tests**: ~300ms
- **Total**: ~600ms

### Optimization for Large Manifests

If testing large manifests:

```python
# Create validator once, reuse for multiple manifests
analyzer = ManifestAnalyzer()
for manifest in large_manifests:
    result = analyzer.validate_manifest(manifest)
```

## Troubleshooting

### "ModuleNotFoundError: No module named 'yaml'"

```bash
# Make sure you're in the nix dev shell
nix develop
python3 tests/test_yaml_validation.py
```

### Test Fails with "path does not exist"

Tests must be committed to git before running `nix flake check`:

```bash
git add tests/
git commit -m "Add test files"
nix flake check
```

### Compliance Label Errors

Verify you're using valid frameworks and levels:

**Valid Frameworks**: PCI-DSS, HIPAA, SOC2, ISO27001, GDPR, NIST

**Valid Levels**: unrestricted, permissive, standard, strict, restricted

## Test Coverage Matrix

| Module | Test Type | Coverage |
|--------|-----------|----------|
| schema | Nix | Version resolution |
| compliance | Nix + Python | Label injection, traceability |
| compliance-enforcement | Nix | Enforcement rules |
| compliance-profiles | Nix | Profile selection |
| policies | Nix + Python | NetworkPolicy, Kyverno |
| policy-generation | Nix | Advanced policy generation |
| rbac | Nix + Python | Role/RoleBinding creation |
| generators | Nix + Python | Deployment/Service generation |
| output | Nix | Resource ordering, formatting |

## Future Test Enhancements

1. **Real Kubernetes Validation**
   - Use kubeconform to validate against official schemas
   - Test with kind cluster if available

2. **Performance Tests**
   - Benchmark evaluation times for large manifests
   - Profile memory usage

3. **Compatibility Tests**
   - Test with multiple Kubernetes versions (1.28, 1.29, 1.30, 1.31)

4. **Security Tests**
   - Validate policies prevent privilege escalation
   - Test pod security policies

5. **Integration Tests**
   - Test with real Vault instances
   - Test with multiple secret backends

## Reporting Test Results

Generate a test report:

```bash
# Run tests and capture output
nix flake check > test-results.txt 2>&1

# Display summary
grep "✓" test-results.txt | wc -l  # Count passes
```

## References

- [Kubernetes Resource Definitions](https://kubernetes.io/docs/concepts/overview/working-with-objects/kubernetes-objects/)
- [NetworkPolicy Documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Kyverno Documentation](https://kyverno.io/docs/)
- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

## Support

For issues with the test suite:
1. Check this documentation
2. Review test output for specific errors
3. Open an issue with test output and manifests
