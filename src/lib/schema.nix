# Schema and API Version Resolution
# 
# This module handles:
# - API version resolution for different Kubernetes versions
# - Mapping of resource kinds to their preferred apiVersions
# - Version compatibility checking

{ lib }:

let
  inherit (lib) mkDefault mapAttrs;

  # Vendored API version mappings for supported Kubernetes versions
  # These map Kubernetes kinds to their preferred apiVersion for each k8s release
  apiVersionMatrix = {
    "1.28" = {
      Deployment = "apps/v1";
      StatefulSet = "apps/v1";
      DaemonSet = "apps/v1";
      Job = "batch/v1";
      CronJob = "batch/v1";
      Pod = "v1";
      Service = "v1";
      Ingress = "networking.k8s.io/v1";
      NetworkPolicy = "networking.k8s.io/v1";
      Namespace = "v1";
      PersistentVolume = "v1";
      PersistentVolumeClaim = "v1";
      ConfigMap = "v1";
      Secret = "v1";
      ServiceAccount = "v1";
      ClusterRole = "rbac.authorization.k8s.io/v1";
      ClusterRoleBinding = "rbac.authorization.k8s.io/v1";
      Role = "rbac.authorization.k8s.io/v1";
      RoleBinding = "rbac.authorization.k8s.io/v1";
      # Kyverno policies
      ClusterPolicy = "kyverno.io/v1";
      Policy = "kyverno.io/v1";
      # ExternalSecrets
      ExternalSecret = "external-secrets.io/v1beta1";
      SecretStore = "external-secrets.io/v1beta1";
    };

    "1.29" = {
      Deployment = "apps/v1";
      StatefulSet = "apps/v1";
      DaemonSet = "apps/v1";
      Job = "batch/v1";
      CronJob = "batch/v1";
      Pod = "v1";
      Service = "v1";
      Ingress = "networking.k8s.io/v1";
      NetworkPolicy = "networking.k8s.io/v1";
      Namespace = "v1";
      PersistentVolume = "v1";
      PersistentVolumeClaim = "v1";
      ConfigMap = "v1";
      Secret = "v1";
      ServiceAccount = "v1";
      ClusterRole = "rbac.authorization.k8s.io/v1";
      ClusterRoleBinding = "rbac.authorization.k8s.io/v1";
      Role = "rbac.authorization.k8s.io/v1";
      RoleBinding = "rbac.authorization.k8s.io/v1";
      ClusterPolicy = "kyverno.io/v1";
      Policy = "kyverno.io/v1";
      ExternalSecret = "external-secrets.io/v1beta1";
      SecretStore = "external-secrets.io/v1beta1";
    };

    "1.30" = {
      Deployment = "apps/v1";
      StatefulSet = "apps/v1";
      DaemonSet = "apps/v1";
      Job = "batch/v1";
      CronJob = "batch/v1";
      Pod = "v1";
      Service = "v1";
      Ingress = "networking.k8s.io/v1";
      NetworkPolicy = "networking.k8s.io/v1";
      Namespace = "v1";
      PersistentVolume = "v1";
      PersistentVolumeClaim = "v1";
      ConfigMap = "v1";
      Secret = "v1";
      ServiceAccount = "v1";
      ClusterRole = "rbac.authorization.k8s.io/v1";
      ClusterRoleBinding = "rbac.authorization.k8s.io/v1";
      Role = "rbac.authorization.k8s.io/v1";
      RoleBinding = "rbac.authorization.k8s.io/v1";
      ClusterPolicy = "kyverno.io/v1";
      Policy = "kyverno.io/v1";
      ExternalSecret = "external-secrets.io/v1beta1";
      SecretStore = "external-secrets.io/v1beta1";
    };

    "1.31" = {
      Deployment = "apps/v1";
      StatefulSet = "apps/v1";
      DaemonSet = "apps/v1";
      Job = "batch/v1";
      CronJob = "batch/v1";
      Pod = "v1";
      Service = "v1";
      Ingress = "networking.k8s.io/v1";
      NetworkPolicy = "networking.k8s.io/v1";
      Namespace = "v1";
      PersistentVolume = "v1";
      PersistentVolumeClaim = "v1";
      ConfigMap = "v1";
      Secret = "v1";
      ServiceAccount = "v1";
      ClusterRole = "rbac.authorization.k8s.io/v1";
      ClusterRoleBinding = "rbac.authorization.k8s.io/v1";
      Role = "rbac.authorization.k8s.io/v1";
      RoleBinding = "rbac.authorization.k8s.io/v1";
      ClusterPolicy = "kyverno.io/v1";
      Policy = "kyverno.io/v1";
      ExternalSecret = "external-secrets.io/v1beta1";
      SecretStore = "external-secrets.io/v1beta1";
    };
  };

  supportedVersions = builtins.attrNames apiVersionMatrix;

in
{
  # Resolve apiVersion for a kind given a Kubernetes version
  resolveApiVersion = { kind, kubernetesVersion }:
    let
      versionMap = apiVersionMatrix.${kubernetesVersion}
        or (throw "Unsupported Kubernetes version: ${kubernetesVersion}. Supported: ${builtins.toJSON supportedVersions}");
    in
      versionMap.${kind}
        or (throw "Unknown resource kind: ${kind} for Kubernetes version ${kubernetesVersion}");

  # Get all supported Kubernetes versions
  getSupportedVersions = supportedVersions;

  # Check if a version is supported
  isSupportedVersion = version: builtins.elem version supportedVersions;

  # Get the full API map for a version
  getApiMap = kubernetesVersion:
    apiVersionMatrix.${kubernetesVersion}
      or (throw "Unsupported Kubernetes version: ${kubernetesVersion}");
}
