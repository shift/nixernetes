# Example: Policy Testing Framework
#
# This example demonstrates comprehensive testing of Kyverno policies
# using the Nixernetes Policy Testing Framework.
#
# Covers:
# - Validation policy testing
# - Mutation policy testing
# - Generation policy testing
# - Policy compliance verification
# - Coverage analysis
# - Test fixtures and matrices

{ lib, ... }:

let
  policyTesting = import ../src/lib/policy-testing.nix { inherit lib; };
  kyverno = import ../src/lib/kyverno.nix { inherit lib; };

in
{
  # ============================================================================
  # Example 1: Image Registry Validation Policy
  # ============================================================================
  
  imageRegistryPolicy = kyverno.mkValidationPolicy {
    name = "require-image-registry";
    metadata = {
      annotations = {
        description = "Enforce images from approved registry";
      };
    };
    rules = [{
      name = "validate-registry";
      match = {
        resources = {
          kinds = ["Pod"];
          namespaces = ["production" "staging"];
        };
      };
      validate = {
        message = "Image must be from myregistry.azurecr.io";
        pattern = {
          spec = {
            containers = [{
              image = "myregistry.azurecr.io/*";
            }];
          };
        };
      };
    }];
  };

  imageRegistryTests = {
    testValidImage = policyTesting.assertPolicyPasses {
      policy = imageRegistryPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        metadata = {
          name = "app-pod";
          namespace = "production";
        };
        spec = {
          containers = [{
            name = "app";
            image = "myregistry.azurecr.io/myapp:1.0.0";
          }];
        };
      };
      description = "approved-registry";
    };

    testInvalidRegistryDocker = policyTesting.assertPolicyRejects {
      policy = imageRegistryPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        metadata = {
          name = "untrusted-pod";
          namespace = "production";
        };
        spec = {
          containers = [{
            name = "app";
            image = "docker.io/library/nginx:latest";
          }];
        };
      };
      reason = "unapproved-registry";
      description = "docker-registry";
    };

    testInvalidRegistryQuay = policyTesting.assertPolicyRejects {
      policy = imageRegistryPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        metadata = {
          name = "untrusted-pod2";
          namespace = "production";
        };
        spec = {
          containers = [{
            name = "app";
            image = "quay.io/operator:v1.2";
          }];
        };
      };
      reason = "unapproved-registry";
      description = "quay-registry";
    };

    testWildcardMatch = policyTesting.assertPolicyPasses {
      policy = imageRegistryPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        metadata = {
          name = "multi-container";
          namespace = "production";
        };
        spec = {
          containers = [
            { name = "app"; image = "myregistry.azurecr.io/app:1.0"; }
            { name = "sidecar"; image = "myregistry.azurecr.io/sidecar:1.0"; }
          ];
        };
      };
      description = "multiple-containers";
    };

    testDevNamespace = policyTesting.assertPolicyPasses {
      policy = imageRegistryPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        metadata = {
          name = "dev-pod";
          namespace = "development";
        };
        spec = {
          containers = [{
            name = "app";
            image = "docker.io/dev/app:latest";  # Allowed in dev
          }];
        };
      };
      description = "development-namespace-excluded";
    };
  };

  # ============================================================================
  # Example 2: Pod Security Policy
  # ============================================================================

  podSecurityPolicy = kyverno.mkValidationPolicy {
    name = "require-pod-security";
    metadata = {
      annotations = {
        description = "Enforce pod security best practices";
      };
    };
    rules = [{
      name = "validate-security-context";
      match = {
        resources = {
          kinds = ["Pod"];
        };
      };
      validate = {
        message = "Pod must have security context with runAsNonRoot and readOnlyRootFilesystem";
        pattern = {
          spec = {
            securityContext = {
              runAsNonRoot = true;
              readOnlyRootFilesystem = true;
              allowPrivilegeEscalation = false;
            };
          };
        };
      };
    }];
  };

  podSecurityTests = {
    testRestrictedPod = policyTesting.assertPolicyPasses {
      policy = podSecurityPolicy;
      resource = policyTesting.fixtures.restrictedPod;
      description = "secure-pod";
    };

    testPermissivePod = policyTesting.assertPolicyRejects {
      policy = podSecurityPolicy;
      resource = policyTesting.fixtures.permissivePod;
      reason = "missing-security-context";
      description = "insecure-pod";
    };

    testMissingRunAsNonRoot = policyTesting.assertPolicyRejects {
      policy = podSecurityPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        metadata = { name = "test-pod"; };
        spec = {
          securityContext = {
            readOnlyRootFilesystem = true;
            allowPrivilegeEscalation = false;
            # Missing runAsNonRoot
          };
          containers = [{
            name = "app";
            image = "myapp:1.0";
          }];
        };
      };
      description = "missing-run-as-non-root";
    };

    testMissingReadOnly = policyTesting.assertPolicyRejects {
      policy = podSecurityPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        metadata = { name = "test-pod"; };
        spec = {
          securityContext = {
            runAsNonRoot = true;
            allowPrivilegeEscalation = false;
            # Missing readOnlyRootFilesystem
          };
          containers = [{
            name = "app";
            image = "myapp:1.0";
          }];
        };
      };
      description = "missing-readonly-filesystem";
    };
  };

  # ============================================================================
  # Example 3: Mutation Policy - Add Labels
  # ============================================================================

  addLabelsPolicy = kyverno.mkMutationPolicy {
    name = "add-required-labels";
    metadata = {
      annotations = {
        description = "Automatically add required labels to pods";
      };
    };
    rules = [{
      name = "add-labels";
      match = {
        resources = {
          kinds = ["Pod"];
        };
      };
      mutate = {
        patchStrategicMerge = {
          metadata = {
            labels = {
              "app.nixernetes.io/managed" = "true";
              "app.nixernetes.io/version" = "1.0";
            };
          };
        };
      };
    }];
  };

  addLabelsTests = {
    testLabelsAdded = policyTesting.assertPolicyMutates {
      policy = addLabelsPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        metadata = {
          name = "test-pod";
          labels = { app = "test"; };
        };
        spec = {
          containers = [{
            name = "app";
            image = "test:1.0";
          }];
        };
      };
      expectedFields = ["metadata.labels"];
      description = "labels-mutation";
    };

    testLabelsPreserved = policyTesting.assertPolicyMutates {
      policy = addLabelsPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        metadata = {
          name = "test-pod";
          labels = {
            app = "myapp";
            team = "platform";
          };
        };
        spec = {
          containers = [{
            name = "app";
            image = "test:1.0";
          }];
        };
      };
      expectedFields = ["metadata.labels"];
      description = "existing-labels-preserved";
    };
  };

  # ============================================================================
  # Example 4: Policy Compliance Testing
  # ============================================================================

  complianceTests = {
    imageRegistryCompliance = policyTesting.mkPolicyComplianceTest imageRegistryPolicy;
    podSecurityCompliance = policyTesting.mkPolicyComplianceTest podSecurityPolicy;
    addLabelsCompliance = policyTesting.mkPolicyComplianceTest addLabelsPolicy;

    allPoliciesCompliant = 
      imageRegistryCompliance.compliant &&
      podSecurityCompliance.compliant &&
      addLabelsCompliance.compliant;
  };

  # ============================================================================
  # Example 5: Coverage Analysis
  # ============================================================================

  policies = [
    imageRegistryPolicy
    podSecurityPolicy
    addLabelsPolicy
  ];

  coverageAnalysis = policyTesting.analyzePolicyCoverage policies;

  coverageReport = {
    totalPolicies = coverageAnalysis.totalPolicies;        # 3
    totalRules = coverageAnalysis.totalRules;              # 3
    validationPolicies = coverageAnalysis.validationPolicies;  # 2
    mutationPolicies = coverageAnalysis.mutationPolicies;      # 1
    generationPolicies = coverageAnalysis.generationPolicies;  # 0
    coveredKinds = coverageAnalysis.coveredResourceKinds;      # 1 (Pod)
  };

  # ============================================================================
  # Example 6: Test Fixtures
  # ============================================================================

  builtInFixtures = {
    restrictedPod = policyTesting.fixtures.restrictedPod;
    permissivePod = policyTesting.fixtures.permissivePod;
    standardDeployment = policyTesting.fixtures.standardDeployment;
  };

  customFixtures = {
    productionPod = policyTesting.mkPolicyFixture "production-pod" {
      resources = [
        {
          apiVersion = "v1";
          kind = "Pod";
          metadata = {
            name = "prod-pod";
            namespace = "production";
            labels = { env = "production"; };
          };
          spec = {
            containers = [{
              name = "app";
              image = "myregistry.azurecr.io/app:1.0";
            }];
          };
        }
      ];
    };

    stagingPod = policyTesting.mkPolicyFixture "staging-pod" {
      resources = [
        {
          apiVersion = "v1";
          kind = "Pod";
          metadata = {
            name = "staging-pod";
            namespace = "staging";
            labels = { env = "staging"; };
          };
          spec = {
            containers = [{
              name = "app";
              image = "myregistry.azurecr.io/app:1.0-rc";
            }];
          };
        }
      ];
    };
  };

  # ============================================================================
  # Example 7: Test Utilities
  # ============================================================================

  generatedTestResources = policyTesting.utils.generateTestResources
    imageRegistryPolicy
    5;  # Generate 5 test pods

  securityTags = policyTesting.utils.filterByTag
    (builtins.attrValues podSecurityTests)
    "security";

  testMatrix = policyTesting.utils.generateTestMatrix
    [
      policyTesting.assertPolicyPasses {
        policy = imageRegistryPolicy;
        resource = policyTesting.fixtures.restrictedPod;
        description = "test1";
      }
    ]
    [
      { name = "fixture1"; resource = { }; }
      { name = "fixture2"; resource = { }; }
    ];

  # ============================================================================
  # Example 8: Test Suite Organization
  # ============================================================================

  securityTestSuite = policyTesting.mkPolicyTestSuite "security-policies" {
    tests = builtins.attrValues podSecurityTests;
    policies = [podSecurityPolicy];
    setup = null;
    teardown = null;
  };

  registryTestSuite = policyTesting.mkPolicyTestSuite "registry-policies" {
    tests = builtins.attrValues imageRegistryTests;
    policies = [imageRegistryPolicy];
  };

  mutationTestSuite = policyTesting.mkPolicyTestSuite "mutation-policies" {
    tests = builtins.attrValues addLabelsTests;
    policies = [addLabelsPolicy];
  };

  # ============================================================================
  # Example 9: Test Reports
  # ============================================================================

  securityReport = policyTesting.mkTestReport securityTestSuite;
  registryReport = policyTesting.mkTestReport registryTestSuite;
  mutationReport = policyTesting.mkTestReport mutationTestSuite;

  # ============================================================================
  # Example 10: Resource Quota Policy Testing
  # ============================================================================

  resourceQuotaPolicy = kyverno.mkValidationPolicy {
    name = "validate-resource-limits";
    rules = [{
      name = "check-limits";
      match = {
        resources = { kinds = ["Pod"]; };
      };
      validate = {
        message = "CPU and memory limits are required";
        pattern = {
          spec = {
            containers = [{
              resources = {
                limits = {
                  cpu = "?*";
                  memory = "?*";
                };
              };
            }];
          };
        };
      };
    }];
  };

  resourceQuotaTests = {
    testWithLimits = policyTesting.assertPolicyPasses {
      policy = resourceQuotaPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        spec = {
          containers = [{
            name = "app";
            image = "app:1.0";
            resources = {
              limits = {
                cpu = "1000m";
                memory = "1Gi";
              };
            };
          }];
        };
      };
      description = "with-limits";
    };

    testWithoutLimits = policyTesting.assertPolicyRejects {
      policy = resourceQuotaPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Pod";
        spec = {
          containers = [{
            name = "app";
            image = "app:1.0";
            # Missing resource limits
          }];
        };
      };
      description = "without-limits";
    };
  };

  # ============================================================================
  # Example 11: Network Policy Testing
  # ============================================================================

  denyAllIngressPolicy = kyverno.mkValidationPolicy {
    name = "require-network-policy";
    rules = [{
      name = "check-network-policy";
      match = {
        resources = { kinds = ["Namespace"]; };
      };
      validate = {
        message = "Namespace must have a deny-all network policy";
        pattern = {
          metadata = {
            labels = {
              "network.nixernetes.io/default-deny" = "true";
            };
          };
        };
      };
    }];
  };

  networkPolicyTests = {
    testNamespaceWithPolicy = policyTesting.assertPolicyPasses {
      policy = denyAllIngressPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Namespace";
        metadata = {
          name = "production";
          labels = { "network.nixernetes.io/default-deny" = "true"; };
        };
      };
      description = "namespace-with-network-policy";
    };

    testNamespaceWithoutPolicy = policyTesting.assertPolicyRejects {
      policy = denyAllIngressPolicy;
      resource = {
        apiVersion = "v1";
        kind = "Namespace";
        metadata = {
          name = "development";
        };
      };
      description = "namespace-without-network-policy";
    };
  };

  # ============================================================================
  # Example 12: Complete Test Summary
  # ============================================================================

  allTestSuites = {
    inherit securityTestSuite registryTestSuite mutationTestSuite;
  };

  summaryStatistics = {
    totalSuites = 3;
    totalPolicies = 4;
    totalTests = 
      (builtins.length (builtins.attrValues imageRegistryTests)) +
      (builtins.length (builtins.attrValues podSecurityTests)) +
      (builtins.length (builtins.attrValues addLabelsTests)) +
      (builtins.length (builtins.attrValues resourceQuotaTests)) +
      (builtins.length (builtins.attrValues networkPolicyTests));
    allCompliant = complianceTests.allPoliciesCompliant;
  };

  # ============================================================================
  # Example 13: Framework Information
  # ============================================================================

  frameworkInfo = {
    name = policyTesting.framework.name;
    version = policyTesting.framework.version;
    features = policyTesting.framework.features;
    supportedPolicyTypes = policyTesting.framework.supportedPolicyTypes;
  };

  # ============================================================================
  # Summary and Export
  # ============================================================================

  complete_test_suite = {
    policies = {
      inherit imageRegistryPolicy podSecurityPolicy addLabelsPolicy
              resourceQuotaPolicy denyAllIngressPolicy;
    };

    tests = {
      inherit imageRegistryTests podSecurityTests addLabelsTests
              resourceQuotaTests networkPolicyTests;
    };

    suites = {
      inherit securityTestSuite registryTestSuite mutationTestSuite;
    };

    reports = {
      inherit securityReport registryReport mutationReport;
    };

    compliance = complianceTests;
    coverage = coverageAnalysis;
    fixtures = builtInFixtures;
    statistics = summaryStatistics;
    framework = frameworkInfo;
  };
}
