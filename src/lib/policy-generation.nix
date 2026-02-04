# Advanced Policy Generation Framework
#
# This module provides:
# - Smart policy generation from intent declarations
# - RBAC policy generation
# - Network topology analysis
# - Policy composition and merging

{ lib }:

let
  inherit (lib) concatStringsSep mkOption types;

  # Policy merge strategies
  mergeIngressRules = rules:
    let
      uniqueRules = lib.unique rules;
    in
    lib.foldl (acc: rule:
      acc ++ [ rule ]
    ) [ ] uniqueRules;

  # Create port specification
  mkPort = { protocol ? "TCP", port }:
    {
      inherit protocol port;
    };

in
{
  # Generate RBAC policy for service account
  mkServiceAccountRBAC = { name, namespace, permissions }:
    let
      roles = map (perm:
        {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "Role";
          metadata = {
            name = "${name}-${perm.name}";
            inherit namespace;
          };
          rules = perm.rules;
        }
      ) permissions;

      roleBindings = map (perm:
        {
          apiVersion = "rbac.authorization.k8s.io/v1";
          kind = "RoleBinding";
          metadata = {
            name = "${name}-${perm.name}";
            inherit namespace;
          };
          roleRef = {
            apiGroup = "rbac.authorization.k8s.io";
            kind = "Role";
            name = "${name}-${perm.name}";
          };
          subjects = [
            {
              kind = "ServiceAccount";
              inherit name namespace;
            }
          ];
        }
      ) permissions;
    in
    {
      inherit roles roleBindings;
      all = roles ++ roleBindings;
    };

  # Generate pod security policy
  mkPodSecurityPolicy = { name, level }:
    let
      basePolicy = {
        apiVersion = "policy/v1beta1";
        kind = "PodSecurityPolicy";
        metadata = { inherit name; };
        spec = {
          privileged = false;
          allowPrivilegeEscalation = false;
          runAsUser = { rule = "MustRunAsNonRoot"; };
          seLinux = { rule = "MustRunAs"; ranges = [ { min = 1000; max = 65535; } ]; };
          fsGroup = { rule = "MustRunAs"; ranges = [ { min = 1000; max = 65535; } ]; };
          readOnlyRootFilesystem = true;
          volumes = [ "configMap" "emptyDir" "projected" "secret" "downwardAPI" "persistentVolumeClaim" ];
          hostNetwork = false;
          hostIPC = false;
          hostPID = false;
          allowedCapabilities = [ ];
          requiredDropCapabilities = [ "ALL" ];
          defaultAddCapabilities = [ ];
        };
      };

      # Enhanced for "high" level
      highPolicy = basePolicy // {
        spec = basePolicy.spec // {
          runAsUser = { rule = "MustRunAs"; ranges = [ { min = 1000; max = 1000; } ]; };
          seLinux = { rule = "MustRunAs"; seLinuxOptions = { level = "s0:c123,c456"; }; };
        };
      };
    in
    if level == "high" then highPolicy else basePolicy;

  # Generate network policy for application communication
  mkCommunicationNetworkPolicy = { namespace, app, allowedClients ? [ ] }:
    {
      apiVersion = "networking.k8s.io/v1";
      kind = "NetworkPolicy";
      metadata = {
        name = "${app}-ingress-allow";
        inherit namespace;
        labels = {
          "nixernetes.io/policy-type" = "communication";
          "nixernetes.io/app" = app;
        };
      };
      spec = {
        podSelector = {
          matchLabels = {
            "app.kubernetes.io/name" = app;
          };
        };
        policyTypes = [ "Ingress" ];
        ingress = [
          {
            from = allowedClients ++ [
              {
                namespaceSelector = {
                  matchLabels = {
                    "name" = namespace;
                  };
                };
              }
            ];
            ports = [
              { protocol = "TCP"; port = 8080; }
            ];
          }
        ];
      };
    };

  # Generate egress policy for external calls
  mkEgressPolicy = { namespace, app, allowedEndpoints }:
    let
      buildEgressRule = endpoint: {
        to = [
          {
            namespaceSelector = {
              matchLabels = {
                "name" = endpoint.namespace or "default";
              };
            };
          }
        ] ++ lib.optionalAttrs (endpoint ? cidr) [
          {
            ipBlock = {
              cidr = endpoint.cidr;
            };
          }
        ];
        ports = map (p: { protocol = p.protocol or "TCP"; port = p.port; }) endpoint.ports;
      };
    in
    {
      apiVersion = "networking.k8s.io/v1";
      kind = "NetworkPolicy";
      metadata = {
        name = "${app}-egress-allow";
        inherit namespace;
        labels = {
          "nixernetes.io/policy-type" = "egress";
          "nixernetes.io/app" = app;
        };
      };
      spec = {
        podSelector = {
          matchLabels = {
            "app.kubernetes.io/name" = app;
          };
        };
        policyTypes = [ "Egress" ];
        egress = map buildEgressRule allowedEndpoints ++ [
          # Allow DNS
          {
            to = [
              {
                namespaceSelector = {
                  matchLabels = {
                    "name" = "kube-system";
                  };
                };
              }
            ];
            ports = [
              { protocol = "UDP"; port = 53; }
            ];
          }
        ];
      };
    };

  # Generate complete policy set for application
  mkApplicationPolicies = { name, namespace, apiVersion, dependencies ? [ ], exposedPorts ? [ 8080 ], allowedClients ? [ ] }:
    let
      # Default deny everything
      defaultDeny = {
        apiVersion = apiVersion;
        kind = "NetworkPolicy";
        metadata = {
          name = "${name}-default-deny";
          inherit namespace;
          labels = {
            "nixernetes.io/policy-type" = "default-deny";
            "nixernetes.io/app" = name;
          };
        };
        spec = {
          podSelector = {
            matchLabels = {
              "app.kubernetes.io/name" = name;
            };
          };
          policyTypes = [ "Ingress" "Egress" ];
          ingress = [ ];
          egress = [ ];
        };
      };

      # Allow to dependencies
      dependencyPolicy = {
        apiVersion = apiVersion;
        kind = "NetworkPolicy";
        metadata = {
          name = "${name}-allow-dependencies";
          inherit namespace;
          labels = {
            "nixernetes.io/policy-type" = "dependency";
            "nixernetes.io/app" = name;
          };
        };
        spec = {
          podSelector = {
            matchLabels = {
              "app.kubernetes.io/name" = name;
            };
          };
          policyTypes = [ "Egress" ];
          egress = map (dep: {
            to = [
              {
                podSelector = {
                  matchLabels = {
                    "app.kubernetes.io/name" = dep;
                  };
                };
              }
            ];
            ports = [ { protocol = "TCP"; port = 5432; } ]; # TODO: make configurable
          }) dependencies ++ [
            # Allow DNS
            {
              to = [
                {
                  namespaceSelector = {
                    matchLabels = {
                      "name" = "kube-system";
                    };
                  };
                }
              ];
              ports = [ { protocol = "UDP"; port = 53; } ];
            }
          ];
        };
      };

      # Allow from clients
      ingressPolicy = {
        apiVersion = apiVersion;
        kind = "NetworkPolicy";
        metadata = {
          name = "${name}-allow-ingress";
          inherit namespace;
          labels = {
            "nixernetes.io/policy-type" = "ingress";
            "nixernetes.io/app" = name;
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
              from = allowedClients;
              ports = map (p: { protocol = "TCP"; port = p; }) exposedPorts;
            }
          ];
        };
      };
    in
    {
      defaultDeny = defaultDeny;
      dependencies = dependencyPolicy;
      ingress = ingressPolicy;
      all = [ defaultDeny dependencyPolicy ingressPolicy ];
    };

  # Analyze traffic patterns and generate optimized policies
  optimizePolicies = { policies }:
    let
      # Merge policies with same selector and direction
      merged = lib.foldl (acc: policy:
        acc # Simplified for now
      ) { } policies;
    in
    policies; # Return as-is for now
}
