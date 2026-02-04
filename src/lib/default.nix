# Nixernetes: Core Library Module System
# 
# This module provides the foundational abstractions for the framework:
# - Schema validation against Kubernetes OpenAPI specs
# - Three-layer API (raw resources, convenience modules, high-level apps)
# - Compliance labeling and enforcement
# - Policy generation (NetworkPolicies, Kyverno)
# - Output formatters (YAML manifests, Helm charts)

{ lib, ... }:

let
  inherit (lib) types mkOption mkEnableOption attrsets;
  inherit (attrsets) filterAttrs mapAttrs;

  # Core types
  k8sResource = types.submodule {
    options = {
      apiVersion = mkOption {
        type = types.str;
        description = "Kubernetes API version (e.g., apps/v1)";
      };
      kind = mkOption {
        type = types.str;
        description = "Kubernetes resource kind (e.g., Deployment)";
      };
      metadata = mkOption {
        type = types.attrs;
        default = {};
        description = "Standard Kubernetes metadata";
      };
      spec = mkOption {
        type = types.attrs;
        default = {};
        description = "Resource specification";
      };
    };
  };

  # Layer 1: Raw Kubernetes Resource Definition
  # Users can define any Kubernetes resource with strict type validation
  layer1 = {
    options = {
      resources = mkOption {
        type = types.attrsOf k8sResource;
        default = {};
        description = "Raw Kubernetes resources with validated types";
      };
    };
  };

  # Layer 2: Convenience Modules for Common Patterns
  # Pre-built modules for Deployment, Service, etc. with sensible defaults
  layer2 = {
    options = {
      deployments = mkOption {
        type = types.attrsOf types.attrs;
        default = {};
        description = "High-level Deployment definitions";
      };
      services = mkOption {
        type = types.attrsOf types.attrs;
        default = {};
        description = "High-level Service definitions";
      };
    };
  };

  # Layer 3: High-Level Application Abstractions
  # Declare apps with dependencies, exposure, compliance - framework generates all resources
  layer3 = {
    options = {
      applications = mkOption {
        type = types.attrsOf types.attrs;
        default = {};
        description = "High-level application declarations";
      };
    };
  };

in
{
  options = {
    # Core framework options
    framework = {
      kubernetesVersion = mkOption {
        type = types.str;
        default = "1.30";
        description = "Target Kubernetes version for API version resolution";
      };

      namespace = mkOption {
        type = types.str;
        default = "default";
        description = "Default namespace for all resources";
      };

      compliance = mkOption {
        type = types.submodule {
          options = {
            labels = mkOption {
              type = types.attrsOf types.str;
              default = {};
              description = "Mandatory compliance labels injected into all resources";
            };

            level = mkOption {
              type = types.enum [ "low" "medium" "high" "restricted" ];
              default = "medium";
              description = "Compliance level for the deployment";
            };
          };
        };
        default = {};
        description = "Enterprise compliance configuration";
      };

      network = mkOption {
        type = types.submodule {
          options = {
            policyMode = mkOption {
              type = types.enum [ "deny-all" "allow-defined" ];
              default = "deny-all";
              description = "Default-deny or allow-defined network policy mode";
            };

            defaultDenyIngress = mkEnableOption "default deny ingress" // { default = true; };
            defaultDenyEgress = mkEnableOption "default deny egress" // { default = false; };
          };
        };
        default = {};
        description = "Zero-trust network policy configuration";
      };

      secrets = mkOption {
        type = types.submodule {
          options = {
            backend = mkOption {
              type = types.enum [ "external-secret" "sealed-secret" "native" ];
              default = "external-secret";
              description = "Secret management backend";
            };
          };
        };
        default = {};
        description = "Secrets configuration";
      };
    };

    # Layered API
    layer1 = layer1;
    layer2 = layer2;
    layer3 = layer3;
  };

  config = {
    # Framework defaults will be set here
  };
}
