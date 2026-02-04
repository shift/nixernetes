# Kyverno Dynamic Policy Framework

## Overview

The Nixernetes Kyverno Framework provides a declarative, Nix-based approach to defining and managing Kubernetes policies using [Kyverno](https://kyverno.io/). Kyverno is a Kubernetes-native policy engine that allows you to validate, mutate, and generate resources.

**Key Features:**
- Policy rule builders for validation, mutation, and generation
- Pre-built security and compliance patterns
- Policy composition and inheritance
- Multi-provider policy libraries
- Integration with compliance frameworks (PCI-DSS, HIPAA, SOC2)
- Context-aware policy conditions

## Architecture

### Core Components

1. **Policy Builders** - Create individual Kyverno policies
2. **Rule Builders** - Define validation, mutation, and generation rules
3. **Pattern Library** - Pre-configured patterns for common use cases
4. **Composition Framework** - Combine and inherit policies
5. **Policy Sets** - Collections of related policies

### Policy Types

#### Validation Policies
Validate resources against rules. Violations are either **enforced** (rejected) or **audited** (allowed but logged).

```nix
mkValidationRule {
  name = "require-image-registry";
  message = "Image must come from gcr.io";
  pattern = {
    spec.containers = [{
      image = "gcr.io/*";
    }];
  };
}
```

#### Mutation Policies
Modify resources to enforce standards (e.g., add labels, set defaults).

```nix
mkMutationRule {
  name = "add-image-pull-policy";
  patchStrategicMerge = {
    spec.containers = [{
      imagePullPolicy = "IfNotPresent";
    }];
  };
}
```

#### Generation Policies
Automatically create related resources (e.g., generate NetworkPolicy for each namespace).

```nix
mkGenerationRule {
  name = "generate-network-policy";
  resourceSpec = {
    kind = "NetworkPolicy";
    apiVersion = "networking.k8s.io/v1";
    name = "default-deny-all";
  };
  synchronize = true;
}
```

## Usage Guide

### Creating a Simple Policy

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  # Create a policy that requires resource limits
  requireLimitsPolicy = kyverno.mkClusterPolicy {
    name = "require-resource-limits";
    description = "Enforce CPU and memory limits on all containers";
    rules = [
      kyverno.mkRequireResourceLimits {}
    ];
    validationFailureAction = "enforce";  # Reject violations
  };
}
```

### Creating a Policy with Multiple Rules

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  securityPolicy = kyverno.mkClusterPolicy {
    name = "pod-security";
    description = "Enforce pod security standards";
    rules = [
      (kyverno.mkRequireImageRegistry {
        registry = "gcr.io";
      })
      (kyverno.mkRequireResourceLimits {})
      (kyverno.mkRequireSecurityContext {})
      (kyverno.mkBlockPrivilegedContainers {})
    ];
    validationFailureAction = "audit";  # Log violations but allow
  };
}
```

### Namespace-Specific Policies

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  strictNamespacePolicy = kyverno.mkPolicy {
    name = "strict-namespace-policy";
    namespace = "production";
    description = "Strict security policy for production namespace";
    rules = [
      (kyverno.mkBlockPrivilegedContainers {})
      (kyverno.mkRequireSecurityContext {
        runAsNonRoot = true;
      })
      (kyverno.mkRequireResourceLimits {})
    ];
    validationFailureAction = "enforce";
  };
}
```

## Built-in Patterns

### Security Patterns

#### Require Image Registry
Ensures all container images come from a trusted registry.

```nix
kyverno.mkRequireImageRegistry {
  name = "require-gcr-images";
  registry = "gcr.io";
  namespace = "production";  # Optional: restrict to namespace
}
```

**Use Case**: Prevent use of untrusted or public images.

#### Require Resource Limits
Mandates CPU and memory limits on all containers.

```nix
kyverno.mkRequireResourceLimits {
  name = "require-limits";
}
```

**Use Case**: Prevent resource starvation and cost overruns.

#### Require Security Context
Enforces security context settings (non-root, read-only filesystem, etc.).

```nix
kyverno.mkRequireSecurityContext {
  name = "require-security-context";
  runAsNonRoot = true;
}
```

**Use Case**: Enforce defense-in-depth security practices.

#### Block Privileged Containers
Prevents containers from running in privileged mode.

```nix
kyverno.mkBlockPrivilegedContainers {
  name = "block-privileged";
}
```

**Use Case**: Comply with PCI-DSS, HIPAA, and other standards.

#### Enforce Pod Security Standards
Ensures pods comply with Kubernetes Pod Security Standards (restricted level).

```nix
kyverno.mkEnforcePodSecurityStandard {
  name = "pod-security-restricted";
}
```

**Use Case**: Enforce security by default.

### Mutation Patterns

#### Add Image Pull Policy
Automatically sets image pull policy if not specified.

```nix
kyverno.mkAddImagePullPolicy {
  name = "add-image-pull-policy";
  policy = "IfNotPresent";  # Options: Always, IfNotPresent, Never
}
```

**Use Case**: Reduce unnecessary image pulls and improve performance.

#### Add Default Labels
Automatically adds labels to resources.

```nix
kyverno.mkAddDefaultLabels {
  name = "add-default-labels";
  labels = {
    "app.kubernetes.io/managed-by" = "nixernetes";
    "app.kubernetes.io/part-of" = "platform";
  };
}
```

**Use Case**: Ensure consistent labeling for cost allocation and resource management.

### Generation Patterns

#### Generate NetworkPolicy
Automatically generates a default-deny NetworkPolicy for each namespace.

```nix
kyverno.mkGenerateNetworkPolicy {
  name = "generate-default-deny-policy";
  namespace = "production";  # Optional
}
```

**Use Case**: Implement zero-trust networking by default.

#### Generate RBAC Resources
Automatically creates basic RBAC roles for namespaces.

```nix
kyverno.mkGenerateRBACResources {
  name = "generate-rbac";
  namespace = "production";  # Optional
}
```

**Use Case**: Ensure consistent RBAC across namespaces.

## Policy Libraries

### Security Baseline

Collection of essential security policies:

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
  policies = kyverno.policyLibrary.securityBaseline;
in
{
  securityPolicies = map (policy: 
    kyverno.mkClusterPolicy {
      name = policy.name;
      rules = [ policy ];
      validationFailureAction = "audit";
    }
  ) policies;
}
```

**Includes**:
- Require image registry
- Require resource limits
- Require security context
- Block privileged containers

### Compliance Suite

Policies for regulatory compliance (PCI-DSS, HIPAA, SOC2):

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
  policies = kyverno.policyLibrary.complianceSuite;
in
{
  compliancePolicies = map (policy:
    kyverno.mkClusterPolicy {
      name = policy.name;
      rules = [ policy ];
      validationFailureAction = "enforce";  # Strictly enforce
    }
  ) policies;
}
```

**Includes**:
- Block privileged containers
- Enforce Pod Security Standards
- Require resource limits
- Require security context

### Cost Optimization

Policies that help reduce costs:

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
  policies = kyverno.policyLibrary.costOptimization;
in
  # Ensures proper resource requests preventing overprovisioning
  kyverno.mkClusterPolicy {
    name = "cost-optimization";
    rules = policies;
  }
```

**Includes**:
- Require resource limits
- Add image pull policy

### Best Practices

Policies for DevOps best practices:

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
  policies = kyverno.policyLibrary.bestPractices;
in
  kyverno.mkClusterPolicy {
    name = "best-practices";
    rules = policies;
  }
```

**Includes**:
- Require image registry
- Require resource limits
- Require security context
- Add default labels
- Add image pull policy

## Advanced Usage

### Policy Composition

Combine multiple policies with inheritance:

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  customPolicy = kyverno.mkPolicyComposition {
    name = "custom-policy";
    basePolicies = [
      (kyverno.mkClusterPolicy {
        name = "security-base";
        rules = [ kyverno.mkBlockPrivilegedContainers ];
      })
    ];
    additionalRules = [
      (kyverno.mkRequireImageRegistry { registry = "gcr.io"; })
    ];
    overrides = {
      validationFailureAction = "enforce";
    };
  };
}
```

### Custom Validation Rules

Define custom validation logic:

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  customValidation = kyverno.mkValidationRule {
    name = "require-owner-label";
    message = "Owner label is required";
    pattern = {
      metadata.labels."owner" = "?*";  # ?* means required
    };
  };
}
```

### Context-Aware Rules

Use context variables for conditional logic:

```nix
{
  rule = {
    name = "context-aware-validation";
    match = {
      resources.kinds = [
        { group = "apps"; version = "v1"; kind = "Deployment"; }
      ];
    };
    context = [
      {
        name = "deploymentName";
        variable = {
          jmesPath = "request.object.metadata.name";
        };
      }
    ];
    validation = {
      message = "Deployment name validation";
      pattern = {
        metadata.labels."app" = "{{deploymentName}}";
      };
    };
  };
}
```

## Integration with Nixernetes Framework

### With Compliance Framework

```nix
let
  compliance = import ./src/lib/compliance.nix { inherit lib; };
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  # Compliance-aware policies
  compliancePolicies = kyverno.policyLibrary.complianceSuite;
  
  # Add compliance labels to resources
  labels = compliance.mkComplianceLabels {
    framework = "PCI-DSS";
    level = "strict";
  };
}
```

### With Policy Generation

```nix
let
  policyGen = import ./src/lib/policy-generation.nix { inherit lib; };
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  # Generate both NetworkPolicies and Kyverno policies
  networkPolicies = policyGen.mkDefaultDenyPolicies {};
  kyvernoPolicies = kyverno.policyLibrary.securityBaseline;
}
```

### With RBAC

```nix
let
  rbac = import ./src/lib/rbac.nix { inherit lib; };
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  # RBAC + Kyverno policies for defense-in-depth
  rbacRoles = rbac.mkClusterRole { /* ... */ };
  kyvernoPolicies = kyverno.policyLibrary.bestPractices;
}
```

## Validation and Testing

### Validate Against Policy

Check if a resource would pass a policy:

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
  
  policy = kyverno.mkClusterPolicy {
    name = "test-policy";
    rules = [ kyverno.mkRequireResourceLimits ];
  };
  
  resource = {
    apiVersion = "v1";
    kind = "Pod";
    spec.containers = [{
      resources.limits = {
        cpu = "500m";
        memory = "512Mi";
      };
    }];
  };
in
  kyverno.validateAgainstPolicy resource policy  # true
```

### Policy Summary

Generate a summary of policies:

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
  
  policies = [
    kyverno.mkClusterPolicy { /* ... */ }
    kyverno.mkClusterPolicy { /* ... */ }
  ];
in
  kyverno.mkPolicySummary policies
  # Returns:
  # {
  #   totalPolicies = 2;
  #   validationCount = 2;
  #   mutationCount = 1;
  #   generationCount = 1;
  # }
```

## Best Practices

### 1. Start with Audit Mode
Begin with `validationFailureAction = "audit"` to observe violations before enforcing.

```nix
kyverno.mkClusterPolicy {
  name = "policy";
  rules = [ /* ... */ ];
  validationFailureAction = "audit";  # Observe first
}
```

### 2. Exclude System Namespaces
Always exclude system namespaces to prevent cluster disruption:

```nix
match = {
  resources.namespaces.excludeNames = [ "kyverno" "kube-system" "kube-public" ];
}
```

### 3. Use Namespace Selector
Target policies to specific namespaces using labels:

```nix
match = {
  resources.namespaceSelector.matchLabels."policies" = "enforced";
}
```

### 4. Combine Patterns
Layer multiple patterns for defense-in-depth:

```nix
rules = [
  kyverno.mkBlockPrivilegedContainers {}
  kyverno.mkRequireSecurityContext {}
  kyverno.mkRequireResourceLimits {}
  kyverno.mkRequireImageRegistry { registry = "gcr.io"; }
]
```

### 5. Monitor and Update
Regularly review policy violations and adjust rules based on operational needs.

### 6. Document Policies
Include clear descriptions and messages for policy violations:

```nix
{
  name = "policy-name";
  match = { /* ... */ };
  validation = {
    message = "Clear explanation of why this policy exists and how to fix it";
    pattern = { /* ... */ };
  };
}
```

## Examples

### Example 1: Security-First Deployment

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  securityPolicy = kyverno.mkClusterPolicy {
    name = "production-security";
    description = "Comprehensive security policy for production";
    validationFailureAction = "enforce";
    rules = [
      # Block dangerous configurations
      (kyverno.mkBlockPrivilegedContainers {})
      
      # Require security best practices
      (kyverno.mkRequireSecurityContext {
        runAsNonRoot = true;
      })
      
      # Ensure resource limits
      (kyverno.mkRequireResourceLimits {})
      
      # Trust only internal registry
      (kyverno.mkRequireImageRegistry {
        registry = "gcr.io";
      })
      
      # Auto-add image pull policy
      (kyverno.mkAddImagePullPolicy {})
    ];
  };
}
```

### Example 2: Compliance Enforcement

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  # PCI-DSS compliance
  pciPolicy = kyverno.mkClusterPolicy {
    name = "pci-dss-compliance";
    validationFailureAction = "enforce";
    rules = kyverno.policyLibrary.complianceSuite;
  };
}
```

### Example 3: Development with Warnings

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  devPolicy = kyverno.mkPolicy {
    name = "development-policies";
    namespace = "development";
    validationFailureAction = "audit";  # Warn, don't enforce
    rules = kyverno.policyLibrary.bestPractices;
  };
}
```

## Troubleshooting

### Policies Not Applying
- Check policy matches correct resources
- Verify operation is in rule (CREATE, UPDATE, etc.)
- Ensure policy is not in audit mode if testing enforcement

### Permission Denied Errors
- Kyverno webhooks need proper RBAC permissions
- Check webhook configuration
- Review ClusterRoleBinding for kyverno

### Performance Issues
- Consider using namespace selectors to limit scope
- Exclude system namespaces
- Use `background = false` for mutation policies

## Related Documentation

- [Security Policies Guide](./SECURITY_POLICIES.md)
- [Compliance Framework](./docs/README.md#compliance)
- [Policy Generation](./SECURITY_POLICIES.md#automatic-policy-generation)
- [RBAC Configuration](./SECURITY_POLICIES.md#rbac-configuration)

## References

- [Kyverno Official Documentation](https://kyverno.io/docs/)
- [Kyverno Policies Library](https://kyverno.io/policies/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)

## License

The Kyverno Dynamic Policy Framework is part of the Nixernetes project.
