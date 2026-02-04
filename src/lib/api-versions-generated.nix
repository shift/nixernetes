# Auto-generated API version mappings for Kubernetes
# Generated from upstream Kubernetes OpenAPI specifications
# DO NOT EDIT MANUALLY - regenerate using: nix run .#generate-api-versions
#
# This maps Kubernetes resource kinds to their preferred apiVersion
# for each supported Kubernetes version.

{ lib }:

let
  inherit (lib) mkDefault;

  apiVersionMatrix = {
    "1.28" = {
      Certificate = "cert-manager.io/v1";
      ClusterIssuer = "cert-manager.io/v1";
      ClusterPolicy = "kyverno.io/v1";
      ClusterRole = "rbac.authorization.k8s.io/v1";
      ClusterRoleBinding = "rbac.authorization.k8s.io/v1";
      ClusterSecretStore = "external-secrets.io/v1beta1";
      ConfigMap = "v1";
      CronJob = "batch/v1";
      DaemonSet = "apps/v1";
      Deployment = "apps/v1";
      ExternalSecret = "external-secrets.io/v1beta1";
      Ingress = "networking.k8s.io/v1";
      IngressClass = "networking.k8s.io/v1";
      Issuer = "cert-manager.io/v1";
      Job = "batch/v1";
      Namespace = "v1";
      NetworkPolicy = "networking.k8s.io/v1";
      PersistentVolume = "v1";
      PersistentVolumeClaim = "v1";
      Pod = "v1";
      Policy = "kyverno.io/v1";
      ReplicaSet = "apps/v1";
      Role = "rbac.authorization.k8s.io/v1";
      RoleBinding = "rbac.authorization.k8s.io/v1";
      Secret = "v1";
      SecretStore = "external-secrets.io/v1beta1";
      Service = "v1";
      ServiceAccount = "v1";
      StatefulSet = "apps/v1";
    };

    "1.29" = {
      Certificate = "cert-manager.io/v1";
      ClusterIssuer = "cert-manager.io/v1";
      ClusterPolicy = "kyverno.io/v1";
      ClusterRole = "rbac.authorization.k8s.io/v1";
      ClusterRoleBinding = "rbac.authorization.k8s.io/v1";
      ClusterSecretStore = "external-secrets.io/v1beta1";
      ConfigMap = "v1";
      CronJob = "batch/v1";
      DaemonSet = "apps/v1";
      Deployment = "apps/v1";
      ExternalSecret = "external-secrets.io/v1beta1";
      Ingress = "networking.k8s.io/v1";
      IngressClass = "networking.k8s.io/v1";
      Issuer = "cert-manager.io/v1";
      Job = "batch/v1";
      Namespace = "v1";
      NetworkPolicy = "networking.k8s.io/v1";
      PersistentVolume = "v1";
      PersistentVolumeClaim = "v1";
      Pod = "v1";
      Policy = "kyverno.io/v1";
      ReplicaSet = "apps/v1";
      Role = "rbac.authorization.k8s.io/v1";
      RoleBinding = "rbac.authorization.k8s.io/v1";
      Secret = "v1";
      SecretStore = "external-secrets.io/v1beta1";
      Service = "v1";
      ServiceAccount = "v1";
      StatefulSet = "apps/v1";
    };

    "1.30" = {
      Certificate = "cert-manager.io/v1";
      ClusterIssuer = "cert-manager.io/v1";
      ClusterPolicy = "kyverno.io/v1";
      ClusterRole = "rbac.authorization.k8s.io/v1";
      ClusterRoleBinding = "rbac.authorization.k8s.io/v1";
      ClusterSecretStore = "external-secrets.io/v1beta1";
      ConfigMap = "v1";
      CronJob = "batch/v1";
      DaemonSet = "apps/v1";
      Deployment = "apps/v1";
      ExternalSecret = "external-secrets.io/v1beta1";
      Ingress = "networking.k8s.io/v1";
      IngressClass = "networking.k8s.io/v1";
      Issuer = "cert-manager.io/v1";
      Job = "batch/v1";
      Namespace = "v1";
      NetworkPolicy = "networking.k8s.io/v1";
      PersistentVolume = "v1";
      PersistentVolumeClaim = "v1";
      Pod = "v1";
      Policy = "kyverno.io/v1";
      ReplicaSet = "apps/v1";
      Role = "rbac.authorization.k8s.io/v1";
      RoleBinding = "rbac.authorization.k8s.io/v1";
      Secret = "v1";
      SecretStore = "external-secrets.io/v1beta1";
      Service = "v1";
      ServiceAccount = "v1";
      StatefulSet = "apps/v1";
    };

    "1.31" = {
      Certificate = "cert-manager.io/v1";
      ClusterIssuer = "cert-manager.io/v1";
      ClusterPolicy = "kyverno.io/v1";
      ClusterRole = "rbac.authorization.k8s.io/v1";
      ClusterRoleBinding = "rbac.authorization.k8s.io/v1";
      ClusterSecretStore = "external-secrets.io/v1beta1";
      ConfigMap = "v1";
      CronJob = "batch/v1";
      DaemonSet = "apps/v1";
      Deployment = "apps/v1";
      ExternalSecret = "external-secrets.io/v1beta1";
      Ingress = "networking.k8s.io/v1";
      IngressClass = "networking.k8s.io/v1";
      Issuer = "cert-manager.io/v1";
      Job = "batch/v1";
      Namespace = "v1";
      NetworkPolicy = "networking.k8s.io/v1";
      PersistentVolume = "v1";
      PersistentVolumeClaim = "v1";
      Pod = "v1";
      Policy = "kyverno.io/v1";
      ReplicaSet = "apps/v1";
      Role = "rbac.authorization.k8s.io/v1";
      RoleBinding = "rbac.authorization.k8s.io/v1";
      Secret = "v1";
      SecretStore = "external-secrets.io/v1beta1";
      Service = "v1";
      ServiceAccount = "v1";
      StatefulSet = "apps/v1";
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
