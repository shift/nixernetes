# Nixernetes API Reference

## Overview

Complete API reference for the Nixernetes framework.

## Schema Module (`schema.nix`)

API version resolution and Kubernetes schema management.

### Functions

```nix
# Get API version for resource kind
resolveApiVersion { 
  kind = "Deployment";
  kubernetesVersion = "1.30";
}
# Returns: "apps/v1"

# Get supported Kubernetes versions
getSupportedVersions  
# Returns: ["1.28" "1.29" "1.30" "1.31"]

# Check if version is supported
isSupportedVersion "1.30"  # Returns: true

# Get full API map for version
getApiMap "1.30"
```

## Types Module (`types.nix`)

Kubernetes resource type definitions.

### Types

```nix
k8sResource        # Base resource type
k8sMetadata        # Metadata submodule
deploymentSpec     # Deployment spec
serviceSpec        # Service spec
```

### Constructors

```nix
mkDeployment {
  name = "myapp";
  namespace = "default";
  replicas = 3;
  selector.matchLabels = { "app" = "myapp"; };
  template = { /* ... */ };
}

mkService {
  name = "myapp";
  type = "ClusterIP";
  ports = [ { port = 8080; } ];
}

mkNamespace { name = "default"; }
mkConfigMap { name = "config"; data = { }; }
mkSecret { name = "secret"; data = { }; }
```

## Compliance Module (`compliance.nix`)

Label injection and annotations.

### Functions

```nix
# Generate compliance labels
mkComplianceLabels {
  framework = "SOC2";
  level = "high";
  owner = "platform-team";
  dataClassification = "internal";
  auditRequired = true;
}

# Inject labels into resource
withComplianceLabels {
  resource = myDeployment;
  labels = { "nixernetes.io/framework" = "SOC2"; };
}

# Inject traceability annotations
withTraceability {
  resource = myDeployment;
  buildId = "abc123";
}

# Validate compliance labels present
validateComplianceLabels {
  resource = myDeployment;
  requiredLabels = { "nixernetes.io/framework" = "SOC2"; };
}
```

## Compliance Enforcement Module (`compliance-enforcement.nix`)

Policy generation and enforcement.

### Levels

- `unrestricted`: No special requirements
- `low`: Basic compliance (audit + RBAC)
- `medium`: Standard compliance (encryption + policies)
- `high`: Strict compliance (mTLS + hardening)
- `restricted`: Maximum compliance (binary auth + scanning)

### Functions

```nix
# Get requirements for level
getComplianceRequirements "high"

# Check resource compliance
checkCompliance {
  resource = myDeployment;
  level = "high";
}

# Generate compliance report
generateComplianceReport {
  resources = [ /* ... */ ];
  level = "high";
}

# Enforce compliance on resources
enforceCompliance {
  resources = [ /* ... */ ];
  level = "high";
  buildId = "abc123";
  failOnNoncompliant = true;
}

# Create audit trail
mkAuditTrail {
  resources = [ /* ... */ ];
  level = "high";
  timestamp = "2024-01-01";
  commitId = "abc123";
}
```

## Compliance Profiles Module (`compliance-profiles.nix`)

Environment-specific compliance.

### Profiles

```nix
getProfile "development"   # Low compliance
getProfile "staging"       # Medium compliance
getProfile "production"    # High compliance
getProfile "regulated"     # Restricted compliance
```

### Functions

```nix
# Create environment-specific compliance
mkEnvironmentCompliance {
  environment = "production";
  framework = "SOC2";
  owner = "platform-team";
}

# Check deployment compatibility
isCompatible {
  deployment = myApp;
  environment = "production";
}

# Multi-environment configuration
mkMultiEnvironmentDeployment {
  name = "myapp";
  framework = "SOC2";
  owner = "platform-team";
  dev = { /* ... */ };
  staging = { /* ... */ };
  production = { /* ... */ };
}
```

## Policies Module (`policies.nix`)

Basic NetworkPolicy and Kyverno generation.

### Functions

```nix
# Default-deny NetworkPolicy
mkDefaultDenyNetworkPolicy {
  name = "myapp";
  namespace = "default";
  apiVersion = "networking.k8s.io/v1";
}

# Dependency NetworkPolicy
mkDependencyNetworkPolicy {
  name = "myapp";
  namespace = "default";
  apiVersion = "networking.k8s.io/v1";
  dependencies = [ "postgres" ];
}

# Ingress NetworkPolicy
mkIngressNetworkPolicy {
  name = "myapp";
  namespace = "default";
  apiVersion = "networking.k8s.io/v1";
  ports = [ 8080 ];
}

# Kyverno ClusterPolicy
mkComplianceClusterPolicy {
  framework = "SOC2";
  level = "high";
}
```

## Policy Generation Module (`policy-generation.nix`)

Advanced policy composition.

### Functions

```nix
# RBAC for service account
mkServiceAccountRBAC {
  name = "myapp";
  namespace = "default";
  permissions = [ /* ... */ ];
}

# Pod security policy
mkPodSecurityPolicy {
  name = "restricted";
  level = "high";
}

# Application policies
mkApplicationPolicies {
  name = "myapp";
  namespace = "default";
  apiVersion = "networking.k8s.io/v1";
  dependencies = [ "postgres" ];
  exposedPorts = [ 8080 ];
  allowedClients = [ /* ... */ ];
}
```

## RBAC Module (`rbac.nix`)

Role-based access control.

### Functions

```nix
# Create Role
mkRole {
  name = "reader";
  namespace = "default";
  rules = [ /* ... */ ];
}

# Create RoleBinding
mkRoleBinding {
  name = "reader-binding";
  namespace = "default";
  role = "reader";
  subjects = [ /* ... */ ];
}

# Create ServiceAccount with read-only permissions
mkReadOnlyServiceAccount {
  name = "viewer";
  namespace = "default";
}

# Create ServiceAccount with edit permissions
mkEditServiceAccount {
  name = "editor";
  namespace = "default";
}

# Common rule sets
readPodsRule           # Get/list/watch pods
readDeploymentsRule    # Get/list/watch deployments
configMapsRule         # Full access to configmaps
secretsRule            # Full access to secrets
```

## API Module (`api.nix`)

Multi-layer abstraction API.

### Layer 2: Convenience Modules

```nix
layer2.deployment {
  name = "myapp";
  image = "myapp:1.0";
  replicas = 2;
  ports = [ 8080 ];
}

layer2.service {
  name = "myapp";
  port = 8080;
  type = "ClusterIP";
}

layer2.configMap { name = "config"; data = { }; }
layer2.namespace { name = "myns"; }
```

### Layer 3: Applications

```nix
layer3.application {
  name = "myapp";
  image = "myapp:1.0";
  replicas = 3;
  ports = [ 8080 ];
  
  compliance = {
    framework = "SOC2";
    level = "high";
    owner = "platform-team";
  };
  
  dependencies = [ "postgres" ];
  resources = { /* ... */ };
}
```

## Manifest Module (`manifest.nix`)

Manifest assembly and generation.

### Functions

```nix
# Build manifest
buildManifest {
  resources = [ /* ... */ ];
  kubernetesVersion = "1.30";
}

# Convert to YAML
toYAML resources

# Generate Helm chart
toHelmChart {
  name = "myapp";
  resources = [ /* ... */ ];
  version = "1.0.0";
  description = "My app";
}

# Generate report
generateReport { manifest = myManifest; }

# Validate manifest
validateForDeployment { manifest = myManifest; }
```

## Output Module (`output.nix`)

YAML and Helm generation.

### Functions

```nix
# Order resources for kubectl apply
orderResourcesForApply resources

# Convert to YAML
resourcesToYaml resources

# Generate Helm chart
mkHelmChart {
  name = "myapp";
  resources = [ /* ... */ ];
  version = "1.0.0";
}
```

## ExternalSecrets Module (`external-secrets.nix`)

Secret management integration.

### Functions

```nix
# Create ExternalSecret
mkExternalSecret {
  name = "db-password";
  namespace = "default";
  secretStore = "vault";
  data = [ /* ... */ ];
}

# Create Vault SecretStore
mkVaultSecretStore {
  name = "vault";
  namespace = "default";
  server = "https://vault.example.com";
  auth = { /* ... */ };
}

# Create AWS SecretStore
mkAWSSecretStore {
  name = "aws-secrets";
  namespace = "default";
  region = "us-east-1";
  auth = { /* ... */ };
}

# Create ClusterSecretStore
mkClusterSecretStore {
  name = "global-vault";
  provider = { /* ... */ };
}
```

## Validation Module (`validation.nix`)

Manifest validation.

### Functions

```nix
# Check required labels
requireLabels {
  resource = myDeployment;
  required = { "nixernetes.io/framework" = "SOC2"; };
}

# Validate namespaces exist
validateNamespaces {
  namespace = "default";
  resources = [ /* ... */ ];
}

# Comprehensive validation
validateManifest {
  resources = [ /* ... */ ];
  schemaMap = apiMap;
  kubernetesVersion = "1.30";
}

# Validation summary
validationSummary {
  resources = [ /* ... */ ];
  schemaMap = apiMap;
  kubernetesVersion = "1.30";
}
```

## Examples

See `src/examples/web-app.nix` for complete working examples.
