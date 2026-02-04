# Test suite for manifest validation
# 
# This tests the Kubernetes manifest validation framework
# Run with: nix eval tests/manifest-validation-test.nix --json

{ lib ? (import <nixpkgs> {}).lib }:

let
  # Import the kubernetes schema module
  k8sSchema = import ./src/lib/kubernetes-schema.nix { inherit lib; };

  # Define test cases
  tests = {
    # Test 1: Valid Pod manifest
    validPod = {
      name = "Valid Pod Manifest";
      manifest = {
        kind = "Pod";
        apiVersion = "v1";
        metadata = {
          name = "test-pod";
          namespace = "default";
        };
      };
      expectValid = true;
    };

    # Test 2: Pod missing required metadata.name
    invalidPodMissingName = {
      name = "Pod Missing Name";
      manifest = {
        kind = "Pod";
        apiVersion = "v1";
        metadata = {
          namespace = "default";
        };
      };
      expectValid = false;
    };

    # Test 3: Valid Deployment
    validDeployment = {
      name = "Valid Deployment";
      manifest = {
        kind = "Deployment";
        apiVersion = "apps/v1";
        metadata = {
          name = "my-deployment";
          namespace = "default";
        };
        spec = {
          replicas = 3;
          selector = {
            matchLabels = {
              app = "myapp";
            };
          };
          template = {
            metadata = {
              labels = {
                app = "myapp";
              };
            };
            spec = {
              containers = [
                {
                  name = "app";
                  image = "myapp:latest";
                }
              ];
            };
          };
        };
      };
      expectValid = true;
    };

    # Test 4: Valid Service
    validService = {
      name = "Valid Service";
      manifest = {
        kind = "Service";
        apiVersion = "v1";
        metadata = {
          name = "my-service";
          namespace = "default";
        };
        spec = {
          selector = {
            app = "myapp";
          };
          ports = [
            {
              protocol = "TCP";
              port = 80;
              targetPort = 8080;
            }
          ];
          type = "ClusterIP";
        };
      };
      expectValid = true;
    };

    # Test 5: Valid ConfigMap
    validConfigMap = {
      name = "Valid ConfigMap";
      manifest = {
        kind = "ConfigMap";
        apiVersion = "v1";
        metadata = {
          name = "my-config";
          namespace = "default";
        };
        data = {
          key1 = "value1";
          key2 = "value2";
        };
      };
      expectValid = true;
    };

    # Test 6: Invalid kind
    invalidKind = {
      name = "Invalid Kind";
      manifest = {
        kind = "UnknownResource";
        apiVersion = "v1";
        metadata = {
          name = "test";
        };
      };
      expectValid = false;
    };

    # Test 7: Missing apiVersion
    missingApiVersion = {
      name = "Missing API Version";
      manifest = {
        kind = "Pod";
        metadata = {
          name = "test";
        };
      };
      expectValid = false;
    };

    # Test 8: Valid ConfigMap with optional fields
    configMapWithBinaryData = {
      name = "ConfigMap with Binary Data";
      manifest = {
        kind = "ConfigMap";
        apiVersion = "v1";
        metadata = {
          name = "binary-config";
          namespace = "default";
          labels = {
            app = "test";
          };
          annotations = {
            description = "Test configuration";
          };
        };
        data = {
          config = "key=value";
        };
        binaryData = {
          image = "aGVsbG8gd29ybGQ="; # base64 encoded
        };
      };
      expectValid = true;
    };

    # Test 9: Valid Secret
    validSecret = {
      name = "Valid Secret";
      manifest = {
        kind = "Secret";
        apiVersion = "v1";
        metadata = {
          name = "my-secret";
          namespace = "default";
        };
        type = "Opaque";
        data = {
          username = "YWRtaW4="; # base64
          password = "c2VjcmV0"; # base64
        };
      };
      expectValid = true;
    };

    # Test 10: Multiple manifests validation
    multipleManifests = {
      name = "Multiple Manifests";
      manifests = [
        {
          kind = "Pod";
          apiVersion = "v1";
          metadata = { name = "pod1"; };
        }
        {
          kind = "Service";
          apiVersion = "v1";
          metadata = { name = "service1"; };
          spec = {
            selector = { app = "test"; };
            ports = [ { port = 80; } ];
          };
        }
      ];
      expectAllValid = true;
    };
  };

  # Run individual tests
  runTest = testName: testCase:
    let
      validation = k8sSchema.validateManifestStrict testCase.manifest;
      passed = validation.valid == testCase.expectValid;
    in
    {
      inherit testName passed;
      expected = testCase.expectValid;
      actual = validation.valid;
      errors = validation.errors;
      status = if passed then "PASS" else "FAIL";
    };

  # Run all single-manifest tests
  singleTests = lib.mapAttrs (name: testCase:
    if builtins.hasAttr "manifest" testCase then
      runTest testCase.name testCase
    else
      null
  ) tests;

  # Run multi-manifest test
  multiTest =
    let
      validation = k8sSchema.validateManifests tests.multipleManifests.manifests;
      passed = validation.valid == tests.multipleManifests.expectAllValid;
    in
    {
      testName = tests.multipleManifests.name;
      inherit passed;
      expected = tests.multipleManifests.expectAllValid;
      actual = validation.valid;
      inherit (validation) errors count;
      status = if passed then "PASS" else "FAIL";
    };

  # Summary
  results = lib.filterAttrs (n: v: v != null) singleTests;
  passed = lib.count (v: v.passed) (lib.attrValues results);
  failed = lib.count (v: !v.passed) (lib.attrValues results);
  total = lib.length (lib.attrValues results);

in
{
  # Test results
  summary = {
    inherit total passed failed;
    passRate = (passed * 100) / total;
  };

  # Individual results
  inherit results multiTest;

  # Supported kinds
  supportedKinds = k8sSchema.supportedKinds;

  # Check kind support
  isKindSupported = k8sSchema.isKindSupported;
}
