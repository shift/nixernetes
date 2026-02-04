# Module Generator Framework
#
# This module provides:
# - High-level builders for creating valid Kubernetes resources
# - Automatic population of standard fields
# - Integration with schema and validation

{ lib, pkgs }:

let
  inherit (lib) mkOption types mkDefault;
  
  schema = import ./schema.nix { inherit lib; };
  validation = import ./validation.nix { inherit lib; };
  typesDefs = import ./types.nix { inherit lib; };

in
{
  # Module configuration for user input
  moduleConfig = {
    options = {
      kubernetesVersion = mkOption {
        type = types.str;
        default = "1.30";
        description = "Target Kubernetes version";
      };

      defaultNamespace = mkOption {
        type = types.str;
        default = "default";
        description = "Default namespace for resources";
      };

      resources = mkOption {
        type = types.listOf types.attrs;
        default = [ ];
        description = "List of Kubernetes resources";
      };

      manifests = mkOption {
        type = types.listOf types.attrs;
        default = [ ];
        description = "Generated manifests with injected defaults";
      };
    };
  };

  # Build a complete configuration and validate it
  mkManifest = { kubernetesVersion ? "1.30", resources }:
    let
      # Get API version map for the target version
      apiMap = schema.getApiMap kubernetesVersion;

      # Validate that all resources are valid
      validatedResources = validation.validateManifest {
        inherit resources;
        schemaMap = apiMap;
        inherit kubernetesVersion;
      };

      # Summary of what was built
      summary = validation.validationSummary {
        inherit resources;
        schemaMap = apiMap;
        inherit kubernetesVersion;
      };
    in
    {
      inherit resources apiMap kubernetesVersion summary;
      valid = validatedResources.ok or false;
    };

  # Helper: inject defaults into resources
  normalizeResources = { resources, kubernetesVersion ? "1.30" }:
    let
      apiMap = schema.getApiMap kubernetesVersion;
      
      normalize = resource:
        let
          # Ensure metadata exists
          metadata = resource.metadata // {
            name = resource.metadata.name or "unnamed";
            namespace = resource.metadata.namespace or "default";
            labels = resource.metadata.labels or { };
            annotations = resource.metadata.annotations or { };
          };
        in
        resource // { inherit metadata; };
    in
    map normalize resources;

  # Helper: group resources by kind
  groupByKind = resources:
    let
      groups = { };
      add = acc: resource:
        let
          kind = resource.kind or "Unknown";
          kindGroup = acc.${kind} or [ ];
        in
        acc // { ${kind} = kindGroup ++ [ resource ]; };
    in
    lib.foldl add { } resources;

  # Helper: group resources by namespace
  groupByNamespace = resources:
    let
      groups = { };
      add = acc: resource:
        let
          namespace = resource.metadata.namespace or "default";
          nsGroup = acc.${namespace} or [ ];
        in
        acc // { ${namespace} = nsGroup ++ [ resource ]; };
    in
    lib.foldl add { } resources;

  # Generate resource dependency graph
  analyzeDependencies = resources:
    let
      # Extract service names
      serviceNames = 
        lib.map (r: r.metadata.name)
          (lib.filter (r: r.kind == "Service") resources);

      # Extract selector information
      extractSelectors = r:
        {
          kind = r.kind;
          name = r.metadata.name;
          namespace = r.metadata.namespace or "default";
          selector = r.spec.selector or r.spec.podSelector or { };
        };

      selectors = map extractSelectors resources;
    in
    {
      services = serviceNames;
      selectors = selectors;
    };
}
