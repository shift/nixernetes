# GitOps Integration Framework
#
# This module provides declarative GitOps support for:
# - Flux v2 (modern, declarative GitOps)
# - ArgoCD (declarative continuous deployment)
# - Multi-cluster management
# - Automated sync and health monitoring
# - Repository and workflow management

{ lib }:

let
  inherit (lib) types mkOption;

in
{
  # ============================================================================
  # Flux v2 Support
  # ============================================================================

  # Create a Flux GitRepository source
  mkGitRepository = { name, namespace ? "flux-system", url, ref ? { branch = "main"; }, interval ? "1m", secretRef ? null }:
    {
      apiVersion = "source.toolkit.fluxcd.io/v1";
      kind = "GitRepository";
      metadata = { inherit name namespace; };
      spec = {
        inherit interval url ref;
      } // (if secretRef != null then { inherit secretRef; } else {});
    };

  # Create a Flux Kustomization resource
  mkKustomization = { name, namespace ? "flux-system", sourceRef, path ? "./", interval ? "10m", prune ? true, wait ? false, health ? {} }:
    {
      apiVersion = "kustomize.toolkit.fluxcd.io/v1";
      kind = "Kustomization";
      metadata = { inherit name namespace; };
      spec = {
        interval = interval;
        prune = prune;
        wait = wait;
        sourceRef = {
          kind = sourceRef.kind or "GitRepository";
          name = sourceRef.name;
        };
        path = path;
      } // (if health != {} then { healthChecks = health; } else {});
    };

  # Create a Flux OCIRepository (for OCI/container registries)
  mkOCIRepository = { name, namespace ? "flux-system", url, interval ? "1m", ref ? { tag = "latest"; } }:
    {
      apiVersion = "source.toolkit.fluxcd.io/v1beta2";
      kind = "OCIRepository";
      metadata = { inherit name namespace; };
      spec = {
        inherit interval url ref;
      };
    };

  # Create a Flux HelmRepository source
  mkHelmRepository = { name, namespace ? "flux-system", url, interval ? "1m" }:
    {
      apiVersion = "source.toolkit.fluxcd.io/v1beta2";
      kind = "HelmRepository";
      metadata = { inherit name namespace; };
      spec = {
        inherit interval url;
      };
    };

  # Create a Flux HelmRelease
  mkHelmRelease = { name, namespace ? "default", chart, sourceRef, values ? {}, interval ? "30m" }:
    {
      apiVersion = "helm.toolkit.fluxcd.io/v2";
      kind = "HelmRelease";
      metadata = { inherit name namespace; };
      spec = {
        inherit interval;
        chart = {
          spec = {
            chart = chart.name;
            sourceRef = {
              kind = sourceRef.kind or "HelmRepository";
              name = sourceRef.name;
            };
            version = chart.version or "*";
          };
        };
        values = values;
      };
    };

  # ============================================================================
  # ArgoCD Support
  # ============================================================================

  # Create an ArgoCD Application resource
  mkApplication = { name, namespace ? "argocd", project ? "default", source, destination, syncPolicy ? {} }:
    {
      apiVersion = "argoproj.io/v1alpha1";
      kind = "Application";
      metadata = { inherit name namespace; };
      spec = {
        project = project;
        source = {
          repoURL = source.repoURL;
          path = source.path or "./";
          targetRevision = source.targetRevision or "HEAD";
        } // (if source ? helm then { helm = source.helm; } else {})
          // (if source ? kustomize then { kustomize = source.kustomize; } else {});
        destination = {
          server = destination.server or "https://kubernetes.default.svc";
          namespace = destination.namespace or "default";
        };
      } // (if syncPolicy != {} then { syncPolicy = syncPolicy; } else {});
    };

  # Create an ArgoCD AppProject resource
  mkAppProject = { name, namespace ? "argocd", description ? "", sourceRepos ? [], destinations ? [], clusterResourceBlacklist ? [], namespaceResourceBlacklist ? [] }:
    {
      apiVersion = "argoproj.io/v1alpha1";
      kind = "AppProject";
      metadata = { inherit name namespace; };
      spec = {
        description = description;
        sourceRepos = sourceRepos ++ [ "*" ];  # Default to all unless restricted
        destinations = destinations ++ [
          {
            server = "https://kubernetes.default.svc";
            namespace = "*";
          }
        ];
        clusterResourceBlacklist = clusterResourceBlacklist;
        namespaceResourceBlacklist = namespaceResourceBlacklist;
      };
    };

  # Create ArgoCD sync policy
  mkSyncPolicy = { automated ? true, syncOptions ? [] }:
    {
      automated = (if automated then { prune = true; selfHeal = true; } else null);
      syncOptions = syncOptions;
      retry = {
        limit = 5;
        backoff = {
          duration = "5s";
          factor = 2;
          maxDuration = "3m";
        };
      };
    };

  # Create ArgoCD notification trigger
  mkNotificationTrigger = { name, onceSynced ? false, onHealthDegraded ? true }:
    {
      trigger = name;
      onceSynced = onceSynced;
      onHealthDegraded = onHealthDegraded;
    };

  # ============================================================================
  # Repository and Workflow Helpers
  # ============================================================================

  # GitOps repository structure helper
  mkGitOpsRepository = { name, defaultBranch ? "main", environments ? ["development" "staging" "production"], structure ? "flat" }:
    let
      # Flat structure: repos/{env}/manifests/
      flatStructure = builtins.listToAttrs (map (env: {
        name = env;
        value = "repos/${env}/manifests/";
      }) environments);
      
      # Hierarchical structure: {env}/kubernetes/{app}/
      hierarchyStructure = builtins.listToAttrs (map (env: {
        name = env;
        value = "${env}/kubernetes/";
      }) environments);
    in
      {
        name = name;
        defaultBranch = defaultBranch;
        environments = environments;
        structure = if structure == "hierarchy" then hierarchyStructure else flatStructure;
        description = "GitOps repository for ${name} managed by Nixernetes";
        topics = [ "gitops" "flux" "argocd" "kubernetes" "nixernetes" ];
      };

  # Flux sync configuration helper
  mkFluxSyncConfig = { repositoryURL, repositoryBranch ? "main", paths ? [], interval ? "10m", prune ? true }:
    {
      kind = "flux";
      repository = {
        url = repositoryURL;
        branch = repositoryBranch;
      };
      paths = paths;
      sync = {
        interval = interval;
        prune = prune;
      };
    };

  # ArgoCD sync configuration helper
  mkArgocdSyncConfig = { repositoryURL, defaultRevision ? "HEAD", automated ? true, selfHeal ? true }:
    {
      kind = "argocd";
      repository = {
        url = repositoryURL;
        defaultRevision = defaultRevision;
      };
      sync = {
        automated = automated;
        selfHeal = selfHeal;
        prune = automated;
      };
    };

  # ============================================================================
  # Deployment Patterns
  # ============================================================================

  # GitOps deployment pattern: single cluster
  mkSingleClusterDeployment = { name, gitRepository, path, namespace ? "default" }:
    {
      flux = {
        source = {
          apiVersion = "source.toolkit.fluxcd.io/v1";
          kind = "GitRepository";
          name = name;
          url = gitRepository;
        };
        kustomization = {
          name = name;
          sourceRef = {
            kind = "GitRepository";
            name = name;
          };
          path = path;
          namespace = namespace;
        };
      };
      argocd = {
        project = {
          name = name;
          description = "GitOps project for ${name}";
        };
        application = {
          name = name;
          sourceRef = {
            repoURL = gitRepository;
            path = path;
          };
          destination = {
            namespace = namespace;
          };
        };
      };
    };

  # GitOps deployment pattern: multi-cluster
  mkMultiClusterDeployment = { name, gitRepository, clusters ? {} }:
    let
      mkClusterApp = clusterName: clusterConfig:
        {
          name = "${name}-${clusterName}";
          sourceRef = {
            repoURL = gitRepository;
            path = clusterConfig.path or "clusters/${clusterName}";
          };
          destination = {
            server = clusterConfig.server or "https://kubernetes.default.svc";
            namespace = clusterConfig.namespace or "default";
          };
        };
    in
      {
        applications = builtins.mapAttrs mkClusterApp clusters;
        description = "Multi-cluster GitOps deployment for ${name}";
        clusterCount = builtins.length (builtins.attrNames clusters);
      };

  # ============================================================================
  # Health and Monitoring
  # ============================================================================

  # Define health checks for Kustomization
  mkHealthChecks = { apiVersion ? "apps/v1", kind ? "Deployment", name ? null }:
    [
      {
        inherit apiVersion kind;
        name = name;
      }
    ];

  # Create notification webhook configuration
  mkWebhookNotification = { url, insecureSkipVerify ? false }:
    {
      url = url;
      headers = {
        "Content-Type" = "application/json";
      };
      insecureSkipVerify = insecureSkipVerify;
    };

  # ============================================================================
  # Configuration Presets
  # ============================================================================

  # Preset configurations for different deployment styles
  presets = {
    # Aggressive: Sync every minute, prune immediately, wait for health
    aggressive = {
      interval = "1m";
      prune = true;
      wait = true;
      timeout = "5m";
    };

    # Standard: Sync every 10 minutes, prune after sync, wait for health
    standard = {
      interval = "10m";
      prune = true;
      wait = true;
      timeout = "5m";
    };

    # Conservative: Sync every hour, manual prune, don't wait for health
    conservative = {
      interval = "1h";
      prune = false;
      wait = false;
      timeout = "10m";
    };

    # Development: Sync every 5 minutes, prune, wait for health
    development = {
      interval = "5m";
      prune = true;
      wait = true;
      timeout = "3m";
    };
  };

  # ============================================================================
  # Helpers and Utilities
  # ============================================================================

  # Check if repository is valid Git URL
  isValidGitURL = url:
    (builtins.match "https?://.*\\.git" url) != null ||
    (builtins.match "git@.*:.*\\.git" url) != null;

  # Extract repository name from URL
  getRepositoryName = url:
    let
      parts = builtins.split "/" url;
      lastPart = lib.last parts;
    in
      builtins.replaceStrings [ ".git" ] [ "" ] lastPart;

  # Get sync interval in seconds
  getSyncIntervalSeconds = interval:
    let
      match = builtins.match "([0-9]+)(s|m|h|d)" interval;
    in
      if match != null then
        let
          value = builtins.fromJSON (builtins.elemAt match 0);
          unit = builtins.elemAt match 1;
          multipliers = {
            "s" = 1;
            "m" = 60;
            "h" = 3600;
            "d" = 86400;
          };
        in
          value * (multipliers.${unit} or 1)
      else 0;

  # Create GitOps deployment summary
  mkDeploymentSummary = deployments:
    {
      totalDeployments = builtins.length deployments;
      fluxCount = builtins.length (lib.filter (d: d ? flux) deployments);
      argoCDCount = builtins.length (lib.filter (d: d ? argocd) deployments);
      description = "GitOps deployment summary";
    };
}
