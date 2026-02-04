# Output Formatters
#
# This module provides:
# - YAML manifest generation with proper ordering
# - Helm chart generation
# - Manifest validation

{ lib, pkgs }:

let
  inherit (lib) lists;

in
{
  # Order resources for proper kubectl apply
  # Namespace -> RBAC -> Configs -> Workloads -> Services -> Ingress -> Policies
  orderResourcesForApply = resources:
    let
      resourcePriority = {
        "Namespace" = 1;
        "ClusterRole" = 2;
        "ClusterRoleBinding" = 2;
        "Role" = 2;
        "RoleBinding" = 2;
        "ConfigMap" = 3;
        "Secret" = 3;
        "ServiceAccount" = 3;
        "Pod" = 4;
        "Deployment" = 4;
        "StatefulSet" = 4;
        "DaemonSet" = 4;
        "Job" = 4;
        "CronJob" = 4;
        "Service" = 5;
        "Ingress" = 6;
        "NetworkPolicy" = 7;
        "ClusterPolicy" = 7;
        "Policy" = 7;
      };

      getPriority = resource:
        resourcePriority.${resource.kind} or 99;

      compareResources = r1: r2:
        if getPriority r1 != getPriority r2 then
          getPriority r1 < getPriority r2
        else
          # Same priority - sort by namespace, then name
          let
            ns1 = r1.metadata.namespace or "default";
            ns2 = r2.metadata.namespace or "default";
            n1 = r1.metadata.name or "";
            n2 = r2.metadata.name or "";
          in
            if ns1 != ns2 then ns1 < ns2 else n1 < n2;
    in
      lists.sort compareResources resources;

  # Convert resources to YAML manifest
  resourcesToYaml = resources:
    let
      ordered = orderResourcesForApply resources;
      toYamlDoc = resource: "---\n" + (builtins.toJSON resource);
    in
      lib.strings.concatStringsSep "\n" (map toYamlDoc ordered);

  # Generate a Helm Chart.yaml
  mkHelmChartYaml = { name, version ? "1.0.0", description, appVersion ? "1.0.0" }:
    {
      apiVersion = "v2";
      kind = "Chart";
      name = name;
      inherit version description appVersion;
      type = "application";
    };

  # Generate a Helm values.yaml
  mkHelmValuesYaml = values:
    values;

  # Generate complete Helm chart structure
  mkHelmChart = { name, version ? "1.0.0", description, resources, values ? {} }:
    let
      chartYaml = mkHelmChartYaml { inherit name version description; };
      manifestYaml = resourcesToYaml resources;
    in
    {
      "Chart.yaml" = chartYaml;
      "values.yaml" = values;
      "templates/resources.yaml" = manifestYaml;
    };

  # Validate manifest against kubeconform (if available)
  validateManifest = { manifest }:
    # This would be implemented as a builder in the Nix flake
    # For now, just return the manifest
    manifest;
}
