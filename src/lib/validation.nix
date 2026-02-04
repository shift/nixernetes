# Manifest Validation Framework
#
# This module provides:
# - Schema validation of resources
# - Version compatibility checking
# - Compliance requirement validation
# - Resource dependency checking

{ lib }:

let
  inherit (lib) concatStringsSep;

  # Create a validation error with context
  mkValidationError = { message, resource, field }:
    throw "Validation Error in ${resource.kind}/${resource.metadata.name} (field: ${field}): ${message}";

in
{
  # Check if a resource has required labels
  requireLabels = { resource, required }:
    let
      labels = resource.metadata.labels or { };
      missing = lib.filterAttrs (name: _: !(builtins.hasAttr name labels)) required;
    in
    if missing == { } then
      true
    else
      throw "Missing required labels on ${resource.kind}/${resource.metadata.name}: ${concatStringsSep ", " (builtins.attrNames missing)}";

  # Check if namespace exists in resource list
  namespaceExists = { namespace, resources }:
    lib.any (r: r.kind == "Namespace" && r.metadata.name == namespace) resources;

  # Validate all namespaces referenced exist
  validateNamespaces = resources:
    let
      namespaces = lib.filter (r: r.kind == "Namespace") resources;
      namespaceNames = map (r: r.metadata.name) namespaces;
      referencedNamespaces = lib.unique (
        lib.filter (ns: ns != null && ns != "default")
          (map (r: r.metadata.namespace or null) resources)
      );
      missing = lib.filter (ns: !(lib.elem ns namespaceNames)) referencedNamespaces;
    in
    if missing == [ ] then
      { ok = true; }
    else
      throw "Resources reference undefined namespaces: ${concatStringsSep ", " missing}";

  # Validate resource selectors
  validateSelectors = resource:
    let
      hasSelector = (resource.spec ? selector) || (resource.spec ? podSelector);
    in
    if !hasSelector then
      { ok = true; }
    else
      { ok = true; }; # Simplified for now

  # Validate a single resource
  validateResource = { resource, schemaMap, kubernetesVersion }:
    let
      validateApiVersion = 
        if !(builtins.hasAttr resource.kind schemaMap) then
          throw "Unknown resource kind: ${resource.kind} for Kubernetes ${kubernetesVersion}"
        else
          schemaMap.${resource.kind} == resource.apiVersion;

      validateMetadata =
        if !(resource.metadata ? name) then
          throw "Resource ${resource.kind} missing metadata.name"
        else if builtins.stringLength resource.metadata.name == 0 then
          throw "Resource ${resource.kind} has empty metadata.name"
        else
          true;

      validateNamespace =
        let
          ns = resource.metadata.namespace or "default";
        in
        if builtins.stringLength ns == 0 then
          throw "Resource ${resource.kind}/${resource.metadata.name} has empty namespace"
        else
          true;
    in
    {
      apiVersion = validateApiVersion;
      metadata = validateMetadata;
      namespace = validateNamespace;
    };

  # Comprehensive validation of resource list
  validateManifest = { resources, schemaMap, kubernetesVersion }:
    let
      # Check for namespace references
      nsCheck = validateNamespaces resources;

      # Validate each resource
      resourceChecks = map (r: validateResource {
        resource = r;
        inherit schemaMap kubernetesVersion;
      }) resources;

      # All checks pass
      allPass = lib.all (checks: checks.apiVersion && checks.metadata && checks.namespace) resourceChecks;
    in
    if allPass then
      { ok = true; resourceCount = builtins.length resources; }
    else
      throw "Manifest validation failed";

  # Helper: create validation summary
  validationSummary = { resources, schemaMap, kubernetesVersion }:
    let
      result = validateManifest { inherit resources schemaMap kubernetesVersion; };
    in
    {
      success = result.ok or false;
      resourceCount = result.resourceCount or 0;
      kinds = lib.unique (map (r: r.kind) resources);
      namespaces = lib.unique (map (r: r.metadata.namespace or "default") resources);
    };
}
