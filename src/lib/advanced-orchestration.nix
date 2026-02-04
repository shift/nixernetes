# Advanced Orchestration Module
#
# This module provides multi-cloud workload scheduling, resource optimization,
# and advanced orchestration patterns:
#
# - Workload affinity and topology-aware scheduling
# - Pod disruption budgets and availability guarantees
# - Priority classes and preemption rules
# - Multi-cluster workload distribution
# - Cluster capacity planning and forecasting
# - Resource optimization with VPA/HPA recommendations
# - Zone and rack-aware scheduling strategies
# - Multi-cloud placement policies

{ lib, pkgs ? null }:

let
  inherit (lib)
    mkOption types optional optionals concatMap attrValues mapAttrs
    recursiveUpdate all any stringLength concatStringsSep;

  # Workload affinity policy builder
  mkWorkloadAffinityPolicy = name: config:
    let
      defaults = {
        name = name;
        podAffinityPresets = config.podAffinityPresets or [];
        nodeAffinityRules = config.nodeAffinityRules or [];
        topologySpreadConstraints = config.topologySpreadConstraints or [];
        antiAffinityStrength = config.antiAffinityStrength or "soft";  # soft | hard
        topologyKey = config.topologyKey or "kubernetes.io/hostname";
        spreadKey = config.spreadKey or "topology.kubernetes.io/zone";
      };
    in
    defaults // config;

  # Pod disruption budget builder
  mkPodDisruptionBudget = name: config:
    let
      defaults = {
        name = name;
        namespace = config.namespace or "default";
        selector = config.selector or { matchLabels = {}; };
        minAvailable = config.minAvailable or null;
        maxUnavailable = config.maxUnavailable or 1;
        unhealthyPodEvictionPolicy = config.unhealthyPodEvictionPolicy or "IfHealthyBudget";
        # Supported policies:
        # - IfHealthyBudget: Don't evict unhealthy pods
        # - AlwaysAllow: Evict all pods, budget allows
      };
    in
    defaults // config;

  # Priority class builder
  mkPriorityClass = name: config:
    let
      defaults = {
        name = name;
        value = config.value or 0;
        globalDefault = config.globalDefault or false;
        description = config.description or "Priority class ${name}";
        preemptionPolicy = config.preemptionPolicy or "PreemptLowerPriority";
        # Policies:
        # - PreemptLowerPriority: Can preempt lower priority pods
        # - Never: Never preempts other pods
      };
    in
    defaults // config;

  # Multi-cluster policy builder
  mkMultiClusterPolicy = name: config:
    let
      defaults = {
        name = name;
        clusters = config.clusters or [];
        distribution = config.distribution or "round-robin";  # round-robin | weighted | latency-based | cost-optimized
        weights = config.weights or {};
        failoverChain = config.failoverChain or [];
        preferredRegions = config.preferredRegions or [];
        costOptimization = config.costOptimization or false;
        latencyThreshold = config.latencyThreshold or 100;  # milliseconds
        metadata = {
          created = config.metadata.created or "2024-02-04";
          version = config.metadata.version or "1.0.0";
        };
      };
    in
    defaults // config;

  # Capacity planner builder
  mkCapacityPlanner = name: config:
    let
      defaults = {
        name = name;
        clusterName = config.clusterName or "";
        currentCapacity = {
          nodes = config.currentCapacity.nodes or 0;
          cpuPerNode = config.currentCapacity.cpuPerNode or "4";
          memoryPerNode = config.currentCapacity.memoryPerNode or "8Gi";
          storagePerNode = config.currentCapacity.storagePerNode or "100Gi";
        };
        currentUtilization = {
          cpu = config.currentUtilization.cpu or 0.5;
          memory = config.currentUtilization.memory or 0.6;
          storage = config.currentUtilization.storage or 0.4;
        };
        forecastingPeriod = config.forecastingPeriod or 90;  # days
        targetUtilization = {
          cpu = config.targetUtilization.cpu or 0.7;
          memory = config.targetUtilization.memory or 0.75;
          storage = config.targetUtilization.storage or 0.80;
        };
        growthRate = config.growthRate or 0.1;  # 10% per month
      };
    in
    defaults // config;

  # Resource optimizer builder
  mkResourceOptimizer = name: config:
    let
      defaults = {
        name = name;
        workloadName = config.workloadName or "";
        workloadType = config.workloadType or "deployment";  # deployment | statefulset | daemonset
        analysisWindow = config.analysisWindow or 30;  # days
        recommendationType = config.recommendationType or "balanced";  # conservative | balanced | aggressive
        vpaRecommendations = {
          enabled = config.vpaRecommendations.enabled or true;
          updateMode = config.vpaRecommendations.updateMode or "Auto";  # Off | Initial | Recreate | Auto
          minAllowedResources = config.vpaRecommendations.minAllowedResources or {
            cpu = "100m";
            memory = "128Mi";
          };
          maxAllowedResources = config.vpaRecommendations.maxAllowedResources or {
            cpu = "4";
            memory = "8Gi";
          };
        };
        hpaRecommendations = {
          enabled = config.hpaRecommendations.enabled or true;
          metric = config.hpaRecommendations.metric or "cpu";  # cpu | memory | custom
          targetValue = config.hpaRecommendations.targetValue or 70;
          minReplicas = config.hpaRecommendations.minReplicas or 1;
          maxReplicas = config.hpaRecommendations.maxReplicas or 10;
        };
      };
    in
    defaults // config;

  # Topology strategy builder
  mkTopologyStrategy = name: config:
    let
      defaults = {
        name = name;
        strategyType = config.strategyType or "zone-spread";  # zone-spread | rack-spread | region-spread | custom
        dimensions = config.dimensions or ["topology.kubernetes.io/zone"];
        skewLimit = config.skewLimit or 1;
        minDomains = config.minDomains or 1;
        nodeAffinityPolicy = config.nodeAffinityPolicy or "Honor";  # Honor | Ignore
        nodeTaintsPolicy = config.nodeTaintsPolicy or "Honor";  # Honor | Ignore
        topology = config.topology or {};
      };
    in
    defaults // config;

  # Workload placement builder
  mkWorkloadPlacement = name: config:
    let
      defaults = {
        name = name;
        workloadName = config.workloadName or "";
        placementConstraints = config.placementConstraints or {};
        multiCloudPlacement = config.multiCloudPlacement or false;
        preferredClusters = config.preferredClusters or [];
        backupClusters = config.backupClusters or [];
        locality = config.locality or "local";  # local | regional | global
        costOptimized = config.costOptimized or false;
        highAvailability = config.highAvailability or true;
        tags = config.tags or {};
        constraints = config.constraints or [];
      };
    in
    defaults // config;

  # Pod spreading constraint builder
  mkPodSpreadingConstraint = config:
    let
      defaults = {
        maxSkew = config.maxSkew or 1;
        topologyKey = config.topologyKey or "kubernetes.io/hostname";
        whenUnsatisfiable = config.whenUnsatisfiable or "DoNotSchedule";
        labelSelector = config.labelSelector or { matchLabels = {}; };
        minDomains = config.minDomains or 1;
        nodeAffinityPolicy = config.nodeAffinityPolicy or "Honor";
        nodeTaintsPolicy = config.nodeTaintsPolicy or "Honor";
      };
    in
    defaults // config;

  # Node affinity constraint builder
  mkNodeAffinityConstraint = config:
    let
      defaults = {
        type = config.type or "required";  # required | preferred
        operator = config.operator or "In";  # In | NotIn | Exists | DoesNotExist | Gt | Lt
        key = config.key or "";
        values = config.values or [];
        weight = config.weight or 100;  # 1-100, only for preferred
      };
    in
    defaults // config;

  # Multi-cloud cost calculator
  calculateMultiCloudCost = workload: clusters:
    let
      clusterCosts = mapAttrs (clusterName: clusterConfig:
        let
          cpuCost = (workload.resources.requests.cpu or "100m") * (clusterConfig.hourlyRate or 0.05);
          memoryCost = (workload.resources.requests.memory or "128Mi") * (clusterConfig.hourlyRate or 0.05);
        in
        {
          name = clusterName;
          monthlyCost = (cpuCost + memoryCost) * 730;  # hours per month
          hourlyRate = clusterConfig.hourlyRate or 0.05;
        }
      ) clusters;
    in
    {
      byCluster = clusterCosts;
      cheapest = lib.elemAt (lib.sort (a: b: a.monthlyCost < b.monthlyCost) (attrValues clusterCosts)) 0;
      average = 
        let
          costs = map (c: c.monthlyCost) (attrValues clusterCosts);
          sum = lib.foldl' (a: b: a + b) 0 costs;
        in
        sum / (builtins.length costs);
    };

  # Affinity helper - Create pod anti-affinity for HA
  mkPodAntiAffinityHA = appLabel: strength:
    let
      affinityType = if strength == "hard" then "requiredDuringSchedulingIgnoredDuringExecution" else "preferredDuringSchedulingIgnoredDuringExecution";
    in
    {
      ${affinityType} = [
        {
          labelSelector = {
            matchExpressions = [
              {
                key = "app";
                operator = "In";
                values = [appLabel];
              }
            ];
          };
          topologyKey = "kubernetes.io/hostname";
          weight = 100;
        }
      ];
    };

  # Zone spread helper - Spread pods across zones
  mkZoneSpreadConstraint = appLabel:
    {
      maxSkew = 1;
      topologyKey = "topology.kubernetes.io/zone";
      whenUnsatisfiable = "DoNotSchedule";
      labelSelector = {
        matchExpressions = [
          {
            key = "app";
            operator = "In";
            values = [appLabel];
          }
        ];
      };
    };

  # Validation helpers
  validateAffinityPolicy = policy:
    let
      hasName = policy.name or null != null;
      hasRules = policy.nodeAffinityRules or null != null || policy.podAffinityPresets or null != null;
    in
    {
      valid = hasName && hasRules;
      errors = []
        ++ (optional (!hasName) "Affinity policy must have a name")
        ++ (optional (!hasRules) "Affinity policy must have rules");
    };

  validateMultiClusterPolicy = policy:
    let
      hasName = policy.name or null != null;
      hasClusters = (policy.clusters or []) != [];
      validDistribution = builtins.elem policy.distribution ["round-robin" "weighted" "latency-based" "cost-optimized"];
    in
    {
      valid = hasName && hasClusters && validDistribution;
      errors = []
        ++ (optional (!hasName) "Multi-cluster policy must have a name")
        ++ (optional (!hasClusters) "Multi-cluster policy must have clusters")
        ++ (optional (!validDistribution) "Invalid distribution strategy: ${policy.distribution}");
    };

in
{
  # Core builders
  inherit mkWorkloadAffinityPolicy mkPodDisruptionBudget mkPriorityClass;
  inherit mkMultiClusterPolicy mkCapacityPlanner mkResourceOptimizer;
  inherit mkTopologyStrategy mkWorkloadPlacement mkPodSpreadingConstraint;
  inherit mkNodeAffinityConstraint;

  # Helper functions
  inherit mkPodAntiAffinityHA mkZoneSpreadConstraint;
  inherit calculateMultiCloudCost;

  # Validation
  inherit validateAffinityPolicy validateMultiClusterPolicy;

  # Framework metadata
  framework = {
    name = "Nixernetes Advanced Orchestration";
    version = "1.0.0";
    author = "Nixernetes Team";
    features = [
      "workload-affinity"
      "pod-disruption-budgets"
      "priority-classes"
      "multi-cluster-distribution"
      "capacity-planning"
      "resource-optimization"
      "topology-aware-scheduling"
      "workload-placement"
      "multi-cloud-support"
      "cost-optimization"
      "high-availability"
    ];
    supportedStrategies = [
      "round-robin"
      "weighted"
      "latency-based"
      "cost-optimized"
      "zone-spread"
      "rack-spread"
      "region-spread"
    ];
    supportedKubernetesVersions = ["1.28" "1.29" "1.30"];
  };
}
