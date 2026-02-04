# Performance Analysis Guide

## Overview

The Performance Analysis module provides comprehensive workload performance analysis, bottleneck detection, and optimization recommendations for Kubernetes environments. It profiles resource utilization, identifies constraints, and generates actionable recommendations.

## Features

### Resource Profiling

Analyzes CPU, memory, disk, and network utilization across workloads.

```nix
let
  workloads = [
    {
      name = "web-app";
      namespace = "production";
      type = "pod";
      containers = 2;
      cpu = { requested = "100m"; limit = "500m"; actual = "45m"; peak = "200m"; };
      memory = { requested = "128Mi"; limit = "512Mi"; actual = "90Mi"; };
      disk = { requested = "1Gi"; used = "500Mi"; };
      network = { inbound = "10Mbps"; outbound = "5Mbps"; };
    }
  ];
  
  profile = performanceAnalysis.profileResources {
    inherit workloads;
    config = {
      breakdownByNamespace = true;
      breakdownByPod = true;
      timeWindow = "7d";
    };
  };
in
  profile
```

**Output Structure:**
```nix
{
  type = "resource-profile";
  workloads = [ /* profiled workloads */ ];
  aggregated = {
    totalWorkloads = 2;
    totalCpuRequested = 200;
    avgCpuUtilization = 40.0;
    peakCpuUtilization = 85.0;
  };
  byNamespace = { /* grouped by namespace */ };
  utilizationAnalysis = {
    cpu = { average = 40.0; peak = 85.0; efficiency = "MODERATE"; };
    memory = { average = 35.0; peak = 60.0; efficiency = "GOOD"; };
  };
  statistics = {
    profiledWorkloads = 2;
    namespaces = 1;
  };
}
```

### Bottleneck Detection

Identifies performance bottlenecks and constraints.

```nix
let
  metrics = {
    cpu = 85;      # Percentage utilization
    memory = 75;
    disk = 60;
    network = 40;
    latency = 150;  # Milliseconds
    errorRate = 1.5;  # Percentage
  };
  
  bottlenecks = performanceAnalysis.detectBottlenecks {
    inherit metrics;
    config = {
      cpuThreshold = 75;
      memoryThreshold = 80;
      diskThreshold = 85;
      latencyThreshold = 100;
    };
  };
in
  bottlenecks
```

**Bottleneck Types:**
- CPU bottleneck: High CPU utilization
- Memory bottleneck: Memory pressure
- Disk bottleneck: I/O constraints
- Network bottleneck: Network saturation
- Latency bottleneck: High response times
- Error rate bottleneck: Elevated error rates

**Output:**
```nix
{
  type = "bottleneck-detection";
  bottlenecks = [
    { component = "CPU"; status = "BOTTLENECK"; severity = "HIGH"; }
    { component = "Memory"; status = "HEALTHY"; severity = "NONE"; }
  ];
  criticalCount = 1;
  healthStatus = "WARNING";
  rootCauseAnalysis = {
    identified = 1;
    causes = [ /* root causes */ ];
  };
  statistics = {
    totalComponents = 6;
    healthyComponents = 5;
    bottleneckedComponents = 1;
    criticalComponents = 0;
  };
}
```

### Optimization Recommendations

Provides actionable optimization recommendations.

```nix
let
  profile = performanceAnalysis.profileResources { workloads = [...]; };
  bottlenecks = performanceAnalysis.detectBottlenecks { metrics = {...}; };
  
  recommendations = performanceAnalysis.recommendOptimizations {
    inherit profile bottlenecks;
    config = {
      includeCapacityPlanning = true;
      includeResourceOptimization = true;
      estimateImpact = true;
    };
  };
in
  recommendations
```

**Recommendation Types:**
- Resource Optimization: Adjust CPU/memory requests
- Capacity Planning: Increase resources
- Scaling Strategy: Implement autoscaling
- Architecture Changes: Restructure workloads

**Output:**
```nix
{
  type = "optimization-recommendations";
  recommendations = [
    {
      workload = "web-app";
      category = "Resource Optimization";
      recommendation = "Reduce CPU request from 500m to 300m";
      rationale = "Only using 45m on average";
      estimatedSavings = "30-40%";
      effort = "LOW";
      risk = "LOW";
    }
  ];
  byCategory = { /* grouped by category */ };
  impactAnalysis = {
    estimatedCostSavings = "20-30%";
    performanceImprovement = "15-25%";
  };
  prioritizedRecommendations = [ /* sorted by effort */ ];
}
```

### Performance Comparison

Compares performance across configurations or time periods.

```nix
let
  baseline = {
    cpu = 50;
    memory = 45;
    latency = 100;
    errorRate = 0.5;
  };
  
  current = {
    cpu = 55;
    memory = 48;
    latency = 110;
    errorRate = 0.8;
  };
  
  comparison = performanceAnalysis.comparePerformance {
    inherit baseline current;
  };
in
  comparison
```

**Output:**
```nix
{
  type = "performance-comparison";
  comparisons = {
    cpu = { absolute = 5; percentage = 10.0; direction = "increased"; };
    memory = { absolute = 3; percentage = 6.7; direction = "increased"; };
    latency = { absolute = 10; percentage = 10.0; direction = "increased"; };
  };
  regressions = [ /* detected regressions */ ];
  verdict = "STABLE";
  statistics = {
    componentsChanged = 3;
    regressions = 0;
    improvements = 0;
  };
}
```

### Trend Analysis

Analyzes performance trends over time.

```nix
let
  measurements = {
    cpu = [ 50 51 49 52 50 ];
    memory = [ 45 46 44 47 45 ];
    latency = [ 100 102 98 105 101 ];
  };
  
  trends = performanceAnalysis.analyzeTrends {
    inherit measurements;
    config = {
      trendWindow = "30d";
      forecastDays = 7;
      anomalyThreshold = 2.0;
    };
  };
in
  trends
```

**Output:**
```nix
{
  type = "performance-trends";
  trends = {
    cpu = { average = 50.4; min = 49; max = 52; stdDev = 1.2; };
    memory = { average = 45.4; min = 44; max = 47; stdDev = 1.1; };
  };
  forecast = {
    cpuForecast = 50.4;
    memoryForecast = 45.4;
    confidenceLevel = 95;
  };
  anomalies = [];
  statistics = {
    measurementsAnalyzed = 5;
    trendingUp = 0;
    trendingDown = 0;
    stable = 3;
  };
}
```

### Performance Report

Generates comprehensive performance analysis report.

```nix
let
  profile = performanceAnalysis.profileResources { workloads = [...]; };
  bottlenecks = performanceAnalysis.detectBottlenecks { metrics = {...}; };
  recommendations = performanceAnalysis.recommendOptimizations { inherit profile bottlenecks; };
  
  report = performanceAnalysis.generatePerformanceReport {
    inherit profile bottlenecks recommendations;
  };
in
  report
```

**Report Contents:**
```nix
{
  type = "performance-report";
  summary = {
    overallHealth = "GOOD";
    criticalIssues = 0;
    recommendationCount = 3;
    estimatedImprovementPotential = "20-30%";
  };
  metrics = {
    cpuUtilization = 50.0;
    memoryUtilization = 45.0;
    containerDensity = 5;
  };
  findings = {
    bottlenecks = [ /* bottlenecks */ ];
    recommendations = [ /* recommendations */ ];
    score = 75.0;
  };
  actionPlan = [
    { priority = "HIGH"; action = "Address critical bottlenecks"; timeline = "1-2 weeks"; }
  ];
}
```

## Usage Examples

### Complete Performance Analysis Workflow

```nix
let
  # 1. Profile resources
  profile = performanceAnalysis.profileResources { workloads = [...]; };
  
  # 2. Detect bottlenecks
  bottlenecks = performanceAnalysis.detectBottlenecks {
    metrics = {
      cpu = profile.utilizationAnalysis.cpu.average;
      memory = profile.utilizationAnalysis.memory.average;
    };
  };
  
  # 3. Get recommendations
  recommendations = performanceAnalysis.recommendOptimizations {
    inherit profile bottlenecks;
  };
  
  # 4. Generate report
  report = performanceAnalysis.generatePerformanceReport {
    inherit profile bottlenecks recommendations;
  };
in
  {
    profile = profile;
    bottlenecks = bottlenecks;
    recommendations = recommendations;
    report = report;
    
    summary = {
      health = report.summary.overallHealth;
      issues = report.summary.criticalIssues;
      improvements = recommendations.impactAnalysis.estimatedCostSavings;
    };
  }
```

### Pre-Deployment Performance Check

```nix
let
  # Profile current environment
  currentProfile = performanceAnalysis.profileResources { workloads = current_workloads; };
  
  # Profile after deployment
  proposedProfile = performanceAnalysis.profileResources { workloads = proposed_workloads; };
  
  # Compare performance
  comparison = performanceAnalysis.comparePerformance {
    baseline = currentProfile.utilizationAnalysis;
    current = proposedProfile.utilizationAnalysis;
  };
in
  {
    canDeploy = comparison.verdict != "REGRESSION_DETECTED";
    verdict = comparison.verdict;
    regressions = lib.length comparison.regressions;
  }
```

### Capacity Planning

```nix
let
  # Analyze current usage
  profile = performanceAnalysis.profileResources { workloads = [...]; };
  
  # Analyze trends
  trends = performanceAnalysis.analyzeTrends { measurements = {...}; };
  
  # Get forecast
  forecast = trends.forecast;
in
  {
    currentUsage = profile.utilizationAnalysis;
    forecast = forecast;
    capacityNeeded = 
      if forecast.cpuForecast > 70 then "INCREASE_NEEDED"
      else "SUFFICIENT";
  }
```

## Configuration

### Profiling Configuration

```nix
{
  includeMetadata = true;
  breakdownByNamespace = true;
  breakdownByPod = true;
  includeHistorical = true;
  timeWindow = "7d";
  samplingInterval = "1m";
}
```

### Bottleneck Detection Configuration

```nix
{
  cpuThreshold = 75;              # Percentage
  memoryThreshold = 80;           # Percentage
  diskThreshold = 85;             # Percentage
  networkThreshold = 80;          # Percentage
  latencyThreshold = 100;         # Milliseconds
  errorRateThreshold = 1.0;       # Percentage
}
```

### Optimization Configuration

```nix
{
  includeCapacityPlanning = true;
  includeResourceOptimization = true;
  includeArchitectureChanges = true;
  estimateImpact = true;
}
```

### Trend Analysis Configuration

```nix
{
  timeUnit = "day";
  trendWindow = "30d";
  forecastDays = 7;
  anomalyThreshold = 2.0;         # Standard deviations
}
```

## Integration with Other Modules

### With Cost Analysis

```nix
let
  profile = performanceAnalysis.profileResources { workloads = [...]; };
  costs = costAnalysis.calculateCosts { resources = profile.aggregated; };
  
  recommendations = performanceAnalysis.recommendOptimizations { inherit profile; };
  costSavings = recommendations.impactAnalysis.estimatedCostSavings;
in
  { costs = costs; potential_savings = costSavings; }
```

### With Security Scanning

```nix
let
  profile = performanceAnalysis.profileResources { workloads = [...]; };
  
  # Include security metadata
  workloadsWithSecurity = builtins.map (w: 
    w // { security_score = 85; }
  ) profile.workloads;
in
  { profile = profile; secure = true; }
```

## Best Practices

1. **Regular Profiling** - Profile workloads weekly
2. **Threshold Tuning** - Adjust thresholds based on SLOs
3. **Trend Monitoring** - Track metrics over time
4. **Capacity Planning** - Plan ahead for growth
5. **Testing** - Validate recommendations before deployment
6. **Documentation** - Track optimization decisions

## See Also

- [Cost Analysis Guide](./COST_ANALYSIS.md)
- [Security Scanning Guide](./SECURITY_SCANNING.md)
- [Policies Guide](./POLICIES.md)
