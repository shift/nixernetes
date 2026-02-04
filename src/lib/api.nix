# Multi-Layer Abstraction API
#
# Layer 1: Raw Kubernetes resources
# Layer 2: Convenience modules (Deployment, Service, etc.)
# Layer 3: High-level applications

{ lib, pkgs }:

let
  inherit (lib) mkOption types mkDefault;

  types_module = import ./types.nix { inherit lib; };
  schema = import ./schema.nix { inherit lib; };

in
{
  # Layer 1: Raw resource definition
  layer1 = {
    resource = types_module.k8sResource;
  };

  # Layer 2: Convenience builders for common patterns
  layer2 = {
    # Deployment builder
    deployment = { name, namespace ? "default", image, replicas ? 2, ports ? [ 8080 ], resources ? { } }:
      {
        apiVersion = "apps/v1";
        kind = "Deployment";
        metadata = { inherit name namespace; };
        spec = {
          inherit replicas;
          selector.matchLabels = { "app.kubernetes.io/name" = name; };
          template = {
            metadata.labels = { "app.kubernetes.io/name" = name; };
            spec = {
              containers = [ {
                inherit name image;
                ports = map (p: { containerPort = p; }) ports;
                inherit resources;
              } ];
            };
          };
        };
      };

    # Service builder
    service = { name, namespace ? "default", port ? 8080, targetPort ? null, type ? "ClusterIP", selector ? { } }:
      {
        apiVersion = "v1";
        kind = "Service";
        metadata = { inherit name namespace; };
        spec = {
          inherit type;
          selector = selector // { "app.kubernetes.io/name" = name; };
          ports = [ {
            inherit port;
            targetPort = targetPort or port;
            protocol = "TCP";
          } ];
        };
      };

    # ConfigMap builder
    configMap = { name, namespace ? "default", data ? { } }:
      {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = { inherit name namespace; };
        inherit data;
      };

    # Namespace builder
    namespace = { name, labels ? { } }:
      {
        apiVersion = "v1";
        kind = "Namespace";
        metadata = { inherit name labels; };
      };
  };

  # Layer 3: High-level application abstractions
  layer3 = {
    # Application definition
    application = { 
      name, 
      namespace ? "default", 
      image, 
      replicas ? 2, 
      ports ? [ 8080 ], 
      compliance ? { },
      dependencies ? [ ],
      resources ? { },
    }:
      let
        compliance_module = import ./compliance.nix { inherit lib; };
        
        # Base deployment
        baseDeployment = lib.layer2.deployment {
          inherit name namespace image replicas ports resources;
        };

        # Apply compliance labels
        withCompliance = 
          if compliance != { } then
            let
              labels = compliance_module.mkComplianceLabels {
                framework = compliance.framework or "SOC2";
                level = compliance.level or "medium";
                owner = compliance.owner or "unknown";
                dataClassification = compliance.dataClassification or "internal";
                auditRequired = compliance.auditRequired or false;
              };
            in
            baseDeployment // {
              metadata = baseDeployment.metadata // {
                labels = (baseDeployment.metadata.labels or { }) // labels;
              };
              spec = baseDeployment.spec // {
                template = baseDeployment.spec.template // {
                  metadata = baseDeployment.spec.template.metadata // {
                    labels = (baseDeployment.spec.template.metadata.labels or { }) // labels;
                  };
                };
              };
            }
          else
            baseDeployment;
      in
      {
        deployment = withCompliance;
        service = lib.layer2.service { inherit name namespace; ports = ports; };
        resources = [ withCompliance ];
        inherit dependencies compliance;
      };
  };

  # API surface
  layer1 = {
    inherit (layer1) resource;
  };

  layer2 = layer2;

  layer3 = layer3;
}
