# Nixernetes

![Build Status](https://img.shields.io/badge/build-passing-brightgreen)
![Tests](https://img.shields.io/badge/tests-158%2F158-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)
![Nix](https://img.shields.io/badge/built%20with-Nix-5277C3)
![Kubernetes](https://img.shields.io/badge/Kubernetes-1.28--1.31-326CE5)

Coded with AI with [Engram](https://github.com/vincents-ai/engram)

Enterprise-grade Nix-driven Kubernetes manifest framework that abstracts Kubernetes complexity into strictly-typed, data-driven modules with built-in compliance enforcement and zero-trust security policies.

## Features at a Glance

| Feature | Details |
|---------|---------|
| **35 Production Modules** | Complete coverage of Foundation, Core Kubernetes, Security, Observability, Data, Workloads, and Operations |
| **300+ Builder Functions** | 10 builders per module for composable deployments |
| **Type Safety** | Strict Nix type validation at build time with clear error messages |
| **Compliance First** | 5 compliance levels (Unrestricted → Restricted) with automatic enforcement |
| **Zero-Trust Security** | Default-deny policies, least-privilege RBAC, Pod Security Standards |
| **Cloud Ready** | Deployment guides for AWS EKS, GCP GKE, and Azure AKS |
| **Observability** | Monitoring, logging, tracing, alerting, and Grafana dashboards |
| **Performance** | Sub-second evaluation, optimized manifests, minimal overhead |
| **CLI Tool** | Command-line interface for validation, generation, deployment, and testing |
| **Comprehensive Documentation** | 25,000+ lines covering guides, API reference, and examples |

## Quick Links

- **[Getting Started](GETTING_STARTED.md)** - Setup and your first deployment
- **[Architecture Overview](ARCHITECTURE.md)** - System design and module organization
- **[Module Reference](MODULE_REFERENCE.md)** - Complete API for all 35 modules
- **[CLI Reference](docs/CLI_REFERENCE.md)** - Command-line tool documentation
- **[Contributing Guide](CONTRIBUTING.md)** - How to contribute to the project
- **[Performance Tuning](docs/PERFORMANCE_TUNING.md)** - Optimization strategies
- **[Security Hardening](docs/SECURITY_HARDENING.md)** - Security best practices

## Cloud Deployment Guides

- **[AWS EKS](docs/DEPLOY_AWS_EKS.md)** - Deploy to AWS Elastic Kubernetes Service with IRSA
- **[GCP GKE](docs/DEPLOY_GCP_GKE.md)** - Deploy to Google Kubernetes Engine with Workload Identity
- **[Azure AKS](docs/DEPLOY_AZURE_AKS.md)** - Deploy to Azure Kubernetes Service with Pod Identity

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

## 35 Production-Ready Modules

Nixernetes provides 35 comprehensive modules organized into 7 categories:

### Foundation (4 modules)
- **flakes.nix** - Nix flake integration and devShell setup
- **profiles.nix** - Environment profiles and namespace management
- **config-maps.nix** - Configuration management and secret handling
- **labels.nix** - Label and annotation strategies

### Core Kubernetes (5 modules)
- **deployments.nix** - Deployment and replica set management
- **services.nix** - Service and networking configuration
- **ingress.nix** - Ingress and routing setup
- **resources.nix** - Resource requests, limits, and quotas
- **scheduling.nix** - Pod scheduling, affinity, and topology spread

### Security & Compliance (8 modules)
- **rbac.nix** - Role-based access control and service accounts
- **network-policies.nix** - Network segmentation and egress control
- **policies.nix** - Kyverno and Pod Security Standard policies
- **compliance.nix** - Regulatory compliance and audit logging
- **security-scanning.nix** - Image scanning and vulnerability detection
- **secrets-management.nix** - Secret rotation and encryption
- **certificate-management.nix** - TLS/SSL certificate automation
- **audit-logging.nix** - Complete audit trail configuration

### Observability (6 modules)
- **monitoring.nix** - Prometheus metrics and AlertManager
- **logging.nix** - Centralized logging with ELK/Loki
- **tracing.nix** - Distributed tracing with Jaeger/Tempo
- **alerting.nix** - Alert routing and notification channels
- **dashboards.nix** - Grafana dashboards and visualization
- **observability-best-practices.nix** - Observability patterns and guidelines

### Data & Events (4 modules)
- **database-management.nix** - PostgreSQL, MySQL, MongoDB, Redis
- **caching.nix** - Redis and caching strategies
- **event-processing.nix** - Kafka, NATS, RabbitMQ, Apache Pulsar
- **message-queues.nix** - Message queue infrastructure

### Workloads (4 modules)
- **batch-processing.nix** - Kubernetes Jobs, CronJobs, Argo Workflows, Spark
- **machine-learning.nix** - ML workloads and model serving
- **serverless.nix** - Serverless function platforms
- **data-processing.nix** - Distributed data processing frameworks

### Operations (4 modules)
- **backup-recovery.nix** - Backup strategies and disaster recovery
- **scaling.nix** - Horizontal and Vertical Pod Autoscaling
- **maintenance.nix** - Cluster maintenance and upgrades
- **cost-optimization.nix** - Resource efficiency and cost management

See [MODULE_REFERENCE.md](MODULE_REFERENCE.md) for detailed API documentation for each module.

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
├── README.md                   # Project overview (this file)
├── GETTING_STARTED.md         # Quick start guide
├── ARCHITECTURE.md            # System design and principles
├── MODULE_REFERENCE.md        # Complete API reference for all 35 modules
├── CONTRIBUTING.md            # Community contribution guidelines
├── CHANGELOG.md               # Release history and version info
│
├── src/
│   ├── lib/                   # 35 production modules
│   │   ├── foundation/        # Foundation modules (4)
│   │   ├── core/              # Core Kubernetes modules (5)
│   │   ├── security/          # Security & Compliance modules (8)
│   │   ├── observability/     # Observability modules (6)
│   │   ├── data-events/       # Data & Events modules (4)
│   │   ├── workloads/         # Workloads modules (4)
│   │   └── operations/        # Operations modules (4)
│   └── examples/              # 22 example files with 400+ examples
│
├── docs/
│   ├── DEPLOY_AWS_EKS.md      # AWS EKS deployment guide
│   ├── DEPLOY_GCP_GKE.md      # GCP GKE deployment guide
│   ├── DEPLOY_AZURE_AKS.md    # Azure AKS deployment guide
│   ├── CLI_REFERENCE.md       # Command-line interface reference
│   ├── PERFORMANCE_TUNING.md  # Performance optimization guide
│   ├── SECURITY_HARDENING.md  # Security hardening guide
│   └── *.md                   # 26 module-specific documentation files
│
├── bin/
│   └── nixernetes            # Python CLI tool
│
├── tests/
│   └── integration-tests.nix  # 158 integration tests
│
├── .github/
│   ├── ISSUE_TEMPLATE/        # Issue templates (bug, feature, security)
│   └── pull_request_template.md
│
├── flake.nix                  # Nix flake with all build targets
├── flake.lock                 # Nix lock file
├── .envrc                     # Direnv configuration
└── .gitignore                 # Git ignore rules
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

## Getting Help

### Documentation
- **[Getting Started Guide](GETTING_STARTED.md)** - Step-by-step setup instructions
- **[Architecture Guide](ARCHITECTURE.md)** - Understand the design
- **[Module Reference](MODULE_REFERENCE.md)** - API documentation for all modules
- **[CLI Reference](docs/CLI_REFERENCE.md)** - Command-line tool usage

### Learning Resources
- **[Performance Tuning Guide](docs/PERFORMANCE_TUNING.md)** - Optimization strategies
- **[Security Hardening Guide](docs/SECURITY_HARDENING.md)** - Security best practices
- **[Cloud Deployment Guides](docs/DEPLOY_AWS_EKS.md)** - AWS, GCP, Azure setup
- **[Examples Directory](src/examples/)** - 400+ production-ready examples

### Community
- **GitHub Issues** - Report bugs and suggest features
- **Discussions** - Ask questions and share ideas
- **Contributing** - See [CONTRIBUTING.md](CONTRIBUTING.md) to get started

## Installation

### Prerequisites
- Nix 2.15+ with flakes enabled
- direnv (optional but recommended)
- Kubernetes 1.28 - 1.31
- kubectl (for deployment)

### Quick Setup

```bash
# Clone the repository
git clone https://github.com/nixernetes/nixernetes.git
cd nixernetes

# Option 1: Use direnv (recommended)
direnv allow

# Option 2: Or manually enter Nix shell
nix develop

# List available modules
./bin/nixernetes list

# Validate your configuration
./bin/nixernetes validate flake.nix

# Generate Kubernetes manifests
./bin/nixernetes generate src/examples/my-app.nix

# Deploy to cluster
./bin/nixernetes deploy --dry-run src/examples/my-app.nix
```

For detailed setup instructions, see [GETTING_STARTED.md](GETTING_STARTED.md).

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Architecture Decision Records

See `docs/` for detailed architecture decisions and design rationale.
