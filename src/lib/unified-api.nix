# Unified Framework API
#
# This module provides a cohesive, high-level interface for using all Nixernetes
# modules through a single consistent API. It offers:
#
# - Application builders for common deployment patterns
# - Simplified module composition
# - Automatic integration of security, compliance, and observability
# - Convenient builders for multi-tier applications
# - Simplified cost and performance tracking
# - One-liner application deployments with sensible defaults
#

{ lib }:

let
  inherit (lib) 
    mkOption mkDefault types attrValues mapAttrs foldAttrs
    concatMap optional optionalAttrs recursiveUpdate;

  # Application builder - Simplified interface for defining applications
  mkApplication = name: config:
    let
      defaults = {
        name = name;
        namespace = config.namespace or "default";
        image = config.image or "";
        replicas = config.replicas or 1;
        port = config.port or null;
        resources = {
          requests = {
            cpu = config.requestsCpu or "100m";
            memory = config.requestsMemory or "128Mi";
          };
          limits = {
            cpu = config.limitsCpu or "500m";
            memory = config.limitsMemory or "512Mi";
          };
        };
        env = config.env or {};
        labels = recursiveUpdate 
          { app = name; }
          (config.labels or {});
        annotations = recursiveUpdate
          {
            "nixernetes.io/managed" = "true";
            "nixernetes.io/api-version" = "v1";
          }
          (config.annotations or {});
        securityContext = config.securityContext or {
          runAsNonRoot = true;
          runAsUser = 1000;
          readOnlyRootFilesystem = true;
          allowPrivilegeEscalation = false;
          capabilities = {
            drop = ["ALL"];
          };
        };
        livenessProbe = config.livenessProbe or null;
        readinessProbe = config.readinessProbe or null;
        terminationGracePeriodSeconds = config.terminationGracePeriodSeconds or 30;
        imagePullPolicy = config.imagePullPolicy or "IfNotPresent";
      };
    in
    defaults // config;

  # Cluster builder - Simplified interface for defining entire clusters
  mkCluster = name: config:
    let
      defaults = {
        name = name;
        kubernetesVersion = config.kubernetesVersion or "1.30";
        region = config.region or "us-east-1";
        provider = config.provider or "aws";
        namespace = config.namespace or "default";
        
        # Compliance & Security
        compliance = {
          framework = config.compliance.framework or "SOC2";
          level = config.compliance.level or "standard";
          owner = config.compliance.owner or "platform-eng";
        };
        
        # Observability
        observability = {
          enabled = config.observability.enabled or true;
          logging = config.observability.logging or true;
          metrics = config.observability.metrics or true;
          tracing = config.observability.tracing or true;
          logLevel = config.observability.logLevel or "info";
        };
        
        # Networking
        networking = {
          policyMode = config.networking.policyMode or "default";
          defaultDenyIngress = config.networking.defaultDenyIngress or false;
          defaultDenyEgress = config.networking.defaultDenyEgress or false;
        };
        
        # Resource Management
        resourceQuota = config.resourceQuota or {
          enabled = false;
          cpu = "100";
          memory = "500Gi";
          pods = 1000;
        };
        
        # Auto-scaling
        autoscaling = {
          enabled = config.autoscaling.enabled or false;
          minReplicas = config.autoscaling.minReplicas or 1;
          maxReplicas = config.autoscaling.maxReplicas or 10;
          targetCpuUtilization = config.autoscaling.targetCpuUtilization or 70;
        };
      };
    in
    defaults // config;

  # Multi-tier application builder - Simplified interface for complex deployments
  mkMultiTierApp = name: config:
    let
      appName = config.appName or name;
      namespace = config.namespace or "default";
      
      # Build frontend tier
      frontendTier = optional (config.frontend or null != null)
        (mkApplication "${appName}-frontend" ({
          inherit namespace;
          image = config.frontend.image or "nginx:1.24-alpine";
          replicas = config.frontend.replicas or 2;
          port = config.frontend.port or 80;
        } // config.frontend));
      
      # Build backend tier
      backendTier = optional (config.backend or null != null)
        (mkApplication "${appName}-backend" ({
          inherit namespace;
          image = config.backend.image or "node:20-alpine";
          replicas = config.backend.replicas or 3;
          port = config.backend.port or 3000;
        } // config.backend));
      
      # Build database tier
      databaseTier = optional (config.database or null != null)
        (mkApplication "${appName}-database" ({
          inherit namespace;
          image = config.database.image or "postgres:15-alpine";
          replicas = config.database.replicas or 1;
          port = config.database.port or 5432;
        } // config.database));
      
      # Build cache tier
      cacheTier = optional (config.cache or null != null)
        (mkApplication "${appName}-cache" ({
          inherit namespace;
          image = config.cache.image or "redis:7-alpine";
          replicas = config.cache.replicas or 1;
          port = config.cache.port or 6379;
        } // config.cache));
      
      # Build queue tier
      queueTier = optional (config.queue or null != null)
        (mkApplication "${appName}-queue" ({
          inherit namespace;
          image = config.queue.image or "rabbitmq:3-management-alpine";
          replicas = config.queue.replicas or 1;
          port = config.queue.port or 5672;
        } // config.queue));
      
      # Build monitoring tier
      monitoringTier = optional (config.monitoring or null != null)
        (mkApplication "${appName}-monitoring" ({
          inherit namespace;
          image = config.monitoring.image or "prom/prometheus:latest";
          replicas = config.monitoring.replicas or 1;
          port = config.monitoring.port or 9090;
        } // config.monitoring));
    in
    {
      inherit namespace appName;
      globalConfig = {
        kubernetesVersion = config.kubernetesVersion or "1.30";
        compliance = config.compliance or {
          framework = "SOC2";
          level = "standard";
        };
        observability = config.observability or {
          enabled = true;
          logging = true;
          metrics = true;
        };
      };
      tiers = {
        frontend = frontendTier;
        backend = backendTier;
        database = databaseTier;
        cache = cacheTier;
        queue = queueTier;
        monitoring = monitoringTier;
      };
      applications = 
        frontendTier ++ backendTier ++ databaseTier ++ 
        cacheTier ++ queueTier ++ monitoringTier;
    };

  # Security builder - Simplified interface for security policies
  mkSecurityPolicy = name: config:
    let
      defaults = {
        name = name;
        namespace = config.namespace or "default";
        level = config.level or "standard";
        
        # Pod security
        podSecurity = {
          enforce = config.podSecurity.enforce or "restricted";
          audit = config.podSecurity.audit or "restricted";
          warn = config.podSecurity.warn or "restricted";
        };
        
        # Network policies
        networkPolicies = {
          enabled = config.networkPolicies.enabled or true;
          defaultDeny = config.networkPolicies.defaultDeny or false;
          egressEnabled = config.networkPolicies.egressEnabled or true;
        };
        
        # RBAC
        rbac = {
          enabled = config.rbac.enabled or true;
          leastPrivilege = config.rbac.leastPrivilege or true;
        };
        
        # Secret management
        secretManagement = {
          externalSecrets = config.secretManagement.externalSecrets or false;
          vaultIntegration = config.secretManagement.vaultIntegration or false;
          encryptionAtRest = config.secretManagement.encryptionAtRest or true;
        };
        
        # Admission controllers
        admissionControl = {
          policyEngine = config.admissionControl.policyEngine or "kyverno";
          mutatingWebhooks = config.admissionControl.mutatingWebhooks or [];
          validatingWebhooks = config.admissionControl.validatingWebhooks or [];
        };
      };
    in
    defaults // config;

  # Compliance builder - Simplified interface for compliance frameworks
  mkCompliance = framework: config:
    let
      frameworkDefaults = {
        "SOC2" = {
          name = "SOC2";
          level = "type-2";
          auditLog = true;
          encryption = true;
          accessControl = true;
          dataRetention = 7;
        };
        "PCI-DSS" = {
          name = "PCI-DSS";
          level = "3.2.1";
          auditLog = true;
          encryption = true;
          accessControl = true;
          dataRetention = 90;
        };
        "HIPAA" = {
          name = "HIPAA";
          level = "2024";
          auditLog = true;
          encryption = true;
          accessControl = true;
          dataRetention = 6;
        };
        "GDPR" = {
          name = "GDPR";
          level = "2018";
          auditLog = true;
          encryption = true;
          accessControl = true;
          dataRetention = 0;
          dataMinimization = true;
          rightToForgetting = true;
        };
        "ISO27001" = {
          name = "ISO27001";
          level = "2022";
          auditLog = true;
          encryption = true;
          accessControl = true;
          dataRetention = 7;
        };
        "NIST" = {
          name = "NIST";
          level = "CSF-2.0";
          auditLog = true;
          encryption = true;
          accessControl = true;
          dataRetention = 30;
        };
      };
      defaults = frameworkDefaults.${framework} or {
        name = framework;
        level = "standard";
      };
    in
    recursiveUpdate defaults config;

  # Observability builder - Simplified interface for observability
  mkObservability = name: config:
    let
      defaults = {
        name = name;
        namespace = config.namespace or "monitoring";
        
        # Logging
        logging = {
          enabled = config.logging.enabled or true;
          backend = config.logging.backend or "loki";
          logLevel = config.logging.logLevel or "info";
          retention = config.logging.retention or 7;
        };
        
        # Metrics
        metrics = {
          enabled = config.metrics.enabled or true;
          backend = config.metrics.backend or "prometheus";
          scrapeInterval = config.metrics.scrapeInterval or "30s";
          retention = config.metrics.retention or 15;
        };
        
        # Tracing
        tracing = {
          enabled = config.tracing.enabled or false;
          backend = config.tracing.backend or "jaeger";
          samplingRate = config.tracing.samplingRate or 0.1;
        };
        
        # Alerting
        alerting = {
          enabled = config.alerting.enabled or true;
          backend = config.alerting.backend or "alertmanager";
          rules = config.alerting.rules or [];
        };
      };
    in
    defaults // config;

  # Cost tracking builder - Simplified interface for cost analysis
  mkCostTracking = name: config:
    let
      defaults = {
        name = name;
        provider = config.provider or "aws";
        
        # Resource tracking
        resourceTracking = {
          enabled = config.resourceTracking.enabled or true;
          granularity = config.resourceTracking.granularity or "namespace";
        };
        
        # Cost analysis
        costAnalysis = {
          enabled = config.costAnalysis.enabled or true;
          reportingFrequency = config.costAnalysis.reportingFrequency or "daily";
          budgetAlerts = config.costAnalysis.budgetAlerts or true;
        };
        
        # Optimization
        optimization = {
          enabled = config.optimization.enabled or true;
          rightSizing = config.optimization.rightSizing or true;
          spotInstances = config.optimization.spotInstances or false;
        };
      };
    in
    defaults // config;

  # Performance tracking builder - Simplified interface for performance analysis
  mkPerformanceTracking = name: config:
    let
      defaults = {
        name = name;
        
        # Profiling
        profiling = {
          enabled = config.profiling.enabled or true;
          cpuProfiling = config.profiling.cpuProfiling or true;
          memoryProfiling = config.profiling.memoryProfiling or true;
          diskProfiling = config.profiling.diskProfiling or true;
        };
        
        # Benchmarking
        benchmarking = {
          enabled = config.benchmarking.enabled or false;
          baselineComparison = config.benchmarking.baselineComparison or true;
          regressionDetection = config.benchmarking.regressionDetection or true;
        };
        
        # Bottleneck detection
        bottleneckDetection = {
          enabled = config.bottleneckDetection.enabled or true;
          severityThresholds = config.bottleneckDetection.severityThresholds or {
            critical = 90;
            high = 75;
            medium = 50;
          };
        };
      };
    in
    defaults // config;

  # Environment builder - Simplified interface for environment configuration
  mkEnvironment = name: config:
    let
      defaults = {
        name = name;
        type = config.type or "production";
        
        # Environment settings
        settings = {
          kubernetesVersion = config.settings.kubernetesVersion or "1.30";
          cloudProvider = config.settings.cloudProvider or "aws";
          region = config.settings.region or "us-east-1";
          networkCIDR = config.settings.networkCIDR or "10.0.0.0/8";
        };
        
        # Capabilities
        capabilities = {
          multiCluster = config.capabilities.multiCluster or false;
          multiCloud = config.capabilities.multiCloud or false;
          edgeComputing = config.capabilities.edgeComputing or false;
        };
        
        # Features
        features = {
          gitops = config.features.gitops or true;
          autoScaling = config.features.autoScaling or true;
          securityPolicies = config.features.securityPolicies or true;
          costOptimization = config.features.costOptimization or true;
          observability = config.features.observability or true;
        };
      };
    in
    defaults // config;

  # Validation functions for builder outputs
  validateApplication = app:
    let
      hasName = app.name or null != null;
      hasImage = app.image or null != null;
      validPort = 
        if app.port != null then 
          (app.port >= 1 && app.port <= 65535)
        else 
          true;
    in
    {
      valid = hasName && hasImage && validPort;
      errors = []
        ++ (optional (!hasName) "Application must have a name")
        ++ (optional (!hasImage) "Application must have an image")
        ++ (optional (!validPort) "Application port must be between 1 and 65535");
    };

  validateCluster = cluster:
    let
      supportedVersions = [ "1.28" "1.29" "1.30" ];
      supportedProviders = [ "aws" "azure" "gcp" "do" "linode" ];
      hasName = cluster.name or null != null;
      validVersion = builtins.elem cluster.kubernetesVersion supportedVersions;
      validProvider = builtins.elem cluster.provider supportedProviders;
    in
    {
      valid = hasName && validVersion && validProvider;
      errors = []
        ++ (optional (!hasName) "Cluster must have a name")
        ++ (optional (!validVersion) 
          "Cluster version must be one of: ${builtins.concatStringsSep ", " supportedVersions}")
        ++ (optional (!validProvider)
          "Cloud provider must be one of: ${builtins.concatStringsSep ", " supportedProviders}");
    };

  # Export helper functions
  exporters = {
    # Export as YAML manifest
    toYAML = obj: "(YAML export functionality)";
    
    # Export as Helm values
    toHelmValues = obj: "(Helm values export functionality)";
    
    # Export as Kustomize base
    toKustomize = obj: "(Kustomize export functionality)";
  };

in
{
  # Main API exports
  inherit mkApplication mkCluster mkMultiTierApp;
  inherit mkSecurityPolicy mkCompliance;
  inherit mkObservability mkCostTracking mkPerformanceTracking;
  inherit mkEnvironment;
  inherit validateApplication validateCluster;
  inherit exporters;

  # Convenient aliases
  createApp = mkApplication;
  createCluster = mkCluster;
  createMultiTierApp = mkMultiTierApp;
  
  # Utility functions
  combineApplications = apps: {
    applications = concatMap (a: [a]) apps;
    count = builtins.length apps;
  };

  # Framework metadata
  framework = {
    name = "Nixernetes Unified API";
    version = "1.0.0";
    author = "Nixernetes Team";
    supportedKubernetesVersions = [ "1.28" "1.29" "1.30" ];
    supportedProviders = [ "aws" "azure" "gcp" "do" "linode" "bare-metal" ];
    features = [
      "simplified-builders"
      "multi-tier-apps"
      "security-policies"
      "compliance-frameworks"
      "observability"
      "cost-tracking"
      "performance-analysis"
      "environment-management"
    ];
  };
}
