# Performance Analysis Examples for Nixernetes
#
# Production-ready examples demonstrating:
# - Resource profiling and utilization analysis
# - Bottleneck detection and root cause analysis
# - Optimization recommendations
# - Performance comparison and trending

{ lib }:

let
  performanceAnalysis = import ../src/lib/performance-analysis.nix { inherit lib; };

in
{
  # Example 1: Production Workload Profiling
  productionWorkloadProfile = {
    name = "production-workload-profile";
    description = "Profile production microservices workloads";

    workloads = [
      {
        name = "frontend-app";
        namespace = "production";
        type = "deployment";
        containers = 1;
        cpu = { requested = "100m"; limit = "500m"; actual = "45m"; peak = "200m"; };
        memory = { requested = "128Mi"; limit = "512Mi"; actual = "90Mi"; peak = "300Mi"; };
        disk = { requested = "1Gi"; used = "500Mi"; peak = "800Mi"; };
        network = { inbound = "10Mbps"; outbound = "5Mbps"; peakInbound = "50Mbps"; };
      }
      {
        name = "api-server";
        namespace = "production";
        type = "statefulset";
        containers = 2;
        cpu = { requested = "200m"; limit = "1000m"; actual = "150m"; peak = "600m"; };
        memory = { requested = "256Mi"; limit = "1Gi"; actual = "200Mi"; peak = "800Mi"; };
        disk = { requested = "10Gi"; used = "5Gi"; peak = "9Gi"; };
      }
      {
        name = "database";
        namespace = "production";
        type = "pod";
        containers = 1;
        cpu = { requested = "500m"; limit = "2000m"; actual = "300m"; peak = "1500m"; };
        memory = { requested = "512Mi"; limit = "2Gi"; actual = "400Mi"; peak = "1.8Gi"; };
        disk = { requested = "50Gi"; used = "30Gi"; peak = "48Gi"; };
      }
    ];

    profile = performanceAnalysis.profileResources {
      workloads = this.workloads;
      config = {
        breakdownByNamespace = true;
        breakdownByPod = true;
        timeWindow = "7d";
      };
    };

    summary = {
      totalWorkloads = lib.length this.workloads;
      cpuEfficiency = this.profile.utilizationAnalysis.cpu.efficiency;
      memoryEfficiency = this.profile.utilizationAnalysis.memory.efficiency;
      peakCpuUtilization = this.profile.aggregated.peakCpuUtilization;
    };
  };

  # Example 2: Bottleneck Detection
  bottleneckAnalysis = {
    name = "bottleneck-detection-analysis";
    description = "Detect performance bottlenecks";

    metrics = {
      cpu = 80;
      memory = 70;
      disk = 55;
      network = 65;
      latency = 95;
      errorRate = 0.8;
    };

    bottlenecks = performanceAnalysis.detectBottlenecks {
      inherit (this) metrics;
      config = {
        cpuThreshold = 75;
        memoryThreshold = 80;
        latencyThreshold = 100;
        errorRateThreshold = 1.0;
      };
    };

    analysis = {
      status = this.bottlenecks.healthStatus;
      criticalIssues = this.bottlenecks.criticalCount;
      cpuBottleneck = lib.any (b: b.component == "CPU" && b.status == "BOTTLENECK") this.bottlenecks.bottlenecks;
      rootCauses = this.bottlenecks.rootCauseAnalysis.causes;
    };
  };

  # Example 3: Optimization Recommendations
  optimizationPlan = {
    name = "optimization-recommendations";
    description = "Generate optimization recommendations";

    profile = productionWorkloadProfile.profile;
    bottlenecks = bottleneckAnalysis.bottlenecks;

    recommendations = performanceAnalysis.recommendOptimizations {
      inherit (this) profile bottlenecks;
      config = {
        includeCapacityPlanning = true;
        includeResourceOptimization = true;
        estimateImpact = true;
      };
    };

    executiveSummary = {
      totalRecommendations = this.recommendations.statistics.totalRecommendations;
      estimatedCostSavings = this.recommendations.impactAnalysis.estimatedCostSavings;
      implementationTime = this.recommendations.impactAnalysis.implementationTime;
      riskLevel = this.recommendations.impactAnalysis.riskLevel;
    };

    actionItems = this.recommendations.prioritizedRecommendations;
  };

  # Example 4: Performance Comparison
  performanceComparison = {
    name = "performance-comparison";
    description = "Compare performance across deployments";

    baseline = {
      cpu = 50;
      memory = 45;
      latency = 100;
      errorRate = 0.5;
      throughput = 1000;
    };

    afterOptimization = {
      cpu = 45;
      memory = 40;
      latency = 85;
      errorRate = 0.3;
      throughput = 1200;
    };

    comparison = performanceAnalysis.comparePerformance {
      baseline = this.baseline;
      current = this.afterOptimization;
    };

    results = {
      verdict = this.comparison.verdict;
      regressions = lib.length this.comparison.regressions;
      improvements = [
        "CPU utilization reduced by 10%"
        "Latency improved by 15%"
        "Error rate decreased by 40%"
        "Throughput increased by 20%"
      ];
    };
  };

  # Example 5: Trend Analysis and Forecasting
  trendAnalysis = {
    name = "trend-analysis-forecast";
    description = "Analyze trends and forecast future usage";

    # Historical measurements over 7 days
    measurements = {
      cpu = [ 45 47 46 48 50 49 51 ];
      memory = [ 40 42 41 43 45 44 46 ];
      latency = [ 95 98 96 100 102 101 105 ];
    };

    trends = performanceAnalysis.analyzeTrends {
      inherit (this) measurements;
      config = {
        trendWindow = "7d";
        forecastDays = 7;
      };
    };

    analysis = {
      cpuTrend = this.trends.trends.cpu;
      memoryTrend = this.trends.trends.memory;
      latencyTrend = this.trends.trends.latency;
      forecast = this.trends.forecast;
      anomalies = lib.length this.trends.anomalies;
    };

    capacityPlanning = {
      currentAverage = {
        cpu = this.trends.trends.cpu.average;
        memory = this.trends.trends.memory.average;
      };
      forecast7Days = {
        cpu = this.trends.forecast.cpuForecast;
        memory = this.trends.forecast.memoryForecast;
      };
      capacityPlan = "Current capacity sufficient for 7 days";
    };
  };

  # Example 6: Comprehensive Performance Report
  comprehensiveReport = {
    name = "comprehensive-performance-report";
    description = "Full performance analysis and recommendations";

    profile = productionWorkloadProfile.profile;
    bottlenecks = bottleneckAnalysis.bottlenecks;
    recommendations = optimizationPlan.recommendations;

    report = performanceAnalysis.generatePerformanceReport {
      inherit (this) profile bottlenecks recommendations;
    };

    executiveSummary = {
      overallHealth = this.report.summary.overallHealth;
      criticalIssues = this.report.summary.criticalIssues;
      recommendations = this.report.summary.recommendationCount;
      improvementPotential = this.report.summary.estimatedImprovementPotential;
    };

    keyFindings = [
      "CPU utilization at ${toString this.report.metrics.cpuUtilization}%"
      "Memory utilization at ${toString this.report.metrics.memoryUtilization}%"
      "${toString this.report.summary.criticalIssues} critical issues identified"
      "${toString this.report.summary.recommendationCount} optimization opportunities"
    ];

    actionPlan = this.report.actionPlan;

    implementationTimeline = {
      phase1 = "Address critical bottlenecks (1-2 weeks)";
      phase2 = "Implement low-effort optimizations (2-3 weeks)";
      phase3 = "Plan architecture improvements (1 month)";
    };
  };

  # Project summary
  projectMetrics = {
    workloadsAnalyzed = lib.length productionWorkloadProfile.workloads;
    bottlenecksDetected = bottleneckAnalysis.bottlenecks.statistics.bottleneckedComponents;
    recommendationsGenerated = optimizationPlan.recommendations.statistics.totalRecommendations;
    costSavingsPotential = optimizationPlan.recommendations.impactAnalysis.estimatedCostSavings;
  };
}
