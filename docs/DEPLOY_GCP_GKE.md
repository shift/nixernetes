# GCP GKE Deployment Guide

Complete guide for deploying Nixernetes on Google Kubernetes Engine (GKE).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Project and Cluster Setup](#project-and-cluster-setup)
3. [Nixernetes Integration](#nixernetes-integration)
4. [Deployment Patterns](#deployment-patterns)
5. [IAM and Security](#iam-and-security)
6. [Cost Optimization](#cost-optimization)
7. [Monitoring and Logging](#monitoring-and-logging)
8. [Disaster Recovery](#disaster-recovery)
9. [Troubleshooting](#troubleshooting)

## Prerequisites

### GCP Account Setup
- Active GCP project with billing enabled
- gcloud CLI installed and authenticated
- Appropriate IAM permissions (Kubernetes Engine Admin, Compute Admin)

### Local Tools
- gcloud >= 1.0
- kubectl >= 1.28
- helm >= 3.12
- Nix and direnv

### Verify Setup

```bash
# Check gcloud configuration
gcloud auth list
gcloud config list

# Set project
gcloud config set project my-project-id

# Verify permissions
gcloud projects get-iam-policy $(gcloud config get-value project)
```

## Project and Cluster Setup

### Step 1: Create GCP Project Configuration

Create `gcp-config.nix`:

```nix
{
  # Project settings
  projectId = "my-project-id";
  region = "us-central1";
  zone = "us-central1-a";
  
  # Cluster settings
  clusterName = "nixernetes-prod";
  clusterVersion = "1.30";
  
  # Network settings
  networkName = "nixernetes-network";
  subnetName = "nixernetes-subnet";
  
  primaryIpRange = "10.0.0.0/20";
  secondaryIpRange = "10.4.0.0/14";  # Pods
  secondaryServicesRange = "10.0.16.0/20";  # Services
  
  # Node pool settings
  nodePools = {
    default = {
      desiredNodeCount = 3;
      minNodeCount = 1;
      maxNodeCount = 10;
      machineType = "n2-standard-4";
      diskSizeGb = 100;
      oauthScopes = [
        "https://www.googleapis.com/auth/compute"
        "https://www.googleapis.com/auth/devstorage.read_only"
        "https://www.googleapis.com/auth/logging.write"
        "https://www.googleapis.com/auth/monitoring"
        "https://www.googleapis.com/auth/servicecontrol"
        "https://www.googleapis.com/auth/service.management.readonly"
        "https://www.googleapis.com/auth/trace.append"
      ];
      labels = { workload = "general"; };
    };
    
    compute = {
      desiredNodeCount = 2;
      minNodeCount = 0;
      maxNodeCount = 20;
      machineType = "c2-standard-8";
      diskSizeGb = 150;
      preemptible = false;
      taints = [{ key = "workload"; value = "compute"; effect = "NoSchedule"; }];
      labels = { workload = "compute"; };
    };
  };
  
  # GKE Add-ons
  addons = {
    httpLoadBalancing = true;
    horizontalPodAutoscaling = true;
    verticalPodAutoscaling = true;
    networkPolicy = true;
    intraNodeVisibility = true;
    cloudLogging = true;
    cloudMonitoring = true;
  };
  
  # Security
  masterAuthorizedNetworks = [
    { name = "office"; cidrBlock = "203.0.113.0/24"; }
    { name = "vpn"; cidrBlock = "198.51.100.0/24"; }
  ];
  
  masterIpv4CidrBlock = "172.16.0.0/28";
  
  enablePodSecurityPolicy = true;
  enableNetworkPolicy = true;
  
  # Labels
  labels = {
    environment = "production";
    managed-by = "nixernetes";
  };
}
```

### Step 2: Create GCP Network and Cluster

```bash
#!/bin/bash

PROJECT_ID="my-project-id"
REGION="us-central1"
ZONE="us-central1-a"
NETWORK="nixernetes-network"
SUBNET="nixernetes-subnet"
CLUSTER="nixernetes-prod"

# Enable required APIs
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable monitoring.googleapis.com
gcloud services enable logging.googleapis.com

# Create VPC network
gcloud compute networks create $NETWORK \
  --subnet-mode=custom \
  --region=$REGION

# Create subnet
gcloud compute networks subnets create $SUBNET \
  --network=$NETWORK \
  --region=$REGION \
  --range=10.0.0.0/20 \
  --secondary-range pods=10.4.0.0/14 \
  --secondary-range services=10.0.16.0/20

# Create GKE cluster
gcloud container clusters create $CLUSTER \
  --project=$PROJECT_ID \
  --region=$REGION \
  --node-locations=$ZONE \
  --network=$NETWORK \
  --subnetwork=$SUBNET \
  --cluster-secondary-range-name=pods \
  --services-secondary-range-name=services \
  --cluster-version=1.30 \
  --machine-type=n2-standard-4 \
  --num-nodes=3 \
  --min-nodes=1 \
  --max-nodes=10 \
  --enable-autoscaling \
  --enable-autorepair \
  --enable-autoupgrade \
  --enable-ip-alias \
  --enable-network-policy \
  --enable-intra-node-visibility \
  --enable-stackdriver-kubernetes \
  --addons=HttpLoadBalancing,HorizontalPodAutoscaling,VerticalPodAutoscaling \
  --workload-pool=$PROJECT_ID.svc.id.goog \
  --enable-shielded-nodes

# Get credentials
gcloud container clusters get-credentials $CLUSTER \
  --region=$REGION \
  --project=$PROJECT_ID

# Verify cluster
kubectl get nodes
kubectl get svc -A
```

## Nixernetes Integration

### Step 1: Create Nixernetes GKE Configuration

Create `nixernetes-gke.nix`:

```nix
{ lib, pkgs }:

let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  security = import ./src/lib/security-policies.nix { inherit lib; };
  gitops = import ./src/lib/gitops.nix { inherit lib; };
  monitoring = import ./src/lib/performance-analysis.nix { inherit lib; };
  
  projectId = "my-project-id";
  
in
{
  # Create nixernetes namespace
  namespace = k8s.mkNamespace {
    name = "nixernetes";
    labels = {
      "app.kubernetes.io/managed-by" = "nixernetes";
    };
  };
  
  # Service Account with Workload Identity
  serviceAccount = k8s.mkServiceAccount {
    namespace = "nixernetes";
    name = "nixernetes-sa";
    annotations = {
      "iam.gke.io/gcp-service-account" = "nixernetes@${projectId}.iam.gserviceaccount.com";
    };
  };
  
  # Network Policy - Default Deny
  networkPolicyDeny = security.mkDefaultDenyNetworkPolicy {
    namespace = "default";
    name = "default-deny-all";
  };
  
  # Monitoring
  monitoring = monitoring.mkPerformanceAnalysis {
    namespace = "monitoring";
    name = "gke-monitoring";
    metrics = ["cpu" "memory" "network" "disk"];
  };
}
```

### Step 2: Set Up Workload Identity

```bash
PROJECT_ID="my-project-id"
GSA_NAME="nixernetes"
KSA_NAME="nixernetes-sa"
KSA_NAMESPACE="nixernetes"

# Create GCP service account
gcloud iam service-accounts create $GSA_NAME \
  --project=$PROJECT_ID

# Grant permissions
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com" \
  --role="roles/container.developer"

# Bind Kubernetes SA to GCP SA
gcloud iam service-accounts add-iam-policy-binding \
  ${GSA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com \
  --role="roles/iam.workloadIdentityUser" \
  --member="serviceAccount:${PROJECT_ID}.svc.id.goog[${KSA_NAMESPACE}/${KSA_NAME}]"
```

### Step 3: Deploy Applications

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  
  projectId = "my-project-id";
  
in
{
  # Example deployment with Cloud SQL proxy
  deployment = k8s.mkDeployment {
    namespace = "production";
    name = "myapp";
    
    replicas = 3;
    
    serviceAccountName = "myapp-sa";
    
    containers = [
      {
        name = "app";
        image = "gcr.io/${projectId}/myapp:latest";
        
        ports = [{ containerPort = 8080; }];
        
        env = [
          { name = "ENVIRONMENT"; value = "production"; }
          { name = "GOOGLE_CLOUD_PROJECT"; value = projectId; }
        ];
        
        resources = {
          requests = { cpu = "500m"; memory = "512Mi"; };
          limits = { cpu = "1000m"; memory = "1Gi"; };
        };
      }
      
      # Cloud SQL proxy sidecar
      {
        name = "cloud-sql-proxy";
        image = "gcr.io/cloud-sql-connectors/cloud-sql-proxy:2.0";
        
        args = [
          "PROJECT_ID:REGION:INSTANCE_NAME"
          "--port=5432"
        ];
        
        securityContext = {
          runAsNonRoot = true;
        };
      }
    ];
  };
}
```

## Deployment Patterns

### Pattern 1: Autopilot Cluster

GKE Autopilot manages infrastructure for you:

```bash
gcloud container clusters create-auto nixernetes-autopilot \
  --region=us-central1 \
  --project=my-project-id \
  --enable-network-policy \
  --enable-intra-node-visibility \
  --addons=HttpLoadBalancing,HorizontalPodAutoscaling
```

### Pattern 2: Multi-Region Deployment

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  
in
{
  # Deployment in us-central1
  us-central = k8s.mkDeployment {
    namespace = "production";
    name = "myapp-us-central";
    replicas = 3;
    nodeSelector = { region = "us-central1"; };
    containers = [{ image = "myapp:latest"; }];
  };
  
  # Deployment in europe-west1
  eu-west = k8s.mkDeployment {
    namespace = "production";
    name = "myapp-eu-west";
    replicas = 3;
    nodeSelector = { region = "europe-west1"; };
    containers = [{ image = "myapp:latest"; }];
  };
}
```

### Pattern 3: Integration with Cloud Run

Deploy serverless functions alongside Kubernetes apps:

```bash
# Deploy function
gcloud functions deploy my-function \
  --runtime=python39 \
  --trigger-http \
  --allow-unauthenticated

# Invoke from Kubernetes
curl https://us-central1-my-project-id.cloudfunctions.net/my-function
```

## IAM and Security

### Step 1: Configure Pod Security Policy

```nix
let
  security = import ./src/lib/security-policies.nix { inherit lib; };
in
{
  restrictedPolicy = security.mkPodSecurityPolicy {
    name = "restricted";
    level = "high";
    
    allowPrivilegeEscalation = false;
    allowedCapabilities = [];
    defaultAddCapabilities = [];
    requiredDropCapabilities = ["ALL"];
    
    runAsUser = {
      rule = "MustRunAsNonRoot";
    };
    
    fsGroup = {
      rule = "MustRunAs";
      ranges = [{ min = 1; max = 65535; }];
    };
    
    readOnlyRootFilesystem = true;
    hostPID = false;
    hostIPC = false;
    hostNetwork = false;
  };
}
```

### Step 2: Configure RBAC

```bash
# Create cluster role for developers
kubectl create clusterrole developer \
  --verb=get,list,watch,create,update,patch \
  --resource=pods,services,deployments

# Create role binding
kubectl create clusterrolebinding developer-binding \
  --clusterrole=developer \
  --group=developers@example.com
```

## Cost Optimization

### Step 1: Use Preemptible Instances

```bash
# Create node pool with preemptible instances
gcloud container node-pools create preemptible-pool \
  --cluster=nixernetes-prod \
  --region=us-central1 \
  --preemptible \
  --num-nodes=2 \
  --machine-type=n2-standard-4 \
  --enable-autoscaling \
  --min-nodes=0 \
  --max-nodes=10
```

### Step 2: Configure Pod Disruption Budgets

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  # Allow only 1 unavailable pod during disruptions
  pdb = {
    apiVersion = "policy/v1";
    kind = "PodDisruptionBudget";
    metadata = {
      namespace = "production";
      name = "myapp-pdb";
    };
    spec = {
      minAvailable = 2;
      selector = {
        matchLabels = { app = "myapp"; };
      };
    };
  };
}
```

## Monitoring and Logging

### Step 1: Configure Google Cloud Logging

```nix
let
  monitoring = import ./src/lib/performance-analysis.nix { inherit lib; };
in
{
  loggingConfig = monitoring.mkPerformanceAnalysis {
    namespace = "monitoring";
    name = "cloud-logging";
    
    logLevel = "INFO";
    logExports = [
      "projects/my-project-id/logs/stdout"
      "projects/my-project-id/logs/stderr"
    ];
  };
}
```

### Step 2: Deploy Monitoring Dashboard

```bash
# Create monitoring dashboard
gcloud monitoring dashboards create --config-from-file=dashboard.json
```

Create `dashboard.json`:

```json
{
  "displayName": "Nixernetes GKE Dashboard",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "CPU Usage",
          "xyChart": {
            "dataSets": [
              {
                "timeSeriesQuery": {
                  "timeSeriesFilter": {
                    "filter": "resource.type=\"k8s_container\" metric.type=\"kubernetes.io/container/cpu/core_usage_time\"",
                    "aggregation": {
                      "alignmentPeriod": "60s"
                    }
                  }
                }
              }
            ]
          }
        }
      }
    ]
  }
}
```

## Disaster Recovery

### Step 1: Configure GKE Backup

```bash
# Enable GKE Backup
gcloud container backup-restore backup-plans create \
  nixernetes-backup-plan \
  --cluster=projects/my-project-id/locations/us-central1/clusters/nixernetes-prod \
  --location=us-central1 \
  --all-namespaces \
  --cron-schedule='0 2 * * *'
```

### Step 2: Create Restore Plan

```bash
gcloud container backup-restore restore-plans create \
  nixernetes-restore-plan \
  --backup-plan=nixernetes-backup-plan \
  --location=us-central1 \
  --cluster=projects/my-project-id/locations/us-central1/clusters/nixernetes-prod
```

## Troubleshooting

### Issue: Workload Identity Not Working

**Solution**: Verify service account binding

```bash
# Check KSA annotation
kubectl get sa nixernetes-sa -n nixernetes -o yaml

# Verify GSA binding
gcloud iam service-accounts get-iam-policy \
  nixernetes@my-project-id.iam.gserviceaccount.com

# Test token binding
kubectl run -it --image=gcr.io/google.com/cloudsdktool/cloud-sdk:slim \
  --serviceaccount=nixernetes-sa \
  --namespace=nixernetes \
  test-pod -- gcloud auth list
```

### Issue: Pod Cannot Access Cloud SQL

**Solution**: Verify Cloud SQL Proxy configuration

```bash
# Check proxy logs
kubectl logs -n production <pod-name> -c cloud-sql-proxy

# Verify instance connectivity
gcloud sql connect INSTANCE_NAME --user=root
```

### Issue: Nodes Not Ready

**Solution**: Check node conditions

```bash
# Describe nodes
kubectl describe nodes

# Check node logs
gcloud logging read "resource.type=k8s_node" --limit 50

# Check GKE metrics
gcloud container operations list --zone=us-central1-a
```

## Summary

You now have:
✓ GKE cluster running Nixernetes
✓ Workload Identity for secure GCP access
✓ Network policies and security configured
✓ Multi-region deployment ready
✓ Monitoring and logging in place
✓ Backup and restore configured
✓ Cost optimization enabled

Next steps:
1. Deploy applications using Nixernetes modules
2. Configure Cloud SQL and managed services
3. Set up continuous deployment with GKE
4. Monitor cluster health and costs

