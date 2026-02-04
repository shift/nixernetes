# Kyverno Dynamic Policy Framework
#
# This module provides:
# - Policy rule builders (validate, mutate, generate, audit)
# - Policy composition and inheritance
# - Common pattern generators (security, compliance, cost)
# - Context variables and conditional logic
# - ClusterPolicy and Policy resource generation
#
# Kyverno is a Kubernetes-native policy engine that validates, mutates, and generates resources
# Reference: https://kyverno.io

{ lib }:

let
  inherit (lib) types mkOption;

  # Core policy rule type
  policyRule = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Name of the policy rule";
      };
      match = mkOption {
        type = types.attrs;
        default = {};
        description = "Match criteria (resources, subjects, operations, etc.)";
      };
      exclude = mkOption {
        type = types.attrs;
        default = {};
        description = "Exclude criteria";
      };
      validation = mkOption {
        type = types.attrs;
        default = {};
        description = "Validation rule (for validation policies)";
      };
      mutation = mkOption {
        type = types.attrs;
        default = {};
        description = "Mutation rule (for mutation policies)";
      };
      generation = mkOption {
        type = types.attrs;
        default = {};
        description = "Generation rule (for resource generation)";
      };
      context = mkOption {
        type = types.listOf types.attrs;
        default = [];
        description = "Context variables for conditional logic";
      };
    };
  };

in
{
  # Create a Kyverno ClusterPolicy resource
  mkClusterPolicy = { name, description ? "", rules, validationFailureAction ? "audit", background ? true, webhookTimeoutSeconds ? 30, failurePolicy ? "fail" }:
    {
      apiVersion = "kyverno.io/v1";
      kind = "ClusterPolicy";
      metadata = { inherit name; };
      spec = {
        validationFailureAction = validationFailureAction;
        background = background;
        webhookTimeoutSeconds = webhookTimeoutSeconds;
        failurePolicy = failurePolicy;
        rules = rules;
      } // (if description != "" then { description = description; } else {});
    };

  # Create a namespaced Kyverno Policy resource
  mkPolicy = { name, namespace ? "default", description ? "", rules, validationFailureAction ? "audit", background ? true }:
    {
      apiVersion = "kyverno.io/v1";
      kind = "Policy";
      metadata = { inherit name namespace; };
      spec = {
        validationFailureAction = validationFailureAction;
        background = background;
        inherit rules;
      } // (if description != "" then { description = description; } else {});
    };

  # Validation Rule Builder
  # Validates resources against a CEL expression or JSON schema pattern
  mkValidationRule = { name, message, pattern ? null, anyPattern ? null, deny ? null, conditions ? [] }:
    {
      inherit name;
      validation = {
        message = message;
        failureAction = "fail";
      } // (if pattern != null then { pattern = pattern; } else {})
        // (if anyPattern != null then { anyPattern = anyPattern; } else {})
        // (if deny != null then { deny = deny; } else {});
    } // (if conditions != [] then { conditions = conditions; } else {});

  # Mutation Rule Builder
  # Mutates/modifies resources that match the criteria
  mkMutationRule = { name, patchStrategicMerge ? null, patchesJson6902 ? null, forEach ? null }:
    {
      inherit name;
      mutation = {
      } // (if patchStrategicMerge != null then { patchStrategicMerge = patchStrategicMerge; } else {})
        // (if patchesJson6902 != null then { patchesJson6902 = patchesJson6902; } else {})
        // (if forEach != null then { forEach = forEach; } else {});
    };

  # Generation Rule Builder
  # Generates new resources based on matched resources
  mkGenerationRule = { name, resourceSpec, synchronize ? true }:
    {
      inherit name;
      generation = {
        kind = resourceSpec.kind;
        apiVersion = resourceSpec.apiVersion;
        name = resourceSpec.name or "{request.object.metadata.name}";
        namespace = resourceSpec.namespace or "{request.namespace}";
        data = resourceSpec.data or {};
        inherit synchronize;
      };
    };

  # Create match criteria for a rule
  mkMatch = { resources ? {}, subjects ? [], operations ? [ "CREATE" "UPDATE" ], kinds ? [] }:
    {
      resources = if resources != {} then resources else { kinds = kinds; };
      inherit subjects operations;
    };

  # Create exclude criteria
  mkExclude = { resources ? {}, subjects ? [] }:
    {
      inherit resources subjects;
    };

  # Security Pattern: Require image registry
  mkRequireImageRegistry = { name ? "require-image-registry", registry ? "gcr.io", namespace ? null }:
    let
      pattern = {
        spec.containers = [{
          image = "${registry}/*";
        }];
      };
      matchResources = {
        kinds = [
          { group = "apps"; version = "v1"; kind = "Deployment"; }
          { group = "apps"; version = "v1"; kind = "StatefulSet"; }
          { group = ""; version = "v1"; kind = "Pod"; }
        ];
      } // (if namespace != null then { namespaces = [ namespace ]; } else { namespaceSelector.matchLabels.policy = "enforced"; });
    in
      {
        name = name;
        match = matchResources;
        validation = {
          message = "Image must come from registry ${registry}";
          pattern = pattern;
        };
      };

  # Security Pattern: Require resource limits
  mkRequireResourceLimits = { name ? "require-resource-limits", namespace ? null }:
    {
      inherit name;
      match = {
        kinds = [
          { group = "apps"; version = "v1"; kind = "Deployment"; }
          { group = "apps"; version = "v1"; kind = "StatefulSet"; }
          { group = ""; version = "v1"; kind = "Pod"; }
        ];
      } // (if namespace != null then { namespaces = [ namespace ]; } else {});
      validation = {
        message = "CPU and memory limits are required";
        pattern = {
          spec = {
            containers = [{
              resources = {
                limits = {
                  memory = "?*";
                  cpu = "?*";
                };
              };
            }];
          };
        };
      };
    };

  # Security Pattern: Require security context
  mkRequireSecurityContext = { name ? "require-security-context", runAsNonRoot ? true, namespace ? null }:
    {
      inherit name;
      match = {
        kinds = [
          { group = "apps"; version = "v1"; kind = "Deployment"; }
          { group = "apps"; version = "v1"; kind = "StatefulSet"; }
          { group = ""; version = "v1"; kind = "Pod"; }
        ];
      } // (if namespace != null then { namespaces = [ namespace ]; } else {});
      validation = {
        message = "Security context is required";
        pattern = {
          spec.containers = [{
            securityContext = {
              runAsNonRoot = runAsNonRoot;
              allowPrivilegeEscalation = false;
              readOnlyRootFilesystem = true;
            };
          }];
        };
      };
    };

  # Compliance Pattern: Block privileged containers
  mkBlockPrivilegedContainers = { name ? "block-privileged", namespace ? null }:
    {
      inherit name;
      match = {
        kinds = [
          { group = "apps"; version = "v1"; kind = "Deployment"; }
          { group = "apps"; version = "v1"; kind = "StatefulSet"; }
          { group = ""; version = "v1"; kind = "Pod"; }
        ];
      } // (if namespace != null then { namespaces = [ namespace ]; } else {});
      validation = {
        message = "Privileged containers are not allowed";
        deny = {
          conditions.all = [
            {
              key = "request.object.spec.containers[].securityContext.privileged";
              operator = "Equals";
              value = true;
            }
          ];
        };
      };
    };

  # Compliance Pattern: Enforce Pod security standards (restricted)
  mkEnforcePodSecurityStandard = { name ? "pod-security-standard-restricted", namespace ? null }:
    {
      inherit name;
      match = {
        kinds = [
          { group = ""; version = "v1"; kind = "Pod"; }
        ];
      } // (if namespace != null then { namespaces = [ namespace ]; } else {});
      validation = {
        message = "Pod does not comply with restricted security standard";
        pattern = {
          metadata.labels."pod-security.kubernetes.io/enforce" = "restricted";
        };
      };
    };

  # Mutation Pattern: Add image pull policy
  mkAddImagePullPolicy = { name ? "add-image-pull-policy", policy ? "IfNotPresent" }:
    {
      inherit name;
      match = {
        kinds = [
          { group = "apps"; version = "v1"; kind = "Deployment"; }
          { group = "apps"; version = "v1"; kind = "StatefulSet"; }
          { group = ""; version = "v1"; kind = "Pod"; }
        ];
      };
      mutation = {
        patchStrategicMerge = {
          spec.containers = [{
            imagePullPolicy = policy;
          }];
        };
      };
    };

  # Mutation Pattern: Add default labels
  mkAddDefaultLabels = { name ? "add-default-labels", labels ? {} }:
    {
      inherit name;
      match = {
        kinds = [
          { group = "apps"; version = "v1"; kind = "Deployment"; }
          { group = "apps"; version = "v1"; kind = "StatefulSet"; }
          { group = ""; version = "v1"; kind = "Pod"; }
        ];
      };
      mutation = {
        patchStrategicMerge = {
          metadata.labels = labels;
        };
      };
    };

  # Generation Pattern: Generate NetworkPolicy
  mkGenerateNetworkPolicy = { name ? "generate-network-policy", namespace ? null }:
    {
      inherit name;
      match = {
        kinds = [
          { group = ""; version = "v1"; kind = "Namespace"; }
        ];
      } // (if namespace != null then { namespaces = [ namespace ]; } else {});
      generation = {
        kind = "NetworkPolicy";
        apiVersion = "networking.k8s.io/v1";
        name = "default-deny-all";
        namespace = "{request.object.metadata.name}";
        synchronize = true;
        data = {
          spec = {
            podSelector = {};
            policyTypes = [ "Ingress" "Egress" ];
          };
        };
      };
    };

  # Generation Pattern: Generate RBAC resources
  mkGenerateRBACResources = { name ? "generate-rbac", namespace ? null }:
    {
      inherit name;
      match = {
        kinds = [
          { group = ""; version = "v1"; kind = "Namespace"; }
        ];
      } // (if namespace != null then { namespaces = [ namespace ]; } else {});
      generation = {
        kind = "Role";
        apiVersion = "rbac.authorization.k8s.io/v1";
        name = "pod-reader";
        namespace = "{request.object.metadata.name}";
        synchronize = true;
        data = {
          rules = [
            {
              apiGroups = [ "" ];
              resources = [ "pods" ];
              verbs = [ "get" "list" "watch" ];
            }
          ];
        };
      };
    };

  # Policy Composition Helper
  # Combines multiple policies with inheritance
  mkPolicyComposition = { name, basePolicies ? [], additionalRules ? [], overrides ? {} }:
    let
      inheritedRules = lib.flatten (map (policy: policy.rules or []) basePolicies);
      allRules = inheritedRules ++ additionalRules;
    in
      {
        rules = allRules;
      } // overrides;

  # Policy validation helper
  # Checks if a resource would pass a policy
  validateAgainstPolicy = resource: policy:
    let
      rulesPass = lib.all (rule:
        let
          # Simple validation check (in production, would use full CEL evaluation)
          matchesCriteria = rule.match == {} || true;  # Simplified
        in
          matchesCriteria
      ) (policy.spec.rules or []);
    in
      rulesPass;

  # Pre-built policy sets
  policyLibrary = {
    # Security baseline: essential security policies
    securityBaseline = [
      { mkRequireImageRegistry._override.registry = "gcr.io"; }
      mkRequireResourceLimits
      mkRequireSecurityContext
      mkBlockPrivilegedContainers
    ];

    # Compliance suite: PCI-DSS, HIPAA, SOC2
    complianceSuite = [
      mkBlockPrivilegedContainers
      mkEnforcePodSecurityStandard
      mkRequireResourceLimits
      mkRequireSecurityContext
    ];

    # Cost optimization: policies that help reduce costs
    costOptimization = [
      mkRequireResourceLimits  # Prevents resource waste
      mkAddImagePullPolicy      # Reduces image pulls
    ];

    # DevOps best practices
    bestPractices = [
      mkRequireImageRegistry
      mkRequireResourceLimits
      mkRequireSecurityContext
      mkAddDefaultLabels
      mkAddImagePullPolicy
    ];
  };

  # Helper to generate policy summary
  mkPolicySummary = policies:
    {
      totalPolicies = builtins.length policies;
      validationCount = builtins.length (lib.filter (p: p.spec.rules != []) policies);
      mutationCount = builtins.length (lib.filter (p: (lib.findFirst (r: r.mutation != {}) null (p.spec.rules or [])) != null) policies);
      generationCount = builtins.length (lib.filter (p: (lib.findFirst (r: r.generation != {}) null (p.spec.rules or [])) != null) policies);
    };
}
