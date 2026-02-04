# Schema and API Version Resolution
# 
# This module handles:
# - API version resolution for different Kubernetes versions
# - Mapping of resource kinds to their preferred apiVersions
# - Version compatibility checking
#
# The apiVersionMatrix is auto-generated from Kubernetes OpenAPI specifications.
# To regenerate: nix run .#generate-api-versions

{ lib }:

let
  inherit (lib) mkDefault mapAttrs;

  # Import auto-generated API version mappings
  # This file is generated using the api_schema_parser.py tool
  # by parsing upstream Kubernetes OpenAPI specifications
  generatedVersions = import ./api-versions-generated.nix { inherit lib; };

in
  # Expose the generated module's functions
  generatedVersions
