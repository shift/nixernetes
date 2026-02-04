# Nixernetes Multi-Tenancy Module Examples
#
# Comprehensive examples demonstrating multi-tenancy configurations
# for different use cases and requirements.

{ lib }:

let
  multiTenancy = import ./multi-tenancy.nix { inherit lib; };
in

{
  # Example 1: Single Tenant Development Environment
  exampleSingleTenantDev = multiTenancy.mkTenant "dev" {
    namespace = "dev";
    displayName = "Development Tenant";
    description = "Development environment for small team";
    
    cpuQuota = "20";
    memoryQuota = "50Gi";
    storageQuota = "100Gi";
    podQuota = 100;
    
    isolationLevel = "permissive";
    networkIsolation = false;
    ingressEnabled = true;
    
    owner = "dev-lead@company.com";
    admins = ["dev-lead@company.com"];
    
    billingContact = "dev-lead@company.com";
    costCenter = "DEV-001";
    
    labels = {
      "environment" = "development";
      "team" = "engineering";
      "tier" = "non-production";
    };
  };

  # Example 2: Multi-Tenant Cluster with Standard Isolation
  exampleMultiTenantStandard = {
    acme = multiTenancy.mkTenant "acme" {
      namespace = "acme-prod";
      displayName = "ACME Corporation";
      cpuQuota = "200";
      memoryQuota = "512Gi";
      storageQuota = "2Ti";
      podQuota = 1000;
      isolationLevel = "standard";
      networkIsolation = true;
      ingressEnabled = true;
      owner = "platform@acme.com";
      admins = ["admin1@acme.com" "admin2@acme.com"];
      billingContact = "billing@acme.com";
      costCenter = "ACME-001";
    };
    
    widgets = multiTenancy.mkTenant "widgets" {
      namespace = "widgets-prod";
      displayName = "Widgets Inc";
      cpuQuota = "150";
      memoryQuota = "384Gi";
      storageQuota = "1Ti";
      podQuota = 750;
      isolationLevel = "standard";
      networkIsolation = true;
      ingressEnabled = true;
      owner = "ops@widgets.com";
      admins = ["admin@widgets.com"];
      billingContact = "accounting@widgets.com";
      costCenter = "WIDGETS-001";
    };
    
    startup = multiTenancy.mkTenant "startup" {
      namespace = "startup-prod";
      displayName = "Early Stage Startup";
      cpuQuota = "50";
      memoryQuota = "128Gi";
      storageQuota = "500Gi";
      podQuota = 250;
      isolationLevel = "standard";
      networkIsolation = true;
      ingressEnabled = true;
      owner = "cto@startup.com";
      admins = ["cto@startup.com"];
      billingContact = "finance@startup.com";
      costCenter = "STARTUP-001";
    };
  };

  # Example 3: Enterprise with Strict Isolation
  exampleEnterpriseStrictIsolation = multiTenancy.mkTenant "enterprise-secure" {
    namespace = "enterprise-secure";
    displayName = "Enterprise Secure Tenant";
    description = "High-security tenant for sensitive workloads";
    
    cpuQuota = "300";
    memoryQuota = "1Ti";
    storageQuota = "5Ti";
    cpuLimit = "200";
    memoryLimit = "512Gi";
    
    isolationLevel = "strict";
    networkIsolation = true;
    ingressEnabled = true;
    egressEnabled = false;
    
    restrictedCapabilities = ["NET_ADMIN" "SYS_ADMIN" "NET_RAW"];
    allowPrivilegedContainers = false;
    
    owner = "security@enterprise.com";
    admins = ["security@enterprise.com" "sre@enterprise.com"];
    
    billingContact = "finance@enterprise.com";
    costCenter = "ENTERPRISE-SEC-001";
    billingCycle = "monthly";
    
    labels = {
      "environment" = "production";
      "security-level" = "high";
      "compliance" = "sox";
    };
  };

  # Example 4: Tenant with Resource Limits and Network Policies
  exampleTenantWithNetworkPolicies = {
    tenant = multiTenancy.mkTenant "restricted" {
      namespace = "restricted";
      displayName = "Restricted Tenant";
      cpuQuota = "100";
      memoryQuota = "256Gi";
      storageQuota = "500Gi";
      isolationLevel = "standard";
      networkIsolation = true;
      ingressEnabled = false;
    };
    
    networkPolicy = multiTenancy.mkTenantNetworkPolicy "restricted" {
      namespace = "restricted";
      ingressEnabled = false;
      allowFromSameTenant = true;
      allowFromNamespaces = ["ingress-nginx"];
      
      egressEnabled = true;
      allowToSameTenant = true;
      allowToDns = true;
      allowToExternal = false;
      allowedPorts = [80 443];
    };
    
    resourceLimits = multiTenancy.mkTenantResourceLimits "restricted" {
      namespace = "restricted";
      podCpuLimit = "8";
      podMemoryLimit = "16Gi";
      podCpuRequest = "100m";
      podMemoryRequest = "128Mi";
      qosClass = "Burstable";
      allowBursting = true;
      minReplicas = 2;
    };
  };

  # Example 5: Tenant with RBAC Configuration
  exampleTenantWithRBAC = {
    tenant = multiTenancy.mkTenant "rbac-demo" {
      namespace = "rbac-demo";
      displayName = "RBAC Demo Tenant";
      cpuQuota = "80";
      memoryQuota = "200Gi";
      isolationLevel = "standard";
    };
    
    rbac = multiTenancy.mkTenantRBAC "rbac-demo" {
      namespace = "rbac-demo";
      
      roles = {
        admin = {
          verbs = ["*"];
          resources = ["*"];
          apiGroups = ["*"];
        };
        developer = {
          verbs = ["get" "list" "watch" "create" "update" "patch"];
          resources = ["deployments" "services" "configmaps" "secrets" "pods"];
          apiGroups = ["apps" "v1" ""];
        };
        operator = {
          verbs = ["get" "list" "watch" "create" "update"];
          resources = ["deployments" "statefulsets" "daemonsets"];
          apiGroups = ["apps"];
        };
        viewer = {
          verbs = ["get" "list" "watch"];
          resources = ["pods" "services" "deployments"];
          apiGroups = ["apps" "v1" ""];
        };
      };
      
      admins = ["admin@company.com"];
      developers = ["dev1@company.com" "dev2@company.com" "dev3@company.com"];
      operator = ["ops1@company.com" "ops2@company.com"];
      viewers = ["stakeholder@company.com"];
      serviceAccounts = ["ci-cd-bot" "monitoring-agent"];
    };
  };

  # Example 6: Tenant with Billing and Cost Tracking
  exampleTenantWithBilling = {
    tenant = multiTenancy.mkTenant "billing-demo" {
      namespace = "billing-demo";
      displayName = "Billing Demo Tenant";
      cpuQuota = "120";
      memoryQuota = "300Gi";
      storageQuota = "1Ti";
      isolationLevel = "standard";
      billingContact = "accounting@customer.com";
      costCenter = "CUSTOMER-123";
    };
    
    billing = multiTenancy.mkTenantBilling "billing-demo" {
      tenantId = "customer-123";
      tenantName = "Customer ABC";
      billingContact = "accounting@customer.com";
      billingEmail = "billing@customer.com";
      costCenter = "CUSTOMER-123";
      department = "Engineering";
      billingCycle = "monthly";
      
      cpuHourlyRate = 0.05;
      memoryHourlyRate = 0.01;
      storageMonthlyRate = 0.10;
      networkEgressRate = 0.02;
      
      monthlyBudget = 5000;
      budgetAlertThreshold = 0.80;
      budgetEnforcement = true;
      
      chargebackModel = "usage";
      volumeDiscount = 0.10;
      commitmentDiscount = 0.15;
    };
  };

  # Example 7: Tenant with Monitoring and Compliance
  exampleTenantWithMonitoring = {
    tenant = multiTenancy.mkTenant "monitoring-demo" {
      namespace = "monitoring-demo";
      displayName = "Monitoring Demo Tenant";
      cpuQuota = "100";
      memoryQuota = "250Gi";
      isolationLevel = "standard";
    };
    
    monitoring = multiTenancy.mkTenantMonitoring "monitoring-demo" {
      namespace = "monitoring-demo";
      
      metricsEnabled = true;
      metricsRetention = "30d";
      
      loggingEnabled = true;
      logLevel = "Info";
      logRetention = "7d";
      logFormat = "json";
      
      alertingEnabled = true;
      alertReceivers = ["alerts@company.com" "oncall@company.com"];
      
      sloEnabled = true;
      targetAvailability = 0.99;
      targetLatency = "100ms";
      
      dashboardsEnabled = true;
      customDashboards = [
        "resource-usage"
        "performance-metrics"
        "error-rates"
        "cost-analysis"
      ];
    };
    
    isolationPolicy = multiTenancy.mkTenantIsolationPolicy "monitoring-demo" {
      namespace = "monitoring-demo";
      isolationLevel = "standard";
      apiAudit = true;
      auditLevel = "Metadata";
      allowedRegistries = ["gcr.io" "docker.io" "quay.io"];
      imageVerification = false;
    };
  };

  # Example 8: Tenant with Backup and Disaster Recovery
  exampleTenantWithBackup = {
    tenant = multiTenancy.mkTenant "backup-demo" {
      namespace = "backup-demo";
      displayName = "Backup Demo Tenant";
      cpuQuota = "80";
      memoryQuota = "200Gi";
      storageQuota = "500Gi";
      isolationLevel = "standard";
    };
    
    backup = multiTenancy.mkTenantBackup "backup-demo" {
      namespace = "backup-demo";
      
      backupEnabled = true;
      backupSchedule = "0 2 * * *";
      backupRetention = 30;
      
      backupNamespace = true;
      backupPersistentVolumes = true;
      backupSecrets = true;
      backupIncludeResources = ["Deployment" "StatefulSet" "ConfigMap" "Secret"];
      backupExcludeResources = ["Event" "Pod"];
      
      backupStorageLocation = "us-east-1-s3";
      encryptionEnabled = true;
      
      restoreEnabled = true;
      restoreSchedule = "0 3 * * 0";
      allowCrossTenantRestore = false;
    };
    
    quota = multiTenancy.mkNamespaceQuota "backup-demo" {
      namespace = "backup-demo";
      cpuQuota = "80";
      memoryQuota = "200Gi";
      podQuota = 200;
      deploymentQuota = 30;
      statefulsetQuota = 5;
      pvQuota = 20;
    };
  };

  # Example 9: Complete Enterprise Setup
  exampleCompleteEnterpriseSetup = {
    # Production tenant
    production = multiTenancy.mkTenant "prod" {
      namespace = "prod";
      displayName = "Production";
      cpuQuota = "500";
      memoryQuota = "1Ti";
      storageQuota = "5Ti";
      isolationLevel = "standard";
      networkIsolation = true;
      ingressEnabled = true;
      owner = "platform@company.com";
      billingContact = "finance@company.com";
      costCenter = "PROD-001";
      
      labels = { environment = "production"; tier = "critical"; };
    };
    
    # Staging tenant
    staging = multiTenancy.mkTenant "staging" {
      namespace = "staging";
      displayName = "Staging";
      cpuQuota = "200";
      memoryQuota = "400Gi";
      storageQuota = "2Ti";
      isolationLevel = "standard";
      networkIsolation = true;
      owner = "qa@company.com";
      billingContact = "finance@company.com";
      costCenter = "QA-001";
      
      labels = { environment = "staging"; tier = "important"; };
    };
    
    # Development tenant
    development = multiTenancy.mkTenant "dev" {
      namespace = "dev";
      displayName = "Development";
      cpuQuota = "100";
      memoryQuota = "200Gi";
      storageQuota = "500Gi";
      isolationLevel = "permissive";
      networkIsolation = false;
      owner = "engineering@company.com";
      billingContact = "finance@company.com";
      costCenter = "DEV-001";
      
      labels = { environment = "development"; tier = "non-critical"; };
    };
  };

  # Example 10: SaaS Multi-Tenant Platform
  exampleSaasPlatform = builtins.mapAttrs (customerName: config:
    let
      tenant = multiTenancy.mkTenant customerName config;
      rbac = multiTenancy.mkTenantRBAC customerName {
        namespace = config.namespace;
        admins = config.admins;
      };
      billing = multiTenancy.mkTenantBilling customerName {
        tenantName = config.displayName;
        billingContact = config.billingContact;
        costCenter = config.costCenter;
      };
      monitoring = multiTenancy.mkTenantMonitoring customerName {
        namespace = config.namespace;
      };
    in
      { inherit tenant rbac billing monitoring; }
  ) {
    customer1 = {
      namespace = "customer1-prod";
      displayName = "Customer 1";
      cpuQuota = "50";
      memoryQuota = "100Gi";
      storageQuota = "200Gi";
      admins = ["admin@customer1.com"];
      billingContact = "billing@customer1.com";
      costCenter = "C1-001";
    };
    
    customer2 = {
      namespace = "customer2-prod";
      displayName = "Customer 2";
      cpuQuota = "100";
      memoryQuota = "250Gi";
      storageQuota = "500Gi";
      admins = ["admin@customer2.com"];
      billingContact = "billing@customer2.com";
      costCenter = "C2-001";
    };
  };
}
