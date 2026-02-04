# Nixernetes - Complete Documentation

## Overview

Nixernetes is an enterprise-grade Nix-driven Kubernetes manifest framework that abstracts Kubernetes complexity into strictly-typed, data-driven modules with built-in compliance enforcement and zero-trust security policies.

## Quick Start

```bash
# Enter development environment
nix develop
# or with direnv
direnv allow

# Build example
nix build .#example-app

# View generated manifests
cat result/manifests.yaml
```

## Architecture

### Design Principles

1. **Schema-Driven**: Kubernetes OpenAPI specs are the single source of truth
2. **Type-Safe**: Strict Nix type validation at build time
3. **Compliance-First**: Mandatory labeling and enforcement
4. **Zero-Trust**: Default-deny policies, explicit allows
5. **Multi-Layer**: Choose your abstraction level

### Three-Layer API

#### Layer 1: Raw Resources
Direct Kubernetes resource definition with strict type validation:

```nix
{
  resources = [
    {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = { name = "myapp"; namespace = "default"; };
      spec = { /* ... */ };
    }
  ];
}
```

#### Layer 2: Convenience Modules
Pre-built helpers for common patterns:

```nix
{
  myDeployment = layer2.deployment {
    name = "myapp";
    image = "myapp:1.0";
    replicas = 3;
    ports = [ 8080 ];
  };
}
```

#### Layer 3: High-Level Applications
Declare apps; framework generates all resources:

```nix
{
  applications.myApp = {
    name = "myapp";
    image = "myapp:1.0";
    replicas = 3;
    ports = [ 8080 ];
    
    compliance = {
      framework = "SOC2";
      level = "high";
      owner = "platform-team";
    };
    
    dependencies = [ "postgres" "redis" ];
  };
}
```

## Modules

### Core Modules

- **schema.nix**: API version resolution for k8s 1.28-1.31
- **types.nix**: Kubernetes type definitions and constructors
- **validation.nix**: Manifest validation framework
- **generators.nix**: Resource building and composition

### Compliance & Enforcement

- **compliance.nix**: Label injection and annotations
- **compliance-enforcement.nix**: Level-based enforcement (unrestricted → restricted)
- **compliance-profiles.nix**: Environment-specific (dev, staging, prod, regulated)

### Security Policies

- **policies.nix**: NetworkPolicy generation
- **policy-generation.nix**: Advanced policy composition and RBAC
- **rbac.nix**: Role/RoleBinding management and RBAC helpers

### API & Output

- **api.nix**: Three-layer abstraction API
- **manifest.nix**: Manifest assembly and validation
- **output.nix**: YAML/Helm generation

### Integration

- **external-secrets.nix**: ExternalSecret and SecretStore resources

## Compliance Levels

Nixernetes enforces five compliance levels:

### Unrestricted
- No special requirements
- Basic RBAC
- Use: Development/sandboxes

### Low
- Audit logging required
- Basic RBAC
- Use: Non-critical systems

### Medium (Default)
- Audit logging required
- Encryption enabled
- RBAC enforced
- NetworkPolicy required
- Restricted PSP
- Use: Standard production

### High
- All medium requirements
- Mutual TLS
- Strict pod security
- Enhanced isolation
- Use: Sensitive production systems

### Restricted
- All high requirements
- Binary authorization
- Image scanning
- Audit ID tracking
- Use: Regulated environments (PCI-DSS, HIPAA, etc.)

## Compliance Profiles

Environment-specific compliance configurations:

```nix
# Development: minimal overhead
development = {
  level = "low";
  requireNetworkPolicy = false;
  requireAudit = false;
};

# Staging: moderate protections
staging = {
  level = "medium";
  requireNetworkPolicy = true;
  requireAudit = true;
};

# Production: strong protections
production = {
  level = "high";
  requireNetworkPolicy = true;
  requireAudit = true;
  mutualTLS = true;
};

# Regulated: maximum protections
regulated = {
  level = "restricted";
  requireNetworkPolicy = true;
  requireAudit = true;
  mutualTLS = true;
  binaryAuthorization = true;
  imageScan = true;
};
```

## Policy Generation

### Zero-Trust Networking

Policies are auto-generated based on intent declarations:

```nix
applications.backend = {
  name = "backend";
  # Ingress from load balancer
  # Egress to postgres (from dependencies)
  # Default-deny everything else
  dependencies = [ "postgres" ];
  ports = [ 8080 ];
};
```

Generated policies:
1. **Default-Deny**: Block all traffic
2. **Dependency Egress**: Allow to postgres on port 5432
3. **Ingress Allow**: Accept traffic on port 8080

### RBAC

Automatic ServiceAccount and Role generation:

```nix
rbac.mkReadOnlyServiceAccount {
  name = "viewer";
  namespace = "default";
}
# Generates: ServiceAccount, Role, RoleBinding
```

## Secrets Management

ExternalSecrets integration for Vault, AWS Secrets Manager, etc:

```nix
externalSecrets.mkExternalSecret {
  name = "db-creds";
  namespace = "default";
  secretStore = "vault";
  data = [
    { remoteRef.key = "secret/data/db/password"; }
  ];
}
```

## Build System

### Development Shell

```bash
nix develop
# Tools available:
# - nix, nixpkgs-fmt
# - yq, jq (YAML/JSON processing)
# - python3 (for tooling)
```

### Flake Outputs

```bash
# Build library modules
nix build .#lib-schema
nix build .#lib-compliance

# Build example
nix build .#example-app

# Run tests
nix flake check
```

## Project Structure

```
nixernetes/
├── src/
│   ├── lib/                    # Core modules (11 files)
│   ├── modules/               # Convenience modules
│   ├── tools/                 # Utility scripts
│   └── examples/              # Example configurations
├── tests/                     # Test suite
├── docs/                      # Requirements & utilities
├── flake.nix                  # Nix build configuration
└── README.md
```

## Examples

### Simple Web App Deployment

See `src/examples/web-app.nix` for a basic example with:
- Multi-app deployment (web-app + postgres)
- Compliance configuration (SOC2, audit requirements)
- ExternalSecret for database password
- Resource constraints
- Dependency declarations

### Multi-Tier Production Application

See `src/examples/multi-tier-app.nix` and `docs/MULTI_TIER_DEPLOYMENT.md` for a comprehensive production example with:

**Architecture**:
- Frontend (Nginx SPA server) - 3 replicas
- API Gateway (Node.js) - 2 replicas  
- PostgreSQL Database - with 50Gi storage
- Redis Cache - with persistence
- RabbitMQ Message Queue - with clustering
- Prometheus Monitoring - with 100Gi time-series storage
- Grafana Dashboards - with pre-configured datasources

**Features Demonstrated**:
- Compliance enforcement (SOC2/Strict)
- Zero-trust networking with default-deny policies
- RBAC with least-privilege service accounts
- ExternalSecrets for sensitive data (Vault integration)
- Resource requests/limits for all components
- Health checks (liveness/readiness probes)
- Pod security standards (restricted)
- Observability with metrics and dashboards
- Multi-environment deployment patterns
- Data classification and audit trails

**Quick Start**:
```bash
# View the comprehensive example
cat src/examples/multi-tier-app.nix

# Read the deployment guide
cat docs/MULTI_TIER_DEPLOYMENT.md

# Review security policies
cat docs/SECURITY_POLICIES.md
```

This example showcases all Nixernetes capabilities in a realistic, production-grade scenario.

## Features

### Type Safety
- Strict Kubernetes types
- Build-time schema validation
- Clear error messages

### Compliance
- Mandatory label injection
- Five compliance levels
- Environment-specific profiles
- Compliance reporting
- Audit trails with build traceability

### Security
- Default-deny network policies
- RBAC with least privilege
- Pod security policies
- Kyverno integration ready
- Zero-trust architecture

### Integration
- ExternalSecrets for secret management
- Helm chart generation
- Multi-cluster support
- Version compatibility checking

### Developer Experience
- Clear, layered API
- Extensive examples
- Comprehensive error messages
- Interactive development shell

## Advanced Usage

### Multi-Environment Deployment

```nix
mkMultiEnvironmentDeployment {
  name = "myapp";
  framework = "SOC2";
  owner = "platform-team";
  
  dev.compliance.level = "low";
  staging.compliance.level = "medium";
  production.compliance.level = "high";
}
```

### Custom Policies

Compose policies for specific requirements:

```nix
policyGeneration.mkApplicationPolicies {
  name = "myapp";
  namespace = "default";
  dependencies = [ "postgres" ];
  exposedPorts = [ 8080 8443 ];
  allowedClients = [ /* */ ];
}
```

### Validation & Reporting

```nix
manifest.buildManifest {
  resources = [ /* ... */ ];
  kubernetesVersion = "1.30";
} |> manifest.validateForDeployment
```

## Contributing

Contributions welcome! Please:

1. Follow Nix style guide (format with `nix fmt`)
2. Add tests for new modules
3. Update documentation
4. Keep commits focused and well-messaged

## Standards & Best Practices

- All code formatted with `nixpkgs-fmt`
- Comprehensive module documentation
- Type validation at build time
- Compliance checks on all deployments
- Audit trails for traceability

## Performance Characteristics

- Evaluation time: < 1 second for typical manifests
- Generated manifests: compact, optimized
- Network policies: minimal overhead
- RBAC evaluation: O(n) resources

## Roadmap

- [ ] Kyverno policy templating
- [ ] Multi-cluster orchestration
- [ ] GitOps integration
- [ ] Observability sidecar injection
- [ ] Advanced policy composition
- [ ] Cost optimization recommendations

## Support & Resources

- GitHub Issues for bug reports
- Discussions for questions
- PR reviews for contributions
- Examples in `src/examples/`

## License

[To be determined]

## Architecture Decision Records

See `docs/` for detailed architecture decisions and design rationale.
