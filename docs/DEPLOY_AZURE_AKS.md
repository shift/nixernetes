# Azure AKS Deployment Guide

Complete guide for deploying Nixernetes on Azure Kubernetes Service (AKS).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Azure Account and Resource Setup](#azure-account-and-resource-setup)
3. [AKS Cluster Configuration](#aks-cluster-configuration)
4. [Nixernetes Integration](#nixernetes-integration)
5. [Deployment Patterns](#deployment-patterns)
6. [Identity and Security](#identity-and-security)
7. [Cost Optimization](#cost-optimization)
8. [Monitoring and Diagnostics](#monitoring-and-diagnostics)
9. [Disaster Recovery](#disaster-recovery)
10. [Troubleshooting](#troubleshooting)

## Prerequisites

### Azure Subscription
- Active Azure subscription
- Azure CLI v2.50+
- Appropriate permissions: Subscription Contributor or higher

### Local Tools
- azure-cli >= 2.50
- kubectl >= 1.28
- helm >= 3.12
- Nix and direnv

### Verify Setup

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription "SUBSCRIPTION_ID"

# Verify access
az account show
```

## Azure Account and Resource Setup

### Step 1: Create Azure Configuration

Create `azure-config.nix`:

```nix
{
  # Azure settings
  subscriptionId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
  location = "eastus";
  
  # Resource Group
  resourceGroupName = "nixernetes-rg";
  
  # Cluster settings
  clusterName = "nixernetes-prod";
  kubernetesVersion = "1.30";
  
  # Network settings
  vnetName = "nixernetes-vnet";
  vnetAddressPrefix = "10.0.0.0/8";
  
  subnets = {
    default = {
      name = "default-subnet";
      addressPrefix = "10.0.0.0/16";
    };
    vm = {
      name = "vm-subnet";
      addressPrefix = "10.1.0.0/16";
    };
  };
  
  # Node pool settings
  nodePools = {
    system = {
      name = "system";
      nodeCount = 3;
      minCount = 1;
      maxCount = 5;
      vmSize = "Standard_D4s_v5";
      mode = "System";
      labels = { workload = "system"; };
      taints = [{ key = "system"; value = "true"; effect = "NoSchedule"; }];
    };
    
    user = {
      name = "user";
      nodeCount = 3;
      minCount = 1;
      maxCount = 10;
      vmSize = "Standard_D4s_v5";
      mode = "User";
      labels = { workload = "general"; };
      taints = [];
    };
    
    compute = {
      name = "compute";
      nodeCount = 0;
      minCount = 0;
      maxCount = 20;
      vmSize = "Standard_D8s_v5";
      mode = "User";
      labels = { workload = "compute"; };
      taints = [{ key = "workload"; value = "compute"; effect = "NoSchedule"; }];
    };
  };
  
  # Network settings
  enableNetworkPolicy = true;
  networkPolicy = "azure";
  
  # Add-ons
  addons = {
    httpApplicationRouting = false;
    monitoring = true;
    azurePolicy = true;
    secretsStoreCSIDriver = true;
  };
  
  # Identity
  enableManagedIdentity = true;
  enableAzureAD = true;
  
  # Tags
  tags = {
    environment = "production";
    managedBy = "nixernetes";
  };
}
```

### Step 2: Create Resource Group and Network

```bash
#!/bin/bash

LOCATION="eastus"
RG_NAME="nixernetes-rg"
VNET_NAME="nixernetes-vnet"
SUBNET_NAME="default-subnet"
CLUSTER_NAME="nixernetes-prod"

# Create resource group
az group create \
  --name $RG_NAME \
  --location $LOCATION

# Create virtual network
az network vnet create \
  --resource-group $RG_NAME \
  --name $VNET_NAME \
  --address-prefix 10.0.0.0/8 \
  --subnet-name $SUBNET_NAME \
  --subnet-prefix 10.0.0.0/16

# Get subnet ID
SUBNET_ID=$(az network vnet subnet show \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name $SUBNET_NAME \
  --query id -o tsv)

# Create AKS cluster
az aks create \
  --resource-group $RG_NAME \
  --name $CLUSTER_NAME \
  --kubernetes-version 1.30 \
  --node-count 3 \
  --vm-set-type VirtualMachineScaleSets \
  --vnet-subnet-id $SUBNET_ID \
  --network-plugin azure \
  --network-policy azure \
  --enable-managed-identity \
  --enable-aad-integration \
  --enable-pod-identity \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 10 \
  --vm-set-type VirtualMachineScaleSets \
  --zones 1 2 3 \
  --enable-addons monitoring,azure-policy,secret-store-csi-driver

# Get credentials
az aks get-credentials \
  --resource-group $RG_NAME \
  --name $CLUSTER_NAME \
  --admin

# Verify cluster
kubectl get nodes
kubectl get svc -A
```

## AKS Cluster Configuration

### Step 1: Create Nixernetes AKS Configuration

Create `nixernetes-aks.nix`:

```nix
{ lib, pkgs }:

let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  security = import ./src/lib/security-policies.nix { inherit lib; };
  secrets = import ./src/lib/secrets-management.nix { inherit lib; };
  gitops = import ./src/lib/gitops.nix { inherit lib; };
  
in
{
  # Create nixernetes namespace
  namespace = k8s.mkNamespace {
    name = "nixernetes";
    labels = {
      "app.kubernetes.io/managed-by" = "nixernetes";
    };
  };
  
  # Pod Identity binding for Azure resources
  podIdentity = {
    apiVersion = "aadpodidentity.k8s.io/v1";
    kind = "AzureIdentity";
    metadata = {
      namespace = "nixernetes";
      name = "nixernetes-identity";
    };
    spec = {
      type = 0;
      resourceID = "/subscriptions/SUBSCRIPTION_ID/resourcegroups/RESOURCE_GROUP/providers/Microsoft.ManagedIdentity/userAssignedIdentities/nixernetes";
      clientID = "CLIENT_ID";
    };
  };
  
  # Pod Identity Binding
  podIdentityBinding = {
    apiVersion = "aadpodidentity.k8s.io/v1";
    kind = "AzureIdentityBinding";
    metadata = {
      namespace = "nixernetes";
      name = "nixernetes-binding";
    };
    spec = {
      azureIdentity = "nixernetes-identity";
      selector = "nixernetes";
    };
  };
  
  # Service Account
  serviceAccount = k8s.mkServiceAccount {
    namespace = "nixernetes";
    name = "nixernetes-sa";
    labels = {
      "aadpodidbinding" = "nixernetes";
    };
  };
  
  # Network Policy
  networkPolicy = security.mkDefaultDenyNetworkPolicy {
    namespace = "default";
    name = "default-deny-all";
  };
}
```

### Step 2: Configure Azure Key Vault for Secrets

```bash
# Create Key Vault
az keyvault create \
  --resource-group nixernetes-rg \
  --name nixernetes-vault \
  --location eastus

# Store secrets
az keyvault secret set \
  --vault-name nixernetes-vault \
  --name db-password \
  --value "secure-password-here"

# Grant AKS access
IDENTITY_CLIENT_ID=$(az aks show \
  --resource-group nixernetes-rg \
  --name nixernetes-prod \
  --query identityProfile.kubeletidentity.clientId -o tsv)

az keyvault set-policy \
  --name nixernetes-vault \
  --spn $IDENTITY_CLIENT_ID \
  --secret-permissions get list
```

### Step 3: Deploy Secret Store CSI Driver

```nix
let
  secrets = import ./src/lib/secrets-management.nix { inherit lib; };
in
{
  # Create SecretProvider class for Key Vault
  secretProvider = {
    apiVersion = "secrets-store.csi.x-k8s.io/v1";
    kind = "SecretProviderClass";
    metadata = {
      namespace = "production";
      name = "azure-keyvault";
    };
    spec = {
      provider = "azure";
      parameters = {
        usePodIdentity = "true";
        keyvaultName = "nixernetes-vault";
        objects = ''
          array:
            - |
              objectName: db-password
              objectType: secret
        '';
        tenantID = "TENANT_ID";
      };
      secretObjects = [{
        secretKey = "password";
        objectName = "db-password";
        data = [{ objectName = "db-password"; key = "password"; }];
      }];
    };
  };
}
```

## Nixernetes Integration

### Step 1: Deploy Application with Azure Integration

```nix
{ lib }:

let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  
in
{
  deployment = k8s.mkDeployment {
    namespace = "production";
    name = "myapp";
    
    replicas = 3;
    
    serviceAccountName = "myapp-sa";
    
    affinity = {
      podAntiAffinity = {
        preferredDuringSchedulingIgnoredDuringExecution = [{
          weight = 100;
          podAffinityTerm = {
            labelSelector = {
              matchExpressions = [{
                key = "app";
                operator = "In";
                values = ["myapp"];
              }];
            };
            topologyKey = "kubernetes.io/hostname";
          };
        }];
      };
    };
    
    containers = [{
      name = "app";
      image = "myregistry.azurecr.io/myapp:latest";
      
      ports = [{ containerPort = 8080; }];
      
      env = [
        { name = "ENVIRONMENT"; value = "production"; }
        { name = "AZURE_SUBSCRIPTION_ID"; value = "SUBSCRIPTION_ID"; }
      ];
      
      volumeMounts = [{
        name = "secrets";
        mountPath = "/mnt/secrets";
        readOnly = true;
      }];
      
      resources = {
        requests = { cpu = "500m"; memory = "512Mi"; };
        limits = { cpu = "1000m"; memory = "1Gi"; };
      };
    }];
    
    volumes = [{
      name = "secrets";
      csi = {
        driver = "secrets-store.csi.k8s.io";
        readOnly = true;
        volumeAttributes = {
          secretProviderClass = "azure-keyvault";
        };
      };
    }];
  };
}
```

## Deployment Patterns

### Pattern 1: Integration with Azure Database

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  # Connection secret from Azure Database
  dbSecret = k8s.mkSecret {
    namespace = "production";
    name = "azure-postgres";
    
    data = {
      host = "myserver.postgres.database.azure.com";
      port = "5432";
      database = "mydb";
      username = "postgres@myserver";
      password = "PASSWORD";
    };
  };
  
  # Application deployment
  app = k8s.mkDeployment {
    namespace = "production";
    name = "app";
    
    containers = [{
      image = "myapp:latest";
      
      env = [
        { name = "DB_HOST"; valueFrom = { secretKeyRef = { name = "azure-postgres"; key = "host"; }; }; }
        { name = "DB_PORT"; valueFrom = { secretKeyRef = { name = "azure-postgres"; key = "port"; }; }; }
        { name = "DB_USER"; valueFrom = { secretKeyRef = { name = "azure-postgres"; key = "username"; }; }; }
        { name = "DB_PASS"; valueFrom = { secretKeyRef = { name = "azure-postgres"; key = "password"; }; }; }
        { name = "DB_NAME"; valueFrom = { secretKeyRef = { name = "azure-postgres"; key = "database"; }; }; }
      ];
    }];
  };
}
```

### Pattern 2: Using Azure Container Registry

```bash
# Create Azure Container Registry
az acr create \
  --resource-group nixernetes-rg \
  --name nixernetesregistry \
  --sku Standard

# Grant AKS access
az aks update \
  --name nixernetes-prod \
  --resource-group nixernetes-rg \
  --attach-acr nixernetesregistry
```

### Pattern 3: Azure Traffic Manager for Multi-Region

```bash
# Create Traffic Manager profile
az network traffic-manager profile create \
  --name nixernetes-tm \
  --resource-group nixernetes-rg \
  --routing-method geographic

# Add AKS endpoints
az network traffic-manager endpoint create \
  --name eastus-endpoint \
  --profile-name nixernetes-tm \
  --resource-group nixernetes-rg \
  --type azureEndpoints \
  --target myapp-eastus.eastus.cloudapp.azure.com
```

## Identity and Security

### Step 1: Configure Azure AD Integration

```bash
# Get cluster credentials
CLUSTER_NAME="nixernetes-prod"
RESOURCE_GROUP="nixernetes-rg"

# Create app registration
az ad app create --display-name "${CLUSTER_NAME}-admin"

# Get app ID
APP_ID=$(az ad app list --display-name "${CLUSTER_NAME}-admin" --query '[0].appId' -o tsv)

# Create service principal
az ad sp create --id $APP_ID

# Grant cluster admin role
CLUSTER_ID=$(az aks show -n $CLUSTER_NAME -g $RESOURCE_GROUP --query id -o tsv)

az role assignment create \
  --role "Azure Kubernetes Service Cluster Admin Role" \
  --assignee $APP_ID \
  --scope $CLUSTER_ID
```

### Step 2: Enable Azure Policy

Azure Policy is already enabled in the cluster creation. Assign policies:

```bash
# Assign built-in policy initiative
az policy assignment create \
  --name "Deploy-Kubernetes-Security" \
  --policy-set-definition-name "Kubernetes-cluster" \
  --scope "/subscriptions/SUBSCRIPTION_ID/resourcegroups/nixernetes-rg"
```

### Step 3: Configure RBAC

```nix
let
  rbac = import ./src/lib/rbac.nix { inherit lib; };
in
{
  # Read-only role for developers
  developerRole = rbac.mkRole {
    namespace = "production";
    name = "developer";
    
    rules = [
      {
        apiGroups = ["" "apps"];
        resources = ["pods" "pods/logs" "deployments" "services"];
        verbs = ["get" "list" "watch"];
      }
    ];
  };
  
  # Binding for Azure AD group
  roleBinding = rbac.mkRoleBinding {
    namespace = "production";
    name = "developer-binding";
    roleRef = { kind = "Role"; name = "developer"; };
    subjects = [{
      kind = "Group";
      name = "developers@example.com";
      apiGroup = "rbac.authorization.k8s.io";
    }];
  };
}
```

## Cost Optimization

### Step 1: Use Spot Instances

```bash
# Add spot node pool
az aks nodepool add \
  --resource-group nixernetes-rg \
  --cluster-name nixernetes-prod \
  --name spotnodepool \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --enable-cluster-autoscaler \
  --min-count 0 \
  --max-count 10 \
  --node-vm-size Standard_D4s_v5
```

### Step 2: Configure Resource Quotas

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  # Limit resources per namespace
  resourceQuota = {
    apiVersion = "v1";
    kind = "ResourceQuota";
    metadata = {
      namespace = "production";
      name = "production-quota";
    };
    spec = {
      hard = {
        "requests.cpu" = "50";
        "requests.memory" = "100Gi";
        "limits.cpu" = "100";
        "limits.memory" = "200Gi";
        "pods" = "100";
        "services.loadbalancers" = "2";
      };
    };
  };
}
```

## Monitoring and Diagnostics

### Step 1: Enable Azure Monitor

Monitoring is already enabled via the `--enable-addons monitoring` flag during cluster creation.

### Step 2: Create Custom Dashboards

```bash
# View cluster metrics
az monitor metrics list \
  --resource-group nixernetes-rg \
  --resource-type Microsoft.ContainerService/managedClusters \
  --resource nixernetes-prod \
  --metric "cpu" \
  --interval PT1M

# View container logs
az monitor log-analytics query \
  --workspace nixernetes-rg \
  --analytics-query "ContainerLogV2 | where PodName startswith 'myapp' | tail 10"
```

## Disaster Recovery

### Step 1: Configure Backup for Persistent Volumes

```bash
# Create Recovery Services vault
az backup vault create \
  --resource-group nixernetes-rg \
  --name nixernetes-vault \
  --location eastus

# Enable backup for AKS
az backup protection enable-for-vm \
  --resource-group nixernetes-rg \
  --vault-name nixernetes-vault \
  --vm nixernetes-prod-node
```

### Step 2: Create Backup Snapshots

```nix
let
  dr = import ./src/lib/disaster-recovery.nix { inherit lib; };
in
{
  backupPolicy = dr.mkBackupPolicy {
    namespace = "backup";
    name = "azure-backup";
    
    schedule = "0 2 * * *";
    retention = "30d";
  };
}
```

## Troubleshooting

### Issue: Pod Identity Not Working

**Solution**: Verify Pod Identity configuration

```bash
# Check Pod Identity controller
kubectl get pods -n kube-system | grep aad-pod-identity

# Check binding
kubectl get azureidentitybinding -A

# Verify secret mount
kubectl exec -it <pod-name> -- ls -la /var/run/secrets/
```

### Issue: Azure Key Vault Secret Not Mounting

**Solution**: Debug Secret Provider

```bash
# Check SecretProvider status
kubectl describe pod <pod-name> -n production

# View Secret Store CSI driver logs
kubectl logs -n kube-system -l app=secrets-store-csi-driver

# Verify Key Vault permissions
az keyvault show-deleted-vault --name nixernetes-vault
```

### Issue: AKS Nodes Not Ready

**Solution**: Check node status

```bash
# Describe nodes
kubectl describe nodes

# Check Azure VM status
az vm list -g nixernetes-rg -d

# View AKS cluster operations
az aks show -g nixernetes-rg -n nixernetes-prod --query provisioningState
```

## Summary

You now have:
✓ AKS cluster running Nixernetes
✓ Pod Identity for Azure resource access
✓ Key Vault integration for secrets
✓ Azure AD integration for authentication
✓ Network policies and security configured
✓ Monitoring and diagnostics enabled
✓ Disaster recovery backup configured
✓ Cost optimization in place

Next steps:
1. Deploy applications using Nixernetes modules
2. Configure Azure-specific services (Database, Cosmos DB, etc.)
3. Set up CI/CD with Azure DevOps
4. Monitor cluster performance and costs

