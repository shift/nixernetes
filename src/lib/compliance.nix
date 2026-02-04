# Compliance & Labeling Engine
#
# This module provides:
# - Mandatory compliance label injection
# - Build-time enforcement of compliance fields
# - Traceability annotations (nix-build-id)

{ lib }:

let
  inherit (lib) mkOption types mkDefault attrsets;

  complianceLevel = types.enum [
    "unrestricted"
    "low"
    "medium"
    "high"
    "restricted"
  ];

in
{
  # Define compliance label requirements
  complianceLabelSchema = {
    options = {
      framework = mkOption {
        type = types.str;
        description = "Regulatory framework (e.g., PCI-DSS, HIPAA, SOC2)";
        example = "PCI-DSS";
      };

      level = mkOption {
        type = complianceLevel;
        default = "medium";
        description = "Compliance level for the resource";
      };

      owner = mkOption {
        type = types.str;
        description = "Team or person responsible for this resource";
        example = "platform-team";
      };

      dataClassification = mkOption {
        type = types.enum [ "public" "internal" "confidential" "restricted" ];
        default = "internal";
        description = "Data classification level";
      };

      auditRequired = mkOption {
        type = types.bool;
        default = false;
        description = "Whether audit logging is required";
      };
    };
  };

  # Generate standard compliance labels for a resource
  mkComplianceLabels = { framework, level, owner, dataClassification ? "internal", auditRequired ? false }:
    {
      "nixernetes.io/framework" = framework;
      "nixernetes.io/compliance-level" = level;
      "nixernetes.io/owner" = owner;
      "nixernetes.io/data-classification" = dataClassification;
    } // lib.optionalAttrs auditRequired {
      "nixernetes.io/audit-required" = "true";
    };

  # Inject compliance labels into a resource
  withComplianceLabels = { resource, labels }:
    let
      metadata = resource.metadata or {};
      existingLabels = metadata.labels or {};
    in
      resource // {
        metadata = metadata // {
          labels = existingLabels // labels;
        };
      };

  # Inject traceability annotation (nix-build-id would be set at build time)
  withTraceability = { resource, buildId ? "unknown" }:
    let
      metadata = resource.metadata or {};
      existingAnnotations = metadata.annotations or {};
    in
      resource // {
        metadata = metadata // {
          annotations = existingAnnotations // {
            "nixernetes.io/nix-build-id" = buildId;
            "nixernetes.io/managed-by" = "nixernetes";
          };
        };
      };

  # Validate that a resource has all required compliance labels
  validateComplianceLabels = { resource, requiredLabels }:
    let
      labels = resource.metadata.labels or {};
      missing = lib.filterAttrs (name: _: !(builtins.hasAttr name labels)) requiredLabels;
    in
      if missing == {} then
        true
      else
        throw "Missing compliance labels on ${resource.kind} ${resource.metadata.name or "unnamed"}: ${builtins.toJSON (builtins.attrNames missing)}";

  # Apply compliance to a list of resources
  applyCompliance = { resources, labels, buildId ? "unknown", validate ? true }:
    let
      withLabels = map (r: withComplianceLabels { resource = r; inherit labels; }) resources;
      withTrace = map (r: withTraceability { resource = r; buildId = buildId; }) withLabels;
    in
      if validate then
        map (r: validateComplianceLabels { resource = r; requiredLabels = labels; }) withTrace
      else
        withTrace;
}
