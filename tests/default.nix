# Test Suite for Nixernetes
#
# This file contains basic tests for core functionality

{ lib, pkgs, ... }:

let
  inherit (lib) mkTest;
  
  # Import our modules
  schema = import ../src/lib/schema.nix { inherit lib; };
  compliance = import ../src/lib/compliance.nix { inherit lib; };
  policies = import ../src/lib/policies.nix { inherit lib; };

in
{
  # Test: API version resolution works correctly
  testApiVersionResolution = {
    expr = schema.resolveApiVersion {
      kind = "Deployment";
      kubernetesVersion = "1.30";
    };
    expected = "apps/v1";
  };

  # Test: Unsupported version throws error
  testUnsupportedVersionThrows = {
    expr = builtins.tryEval (
      schema.resolveApiVersion {
        kind = "Deployment";
        kubernetesVersion = "1.99";
      }
    );
    expected = { success = false; value = null; };
  };

  # Test: Compliance label generation works
  testComplianceLabelGeneration = {
    expr = compliance.mkComplianceLabels {
      framework = "PCI-DSS";
      level = "high";
      owner = "platform-team";
    };
    expected = {
      "nixernetes.io/framework" = "PCI-DSS";
      "nixernetes.io/compliance-level" = "high";
      "nixernetes.io/owner" = "platform-team";
      "nixernetes.io/data-classification" = "internal";
    };
  };

  # Test: Compliance label injection works
  testComplianceLabelInjection = {
    expr = 
      let
        resource = {
          apiVersion = "v1";
          kind = "Pod";
          metadata = { name = "test"; };
          spec = {};
        };
        labels = {
          "nixernetes.io/framework" = "SOC2";
        };
        result = compliance.withComplianceLabels { inherit resource labels; };
      in
        result.metadata.labels."nixernetes.io/framework";
    expected = "SOC2";
  };

  # Test: Traceability annotation injection works
  testTraceabilityAnnotation = {
    expr =
      let
        resource = {
          apiVersion = "v1";
          kind = "Pod";
          metadata = { name = "test"; };
          spec = {};
        };
        result = compliance.withTraceability { resource = resource; buildId = "abc123"; };
      in
        result.metadata.annotations."nixernetes.io/nix-build-id";
    expected = "abc123";
  };

  # Test: Default deny network policy generation
  testDefaultDenyNetworkPolicy = {
    expr =
      let
        policy = policies.mkDefaultDenyNetworkPolicy {
          name = "test-app";
          namespace = "default";
          apiVersion = "networking.k8s.io/v1";
        };
      in
        policy.kind;
    expected = "NetworkPolicy";
  };

  # Test: Kyverno compliance policy generation
  testKyvernoCompliancePolicy = {
    expr =
      let
        policy = policies.mkComplianceClusterPolicy {
          framework = "PCI-DSS";
          level = "high";
        };
      in
        policy.kind;
    expected = "ClusterPolicy";
  };
}
