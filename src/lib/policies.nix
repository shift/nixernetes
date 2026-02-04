# Zero-Trust Policy Generation
#
# This module generates:
# - NetworkPolicies for default-deny and explicit allow rules
# - Kyverno ClusterPolicies for admission control
# - RBAC policies based on workload requirements

{ lib }:

let
  inherit (lib) mkOption types;

in
{
  # Generate a default-deny NetworkPolicy
  mkDefaultDenyNetworkPolicy = { name, namespace, apiVersion }:
    {
      inherit apiVersion;
      kind = "NetworkPolicy";
      metadata = {
        name = "${name}-default-deny";
        inherit namespace;
        labels = {
          "nixernetes.io/policy-type" = "default-deny";
          "nixernetes.io/resource" = name;
        };
      };
      spec = {
        podSelector = {
          matchLabels = {
            "app.kubernetes.io/name" = name;
          };
        };
        policyTypes = [ "Ingress" "Egress" ];
        # Default deny everything
        ingress = [];
        egress = [];
      };
    };

  # Generate a NetworkPolicy allowing specific dependencies
  mkDependencyNetworkPolicy = { name, namespace, apiVersion, dependencies }:
    let
      # Build egress rules for each dependency
      egressRules = map (dep: {
        to = [
          {
            podSelector = {
              matchLabels = {
                "app.kubernetes.io/name" = dep;
              };
            };
          }
        ];
        ports = [
          { protocol = "TCP"; port = 5432; } # Default to postgres, should be configurable
        ];
      }) dependencies;
    in
    {
      inherit apiVersion;
      kind = "NetworkPolicy";
      metadata = {
        name = "${name}-dependencies";
        inherit namespace;
        labels = {
          "nixernetes.io/policy-type" = "dependency";
          "nixernetes.io/resource" = name;
        };
      };
      spec = {
        podSelector = {
          matchLabels = {
            "app.kubernetes.io/name" = name;
          };
        };
        policyTypes = [ "Egress" ];
        egress = egressRules;
      };
    };

  # Generate a NetworkPolicy allowing ingress on specific ports
  mkIngressNetworkPolicy = { name, namespace, apiVersion, ports, allowFrom ? [] }:
    {
      inherit apiVersion;
      kind = "NetworkPolicy";
      metadata = {
        name = "${name}-ingress";
        inherit namespace;
        labels = {
          "nixernetes.io/policy-type" = "ingress";
          "nixernetes.io/resource" = name;
        };
      };
      spec = {
        podSelector = {
          matchLabels = {
            "app.kubernetes.io/name" = name;
          };
        };
        policyTypes = [ "Ingress" ];
        ingress = [
          {
            from = allowFrom;
            ports = map (p: {
              protocol = "TCP";
              port = p;
            }) ports;
          }
        ];
      };
    };

  # Generate a Kyverno ClusterPolicy to enforce compliance labels
  mkComplianceClusterPolicy = { framework, level }:
    {
      apiVersion = "kyverno.io/v1";
      kind = "ClusterPolicy";
      metadata = {
        name = "enforce-compliance-labels";
        labels = {
          "nixernetes.io/policy-type" = "compliance";
        };
      };
      spec = {
        validationFailureAction = "Enforce";
        rules = [
          {
            name = "check-compliance-labels";
            match = {
              any = [
                {
                  resources = {
                    kinds = [ "Pod" "Deployment" "StatefulSet" "DaemonSet" ];
                  };
                }
              ];
            };
            validate = {
              message = "Pod must have compliance labels for framework: ${framework}, level: ${level}";
              pattern = {
                metadata = {
                  labels = {
                    "nixernetes.io/framework" = framework;
                    "nixernetes.io/compliance-level" = level;
                  };
                };
              };
            };
          }
        ];
      };
    };

  # Generate a Kyverno ClusterPolicy for mutation (e.g., add sidecars)
  mkMutationClusterPolicy = { name, mutation }:
    {
      apiVersion = "kyverno.io/v1";
      kind = "ClusterPolicy";
      metadata = {
        name = "${name}-mutation";
        labels = {
          "nixernetes.io/policy-type" = "mutation";
        };
      };
      spec = {
        validationFailureAction = "Audit";
        rules = [
          {
            name = "apply-mutation";
            match = {
              any = [
                {
                  resources = {
                    kinds = [ "Pod" ];
                  };
                }
              ];
            };
            mutate = mutation;
          }
        ];
      };
    };
}
