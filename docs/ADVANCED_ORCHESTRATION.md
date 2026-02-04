# Advanced Orchestration Module

## Overview

The Advanced Orchestration module extends Nixernetes with sophisticated multi-cloud workload scheduling, resource optimization, and advanced orchestration patterns. It provides builders for managing complex placement requirements, availability guarantees, and cost-optimized scheduling across single and multi-cluster environments.

## Key Capabilities

### Workload Affinity & Topology Awareness
- Pod-to-pod affinity and anti-affinity rules
- Node affinity constraints with multiple operators
- Topology-spread constraints for zone/rack awareness
- Customizable affinity strength (hard/soft)

### Availability & Resilience
- Pod disruption budgets with minAvailable/maxUnavailable
- Unhealthy pod eviction policies
- High-availability pod spreading
- Priority classes with preemption control

### Multi-Cloud & Multi-Cluster
- Multi-cluster workload distribution policies
- Distribution strategies: round-robin, weighted, latency-based, cost-optimized
- Failover chains and cluster preferences
- Region and locality awareness

### Resource Optimization
- Capacity planning and forecasting
- VPA recommendations with update modes
- HPA recommendations with custom metrics
- Growth rate modeling and target utilization

### Cost Optimization
- Multi-cloud cost calculation
- Cost-aware workload placement
- Cloud provider selection based on pricing
- Monthly cost forecasting

## Core Builders

### mkWorkloadAffinityPolicy

Creates a workload affinity policy for scheduling decisions.

```nix
orchestration.mkWorkloadAffinityPolicy "app-affinity" {
  podAffinityPresets = ["web" "cache"];
  nodeAffinityRules = [
    {
      key = "node-type";
      operator = "In";
      values = ["compute"];
      type = "required";
    }
  ];
  topologySpreadConstraints = [
    {
      key = "topology.kubernetes.io/zone";
      skewLimit = 1;
    }
  ];
  antiAffinityStrength = "soft";  # soft | hard
  topologyKey = "kubernetes.io/hostname";
  spreadKey = "topology.kubernetes.io/zone";
}
```

**Parameters:**
- `podAffinityPresets`: List of pod labels to co-locate with
- `nodeAffinityRules`: List of node affinity constraints
- `topologySpreadConstraints`: List of topology spread rules
- `antiAffinityStrength`: Affinity strength (soft/hard)
- `topologyKey`: Default topology key for affinity
- `spreadKey`: Default topology key for spreading

### mkPodDisruptionBudget

Defines availability guarantees during node disruptions.

```nix
orchestration.mkPodDisruptionBudget "api-pdb" {
  namespace = "production";
  selector = { matchLabels = { app = "api-server"; }; };
  minAvailable = 2;
  maxUnavailable = 1;
  unhealthyPodEvictionPolicy = "IfHealthyBudget";
}
```

**Parameters:**
- `namespace`: Target namespace
- `selector`: Pod label selector
- `minAvailable`: Minimum available pods
- `maxUnavailable`: Maximum unavailable pods (if minAvailable not set)
- `unhealthyPodEvictionPolicy`: Policy for unhealthy pods (IfHealthyBudget | AlwaysAllow)

### mkPriorityClass

Defines pod priority and preemption behavior.

```nix
orchestration.mkPriorityClass "high-priority" {
  value = 1000;
  globalDefault = false;
  description = "High priority workloads";
  preemptionPolicy = "PreemptLowerPriority";
}
```

**Parameters:**
- `value`: Priority value (higher = higher priority)
- `globalDefault`: Whether to use as default priority
- `description`: Human-readable description
- `preemptionPolicy`: Preemption policy (PreemptLowerPriority | Never)

### mkMultiClusterPolicy

Defines workload distribution across multiple clusters.

```nix
orchestration.mkMultiClusterPolicy "global-app" {
  clusters = ["us-east-1" "us-west-1" "eu-west-1"];
  distribution = "cost-optimized";  # round-robin | weighted | latency-based | cost-optimized
  weights = {
    "us-east-1" = 0.5;
    "us-west-1" = 0.3;
    "eu-west-1" = 0.2;
  };
  failoverChain = ["us-east-1" "us-west-1" "eu-west-1"];
  preferredRegions = ["us"];
  costOptimization = true;
  latencyThreshold = 100;  # milliseconds
}
```

**Parameters:**
- `clusters`: List of target clusters
- `distribution`: Distribution strategy
- `weights`: Per-cluster weights for weighted distribution
- `failoverChain`: Order for failover attempts
- `preferredRegions`: Preferred cloud regions
- `costOptimization`: Enable cost-aware placement
- `latencyThreshold`: Maximum acceptable latency

### mkCapacityPlanner

Plans cluster capacity and forecasts growth.

```nix
orchestration.mkCapacityPlanner "production-cluster" {
  clusterName = "prod-us-east";
  currentCapacity = {
    nodes = 10;
    cpuPerNode = "16";
    memoryPerNode = "32Gi";
    storagePerNode = "200Gi";
  };
  currentUtilization = {
    cpu = 0.65;
    memory = 0.72;
    storage = 0.55;
  };
  forecastingPeriod = 90;  # days
  targetUtilization = {
    cpu = 0.70;
    memory = 0.75;
    storage = 0.80;
  };
  growthRate = 0.12;  # 12% per month
}
```

**Parameters:**
- `clusterName`: Cluster identifier
- `currentCapacity`: Current node resources
- `currentUtilization`: Current usage percentages
- `forecastingPeriod`: Planning horizon in days
- `targetUtilization`: Target resource usage
- `growthRate`: Expected monthly growth rate

### mkResourceOptimizer

Generates resource optimization recommendations.

```nix
orchestration.mkResourceOptimizer "api-server-optimization" {
  workloadName = "api-server";
  workloadType = "deployment";  # deployment | statefulset | daemonset
  analysisWindow = 30;  # days
  recommendationType = "balanced";  # conservative | balanced | aggressive
  vpaRecommendations = {
    enabled = true;
    updateMode = "Auto";  # Off | Initial | Recreate | Auto
    minAllowedResources = { cpu = "100m"; memory = "128Mi"; };
    maxAllowedResources = { cpu = "4"; memory = "8Gi"; };
  };
  hpaRecommendations = {
    enabled = true;
    metric = "cpu";  # cpu | memory | custom
    targetValue = 70;
    minReplicas = 2;
    maxReplicas = 20;
  };
}
```

**Parameters:**
- `workloadName`: Target workload name
- `workloadType`: Type of workload (deployment | statefulset | daemonset)
- `analysisWindow`: Historical data period in days
- `recommendationType`: Recommendation aggressiveness
- `vpaRecommendations`: Vertical Pod Autoscaler config
- `hpaRecommendations`: Horizontal Pod Autoscaler config

### mkTopologyStrategy

Defines workload distribution topology strategy.

```nix
orchestration.mkTopologyStrategy "zone-balanced" {
  strategyType = "zone-spread";  # zone-spread | rack-spread | region-spread | custom
  dimensions = ["topology.kubernetes.io/zone"];
  skewLimit = 1;
  minDomains = 2;
  nodeAffinityPolicy = "Honor";  # Honor | Ignore
  nodeTaintsPolicy = "Honor";  # Honor | Ignore
  topology = {
    "us-east-1a" = 3;
    "us-east-1b" = 3;
    "us-east-1c" = 3;
  };
}
```

**Parameters:**
- `strategyType`: Type of topology strategy
- `dimensions`: Topology dimensions (keys)
- `skewLimit`: Maximum skew between topology domains
- `minDomains`: Minimum number of domains to spread across
- `nodeAffinityPolicy`: How to handle node affinity
- `nodeTaintsPolicy`: How to handle node taints
- `topology`: Current topology distribution

### mkWorkloadPlacement

Defines where and how workloads are placed.

```nix
orchestration.mkWorkloadPlacement "critical-app" {
  workloadName = "critical-app";
  placementConstraints = {
    minReplicas = 3;
    maxReplicas = 10;
    preferredClusters = ["us-east-1"];
  };
  multiCloudPlacement = true;
  preferredClusters = ["aws-us-east"];
  backupClusters = ["gcp-us-central"];
  locality = "regional";  # local | regional | global
  costOptimized = true;
  highAvailability = true;
  tags = {
    tier = "critical";
    compliance = "PCI-DSS";
  };
  constraints = [
    { type = "resource"; key = "cpu"; minValue = "4"; }
    { type = "region"; key = "data-residency"; values = ["us" "ca"]; }
  ];
}
```

**Parameters:**
- `workloadName`: Target workload identifier
- `placementConstraints`: Constraints on placement
- `multiCloudPlacement`: Enable multi-cloud placement
- `preferredClusters`: Ordered list of preferred clusters
- `backupClusters`: Fallback clusters for failover
- `locality`: Locality preference
- `costOptimized`: Enable cost optimization
- `highAvailability`: Require high availability
- `tags`: Workload tags for filtering
- `constraints`: Custom placement constraints

## Helper Functions

### mkPodAntiAffinityHA

Creates pod anti-affinity for high availability.

```nix
affinity = orchestration.mkPodAntiAffinityHA "myapp" "soft";
```

### mkZoneSpreadConstraint

Creates a zone spread constraint.

```nix
topologySpreadConstraints = [
  (orchestration.mkZoneSpreadConstraint "myapp")
];
```

### calculateMultiCloudCost

Calculates costs across multiple cloud providers.

```nix
costs = orchestration.calculateMultiCloudCost
  {
    resources.requests = { cpu = "1"; memory = "2Gi"; };
  }
  {
    "aws" = { hourlyRate = 0.05; };
    "gcp" = { hourlyRate = 0.048; };
    "azure" = { hourlyRate = 0.052; };
  };
```

## Integration with Unified API

The Advanced Orchestration module integrates seamlessly with the unified API:

```nix
let
  api = import ../src/lib/unified-api.nix { inherit lib; };
  orchestration = import ../src/lib/advanced-orchestration.nix { inherit lib; };
in
{
  # Create application with orchestration
  app = api.mkApplication "myapp" {
    namespace = "production";
    image = "myapp:1.0.0";
    replicas = 3;
    
    # Enhanced with orchestration
    affinity = orchestration.mkPodAntiAffinityHA "myapp" "hard";
    topologySpreadConstraints = [
      (orchestration.mkZoneSpreadConstraint "myapp")
    ];
  };
  
  # Add multi-cluster distribution
  multiCluster = orchestration.mkMultiClusterPolicy "global-app" {
    clusters = ["us-east" "eu-west"];
    distribution = "cost-optimized";
  };
}
```

## Validation

All builders include validation:

```nix
validation = orchestration.validateAffinityPolicy policy;
# Returns { valid = true/false; errors = [...]; }
```

## Framework Metadata

Access framework information:

```nix
meta = orchestration.framework;
# Provides version, supported strategies, Kubernetes versions, etc.
```

## Distribution Strategies

### Round-Robin
Distributes workloads equally across all clusters.

```nix
distribution = "round-robin";
```

### Weighted
Distributes based on specified weights.

```nix
distribution = "weighted";
weights = { cluster1 = 0.6; cluster2 = 0.4; };
```

### Latency-Based
Routes to clusters with lowest latency.

```nix
distribution = "latency-based";
latencyThreshold = 100;  # ms
```

### Cost-Optimized
Routes to most cost-effective clusters.

```nix
distribution = "cost-optimized";
costOptimization = true;
```

## Best Practices

1. **Pod Disruption Budgets**: Always define PDBs for stateful applications
2. **Anti-Affinity**: Use soft anti-affinity for flexibility, hard for critical apps
3. **Zone Spreading**: Distribute across zones for resilience
4. **Priority Classes**: Define priorities for all workload tiers
5. **Capacity Planning**: Regularly forecast cluster growth
6. **Cost Optimization**: Monitor and optimize resource requests
7. **Multi-Cluster**: Use for critical production workloads
8. **Testing**: Validate placement policies in staging first

## Performance Considerations

- Pod anti-affinity can impact scheduling performance at large scale
- Zone spread constraints may reduce scheduling flexibility
- Multi-cluster policies add latency for decision-making
- Capacity planning forecasts should be reviewed monthly

## Future Enhancements

- Custom metric support for cost calculation
- Machine learning-based placement optimization
- Automatic scaling policies based on topology
- Cross-cloud data locality optimization
- Policy templates for common patterns
