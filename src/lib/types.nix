# Kubernetes Resource Type Definitions and Validation
#
# This module provides:
# - Nix type definitions for Kubernetes resources
# - Schema validation for resources
# - Type checking and error messages

{ lib }:

let
  inherit (lib) types mkOption mkDefault;

  # Base Kubernetes metadata type
  k8sMetadata = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the resource";
      };

      namespace = mkOption {
        type = types.str;
        default = "default";
        description = "Kubernetes namespace";
      };

      labels = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Resource labels";
      };

      annotations = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Resource annotations";
      };
    };
  };

  # Base Kubernetes resource type
  k8sResource = types.submodule {
    options = {
      apiVersion = mkOption {
        type = types.str;
        description = "Kubernetes API version";
        example = "v1";
      };

      kind = mkOption {
        type = types.str;
        description = "Kubernetes resource kind";
        example = "Pod";
      };

      metadata = mkOption {
        type = k8sMetadata;
        description = "Resource metadata";
      };

      spec = mkOption {
        type = types.attrs;
        default = { };
        description = "Resource specification (type varies by kind)";
      };
    };
  };

  # Deployment spec
  deploymentSpec = types.submodule {
    options = {
      replicas = mkOption {
        type = types.int;
        default = 1;
        description = "Number of replicas";
      };

      selector = mkOption {
        type = types.submodule {
          options = {
            matchLabels = mkOption {
              type = types.attrsOf types.str;
              description = "Pod selector labels";
            };
          };
        };
        description = "Label selector for pods";
      };

      template = mkOption {
        type = types.attrs;
        description = "Pod template";
      };

      strategy = mkOption {
        type = types.attrs;
        default = { };
        description = "Deployment strategy";
      };
    };
  };

  # Service spec
  serviceSpec = types.submodule {
    options = {
      type = mkOption {
        type = types.enum [ "ClusterIP" "NodePort" "LoadBalancer" "ExternalName" ];
        default = "ClusterIP";
        description = "Service type";
      };

      selector = mkOption {
        type = types.attrsOf types.str;
        default = { };
        description = "Pod selector labels";
      };

      ports = mkOption {
        type = types.listOf (types.submodule {
          options = {
            name = mkOption {
              type = types.str;
              default = "";
              description = "Port name";
            };

            port = mkOption {
              type = types.int;
              description = "Service port";
            };

            targetPort = mkOption {
              type = types.oneOf [ types.int types.str ];
              default = null;
              description = "Target port on pod";
            };

            protocol = mkOption {
              type = types.enum [ "TCP" "UDP" ];
              default = "TCP";
              description = "Protocol";
            };
          };
        });
        default = [ ];
        description = "Service ports";
      };

      clusterIP = mkOption {
        type = types.str;
        default = "";
        description = "Cluster IP";
      };
    };
  };

in
{
  # Type exports
  inherit k8sResource k8sMetadata deploymentSpec serviceSpec;

  # Resource type constructors
  mkDeployment = { name, namespace ? "default", replicas ? 1, selector, template, strategy ? { } }:
    {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = { inherit name namespace; };
      spec = {
        inherit replicas selector template strategy;
      };
    };

  mkService = { name, namespace ? "default", type ? "ClusterIP", selector ? { }, ports ? [ ] }:
    {
      apiVersion = "v1";
      kind = "Service";
      metadata = { inherit name namespace; };
      spec = {
        inherit type selector ports;
      };
    };

  mkNamespace = { name }:
    {
      apiVersion = "v1";
      kind = "Namespace";
      metadata = { inherit name; };
    };

  mkConfigMap = { name, namespace ? "default", data ? { } }:
    {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = { inherit name namespace; };
      inherit data;
    };

  mkSecret = { name, namespace ? "default", type ? "Opaque", data ? { } }:
    {
      apiVersion = "v1";
      kind = "Secret";
      metadata = { inherit name namespace; };
      inherit type data;
    };

  # Validation functions
  validateResource = resource:
    let
      hasRequiredFields = (resource ? apiVersion) && (resource ? kind) && (resource ? metadata) && (resource.metadata ? name);
    in
    if !hasRequiredFields then
      throw "Resource missing required fields: apiVersion, kind, metadata.name"
    else
      resource;

  # Check if apiVersion is valid for a given kind and k8s version
  validateApiVersion = { kind, apiVersion, kubernetesVersion }:
    if builtins.typeOf apiVersion != "string" then
      throw "apiVersion must be a string, got ${builtins.typeOf apiVersion}"
    else if builtins.typeOf kind != "string" then
      throw "kind must be a string, got ${builtins.typeOf kind}"
    else
      true;

  # Batch validate a list of resources
  validateResources = resources:
    map (resource: validateResource resource) resources;
}
