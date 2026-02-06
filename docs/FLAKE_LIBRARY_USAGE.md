Flake Library Usage Guide
=========================

As of this version, Nixernetes properly exports a `lib` attribute in its flake outputs, making it consumable by other Nix Flakes as a standard library flake.

## Quick Start

Add Nixernetes to your flake inputs:

```nix
{
  inputs = {
    nixernetes.url = "git+file:///path/to/nixernetes";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixernetes, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;

        # Access Nixernetes lib modules directly
        nixernetesLib = nixernetes.lib;

      in {
        # Now you can use all Nixernetes functions
        packages = {
          # Example: Use the unified API to define an app
          my-app = nixernetesLib.unifiedApi.mkApplication {
            name = "my-app";
            namespace = "default";
            
            spec = {
              compliance.profile = "SOC2";
              workload = {
                image = "nginx:latest";
                replicas = 2;
              };
            };
          };
        };
      }
    );
}
```

## Available Modules

The Nixernetes `lib` attribute exports the following modules:

### Core Modules
- `schema` - Kubernetes API schema definitions
- `types` - Nix type definitions for validation
- `validation` - Validation functions
- `generators` - YAML/JSON generators
- `output` - Output formatting functions

### Kubernetes Abstractions
- `api` - Low-level Kubernetes API builders
- `manifest` - Manifest composition utilities
- `rbac` - RBAC (Role, RoleBinding, ClusterRole) builders
- `policies` - NetworkPolicy and security policy builders

### Compliance & Governance
- `compliance` - Compliance label injection
- `complianceEnforcement` - Enforce compliance rules
- `complianceProfiles` - Pre-configured compliance profiles
- `policyGeneration` - Automatic policy generation
- `kyverno` - Kyverno policy builders
- `securityScanning` - Security scanning integration

### Observability & Analysis
- `performanceAnalysis` - Performance profiling and analysis
- `costAnalysis` - Cost estimation and optimization
- `policyVisualization` - Policy graph visualization

### Advanced Features
- `unifiedApi` - High-level declarative API
- `helmIntegration` - Helm chart generation
- `gitops` - GitOps configuration (Flux, ArgoCD)
- `serviceMesh` - Service mesh (Istio, Linkerd) builders
- `apiGateway` - API gateway configuration
- `multiTenancy` - Multi-tenancy isolation
- `disasterRecovery` - Backup and recovery builders
- `advancedOrchestration` - Advanced scheduling and affinity

### Infrastructure Integration
- `externalSecrets` - External Secrets Operator
- `secretsManagement` - Secrets management solutions
- `containerRegistry` - Container registry integration
- `databaseManagement` - Database deployment builders
- `mlOperations` - ML/AI workload builders
- `batchProcessing` - Batch and workflow builders
- `eventProcessing` - Event streaming builders

### Testing & Validation
- `policyTesting` - Policy testing framework

## Module Structure

Each module provides:

1. **Builder Functions** - `mk*` functions that construct Kubernetes objects
   ```nix
   nixernetesLib.rbac.mkServiceAccount { name = "my-sa"; namespace = "default"; }
   ```

2. **Type Definitions** - Input validation
   ```nix
   nixernetesLib.types.kubernetesObject
   nixernetesLib.types.complianceProfile
   ```

3. **Utility Functions** - Helper functions for common patterns
   ```nix
   nixernetesLib.policies.mkDefaultDenyNetworkPolicy
   nixernetesLib.compliance.mkComplianceLabels
   ```

## Example: Building a Deployment with Compliance

```nix
let
  nixLib = nixernetes.lib;
in
{
  deployment = nixLib.api.mkDeployment {
    name = "web-server";
    namespace = "production";
    image = "nginx:1.25";
    replicas = 3;
    
    # Automatically injects compliance labels and security context
    compliance = {
      profile = "SOC2";
      level = "high";
    };
  };

  # Auto-generate deny-all NetworkPolicy
  networkPolicy = nixLib.policies.mkDefaultDenyNetworkPolicy {
    namespace = "production";
    podSelector = { matchLabels = { app = "web-server"; }; };
  };

  # Auto-generate RBAC
  serviceAccount = nixLib.rbac.mkReadOnlyServiceAccount {
    name = "web-server";
    namespace = "production";
  };
}
```

## Example: High-Level Application Builder

For the most declarative approach, use the Unified API:

```nix
nixernetes.lib.unifiedApi.mkApplication {
  name = "ecommerce";
  namespace = "production";

  spec = {
    compliance.profile = "PCI-DSS";
    compliance.level = "restricted";

    workload = {
      image = "myapp:v1";
      replicas = 3;
      port = 8080;
      
      resources = {
        limits = { cpu = "500m"; memory = "512Mi"; };
        requests = { cpu = "100m"; memory = "128Mi"; };
      };
    };

    dependencies = [ "postgres" "redis" ];

    networking = {
      ingressAllowed = [ "ingress-controller" ];
      egressAllowed = [ "external-api" ];
    };

    observability = {
      metrics = true;
      logging = true;
      tracing = true;
    };
  };
}
```

The Unified API will automatically:
- Generate NetworkPolicies based on dependencies
- Inject compliance labels
- Create RBAC resources
- Apply security contexts
- Configure observability sidecars

## Advanced: Custom Compliance Profiles

Create custom compliance profiles:

```nix
let
  myProfile = nixernetesLib.complianceProfiles.mkProfile {
    name = "mycompany-standard";
    rules = [
      nixernetesLib.compliance.mkComplianceLabel "mycompany.com/profile" "standard"
      nixernetesLib.compliance.mkSecurityContext "restricted"
      nixernetesLib.policies.mkNetworkPolicyCIDRBlock "10.0.0.0/8"
    ];
  };
in
# Now use this profile in your apps
```

## Integration with Existing Flakes

To export your own lib that re-exports Nixernetes modules:

```nix
{
  inputs = {
    nixernetes.url = "git+file:///path/to/nixernetes";
  };

  outputs = { nixernetes, ... }:
    {
      lib = nixernetes.lib // {
        # Your custom extensions
        custom = { ... };
      };
    };
}
```

Other flakes can then use:
```nix
{
  inputs = {
    mycompany.url = "git+file:///path/to/mycompany";
  };

  outputs = { mycompany, ... }:
    {
      packages.myApp = mycompany.lib.unifiedApi.mkApplication { ... };
    };
}
```

## Architecture Notes

Nixernetes follows a **Three-Layer API Design**:

### Layer 1: Raw Resources (1:1 Kubernetes API)
```nix
nixernetesLib.api.mkDeployment
nixernetesLib.api.mkService
nixernetesLib.api.mkNetworkPolicy
```

Full control, zero abstraction. Use when you need exact API version compatibility.

### Layer 2: Convenience Modules (Opinionated Builders)
```nix
nixernetesLib.rbac.mkReadOnlyServiceAccount
nixernetesLib.policies.mkDefaultDenyNetworkPolicy
```

Sensible defaults, best practices baked in. Reduces boilerplate by 70%.

### Layer 3: High-Level Applications (Intent-Based)
```nix
nixernetesLib.unifiedApi.mkApplication
```

Declare *what* you want, not *how*. Framework generates all supporting resources.

## System-Specific Pkgs Availability

Some modules (notably `generators` and `output`) require access to `pkgs`. The top-level `lib` export uses `nixpkgs.legacyPackages.x86_64-linux` as a default, making it work in most cases.

If you need system-specific package access, import directly in your flake:

```nix
let
  # Get system-specific pkgs from consumer's flake-utils
  nixernetesLibWithPkgs = nixernetes.lib;
in
# This is already system-aware when used inside eachDefaultSystem
```

## Backward Compatibility

All existing packages in the flake (`packages.default`, `packages.example-app`, `packages.lib-*`) continue to work unchanged. The `lib` output is an *addition*, not a replacement.

## Troubleshooting

### "attribute 'schema' missing in lib"
Ensure you're accessing the top-level `lib`:
```nix
nixernetes.lib.schema  # Correct
nixernetes.lib # This should be an attrset with all modules
```

### "call is not a function"
You're likely trying to call a builder without proper arguments:
```nix
# Wrong
nixernetesLib.api.mkDeployment

# Correct
nixernetesLib.api.mkDeployment { name = "app"; ... }
```

### "pkgs not available"
Use the system-specific pkgs from your flake's `eachDefaultSystem`:
```nix
flake-utils.lib.eachDefaultSystem (system:
  let
    pkgs = nixpkgs.legacyPackages.${system};
    # Now pkgs is available for generators, etc.
  in
  ...
)
```

## See Also

- `docs/UNIFIED_API.md` - Detailed Unified API documentation
- `docs/API.md` - Low-level API reference
- `docs/DEPLOYMENT.md` - Deployment patterns
- `docs/SECURITY_POLICIES.md` - Security policy examples
