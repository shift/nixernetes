# Example: Unified Framework API
#
# This example demonstrates comprehensive usage of the Nixernetes Unified API
# for building production-grade Kubernetes applications with minimal boilerplate.
#
# The Unified API provides:
# - Simple application builders with sensible defaults
# - Multi-tier application templates
# - Integrated security, compliance, and observability
# - One-liner deployments for common patterns

{ lib, ... }:

let
  nixernetes = import ../flake.nix;
  api = import ../src/lib/unified-api.nix { inherit lib; };

in
{
  # ============================================================================
  # Example 1: Simple Web Application
  # ============================================================================
  
  simple_web_app = api.mkApplication "simple-web" {
    namespace = "default";
    image = "nginx:1.24-alpine";
    replicas = 2;
    port = 80;
    
    labels = {
      app = "simple-web";
      version = "v1";
    };
  };

  # ============================================================================
  # Example 2: Backend API Service with Full Configuration
  # ============================================================================
  
  backend_api = api.mkApplication "api-server" {
    namespace = "production";
    image = "myregistry.azurecr.io/api-server:1.2.3";
    replicas = 3;
    port = 3000;
    
    # Resource management
    requestsCpu = "500m";
    requestsMemory = "512Mi";
    limitsCpu = "1000m";
    limitsMemory = "1Gi";
    
    # Environment variables
    env = {
      NODE_ENV = "production";
      LOG_LEVEL = "info";
      DATABASE_POOL_SIZE = "20";
      CACHE_TTL = "3600";
    };
    
    # Labels and annotations
    labels = {
      app = "api-server";
      version = "v1.2.3";
      tier = "backend";
    };
    annotations = {
      "prometheus.io/scrape" = "true";
      "prometheus.io/port" = "3000";
      "prometheus.io/path" = "/metrics";
    };
    
    # Security context
    securityContext = {
      runAsNonRoot = true;
      runAsUser = 1000;
      readOnlyRootFilesystem = true;
      allowPrivilegeEscalation = false;
      capabilities = { drop = ["ALL"]; };
    };
    
    # Health probes
    livenessProbe = {
      httpGet = {
        path = "/api/health/live";
        port = 3000;
      };
      initialDelaySeconds = 30;
      periodSeconds = 10;
      timeoutSeconds = 5;
      failureThreshold = 3;
    };
    
    readinessProbe = {
      httpGet = {
        path = "/api/health/ready";
        port = 3000;
      };
      initialDelaySeconds = 5;
      periodSeconds = 5;
      timeoutSeconds = 3;
      failureThreshold = 2;
    };
    
    terminationGracePeriodSeconds = 30;
    imagePullPolicy = "IfNotPresent";
  };

  # ============================================================================
  # Example 3: Database Service
  # ============================================================================
  
  postgres_database = api.mkApplication "postgres" {
    namespace = "production";
    image = "postgres:15-alpine";
    replicas = 1;
    port = 5432;
    
    # High resource limits for database
    requestsCpu = "2000m";
    requestsMemory = "4Gi";
    limitsCpu = "4000m";
    limitsMemory = "8Gi";
    
    env = {
      POSTGRES_DB = "production_db";
      POSTGRES_PASSWORD = "postgres";
    };
    
    labels = {
      app = "postgres";
      tier = "database";
      criticality = "critical";
    };
    
    securityContext = {
      runAsNonRoot = true;
      runAsUser = 999;
      readOnlyRootFilesystem = false;
      allowPrivilegeEscalation = false;
    };
  };

  # ============================================================================
  # Example 4: Multi-Tier E-Commerce Platform
  # ============================================================================
  
  ecommerce_platform = api.mkMultiTierApp "ecommerce" {
    namespace = "production";
    appName = "ecommerce-platform";
    kubernetesVersion = "1.30";
    
    # Global compliance and observability
    compliance = {
      framework = "PCI-DSS";
      level = "3.2.1";
      owner = "security-team";
      dataClassification = "confidential";
    };
    
    observability = {
      enabled = true;
      logging = true;
      metrics = true;
      tracing = true;
      logLevel = "info";
    };
    
    # Frontend: React web UI
    frontend = {
      image = "ecommerce/frontend:1.0.0";
      replicas = 3;
      port = 80;
      requestsCpu = "100m";
      requestsMemory = "128Mi";
      limitsCpu = "500m";
      limitsMemory = "512Mi";
      labels = { component = "ui"; };
    };
    
    # Backend: Node.js API
    backend = {
      image = "ecommerce/api:1.2.3";
      replicas = 5;
      port = 3000;
      requestsCpu = "500m";
      requestsMemory = "512Mi";
      limitsCpu = "1000m";
      limitsMemory = "1Gi";
      labels = { component = "api"; };
    };
    
    # Database: PostgreSQL
    database = {
      image = "postgres:15-alpine";
      replicas = 1;
      port = 5432;
      limitsCpu = "2000m";
      limitsMemory = "4Gi";
      labels = { component = "database"; };
    };
    
    # Cache: Redis
    cache = {
      image = "redis:7-alpine";
      replicas = 2;
      port = 6379;
      requestsCpu = "200m";
      requestsMemory = "256Mi";
      limitsCpu = "1000m";
      limitsMemory = "1Gi";
      labels = { component = "cache"; };
    };
    
    # Queue: RabbitMQ
    queue = {
      image = "rabbitmq:3.12-management-alpine";
      replicas = 2;
      port = 5672;
      requestsCpu = "500m";
      requestsMemory = "512Mi";
      limitsCpu = "1000m";
      limitsMemory = "1Gi";
      labels = { component = "queue"; };
    };
    
    # Monitoring: Prometheus
    monitoring = {
      image = "prom/prometheus:v2.47.0";
      replicas = 1;
      port = 9090;
      requestsCpu = "500m";
      requestsMemory = "1Gi";
      limitsCpu = "2000m";
      limitsMemory = "2Gi";
      labels = { component = "monitoring"; };
    };
  };

  # ============================================================================
  # Example 5: Secure Production Cluster
  # ============================================================================
  
  secure_production_cluster = api.mkCluster "prod-us-east-1" {
    kubernetesVersion = "1.30";
    region = "us-east-1";
    provider = "aws";
    namespace = "production";
    
    # Strict compliance
    compliance = {
      framework = "SOC2";
      level = "type-2";
      owner = "compliance-team";
    };
    
    # Full observability
    observability = {
      enabled = true;
      logging = true;
      metrics = true;
      tracing = true;
      logLevel = "info";
    };
    
    # Zero-trust networking
    networking = {
      policyMode = "deny-all";
      defaultDenyIngress = true;
      defaultDenyEgress = false;
    };
    
    # Resource quotas
    resourceQuota = {
      enabled = true;
      cpu = "500";
      memory = "1000Gi";
      pods = 5000;
    };
    
    # Auto-scaling
    autoscaling = {
      enabled = true;
      minReplicas = 3;
      maxReplicas = 50;
      targetCpuUtilization = 70;
    };
  };

  # ============================================================================
  # Example 6: Security Policy Configuration
  # ============================================================================
  
  strict_security_policy = api.mkSecurityPolicy "production-strict" {
    namespace = "production";
    level = "strict";
    
    podSecurity = {
      enforce = "restricted";
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
      externalSecrets = true;
      vaultIntegration = true;
      encryptionAtRest = true;
    };
    
    admissionControl = {
      policyEngine = "kyverno";
      mutatingWebhooks = [];
      validatingWebhooks = [];
    };
  };

  # ============================================================================
  # Example 7: Compliance Framework Configuration
  # ============================================================================
  
  hipaa_compliance = api.mkCompliance "HIPAA" {
    auditLog = true;
    encryption = true;
    accessControl = true;
  };

  pci_dss_compliance = api.mkCompliance "PCI-DSS" {
    auditLog = true;
    encryption = true;
    accessControl = true;
  };

  gdpr_compliance = api.mkCompliance "GDPR" {
    auditLog = true;
    encryption = true;
    accessControl = true;
  };

  # ============================================================================
  # Example 8: Observability Stack
  # ============================================================================
  
  monitoring_stack = api.mkObservability "monitoring" {
    namespace = "monitoring";
    
    logging = {
      enabled = true;
      backend = "loki";
      logLevel = "info";
      retention = 30;
    };
    
    metrics = {
      enabled = true;
      backend = "prometheus";
      scrapeInterval = "30s";
      retention = 30;
    };
    
    tracing = {
      enabled = true;
      backend = "jaeger";
      samplingRate = 0.1;
    };
    
    alerting = {
      enabled = true;
      backend = "alertmanager";
      rules = [];
    };
  };

  # ============================================================================
  # Example 9: Cost Tracking Configuration
  # ============================================================================
  
  aws_cost_tracking = api.mkCostTracking "aws-cost-analysis" {
    provider = "aws";
    
    resourceTracking = {
      enabled = true;
      granularity = "namespace";
    };
    
    costAnalysis = {
      enabled = true;
      reportingFrequency = "daily";
      budgetAlerts = true;
    };
    
    optimization = {
      enabled = true;
      rightSizing = true;
      spotInstances = true;
    };
  };

  # ============================================================================
  # Example 10: Performance Tracking Configuration
  # ============================================================================
  
  performance_tracking = api.mkPerformanceTracking "performance-analysis" {
    profiling = {
      enabled = true;
      cpuProfiling = true;
      memoryProfiling = true;
      diskProfiling = true;
    };
    
    benchmarking = {
      enabled = true;
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
  };

  # ============================================================================
  # Example 11: Environment Configuration
  # ============================================================================
  
  production_environment = api.mkEnvironment "prod-env" {
    type = "production";
    
    settings = {
      kubernetesVersion = "1.30";
      cloudProvider = "aws";
      region = "us-east-1";
      networkCIDR = "10.0.0.0/8";
    };
    
    capabilities = {
      multiCluster = true;
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
  };

  staging_environment = api.mkEnvironment "staging-env" {
    type = "staging";
    
    settings = {
      kubernetesVersion = "1.30";
      cloudProvider = "aws";
      region = "eu-west-1";
      networkCIDR = "10.1.0.0/8";
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
      costOptimization = false;
      observability = true;
    };
  };

  # ============================================================================
  # Example 12: Microservices Architecture
  # ============================================================================
  
  microservices = {
    auth_service = api.mkApplication "auth-service" {
      namespace = "production";
      image = "myregistry.azurecr.io/auth:1.0";
      replicas = 3;
      port = 8080;
      requestsCpu = "200m";
      requestsMemory = "256Mi";
      limitsCpu = "500m";
      limitsMemory = "512Mi";
    };
    
    user_service = api.mkApplication "user-service" {
      namespace = "production";
      image = "myregistry.azurecr.io/user:1.0";
      replicas = 3;
      port = 8081;
      requestsCpu = "200m";
      requestsMemory = "256Mi";
      limitsCpu = "500m";
      limitsMemory = "512Mi";
    };
    
    order_service = api.mkApplication "order-service" {
      namespace = "production";
      image = "myregistry.azurecr.io/order:1.0";
      replicas = 5;
      port = 8082;
      requestsCpu = "500m";
      requestsMemory = "512Mi";
      limitsCpu = "1000m";
      limitsMemory = "1Gi";
    };
    
    product_service = api.mkApplication "product-service" {
      namespace = "production";
      image = "myregistry.azurecr.io/product:1.0";
      replicas = 3;
      port = 8083;
      requestsCpu = "200m";
      requestsMemory = "256Mi";
      limitsCpu = "500m";
      limitsMemory = "512Mi";
    };
    
    payment_service = api.mkApplication "payment-service" {
      namespace = "production";
      image = "myregistry.azurecr.io/payment:1.0";
      replicas = 2;
      port = 8084;
      requestsCpu = "500m";
      requestsMemory = "512Mi";
      limitsCpu = "1000m";
      limitsMemory = "1Gi";
      labels = { criticality = "critical"; };
    };
  };

  # ============================================================================
  # Example 13: Validation Examples
  # ============================================================================
  
  validation_examples = {
    # Valid application
    valid_app = api.validateApplication backend_api;
    
    # Invalid application (missing image)
    invalid_app = api.validateApplication {
      name = "test";
      image = "";  # Empty image
      replicas = 1;
    };
    
    # Cluster validation
    cluster_validation = api.validateCluster secure_production_cluster;
  };

  # ============================================================================
  # Example 14: Combining Multiple Applications
  # ============================================================================
  
  combined_services = api.combineApplications [
    backend_api
    postgres_database
  ];

  # ============================================================================
  # Summary and Framework Information
  # ============================================================================
  
  framework_info = {
    name = api.framework.name;
    version = api.framework.version;
    author = api.framework.author;
    supportedVersions = api.framework.supportedKubernetesVersions;
    supportedProviders = api.framework.supportedProviders;
    availableFeatures = api.framework.features;
  };

  # ============================================================================
  # Complete Production Deployment
  # ============================================================================
  
  complete_production_setup = {
    # Infrastructure
    cluster = secure_production_cluster;
    environment = production_environment;
    
    # Applications
    applications = {
      ecommerce = ecommerce_platform;
      services = microservices;
    };
    
    # Security and Compliance
    security = {
      policies = [strict_security_policy];
      compliance = [hipaa_compliance pci_dss_compliance];
    };
    
    # Observability
    monitoring = monitoring_stack;
    
    # Cost and Performance
    costTracking = aws_cost_tracking;
    performanceTracking = performance_tracking;
    
    # Metadata
    metadata = framework_info;
  };
}
