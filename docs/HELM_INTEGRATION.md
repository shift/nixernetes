# Helm Integration Module

## Overview

The Helm Integration Module bridges Nixernetes and Helm, enabling you to:

- Generate Helm charts from Nixernetes configurations
- Convert Unified API applications to Helm chart values
- Validate chart structure and versions
- Manage chart dependencies
- Compose values and overrides
- Package charts for publishing
- Support multi-version chart management

This module makes Nixernetes configurations accessible to 90% of Kubernetes users who rely on Helm.

## Architecture

The module consists of four main layers:

### Layer 1: Chart Builders
- `mkChartMetadata` - Chart metadata (name, version, description)
- `mkChartValues` - Default values with sensible defaults
- `mkHelmChart` - Complete chart definition
- `mkChartDependency` - Chart dependency declarations

### Layer 2: Conversion
- `applicationToChartValues` - Convert Unified API app to chart values
- `mkValuesOverride` - Create values overrides
- `mkTemplate` - Define chart templates

### Layer 3: Organization
- `mkChartPackage` - Package chart structure
- `mkChartRequirements` - Define dependencies

### Layer 4: Validation & Publishing
- `validateChart` - Verify chart structure
- `mkChartUpdate` - Manage version updates

## Quick Start

### Generate a Basic Chart

```nix
let
  helmIntegration = import ./src/lib/helm-integration.nix { inherit lib; };
  
  chart = helmIntegration.mkHelmChart "my-app" {
    description = "My Kubernetes application";
    version = "1.0.0";
    appVersion = "1.2.3";
    maintainers = [{
      name = "Your Team";
      email = "team@example.com";
    }];
  };
in
chart
```

### Convert Unified API App to Chart

```nix
let
  api = import ./src/lib/unified-api.nix { inherit lib; };
  helmIntegration = import ./src/lib/helm-integration.nix { inherit lib; };
  
  app = api.mkApplication "web-service" {
    image = "myregistry/web:1.0";
    replicas = 3;
    requestsCpu = "100m";
    requestsMemory = "128Mi";
  };
  
  chartValues = helmIntegration.applicationToChartValues app;
  
  chart = helmIntegration.mkHelmChart "web-service" {
    description = "Web Service Helm Chart";
    version = "1.0.0";
  };
in
chart
```

## Builder Reference

### Chart Metadata Builder

```nix
mkChartMetadata "chart-name" {
  description = "Chart description";
  version = "1.0.0";                # Semantic version required
  appVersion = "1.2.3";             # Application version
  type = "application";             # application | library
  keywords = ["web" "api"];
  home = "https://example.com";
  sources = ["https://github.com/..."];
  maintainers = [{
    name = "Team Name";
    email = "team@example.com";
    url = "https://example.com";
  }];
  kubeVersion = ">=1.28.0";
  icon = "https://example.com/icon.png";
  dependencies = [];
  deprecated = false;
}
```

### Chart Values Builder

```nix
mkChartValues "app-name" {
  replicaCount = 3;
  image = {
    repository = "myregistry/app";
    tag = "1.0.0";
    pullPolicy = "IfNotPresent";
  };
  imagePullSecrets = [];
  nameOverride = "";
  fullnameOverride = "";
  
  serviceAccount = {
    create = true;
    annotations = {};
    name = "";
  };
  
  podAnnotations = {
    "prometheus.io/scrape" = "true";
  };
  
  podSecurityContext = {
    runAsNonRoot = true;
    runAsUser = 1000;
  };
  
  securityContext = {
    allowPrivilegeEscalation = false;
    readOnlyRootFilesystem = true;
    capabilities = { drop = ["ALL"]; };
  };
  
  service = {
    type = "ClusterIP";
    port = 80;
    targetPort = 8080;
    annotations = {};
  };
  
  ingress = {
    enabled = false;
    className = "nginx";
    annotations = {};
    hosts = [{
      host = "example.com";
      paths = [{
        path = "/";
        pathType = "Prefix";
      }];
    }];
    tls = [];
  };
  
  resources = {
    limits = { cpu = "500m"; memory = "512Mi"; };
    requests = { cpu = "100m"; memory = "128Mi"; };
  };
  
  autoscaling = {
    enabled = false;
    minReplicas = 1;
    maxReplicas = 10;
    targetCPUUtilizationPercentage = 80;
  };
  
  nodeSelector = {};
  tolerations = [];
  affinity = {};
  env = [];
  envFrom = [];
  livenessProbe = null;
  readinessProbe = null;
  extraVolumes = [];
  extraVolumeMounts = [];
}
```

### Helm Chart Builder

```nix
mkHelmChart "app-name" {
  description = "Application description";
  version = "1.0.0";
  appVersion = "1.2.3";
  type = "application";
  keywords = [];
  home = "";
  sources = [];
  maintainers = [];
  kubeVersion = ">=1.28.0";
  icon = null;
  dependencies = [];
  deprecated = false;
  replicaCount = 3;
  image = { repository = "app"; tag = "1.0"; };
  # ... all mkChartValues options
}
```

### Chart Dependency Builder

```nix
mkChartDependency "postgresql" {
  version = ">=12.0.0";
  repository = "https://charts.bitnami.com/bitnami";
  condition = "postgresql.enabled";
  tags = ["database"];
  import-values = ["postgresql.auth.username"];
  alias = "db";
}
```

### Values Override Builder

```nix
mkValuesOverride {
  replicaCount = 5;
  imageRepository = "myregistry/app";
  imageTag = "2.0.0";
  imagePullPolicy = "Always";
  serviceType = "LoadBalancer";
  servicePort = 443;
  ingressEnabled = true;
  ingressHosts = ["app.example.com"];
  resourceLimitsCpu = "1000m";
  resourceLimitsMemory = "1Gi";
  resourceRequestsCpu = "500m";
  resourceRequestsMemory = "512Mi";
}
```

## Conversion Functions

### Application to Chart Values

Convert a Unified API application directly to chart values:

```nix
let
  app = api.mkApplication "myapp" {
    image = "myregistry/myapp:1.0";
    replicas = 3;
    requestsCpu = "100m";
    requestsMemory = "128Mi";
    limitsCpu = "500m";
    limitsMemory = "512Mi";
  };
  
  chartValues = helmIntegration.applicationToChartValues app;
in
chartValues
```

This automatically:
- Extracts image repository and tag
- Sets replica count
- Configures resources
- Applies annotations and labels
- Sets security context

## Common Templates

The module includes pre-built Helm templates:

### Built-in Templates
- **deployment.yaml** - Standard Kubernetes Deployment
- **service.yaml** - Kubernetes Service
- **serviceaccount.yaml** - ServiceAccount
- **ingress.yaml** - Ingress with TLS support
- **_helpers.tpl** - Helm helper functions

Access via: `helmIntegration.commonTemplates.deployment`

## Chart Validation

Validate chart structure before publishing:

```nix
let
  chart = helmIntegration.mkHelmChart "myapp" { /* ... */ };
  validation = helmIntegration.validateChart chart;
in
if validation.valid then
  "Chart is valid"
else
  validation.errors  # List of validation errors
```

Validates:
- Chart has a name
- Chart has a version (semantic format)
- Chart has a description
- Version follows semver (X.Y.Z)

## Chart Packaging

Package a chart for distribution:

```nix
let
  chart = helmIntegration.mkHelmChart "myapp" { /* ... */ };
  package = helmIntegration.mkChartPackage chart;
in
{
  structure = package.structure;      # File structure
  publishPath = package.publishPath;  # Distribution path
}
```

Generates:
- Chart.yaml
- values.yaml
- templates/ directory
- README.md

## Advanced Usage

### Multiple Deployments with Shared Chart

```nix
let
  baseChart = helmIntegration.mkHelmChart "shared-app" {
    description = "Shared application chart";
    version = "1.0.0";
  };
  
  prodValues = helmIntegration.mkValuesOverride {
    replicaCount = 5;
    resourceLimitsCpu = "1000m";
    resourceLimitsMemory = "1Gi";
  };
  
  stagingValues = helmIntegration.mkValuesOverride {
    replicaCount = 2;
    resourceLimitsCpu = "500m";
    resourceLimitsMemory = "512Mi";
  };
in
{
  inherit baseChart;
  deployments = { inherit prodValues stagingValues; };
}
```

### Chart with Dependencies

```nix
let
  chart = helmIntegration.mkHelmChart "web-app" {
    description = "Web application with database";
    version = "2.0.0";
    dependencies = [
      (helmIntegration.mkChartDependency "postgresql" {
        version = ">=12.0.0";
        repository = "https://charts.bitnami.com/bitnami";
      })
      (helmIntegration.mkChartDependency "redis" {
        version = ">=7.0.0";
        repository = "https://charts.bitnami.com/bitnami";
      })
    ];
  };
in
chart
```

### Multi-Application Helm Repository

```nix
let
  apps = {
    frontend = helmIntegration.mkHelmChart "frontend" { /* ... */ };
    backend = helmIntegration.mkHelmChart "backend" { /* ... */ };
    database = helmIntegration.mkHelmChart "database" { /* ... */ };
  };
  
  packages = mapAttrs (name: chart:
    helmIntegration.mkChartPackage chart
  ) apps;
in
packages
```

## Version Management

Manage chart versions and updates:

```nix
let
  update = helmIntegration.mkChartUpdate "myapp" {
    currentVersion = "1.0.0";
    newVersion = "1.1.0";
    changes = [
      "Add ingress support"
      "Improve resource defaults"
    ];
    breakingChanges = [];
  };
in
update
```

## Integration with Other Modules

### With Unified API

```nix
let
  api = import ./src/lib/unified-api.nix { inherit lib; };
  helmIntegration = import ./src/lib/helm-integration.nix { inherit lib; };
  
  # Define using Unified API
  app = api.mkApplication "myapp" {
    image = "myapp:1.0";
    replicas = 3;
  };
  
  # Convert to Helm chart
  chartValues = helmIntegration.applicationToChartValues app;
  chart = helmIntegration.mkHelmChart app.name {
    description = "My application chart";
    version = "1.0.0";
  };
in
{ inherit app chart chartValues; }
```

### With Security Policies

```nix
let
  securityPolicy = api.mkSecurityPolicy "strict" { /* ... */ };
  
  # Chart respects security requirements
  chart = helmIntegration.mkHelmChart "secure-app" {
    podSecurityContext = {
      runAsNonRoot = true;
      readOnlyRootFilesystem = true;
    };
    securityContext = {
      allowPrivilegeEscalation = false;
      capabilities = { drop = ["ALL"]; };
    };
  };
in
chart
```

## Common Patterns

### Production-Grade Chart

```nix
let
  chart = helmIntegration.mkHelmChart "production-app" {
    description = "Production-ready application";
    version = "1.0.0";
    appVersion = "1.2.3";
    type = "application";
    kubeVersion = ">=1.28.0";
    
    image = {
      repository = "myregistry/app";
      tag = "1.2.3";
      pullPolicy = "IfNotPresent";
    };
    
    replicaCount = 3;
    
    service = {
      type = "ClusterIP";
      port = 80;
      targetPort = 8080;
    };
    
    resources = {
      limits = { cpu = "1000m"; memory = "1Gi"; };
      requests = { cpu = "500m"; memory = "512Mi"; };
    };
    
    autoscaling = {
      enabled = true;
      minReplicas = 3;
      maxReplicas = 10;
      targetCPUUtilizationPercentage = 70;
    };
    
    podSecurityContext = {
      runAsNonRoot = true;
      runAsUser = 1000;
    };
    
    securityContext = {
      allowPrivilegeEscalation = false;
      readOnlyRootFilesystem = true;
    };
    
    ingress = {
      enabled = true;
      className = "nginx";
      hosts = [{
        host = "app.example.com";
        paths = [{ path = "/"; pathType = "Prefix"; }];
      }];
    };
  };
in
chart
```

### SaaS Multi-Tenant Chart

```nix
let
  baseTenantChart = helmIntegration.mkHelmChart "tenant-app" {
    description = "Multi-tenant application chart";
    version = "1.0.0";
    type = "application";
  };
  
  tenant1Values = helmIntegration.mkValuesOverride {
    replicaCount = 3;
    ingressHosts = ["tenant1.example.com"];
  };
  
  tenant2Values = helmIntegration.mkValuesOverride {
    replicaCount = 5;
    ingressHosts = ["tenant2.example.com"];
  };
in
{
  inherit baseTenantChart;
  tenants = { tenant1Values; tenant2Values; };
}
```

## Framework Information

```nix
helmIntegration.framework = {
  name = "Nixernetes Helm Integration";
  version = "1.0.0";
  features = [
    "chart-generation"
    "values-generation"
    "chart-validation"
    "dependency-management"
    "version-management"
    "chart-packaging"
    "values-composition"
    "template-rendering"
    "unified-api-integration"
  ];
  supportedHelmVersions = ["3.10+" "3.11+" "3.12+" "3.13+"];
  supportedKubernetesVersions = ["1.28" "1.29" "1.30"];
}
```

## See Also

- [Unified API](./UNIFIED_API.md) - Application definitions
- [Kyverno Framework](./KYVERNO.md) - Policy definitions
- [Security Scanning](./SECURITY_SCANNING.md) - Security validation
- [Helm Documentation](https://helm.sh/docs/) - Official Helm docs

## Examples

See `/src/examples/helm-integration-example.nix` for complete working examples including:
- Basic chart generation
- Multi-application Helm repositories
- Unified API integration
- Dependency management
- Multi-environment deployments
- Production-grade charts
