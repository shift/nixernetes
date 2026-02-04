# Getting Started with Nixernetes

Welcome to Nixernetes - the enterprise Kubernetes framework built on Nix. This guide will help you set up and deploy your first Kubernetes infrastructure using Nixernetes.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Your First Deployment](#your-first-deployment)
4. [Core Concepts](#core-concepts)
5. [Common Patterns](#common-patterns)
6. [Next Steps](#next-steps)
7. [Troubleshooting](#troubleshooting)

## Prerequisites

Before you begin, ensure you have:

- **NixOS or Nix installed** - [Installation guide](https://nixos.org/download)
- **direnv** - For automatic development environment loading
- **Basic Kubernetes knowledge** - Understanding of Pods, Services, Deployments
- **A text editor** - VS Code, Vim, Emacs, or your preference
- **Git** - For version control

### System Requirements

- **CPU**: 2+ cores (4+ recommended for development)
- **RAM**: 4GB minimum (8GB+ recommended)
- **Disk**: 5GB free space
- **Network**: Internet access for Nix package downloads

## Installation

### Step 1: Clone the Repository

```bash
git clone https://github.com/anomalyco/nixernetes.git
cd nixernetes
```

### Step 2: Enter the Development Environment

```bash
direnv allow
```

This will automatically load the Nix development shell configured in `flake.nix`, which includes all necessary tools and dependencies.

If direnv is not configured, you can enter the environment manually:

```bash
nix develop
```

### Step 3: Verify Installation

```bash
# Check that you're in the nix shell
echo $IN_NIX_SHELL  # Should output: impure

# Verify nix tools are available
nix --version
nixpkgs-fmt --version
```

### Step 4: Run Flake Checks

Verify everything works by running the test suite:

```bash
nix flake check --offline
```

You should see output indicating all 24 checks passed.

## Your First Deployment

### Understanding the Structure

Nixernetes organizes functionality into 35 modules, each providing specialized Kubernetes management:

```
nixernetes/
├── src/
│   ├── lib/              # Core modules (35 total)
│   │   ├── schema.nix
│   │   ├── compliance.nix
│   │   ├── kubernetes-core.nix
│   │   ├── batch-processing.nix
│   │   ├── database-management.nix
│   │   ├── event-processing.nix
│   │   └── ... (29 more modules)
│   └── examples/         # Real-world examples
├── docs/                 # Module documentation
├── tests/                # Integration tests
├── flake.nix            # Project definition
└── README.md            # Overview
```

### Basic Example: Deploy a Simple Workload

Create a file `my-first-deployment.nix`:

```nix
{ lib, pkgs }:

let
  # Import the core Kubernetes module
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  
  # Define a simple deployment
  myApp = k8s.mkDeployment {
    namespace = "default";
    name = "hello-world";
    labels = {
      app = "hello-world";
      version = "1.0.0";
    };
    
    replicas = 3;
    
    containers = [
      {
        name = "app";
        image = "nginx:latest";
        ports = [{ containerPort = 80; }];
        
        resources = {
          limits.memory = "128Mi";
          limits.cpu = "100m";
          requests.memory = "64Mi";
          requests.cpu = "50m";
        };
      }
    ];
  };
  
  # Define a service to expose the deployment
  myService = k8s.mkService {
    namespace = "default";
    name = "hello-world";
    labels = {
      app = "hello-world";
    };
    
    type = "LoadBalancer";
    selector = { app = "hello-world"; };
    
    ports = [
      {
        port = 80;
        targetPort = 80;
        protocol = "TCP";
      }
    ];
  };

in
{
  # Export the Kubernetes resources
  resources = {
    deployments = [ myApp ];
    services = [ myService ];
  };
}
```

### Apply the Configuration

To generate and view the Kubernetes YAML:

```bash
# Load and evaluate the configuration
nix eval ./my-first-deployment.nix --json | jq .

# Or generate YAML directly (if you have yq installed)
nix eval ./my-first-deployment.nix --json > deployment.json
```

## Core Concepts

### 1. Modules

Nixernetes is built on 35 specialized modules. Each module provides builders that simplify Kubernetes resource creation:

```nix
let
  kube = import ./src/lib/kubernetes-core.nix { inherit lib; };
  batch = import ./src/lib/batch-processing.nix { inherit lib; };
  db = import ./src/lib/database-management.nix { inherit lib; };
  events = import ./src/lib/event-processing.nix { inherit lib; };
in
{
  # Use builders from different modules
  deployment = kube.mkDeployment { ... };
  job = batch.mkKubernetesJob { ... };
  postgres = db.mkPostgreSQL { ... };
  kafka = events.mkKafkaCluster { ... };
}
```

### 2. Builders

Each module exports builder functions (like `mkDeployment`, `mkService`) that generate Kubernetes resources:

```nix
# Simple builder with minimal config
resource = module.mkBuilder {
  name = "my-resource";
  # ... other required fields
};

# Complex builder with all features
resource = module.mkBuilder {
  name = "my-resource";
  namespace = "production";
  labels = { environment = "prod"; };
  annotations = { "owner" = "platform-team"; };
  # ... additional configuration
};
```

### 3. Namespaces

Organize your resources by namespace:

```nix
{
  # Resources in different namespaces
  "default" = { ... };
  "kube-system" = { ... };
  "monitoring" = { ... };
  "production" = { ... };
}
```

### 4. Labels and Selectors

Use labels to organize and select resources:

```nix
deployment = mkDeployment {
  labels = {
    app = "my-app";
    version = "1.0";
    tier = "backend";
    environment = "prod";
  };
  
  # Service uses labels to find pods
  # selector = { app = "my-app"; };
};
```

### 5. Framework Features

All modules provide automatic:

- **Compliance injection** - Labels, annotations for audit trails
- **Traceability** - Resource ownership and modification tracking
- **Policy enforcement** - Default security and resource policies
- **Validation** - Configuration validation before deployment

## Common Patterns

### Pattern 1: Multi-Tier Application

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  # Frontend
  frontend = k8s.mkDeployment {
    name = "frontend";
    replicas = 3;
    labels = { tier = "frontend"; };
    containers = [{
      image = "myregistry.azurecr.io/frontend:latest";
      ports = [{ containerPort = 3000; }];
    }];
  };

  # Backend API
  backend = k8s.mkDeployment {
    name = "backend";
    replicas = 5;
    labels = { tier = "backend"; };
    containers = [{
      image = "myregistry.azurecr.io/api:latest";
      ports = [{ containerPort = 8080; }];
    }];
  };

  # Database
  database = k8s.mkStatefulSet {
    name = "database";
    replicas = 1;
    labels = { tier = "data"; };
    containers = [{
      image = "postgres:15";
      ports = [{ containerPort = 5432; }];
    }];
  };
}
```

### Pattern 2: Batch Processing Pipeline

```nix
let
  batch = import ./src/lib/batch-processing.nix { inherit lib; };
  events = import ./src/lib/event-processing.nix { inherit lib; };
in
{
  # Event stream
  kafka = events.mkKafkaCluster {
    name = "data-pipeline";
    replicas = 3;
    brokers = 3;
  };

  # Batch jobs triggered by events
  processor = batch.mkKubernetesJob {
    name = "data-processor";
    image = "myapp:latest";
    schedule = "0 */6 * * *";  # Every 6 hours
  };

  # Airflow orchestration
  orchestration = batch.mkAirflowDeployment {
    name = "data-orchestration";
    dags = [
      { name = "etl-pipeline"; }
      { name = "data-quality"; }
    ];
  };
}
```

### Pattern 3: Observability Stack

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  perf = import ./src/lib/performance-analysis.nix { inherit lib; };
in
{
  # Prometheus for metrics
  prometheus = k8s.mkStatefulSet {
    name = "prometheus";
    containers = [{
      image = "prom/prometheus:latest";
      ports = [{ containerPort = 9090; }];
    }];
  };

  # Grafana for dashboards
  grafana = k8s.mkDeployment {
    name = "grafana";
    replicas = 2;
    containers = [{
      image = "grafana/grafana:latest";
      ports = [{ containerPort = 3000; }];
    }];
  };

  # Performance monitoring
  monitoring = perf.mkPerformanceAnalysis {
    name = "app-monitoring";
    metrics = [ "cpu" "memory" "network" ];
  };
}
```

### Pattern 4: Multi-Database Setup

```nix
let
  db = import ./src/lib/database-management.nix { inherit lib; };
in
{
  # PostgreSQL for transactional data
  postgres = db.mkPostgreSQL {
    name = "app-db";
    version = "15";
    storage = "10Gi";
  };

  # MongoDB for documents
  mongo = db.mkMongoDB {
    name = "document-store";
    replicas = 3;
    storage = "20Gi";
  };

  # Redis for caching
  redis = db.mkRedis {
    name = "cache";
    maxmemory = "2Gi";
    persistence = true;
  };

  # Backups
  backups = db.mkDatabaseBackup {
    name = "backup-policy";
    databases = [ "app-db" "document-store" ];
    schedule = "0 2 * * *";  # Daily at 2 AM
  };
}
```

## Next Steps

### 1. Explore Module Documentation

Each module has comprehensive documentation in `docs/`:

- **Core Infrastructure**: `KUBERNETES_CORE.md`, `CONTAINER_REGISTRY.md`
- **Workloads**: `BATCH_PROCESSING.md`, `ML_OPERATIONS.md`
- **Data**: `DATABASE_MANAGEMENT.md`, `EVENT_PROCESSING.md`
- **Security**: `SECRETS_MANAGEMENT.md`, `SECURITY_POLICIES.md`
- **Operations**: `DISASTER_RECOVERY.md`, `PERFORMANCE_ANALYSIS.md`

### 2. Study Real-World Examples

Explore complete examples in `src/examples/`:

```bash
ls src/examples/*.nix
# See batch-processing-example.nix, database-management-example.nix, etc.
```

Each example file contains 18 production-ready configurations.

### 3. Understand Project Configuration

Review key files:

- `flake.nix` - Project definition, dependencies, build instructions
- `src/lib/schema.nix` - Core validation schema
- `src/lib/compliance.nix` - Compliance framework
- `README.md` - Full project overview

### 4. Deploy to Your Environment

- **Local Development**: Use `kind` or `minikube`
- **Cloud Providers**: Follow provider-specific guides
- **On-Premises**: Use your existing Kubernetes cluster

### 5. Customize for Your Needs

Start building your infrastructure by:

1. Creating a `flake.nix` in your project
2. Importing Nixernetes modules
3. Defining your infrastructure in Nix
4. Using Nix tooling to validate and deploy

Example project structure:

```
my-platform/
├── flake.nix
├── infrastructure/
│   ├── base.nix
│   ├── monitoring.nix
│   ├── databases.nix
│   ├── applications.nix
│   └── production.nix
├── modules/
│   └── custom-builders.nix
└── examples/
    └── deployment.nix
```

## Troubleshooting

### Issue: `nix develop` fails with "unknown system"

**Solution**: Ensure you're on a supported platform (Linux x86_64 is primary):

```bash
nix flake show  # See available systems
```

### Issue: "Argument list too long" during builds

**Solution**: This is fixed in flake.nix. If you encounter it, ensure you're using the latest version.

### Issue: Modules not found when importing

**Solution**: Use absolute paths or ensure proper import context:

```nix
# Correct
let
  module = import ./src/lib/module-name.nix { inherit lib; };
in { ... }

# Wrong - relative paths may not work
let
  module = import ../src/lib/module-name.nix { inherit lib; };
in { ... }
```

### Issue: Type validation errors

**Solution**: Check module documentation for required fields and types:

```bash
# Example: Check kubernetes-core.nix documentation
cat docs/KUBERNETES_CORE.md | grep -A 10 "mkDeployment"
```

### Issue: "Nix flake check" fails

**Solution**: Run with offline flag to see detailed errors:

```bash
nix flake check --offline 2>&1 | tail -50
```

Check that:
- All referenced files exist
- Module syntax is correct (use `nixpkgs-fmt` to format)
- No circular imports

### Getting Help

- **Documentation**: Browse `docs/*.md` files
- **Examples**: Study `src/examples/*.nix` files
- **Tests**: Review `tests/integration-tests.nix`
- **Issues**: Report bugs at https://github.com/anomalyco/opencode

## Key Commands Reference

```bash
# Development environment
nix develop                          # Enter dev shell
direnv allow                         # Auto-load dev shell

# Testing and validation
nix flake check --offline            # Run all checks
nix flake show                       # Show outputs
nixpkgs-fmt src/                     # Format Nix files

# Building packages
nix build .#lib-schema               # Build specific package
nix build                            # Build everything

# Evaluation
nix eval ./config.nix --json         # Evaluate as JSON
nix eval ./config.nix --json | jq .  # Pretty print

# Debugging
nix log /nix/store/...              # View build logs
nix repl                             # Interactive REPL
```

## Additional Resources

- **Official Documentation**: https://nixernetes.io/docs (future)
- **Kubernetes Concepts**: https://kubernetes.io/docs/concepts
- **Nix Manual**: https://nixos.org/manual/nix
- **Nix Pills**: https://nixos.org/guides/nix-pills/

## Summary

You now have:

✓ Installed Nixernetes and verified setup  
✓ Understood the module architecture  
✓ Created and evaluated your first configuration  
✓ Learned common patterns and workflows  
✓ Know where to find additional documentation  

**Next**: Pick a module from `docs/` that interests you and explore its builders and examples. Build incrementally and leverage the framework's validation and policy features.

Happy deploying! 🚀
