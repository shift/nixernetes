# Cost Analysis Module
#
# This module provides:
# - Resource cost calculation based on CPU and memory
# - Cost estimation for different cloud providers (AWS, Azure, GCP)
# - Cost optimization recommendations
# - Namespace and resource-level cost breakdown
# - Monthly and annual cost projections

{ lib }:

let
  inherit (lib) mkOption types;
  
  # Pricing data for different cloud providers
  # This is based on standard on-demand pricing (2024 rates)
  # Prices are in USD per hour
  awsPricing = {
    cpu = 0.0535;        # $0.0535 per vCPU-hour (m5.large equivalent)
    memory = 0.0108;     # $0.0108 per GB-hour (m5.large equivalent)
  };
  
  azurePricing = {
    cpu = 0.0490;        # $0.049 per vCPU-hour
    memory = 0.0098;     # $0.0098 per GB-hour
  };
  
  gcpPricing = {
    cpu = 0.0440;        # $0.044 per vCPU-hour (n2 machine)
    memory = 0.0059;     # $0.0059 per GB-hour (n2 machine)
  };
  
  # Parse resource quantity (e.g., "500m" -> 0.5, "1Gi" -> 1)
  parseQuantity = value:
    if builtins.isInt value then value
    else if builtins.isString value then
      let
        # Handle CPU values with "m" suffix (millicores)
        cpuMatch = builtins.match "([0-9]+)m" value;
      in
        if cpuMatch != null then
          (builtins.fromJSON (builtins.elemAt cpuMatch 0)) / 1000.0
        else
          # Handle memory values like 128Mi, 1Gi, etc.
          let
            memMatch = builtins.match "([0-9.]+)(Mi|Gi|Ti)" value;
          in
            if memMatch != null then
              let
                amount = builtins.fromJSON (builtins.elemAt memMatch 0);
                unit = builtins.elemAt memMatch 1;
              in
                if unit == "Gi" then amount
                else if unit == "Mi" then amount / 1024.0
                else if unit == "Ti" then amount * 1024.0
                else amount
            else
              # Try parsing as plain number
              let plainMatch = builtins.match "([0-9.]+)" value;
              in if plainMatch != null then
                builtins.fromJSON (builtins.elemAt plainMatch 0)
              else 0.0
    else 0.0;

  # Helper to calculate container cost
  containerCostHelper = container: provider:
    let
      pricing = 
        if provider == "aws" then awsPricing
        else if provider == "azure" then azurePricing
        else if provider == "gcp" then gcpPricing
        else awsPricing;
      
      requests = container.resources.requests or {};
      cpu = parseQuantity (requests.cpu or "100m");
      memory = parseQuantity (requests.memory or "128Mi");
    in
      (cpu * pricing.cpu) + (memory * pricing.memory);

in
{
  # Calculate hourly cost for a single container
  # containerCost :: { resources : { requests/limits }, provider : string } -> float
  mkContainerCost = { resources ? {}, provider ? "aws" }:
    let
      pricing = 
        if provider == "aws" then awsPricing
        else if provider == "azure" then azurePricing
        else if provider == "gcp" then gcpPricing
        else awsPricing;
      
      requests = resources.requests or {};
      cpu = parseQuantity (requests.cpu or "100m");
      memory = parseQuantity (requests.memory or "128Mi");
    in
      (cpu * pricing.cpu) + (memory * pricing.memory);

  # Calculate hourly cost for a Pod (sum of all containers)
  mkPodCost = { containers ? [], replicas ? 1, provider ? "aws" }:
    let
      totalContainerCost = builtins.foldl' (acc: container:
        acc + (containerCostHelper container provider)
      ) 0.0 containers;
    in
      totalContainerCost * replicas;

  # Analyze a Deployment and calculate costs
  mkDeploymentCost = { replicas ? 1, template ? {}, provider ? "aws" }:
    let
      spec = template.spec or {};
      containers = spec.containers or [];
      
      podCostPerHour = builtins.foldl' (acc: container:
        acc + (containerCostHelper container provider)
      ) 0.0 containers;
      
      totalHourly = podCostPerHour * replicas;
    in
      {
        hourly = totalHourly;
        daily = totalHourly * 24.0;
        monthly = totalHourly * 24.0 * 30.0;
        annual = totalHourly * 24.0 * 365.0;
        perPod = {
          hourly = podCostPerHour;
          daily = podCostPerHour * 24.0;
          monthly = podCostPerHour * 24.0 * 30.0;
          annual = podCostPerHour * 24.0 * 365.0;
        };
      };

  # Generate cost recommendations for optimization
  mkCostRecommendations = { deployments ? {} }:
    let
      # Check for oversized CPU requests
      checkCpuOversizing = depName:
        let
          deployment = deployments.${depName};
          spec = deployment.spec.template.spec or {};
          containers = spec.containers or [];
          issues = builtins.concatMap (container:
            let
              requests = container.resources.requests or {};
              cpu = parseQuantity (requests.cpu or "100m");
              limits = container.resources.limits or {};
              cpuLimit = parseQuantity (limits.cpu or "1000m");
            in
              if cpu > 2.0 && cpu > (cpuLimit * 0.8) then
                [{
                  deployment = depName;
                  severity = "medium";
                  resource = container.name or "unknown";
                  issue = "CPU request significantly exceeds typical usage";
                  impact = "High CPU requests increase hourly cost";
                  recommendation = "Consider reducing CPU request to 1-2 cores for most workloads";
                  savings = cpu - 1.0;
                }]
              else []
          ) containers;
        in issues;
      
      # Check for missing memory limits
      checkMemoryLimits = depName:
        let
          deployment = deployments.${depName};
          spec = deployment.spec.template.spec or {};
          containers = spec.containers or [];
          issues = builtins.concatMap (container:
            let
              limits = container.resources.limits or {};
              hasMemLimit = (limits.memory or null) != null;
            in
              if !hasMemLimit then
                [{
                  deployment = depName;
                  severity = "low";
                  resource = container.name or "unknown";
                  issue = "No memory limit specified";
                  impact = "Pod can consume unlimited memory, risking OOMKill";
                  recommendation = "Set memory limit equal to or slightly above memory request";
                }]
              else []
          ) containers;
        in issues;
      
      depNames = builtins.attrNames deployments;
      allRecommendations = builtins.concatMap (depName:
        (checkCpuOversizing depName) ++ (checkMemoryLimits depName)
      ) depNames;
    in
      allRecommendations;

  # Summary statistics for cost analysis
  mkCostSummary = { deployments ? {}, provider ? "aws" }:
    let
      calculateDeploymentCost = depName:
        let
          deployment = deployments.${depName};
          spec = deployment.spec.template.spec or {};
          containers = spec.containers or [];
          replicas = deployment.spec.replicas or 1;
          
          podCost = builtins.foldl' (acc: container:
            acc + (containerCostHelper container provider)
          ) 0.0 containers;
        in
          {
            name = depName;
            replicas = replicas;
            hourly = podCost * replicas;
            daily = podCost * replicas * 24.0;
            monthly = podCost * replicas * 24.0 * 30.0;
            annual = podCost * replicas * 24.0 * 365.0;
          };
      
      depNames = builtins.attrNames deployments;
      depCosts = builtins.map calculateDeploymentCost depNames;
      
      totalHourly = builtins.foldl' (acc: cost: acc + cost.hourly) 0.0 depCosts;
    in
      {
        total = {
          hourly = totalHourly;
          daily = totalHourly * 24.0;
          monthly = totalHourly * 24.0 * 30.0;
          annual = totalHourly * 24.0 * 365.0;
        };
        byDeployment = depCosts;
        provider = provider;
        currency = "USD";
      };

  # Cloud provider pricing presets
  providers = {
    aws = awsPricing;
    azure = azurePricing;
    gcp = gcpPricing;
  };

  # CPU and memory size presets for quick estimation
  sizePresets = {
    small = { cpu = "250m"; memory = "256Mi"; };
    medium = { cpu = "500m"; memory = "512Mi"; };
    large = { cpu = "1"; memory = "1Gi"; };
    xlarge = { cpu = "2"; memory = "2Gi"; };
    xxlarge = { cpu = "4"; memory = "4Gi"; };
  };

  # Format currency for display
  formatCurrency = amount:
    let
      cents = builtins.floor ((amount * 100.0) + 0.5);
      dollars = cents / 100.0;
      dollarStr = builtins.toString dollars;
    in
      "$${dollarStr}";
}
