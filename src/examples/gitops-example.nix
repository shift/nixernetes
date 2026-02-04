# Example: GitOps Deployments (Flux v2 & ArgoCD)
#
# This example demonstrates production-ready GitOps configurations using both
# Flux v2 (lightweight, event-driven) and ArgoCD (feature-rich, UI-driven)
#
# Includes:
# - Single cluster deployment (Flux)
# - Multi-cluster deployment (ArgoCD)
# - Helm releases
# - Health monitoring
# - Environment-specific sync policies

{ lib }:

let
  gitops = import ../lib/gitops.nix { inherit lib; };

in
{
  # ============================================================================
  # Flux v2: Single Cluster (Development Environment)
  # ============================================================================
  
  flux = {
    # Git repository configuration
    gitRepository = gitops.mkGitRepository {
      name = "platform-config";
      namespace = "flux-system";
      url = "https://github.com/myorg/platform-config";
      ref = { branch = "main"; };
      interval = "1m";
    };

    # Development environment: aggressive syncing
    developmentKustomization = gitops.mkKustomization {
      name = "development";
      namespace = "flux-system";
      sourceRef = {
        kind = "GitRepository";
        name = "platform-config";
      };
      path = "./environments/development";
      interval = "5m";
      prune = true;
      wait = true;
    };

    # Staging environment: standard syncing
    stagingKustomization = gitops.mkKustomization {
      name = "staging";
      namespace = "flux-system";
      sourceRef = {
        kind = "GitRepository";
        name = "platform-config";
      };
      path = "./environments/staging";
      interval = "10m";
      prune = true;
      wait = true;
    };

    # Production environment: conservative syncing
    productionKustomization = gitops.mkKustomization {
      name = "production";
      namespace = "flux-system";
      sourceRef = {
        kind = "GitRepository";
        name = "platform-config";
      };
      path = "./environments/production";
      interval = "30m";  # Manual review before production changes
      prune = false;     # Careful pruning in production
      wait = true;
    };

    # Helm repository for bitnami charts
    bitnami = gitops.mkHelmRepository {
      name = "bitnami";
      namespace = "flux-system";
      url = "https://charts.bitnami.com/bitnami";
      interval = "1h";
    };

    # Deploy PostgreSQL via Helm
    postgresqlRelease = gitops.mkHelmRelease {
      name = "postgresql";
      namespace = "databases";
      chart = {
        name = "postgresql";
        version = "13.2.0";
      };
      sourceRef = {
        kind = "HelmRepository";
        name = "bitnami";
      };
      values = {
        auth = {
          username = "app";
          password = "changeme";  # Use secretRef in production
          database = "appdb";
        };
        primary = {
          persistence = {
            enabled = true;
            size = "50Gi";
            storageClassName = "gp3";
          };
          resources = {
            requests = { cpu = "500m"; memory = "512Mi"; };
            limits = { cpu = "1000m"; memory = "1Gi"; };
          };
        };
        metrics.enabled = true;
      };
      interval = "1h";
    };
  };

  # ============================================================================
  # ArgoCD: Multi-Cluster (Global Production)
  # ============================================================================
  
  argocd = {
    # AppProject for access control
    platformTeamProject = gitops.mkAppProject {
      name = "platform-team";
      namespace = "argocd";
      description = "Platform engineering team - full production access";
      sourceRepos = [
        "https://github.com/myorg/platform-config"
        "https://github.com/myorg/infrastructure"
      ];
      destinations = [
        {
          server = "https://kubernetes.default.svc";  # Current cluster
          namespace = "*";
        }
        {
          server = "https://us-east-1.k8s.example.com";
          namespace = "*";
        }
        {
          server = "https://eu-west-1.k8s.example.com";
          namespace = "*";
        }
      ];
      clusterResourceBlacklist = [
        { group = ""; kind = "ResourceQuota"; }
        { group = ""; kind = "LimitRange"; }
      ];
    };

    # AppProject for application teams (restricted)
    appTeamProject = gitops.mkAppProject {
      name = "app-team";
      namespace = "argocd";
      description = "Application team - staging/production app deployments only";
      sourceRepos = [
        "https://github.com/myorg/application-config"
      ];
      destinations = [
        { server = "https://kubernetes.default.svc"; namespace = "staging"; }
        { server = "https://kubernetes.default.svc"; namespace = "production"; }
      ];
      clusterResourceBlacklist = [
        # Restrict to namespace-scoped resources
        { group = ""; kind = "Namespace"; }
        { group = "rbac.authorization.k8s.io"; kind = "ClusterRole"; }
        { group = "rbac.authorization.k8s.io"; kind = "ClusterRoleBinding"; }
        { group = ""; kind = "NetworkPolicy"; }
      ];
    };

    # Bootstrap application: deploys infrastructure policies
    bootstrapApp = gitops.mkApplication {
      name = "cluster-bootstrap";
      namespace = "argocd";
      project = "platform-team";
      source = {
        repoURL = "https://github.com/myorg/platform-config";
        path = "bootstrap";
        targetRevision = "main";
      };
      destination = {
        server = "https://kubernetes.default.svc";
        namespace = "default";
      };
      syncPolicy = gitops.mkSyncPolicy {
        automated = true;
        syncOptions = [
          "CreateNamespace=true"
        ];
      };
    };

    # Core platform services
    platformServicesApp = gitops.mkApplication {
      name = "platform-services";
      namespace = "argocd";
      project = "platform-team";
      source = {
        repoURL = "https://github.com/myorg/platform-config";
        path = "services";
        targetRevision = "main";
      };
      destination = {
        server = "https://kubernetes.default.svc";
        namespace = "platform";
      };
      syncPolicy = gitops.mkSyncPolicy {
        automated = true;
      };
    };

    # US East 1 region deployment
    usEastApp = gitops.mkApplication {
      name = "platform-us-east-1";
      namespace = "argocd";
      project = "platform-team";
      source = {
        repoURL = "https://github.com/myorg/platform-config";
        path = "clusters/us-east-1";
        targetRevision = "main";
      };
      destination = {
        server = "https://us-east-1.k8s.example.com";
        namespace = "default";
      };
      syncPolicy = gitops.mkSyncPolicy {
        automated = false;  # Manual approval for multi-region
      };
    };

    # EU West 1 region deployment
    euWestApp = gitops.mkApplication {
      name = "platform-eu-west-1";
      namespace = "argocd";
      project = "platform-team";
      source = {
        repoURL = "https://github.com/myorg/platform-config";
        path = "clusters/eu-west-1";
        targetRevision = "main";
      };
      destination = {
        server = "https://eu-west-1.k8s.example.com";
        namespace = "default";
      };
      syncPolicy = gitops.mkSyncPolicy {
        automated = false;
      };
    };

    # User application (deployed by app team)
    userApp = gitops.mkApplication {
      name = "my-application";
      namespace = "argocd";
      project = "app-team";
      source = {
        repoURL = "https://github.com/myorg/application-config";
        path = "app";
        targetRevision = "main";
      };
      destination = {
        server = "https://kubernetes.default.svc";
        namespace = "production";
      };
      syncPolicy = gitops.mkSyncPolicy {
        automated = true;
        syncOptions = [
          "CreateNamespace=true"
          "PrunePropagationPolicy=background"
        ];
      };
    };
  };

  # ============================================================================
  # Repository Configurations
  # ============================================================================
  
  repositories = {
    # Development configuration repository
    developmentRepo = gitops.mkGitOpsRepository {
      name = "platform-dev-config";
      defaultBranch = "develop";
      environments = [ "development" "staging" ];
      structure = "flat";
    };

    # Production configuration repository
    productionRepo = gitops.mkGitOpsRepository {
      name = "platform-prod-config";
      defaultBranch = "main";
      environments = [ "us-east-1" "eu-west-1" "ap-south-1" ];
      structure = "hierarchy";
    };
  };

  # ============================================================================
  # Deployment Patterns
  # ============================================================================
  
  deployments = {
    # Single cluster with Flux
    fluxSingleCluster = gitops.mkSingleClusterDeployment {
      name = "development-platform";
      gitRepository = "https://github.com/myorg/platform-config";
      path = "./apps";
      namespace = "default";
    };

    # Multi-cluster with ArgoCD
    argoCDMultiCluster = gitops.mkMultiClusterDeployment {
      name = "global-platform";
      gitRepository = "https://github.com/myorg/platform-config";
      clusters = {
        "us-east-1" = {
          server = "https://us-east-1.k8s.example.com";
          path = "clusters/us-east-1";
          namespace = "default";
        };
        "eu-west-1" = {
          server = "https://eu-west-1.k8s.example.com";
          path = "clusters/eu-west-1";
          namespace = "default";
        };
        "ap-south-1" = {
          server = "https://ap-south-1.k8s.example.com";
          path = "clusters/ap-south-1";
          namespace = "default";
        };
      };
    };
  };

  # ============================================================================
  # Sync Configurations
  # ============================================================================
  
  syncConfigs = {
    # Development: fast sync (5 minutes)
    devSync = gitops.mkFluxSyncConfig {
      repositoryURL = "https://github.com/myorg/platform-config";
      repositoryBranch = "develop";
      paths = [ "./environments/development" ];
      interval = "5m";
      prune = true;
    };

    # Staging: standard sync (15 minutes)
    stagingSync = gitops.mkFluxSyncConfig {
      repositoryURL = "https://github.com/myorg/platform-config";
      repositoryBranch = "staging";
      paths = [ "./environments/staging" ];
      interval = "15m";
      prune = true;
    };

    # Production: careful sync (1 hour)
    prodSync = gitops.mkFluxSyncConfig {
      repositoryURL = "https://github.com/myorg/platform-config";
      repositoryBranch = "main";
      paths = [ "./environments/production" ];
      interval = "1h";
      prune = false;  # Manual prune for safety
    };

    # ArgoCD multi-region
    multiRegionSync = gitops.mkArgocdSyncConfig {
      repositoryURL = "https://github.com/myorg/platform-config";
      defaultRevision = "main";
      automated = false;  # Manual approval
      selfHeal = true;
    };
  };

  # ============================================================================
  # Summary Statistics
  # ============================================================================
  
  summary = {
    flux = {
      gitRepositories = 1;
      helmRepositories = 1;
      kustomizations = 3;
      helmReleases = 1;
      totalResources = 6;
    };

    argocd = {
      appProjects = 2;
      applications = 7;
      singleClusterApps = 5;
      multiClusterApps = 2;
      totalResources = 9;
    };

    repositories = 2;
    environments = 7;  # dev, staging, prod, us-east-1, eu-west-1, ap-south-1, + bootstrap
    clusters = 4;      # local + 3 regional
    syncStrategies = 5; # dev (fast), staging (standard), prod (conservative), argocd, multi-region

    description = "Production-grade GitOps setup with Flux v2 and ArgoCD";
  };
}
