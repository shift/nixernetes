# Compliance Enforcement and Policy Generation
#
# This module provides:
# - Compliance policy definitions
# - Automatic policy injection
# - Compliance level-based configuration
# - Policy validation and enforcement

{ lib }:

let
  inherit (lib) types mkOption mkDefault mkEnableOption concatStringsSep;

  # Compliance level definitions
  complianceLevelDefs = {
    unrestricted = {
      description = "No compliance requirements";
      auditRequired = false;
      encryptionRequired = false;
      rbacRequired = false;
      networkPolicyRequired = false;
      podSecurityPolicy = "baseline";
    };

    low = {
      description = "Basic compliance requirements";
      auditRequired = true;
      encryptionRequired = false;
      rbacRequired = true;
      networkPolicyRequired = false;
      podSecurityPolicy = "baseline";
    };

    medium = {
      description = "Standard compliance requirements";
      auditRequired = true;
      encryptionRequired = true;
      rbacRequired = true;
      networkPolicyRequired = true;
      podSecurityPolicy = "restricted";
      requiredLabels = [ "framework" "owner" "dataClassification" ];
    };

    high = {
      description = "Strict compliance requirements";
      auditRequired = true;
      encryptionRequired = true;
      rbacRequired = true;
      networkPolicyRequired = true;
      podSecurityPolicy = "restricted";
      requiredLabels = [ "framework" "owner" "dataClassification" ];
      mutualTLS = true;
    };

    restricted = {
      description = "Maximum compliance requirements";
      auditRequired = true;
      encryptionRequired = true;
      rbacRequired = true;
      networkPolicyRequired = true;
      podSecurityPolicy = "restricted";
      requiredLabels = [ "framework" "owner" "dataClassification" "auditId" ];
      mutualTLS = true;
      imageScan = true;
      binaryAuthorization = true;
    };
  };

in
{
  # Get compliance requirements for a level
  getComplianceRequirements = level:
    complianceLevelDefs.${level}
      or (throw "Unknown compliance level: ${level}");

  # All available compliance levels
  availableLevels = builtins.attrNames complianceLevelDefs;

  # Validate compliance level
  isValidLevel = level: builtins.elem level (builtins.attrNames complianceLevelDefs);

  # Generate required labels for a compliance level
  getRequiredLabels = level:
    let
      reqs = complianceLevelDefs.${level}
        or (throw "Unknown compliance level: ${level}");
    in
    reqs.requiredLabels or [ ];

  # Check if resource meets compliance requirements
  checkCompliance = { resource, level }:
    let
      reqs = getComplianceRequirements level;
      labels = resource.metadata.labels or { };

      # Check for required labels
      requiredLabels = reqs.requiredLabels or [ ];
      missingLabels = lib.filter (label:
        !(builtins.hasAttr "nixernetes.io/${label}" labels)
      ) requiredLabels;

      # Check for audit annotations
      hasAuditAnnotations = (resource.metadata.annotations or { }) ? "nixernetes.io/audit-id";

    in
    {
      compliant = missingLabels == [ ] && (if reqs.auditRequired then hasAuditAnnotations else true);
      missingLabels = missingLabels;
      requirements = reqs;
    };

  # Generate compliance report for resources
  generateComplianceReport = { resources, level }:
    let
      results = map (resource: {
        resource = resource.kind + "/" + resource.metadata.name;
        check = checkCompliance { inherit resource level; };
      }) resources;

      compliant = lib.filter (r: r.check.compliant) results;
      noncompliant = lib.filter (r: !r.check.compliant) results;
    in
    {
      total = builtins.length resources;
      compliant = builtins.length compliant;
      noncompliant = builtins.length noncompliant;
      complianceRate = (builtins.length compliant) / (builtins.length resources);
      level = level;
      failures = noncompliant;
    };

  # Inject compliance annotations based on level
  injectComplianceAnnotations = { resource, level, buildId ? "unknown" }:
    let
      reqs = getComplianceRequirements level;
      metadata = resource.metadata // {
        annotations = (resource.metadata.annotations or { }) // {
          "nixernetes.io/compliance-level" = level;
          "nixernetes.io/nix-build-id" = buildId;
          "nixernetes.io/managed-by" = "nixernetes";
        } // lib.optionalAttrs reqs.auditRequired {
          "nixernetes.io/audit-required" = "true";
        };
      };
    in
    resource // { inherit metadata; };

  # Apply compliance enforcement to resources
  enforceCompliance = { resources, level, buildId ? "unknown", failOnNoncompliant ? true }:
    let
      withAnnotations = map (r: injectComplianceAnnotations {
        resource = r;
        inherit level buildId;
      }) resources;

      report = generateComplianceReport {
        resources = withAnnotations;
        inherit level;
      };
    in
    if failOnNoncompliant && report.noncompliant > 0 then
      throw "Compliance enforcement failed: ${toString report.noncompliant}/${toString report.total} resources non-compliant. Failures: ${concatStringsSep ", " (map (f: f.resource) report.failures)}"
    else
      {
        inherit resources withAnnotations report;
        success = report.noncompliant == 0;
      };

  # Create a compliance audit trail
  mkAuditTrail = { resources, level, timestamp, commitId ? "unknown" }:
    {
      timestamp = timestamp;
      commit = commitId;
      level = level;
      resourceCount = builtins.length resources;
      kinds = lib.unique (map (r: r.kind) resources);
      namespaces = lib.unique (map (r: r.metadata.namespace or "default") resources);
      report = generateComplianceReport { inherit resources level; };
    };
}
