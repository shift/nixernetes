{ lib }:

let
  # Import the auto-generated API version mappings
  apiVersions = import ./api-versions-generated.nix { inherit lib; };
  
  # Import the auto-generated validators
  validators = import ./validators-generated.nix { inherit lib; };
  
  # Import the manifest validation utilities
  manifestValidation = import ./manifest-validation.nix { inherit lib validators; };

in
{
  # API version resolution and mapping
  inherit (apiVersions)
    resolveApiVersion
    getSupportedVersions
    isSupportedVersion
    getApiMap;
  
  # Schema validation
  inherit (manifestValidation)
    validateManifestStrict
    validateManifests
    supportedKinds
    isKindSupported
    getKindInfo
    validateWithReport
    validateFromString;
  
  # Low-level validators (for advanced use)
  inherit (validators)
    validateManifest
    getValidator
    validate;
}
