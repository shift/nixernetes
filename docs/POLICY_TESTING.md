# Policy Testing Framework

## Overview

The Policy Testing Framework provides comprehensive testing capabilities for Kyverno policies in Nixernetes. It enables:

- Unit testing of validation, mutation, and generation policies
- Policy behavior verification
- Compliance checking
- Coverage analysis
- Test fixtures and reusable test resources
- Test report generation
- Policy composition testing

This framework ensures policies work as intended before deployment and catches regressions early.

## Architecture

The framework consists of four main layers:

### Layer 1: Test Builders
High-level functions for creating typed tests:
- `mkPolicyTest` - Generic policy test
- `mkValidationPolicyTest` - Validation policy tests
- `mkMutationPolicyTest` - Mutation policy tests
- `mkGenerationPolicyTest` - Generation policy tests

### Layer 2: Assertions
Assertion helpers for verifying policy behavior:
- `assertPolicyPasses` - Verify policy accepts a resource
- `assertPolicyRejects` - Verify policy rejects a resource
- `assertPolicyMutates` - Verify policy mutates a resource

### Layer 3: Test Organization
Structure tests into logical groups:
- `mkPolicyTestSuite` - Group related tests with statistics
- `mkPolicyFixture` - Reusable test resources

### Layer 4: Analysis & Reporting
Tools for policy analysis and test reporting:
- `analyzePolicyCoverage` - Coverage metrics
- `mkPolicyComplianceTest` - Policy structure validation
- `mkTestReport` - Generate test reports

## Quick Start

### Simple Policy Test

```nix
let
  policyTesting = import ./src/lib/policy-testing.nix { inherit lib; };
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
  
  # Define a policy
  imageRegistryPolicy = kyverno.mkValidationPolicy {
    name = "require-registry";
    rules = [{
      name = "validate-registry";
      match = {
        resources = { kinds = ["Pod"]; };
      };
      validate = {
        message = "Image must be from trusted registry";
        pattern = {
          spec = {
            containers = [{
              image = "myregistry.azurecr.io/*";
            }];
          };
        };
      };
    }];
  };
  
  # Define a test
  testValidImage = policyTesting.assertPolicyPasses {
    policy = imageRegistryPolicy;
    resource = {
      apiVersion = "v1";
      kind = "Pod";
      spec = {
        containers = [{
          image = "myregistry.azurecr.io/myapp:1.0";
        }];
      };
    };
    description = "image-from-registry";
  };
  
  testInvalidImage = policyTesting.assertPolicyRejects {
    policy = imageRegistryPolicy;
    resource = {
      apiVersion = "v1";
      kind = "Pod";
      spec = {
        containers = [{
          image = "docker.io/untrusted/app:1.0";
        }];
      };
    };
    description = "image-from-untrusted-registry";
  };
in
{
  inherit testValidImage testInvalidImage;
}
```

## Builder Reference

### Policy Test Builder

```nix
mkPolicyTest "test-name" {
  policy = kyverno_policy;           # Required: Kyverno policy to test
  resource = kubernetes_resource;    # Required: Resource to test against
  expectedResult = "pass";           # pass | reject | mutate
  expectedMessage = "error message"; # Optional: Expected error message
  expectedMutation = { /* ... */ };  # Optional: Expected mutation result
  timeout = 5000;                    # Optional: Timeout in ms
  tags = ["security" "production"];  # Optional: Test tags for filtering
  description = "test description";  # Optional: Human-readable description
}
```

### Validation Policy Test Builder

```nix
mkValidationPolicyTest "test-name" {
  policy = validation_policy;
  resource = test_resource;
  shouldPass = true;                 # true = policy should accept
  description = "test-description";
  tags = [];
}
```

### Mutation Policy Test Builder

```nix
mkMutationPolicyTest "test-name" {
  policy = mutation_policy;
  resource = test_resource;
  expectedFields = ["metadata.labels"];  # Expected mutation targets
  description = "test-description";
}
```

### Test Suite Builder

```nix
mkPolicyTestSuite "test-suite-name" {
  tests = [
    test1,
    test2,
    test3,
  ];
  policies = [policy1, policy2];
  setup = { /* initialization */ };      # Optional: Pre-test setup
  teardown = { /* cleanup */ };          # Optional: Post-test cleanup
}
```

### Policy Fixture Builder

```nix
mkPolicyFixture "fixture-name" {
  resources = [
    resource1,
    resource2,
  ];
  policies = [policy1, policy2];
  setup = { /* setup code */ };
  teardown = { /* teardown code */ };
}
```

## Assertion Functions

### Assert Policy Passes

```nix
assertPolicyPasses {
  policy = my_policy;
  resource = valid_resource;
  description = "valid-input";
}
```

Verifies that a policy accepts a resource without rejection. Returns:
```nix
{
  assertion = true|false;           # Whether the assertion passed
  message = "...";                  # Human-readable result message
  passed = true|false;              # Alias for assertion
  testName = "assert-passes-...";
  duration = 1;                     # Test duration in ms
}
```

### Assert Policy Rejects

```nix
assertPolicyRejects {
  policy = my_policy;
  resource = invalid_resource;
  reason = "image-not-approved";    # Optional: Expected rejection reason
  description = "invalid-input";
}
```

Verifies that a policy rejects a resource. Returns:
```nix
{
  assertion = true|false;
  message = "...";
  passed = true|false;
  testName = "assert-rejects-...";
  duration = 1;
}
```

### Assert Policy Mutates

```nix
assertPolicyMutates {
  policy = my_policy;
  resource = test_resource;
  expectedFields = ["metadata.labels"]; # Fields expected to be mutated
  description = "add-labels";
}
```

Verifies that a mutation policy transforms a resource as expected.

## Test Fixtures

Pre-built test resources for common scenarios:

### Pod Fixtures

```nix
# Restricted pod with all security best practices
policyTesting.fixtures.restrictedPod

# Permissive pod (should fail security policies)
policyTesting.fixtures.permissivePod

# Standard deployment
policyTesting.fixtures.standardDeployment
```

Example usage:
```nix
let
  securityPolicy = kyverno.mkValidationPolicy { /* ... */ };
  fixture = policyTesting.fixtures.restrictedPod;
in
policyTesting.assertPolicyPasses {
  policy = securityPolicy;
  resource = fixture;
  description = "restricted-pod-passes";
}
```

## Coverage Analysis

Analyze which Kubernetes resources are covered by policies:

```nix
let
  policies = [policy1, policy2, policy3];
  coverage = policyTesting.analyzePolicyCoverage policies;
in
{
  total = coverage.totalPolicies;           # 3
  rules = coverage.totalRules;              # 8
  validationPolicies = coverage.validationPolicies;  # 2
  mutationPolicies = coverage.mutationPolicies;      # 1
  resources = coverage.coveredResourceKinds;         # e.g., ["Pod", "Deployment"]
}
```

## Policy Compliance Testing

Check if policies follow best practices:

```nix
let
  policy = kyverno.mkValidationPolicy { /* ... */ };
  compliance = policyTesting.mkPolicyComplianceTest policy;
in
{
  hasValidStructure = compliance.hasValidStructure;      # Has metadata + spec
  isDocumented = compliance.isDocumented;                # Has description
  hasMeaningfulName = compliance.hasMeaningfulName;      # Name >= 5 chars
  hasSelectors = compliance.hasSelectors;                # Has match/exclude
  hasFailureAction = compliance.hasFailureAction;        # audit|enforce
  compliant = compliance.compliant;                      # All checks pass
}
```

## Test Utilities

### Generate Test Resources

```nix
let
  testPods = policyTesting.utils.generateTestResources
    imageRegistryPolicy
    10;  # Generate 10 test pods
in
# Use testPods in assertions
```

### Filter Tests by Tag

```nix
let
  allTests = [test1, test2, test3];
  securityTests = policyTesting.utils.filterByTag allTests "security";
in
securityTests
```

### Generate Test Matrix

Combine tests with fixtures for comprehensive coverage:

```nix
let
  tests = [test1, test2, test3];
  fixtures = [fixtureA, fixtureB, fixtureC];
  matrix = policyTesting.utils.generateTestMatrix tests fixtures;
in
# Generates 9 test combinations (3 × 3)
```

## Test Reports

Generate comprehensive test reports:

```nix
let
  testSuite = mkPolicyTestSuite "security-policies" {
    tests = [test1, test2, test3];
    policies = [policy1, policy2];
  };
  report = policyTesting.mkTestReport testSuite;
in
{
  name = report.name;
  status = report.status;                  # PASSED | WARNING | FAILED
  summary = {
    total = report.summary.total;          # Total tests
    passed = report.summary.passed;        # Passed tests
    failed = report.summary.failed;        # Failed tests
    successRate = report.summary.successRate;  # Percentage
    durationMs = report.summary.durationMs;    # Total duration
  };
}
```

## Common Test Patterns

### Testing Image Registry Policy

```nix
let
  policy = kyverno.mkValidationPolicy {
    name = "require-registry";
    rules = [{
      name = "check-image";
      match = {
        resources = { kinds = ["Pod"]; };
      };
      validate = {
        message = "Image must be from approved registry";
        pattern = {
          spec = {
            containers = [{
              image = "myregistry/*";
            }];
          };
        };
      };
    }];
  };
  
  tests = {
    approved = policyTesting.assertPolicyPasses {
      policy = policy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        spec = {
          containers = [{
            image = "myregistry/app:1.0";
          }];
        };
      };
      description = "approved-registry";
    };
    
    denied = policyTesting.assertPolicyRejects {
      policy = policy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        spec = {
          containers = [{
            image = "docker.io/app:1.0";
          }];
        };
      };
      description = "unapproved-registry";
    };
  };
in
tests
```

### Testing Pod Security Policy

```nix
let
  policy = kyverno.mkValidationPolicy {
    name = "require-pod-security";
    rules = [{
      name = "check-security";
      match = {
        resources = { kinds = ["Pod"]; };
      };
      validate = {
        message = "Pod must have security context";
        pattern = {
          spec = {
            securityContext = {
              runAsNonRoot = true;
              readOnlyRootFilesystem = true;
            };
          };
        };
      };
    }];
  };
  
  tests = {
    secure = policyTesting.assertPolicyPasses {
      policy = policy;
      resource = policyTesting.fixtures.restrictedPod;
      description = "secure-pod";
    };
    
    insecure = policyTesting.assertPolicyRejects {
      policy = policy;
      resource = policyTesting.fixtures.permissivePod;
      description = "insecure-pod";
    };
  };
in
tests
```

### Testing Mutation Policy

```nix
let
  policy = kyverno.mkMutationPolicy {
    name = "add-labels";
    rules = [{
      name = "add-required-labels";
      match = {
        resources = { kinds = ["Pod"]; };
      };
      mutate = {
        patchStrategicMerge = {
          metadata = {
            labels = {
              "app.nixernetes.io/managed" = "true";
            };
          };
        };
      };
    }];
  };
  
  test = policyTesting.assertPolicyMutates {
    policy = policy;
    resource = {
      apiVersion = "v1";
      kind = "Pod";
      metadata = {
        name = "test-pod";
        labels = { app = "test"; };
      };
    };
    expectedFields = ["metadata.labels"];
    description = "labels-added";
  };
in
test
```

## Integration with CI/CD

Use policy tests in your CI/CD pipeline:

```bash
# Run all policy tests
nix eval -f tests/policy-tests.nix 'runAllTests'

# Run specific policy tests
nix eval -f tests/policy-tests.nix 'runTestsByTag' --arg tag "security"

# Generate test report
nix build .#policy-test-report
```

## Best Practices

### 1. Organize Tests by Policy
Group tests for each policy together:

```nix
let
  imageRegistryTests = {
    test1 = { /* ... */ };
    test2 = { /* ... */ };
  };
  
  podSecurityTests = {
    test1 = { /* ... */ };
    test2 = { /* ... */ };
  };
in
{ inherit imageRegistryTests podSecurityTests; }
```

### 2. Use Descriptive Names
Test names should describe what they verify:

```nix
# Good
testImageRegistryPolicyAcceptsApprovedImage = { /* ... */ };

# Avoid
test1 = { /* ... */ };
```

### 3. Test Both Positive and Negative Cases
For each policy, test both acceptance and rejection:

```nix
{
  testPolicyAcceptsValidResource = { /* ... */ };
  testPolicyRejectsInvalidResource = { /* ... */ };
}
```

### 4. Use Fixtures for Consistency
Reuse fixtures across test suites:

```nix
let
  fixture = policyTesting.fixtures.restrictedPod;
in
{
  test1 = policyTesting.assertPolicyPasses {
    resource = fixture;
    /* ... */
  };
  test2 = policyTesting.assertPolicyPasses {
    resource = fixture;
    /* ... */
  };
}
```

### 5. Tag Tests for Organization
Use tags to organize and filter tests:

```nix
{
  test1 = mkPolicyTest "test1" {
    tags = ["security" "pod-security"];
    /* ... */
  };
  test2 = mkPolicyTest "test2" {
    tags = ["security" "network"];
    /* ... */
  };
}
```

## Troubleshooting

### Test Not Executing

Ensure:
- Policy has valid Kubernetes syntax
- Resource matches policy selector (or no selector)
- Policy kind is ClusterPolicy or Policy

### Assertion Failures

Check:
- Expected result matches actual behavior (pass|reject|mutate)
- Resource structure matches policy expectations
- Policy rules are correctly evaluated

### Coverage Gaps

Use `analyzePolicyCoverage` to identify:
- Resource kinds without policies
- Rules that might not match any resources
- Unused policy rules

## Framework Information

```nix
policyTesting.framework = {
  name = "Nixernetes Policy Testing Framework";
  version = "1.0.0";
  features = [
    "validation-policy-testing"
    "mutation-policy-testing"
    "generation-policy-testing"
    "policy-compliance-checking"
    "coverage-analysis"
    "test-fixtures"
    "test-matrix-generation"
    "test-report-generation"
  ];
  supportedPolicyTypes = ["ClusterPolicy" "Policy"];
  testFrameworks = ["unit" "integration" "compliance"];
}
```

## See Also

- [Kyverno Framework](./KYVERNO.md) - Policy definitions
- [Security Scanning](./SECURITY_SCANNING.md) - Runtime policy enforcement
- [Unified API](./UNIFIED_API.md) - Simplified configuration
- [Compliance Enforcement](./COMPLIANCE_ENFORCEMENT.md) - Policy compliance

## Examples

See `/src/examples/policy-testing-example.nix` for complete working examples including:
- Image registry validation policies
- Pod security policies
- Network policy testing
- Resource quota policies
- Multi-policy test suites
- Policy compliance reporting
