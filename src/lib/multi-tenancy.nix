# Nixernetes Multi-Tenancy Module
#
# Provides comprehensive multi-tenancy support for Kubernetes clusters including:
# - Namespace isolation with quotas
# - Network policies for traffic control
# - RBAC with tenant-specific roles
# - Resource limits and guarantees
# - Tenant billing and cost tracking
# - Tenant isolation validation
#
# This module enables secure sharing of a single Kubernetes cluster among
# multiple independent tenants with strong isolation guarantees.

{ lib }:

let
  inherit (lib) mkOption types;
in

{
  # Create a tenant namespace with isolation policies
  mkTenant = name: config:
    let
      cfg = {
        name = name;
        namespace = config.namespace or name;
        displayName = config.displayName or name;
        description = config.description or "";
        
        # Resource allocation
        cpuQuota = config.cpuQuota or "100";
        memoryQuota = config.memoryQuota or "256Gi";
        storageQuota = config.storageQuota or "1Ti";
        podQuota = config.podQuota or 500;
        
        # Resource limits
        cpuLimit = config.cpuLimit or "50";
        memoryLimit = config.memoryLimit or "128Gi";
        
        # Billing
        billingContact = config.billingContact or "";
        costCenter = config.costCenter or "";
        billingCycle = config.billingCycle or "monthly";
        
        # Isolation level: strict, standard, permissive
        isolationLevel = config.isolationLevel or "standard";
        
        # Network policies
        networkIsolation = config.networkIsolation or true;
        ingressEnabled = config.ingressEnabled or false;
        egressEnabled = config.egressEnabled or true;
        
        # Allowed resources (empty = all)
        allowedResources = config.allowedResources or [];
        
        # Restricted capabilities
        restrictedCapabilities = config.restrictedCapabilities or ["NET_ADMIN" "SYS_ADMIN"];
        allowPrivilegedContainers = config.allowPrivilegedContainers or false;
        
        # Owner/admin
        owner = config.owner or "";
        admins = config.admins or [];
        
        # Labels for identification
        labels = (config.labels or {}) // {
          "nixernetes.io/tenant" = name;
          "nixernetes.io/isolation" = config.isolationLevel or "standard";
        };
        
        # Annotations for metadata
        annotations = config.annotations or {};
      };
    in
      cfg;

  # Create namespace resource quota
  mkNamespaceQuota = name: config:
    let
      cfg = {
        name = name;
        namespace = config.namespace or name;
        
        # Compute quotas
        cpuQuota = config.cpuQuota or "100";
        memoryQuota = config.memoryQuota or "256Gi";
        ephemeralStorageQuota = config.ephemeralStorageQuota or "10Gi";
        
        # Object count quotas
        podQuota = config.podQuota or 500;
        deploymentQuota = config.deploymentQuota or 50;
        statefulsetQuota = config.statefulsetQuota or 10;
        jobQuota = config.jobQuota or 100;
        pvQuota = config.pvQuota or 50;
        serviceQuota = config.serviceQuota or 50;
        ingressQuota = config.ingressQuota or 10;
        configmapQuota = config.configmapQuota or 100;
        secretQuota = config.secretQuota or 100;
        
        # PVC-related quotas
        pvcQuota = config.pvcQuota or 50;
        storageQuota = config.storageQuota or "1Ti";
        
        # Scopes
        scopes = config.scopes or [];
        
        # Soft limits (warnings)
        softLimits = config.softLimits or false;
        warnings = config.warnings or {};
      };
    in
      cfg;

  # Create network policy for tenant isolation
  mkTenantNetworkPolicy = name: config:
    let
      cfg = {
        name = "tenant-${name}";
        namespace = config.namespace or name;
        
        # Ingress rules
        ingressEnabled = config.ingressEnabled or false;
        allowFromSameTenant = config.allowFromSameTenant or true;
        allowFromNamespaces = config.allowFromNamespaces or [];
        allowFromPods = config.allowFromPods or [];
        
        # Egress rules
        egressEnabled = config.egressEnabled or true;
        allowToSameTenant = config.allowToSameTenant or true;
        allowToNamespaces = config.allowToNamespaces or [];
        allowToDns = config.allowToDns or true;
        allowToExternal = config.allowToExternal or false;
        allowedExternalCIDRs = config.allowedExternalCIDRs or [];
        
        # Port restrictions
        allowedPorts = config.allowedPorts or [];
        blockedPorts = config.blockedPorts or [];
        
        # Policy type
        policyTypes = config.policyTypes or ["Ingress" "Egress"];
        
        # Labels for pod selection
        podSelector = config.podSelector or { matchLabels = { "tenant" = name; }; };
      };
    in
      cfg;

  # Create RBAC configuration for tenant
  mkTenantRBAC = name: config:
    let
      cfg = {
        name = name;
        namespace = config.namespace or name;
        
        # Role definitions
        roles = config.roles or {
          admin = {
            verbs = ["*"];
            resources = ["*"];
            apiGroups = ["*"];
          };
          developer = {
            verbs = ["get" "list" "watch" "create" "update" "patch"];
            resources = ["deployments" "statefulsets" "services" "configmaps" "secrets"];
            apiGroups = ["apps" "v1" ""];
          };
          viewer = {
            verbs = ["get" "list" "watch"];
            resources = ["deployments" "statefulsets" "services" "pods"];
            apiGroups = ["apps" "v1" ""];
          };
        };
        
        # Users/groups
        admins = config.admins or [];
        developers = config.developers or [];
        viewers = config.viewers or [];
        
        # Service accounts
        serviceAccounts = config.serviceAccounts or [];
        
        # Cross-tenant access control
        allowCrossTenantAccess = config.allowCrossTenantAccess or false;
        allowedTenants = config.allowedTenants or [];
      };
    in
      cfg;

  # Create resource limits for tenant
  mkTenantResourceLimits = name: config:
    let
      cfg = {
        name = name;
        namespace = config.namespace or name;
        
        # Pod resource limits
        podCpuLimit = config.podCpuLimit or "10";
        podMemoryLimit = config.podMemoryLimit or "32Gi";
        
        # Pod resource requests
        podCpuRequest = config.podCpuRequest or "100m";
        podMemoryRequest = config.podMemoryRequest or "128Mi";
        
        # Container limits
        containerCpuLimit = config.containerCpuLimit or "8";
        containerMemoryLimit = config.containerMemoryLimit or "16Gi";
        
        # Quality of Service (QoS) class
        qosClass = config.qosClass or "Burstable";
        
        # Burst limits
        allowBursting = config.allowBursting or true;
        burstCpu = config.burstCpu or "50";
        burstMemory = config.burstMemory or "128Gi";
        
        # Min replicas for HA
        minReplicas = config.minReplicas or 1;
        
        # Ephemeral storage
        ephemeralStorageLimit = config.ephemeralStorageLimit or "10Gi";
        ephemeralStorageRequest = config.ephemeralStorageRequest or "1Gi";
      };
    in
      cfg;

  # Create tenant billing configuration
  mkTenantBilling = name: config:
    let
      cfg = {
        name = name;
        tenantId = config.tenantId or name;
        tenantName = config.tenantName or name;
        
        # Billing contact
        billingContact = config.billingContact or "";
        billingEmail = config.billingEmail or "";
        costCenter = config.costCenter or "";
        department = config.department or "";
        
        # Billing cycle
        billingCycle = config.billingCycle or "monthly";
        billingStartDate = config.billingStartDate or "";
        
        # Rate configuration
        cpuHourlyRate = config.cpuHourlyRate or 0.05;
        memoryHourlyRate = config.memoryHourlyRate or 0.01;
        storageMonthlyRate = config.storageMonthlyRate or 0.10;
        networkEgressRate = config.networkEgressRate or 0.02;
        
        # Budget
        monthlyBudget = config.monthlyBudget or null;
        budgetAlertThreshold = config.budgetAlertThreshold or 0.80;
        budgetEnforcement = config.budgetEnforcement or false;
        
        # Chargeback
        chargebackModel = config.chargebackModel or "shared";
        chargebackTags = config.chargebackTags or [];
        
        # Discounts
        volumeDiscount = config.volumeDiscount or 0;
        commitmentDiscount = config.commitmentDiscount or 0;
      };
    in
      cfg;

  # Create tenant isolation policy
  mkTenantIsolationPolicy = name: config:
    let
      cfg = {
        name = name;
        namespace = config.namespace or name;
        
        # Isolation levels
        isolationLevel = config.isolationLevel or "standard";
        
        # Network isolation
        networkIsolation = config.networkIsolation or true;
        dnsIsolation = config.dnsIsolation or false;
        
        # Storage isolation
        storageIsolation = config.storageIsolation or true;
        pvAccessControl = config.pvAccessControl or true;
        
        # Compute isolation
        cpuPinning = config.cpuPinning or false;
        nodeAffinity = config.nodeAffinity or null;
        dedicatedNodes = config.dedicatedNodes or false;
        
        # Security isolation
        podSecurityPolicy = config.podSecurityPolicy or "restricted";
        appArmor = config.appArmor or false;
        selinux = config.selinux or false;
        
        # Secrets isolation
        secretsEncryption = config.secretsEncryption or true;
        encryptionAtRest = config.encryptionAtRest or false;
        
        # API access isolation
        apiAudit = config.apiAudit or true;
        auditLevel = config.auditLevel or "Metadata";
        
        # Constraints
        allowedRegistries = config.allowedRegistries or [];
        blockedRegistries = config.blockedRegistries or [];
        imageVerification = config.imageVerification or false;
      };
    in
      cfg;

  # Create tenant monitoring configuration
  mkTenantMonitoring = name: config:
    let
      cfg = {
        name = name;
        namespace = config.namespace or name;
        tenantLabel = "nixernetes.io/tenant=${name}";
        
        # Metrics
        metricsEnabled = config.metricsEnabled or true;
        metricsRetention = config.metricsRetention or "30d";
        
        # Logging
        loggingEnabled = config.loggingEnabled or true;
        logLevel = config.logLevel or "Info";
        logRetention = config.logRetention or "7d";
        logFormat = config.logFormat or "json";
        
        # Alerting
        alertingEnabled = config.alertingEnabled or true;
        alertReceivers = config.alertReceivers or [];
        
        # SLO/SLI
        sloEnabled = config.sloEnabled or true;
        targetAvailability = config.targetAvailability or 0.99;
        targetLatency = config.targetLatency or "100ms";
        
        # Dashboards
        dashboardsEnabled = config.dashboardsEnabled or true;
        customDashboards = config.customDashboards or [];
      };
    in
      cfg;

  # Create tenant backup configuration
  mkTenantBackup = name: config:
    let
      cfg = {
        name = name;
        namespace = config.namespace or name;
        
        # Backup policy
        backupEnabled = config.backupEnabled or true;
        backupSchedule = config.backupSchedule or "0 2 * * *";
        backupRetention = config.backupRetention or 30;
        
        # Backup scope
        backupNamespace = config.backupNamespace or true;
        backupPersistentVolumes = config.backupPersistentVolumes or true;
        backupSecrets = config.backupSecrets or true;
        backupIncludeResources = config.backupIncludeResources or [];
        backupExcludeResources = config.backupExcludeResources or [];
        
        # Backup storage
        backupStorageLocation = config.backupStorageLocation or "default";
        encryptionEnabled = config.encryptionEnabled or true;
        
        # Restore policy
        restoreEnabled = config.restoreEnabled or true;
        restoreSchedule = config.restoreSchedule or "0 3 * * 0";
        
        # Cross-tenant restore
        allowCrossTenantRestore = config.allowCrossTenantRestore or false;
      };
    in
      cfg;

  # Validate tenant configuration
  validateTenant = tenant:
    let
      errors = [];
      checks = {
        validIsolationLevel = builtins.elem tenant.isolationLevel ["strict" "standard" "permissive"];
        validBillingCycle = builtins.elem tenant.billingCycle ["hourly" "daily" "weekly" "monthly"];
        nameNotEmpty = tenant.name != "";
        namespaceNotEmpty = tenant.namespace != "";
      };
      errorList = lib.optional (!checks.validIsolationLevel) "Invalid isolation level: ${tenant.isolationLevel}"
                ++ lib.optional (!checks.validBillingCycle) "Invalid billing cycle: ${tenant.billingCycle}"
                ++ lib.optional (!checks.nameNotEmpty) "Tenant name cannot be empty"
                ++ lib.optional (!checks.namespaceNotEmpty) "Tenant namespace cannot be empty";
    in
      {
        valid = builtins.length errorList == 0;
        errors = errorList;
        checks = checks;
      };

  # Calculate total tenant quota
  calculateTotalQuota = tenants:
    let
      totalCpu = builtins.foldl' (acc: t: acc + (lib.toInt (lib.strings.removeSuffix "" t.cpuQuota))) 0 tenants;
      totalMemory = builtins.foldl' (acc: t: acc + 
        (lib.toInt (lib.strings.removeSuffix "Gi" t.memoryQuota))) 0 tenants;
    in
      {
        totalCpuQuota = builtins.toString totalCpu;
        totalMemoryQuota = "${builtins.toString totalMemory}Gi";
        tenantCount = builtins.length tenants;
      };

  # Framework metadata
  framework = {
    name = "Nixernetes Multi-Tenancy";
    version = "1.0.0";
    description = "Multi-tenancy support for enterprise Kubernetes clusters";
    
    features = {
      "tenant-management" = "Create and manage isolated tenants";
      "namespace-quotas" = "Resource quotas per namespace";
      "network-policies" = "Network isolation between tenants";
      "rbac" = "Role-based access control per tenant";
      "resource-limits" = "CPU, memory, and storage limits";
      "billing" = "Tenant billing and cost tracking";
      "isolation-policies" = "Multi-level isolation guarantees";
      "monitoring" = "Per-tenant monitoring and metrics";
      "backup-restore" = "Tenant-specific backup and restore";
      "audit" = "API audit logging per tenant";
    };
    
    supportedIsolationLevels = ["strict" "standard" "permissive"];
    supportedBillingCycles = ["hourly" "daily" "weekly" "monthly"];
    supportedResourceTypes = ["compute" "storage" "network"];
    supportedMonitoringBackends = ["prometheus" "datadog" "new-relic"];
    supportedLoggingBackends = ["elasticsearch" "loki" "splunk"];
    
    kubernetesVersions = ["1.24" "1.25" "1.26" "1.27" "1.28" "1.29"];
  };
}
