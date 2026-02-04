# AWS EKS Deployment Guide

Complete guide for deploying Nixernetes on Amazon Elastic Kubernetes Service (EKS).

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Infrastructure Setup](#infrastructure-setup)
3. [Cluster Configuration](#cluster-configuration)
4. [Nixernetes Integration](#nixernetes-integration)
5. [Deployment Patterns](#deployment-patterns)
6. [IAM and Security](#iam-and-security)
7. [Cost Optimization](#cost-optimization)
8. [Monitoring and Logging](#monitoring-and-logging)
9. [Disaster Recovery](#disaster-recovery)
10. [Troubleshooting](#troubleshooting)

## Prerequisites

### AWS Account Setup
- Active AWS account with appropriate permissions
- AWS CLI v2 installed and configured
- IAM user with EKS, EC2, IAM, VPC, and CloudFormation permissions

### Local Tools
- Nix and direnv installed
- kubectl >= 1.28
- helm >= 3.12
- eksctl >= 0.170
- aws-cli >= 2.13

### Verify Prerequisites
```bash
# Check tool versions
aws --version
eksctl version
kubectl version --client
helm version

# Verify AWS credentials
aws sts get-caller-identity
```

## Infrastructure Setup

### Step 1: Prepare AWS Environment

Create a file `aws-env.nix` to define your AWS configuration:

```nix
{
  # AWS Region
  region = "us-east-1";
  
  # Cluster Configuration
  clusterName = "nixernetes-prod";
  clusterVersion = "1.30";
  
  # Networking
  vpcCidr = "10.0.0.0/16";
  privateSubnets = [
    { cidr = "10.0.1.0/24"; az = "us-east-1a"; }
    { cidr = "10.0.2.0/24"; az = "us-east-1b"; }
    { cidr = "10.0.3.0/24"; az = "us-east-1c"; }
  ];
  publicSubnets = [
    { cidr = "10.0.101.0/24"; az = "us-east-1a"; }
    { cidr = "10.0.102.0/24"; az = "us-east-1b"; }
    { cidr = "10.0.103.0/24"; az = "us-east-1c"; }
  ];
  
  # Node Groups
  nodeGroups = {
    general = {
      desiredSize = 3;
      minSize = 2;
      maxSize = 10;
      instanceTypes = ["t3.medium"];
      diskSize = 100;
      taints = [];
      labels = { workload = "general"; };
    };
    
    compute = {
      desiredSize = 2;
      minSize = 1;
      maxSize = 20;
      instanceTypes = ["c5.xlarge"];
      diskSize = 150;
      taints = [{ key = "workload"; value = "compute"; effect = "NoSchedule"; }];
      labels = { workload = "compute"; };
    };
  };
  
  # Add-ons
  addons = {
    vpc-cni = {
      version = "latest";
    };
    coredns = {
      version = "latest";
    };
    kube-proxy = {
      version = "latest";
    };
    ebs-csi-driver = {
      version = "latest";
    };
  };
  
  # Logging
  logging = {
    enabled = true;
    types = ["api" "audit" "authenticator" "controllerManager" "scheduler"];
    logGroupRetention = 30;
  };
  
  # Tags
  tags = {
    Environment = "production";
    ManagedBy = "nixernetes";
    Team = "platform";
  };
}
```

### Step 2: Create EKS Cluster with eksctl

Using the above configuration:

```bash
# Create cluster
eksctl create cluster \
  --name nixernetes-prod \
  --region us-east-1 \
  --version 1.30 \
  --nodegroup-name general \
  --node-type t3.medium \
  --nodes 3 \
  --nodes-min 2 \
  --nodes-max 10 \
  --enable-ssm \
  --enable-ipv6 \
  --vpc-cidr 10.0.0.0/16 \
  --with-oidc \
  --tags Environment=production,ManagedBy=nixernetes

# Verify cluster
kubectl get nodes
kubectl get svc -A
```

### Step 3: Configure kubeconfig

```bash
# Update kubeconfig
aws eks update-kubeconfig \
  --name nixernetes-prod \
  --region us-east-1

# Verify access
kubectl auth can-i list nodes
```

## Cluster Configuration

### Step 1: Create Nixernetes Configuration

Create `nixernetes-eks.nix`:

```nix
{ lib, pkgs }:

let
  # Import Nixernetes modules
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  security = import ./src/lib/security-policies.nix { inherit lib; };
  perf = import ./src/lib/performance-analysis.nix { inherit lib; };
  observ = import ./src/lib/cost-analysis.nix { inherit lib; };
  
  # AWS-specific configuration
  awsRegion = "us-east-1";
  awsAccountId = "123456789012";
  
in
{
  # AWS Load Balancer Controller
  awsLoadBalancerController = k8s.mkDeployment {
    namespace = "kube-system";
    name = "aws-load-balancer-controller";
    
    labels = {
      app = "aws-load-balancer-controller";
      "app.kubernetes.io/name" = "aws-load-balancer-controller";
    };
    
    replicas = 2;
    
    serviceAccountName = "aws-load-balancer-controller";
    
    containers = [{
      name = "controller";
      image = "602401143452.dkr.ecr.${awsRegion}.amazonaws.com/amazon-k8s-aws-load-balancer-controller:v2.7.0";
      
      ports = [
        { name = "webhook"; containerPort = 9443; }
        { name = "metrics"; containerPort = 8080; }
      ];
      
      args = [
        "--cluster-name=nixernetes-prod"
        "--aws-region=${awsRegion}"
      ];
      
      resources = {
        requests = { cpu = "100m"; memory = "100Mi"; };
        limits = { cpu = "200m"; memory = "500Mi"; };
      };
      
      volumeMounts = [{
        name = "webhook-certs";
        mountPath = "/tmp/k8s-webhook-server/serving-certs";
        readOnly = true;
      }];
    }];
    
    volumes = [{
      name = "webhook-certs";
      secret = {
        secretName = "aws-load-balancer-webhook-tls";
      };
    }];
  };
  
  # EBS CSI Driver
  ebsCsiDriver = k8s.mkDeployment {
    namespace = "kube-system";
    name = "ebs-csi-controller";
    replicas = 2;
    
    serviceAccountName = "ebs-csi-controller-sa";
    
    containers = [{
      name = "ebs-plugin";
      image = "602401143452.dkr.ecr.${awsRegion}.amazonaws.com/ebs-csi-driver:v1.24.0";
      
      args = [
        "controller"
        "--endpoint=unix:///var/lib/csi/sockets/pluginproxy/csi.sock"
      ];
      
      volumeMounts = [{
        name = "socket-dir";
        mountPath = "/var/lib/csi/sockets/pluginproxy";
      }];
    }];
    
    volumes = [{
      name = "socket-dir";
      emptyDir = {};
    }];
  };
  
  # Network Policy
  networkPolicy = security.mkDefaultDenyNetworkPolicy {
    namespace = "default";
    name = "default-deny";
  };
  
  # Performance Monitoring
  performanceMonitoring = perf.mkPerformanceAnalysis {
    namespace = "monitoring";
    name = "eks-performance";
    metrics = ["cpu" "memory" "network" "disk"];
  };
  
  # Cost Analysis
  costAnalysis = observ.mkCostAnalysis {
    namespace = "monitoring";
    name = "eks-costs";
    services = ["ec2" "ebs" "nat-gateway" "data-transfer"];
  };
}
```

### Step 2: Deploy with Nixernetes

```bash
# Evaluate configuration
nix eval ./nixernetes-eks.nix --json > deployment.json

# Generate YAML
nix eval ./nixernetes-eks.nix --json | jq . > resources.json

# Apply to cluster
kubectl apply -f - < <(nix eval ./nixernetes-eks.nix --json | jq .)
```

## Nixernetes Integration

### Step 1: Set Up IAM Roles for Service Accounts (IRSA)

```bash
# Enable OIDC provider
eksctl utils associate-iam-oidc-provider \
  --cluster=nixernetes-prod \
  --region=us-east-1 \
  --approve

# Create IAM role for Nixernetes
eksctl create iamserviceaccount \
  --cluster=nixernetes-prod \
  --namespace=nixernetes \
  --name=nixernetes-sa \
  --attach-policy-arn=arn:aws:iam::aws:policy/AdministratorAccess \
  --approve
```

### Step 2: Create Nixernetes Namespace

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  namespace = k8s.mkNamespace {
    name = "nixernetes";
    labels = {
      "app.kubernetes.io/managed-by" = "nixernetes";
    };
  };
  
  serviceAccount = k8s.mkServiceAccount {
    namespace = "nixernetes";
    name = "nixernetes-sa";
    annotations = {
      "eks.amazonaws.com/role-arn" = "arn:aws:iam::123456789012:role/nixernetes-sa";
    };
  };
}
```

### Step 3: Deploy Core Nixernetes Modules

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  db = import ./src/lib/database-management.nix { inherit lib; };
  events = import ./src/lib/event-processing.nix { inherit lib; };
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  # RDS for PostgreSQL (use AWS RDS instead of Kubernetes)
  # Nixernetes can manage RDS configuration
  
  # Event streaming with MSK (Amazon Managed Streaming for Kafka)
  # Nixernetes manages consumers and topics
  
  # ArgoCD for GitOps
  argocd = gitops.mkArgoCD {
    namespace = "argocd";
    name = "argocd";
    
    server = {
      replicas = 2;
      service = "LoadBalancer";
    };
    
    config = {
      url = "https://argocd.example.com";
      ingress = {
        enabled = true;
        className = "alb";
        hosts = ["argocd.example.com"];
      };
    };
  };
}
```

## Deployment Patterns

### Pattern 1: Multi-Environment Deployment

```nix
# environments.nix
{ lib, environment }:

let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  
  envConfig = {
    dev = {
      replicas = 1;
      nodeSelector = { workload = "general"; };
      resources = {
        requests = { cpu = "100m"; memory = "128Mi"; };
        limits = { cpu = "500m"; memory = "256Mi"; };
      };
    };
    
    staging = {
      replicas = 2;
      nodeSelector = { workload = "general"; };
      resources = {
        requests = { cpu = "250m"; memory = "256Mi"; };
        limits = { cpu = "1000m"; memory = "512Mi"; };
      };
    };
    
    production = {
      replicas = 3;
      nodeSelector = { workload = "compute"; };
      podAntiAffinity = true;
      resources = {
        requests = { cpu = "500m"; memory = "512Mi"; };
        limits = { cpu = "2000m"; memory = "1Gi"; };
      };
    };
  };
  
  config = envConfig.${environment};
  
in
{
  deployment = k8s.mkDeployment {
    namespace = environment;
    name = "myapp";
    replicas = config.replicas;
    nodeSelector = config.nodeSelector;
    resources = config.resources;
    
    containers = [{
      image = "myapp:latest";
      ports = [{ containerPort = 8080; }];
    }];
  };
}
```

### Pattern 2: Auto-Scaling Configuration

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  
in
{
  deployment = k8s.mkDeployment {
    namespace = "production";
    name = "scalable-app";
    
    # Initial replicas
    replicas = 3;
    
    containers = [{
      image = "myapp:latest";
      resources = {
        requests = { cpu = "500m"; memory = "512Mi"; };
        limits = { cpu = "1000m"; memory = "1Gi"; };
      };
    }];
  };
  
  # Horizontal Pod Autoscaler
  hpa = {
    apiVersion = "autoscaling/v2";
    kind = "HorizontalPodAutoscaler";
    metadata = {
      namespace = "production";
      name = "scalable-app-hpa";
    };
    spec = {
      scaleTargetRef = {
        apiVersion = "apps/v1";
        kind = "Deployment";
        name = "scalable-app";
      };
      minReplicas = 2;
      maxReplicas = 10;
      metrics = [
        {
          type = "Resource";
          resource = {
            name = "cpu";
            target = {
              type = "Utilization";
              averageUtilization = 70;
            };
          };
        }
      ];
    };
  };
}
```

### Pattern 3: Database with RDS

```nix
# Use AWS Systems Manager Parameter Store for RDS endpoint
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  
in
{
  # Create secret from RDS credentials
  dbSecret = k8s.mkSecret {
    namespace = "databases";
    name = "rds-postgres";
    type = "Opaque";
    
    data = {
      # Reference from AWS Secrets Manager
      host = "mydb.c9akciq32.us-east-1.rds.amazonaws.com";
      port = "5432";
      username = "postgres";
      password = ""; # Load from AWS Secrets Manager
    };
  };
  
  # Application connecting to RDS
  app = k8s.mkDeployment {
    namespace = "production";
    name = "app";
    
    containers = [{
      image = "myapp:latest";
      
      env = [
        { name = "DB_HOST"; valueFrom = { secretKeyRef = { name = "rds-postgres"; key = "host"; }; }; }
        { name = "DB_PORT"; valueFrom = { secretKeyRef = { name = "rds-postgres"; key = "port"; }; }; }
        { name = "DB_USER"; valueFrom = { secretKeyRef = { name = "rds-postgres"; key = "username"; }; }; }
        { name = "DB_PASS"; valueFrom = { secretKeyRef = { name = "rds-postgres"; key = "password"; }; }; }
      ];
    }];
  };
}
```

## IAM and Security

### Step 1: Create IAM Policies for Nixernetes

```bash
# Create policy for Nixernetes service account
aws iam create-policy \
  --policy-name NixernetesPolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "ec2:DescribeInstances",
          "autoscaling:DescribeAutoScalingGroups",
          "elasticloadbalancing:DescribeLoadBalancers"
        ],
        "Resource": "*"
      }
    ]
  }'
```

### Step 2: Configure Network Policies

```nix
let
  security = import ./src/lib/security-policies.nix { inherit lib; };
in
{
  # Deny all ingress by default
  denyAllIngress = security.mkDefaultDenyNetworkPolicy {
    namespace = "production";
    name = "deny-all-ingress";
  };
  
  # Allow specific ingress
  allowAppIngress = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata = {
      namespace = "production";
      name = "allow-app-ingress";
    };
    spec = {
      podSelector = {
        matchLabels = { app = "myapp"; };
      };
      policyTypes = ["Ingress"];
      ingress = [{
        from = [
          {
            podSelector = {
              matchLabels = { role = "frontend"; };
            };
          }
        ];
        ports = [{
          protocol = "TCP";
          port = 8080;
        }];
      }];
    };
  };
}
```

## Cost Optimization

### Step 1: Use Spot Instances for Non-Critical Workloads

```bash
# Create spot node group
eksctl create nodegroup \
  --cluster=nixernetes-prod \
  --name=spot-instances \
  --spot \
  --instance-types=m5.large,m5.xlarge,m5a.large \
  --nodes=2 \
  --nodes-min=1 \
  --nodes-max=10
```

### Step 2: Configure Resource Requests/Limits

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  deployment = k8s.mkDeployment {
    namespace = "production";
    name = "optimized-app";
    
    containers = [{
      image = "myapp:latest";
      
      # Right-sized requests prevent over-provisioning
      resources = {
        requests = {
          cpu = "100m";      # Start small
          memory = "128Mi";
        };
        limits = {
          cpu = "500m";      # Cap at reasonable limit
          memory = "512Mi";
        };
      };
    }];
  };
}
```

## Monitoring and Logging

### Step 1: Configure CloudWatch

```bash
# Enable EKS control plane logging
aws eks update-cluster-logging --name nixernetes-prod \
  --logging '{"clusterLogging":[{"types":["api","audit","authenticator","controllerManager","scheduler"],"enabled":true}]}' \
  --region us-east-1
```

### Step 2: Deploy Prometheus and Grafana

```nix
let
  perf = import ./src/lib/performance-analysis.nix { inherit lib; };
in
{
  prometheus = perf.mkPrometheus {
    namespace = "monitoring";
    name = "prometheus";
    
    storage = "50Gi";
    
    remoteWrite = {
      url = "https://monitoring.us-east-1.amazonaws.com/api/v1/write";
    };
  };
}
```

### Step 3: Setup Container Insights

```bash
# Deploy Container Insights for EKS
eksctl utils write-logs \
  --cluster=nixernetes-prod \
  --region=us-east-1 \
  --logRetentionDays=30 \
  --enable-logging \
  --types=all
```

## Disaster Recovery

### Step 1: Configure Backup with Velero

```bash
# Install Velero
eksctl utils install-velero \
  --cluster=nixernetes-prod \
  --region=us-east-1 \
  --bucket=my-velero-bucket \
  --secret-file=credentials-velero
```

### Step 2: Create Backup Schedule

```nix
let
  dr = import ./src/lib/disaster-recovery.nix { inherit lib; };
in
{
  backupSchedule = dr.mkBackupPolicy {
    namespace = "velero";
    name = "daily-backup";
    
    schedule = "0 2 * * *";
    retention = "30d";
    
    includedNamespaces = ["*"];
    excludedNamespaces = ["kube-system" "kube-node-lease"];
  };
}
```

## Troubleshooting

### Issue: Pod Cannot Access AWS Resources

**Solution**: Verify IRSA configuration

```bash
# Check service account annotation
kubectl describe sa nixernetes-sa -n nixernetes

# Verify IAM role trust relationship
aws iam get-role --role-name nixernetes-sa

# Check pod environment
kubectl exec -it <pod-name> -n nixernetes -- env | grep AWS
```

### Issue: Load Balancer Not Getting IP

**Solution**: Ensure AWS Load Balancer Controller is installed

```bash
# Check controller logs
kubectl logs -n kube-system deploy/aws-load-balancer-controller

# Verify ingress
kubectl get ingress -A
kubectl describe ing <ingress-name> -n <namespace>
```

### Issue: EBS Volume Not Mounting

**Solution**: Verify EBS CSI Driver

```bash
# Check driver status
kubectl get ds -n kube-system ebs-csi-node

# Check PVC status
kubectl get pvc -A
kubectl describe pvc <pvc-name> -n <namespace>
```

## Summary

You now have:
✓ EKS cluster running Nixernetes
✓ Proper IAM and RBAC configuration
✓ Networking and security policies
✓ Monitoring and logging
✓ Disaster recovery backup
✓ Cost optimization in place
✓ Production-ready deployment

Next steps:
1. Deploy your applications using Nixernetes modules
2. Configure auto-scaling for workloads
3. Set up CI/CD with GitOps
4. Monitor and optimize costs

