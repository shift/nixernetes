# Nixernetes

**Enterprise Nix-driven Kubernetes Manifest Framework with Auto-API Discovery**

Nixernetes is a framework that abstracts the complexities of Kubernetes into high-level, strictly-typed, and data-driven modules. It provides:

- **Schema-Driven Generation**: Kubernetes resources are validated against official OpenAPI specifications
- **Enterprise Compliance**: Mandatory compliance labeling and traceability built-in
- **Zero-Trust Security**: Automatic NetworkPolicy and Kyverno policy generation from intent declarations
- **Multi-Layer API**: Choose your abstraction level - raw resources, convenience modules, or high-level applications
- **Dual Output Modes**: Generate raw YAML manifests or complete Helm charts
- **ExternalSecrets Integration**: Seamless secret management with Vault, AWS Secrets Manager, and more

## Quick Start

### Prerequisites

- Nix with flakes enabled
- direnv (optional, but recommended)

### Setup

```bash
# Clone or create the project
cd nixernetes

# Enter the development shell
nix develop
# or with direnv: direnv allow

# Build an example
nix build .#example-app
```

## Architecture

Nixernetes is organized into three abstraction layers:

### Layer 1: Raw Kubernetes Resources
Direct definition of Kubernetes resources with strict type validation against OpenAPI schemas.

```nix
{
  resources.myPod = {
    apiVersion = "v1";
    kind = "Pod";
    metadata = { name = "my-pod"; };
    spec = { ... };
  };
}
```

### Layer 2: Convenience Modules
Pre-built modules for common patterns (Deployments, Services, etc.) with sensible defaults.

```nix
{
  deployments.myApp = {
    image = "myapp:1.0";
    replicas = 3;
    ports = [ 8080 ];
  };
}
```

### Layer 3: High-Level Applications
Declare applications with dependencies, compliance, and exposure - the framework generates all resources.

```nix
{
  applications.myApp = {
    image = "myapp:1.0";
    replicas = 3;
    ports = [ 8080 ];
    compliance.framework = "PCI-DSS";
    compliance.level = "restricted";
    dependencies = [ "postgres" "redis" ];
  };
}
```

## Key Features

### Automated API Version Resolution
- Supports Kubernetes 1.28, 1.29, 1.30, 1.31
- Automatically resolves preferred `apiVersion` for each resource kind
- Build-time errors for unsupported API versions

### Compliance Engine
- Inject mandatory labels into all resources
- Build-time enforcement of compliance requirements
- Traceability annotations linking resources to Nix build IDs

### Zero-Trust Security
- Default-deny NetworkPolicies generated automatically
- Dependency-based egress rules
- Kyverno ClusterPolicies for admission control

### Output Modes
- **Manifest Mode**: Single `manifests.yaml` with properly ordered resources
- **Helm Mode**: Complete Helm chart with Chart.yaml, values.yaml, and templated resources

## Project Structure

```
nixernetes/
├── flake.nix                 # Nix flake configuration
├── flake.lock               # Locked dependency versions
├── .envrc                   # direnv configuration
├── docs/
│   ├── requirements.md      # Full technical requirements
│   └── api_schema_parser.py # Python utility for OpenAPI parsing
├── src/
│   ├── lib/
│   │   ├── default.nix      # Module system definitions
│   │   ├── schema.nix       # API version resolution
│   │   ├── compliance.nix   # Compliance labeling engine
│   │   ├── policies.nix     # Policy generation (NetworkPolicy, Kyverno)
│   │   └── output.nix       # Output formatters (YAML, Helm)
│   ├── modules/             # Convenience modules (Layer 2)
│   ├── tools/               # Utility scripts and tools
│   └── examples/            # Example configurations
└── tests/                   # Test suite
```

## Development

### Running the dev shell

```bash
nix develop
# or with direnv
direnv allow
direnv reload
```

### Building

```bash
# Build an example
nix build .#example-app

# View the generated manifests
cat result/manifests.yaml
```

### Testing

```bash
# Run tests
nix flake check
```

### Formatting

```bash
# Format Nix files
nix fmt
```

## Implementation Plan

The project is organized into 8 implementation phases:

1. **Foundation & Infrastructure** - Project structure, tooling, flake setup
2. **Schema System & Type Validation** - OpenAPI schema integration, type generation
3. **Compliance & Labeling Engine** - Mandatory labels, traceability, enforcement
4. **Zero-Trust Policy Generation** - NetworkPolicies, Kyverno policies
5. **Multi-Layer Abstraction API** - Layer 1, 2, 3 implementations
6. **Output Generation & Formatters** - YAML and Helm output
7. **ExternalSecrets Integration** - Secret management
8. **Documentation & Examples** - User guide and examples

See Engram task system for detailed implementation details.

## Contributing

Please follow these guidelines:

- Write tests for all new functionality
- Keep Nix files formatted with `nix fmt`
- Document complex logic with comments
- Add examples for new features

## License

[To be determined]

## Support

For issues, questions, or contributions, please refer to the GitHub repository.
