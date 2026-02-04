# Manifest Builder and Assembly
#
# This module provides:
# - Complete manifest assembly from resources
# - YAML serialization with ordering
# - Helm chart generation
# - Manifest analysis and reporting

{ lib, pkgs }:

let
  inherit (lib) concatStringsSep mapAttrs;

in
{
  # Build complete manifest from resources
  buildManifest = { resources, kubernetesVersion ? "1.30", format ? "yaml" }:
    let
      output_module = import ./output.nix { inherit lib pkgs; };
      ordered = output_module.orderResourcesForApply resources;
    in
    {
      inherit resources ordered kubernetesVersion;
      resourceCount = builtins.length resources;
      resourceKinds = lib.unique (map (r: r.kind) resources);
      namespaces = lib.unique (map (r: r.metadata.namespace or "default") resources);
    };

  # Generate YAML output
  toYAML = resources:
    let
      output_module = import ./output.nix { inherit lib pkgs; };
    in
    output_module.resourcesToYaml resources;

  # Generate Helm chart
  toHelmChart = { name, resources, kubernetesVersion ? "1.30", version ? "1.0.0", description ? "" }:
    let
      output_module = import ./output.nix { inherit lib pkgs; };
    in
    output_module.mkHelmChart {
      inherit name version description resources;
    };

  # Generate manifest report
  generateReport = { manifest }:
    let
      byKind = lib.foldl (acc: r:
        acc // {
          ${r.kind} = (acc.${r.kind} or [ ]) ++ [ r ];
        }
      ) { } manifest.resources;

      byNamespace = lib.foldl (acc: r:
        let ns = r.metadata.namespace or "default";
        in
        acc // {
          ${ns} = (acc.${ns} or [ ]) ++ [ r ];
        }
      ) { } manifest.resources;
    in
    {
      total = builtins.length manifest.resources;
      byKind = mapAttrs (kind: rs: builtins.length rs) byKind;
      byNamespace = mapAttrs (ns: rs: builtins.length rs) byNamespace;
      kinds = lib.unique manifest.resourceKinds;
      namespaces = lib.unique manifest.namespaces;
    };

  # Validate manifest for deployment
  validateForDeployment = { manifest }:
    let
      validation_module = import ./validation.nix { inherit lib; };
      schema = import ./schema.nix { inherit lib; };
      
      apiMap = schema.getApiMap manifest.kubernetesVersion;
      result = validation_module.validateManifest {
        resources = manifest.resources;
        schemaMap = apiMap;
        kubernetesVersion = manifest.kubernetesVersion;
      };
    in
    {
      valid = result.ok or false;
      message = if result.ok then "Manifest is valid" else "Manifest validation failed";
      report = validation_module.validationSummary {
        resources = manifest.resources;
        schemaMap = apiMap;
        kubernetesVersion = manifest.kubernetesVersion;
      };
    };
}
