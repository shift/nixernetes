# GitOps Integration Guide

## Overview

The Nixernetes GitOps Framework provides declarative, infrastructure-as-code support for modern GitOps workflows. It integrates seamlessly with both **Flux v2** (lightweight, native Kubernetes) and **ArgoCD** (feature-rich, application-centric), enabling version-controlled, automated Kubernetes deployments.

**Key Features:**
- Flux v2 support (GitRepository, Kustomization, HelmRelease)
- ArgoCD support (Application, AppProject, Notification)
- Multi-cluster deployment patterns
- Repository management helpers
- Health monitoring and automated sync
- Configuration presets for different deployment styles

## Architecture

### Flux v2 (CNCF Graduated Project)

Flux is a lightweight, Kubernetes-native GitOps solution ideal for declarative infrastructure.

```
Git Repository
    ↓
GitRepository (polls for changes)
    ↓
Kustomization (applies manifests)
    ↓
Kubernetes Cluster
    ↓
Status & Notifications
```

**Characteristics:**
- Event-driven, pull-based updates
- CRD-based configuration
- Integrates with Kustomize, Helm
- Minimal resource overhead
- Strong RBAC integration

### ArgoCD (CNCF Incubating)

ArgoCD is a declarative continuous delivery solution with a web UI.

```
Git Repository
    ↓
AppProject (access control)
    ↓
Application (deployment config)
    ↓
Application Controller
    ↓
Kubernetes Cluster
    ↓
ArgoCDUI (visualization & control)
```

**Characteristics:**
- Web UI for visibility and control
- Declarative application management
- Automatic app-of-apps pattern support
- Web hook and polling support
- Multi-cluster and multi-tenancy support

## Usage Guide

### Flux v2: Basic Setup

#### 1. Create a Git Repository Source

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  gitRepo = gitops.mkGitRepository {
    name = "nixernetes-repo";
    url = "https://github.com/myorg/nixernetes-config";
    ref = { branch = "main"; };
    interval = "1m";
  };
}
```

**Result**: Flux polls GitHub every minute for changes

#### 2. Create a Kustomization

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  kustomization = gitops.mkKustomization {
    name = "nixernetes-kustomize";
    sourceRef = {
      kind = "GitRepository";
      name = "nixernetes-repo";
    };
    path = "./apps";
    interval = "10m";
    prune = true;
    wait = true;
  };
}
```

**Result**: Kustomizations in `./apps` are applied every 10 minutes

#### 3. Add Health Checks

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  kustomization = gitops.mkKustomization {
    name = "nixernetes-kustomize";
    sourceRef = { kind = "GitRepository"; name = "nixernetes-repo"; };
    path = "./apps";
    health = gitops.mkHealthChecks {
      kind = "Deployment";
      name = "app";
    };
  };
}
```

**Result**: Flux waits for Deployments to be healthy before considering sync complete

### Flux v2: Helm Support

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  # Add Helm repository
  helmRepo = gitops.mkHelmRepository {
    name = "bitnami";
    url = "https://charts.bitnami.com/bitnami";
  };

  # Deploy Helm chart
  helmRelease = gitops.mkHelmRelease {
    name = "postgres";
    namespace = "databases";
    chart = {
      name = "postgresql";
      version = "13.0.0";
    };
    sourceRef = {
      kind = "HelmRepository";
      name = "bitnami";
    };
    values = {
      auth.password = "secretpassword";
      primary.persistence.size = "50Gi";
    };
  };
}
```

**Result**: PostgreSQL chart from Bitnami deployed with custom values

### ArgoCD: Application Setup

#### 1. Create AppProject (Access Control)

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  appProject = gitops.mkAppProject {
    name = "platform-team";
    description = "Platform team's applications";
    sourceRepos = [
      "https://github.com/myorg/config"
    ];
    destinations = [
      { namespace = "production"; server = "https://kubernetes.default.svc"; }
      { namespace = "staging"; server = "https://kubernetes.default.svc"; }
    ];
    clusterResourceBlacklist = [
      { group = ""; kind = "ResourceQuota"; }
      { group = ""; kind = "NetworkPolicy"; }
    ];
  };
}
```

**Result**: Platform team can deploy to prod/staging, but can't modify NetworkPolicy

#### 2. Create Application

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  application = gitops.mkApplication {
    name = "my-app";
    namespace = "argocd";
    project = "platform-team";
    source = {
      repoURL = "https://github.com/myorg/config";
      path = "apps/my-app";
      targetRevision = "main";
    };
    destination = {
      namespace = "production";
    };
    syncPolicy = gitops.mkSyncPolicy {
      automated = true;
      syncOptions = [ "CreateNamespace=true" ];
    };
  };
}
```

**Result**: ArgoCD automatically syncs `apps/my-app` to production namespace

#### 3. Multi-App Deployment (App-of-Apps Pattern)

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  # Root application
  root = gitops.mkApplication {
    name = "cluster-bootstrap";
    project = "system";
    source = {
      repoURL = "https://github.com/myorg/config";
      path = "apps";
    };
    syncPolicy = gitops.mkSyncPolicy {
      automated = true;
    };
  };

  # This Application manages other Applications
  # Directory structure:
  # apps/
  #   └── my-app/
  #       ├── kustomization.yaml
  #       └── argocd.yaml  # Contains Application CRD
}
```

**Result**: Single Application manages entire cluster setup

## Repository Patterns

### Flat Structure (Simple, Recommended for Small Teams)

```
repos/
├── development/manifests/
│   ├── app1/
│   ├── app2/
│   └── kustomization.yaml
├── staging/manifests/
│   ├── app1/
│   ├── app2/
│   └── kustomization.yaml
└── production/manifests/
    ├── app1/
    ├── app2/
    └── kustomization.yaml
```

**Setup:**
```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  repository = gitops.mkGitOpsRepository {
    name = "platform-config";
    environments = ["development" "staging" "production"];
    structure = "flat";
  };
}
```

### Hierarchical Structure (Organized, Recommended for Large Teams)

```
clusters/
├── us-east-1/
│   ├── kubernetes/
│   │   ├── app1/
│   │   ├── app2/
│   │   └── kustomization.yaml
│   └── flux-system/
│       ├── helmrepositories/
│       └── kustomizations/
├── eu-west-1/
│   ├── kubernetes/
│   └── flux-system/
└── shared/
    └── base/
        ├── app1/
        └── app2/
```

**Setup:**
```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  repository = gitops.mkGitOpsRepository {
    name = "platform-config";
    environments = ["us-east-1" "eu-west-1"];
    structure = "hierarchy";
  };
}
```

## Deployment Patterns

### Single Cluster with Flux

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  deployment = gitops.mkSingleClusterDeployment {
    name = "platform";
    gitRepository = "https://github.com/myorg/config";
    path = "./apps";
    namespace = "default";
  };
}
```

### Multi-Cluster with ArgoCD

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  deployment = gitops.mkMultiClusterDeployment {
    name = "global-platform";
    gitRepository = "https://github.com/myorg/config";
    clusters = {
      "us-east-1" = {
        server = "https://us-east-cluster.example.com";
        path = "clusters/us-east-1";
      };
      "eu-west-1" = {
        server = "https://eu-west-cluster.example.com";
        path = "clusters/eu-west-1";
      };
      "ap-south-1" = {
        server = "https://ap-south-cluster.example.com";
        path = "clusters/ap-south-1";
      };
    };
  };
}
```

**Result**: Single GitOps repository manages 3 clusters automatically

## Configuration Presets

### Aggressive Sync (for development, every minute)

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  kustomization = gitops.mkKustomization {
    name = "dev-apps";
    sourceRef = { kind = "GitRepository"; name = "repo"; };
    path = "./dev";
  } // gitops.presets.aggressive;
}
```

**Settings**: 1m sync, immediate prune, wait for health

### Standard Sync (for staging, every 10 minutes)

```nix
{
  kustomization = gitops.mkKustomization {
    name = "staging-apps";
    sourceRef = { kind = "GitRepository"; name = "repo"; };
    path = "./staging";
  } // gitops.presets.standard;
}
```

**Settings**: 10m sync, prune after sync, wait for health

### Conservative Sync (for production, every hour)

```nix
{
  kustomization = gitops.mkKustomization {
    name = "prod-apps";
    sourceRef = { kind = "GitRepository"; name = "repo"; };
    path = "./prod";
  } // gitops.presets.conservative;
}
```

**Settings**: 1h sync, manual prune, don't wait for health (fast failure detection)

## Advanced Features

### Webhook Notifications

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  notification = gitops.mkWebhookNotification {
    url = "https://slack.example.com/hooks/deployment";
    insecureSkipVerify = false;
  };
}
```

### Health Monitoring

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  kustomization = gitops.mkKustomization {
    name = "app";
    sourceRef = { kind = "GitRepository"; name = "repo"; };
    health = [
      { apiVersion = "apps/v1"; kind = "Deployment"; name = "frontend"; }
      { apiVersion = "apps/v1"; kind = "StatefulSet"; name = "postgres"; }
    ];
  };
}
```

### Sync Policies

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  syncPolicy = gitops.mkSyncPolicy {
    automated = true;
    syncOptions = [
      "CreateNamespace=true"           # Create namespace if missing
      "PrunePropagationPolicy=orphan"  # Delete orphaned resources
      "RespectIgnoreDifferences=true"  # Ignore specified differences
    ];
  };
}
```

## Best Practices

### 1. Environment Separation
Keep dev, staging, and production completely separate:
- Different Git branches per environment
- Different namespaces per environment
- Different sync intervals per environment

### 2. Use AppProjects for Access Control
Restrict who can deploy what:
```nix
gitops.mkAppProject {
  name = "frontend-team";
  sourceRepos = ["https://github.com/myorg/frontend"];
  destinations = [
    { namespace = "frontend-dev"; }
    { namespace = "frontend-staging"; }
  ];
}
```

### 3. Automate Releases
Use GitOps for all deployments:
- No manual `kubectl apply`
- All changes in Git
- Audit trail via Git history
- Rollback via Git revert

### 4. Health Checks
Always define health checks for critical resources:
```nix
health = [
  { apiVersion = "apps/v1"; kind = "Deployment"; }
  { apiVersion = "v1"; kind = "Service"; }
]
```

### 5. Start Conservative
Begin with audit/manual sync, then automate:
```nix
validationFailureAction = "audit";  # First: observe
# Later, after validation:
validationFailureAction = "enforce"; # Enforce
```

### 6. Use Separate Repositories
- **Config repo**: Kubernetes manifests (gitops-config)
- **Application repo**: Application source code (app-source)
- **GitOps repo**: GitOps declarations (gitops-bootstrap)

## Integration with Nixernetes

### With Compliance

```nix
let
  compliance = import ./src/lib/compliance.nix { inherit lib; };
  gitops = import ./src/lib/gitops.nix { inherit lib; };
in
{
  # GitOps deployment with compliance labels
  application = gitops.mkApplication {
    name = "app";
    source = { repoURL = "..."; path = "./apps/app"; };
  };
  
  # Compliance labels applied to all resources
  labels = compliance.mkComplianceLabels {
    framework = "SOC2";
    level = "strict";
  };
}
```

### With Kyverno Policies

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  # GitOps ensures Kyverno policies are deployed
  policies = gitops.mkApplication {
    name = "security-policies";
    source = { repoURL = "..."; path = "./policies"; };
  };
  
  # Kyverno validates all deployments
  policyLibrary = kyverno.policyLibrary.securityBaseline;
}
```

### With Cost Analysis

```nix
let
  gitops = import ./src/lib/gitops.nix { inherit lib; };
  costAnalysis = import ./src/lib/cost-analysis.nix { inherit lib; };
in
{
  # Deploy applications via GitOps
  application = gitops.mkApplication { /* ... */ };
  
  # Analyze costs of deployed resources
  costs = costAnalysis.mkCostSummary {
    deployments = { /* ... */ };
  };
}
```

## Troubleshooting

### Sync Not Happening
1. Check GitRepository status: `kubectl describe gitrepository -n flux-system`
2. Check Kustomization status: `kubectl describe kustomization -n flux-system`
3. Review logs: `kubectl logs -n flux-system deployment/source-controller`

### ArgoCD Application Out of Sync
1. Check Application status: `kubectl describe application -n argocd`
2. Refresh manually: `argocd app sync app-name`
3. Check server connection: `argocd cluster list`

### Webhook Not Firing
1. Verify webhook URL is reachable
2. Check Events: `kubectl get events -n flux-system --sort-by='.lastTimestamp'`
3. Review notification logs

## Related Documentation

- [Flux v2 Official Docs](https://fluxcd.io/)
- [ArgoCD Official Docs](https://argo-cd.readthedocs.io/)
- [GitOps Best Practices](https://www.gitops.tech/)
- [Kyverno Policies](./KYVERNO.md)
- [Compliance Framework](./README.md#compliance)

## License

The GitOps Integration Framework is part of the Nixernetes project.
