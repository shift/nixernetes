# Nixernetes Multi-Tenancy Module

## Overview

The Multi-Tenancy module provides comprehensive support for running multiple independent tenants on a single Kubernetes cluster with strong isolation guarantees, resource management, and billing capabilities. This enables cost-effective cluster sharing while maintaining security and performance isolation.

## Key Features

- **Tenant Management**: Create and configure isolated tenant environments
- **Namespace Quotas**: Resource quotas and limits per namespace
- **Network Policies**: Network isolation between tenants
- **RBAC**: Fine-grained role-based access control per tenant
- **Resource Limits**: CPU, memory, and storage constraints
- **Billing**: Multi-tenant billing and cost tracking
- **Isolation Policies**: Multiple isolation levels (strict, standard, permissive)
- **Monitoring**: Per-tenant metrics, logs, and dashboards
- **Backup/Restore**: Tenant-specific data backup and recovery
- **Audit**: Complete API audit logging per tenant

## Builders

### mkTenant

Create a tenant namespace with isolation policies.

```nix
mkTenant "acme-corp" {
  namespace = "acme-corp";
  displayName = "ACME Corporation";
  description = "Main production tenant";
  
  cpuQuota = "200";
  memoryQuota = "512Gi";
  storageQuota = "2Ti";
  podQuota = 1000;
  
  isolationLevel = "standard";
  networkIsolation = true;
  ingressEnabled = true;
  
  owner = "platform-team@acme.com";
  admins = ["admin1@acme.com" "admin2@acme.com"];
  
  billingContact = "billing@acme.com";
  costCenter = "ENG-001";
  billingCycle = "monthly";
  
  labels = {
    "team" = "platform";
    "environment" = "production";
  };
}
```

**Parameters**:
- `namespace`: Kubernetes namespace name (default: tenant name)
- `displayName`: Human-readable tenant name
- `description`: Tenant description
- `cpuQuota`: CPU quota (millicores)
- `memoryQuota`: Memory quota (Gi)
- `storageQuota`: Storage quota (Ti)
- `podQuota`: Maximum pods per namespace
- `cpuLimit`: CPU hard limit
- `memoryLimit`: Memory hard limit
- `isolationLevel`: `"strict"`, `"standard"`, or `"permissive"`
- `networkIsolation`: Enable network policies
- `ingressEnabled`: Allow ingress traffic
- `egressEnabled`: Allow egress traffic
- `owner`: Tenant owner email
- `admins`: List of admin emails
- `billingContact`: Contact for billing matters
- `costCenter`: Billing cost center
- `labels`: Custom Kubernetes labels
- `annotations`: Custom Kubernetes annotations

### mkNamespaceQuota

Define resource quotas for a namespace.

```nix
mkNamespaceQuota "acme-corp-prod" {
  namespace = "acme-corp-prod";
  cpuQuota = "200";
  memoryQuota = "512Gi";
  podQuota = 500;
  deploymentQuota = 100;
  statefulsetQuota = 20;
  pvQuota = 100;
  serviceQuota = 100;
  ingressQuota = 20;
}
```

**Parameters**:
- `cpuQuota`: Total CPU quota for namespace
- `memoryQuota`: Total memory quota
- `ephemeralStorageQuota`: Ephemeral storage quota
- `podQuota`: Maximum pod count
- `deploymentQuota`: Maximum deployment count
- `statefulsetQuota`: Maximum StatefulSet count
- `jobQuota`: Maximum job count
- `pvQuota`: Maximum persistent volume count
- `serviceQuota`: Maximum service count
- `ingressQuota`: Maximum ingress count
- `configmapQuota`: Maximum ConfigMap count
- `secretQuota`: Maximum secret count
- `pvcQuota`: Maximum PVC count
- `storageQuota`: Total storage quota
- `scopes`: Quota scopes (e.g., "BestEffort", "NotTerminating")

### mkTenantNetworkPolicy

Configure network isolation policies for a tenant.

```nix
mkTenantNetworkPolicy "acme-corp" {
  namespace = "acme-corp";
  ingressEnabled = false;
  allowFromSameTenant = true;
  allowFromNamespaces = [];
  
  egressEnabled = true;
  allowToSameTenant = true;
  allowToDns = true;
  allowToExternal = false;
  
  allowedPorts = [80 443];
}
```

**Parameters**:
- `ingressEnabled`: Allow ingress traffic
- `allowFromSameTenant`: Allow traffic within tenant
- `allowFromNamespaces`: List of allowed namespaces
- `allowFromPods`: List of allowed pod selectors
- `egressEnabled`: Allow egress traffic
- `allowToSameTenant`: Allow egress within tenant
- `allowToNamespaces`: List of allowed egress namespaces
- `allowToDns`: Allow DNS queries
- `allowToExternal`: Allow external traffic
- `allowedExternalCIDRs`: List of allowed external CIDRs
- `allowedPorts`: Allowed ports
- `blockedPorts`: Blocked ports

### mkTenantRBAC

Configure role-based access control for a tenant.

```nix
mkTenantRBAC "acme-corp" {
  namespace = "acme-corp";
  
  roles = {
    admin = {
      verbs = ["*"];
      resources = ["*"];
    };
    developer = {
      verbs = ["get" "list" "watch" "create" "update" "patch"];
      resources = ["deployments" "services" "configmaps"];
    };
  };
  
  admins = ["admin@acme.com"];
  developers = ["dev1@acme.com" "dev2@acme.com"];
  viewers = ["viewer@acme.com"];
  
  serviceAccounts = ["ci-cd" "monitoring"];
}
```

**Parameters**:
- `roles`: Role definitions with verbs and resources
- `admins`: Admin user list
- `developers`: Developer user list
- `viewers`: Viewer user list
- `serviceAccounts`: Service account names
- `allowCrossTenantAccess`: Allow access to other tenants
- `allowedTenants`: List of accessible tenants

### mkTenantResourceLimits

Define resource limits for tenant workloads.

```nix
mkTenantResourceLimits "acme-corp" {
  namespace = "acme-corp";
  
  podCpuLimit = "10";
  podMemoryLimit = "32Gi";
  podCpuRequest = "100m";
  podMemoryRequest = "128Mi";
  
  containerCpuLimit = "8";
  containerMemoryLimit = "16Gi";
  
  qosClass = "Burstable";
  allowBursting = true;
  minReplicas = 2;
}
```

**Parameters**:
- `podCpuLimit`: Max CPU per pod
- `podMemoryLimit`: Max memory per pod
- `podCpuRequest`: Requested CPU per pod
- `podMemoryRequest`: Requested memory per pod
- `containerCpuLimit`: Max CPU per container
- `containerMemoryLimit`: Max memory per container
- `qosClass`: Quality of Service class
- `allowBursting`: Allow CPU bursting
- `burstCpu`: CPU burst limit
- `burstMemory`: Memory burst limit
- `minReplicas`: Minimum replicas for HA
- `ephemeralStorageLimit`: Ephemeral storage limit

### mkTenantBilling

Configure billing and cost tracking for a tenant.

```nix
mkTenantBilling "acme-corp" {
  billingContact = "billing@acme.com";
  costCenter = "ENG-001";
  billingCycle = "monthly";
  
  cpuHourlyRate = 0.05;
  memoryHourlyRate = 0.01;
  storageMonthlyRate = 0.10;
  networkEgressRate = 0.02;
  
  monthlyBudget = 10000;
  budgetAlertThreshold = 0.80;
  budgetEnforcement = true;
  
  chargebackModel = "shared";
  volumeDiscount = 0.10;
}
```

**Parameters**:
- `billingContact`: Billing contact email
- `billingEmail`: Billing email address
- `costCenter`: Cost center code
- `billingCycle`: `"hourly"`, `"daily"`, `"weekly"`, `"monthly"`
- `cpuHourlyRate`: Hourly rate per CPU
- `memoryHourlyRate`: Hourly rate per GB memory
- `storageMonthlyRate`: Monthly rate per GB storage
- `networkEgressRate`: Rate for egress traffic
- `monthlyBudget`: Monthly budget limit
- `budgetAlertThreshold`: Alert threshold (0-1)
- `budgetEnforcement`: Enforce budget limits
- `chargebackModel`: `"shared"`, `"dedicated"`, or `"usage"`
- `volumeDiscount`: Volume discount percentage
- `commitmentDiscount`: Commitment discount percentage

### mkTenantIsolationPolicy

Define isolation policies for a tenant.

```nix
mkTenantIsolationPolicy "acme-corp" {
  namespace = "acme-corp";
  
  isolationLevel = "standard";
  networkIsolation = true;
  storageIsolation = true;
  
  podSecurityPolicy = "restricted";
  secretsEncryption = true;
  encryptionAtRest = true;
  
  apiAudit = true;
  auditLevel = "Metadata";
  
  allowedRegistries = ["gcr.io" "docker.io"];
  imageVerification = true;
}
```

**Parameters**:
- `isolationLevel`: `"strict"`, `"standard"`, or `"permissive"`
- `networkIsolation`: Enable network isolation
- `dnsIsolation`: Enable DNS isolation
- `storageIsolation`: Enable storage isolation
- `pvAccessControl`: Control PV access
- `cpuPinning`: Pin CPU to tenants
- `dedicatedNodes`: Use dedicated nodes
- `podSecurityPolicy`: PSP level
- `appArmor`: Enable AppArmor
- `selinux`: Enable SELinux
- `secretsEncryption`: Encrypt secrets
- `encryptionAtRest`: Encrypt data at rest
- `apiAudit`: Enable API audit logging
- `auditLevel`: Audit detail level
- `allowedRegistries`: Allowed image registries
- `blockedRegistries`: Blocked registries
- `imageVerification`: Verify image signatures

### mkTenantMonitoring

Configure monitoring for a tenant.

```nix
mkTenantMonitoring "acme-corp" {
  namespace = "acme-corp";
  
  metricsEnabled = true;
  metricsRetention = "30d";
  
  loggingEnabled = true;
  logLevel = "Info";
  logRetention = "7d";
  
  alertingEnabled = true;
  alertReceivers = ["alerts@acme.com"];
  
  sloEnabled = true;
  targetAvailability = 0.99;
  targetLatency = "100ms";
}
```

**Parameters**:
- `metricsEnabled`: Enable metrics collection
- `metricsRetention`: Retention period for metrics
- `loggingEnabled`: Enable centralized logging
- `logLevel`: Log level
- `logRetention`: Log retention period
- `logFormat`: Log format (json, text)
- `alertingEnabled`: Enable alerting
- `alertReceivers`: Alert receiver emails
- `sloEnabled`: Enable SLO tracking
- `targetAvailability`: Target availability (0-1)
- `targetLatency`: Target request latency
- `dashboardsEnabled`: Enable dashboards
- `customDashboards`: Custom dashboard definitions

### mkTenantBackup

Configure backup and recovery for a tenant.

```nix
mkTenantBackup "acme-corp" {
  namespace = "acme-corp";
  
  backupEnabled = true;
  backupSchedule = "0 2 * * *";
  backupRetention = 30;
  
  backupNamespace = true;
  backupPersistentVolumes = true;
  backupSecrets = true;
  
  encryptionEnabled = true;
  
  restoreEnabled = true;
  allowCrossTenantRestore = false;
}
```

**Parameters**:
- `backupEnabled`: Enable backups
- `backupSchedule`: Backup schedule (cron)
- `backupRetention`: Retention in days
- `backupNamespace`: Backup namespace resources
- `backupPersistentVolumes`: Backup PVs
- `backupSecrets`: Backup secrets
- `backupIncludeResources`: Resource types to include
- `backupExcludeResources`: Resource types to exclude
- `backupStorageLocation`: Storage location name
- `encryptionEnabled`: Enable backup encryption
- `restoreEnabled`: Enable restores
- `restoreSchedule`: Restore schedule
- `allowCrossTenantRestore`: Allow cross-tenant restores

## Validation Functions

### validateTenant

Validates tenant configuration and returns validation results.

```nix
let
  result = validateTenant tenant;
in
  if result.valid then "OK" else builtins.concatStringsSep ", " result.errors
```

Returns object with:
- `valid`: Boolean indicating validity
- `errors`: List of error messages
- `checks`: Detailed validation checks

## Helper Functions

### calculateTotalQuota

Calculate total quota allocation across all tenants.

```nix
let
  total = calculateTotalQuota allTenants;
in
  "Total CPU: ${total.totalCpuQuota}, Total Memory: ${total.totalMemoryQuota}"
```

## Framework Metadata

The framework object provides metadata about the module:

```nix
{
  name = "Nixernetes Multi-Tenancy";
  version = "1.0.0";
  
  features = {
    tenant-management = "...";
    namespace-quotas = "...";
    network-policies = "...";
    # ... more features
  };
  
  supportedIsolationLevels = ["strict" "standard" "permissive"];
  supportedBillingCycles = ["hourly" "daily" "weekly" "monthly"];
  supportedResourceTypes = ["compute" "storage" "network"];
}
```

## Integration

### With RBAC Module

```nix
let
  tenant = mkTenant "acme" { ... };
  rbac = mkTenantRBAC "acme" { ... };
in
  # Create both tenant and RBAC rules
```

### With Compliance Module

```nix
let
  tenant = mkTenant "acme" { ... };
in
  # Ensure tenant meets compliance requirements
```

### With Cost Analysis Module

```nix
let
  billing = mkTenantBilling "acme" { ... };
in
  # Track and analyze costs per tenant
```

## Examples

### Single Tenant

```nix
let
  tenant = mkTenant "single" {
    namespace = "single";
    cpuQuota = "50";
    memoryQuota = "128Gi";
    isolationLevel = "permissive";
  };
in
  tenant
```

### Multi-Tenant Cluster

```nix
let
  tenants = {
    acme = mkTenant "acme" {
      cpuQuota = "200";
      memoryQuota = "512Gi";
      isolationLevel = "standard";
    };
    
    widgets = mkTenant "widgets" {
      cpuQuota = "100";
      memoryQuota = "256Gi";
      isolationLevel = "standard";
    };
    
    startup = mkTenant "startup" {
      cpuQuota = "50";
      memoryQuota = "128Gi";
      isolationLevel = "permissive";
    };
  };
in
  tenants
```

### Strict Isolation with Dedicated Resources

```nix
mkTenant "secure" {
  isolationLevel = "strict";
  networkIsolation = true;
  
  podSecurityPolicy = "restricted";
  secretsEncryption = true;
  encryptionAtRest = true;
  
  allowedRegistries = ["private-registry.company.com"];
  imageVerification = true;
  
  cpuPinning = true;
  dedicatedNodes = true;
}
```

### Cost-Optimized Tenant

```nix
mkTenant "dev" {
  cpuQuota = "20";
  memoryQuota = "50Gi";
  storageQuota = "100Gi";
  isolationLevel = "permissive";
  
  billingCycle = "hourly";
  budgetEnforcement = true;
  monthlyBudget = 1000;
}
```

## Best Practices

### Isolation Planning

1. **Assess Security Requirements**: Determine isolation level based on tenant sensitivity
2. **Define Quotas**: Set appropriate resource quotas for each tenant workload
3. **Configure Policies**: Use network and RBAC policies for fine-grained control
4. **Monitor Usage**: Track resource usage against quotas
5. **Plan Growth**: Reserve capacity for future growth

### Resource Management

1. **Conservative Quotas**: Set quotas to 70-80% of available capacity
2. **Monitoring**: Enable monitoring for all tenants
3. **Alerts**: Configure alerts for quota warnings
4. **Review Regularly**: Audit and adjust quotas monthly
5. **Burst Limits**: Use burst limits for peak handling

### Billing

1. **Clear Models**: Define chargeback models upfront
2. **Rate Transparency**: Ensure rates are clear to tenants
3. **Budget Alerts**: Enable budget alerts at 80%
4. **Regular Reviews**: Review costs monthly
5. **Forecasting**: Project future costs

### Security

1. **Network Policies**: Always enable for production
2. **RBAC**: Implement least privilege
3. **Audit Logging**: Enable for compliance
4. **Secrets Management**: Use encryption for sensitive data
5. **Image Verification**: Enforce for strict isolation

### Monitoring Checklist

- [ ] Metrics collection enabled for all tenants
- [ ] Centralized logging configured
- [ ] Alerts configured for quota breaches
- [ ] SLOs defined for each tenant
- [ ] Dashboards created for monitoring
- [ ] Regular audit log reviews scheduled

## Performance Considerations

- Network policies add 2-5% latency overhead
- Resource quotas have minimal performance impact
- Encryption at rest adds 5-10% storage overhead
- API audit logging adds 1-2% API overhead
- Monitoring adds 3-5% compute overhead

## Supported Kubernetes Versions

- 1.24+
- 1.25+
- 1.26+
- 1.27+
- 1.28+
- 1.29+
