# Unified Framework API

## Overview

The Unified Framework API provides a cohesive, high-level interface for using all 21 Nixernetes modules through a single consistent API. It simplifies:

- Application declarations and deployment patterns
- Multi-tier application definitions
- Security policy management
- Compliance framework setup
- Observability configuration
- Cost tracking and optimization
- Performance analysis
- Environment management

The Unified API follows a builder pattern, providing sensible defaults while allowing deep customization when needed.

## Architecture

The Unified API is organized into several logical groups:

### Core Builders

1. **Application Builder** (`mkApplication`)
   - Single-service deployment declarations
   - Resource management (CPU, memory limits)
   - Container configuration
   - Health probes and lifecycle management

2. **Cluster Builder** (`mkCluster`)
   - Complete cluster configuration
   - Kubernetes version selection
   - Provider and region specification
   - Global compliance and observability settings

3. **Multi-Tier Application Builder** (`mkMultiTierApp`)
   - Frontend tier (web servers, CDN)
   - Backend tier (API services)
   - Database tier (relational, document)
   - Cache tier (Redis, Memcached)
   - Queue tier (messaging systems)
   - Monitoring tier (Prometheus, Grafana)

### Feature Builders

4. **Security Policy Builder** (`mkSecurityPolicy`)
   - Pod security enforcement
   - Network policy management
   - RBAC configuration
   - Secret management and encryption

5. **Compliance Builder** (`mkCompliance`)
   - Framework templates (SOC2, PCI-DSS, HIPAA, GDPR, ISO27001, NIST)
   - Automatic compliance configuration
   - Audit logging setup

6. **Observability Builder** (`mkObservability`)
   - Logging configuration (Loki, ELK, Splunk)
   - Metrics collection (Prometheus)
   - Distributed tracing (Jaeger, Zipkin)
   - Alerting and notification setup

7. **Cost Tracking Builder** (`mkCostTracking`)
   - Multi-provider cost estimation
   - Resource usage tracking
   - Budget alerts and optimization

8. **Performance Tracking Builder** (`mkPerformanceTracking`)
   - Resource profiling (CPU, memory, disk, network)
   - Bottleneck detection
   - Regression analysis

9. **Environment Builder** (`mkEnvironment`)
   - Environment-specific configuration
   - Multi-cluster and multi-cloud setup
   - Capability declaration

## Quick Start

### Simple Web Application

```nix
let
  nixernetes = import ./flake.nix;
  lib = import <nixpkgs> {};
  api = import ./src/lib/unified-api.nix { inherit lib; };
in

api.mkApplication "my-web-app" {
  namespace = "production";
  image = "nginx:1.24-alpine";
  replicas = 3;
  port = 80;
  requestsCpu = "100m";
  requestsMemory = "128Mi";
  limitsCpu = "500m";
  limitsMemory = "512Mi";
  labels = {
    tier = "frontend";
  };
}
```

### Multi-Tier Application

```nix
let
  api = import ./src/lib/unified-api.nix { inherit lib; };
in

api.mkMultiTierApp "ecommerce-platform" {
  namespace = "production";
  kubernetesVersion = "1.30";
  
  compliance = {
    framework = "PCI-DSS";
    level = "3.2.1";
  };
  
  observability = {
    enabled = true;
    logging = true;
    metrics = true;
    tracing = true;
  };
  
  frontend = {
    image = "nginx:latest";
    replicas = 3;
  };
  
  backend = {
    image = "node:20-alpine";
    replicas = 5;
    requestsCpu = "500m";
    requestsMemory = "512Mi";
  };
  
  database = {
    image = "postgres:15-alpine";
    replicas = 1;
    limitsCpu = "2000m";
    limitsMemory = "4Gi";
  };
  
  cache = {
    image = "redis:7-alpine";
    replicas = 2;
  };
}
```

## Builder Reference

### Application Builder

```nix
mkApplication "app-name" {
  # Basic configuration
  namespace = "default";           # Kubernetes namespace
  image = "myimage:latest";        # Container image
  replicas = 1;                    # Number of replicas
  port = 8080;                     # Container port (optional)
  
  # Resource configuration
  requestsCpu = "100m";            # CPU request
  requestsMemory = "128Mi";        # Memory request
  limitsCpu = "500m";              # CPU limit
  limitsMemory = "512Mi";          # Memory limit
  
  # Environment and configuration
  env = {                          # Environment variables
    LOG_LEVEL = "info";
    DEBUG = "false";
  };
  labels = {                       # Labels for pod selection
    app = "my-app";
    version = "v1";
  };
  annotations = {                  # Annotations for metadata
    "prometheus.io/scrape" = "true";
  };
  
  # Security configuration
  securityContext = {              # Pod security context
    runAsNonRoot = true;
    runAsUser = 1000;
    readOnlyRootFilesystem = true;
    allowPrivilegeEscalation = false;
  };
  
  # Health checks
  livenessProbe = {                # Liveness probe
    httpGet = { path = "/health"; port = 8080; };
    initialDelaySeconds = 30;
    periodSeconds = 10;
  };
  
  readinessProbe = {               # Readiness probe
    httpGet = { path = "/ready"; port = 8080; };
    initialDelaySeconds = 5;
    periodSeconds = 5;
  };
  
  # Lifecycle
  terminationGracePeriodSeconds = 30;
  imagePullPolicy = "IfNotPresent";
}
```

### Cluster Builder

```nix
mkCluster "production-cluster" {
  kubernetesVersion = "1.30";      # Kubernetes version
  region = "us-east-1";            # Cloud region
  provider = "aws";                # Cloud provider
  namespace = "default";           # Default namespace
  
  # Compliance configuration
  compliance = {
    framework = "SOC2";            # Compliance framework
    level = "type-2";              # Compliance level
    owner = "platform-eng";        # Responsible team
  };
  
  # Observability configuration
  observability = {
    enabled = true;
    logging = true;
    metrics = true;
    tracing = true;
    logLevel = "info";
  };
  
  # Networking configuration
  networking = {
    policyMode = "deny-all";       # Network policy mode
    defaultDenyIngress = true;
    defaultDenyEgress = false;
  };
  
  # Resource quotas
  resourceQuota = {
    enabled = true;
    cpu = "100";
    memory = "500Gi";
    pods = 1000;
  };
  
  # Autoscaling configuration
  autoscaling = {
    enabled = true;
    minReplicas = 1;
    maxReplicas = 10;
    targetCpuUtilization = 70;
  };
}
```

### Multi-Tier Application Builder

```nix
mkMultiTierApp "my-platform" {
  appName = "platform";
  namespace = "production";
  kubernetesVersion = "1.30";
  
  globalConfig = {
    compliance = { framework = "SOC2"; };
    observability = { enabled = true; };
  };
  
  # Optional: Frontend tier
  frontend = {
    image = "nginx:1.24-alpine";
    replicas = 2;
    port = 80;
  };
  
  # Optional: Backend tier
  backend = {
    image = "node:20-alpine";
    replicas = 3;
    port = 3000;
    requestsCpu = "500m";
    requestsMemory = "512Mi";
  };
  
  # Optional: Database tier
  database = {
    image = "postgres:15-alpine";
    replicas = 1;
    port = 5432;
    limitsCpu = "2000m";
    limitsMemory = "4Gi";
  };
  
  # Optional: Cache tier
  cache = {
    image = "redis:7-alpine";
    replicas = 1;
    port = 6379;
  };
  
  # Optional: Queue tier
  queue = {
    image = "rabbitmq:3-management-alpine";
    replicas = 1;
    port = 5672;
  };
  
  # Optional: Monitoring tier
  monitoring = {
    image = "prom/prometheus:latest";
    replicas = 1;
    port = 9090;
  };
}
```

### Security Policy Builder

```nix
mkSecurityPolicy "strict-policy" {
  namespace = "production";
  level = "strict";               # strict | standard | permissive
  
  podSecurity = {
    enforce = "restricted";       # Pod security enforcement
    audit = "restricted";
    warn = "restricted";
  };
  
  networkPolicies = {
    enabled = true;
    defaultDeny = true;
    egressEnabled = true;
  };
  
  rbac = {
    enabled = true;
    leastPrivilege = true;
  };
  
  secretManagement = {
    externalSecrets = false;
    vaultIntegration = false;
    encryptionAtRest = true;
  };
  
  admissionControl = {
    policyEngine = "kyverno";
    mutatingWebhooks = [];
    validatingWebhooks = [];
  };
}
```

### Compliance Builder

```nix
mkCompliance "SOC2" {
  auditLog = true;
  encryption = true;
  accessControl = true;
}

# Pre-configured templates
mkCompliance "PCI-DSS" {};        # PCI DSS v3.2.1
mkCompliance "HIPAA" {};          # HIPAA 2024
mkCompliance "GDPR" {};           # GDPR 2018 with data minimization
mkCompliance "ISO27001" {};       # ISO/IEC 27001:2022
mkCompliance "NIST" {};           # NIST CSF 2.0
```

### Observability Builder

```nix
mkObservability "monitoring-stack" {
  namespace = "monitoring";
  
  logging = {
    enabled = true;
    backend = "loki";              # loki | elasticsearch | splunk
    logLevel = "info";
    retention = 7;                  # days
  };
  
  metrics = {
    enabled = true;
    backend = "prometheus";         # prometheus | datadog | newrelic
    scrapeInterval = "30s";
    retention = 15;                 # days
  };
  
  tracing = {
    enabled = false;
    backend = "jaeger";             # jaeger | zipkin | honeycomb
    samplingRate = 0.1;             # 0-1
  };
  
  alerting = {
    enabled = true;
    backend = "alertmanager";
    rules = [];
  };
}
```

### Cost Tracking Builder

```nix
mkCostTracking "aws-cost-tracking" {
  provider = "aws";               # aws | azure | gcp
  
  resourceTracking = {
    enabled = true;
    granularity = "namespace";    # namespace | pod | node
  };
  
  costAnalysis = {
    enabled = true;
    reportingFrequency = "daily"; # daily | weekly | monthly
    budgetAlerts = true;
  };
  
  optimization = {
    enabled = true;
    rightSizing = true;
    spotInstances = false;
  };
}
```

### Performance Tracking Builder

```nix
mkPerformanceTracking "performance-analysis" {
  profiling = {
    enabled = true;
    cpuProfiling = true;
    memoryProfiling = true;
    diskProfiling = true;
  };
  
  benchmarking = {
    enabled = false;
    baselineComparison = true;
    regressionDetection = true;
  };
  
  bottleneckDetection = {
    enabled = true;
    severityThresholds = {
      critical = 90;
      high = 75;
      medium = 50;
    };
  };
}
```

### Environment Builder

```nix
mkEnvironment "production" {
  type = "production";            # production | staging | development
  
  settings = {
    kubernetesVersion = "1.30";
    cloudProvider = "aws";
    region = "us-east-1";
    networkCIDR = "10.0.0.0/8";
  };
  
  capabilities = {
    multiCluster = false;
    multiCloud = false;
    edgeComputing = false;
  };
  
  features = {
    gitops = true;
    autoScaling = true;
    securityPolicies = true;
    costOptimization = true;
    observability = true;
  };
}
```

## Validation Functions

The API includes built-in validation functions:

### Application Validation

```nix
api.validateApplication app
```

Returns:
```nix
{
  valid = true;                    # Overall validity
  errors = [];                     # List of validation errors
}
```

Validates:
- Application has a name
- Application has an image
- Port is within valid range (1-65535)

### Cluster Validation

```nix
api.validateCluster cluster
```

Validates:
- Cluster has a name
- Kubernetes version is supported (1.28, 1.29, 1.30)
- Cloud provider is supported (aws, azure, gcp, do, linode)

## Utility Functions

### Combining Applications

```nix
let
  api = import ./src/lib/unified-api.nix { inherit lib; };
  app1 = api.mkApplication "app1" { ... };
  app2 = api.mkApplication "app2" { ... };
  combined = api.combineApplications [app1 app2];
in
combined.applications    # All applications
combined.count          # 2
```

## Export Functions

The API provides helpers for exporting to various formats:

```nix
# Export to YAML manifests
api.exporters.toYAML myApp

# Export to Helm values
api.exporters.toHelmValues myCluster

# Export to Kustomize base
api.exporters.toKustomize myMultiTierApp
```

## Framework Information

Access framework metadata:

```nix
api.framework.name                          # "Nixernetes Unified API"
api.framework.version                       # "1.0.0"
api.framework.supportedKubernetesVersions  # ["1.28" "1.29" "1.30"]
api.framework.supportedProviders            # Cloud providers
api.framework.features                      # List of available features
```

## Integration with Other Modules

The Unified API is designed to work seamlessly with all 21 Nixernetes modules:

### Security Integration
```nix
let
  api = import ./src/lib/unified-api.nix { inherit lib; };
  securityScanning = import ./src/lib/security-scanning.nix { inherit lib; };
  
  app = api.mkApplication "secure-app" { ... };
  policy = api.mkSecurityPolicy "strict-policy" { ... };
  scanning = securityScanning.mkScanningPipeline { ... };
in
{
  inherit app policy scanning;
}
```

### Compliance Integration
```nix
let
  compliance = import ./src/lib/compliance.nix { inherit lib; };
  complianceEnforcement = import ./src/lib/compliance-enforcement.nix { inherit lib; };
  
  apiCompliance = api.mkCompliance "SOC2" { ... };
  enforcedCompliance = complianceEnforcement.mkEnforcement apiCompliance;
in
{ inherit apiCompliance enforcedCompliance; }
```

### Cost Analysis Integration
```nix
let
  costAnalysis = import ./src/lib/cost-analysis.nix { inherit lib; };
  app = api.mkApplication "my-app" { ... };
  costs = costAnalysis.analyzeCosts app;
in
{ inherit app costs; }
```

### Performance Analysis Integration
```nix
let
  performance = import ./src/lib/performance-analysis.nix { inherit lib; };
  tracking = api.mkPerformanceTracking "analysis" { ... };
  analysis = performance.analyzeWorkload { ... };
in
{ inherit tracking analysis; }
```

## Best Practices

### 1. Use Sensible Defaults
The API provides excellent defaults for all configurations. Only customize when needed:

```nix
# Good: Simple and readable
api.mkApplication "myapp" {
  image = "myimage:latest";
  replicas = 3;
}

# Avoid: Verbose and redundant
api.mkApplication "myapp" {
  namespace = "default";
  image = "myimage:latest";
  replicas = 3;
  port = null;
  resources.requests.cpu = "100m";
  resources.requests.memory = "128Mi";
  # ... many more defaults
}
```

### 2. Group Related Configuration
Keep related settings together for clarity:

```nix
api.mkCluster "prod" {
  # Infrastructure
  kubernetesVersion = "1.30";
  region = "us-east-1";
  
  # Security & Compliance
  compliance = { framework = "SOC2"; };
  
  # Observability
  observability = {
    enabled = true;
    logging = true;
  };
}
```

### 3. Use Environment-Specific Builders
Create environment-specific configurations:

```nix
let
  baseEnv = api.mkEnvironment "base" { type = "production"; };
  prodEnv = baseEnv // { region = "us-east-1"; };
  stagingEnv = baseEnv // { type = "staging"; region = "eu-west-1"; };
in
{ inherit prodEnv stagingEnv; }
```

### 4. Combine with Module-Specific Functions
Mix Unified API with detailed module APIs for advanced use cases:

```nix
let
  app = api.mkApplication "myapp" { ... };
  kyvernoPolicy = kyverno.mkValidationPolicy { ... };
  gitopsConfig = gitops.mkFluxDeployment { ... };
in
{
  application = app;
  policies = [kyvernoPolicy];
  deployment = gitopsConfig;
}
```

## Common Patterns

### Production Web Service
```nix
api.mkApplication "web-service" {
  image = "myapp:1.2.3";
  replicas = 3;
  requestsCpu = "500m";
  requestsMemory = "512Mi";
  limitsCpu = "1000m";
  limitsMemory = "1Gi";
  labels = { tier = "frontend"; };
  livenessProbe = {
    httpGet = { path = "/health"; port = 8080; };
    initialDelaySeconds = 30;
  };
}
```

### Backend API Service
```nix
api.mkApplication "api-server" {
  image = "myapi:latest";
  replicas = 5;
  port = 3000;
  requestsCpu = "1000m";
  requestsMemory = "1Gi";
  limitsCpu = "2000m";
  limitsMemory = "2Gi";
  env = {
    NODE_ENV = "production";
    LOG_LEVEL = "info";
  };
  labels = { tier = "backend"; service = "api"; };
}
```

### Database Service
```nix
api.mkApplication "postgres" {
  image = "postgres:15-alpine";
  replicas = 1;
  port = 5432;
  requestsCpu = "2000m";
  requestsMemory = "4Gi";
  limitsCpu = "4000m";
  limitsMemory = "8Gi";
  labels = { tier = "database"; };
}
```

### Complete Multi-Tier Platform
See `/src/examples/unified-api-example.nix` for a complete, production-ready example.

## Troubleshooting

### Validation Errors
Use the validation functions to debug configuration:

```nix
let
  app = api.mkApplication "myapp" { image = ""; };
  validation = api.validateApplication app;
in
if validation.valid then
  app
else
  builtins.trace validation.errors (abort "Invalid application")
```

### Missing Required Fields
The API provides helpful error messages:

```
Invalid application with errors:
- Application must have a name
- Application must have an image
```

### Type Errors
Ensure configuration values match expected types:

```nix
# Wrong: port as string
{ port = "8080"; }          # ERROR

# Correct: port as integer
{ port = 8080; }            # OK

# Correct: no port specified (optional)
{}                          # OK (defaults to null)
```

## Advanced Usage

### Templating and Composition
```nix
let
  api = import ./src/lib/unified-api.nix { inherit lib; };
  
  # Template for backend services
  mkBackendService = name: image: api.mkApplication name {
    inherit image;
    replicas = 3;
    requestsCpu = "500m";
    requestsMemory = "512Mi";
    labels = { tier = "backend"; };
  };
  
  # Use template
  authService = mkBackendService "auth-service" "auth-api:1.0";
  userService = mkBackendService "user-service" "user-api:1.0";
  orderService = mkBackendService "order-service" "order-api:1.0";
in
{
  services = [authService userService orderService];
}
```

### Conditional Configuration
```nix
let
  isProduction = true;
  
  app = api.mkApplication "myapp" ({
    image = "myapp:latest";
    replicas = if isProduction then 5 else 1;
    requestsCpu = if isProduction then "1000m" else "100m";
  } // (if isProduction then {
    limits = { memory = "2Gi"; };
  } else {}));
in
app
```

## Migration Guide

If you're already using individual Nixernetes modules, migrating to the Unified API is straightforward:

### Before (Individual Modules)
```nix
let
  schema = import ./src/lib/schema.nix { inherit lib; };
  manifest = import ./src/lib/manifest.nix { inherit lib pkgs; };
  rbac = import ./src/lib/rbac.nix { inherit lib; };
in
{
  deployment = manifest.mkDeployment { ... };
  role = rbac.mkRole { ... };
}
```

### After (Unified API)
```nix
let
  api = import ./src/lib/unified-api.nix { inherit lib; };
in
{
  app = api.mkApplication "myapp" { ... };
}
```

The Unified API handles the underlying complexity while keeping your configuration clean and readable.

## See Also

- [Cost Analysis Module](./COST_ANALYSIS.md) - Detailed cost estimation
- [Kyverno Framework](./KYVERNO.md) - Policy management
- [Security Scanning](./SECURITY_SCANNING.md) - Vulnerability scanning
- [Performance Analysis](./PERFORMANCE_ANALYSIS.md) - Performance profiling
- [Policy Visualization](./POLICY_VISUALIZATION.md) - Visual policy management
- [GitOps Integration](./GITOPS.md) - Continuous deployment
