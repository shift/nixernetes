# Integration Tests for Nixernetes Modules
#
# This test suite validates:
# - Compliance label injection and enforcement
# - Module interactions
# - YAML output generation
# - Policy correctness

{ lib, pkgs, ... }:

let
  inherit (lib) mkOption types;

  # Import our modules
  schema = import ../src/lib/schema.nix { inherit lib; };
  compliance = import ../src/lib/compliance.nix { inherit lib; };
  complianceEnforcement = import ../src/lib/compliance-enforcement.nix { inherit lib; };
  complianceProfiles = import ../src/lib/compliance-profiles.nix { inherit lib; };
  policies = import ../src/lib/policies.nix { inherit lib; };
  policyGeneration = import ../src/lib/policy-generation.nix { inherit lib; };
  rbac = import ../src/lib/rbac.nix { inherit lib; };
  output = import ../src/lib/output.nix { inherit lib pkgs; };
  types_module = import ../src/lib/types.nix { inherit lib; };
  generators = import ../src/lib/generators.nix { inherit lib pkgs; };

  # Helper to check if a resource has expected labels
  hasLabels = resource: expectedLabels:
    let
      actualLabels = resource.metadata.labels or {};
    in
      lib.all (label: actualLabels ? ${label}) expectedLabels;

  # Helper to check if a resource has expected annotations
  hasAnnotations = resource: expectedAnnotations:
    let
      actualAnnotations = resource.metadata.annotations or {};
    in
      lib.all (annotation: actualAnnotations ? ${annotation}) expectedAnnotations;

in
{
  # Test 1: Compliance labels are properly injected
  testComplianceLabelInjection = {
    name = "compliance label injection";
    test = 
      let
        resource = {
          apiVersion = "v1";
          kind = "Pod";
          metadata = { name = "test-pod"; };
          spec = {};
        };
        labels = {
          "nixernetes.io/framework" = "SOC2";
          "nixernetes.io/compliance-level" = "standard";
          "nixernetes.io/owner" = "platform-team";
        };
        result = compliance.withComplianceLabels { inherit resource labels; };
      in
        hasLabels result [ "nixernetes.io/framework" "nixernetes.io/compliance-level" "nixernetes.io/owner" ];
    expected = true;
  };

  # Test 2: Traceability annotations are injected
  testTraceabilityInjection = {
    name = "traceability annotation injection";
    test =
      let
        resource = {
          apiVersion = "v1";
          kind = "Pod";
          metadata = { name = "test-pod"; };
          spec = {};
        };
        result = compliance.withTraceability { 
          inherit resource;
          buildId = "abc123"; 
          generatedBy = "nixernetes";
        };
      in
        hasAnnotations result [ "nixernetes.io/nix-build-id" "nixernetes.io/generated-by" ];
    expected = true;
  };

  # Test 3: Compliance enforcement generates correct labels
  testComplianceEnforcementLabels = {
    name = "compliance enforcement label generation";
    test =
      let
        result = complianceEnforcement.mkComplianceEnforcedLabels {
          framework = "PCI-DSS";
          level = "strict";
          owner = "security-team";
        };
      in
        (result."nixernetes.io/framework" == "PCI-DSS") &&
        (result."nixernetes.io/compliance-level" == "strict") &&
        (result."nixernetes.io/owner" == "security-team");
    expected = true;
  };

  # Test 4: Default deny network policy is generated correctly
  testDefaultDenyNetworkPolicy = {
    name = "default deny network policy generation";
    test =
      let
        policy = policies.mkDefaultDenyNetworkPolicy {
          name = "test-deny";
          namespace = "default";
          apiVersion = "networking.k8s.io/v1";
        };
      in
        (policy.kind == "NetworkPolicy") &&
        (policy.metadata.name == "test-deny") &&
        (policy.metadata.namespace == "default");
    expected = true;
  };

  # Test 5: Kyverno policy is generated with required structure
  testKyvernoPolicyStructure = {
    name = "kyverno policy structure";
    test =
      let
        policy = policies.mkComplianceClusterPolicy {
          framework = "SOC2";
          level = "standard";
        };
      in
        (policy.kind == "ClusterPolicy") &&
        (policy.spec ? rules) &&
        (builtins.length policy.spec.rules > 0);
    expected = true;
  };

  # Test 6: RBAC resources are generated correctly
  testRBACGeneration = {
    name = "RBAC resource generation";
    test =
      let
        role = rbac.mkRole {
          name = "test-role";
          namespace = "default";
          rules = [
            {
              apiGroups = [ "" ];
              resources = [ "pods" ];
              verbs = [ "get" "list" "watch" ];
            }
          ];
        };
      in
        (role.kind == "Role") &&
        (role.metadata.name == "test-role") &&
        (builtins.length role.spec.rules > 0);
    expected = true;
  };

  # Test 7: Resource ordering for kubectl apply
  testResourceOrdering = {
    name = "resource ordering for kubectl apply";
    test =
      let
        resources = [
          { kind = "Service"; metadata = { name = "svc"; }; }
          { kind = "Namespace"; metadata = { name = "ns"; }; }
          { kind = "Deployment"; metadata = { name = "deploy"; }; }
          { kind = "NetworkPolicy"; metadata = { name = "np"; }; }
        ];
        ordered = output.orderResourcesForApply resources;
        kinds = map (r: r.kind) ordered;
      in
        # Should be: Namespace, Deployment, Service, NetworkPolicy
        kinds == [ "Namespace" "Deployment" "Service" "NetworkPolicy" ];
    expected = true;
  };

  # Test 8: Compliance profile selection works
  testComplianceProfileSelection = {
    name = "compliance profile selection";
    test =
      let
        result = complianceProfiles.getProfile "prod";
      in
        (result ? labels) &&
        (result ? networkPolicy) &&
        (result ? securityPolicy);
    expected = true;
  };

  # Test 9: Schema version resolution
  testSchemaVersionResolution = {
    name = "schema version resolution";
    test =
      let
        apiVersion = schema.resolveApiVersion {
          kind = "Deployment";
          kubernetesVersion = "1.30";
        };
      in
        apiVersion == "apps/v1";
    expected = true;
  };

  # Test 10: Deployment generator creates valid structure
  testDeploymentGeneration = {
    name = "deployment resource generation";
    test =
      let
        deployment = generators.mkDeployment {
          name = "test-app";
          namespace = "default";
          image = "nginx:latest";
          replicas = 3;
          labels = { app = "test"; };
        };
      in
        (deployment.kind == "Deployment") &&
        (deployment.metadata.name == "test-app") &&
        (deployment.spec.replicas == 3) &&
        (builtins.length deployment.spec.template.spec.containers > 0);
    expected = true;
  };

  # Test 11: Service generator creates valid structure
  testServiceGeneration = {
    name = "service resource generation";
    test =
      let
        service = generators.mkService {
          name = "test-svc";
          namespace = "default";
          selector = { app = "test"; };
          ports = [ { port = 80; targetPort = 8080; } ];
        };
      in
        (service.kind == "Service") &&
        (service.metadata.name == "test-svc") &&
        (builtins.length service.spec.ports > 0);
    expected = true;
  };

  # Test 12: Multi-environment compliance generation
  testMultiEnvironmentCompliance = {
    name = "multi-environment compliance generation";
    test =
      let
        result = complianceProfiles.mkMultiEnvironmentDeployment {
          appName = "test-app";
          resources = [
            {
              kind = "Deployment";
              metadata = { name = "test-app"; };
              spec = { replicas = 1; };
            }
          ];
          environments = {
            dev = {
              enabled = true;
              complianceLevel = "permissive";
            };
            prod = {
              enabled = true;
              complianceLevel = "strict";
            };
          };
        };
      in
        (result ? dev) &&
        (result ? prod) &&
        (builtins.length result.dev > 0) &&
        (builtins.length result.prod > 0);
    expected = true;
  };
}
