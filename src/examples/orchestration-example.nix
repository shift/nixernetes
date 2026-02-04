# Example: Advanced Orchestration Module
#
# This example demonstrates comprehensive usage of the Nixernetes Advanced
# Orchestration module for multi-cloud workload scheduling, resource optimization,
# and advanced placement strategies.
#
# The Advanced Orchestration module provides:
# - Workload affinity and topology-aware scheduling
# - Pod disruption budgets and availability guarantees
# - Priority classes and preemption rules
# - Multi-cluster workload distribution
# - Capacity planning and resource optimization

{ lib, ... }:

let
  orchestration = import ../src/lib/advanced-orchestration.nix { inherit lib; };

in
{
  # ============================================================================
  # Example 1: Multi-Zone High Availability with Pod Anti-Affinity
  # ============================================================================
  
  ha_multi_zone_app = 
    let
      affinity = orchestration.mkWorkloadAffinityPolicy "ha-web-app" {
        antiAffinityStrength = "hard";  # Hard anti-affinity required
        topologyKey = "kubernetes.io/hostname";
        spreadKey = "topology.kubernetes.io/zone";
      };
    in
    {
      inherit affinity;
      
      # Pod anti-affinity for HA
      podAntiAffinity = orchestration.mkPodAntiAffinityHA "web-app" "hard";
      
      # Zone spread constraint
      topologySpreadConstraints = [
        (orchestration.mkZoneSpreadConstraint "web-app")
      ];
      
      # Pod disruption budget
      pdb = orchestration.mkPodDisruptionBudget "web-app-pdb" {
        namespace = "production";
        selector = { matchLabels = { app = "web-app"; }; };
        minAvailable = 2;
        unhealthyPodEvictionPolicy = "IfHealthyBudget";
      };
    };

  # ============================================================================
  # Example 2: Critical Application with Priority Classes
  # ============================================================================
  
  critical_app_orchestration =
    let
      # System priority class
      systemPriority = orchestration.mkPriorityClass "system-critical" {
        value = 10000;
        description = "System and infrastructure critical workloads";
        preemptionPolicy = "PreemptLowerPriority";
      };
      
      # Application priority class
      appPriority = orchestration.mkPriorityClass "app-critical" {
        value = 5000;
        description = "Application critical workloads";
        preemptionPolicy = "PreemptLowerPriority";
      };
      
      # Standard priority class
      standardPriority = orchestration.mkPriorityClass "app-standard" {
        value = 1000;
        globalDefault = false;
        description = "Standard application workloads";
        preemptionPolicy = "PreemptLowerPriority";
      };
      
      # Batch priority class
      batchPriority = orchestration.mkPriorityClass "batch-workloads" {
        value = 100;
        description = "Non-critical batch jobs";
        preemptionPolicy = "Never";  # Don't preempt batch jobs
      };
    in
    {
      inherit systemPriority appPriority standardPriority batchPriority;
    };

  # ============================================================================
  # Example 3: Multi-Cluster Global Distribution with Cost Optimization
  # ============================================================================
  
  multi_cluster_distribution =
    let
      policy = orchestration.mkMultiClusterPolicy "global-saas-app" {
        clusters = ["aws-us-east-1" "gcp-us-central" "azure-eastus"];
        distribution = "cost-optimized";
        weights = {
          "aws-us-east-1" = 0.5;    # 50% - cheapest
          "gcp-us-central" = 0.3;   # 30% - medium cost
          "azure-eastus" = 0.2;     # 20% - backup
        };
        failoverChain = [
          "aws-us-east-1"
          "gcp-us-central"
          "azure-eastus"
        ];
        preferredRegions = ["us"];
        costOptimization = true;
        latencyThreshold = 100;  # Maximum acceptable latency in ms
      };
      
      validation = orchestration.validateMultiClusterPolicy policy;
    in
    {
      inherit policy validation;
      
      # Cost calculation for a workload
      costEstimate = orchestration.calculateMultiCloudCost
        {
          name = "global-app";
          resources.requests = {
            cpu = "2";
            memory = "4Gi";
          };
        }
        {
          "aws-us-east-1" = { hourlyRate = 0.05; };
          "gcp-us-central" = { hourlyRate = 0.048; };
          "azure-eastus" = { hourlyRate = 0.052; };
        };
    };

  # ============================================================================
  # Example 4: Production Cluster Capacity Planning
  # ============================================================================
  
  cluster_capacity_planning =
    let
      # Current production cluster capacity
      planner = orchestration.mkCapacityPlanner "prod-us-east-1" {
        clusterName = "production-us-east-1";
        currentCapacity = {
          nodes = 20;
          cpuPerNode = "32";
          memoryPerNode = "64Gi";
          storagePerNode = "500Gi";
        };
        currentUtilization = {
          cpu = 0.68;      # 68% utilized
          memory = 0.72;   # 72% utilized
          storage = 0.55;  # 55% utilized
        };
        forecastingPeriod = 90;  # Plan for next 3 months
        targetUtilization = {
          cpu = 0.70;      # Don't exceed 70%
          memory = 0.75;   # Don't exceed 75%
          storage = 0.80;  # Don't exceed 80%
        };
        growthRate = 0.15;  # Expecting 15% monthly growth
      };
    in
    {
      inherit planner;
      
      # Forecast results (computed)
      forecast = {
        month1 = {
          estimatedNodeCount = 23;
          estimatedCpuDemand = "736 cores";
          estimatedMemoryDemand = "1472Gi";
        };
        month2 = {
          estimatedNodeCount = 26;
          estimatedCpuDemand = "832 cores";
          estimatedMemoryDemand = "1664Gi";
        };
        month3 = {
          estimatedNodeCount = 30;
          estimatedCpuDemand = "960 cores";
          estimatedMemoryDemand = "1920Gi";
        };
      };
    };

  # ============================================================================
  # Example 5: Resource Optimization with VPA & HPA Recommendations
  # ============================================================================
  
  resource_optimization =
    let
      optimizer = orchestration.mkResourceOptimizer "api-server-optimization" {
        workloadName = "api-server";
        workloadType = "deployment";
        analysisWindow = 30;  # Analyze last 30 days
        recommendationType = "balanced";
        
        vpaRecommendations = {
          enabled = true;
          updateMode = "Auto";  # Automatically apply recommendations
          minAllowedResources = {
            cpu = "250m";
            memory = "256Mi";
          };
          maxAllowedResources = {
            cpu = "4";
            memory = "8Gi";
          };
        };
        
        hpaRecommendations = {
          enabled = true;
          metric = "cpu";
          targetValue = 70;  # Target 70% CPU utilization
          minReplicas = 3;
          maxReplicas = 30;
        };
      };
      
      # Conservative recommendations (stable, low risk)
      conservativeOptimizer = orchestration.mkResourceOptimizer "batch-jobs" {
        workloadName = "batch-processor";
        workloadType = "deployment";
        recommendationType = "conservative";
        vpaRecommendations.updateMode = "Initial";  # Only on pod creation
      };
      
      # Aggressive recommendations (maximize efficiency)
      aggressiveOptimizer = orchestration.mkResourceOptimizer "cache-layer" {
        workloadName = "redis-cache";
        workloadType = "statefulset";
        recommendationType = "aggressive";
        vpaRecommendations.updateMode = "Recreate";  # Recreate pods for changes
      };
    in
    {
      inherit optimizer conservativeOptimizer aggressiveOptimizer;
    };

  # ============================================================================
  # Example 6: Zone-Aware Topology Distribution Strategy
  # ============================================================================
  
  topology_aware_scheduling =
    let
      # Zone spread strategy
      zoneStrategy = orchestration.mkTopologyStrategy "zone-balanced" {
        strategyType = "zone-spread";
        dimensions = ["topology.kubernetes.io/zone"];
        skewLimit = 1;  # Max skew of 1 pod between zones
        minDomains = 3;  # Spread across at least 3 zones
        nodeAffinityPolicy = "Honor";
        nodeTaintsPolicy = "Honor";
        topology = {
          "us-east-1a" = 3;
          "us-east-1b" = 3;
          "us-east-1c" = 3;
        };
      };
      
      # Rack-aware strategy
      rackStrategy = orchestration.mkTopologyStrategy "rack-balanced" {
        strategyType = "rack-spread";
        dimensions = ["topology.kubernetes.io/rack"];
        skewLimit = 2;
        minDomains = 2;
      };
      
      # Region-aware strategy
      regionStrategy = orchestration.mkTopologyStrategy "region-aware" {
        strategyType = "region-spread";
        dimensions = ["topology.kubernetes.io/region"];
        skewLimit = 5;
        minDomains = 2;
      };
    in
    {
      inherit zoneStrategy rackStrategy regionStrategy;
    };

  # ============================================================================
  # Example 7: Critical Workload Multi-Cloud Placement
  # ============================================================================
  
  critical_workload_placement =
    let
      placement = orchestration.mkWorkloadPlacement "critical-database" {
        workloadName = "postgresql-primary";
        
        placementConstraints = {
          minReplicas = 1;  # Always at least one replica
          maxReplicas = 3;
          preferredClusters = ["aws-us-east-1"];
        };
        
        multiCloudPlacement = true;
        preferredClusters = ["aws-us-east-1"];
        backupClusters = ["gcp-us-central" "azure-eastus"];
        
        locality = "regional";  # Keep in same region
        costOptimized = false;  # Prioritize availability
        highAvailability = true;  # Strict HA requirements
        
        tags = {
          tier = "critical";
          compliance = "PCI-DSS";
          dataResidency = "us-only";
        };
        
        constraints = [
          {
            type = "resource";
            key = "memory";
            minValue = "8Gi";
          }
          {
            type = "region";
            key = "data-residency";
            values = ["us-east" "us-west"];
          }
          {
            type = "network";
            key = "bandwidth";
            minValue = "1Gbps";
          }
        ];
      };
    in
    {
      inherit placement;
    };

  # ============================================================================
  # Example 8: Development/Staging/Production Environment Strategy
  # ============================================================================
  
  environment_orchestration =
    let
      # Production - Strict HA, cost not primary concern
      productionPlacement = orchestration.mkWorkloadPlacement "prod-app" {
        workloadName = "prod-app";
        placementConstraints.minReplicas = 3;
        placementConstraints.maxReplicas = 50;
        multiCloudPlacement = true;
        preferredClusters = ["aws-prod"];
        backupClusters = ["gcp-prod" "azure-prod"];
        locality = "regional";
        costOptimized = false;
        highAvailability = true;
        tags = { environment = "production"; tier = "critical"; };
      };
      
      # Staging - Balanced approach
      stagingPlacement = orchestration.mkWorkloadPlacement "staging-app" {
        workloadName = "staging-app";
        placementConstraints.minReplicas = 2;
        placementConstraints.maxReplicas = 10;
        multiCloudPlacement = false;
        preferredClusters = ["aws-staging"];
        locality = "zonal";
        costOptimized = true;
        highAvailability = true;
        tags = { environment = "staging"; tier = "standard"; };
      };
      
      # Development - Cost-focused
      developmentPlacement = orchestration.mkWorkloadPlacement "dev-app" {
        workloadName = "dev-app";
        placementConstraints.minReplicas = 1;
        placementConstraints.maxReplicas = 3;
        multiCloudPlacement = false;
        preferredClusters = ["aws-dev"];
        locality = "local";
        costOptimized = true;
        highAvailability = false;
        tags = { environment = "development"; tier = "standard"; };
      };
      
      # Production priority class
      productionPriority = orchestration.mkPriorityClass "production" {
        value = 5000;
        description = "Production workload priority";
        preemptionPolicy = "PreemptLowerPriority";
      };
      
      # Staging priority class
      stagingPriority = orchestration.mkPriorityClass "staging" {
        value = 2000;
        description = "Staging workload priority";
        preemptionPolicy = "PreemptLowerPriority";
      };
      
      # Development priority class
      developmentPriority = orchestration.mkPriorityClass "development" {
        value = 500;
        description = "Development workload priority";
        preemptionPolicy = "Never";  # Don't interrupt dev work
      };
    in
    {
      production = {
        inherit productionPlacement productionPriority;
        pdb = orchestration.mkPodDisruptionBudget "prod-pdb" {
          namespace = "production";
          selector = { matchLabels = { env = "production"; }; };
          minAvailable = 2;
        };
      };
      
      staging = {
        inherit stagingPlacement stagingPriority;
        pdb = orchestration.mkPodDisruptionBudget "staging-pdb" {
          namespace = "staging";
          selector = { matchLabels = { env = "staging"; }; };
          minAvailable = 1;
        };
      };
      
      development = {
        inherit developmentPlacement developmentPriority;
        pdb = orchestration.mkPodDisruptionBudget "dev-pdb" {
          namespace = "development";
          selector = { matchLabels = { env = "development"; }; };
          maxUnavailable = 1;  # Allow some disruption in dev
        };
      };
    };

  # ============================================================================
  # Framework information
  # ============================================================================
  
  framework_info = orchestration.framework;
}
