{ lib, validators }:

let
  # Destructure the validators that were passed in
  inherit (validators) validateManifest getValidator validate;

  # Validate a manifest against its schema
  validateManifestStrict = manifest:
    let
      basicValidation = validateManifest manifest;
    in
    if !basicValidation.valid then
      basicValidation
    else
      let
        kind = manifest.kind or null;
        kindValidator = if kind != null then (getValidator kind) else null;
      in
      if kindValidator == null then
        { valid = false; errors = ["Unable to determine validator for kind: ${toString kind}"]; }
      else
        kindValidator manifest;

  # Validate multiple manifests
  validateManifests = manifests:
    let
      results = map validateManifestStrict manifests;
      allValid = builtins.all (r: r.valid) results;
      allErrors = lib.flatten (map (r: r.errors) (builtins.filter (r: !r.valid) results));
    in
    {
      valid = allValid;
      errors = allErrors;
      count = {
        total = builtins.length manifests;
        valid = builtins.length (builtins.filter (r: r.valid) results);
        invalid = builtins.length (builtins.filter (r: !r.valid) results);
      };
      details = results;
    };

  # Get all supported kinds
  supportedKinds = [
    "Certificate"
    "ClusterRole"
    "ClusterRoleBinding"
    "ConfigMap"
    "CronJob"
    "Deployment"
    "Ingress"
    "IngressClass"
    "Job"
    "Namespace"
    "NetworkPolicy"
    "Pod"
    "PersistentVolume"
    "PersistentVolumeClaim"
    "Role"
    "RoleBinding"
    "Secret"
    "Service"
    "ServiceAccount"
    "StatefulSet"
  ];

  # Check if a kind is supported
  isKindSupported = kind:
    builtins.elem kind supportedKinds;

  # Get schema/validator info for a kind
  getKindInfo = kind:
    if isKindSupported kind then
      {
        supported = true;
        validator = getValidator kind;
      }
    else
      {
        supported = false;
        validator = null;
        available = supportedKinds;
      };

  # Validate and return detailed report
  validateWithReport = manifest:
    let
      validation = validateManifestStrict manifest;
      kind = manifest.kind or null;
      apiVersion = manifest.apiVersion or null;
      name = (manifest.metadata or {}).name or null;
    in
    validation // {
      manifest = {
        kind = kind;
        apiVersion = apiVersion;
        name = name;
      };
    };

  # Validate a manifest file (from string content)
  validateFromString = content:
    let
      manifest = builtins.fromJSON content;
    in
    validateManifestStrict manifest;

in
{
  # Main validation functions
  inherit validateManifestStrict validateManifests;
  inherit supportedKinds isKindSupported getKindInfo;
  inherit validateWithReport validateFromString;

  # Re-export validators
  inherit validateManifest getValidator validate;
}
