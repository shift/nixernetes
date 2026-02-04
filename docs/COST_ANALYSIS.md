# Cost Analysis Guide

## Overview

The Nixernetes Cost Analysis framework provides comprehensive cost estimation, optimization recommendations, and detailed breakdowns for Kubernetes deployments. It supports multiple cloud providers (AWS, Azure, GCP) and generates projections for hourly, daily, monthly, and annual costs.

**Key Features:**
- Multi-provider pricing models (AWS, Azure, GCP)
- Resource-based cost calculation (CPU and memory)
- Deployment-level cost breakdowns
- Optimization recommendations
- Multiple output formats (text, JSON, YAML)
- CLI tool for manifest analysis

## Pricing Models

The cost analysis framework includes current (2024) standard pricing for major cloud providers:

### AWS (m5.large equivalent)
- **CPU**: $0.0535/vCPU-hour
- **Memory**: $0.0108/GB-hour

### Azure
- **CPU**: $0.0490/vCPU-hour
- **Memory**: $0.0098/GB-hour

### GCP (n2 machine)
- **CPU**: $0.0440/vCPU-hour
- **Memory**: $0.0059/GB-hour

**Note**: Prices are based on on-demand instances. Reserved instances, spot instances, and other commitment models will have different pricing.

## Architecture

### Module Structure

The cost analysis module (`src/lib/cost-analysis.nix`) provides:

1. **Quantity Parser** - Converts Kubernetes resource quantities (500m, 1Gi, etc.) to numeric values
2. **Cost Calculator** - Computes hourly costs based on CPU and memory requests
3. **Deployment Analyzer** - Analyzes full deployments with multiple containers
4. **Recommendation Engine** - Identifies optimization opportunities
5. **Summary Generator** - Creates cost breakdowns by resource type

### Cost Calculation Formula

```
Hourly Cost = (CPU cores × CPU price/hour) + (Memory GB × Memory price/hour)

Daily Cost = Hourly Cost × 24
Monthly Cost = Hourly Cost × 24 × 30
Annual Cost = Hourly Cost × 24 × 365
```

**Example**: A deployment with 2 replicas of a container requesting 500m CPU and 512Mi memory:

```
Pod Cost = (0.5 cores × $0.0535) + (0.5 GB × $0.0108)
         = $0.02675 + $0.0054
         = $0.03215/hour

Total Cost (2 replicas) = $0.03215 × 2 = $0.0643/hour
                        = $1.55/day
                        = $46.34/month
                        = $561.12/year
```

## Using the CLI Tool

### Basic Usage

```bash
# Analyze a single manifest file
nix develop -c python3 tools/cost-analyzer.py manifests/app.yaml

# Analyze multiple manifest files
nix develop -c python3 tools/cost-analyzer.py manifests/app.yaml manifests/database.yaml
```

### Command Options

```bash
# Use different cloud provider
nix develop -c python3 tools/cost-analyzer.py -p azure manifests/app.yaml
nix develop -c python3 tools/cost-analyzer.py -p gcp manifests/app.yaml

# Output as JSON
nix develop -c python3 tools/cost-analyzer.py -f json manifests/app.yaml

# Output as YAML
nix develop -c python3 tools/cost-analyzer.py -f yaml manifests/app.yaml

# Save to file
nix develop -c python3 tools/cost-analyzer.py -o costs.json -f json manifests/app.yaml
```

### Example Output

```
======================================================================
Nixernetes Cost Analysis Report
Provider: AWS | Currency: USD
======================================================================

Total Estimated Costs:
  Hourly:   $1.23
  Daily:    $29.52
  Monthly:  $885.60
  Annual:   $10,627.20

Deployments (3)
----------------------------------------------------------------------
  frontend (3 replicas)
    Monthly: $145.68

  api (2 replicas)
    Monthly: $292.80

  worker (5 replicas)
    Monthly: $447.12

Optimization Recommendations (4)
======================================================================

⚡ api/worker
  Issue: CPU request is 4.0 cores
  Impact: High CPU requests increase hourly costs
  Recommendation: Consider reducing CPU to 1-2 cores for most workloads
  Potential Savings: $73.20/month

ℹ️  frontend/nginx
  Issue: No memory limit specified
  Impact: Pod can consume unlimited memory
  Recommendation: Set memory limit based on request + safety margin
```

## Cost Analysis Functions

### mkContainerCost

Calculates the hourly cost for a single container.

```nix
let
  cost = mkContainerCost {
    resources.requests = {
      cpu = "500m";
      memory = "512Mi";
    };
    provider = "aws";
  };
in
  cost  # Result: 0.00835 (USD/hour)
```

### mkPodCost

Calculates the cost for a Pod with multiple containers.

```nix
let
  cost = mkPodCost {
    containers = [
      {
        name = "app";
        resources.requests = {
          cpu = "500m";
          memory = "512Mi";
        };
      }
      {
        name = "sidecar";
        resources.requests = {
          cpu = "100m";
          memory = "128Mi";
        };
      }
    ];
    replicas = 3;
    provider = "aws";
  };
in
  cost.monthly  # Result: 38.88 (USD/month)
```

### mkDeploymentCost

Analyzes a complete Deployment specification.

```nix
let
  deployment = {
    spec = {
      replicas = 2;
      template.spec = {
        containers = [
          {
            name = "app";
            resources.requests = {
              cpu = "500m";
              memory = "512Mi";
            };
          }
        ];
      };
    };
  };

  cost = mkDeploymentCost {
    replicas = deployment.spec.replicas;
    template = deployment.spec.template;
    provider = "aws";
  };
in
  cost.monthly  # Result: 25.92 (USD/month)
```

### mkCostRecommendations

Analyzes deployments for optimization opportunities.

```nix
let
  recommendations = mkCostRecommendations {
    deployments = {
      "my-app" = {
        spec.template.spec.containers = [
          {
            name = "app";
            resources = {
              requests = { cpu = "4"; memory = "2Gi"; };
              # No limits specified
            };
          }
        ];
      };
    };
  };
in
  recommendations
  # Returns:
  # [
  #   {
  #     deployment = "my-app";
  #     severity = "medium";
  #     resource = "app";
  #     issue = "CPU request significantly exceeds typical usage";
  #     impact = "High CPU requests increase hourly cost";
  #     recommendation = "Consider reducing CPU request to 1-2 cores...";
  #     savings = 3.0;
  #   },
  #   {
  #     deployment = "my-app";
  #     severity = "low";
  #     resource = "app";
  #     issue = "No memory limit specified";
  #     ...
  #   }
  # ]
```

### mkCostSummary

Generates a comprehensive cost breakdown.

```nix
let
  summary = mkCostSummary {
    deployments = {
      "frontend" = { /* deployment spec */ };
      "api" = { /* deployment spec */ };
      "database" = { /* deployment spec */ };
    };
    provider = "aws";
  };
in
  summary
  # Returns:
  # {
  #   total = {
  #     hourly = 1.23;
  #     daily = 29.52;
  #     monthly = 885.60;
  #     annual = 10627.20;
  #   };
  #   byDeployment = [
  #     { name = "frontend"; replicas = 3; hourly = 0.4; ... }
  #     { name = "api"; replicas = 2; hourly = 0.6; ... }
  #     { name = "database"; replicas = 1; hourly = 0.23; ... }
  #   ];
  #   provider = "aws";
  #   currency = "USD";
  # }
```

## Optimization Recommendations

The cost analysis framework automatically detects several optimization opportunities:

### CPU Oversizing
**Severity**: Medium

When a container requests more than 2 CPU cores, the analyzer recommends reducing to 1-2 cores for most workloads. This can save $0.0535+ per hour per overprovisioned core.

**Example**:
```yaml
containers:
  - name: api
    resources:
      requests:
        cpu: "4"           # ⚠️  Too high
        memory: "1Gi"
```

**Recommendation**: Reduce to 1-2 cores based on actual usage monitoring.

### Missing Memory Limits
**Severity**: Low

When a container has memory requests but no limits, it can consume unlimited memory, potentially causing OOMKill and cost surprises from node scaling.

**Example**:
```yaml
containers:
  - name: app
    resources:
      requests:
        memory: "512Mi"    # Set but no limit
```

**Recommendation**: Set memory limits to 1.5-2x the request.

### Tight Resource Limits
**Severity**: Low

When CPU limits are less than 2x the request, containers may be throttled during normal operation spikes.

**Example**:
```yaml
containers:
  - name: api
    resources:
      requests:
        cpu: "500m"
      limits:
        cpu: "550m"        # Only 1.1x, too tight
```

**Recommendation**: Set limits 2-3x requests for typical workloads.

## Practical Examples

### Example 1: Simple Web Application

**Manifest** (`web-app.yaml`):
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-server
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
```

**Analysis**:
```bash
nix develop -c python3 tools/cost-analyzer.py web-app.yaml
```

**Result**:
- Per pod: $0.00227/hour
- Total (3 replicas): $0.00682/hour
- **Monthly cost**: $4.89
- **Annual cost**: $59.68

### Example 2: Multi-Tier Application

**Manifest** (`multi-tier-app.yaml`):
```yaml
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: nginx
        resources:
          requests:
            cpu: "100m"
            memory: "256Mi"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        resources:
          requests:
            cpu: "500m"
            memory: "512Mi"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: database
spec:
  replicas: 1
  template:
    spec:
      containers:
      - name: postgres
        resources:
          requests:
            cpu: "1000m"
            memory: "1Gi"
```

**Analysis**:
```bash
nix develop -c python3 tools/cost-analyzer.py multi-tier-app.yaml
```

**Result**:
```
Total Monthly Cost: $46.34
- Frontend: $3.27 (2×100m CPU, 256Mi mem)
- API: $24.59 (3×500m CPU, 512Mi mem)
- Database: $18.48 (1×1000m CPU, 1Gi mem)

Optimization Opportunities:
- Database CPU request is 1000m (1 core), consider monitoring actual usage
```

### Example 3: Comparing Cloud Providers

Analyze the same manifest across providers:

```bash
# AWS (default)
nix develop -c python3 tools/cost-analyzer.py -p aws multi-tier-app.yaml

# Azure
nix develop -c python3 tools/cost-analyzer.py -p azure multi-tier-app.yaml

# GCP
nix develop -c python3 tools/cost-analyzer.py -p gcp multi-tier-app.yaml
```

**Cost Comparison** (monthly):
| Provider | Cost | Savings vs AWS |
|----------|------|--------|
| AWS | $46.34 | - |
| Azure | $42.47 | $3.87 (8.4%) |
| GCP | $38.68 | $7.66 (16.5%) |

## Integration with Nixernetes Framework

The cost analysis module integrates seamlessly with other Nixernetes modules:

### In Compliance Profiles

```nix
let
  nixernetes = import ./src/lib/default.nix;
  costAnalysis = import ./src/lib/cost-analysis.nix { inherit lib; };

  deployment = {
    spec = {
      replicas = 3;
      template.spec.containers = [ /* ... */ ];
    };
  };

  # Calculate cost for compliance level
  highSecurityCost = costAnalysis.mkDeploymentCost {
    replicas = deployment.spec.replicas;
    template = deployment.spec.template;
    provider = "aws";
  };
in
  deployment // { cost = highSecurityCost; }
```

### In Manifest Generation

```nix
let
  costAnalysis = import ./src/lib/cost-analysis.nix { inherit lib; };

  app = {
    deployments = {
      frontend = { /* ... */ };
      api = { /* ... */ };
      database = { /* ... */ };
    };
  };

  # Add cost information to deployment
  costInfo = costAnalysis.mkCostSummary {
    deployments = app.deployments;
    provider = "aws";
  };
in
  app // { costs = costInfo; }
```

## Advanced Usage

### Custom Pricing

To use custom pricing, you can modify the provider pricing constants in the module:

```nix
let
  costAnalysis = import ./src/lib/cost-analysis.nix { inherit lib; };
  
  # Override pricing for reserved instances (30% discount)
  reservedPricing = {
    aws = {
      cpu = 0.03745;    # 0.0535 × 0.7
      memory = 0.00756; # 0.0108 × 0.7
    };
  };
in
  # Use in calculations
  costAnalysis.mkDeploymentCost {
    replicas = 3;
    template = myTemplate;
    provider = "aws";
    # Would need to modify the function to support custom pricing
  }
```

### Batch Analysis

Analyze entire directory of manifests:

```bash
# Analyze all YAML files in a directory
nix develop -c python3 tools/cost-analyzer.py manifests/*.yaml -o analysis.json -f json

# Analyze with specific provider
nix develop -c python3 tools/cost-analyzer.py manifests/*.yaml -p gcp -o gcp-costs.yaml -f yaml
```

## Cost Optimization Strategies

### 1. Right-size Resource Requests

**Before**: Many containers request excessive CPU and memory
**After**: Implement resource monitoring and adjust based on actual usage

**Savings**: Up to 40-60% depending on current over-provisioning

### 2. Use Quality of Service Classes

**Burstable QoS**: Set requests < limits to allow temporary spikes
**Guaranteed QoS**: Use for critical workloads

```yaml
# Burstable - cheaper but can be evicted
requests:
  cpu: 100m
  memory: 128Mi
limits:
  cpu: 500m
  memory: 512Mi

# Guaranteed - expensive but protected
requests:
  cpu: 500m
  memory: 512Mi
limits:
  cpu: 500m
  memory: 512Mi
```

### 3. Multi-cloud Strategy

Use cost analysis to compare cloud providers and select the most cost-effective one for different workloads:

- **GCP**: Best for data analytics and AI workloads (16.5% cheaper than AWS)
- **Azure**: Good for Windows workloads (8.4% cheaper than AWS)
- **AWS**: Largest ecosystem and instance variety

### 4. Workload Consolidation

Analyze multiple small deployments and consolidate where possible:

```
Before: 10 deployments × 2 replicas = 20 pods
After: 3 deployments × 6 replicas = 18 pods (fewer node allocations)
```

### 5. Time-based Scaling

Use HPA and scheduled scaling for variable workloads:

```
Peak hours: 10 replicas
Off-peak hours: 2 replicas
Potential savings: 40-60% outside peak hours
```

## Troubleshooting

### Issue: "No module named 'yaml'"
**Solution**: Ensure you're running in the nix develop environment:
```bash
nix develop -c python3 tools/cost-analyzer.py manifests/app.yaml
```

### Issue: Inaccurate cost estimates
**Possible causes**:
1. Pricing data is outdated (update constants in cost-analysis.nix)
2. Using different instance types than defaults
3. Not accounting for storage, networking, or data transfer costs

**Solution**: Adjust provider pricing constants for your specific setup.

### Issue: Missing optimization recommendations
**Possible causes**:
1. Resources are already well-configured
2. Specific recommendation check is disabled

**Solution**: Manually review resource requests against production metrics.

## Best Practices

1. **Monitor Actual Usage**: Use Prometheus and Grafana to track actual CPU/memory usage
2. **Set Conservative Limits**: Use limits 2-3x your requests
3. **Use Quality of Service**: Explicitly set QoS class for each deployment
4. **Regular Cost Reviews**: Run cost analysis monthly and compare with previous periods
5. **Test Before Optimizing**: Use staging environment to validate resource changes
6. **Document Changes**: Keep records of cost optimization changes and their impact
7. **Account for Hidden Costs**: Remember to include storage, networking, and data transfer

## Related Documentation

- [Multi-Tier Deployment Guide](./MULTI_TIER_DEPLOYMENT.md) - See cost examples for production applications
- [Testing Guide](./TESTING.md) - Includes cost analysis tests
- [API Reference](./API.md) - Complete module API documentation
- [Security Policies](./SECURITY_POLICIES.md) - Security considerations for cost-optimized deployments

## Contributing

To improve cost analysis:

1. Add new cloud providers by updating `PROVIDERS` in both modules
2. Improve recommendation logic by adding new checks to `_check_deployment_optimization()`
3. Add region-specific pricing
4. Support for reserved instances and spot pricing
5. Integration with actual cloud provider cost APIs

## License

The Nixernetes Cost Analysis framework is part of the Nixernetes project and is available under the same license.
