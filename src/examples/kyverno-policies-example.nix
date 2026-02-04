# Example: Kyverno Dynamic Policies
#
# This example demonstrates how to use the Kyverno policy framework to enforce
# security, compliance, and best practices across a Kubernetes cluster.
#
# Includes:
# - Security baseline policies
# - Compliance enforcement (PCI-DSS)
# - Cost optimization policies
# - Custom organizational policies

{ lib }:

let
  kyverno = import ../lib/kyverno.nix { inherit lib; };

in
{
  # Security Baseline Policies
  # Applied cluster-wide to enforce minimum security standards
  securityBaseline = {
    # Prevent use of untrusted container registries
    requireImageRegistry = kyverno.mkClusterPolicy {
      name = "require-image-registry";
      description = "Ensure all container images come from trusted registry (gcr.io)";
      validationFailureAction = "audit";  # Start in audit mode
      rules = [
        (kyverno.mkRequireImageRegistry {
          registry = "gcr.io";
        })
      ];
    };

    # Prevent resource starvation
    requireResourceLimits = kyverno.mkClusterPolicy {
      name = "require-resource-limits";
      description = "Enforce CPU and memory limits to prevent resource starvation";
      validationFailureAction = "enforce";  # Strictly enforce
      rules = [
        (kyverno.mkRequireResourceLimits {})
      ];
    };

    # Enforce security context
    requireSecurityContext = kyverno.mkClusterPolicy {
      name = "require-security-context";
      description = "Enforce security context (non-root, read-only filesystem)";
      validationFailureAction = "audit";
      rules = [
        (kyverno.mkRequireSecurityContext {
          runAsNonRoot = true;
        })
      ];
    };

    # Block privileged containers
    blockPrivileged = kyverno.mkClusterPolicy {
      name = "block-privileged-containers";
      description = "Prevent privileged container execution";
      validationFailureAction = "enforce";
      rules = [
        (kyverno.mkBlockPrivilegedContainers {})
      ];
    };
  };

  # Compliance Policies
  # Enforce regulatory compliance (PCI-DSS, HIPAA, SOC2)
  compliancePolicies = {
    pciDss = kyverno.mkClusterPolicy {
      name = "pci-dss-compliance";
      description = "Enforce PCI-DSS security requirements";
      validationFailureAction = "enforce";
      rules = kyverno.policyLibrary.complianceSuite;
    };

    podSecurityStandard = kyverno.mkClusterPolicy {
      name = "pod-security-standard";
      description = "Enforce Kubernetes Pod Security Standards (restricted)";
      validationFailureAction = "audit";
      rules = [
        (kyverno.mkEnforcePodSecurityStandard {})
      ];
    };
  };

  # Cost Optimization Policies
  # Help reduce infrastructure costs
  costOptimization = {
    rightSizing = kyverno.mkClusterPolicy {
      name = "cost-optimization-rightsizing";
      description = "Enforce proper resource requests to prevent cost overruns";
      validationFailureAction = "audit";
      rules = [
        (kyverno.mkRequireResourceLimits {})
      ];
    };

    imagePullPolicy = kyverno.mkClusterPolicy {
      name = "cost-optimization-image-pull";
      description = "Set IfNotPresent pull policy to reduce image pulls";
      validationFailureAction = "audit";  # Mutation - audit only
      rules = [
        (kyverno.mkAddImagePullPolicy {
          policy = "IfNotPresent";
        })
      ];
    };
  };

  # Mutation Policies
  # Automatically modify resources to meet standards
  mutationPolicies = {
    # Automatically add required labels
    addLabels = kyverno.mkClusterPolicy {
      name = "add-required-labels";
      description = "Automatically add platform labels to resources";
      validationFailureAction = "audit";
      rules = [
        (kyverno.mkAddDefaultLabels {
          labels = {
            "app.kubernetes.io/managed-by" = "nixernetes";
            "app.kubernetes.io/part-of" = "platform";
            "security.policy" = "enforced";
          };
        })
      ];
    };

    # Set default image pull policy
    setImagePullPolicy = kyverno.mkClusterPolicy {
      name = "set-image-pull-policy";
      description = "Set default image pull policy";
      rules = [
        (kyverno.mkAddImagePullPolicy {
          policy = "IfNotPresent";
        })
      ];
    };
  };

  # Generation Policies
  # Automatically create related resources
  generationPolicies = {
    # Generate default-deny NetworkPolicy for each namespace
    generateNetworkPolicy = kyverno.mkClusterPolicy {
      name = "generate-network-policy";
      description = "Automatically generate default-deny NetworkPolicy in each namespace";
      validationFailureAction = "audit";
      rules = [
        (kyverno.mkGenerateNetworkPolicy {})
      ];
    };

    # Generate RBAC resources
    generateRbac = kyverno.mkClusterPolicy {
      name = "generate-rbac-resources";
      description = "Automatically generate basic RBAC roles";
      validationFailureAction = "audit";
      rules = [
        (kyverno.mkGenerateRBACResources {})
      ];
    };
  };

  # Namespace-Specific Policies
  # Strict enforcement in production, relaxed in development
  namespaceSpecific = {
    # Production namespace: strict enforcement
    productionPolicy = kyverno.mkPolicy {
      name = "production-strict-policy";
      namespace = "production";
      description = "Strict security and compliance enforcement for production";
      validationFailureAction = "enforce";
      rules = [
        (kyverno.mkBlockPrivilegedContainers {
          namespace = "production";
        })
        (kyverno.mkRequireResourceLimits {
          namespace = "production";
        })
        (kyverno.mkRequireSecurityContext {
          namespace = "production";
        })
        (kyverno.mkRequireImageRegistry {
          namespace = "production";
          registry = "gcr.io";
        })
      ];
    };

    # Development namespace: warnings only
    developmentPolicy = kyverno.mkPolicy {
      name = "development-policy";
      namespace = "development";
      description = "Development policies - audit only, no enforcement";
      validationFailureAction = "audit";
      rules = kyverno.policyLibrary.bestPractices;
    };
  };

  # Policy Summary
  summary = {
    securityPolicies = kyverno.mkPolicySummary [
      securityBaseline.requireImageRegistry
      securityBaseline.requireResourceLimits
      securityBaseline.requireSecurityContext
      securityBaseline.blockPrivileged
    ];

    compliancePolicies = kyverno.mkPolicySummary [
      compliancePolicies.pciDss
      compliancePolicies.podSecurityStandard
    ];

    costOptimizationPolicies = kyverno.mkPolicySummary [
      costOptimization.rightSizing
      costOptimization.imagePullPolicy
    ];

    mutationPolicies = kyverno.mkPolicySummary [
      mutationPolicies.addLabels
      mutationPolicies.setImagePullPolicy
    ];

    generationPolicies = kyverno.mkPolicySummary [
      generationPolicies.generateNetworkPolicy
      generationPolicies.generateRbac
    ];

    total = {
      clusterPolicies = 12;
      namespacePolicies = 2;
      validationRules = 11;
      mutationRules = 2;
      generationRules = 2;
    };
  };

  # All policies combined for easy deployment
  allPolicies = {
    security = builtins.attrValues securityBaseline;
    compliance = builtins.attrValues compliancePolicies;
    costOptimization = builtins.attrValues costOptimization;
    mutations = builtins.attrValues mutationPolicies;
    generation = builtins.attrValues generationPolicies;
    namespaceSpecific = builtins.attrValues namespaceSpecific;
  };
}
