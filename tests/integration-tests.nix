# Integration Tests for Nixernetes Modules
#
# This test suite validates:
# - Compliance label injection and enforcement
# - Module interactions
# - YAML output generation
# - Policy correctness
# - Cost analysis calculations

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
    costAnalysis = import ../src/lib/cost-analysis.nix { inherit lib; };
    kyverno = import ../src/lib/kyverno.nix { inherit lib; };
    gitops = import ../src/lib/gitops.nix { inherit lib; };
    policyVisualization = import ../src/lib/policy-visualization.nix { inherit lib; };
    securityScanning = import ../src/lib/security-scanning.nix { inherit lib; };
    performanceAnalysis = import ../src/lib/performance-analysis.nix { inherit lib; };
    unifiedApi = import ../src/lib/unified-api.nix { inherit lib; };
      policyTesting = import ../src/lib/policy-testing.nix { inherit lib; };
        helmIntegration = import ../src/lib/helm-integration.nix { inherit lib; };
        advancedOrchestration = import ../src/lib/advanced-orchestration.nix { inherit lib; };
        disasterRecovery = import ../src/lib/disaster-recovery.nix { inherit lib; };
        multiTenancy = import ../src/lib/multi-tenancy.nix { inherit lib; };
        serviceMesh = import ../src/lib/service-mesh.nix { inherit lib; };
        apiGateway = import ../src/lib/api-gateway.nix { inherit lib; };
        containerRegistry = import ../src/lib/container-registry.nix { inherit lib; };
 
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

  # Test 13: Cost analysis module loads and calculates correctly
  testCostAnalysisModule = {
    name = "cost analysis module";
    test =
      let
        # Test container cost calculation
        containerCost = costAnalysis.mkContainerCost {
          resources = {
            requests = {
              cpu = "500m";
              memory = "512Mi";
            };
          };
          provider = "aws";
        };
        # 0.5 CPU × 0.0535 + 0.5 GB × 0.0108 = 0.03215/hour
        expectedHourly = 0.03215;
        isClose = builtins.abs (containerCost - expectedHourly) < 0.001;
      in
        isClose;
    expected = true;
  };

  # Test 14: Cost analysis for deployment
  testDeploymentCostCalculation = {
    name = "deployment cost calculation";
    test =
      let
        deployment = {
          spec = {
            replicas = 3;
            template.spec = {
              containers = [
                {
                  name = "app";
                  resources = {
                    requests = {
                      cpu = "100m";
                      memory = "128Mi";
                    };
                  };
                }
              ];
            };
          };
        };
        cost = costAnalysis.mkDeploymentCost {
          replicas = deployment.spec.replicas;
          template = deployment.spec.template;
          provider = "aws";
        };
      in
        # Should have cost fields
        (cost ? hourly) &&
        (cost ? daily) &&
        (cost ? monthly) &&
        (cost ? annual) &&
        (cost.hourly > 0) &&
        (cost.daily == cost.hourly * 24) &&
        (cost.monthly == cost.hourly * 24 * 30);
    expected = true;
  };

  # Test 15: Multi-provider cost comparison
  testMultiProviderComparison = {
    name = "multi-provider cost comparison";
    test =
      let
        deployments = {
          app = {
            spec = {
              replicas = 1;
              template.spec = {
                containers = [
                  {
                    name = "web";
                    resources = {
                      requests = {
                        cpu = "500m";
                        memory = "512Mi";
                      };
                    };
                  }
                ];
              };
            };
          };
        };
        awsSummary = costAnalysis.mkCostSummary {
          inherit deployments;
          provider = "aws";
        };
        azureSummary = costAnalysis.mkCostSummary {
          inherit deployments;
          provider = "azure";
        };
        gcpSummary = costAnalysis.mkCostSummary {
          inherit deployments;
          provider = "gcp";
        };
      in
        # Azure should be cheaper than AWS
        (azureSummary.total.monthly < awsSummary.total.monthly) &&
        # GCP should be cheapest
        (gcpSummary.total.monthly < azureSummary.total.monthly) &&
        # All should have cost summary fields
        (awsSummary ? total) &&
        (awsSummary ? byDeployment) &&
        (awsSummary.provider == "aws") &&
        (azureSummary.provider == "azure") &&
        (gcpSummary.provider == "gcp");
    expected = true;
  };

  # Test 16: Cost recommendations generation
  testCostRecommendations = {
    name = "cost recommendations generation";
    test =
      let
        deployments = {
          oversized-app = {
            spec.template.spec.containers = [
              {
                name = "app";
                resources = {
                  requests = {
                    cpu = "4";  # Very high CPU request
                    memory = "2Gi";
                  };
                  limits = {
                    cpu = "4";
                    memory = "2Gi";
                  };
                };
              }
              {
                name = "sidecar";
                resources = {
                  requests = {
                    cpu = "100m";
                    memory = "128Mi";
                  };
                  # No limits specified
                };
              }
            ];
          };
        };
        recommendations = costAnalysis.mkCostRecommendations {
          inherit deployments;
        };
       in
         # Should find recommendations
         (builtins.length recommendations > 0) &&
         # Should detect CPU oversizing
         (builtins.any (r: r.type == "cpu_oversizing") recommendations) &&
         # Should detect missing limits
         (builtins.any (r: r.type == "missing_limit") recommendations);
    expected = true;
  };

  # Test 17: Kyverno ClusterPolicy generation
  testKyvernoClusterPolicyGeneration = {
    name = "kyverno cluster policy generation";
    test =
      let
        policy = kyverno.mkClusterPolicy {
          name = "test-policy";
          description = "Test policy";
          rules = [
            (kyverno.mkBlockPrivilegedContainers {})
          ];
          validationFailureAction = "enforce";
        };
      in
        # Should create valid Kyverno resource
        (policy.apiVersion == "kyverno.io/v1") &&
        (policy.kind == "ClusterPolicy") &&
        (policy.metadata.name == "test-policy") &&
        (policy.spec.validationFailureAction == "enforce") &&
        (builtins.length policy.spec.rules > 0);
    expected = true;
  };

  # Test 18: Kyverno Policy generation (namespaced)
  testKyvernoPolicyGeneration = {
    name = "kyverno policy generation";
    test =
      let
        policy = kyverno.mkPolicy {
          name = "test-policy";
          namespace = "production";
          description = "Test namespaced policy";
          rules = [
            (kyverno.mkRequireResourceLimits {})
          ];
          validationFailureAction = "audit";
        };
      in
        # Should create valid Kyverno Policy resource
        (policy.apiVersion == "kyverno.io/v1") &&
        (policy.kind == "Policy") &&
        (policy.metadata.name == "test-policy") &&
        (policy.metadata.namespace == "production") &&
        (policy.spec.validationFailureAction == "audit");
    expected = true;
  };

  # Test 19: Kyverno security patterns
  testKyvernoSecurityPatterns = {
    name = "kyverno security patterns";
    test =
      let
        requireRegistry = kyverno.mkRequireImageRegistry {
          registry = "gcr.io";
        };
        requireLimits = kyverno.mkRequireResourceLimits {};
        requireSecContext = kyverno.mkRequireSecurityContext {};
        blockPriv = kyverno.mkBlockPrivilegedContainers {};
      in
        # All patterns should have name and validation/generation
        (requireRegistry ? name) &&
        (requireLimits ? name) &&
        (requireSecContext ? name) &&
        (blockPriv ? name) &&
        # Should be properly structured
        (builtins.length (lib.attrNames requireRegistry) > 0) &&
        (builtins.length (lib.attrNames requireLimits) > 0) &&
        (builtins.length (lib.attrNames requireSecContext) > 0) &&
        (builtins.length (lib.attrNames blockPriv) > 0);
    expected = true;
  };

  # Test 20: Kyverno mutation and generation patterns
  testKyvernoMutationGeneration = {
    name = "kyverno mutation and generation patterns";
    test =
      let
        addLabels = kyverno.mkAddDefaultLabels {
          labels = { "app" = "test"; };
        };
        addImagePullPolicy = kyverno.mkAddImagePullPolicy {};
        generateNetPolicy = kyverno.mkGenerateNetworkPolicy {};
      in
        # All patterns should be properly structured
        (addLabels ? name) &&
        (addImagePullPolicy ? name) &&
        (generateNetPolicy ? name) &&
        # Should have mutation/generation fields
        (addLabels ? mutation) &&
        (addImagePullPolicy ? mutation) &&
        (generateNetPolicy ? generation);
    expected = true;
  };

  # Test 21: Kyverno policy library
  testKyvernoPolicyLibrary = {
    name = "kyverno policy library";
    test =
      let
        lib_policies = kyverno.policyLibrary;
      in
        # Should have all expected policy sets
        (lib_policies ? securityBaseline) &&
        (lib_policies ? complianceSuite) &&
        (lib_policies ? costOptimization) &&
        (lib_policies ? bestPractices) &&
        # Each set should have policies
        (builtins.length lib_policies.securityBaseline > 0) &&
        (builtins.length lib_policies.complianceSuite > 0) &&
        (builtins.length lib_policies.costOptimization > 0) &&
        (builtins.length lib_policies.bestPractices > 0);
    expected = true;
  };

  # Test 22: Kyverno policy validation
  testKyvernoPolicyValidation = {
    name = "kyverno policy validation";
    test =
      let
        policy = kyverno.mkClusterPolicy {
          name = "test-policy";
          rules = [
            (kyverno.mkRequireResourceLimits {})
          ];
        };
        resource = {
          apiVersion = "v1";
          kind = "Pod";
          spec.containers = [{
            resources.limits = {
              cpu = "500m";
              memory = "512Mi";
            };
          }];
        };
      in
        # Validation should succeed for compliant resource
        (kyverno.validateAgainstPolicy resource policy) == true;
    expected = true;
  };

  # Test 23: Flux v2 GitRepository generation
  testFluxGitRepository = {
    name = "flux gitrepository generation";
    test =
      let
        gitRepo = gitops.mkGitRepository {
          name = "test-repo";
          url = "https://github.com/test/repo";
          ref = { branch = "main"; };
        };
      in
        # Should create valid Flux GitRepository
        (gitRepo.apiVersion == "source.toolkit.fluxcd.io/v1") &&
        (gitRepo.kind == "GitRepository") &&
        (gitRepo.metadata.name == "test-repo") &&
        (gitRepo.spec.url == "https://github.com/test/repo") &&
        (gitRepo.spec.ref.branch == "main");
    expected = true;
  };

  # Test 24: Flux v2 Kustomization generation
  testFluxKustomization = {
    name = "flux kustomization generation";
    test =
      let
        kustomization = gitops.mkKustomization {
          name = "test-kustomize";
          sourceRef = { kind = "GitRepository"; name = "test-repo"; };
          path = "./apps";
        };
      in
        # Should create valid Flux Kustomization
        (kustomization.apiVersion == "kustomize.toolkit.fluxcd.io/v1") &&
        (kustomization.kind == "Kustomization") &&
        (kustomization.metadata.name == "test-kustomize") &&
        (kustomization.spec.path == "./apps") &&
        (kustomization.spec.sourceRef.kind == "GitRepository") &&
        (kustomization.spec.prune == true);
    expected = true;
  };

  # Test 25: ArgoCD Application generation
  testArgoCDApplication = {
    name = "argocd application generation";
    test =
      let
        app = gitops.mkApplication {
          name = "test-app";
          project = "default";
          source = {
            repoURL = "https://github.com/test/repo";
            path = "./apps";
          };
          destination = {
            namespace = "production";
          };
        };
      in
        # Should create valid ArgoCD Application
        (app.apiVersion == "argoproj.io/v1alpha1") &&
        (app.kind == "Application") &&
        (app.metadata.name == "test-app") &&
        (app.spec.project == "default") &&
        (app.spec.source.repoURL == "https://github.com/test/repo") &&
        (app.spec.destination.namespace == "production");
    expected = true;
  };

  # Test 26: ArgoCD AppProject generation
  testArgoCDAppProject = {
    name = "argocd appproject generation";
    test =
      let
        project = gitops.mkAppProject {
          name = "test-project";
          description = "Test project";
          sourceRepos = ["https://github.com/test/repo"];
          destinations = [
            { namespace = "default"; server = "https://kubernetes.default.svc"; }
          ];
        };
      in
        # Should create valid ArgoCD AppProject
        (project.apiVersion == "argoproj.io/v1alpha1") &&
        (project.kind == "AppProject") &&
        (project.metadata.name == "test-project") &&
        (project.spec.description == "Test project") &&
        (builtins.length project.spec.destinations > 0);
    expected = true;
  };

  # Test 27: GitOps deployment patterns
  testGitOpsDeploymentPatterns = {
    name = "gitops deployment patterns";
    test =
      let
        singleCluster = gitops.mkSingleClusterDeployment {
          name = "single";
          gitRepository = "https://github.com/test/repo";
          path = "./apps";
        };
        
        multiCluster = gitops.mkMultiClusterDeployment {
          name = "multi";
          gitRepository = "https://github.com/test/repo";
          clusters = {
            "us-east" = { server = "https://us-east.example.com"; };
            "eu-west" = { server = "https://eu-west.example.com"; };
          };
        };
      in
        # Should create valid deployment patterns
        (singleCluster ? flux) &&
        (singleCluster ? argocd) &&
        (multiCluster ? applications) &&
        (multiCluster.clusterCount == 2);
    expected = true;
  };

  # Test 28: GitOps sync policies
  testGitOpsSyncPolicies = {
    name = "gitops sync policies";
    test =
      let
        syncPolicy = gitops.mkSyncPolicy {
          automated = true;
          syncOptions = ["CreateNamespace=true"];
        };
      in
        # Should have valid sync policy
        (syncPolicy ? automated) &&
        (syncPolicy ? retry) &&
        (builtins.length syncPolicy.syncOptions > 0) &&
        (syncPolicy.automated.prune == true) &&
        (syncPolicy.automated.selfHeal == true);
    expected = true;
  };

   # Test 29: GitOps configuration presets
   testGitOpsPresets = {
     name = "gitops configuration presets";
     test =
       let
         presets = gitops.presets;
       in
         # Should have all presets
         (presets ? aggressive) &&
         (presets ? standard) &&
         (presets ? conservative) &&
         (presets ? development) &&
         # Each preset should have sync configuration
         (presets.aggressive ? interval) &&
         (presets.standard.interval == "10m") &&
         (presets.conservative.prune == false);
     expected = true;
   };

   # Test 30: Policy Visualization - Dependency Graph
   testPolicyVisualizationGraph = {
     name = "policy visualization dependency graph";
     test =
       let
         policies = [
           {
             metadata = {
               name = "policy-a";
               namespace = "default";
               labels = { severity = "high"; };
               annotations = { "depends-on" = "policy-b"; };
             };
             spec = { rules = [{} {} {}]; };
           }
           {
             metadata = {
               name = "policy-b";
               namespace = "default";
               labels = { severity = "medium"; };
               annotations = { "validation-status" = "valid"; };
             };
             spec = { rules = [{} {}]; };
           }
         ];
         graph = policyVisualization.dependencyGraph { inherit policies; };
       in
         # Should create valid dependency graph
         (graph.type == "dependency-graph") &&
         (builtins.length graph.nodes == 2) &&
         (builtins.length graph.links > 0) &&
         (graph.statistics.nodeCount == 2) &&
         (graph.d3 ? nodes) &&
         (graph.d3 ? links);
     expected = true;
   };

   # Test 31: Policy Visualization - Network Topology
   testPolicyVisualizationTopology = {
     name = "policy visualization network topology";
     test =
       let
         cluster = {
           pods = [
             {
               metadata = { name = "pod-1"; namespace = "default"; labels = { app = "web"; }; };
               spec = { containers = [{ name = "app"; }]; };
               status = { phase = "Running"; };
             }
             {
               metadata = { name = "pod-2"; namespace = "default"; labels = { app = "api"; }; };
               spec = { containers = [{ name = "app"; }]; };
               status = { phase = "Running"; };
             }
           ];
           services = [
             {
               metadata = { name = "web-svc"; namespace = "default"; };
               spec = { selector = { app = "web"; }; ports = [{ port = 80; }]; clusterIP = "10.0.0.1"; };
             }
           ];
           networkPolicies = [];
         };
         topology = policyVisualization.networkTopology { inherit cluster; };
       in
         # Should create valid network topology
         (topology.type == "network-topology") &&
         (builtins.length topology.nodes > 0) &&
         (topology.statistics.podCount == 2) &&
         (topology.statistics.serviceCount == 1) &&
         (topology.namespaces ? default);
     expected = true;
   };

   # Test 32: Policy Visualization - Policy Interactions
   testPolicyVisualizationInteractions = {
     name = "policy visualization interactions";
     test =
       let
         policies = [
           {
             metadata = {
               name = "policy-x";
               namespace = "default";
               labels = { severity = "high"; };
               annotations = {};
             };
             spec = { podSelector = { matchLabels = { app = "web"; }; }; rules = []; };
           }
           {
             metadata = {
               name = "policy-y";
               namespace = "default";
               labels = { severity = "medium"; };
               annotations = {};
             };
             spec = { podSelector = { matchLabels = { app = "web"; }; }; rules = []; };
           }
         ];
         interactions = policyVisualization.policyInteractions { inherit policies; };
       in
         # Should detect policy interactions
         (interactions.type == "policy-interactions") &&
         (interactions.statistics ? totalInteractions) &&
         (interactions ? byType) &&
         (interactions ? conflictMatrix);
     expected = true;
   };

   # Test 33: Policy Visualization - SVG Export
   testPolicyVisualizationExport = {
     name = "policy visualization svg export";
     test =
       let
         graph = policyVisualization.dependencyGraph {
           policies = [
             {
               metadata = { name = "test-policy"; namespace = "default"; labels = { severity = "high"; }; annotations = {}; };
               spec = { rules = [{}]; };
             }
           ];
         };
         export = policyVisualization.exportVisualization { visualization = graph; format = "svg"; };
       in
         # Should export valid visualization
         (export.format == "svg") &&
         (export ? config) &&
         (export ? d3) &&
         (export ? svg) &&
         (export.svg ? metadata) &&
         (export.svg.metadata ? width) &&
         (export.svg.metadata.width == 1200);
     expected = true;
   };

   # Test 34: Policy Visualization - Themes
   testPolicyVisualizationThemes = {
     name = "policy visualization themes";
     test =
       let
         defaultTheme = policyVisualization.visualizationTheme {};
         darkTheme = policyVisualization.visualizationTheme { theme = "dark"; };
         minimalTheme = policyVisualization.visualizationTheme { theme = "minimal"; };
       in
         # Should create valid themes
         (defaultTheme ? colors) &&
         (defaultTheme.colors ? nodeDefault) &&
         (defaultTheme ? styles) &&
         (defaultTheme.styles.fontSize == 12) &&
         (darkTheme.colors.background == "#1E1E1E") &&
         (minimalTheme.styles.nodeOpacity == 1.0);
     expected = true;
   };

   # Test 35: Security Scanning - Trivy Image Scanning
   testSecurityScanningTrivy = {
     name = "security scanning trivy image scan";
     test =
       let
         images = [ "nginx:latest" "postgres:15" "redis:7.0" ];
         scan = securityScanning.trivyScan { inherit images; };
       in
         # Should create valid trivy scan results
         (scan.type == "trivy-scan") &&
         (builtins.length scan.results == 3) &&
         (scan.aggregated ? totalImages) &&
         (scan.riskAssessment ? overallRisk) &&
         (scan.statistics ? scannedImages);
     expected = true;
   };

   # Test 36: Security Scanning - Snyk Dependency Scanning
   testSecurityScanningSnyk = {
     name = "security scanning snyk dependencies";
     test =
       let
         manifests = [
           { "package.json" = {}; }
           { "Pipfile" = {}; }
         ];
         scan = securityScanning.snykScan { inherit manifests; };
       in
         # Should create valid snyk scan results
         (scan.type == "snyk-scan") &&
         (builtins.length scan.results == 2) &&
         (scan.aggregated ? totalManifests) &&
         (scan.riskAssessment ? remediationPossible) &&
         (scan.statistics ? manifestsScanned);
     expected = true;
   };

   # Test 37: Security Scanning - Falco Runtime Monitoring
   testSecurityScanningFalco = {
     name = "security scanning falco runtime";
     test =
       let
         rules = {
           malicious_behavior = [];
           network_anomaly = [];
         };
         monitoring = securityScanning.falcoMonitoring { inherit rules; };
       in
         # Should create valid falco configuration
         (monitoring.type == "falco-monitoring") &&
         (monitoring.totalRules > 0) &&
         (monitoring.alerts ? channels) &&
         (monitoring.deployment ? daemonSetConfig) &&
         (monitoring.statistics ? totalRules);
     expected = true;
   };

   # Test 38: Security Scanning - Orchestration
   testSecurityScanningOrchestration = {
     name = "security scanning orchestration";
     test =
       let
         scanConfigs = [
           { type = "trivy"; target = "images"; }
           { type = "snyk"; target = "dependencies"; }
         ];
         orchestration = securityScanning.securityOrchestration { inherit scanConfigs; };
       in
         # Should create valid orchestration pipeline
         (orchestration.type == "security-orchestration") &&
         (builtins.length orchestration.pipeline > 0) &&
         (orchestration.schedule ? cronExpression) &&
         (orchestration.reporting ? formats) &&
         (orchestration.complianceTracking ? frameworks);
     expected = true;
   };

   # Test 39: Security Scanning - Report Generation
   testSecurityScanningReport = {
     name = "security scanning report generation";
     test =
       let
         scans = [
           {
             type = "trivy-scan";
             bySeverity = { critical = []; high = []; medium = []; };
             aggregated = { critical = []; high = []; };
           }
         ];
         report = securityScanning.generateSecurityReport { inherit scans; };
       in
         # Should create valid security report
         (report.type == "security-report") &&
         (report.summary ? totalVulnerabilities) &&
         (report.findings ? CRITICAL || report.findings ? HIGH) &&
         (report ? recommendations) &&
         (report ? remediationPlan);
     expected = true;
   };

   # Test 40: Performance Analysis - Resource Profiling
   testPerformanceAnalysisProfile = {
     name = "performance analysis resource profiling";
     test =
       let
         workloads = [
           {
             name = "web-app";
             namespace = "production";
             type = "pod";
             containers = 2;
             cpu = { requested = "100m"; limit = "500m"; };
             memory = { requested = "128Mi"; limit = "512Mi"; };
           }
           {
             name = "api-server";
             namespace = "production";
             type = "pod";
             containers = 3;
             cpu = { requested = "200m"; limit = "1000m"; };
             memory = { requested = "256Mi"; limit = "1Gi"; };
           }
         ];
         profile = performanceAnalysis.profileResources { inherit workloads; };
       in
         # Should create valid resource profile
         (profile.type == "resource-profile") &&
         (builtins.length profile.workloads == 2) &&
         (profile.aggregated ? totalWorkloads) &&
         (profile ? byNamespace) &&
         (profile ? utilizationAnalysis);
     expected = true;
   };

   # Test 41: Performance Analysis - Bottleneck Detection
   testPerformanceAnalysisBottlenecks = {
     name = "performance analysis bottleneck detection";
     test =
       let
         metrics = { cpu = 85; memory = 70; disk = 60; network = 40; };
         bottlenecks = performanceAnalysis.detectBottlenecks { inherit metrics; };
       in
         # Should detect bottlenecks
         (bottlenecks.type == "bottleneck-detection") &&
         (builtins.length bottlenecks.bottlenecks > 0) &&
         (bottlenecks ? bySeverity) &&
         (bottlenecks ? rootCauseAnalysis) &&
         (bottlenecks.healthStatus != null);
     expected = true;
   };

   # Test 42: Performance Analysis - Optimization Recommendations
   testPerformanceAnalysisRecommendations = {
     name = "performance analysis optimization recommendations";
     test =
       let
         profile = {
           type = "resource-profile";
           workloads = [
             { name = "app-1"; cpu = 50; memory = 45; }
           ];
           utilizationAnalysis = { cpu = { average = 40; }; };
         };
         bottlenecks = {
           type = "bottleneck-detection";
           statistics = { criticalComponents = 0; };
         };
         recommendations = performanceAnalysis.recommendOptimizations { inherit profile bottlenecks; };
       in
         # Should generate recommendations
         (recommendations.type == "optimization-recommendations") &&
         (recommendations ? recommendations) &&
         (recommendations ? byCategory) &&
         (recommendations.impactAnalysis ? estimatedCostSavings) &&
         (recommendations ? prioritizedRecommendations);
     expected = true;
   };

   # Test 43: Performance Analysis - Comparison
   testPerformanceAnalysisComparison = {
     name = "performance analysis comparison";
     test =
       let
         baseline = { cpu = 50; memory = 45; latency = 100; };
         current = { cpu = 55; memory = 48; latency = 110; };
         comparison = performanceAnalysis.comparePerformance { inherit baseline current; };
       in
         # Should create valid comparison
         (comparison.type == "performance-comparison") &&
         (comparison.comparisons ? cpu) &&
         (comparison.comparisons ? memory) &&
         (comparison.comparisons ? latency) &&
         (comparison ? verdict);
     expected = true;
   };

   # Test 44: Performance Analysis - Trends
   testPerformanceAnalysisTrends = {
     name = "performance analysis trends";
     test =
       let
         measurements = {
           cpu = [ 50 51 49 52 50 ];
           memory = [ 45 46 44 47 45 ];
           latency = [ 100 102 98 105 101 ];
         };
         trends = performanceAnalysis.analyzeTrends { inherit measurements; };
       in
         # Should analyze trends
         (trends.type == "performance-trends") &&
         (trends.trends ? cpu) &&
         (trends.trends ? memory) &&
         (trends.trends ? latency) &&
         (trends ? forecast);
     expected = true;
   };

   # Test 45: Performance Analysis - Report Generation
   testPerformanceAnalysisReport = {
     name = "performance analysis report generation";
     test =
       let
         profile = { utilizationAnalysis = { cpu = { average = 50; }; }; statistics = { profiledWorkloads = 5; }; };
         bottlenecks = { statistics = { criticalComponents = 0; }; bottlenecks = []; };
         recommendations = { statistics = { totalRecommendations = 3; }; recommendations = []; };
         report = performanceAnalysis.generatePerformanceReport { inherit profile bottlenecks recommendations; };
       in
         # Should generate performance report
         (report.type == "performance-report") &&
         (report.summary ? overallHealth) &&
         (report ? metrics) &&
         (report ? findings) &&
         (report ? actionPlan);
      expected = true;
    };

    # Test 46: Unified API - Application Builder
    testUnifiedApiApplicationBuilder = {
      name = "unified API application builder";
      test =
        let
          app = unifiedApi.mkApplication "test-app" {
            image = "nginx:1.24";
            replicas = 2;
            namespace = "default";
          };
        in
          # Should create valid application with name, image, replicas
          (app.name == "test-app") &&
          (app.image == "nginx:1.24") &&
          (app.replicas == 2) &&
          (app.namespace == "default") &&
          (app.resources ? requests) &&
          (app.resources ? limits);
      expected = true;
    };

    # Test 47: Unified API - Cluster Builder
    testUnifiedApiClusterBuilder = {
      name = "unified API cluster builder";
      test =
        let
          cluster = unifiedApi.mkCluster "prod-cluster" {
            kubernetesVersion = "1.30";
            provider = "aws";
            region = "us-east-1";
          };
        in
          # Should create valid cluster configuration
          (cluster.name == "prod-cluster") &&
          (cluster.kubernetesVersion == "1.30") &&
          (cluster.provider == "aws") &&
          (cluster.region == "us-east-1") &&
          (cluster.compliance ? framework) &&
          (cluster.observability ? enabled) &&
          (cluster.networking ? policyMode);
      expected = true;
    };

    # Test 48: Unified API - Security Policy Builder
    testUnifiedApiSecurityPolicyBuilder = {
      name = "unified API security policy builder";
      test =
        let
          policy = unifiedApi.mkSecurityPolicy "strict-policy" {
            namespace = "production";
            level = "strict";
          };
        in
          # Should create valid security policy
          (policy.name == "strict-policy") &&
          (policy.namespace == "production") &&
          (policy.level == "strict") &&
          (policy.podSecurity ? enforce) &&
          (policy.networkPolicies ? enabled) &&
          (policy.rbac ? enabled) &&
          (policy.secretManagement ? encryptionAtRest);
      expected = true;
    };

    # Test 49: Unified API - Compliance Builder
    testUnifiedApiComplianceBuilder = {
      name = "unified API compliance builder";
      test =
        let
          socCompliance = unifiedApi.mkCompliance "SOC2" { auditLog = true; };
          pciCompliance = unifiedApi.mkCompliance "PCI-DSS" { encryption = true; };
          hipaaCompliance = unifiedApi.mkCompliance "HIPAA" { accessControl = true; };
        in
          # Should create valid compliance configurations
          (socCompliance.name == "SOC2") &&
          (socCompliance.auditLog == true) &&
          (pciCompliance.name == "PCI-DSS") &&
          (pciCompliance.encryption == true) &&
          (hipaaCompliance.name == "HIPAA") &&
          (hipaaCompliance.accessControl == true);
      expected = true;
    };

    # Test 50: Unified API - Observability Builder
    testUnifiedApiObservabilityBuilder = {
      name = "unified API observability builder";
      test =
        let
          observability = unifiedApi.mkObservability "monitoring" {
            namespace = "monitoring";
            logging = { enabled = true; backend = "loki"; };
            metrics = { enabled = true; backend = "prometheus"; };
          };
        in
          # Should create valid observability configuration
          (observability.name == "monitoring") &&
          (observability.namespace == "monitoring") &&
          (observability.logging.enabled == true) &&
          (observability.logging.backend == "loki") &&
          (observability.metrics.enabled == true) &&
          (observability.metrics.backend == "prometheus") &&
          (observability.alerting ? enabled);
      expected = true;
    };

    # Test 51: Unified API - Cost Tracking Builder
    testUnifiedApiCostTrackingBuilder = {
      name = "unified API cost tracking builder";
      test =
        let
          costTracking = unifiedApi.mkCostTracking "aws-costs" {
            provider = "aws";
            resourceTracking = { enabled = true; };
            costAnalysis = { enabled = true; };
          };
        in
          # Should create valid cost tracking configuration
          (costTracking.name == "aws-costs") &&
          (costTracking.provider == "aws") &&
          (costTracking.resourceTracking.enabled == true) &&
          (costTracking.costAnalysis.enabled == true) &&
          (costTracking.optimization ? enabled);
      expected = true;
    };

    # Test 52: Unified API - Performance Tracking Builder
    testUnifiedApiPerformanceTrackingBuilder = {
      name = "unified API performance tracking builder";
      test =
        let
          performance = unifiedApi.mkPerformanceTracking "perf-analysis" {
            profiling = { enabled = true; cpuProfiling = true; };
            benchmarking = { enabled = true; };
          };
        in
          # Should create valid performance tracking configuration
          (performance.name == "perf-analysis") &&
          (performance.profiling.enabled == true) &&
          (performance.profiling.cpuProfiling == true) &&
          (performance.benchmarking.enabled == true) &&
          (performance.bottleneckDetection ? enabled);
      expected = true;
    };

    # Test 53: Unified API - Application Validation
    testUnifiedApiApplicationValidation = {
      name = "unified API application validation";
      test =
        let
          validApp = unifiedApi.mkApplication "app" {
            image = "nginx:1.24";
            replicas = 1;
          };
          validationResult = unifiedApi.validateApplication validApp;
        in
          # Should validate correctly
          (validationResult.valid == true) &&
          (validationResult.errors == []);
      expected = true;
    };

    # Test 54: Unified API - Cluster Validation
    testUnifiedApiClusterValidation = {
      name = "unified API cluster validation";
      test =
        let
          validCluster = unifiedApi.mkCluster "test" {
            kubernetesVersion = "1.30";
            provider = "aws";
          };
          validationResult = unifiedApi.validateCluster validCluster;
        in
          # Should validate correctly
          (validationResult.valid == true) &&
          (validationResult.errors == []);
      expected = true;
    };

    # Test 55: Policy Testing - Test Builder
    testPolicyTestingTestBuilder = {
      name = "policy testing test builder";
      test =
        let
          policy = kyverno.mkValidationPolicy {
            name = "test-policy";
            rules = [];
          };
          test = policyTesting.mkPolicyTest "test-1" {
            inherit policy;
            resource = { apiVersion = "v1"; kind = "Pod"; };
            expectedResult = "pass";
            tags = ["security"];
          };
        in
          # Should create valid test
          (test.name == "test-1") &&
          (test.policy.metadata.name == "test-policy") &&
          (test.expectedResult == "pass") &&
          (builtins.elem "security" test.tags);
      expected = true;
    };

    # Test 56: Policy Testing - Validation Policy Test
    testPolicyTestingValidationPolicyTest = {
      name = "policy testing validation policy test builder";
      test =
        let
          policy = kyverno.mkValidationPolicy {
            name = "validation-test-policy";
            rules = [];
          };
          test = policyTesting.mkValidationPolicyTest "validation-test" {
            inherit policy;
            resource = { apiVersion = "v1"; kind = "Pod"; };
            shouldPass = true;
          };
        in
          # Should create validation policy test
          (test.name == "validation-test") &&
          (test.expectedResult == "pass") &&
          (test.policy.metadata.name == "validation-test-policy");
      expected = true;
    };

    # Test 57: Policy Testing - Mutation Policy Test
    testPolicyTestingMutationPolicyTest = {
      name = "policy testing mutation policy test builder";
      test =
        let
          policy = kyverno.mkMutationPolicy {
            name = "mutation-policy";
            rules = [];
          };
          test = policyTesting.mkMutationPolicyTest "mutation-test" {
            inherit policy;
            resource = { apiVersion = "v1"; kind = "Pod"; };
          };
        in
          # Should create mutation policy test
          (test.name == "mutation-test") &&
          (test.expectedResult == "mutate") &&
          (test.policy.metadata.name == "mutation-policy");
      expected = true;
    };

    # Test 58: Policy Testing - Test Suite Builder
    testPolicyTestingTestSuite = {
      name = "policy testing test suite builder";
      test =
        let
          tests = [
            { name = "test1"; result = { passed = true; duration = 1; }; }
            { name = "test2"; result = { passed = true; duration = 2; }; }
            { name = "test3"; result = { passed = false; duration = 1; }; }
          ];
          suite = policyTesting.mkPolicyTestSuite "test-suite" {
            inherit tests;
            policies = [];
          };
        in
          # Should create valid test suite with statistics
          (suite.name == "test-suite") &&
          (suite.statistics.total == 3) &&
          (suite.statistics.passed == 2) &&
          (suite.statistics.failed == 1) &&
          (suite.statistics.successRate == 66);  # 2/3 * 100 ≈ 66
      expected = true;
    };

    # Test 59: Policy Testing - Policy Compliance Test
    testPolicyTestingPolicyCompliance = {
      name = "policy testing policy compliance";
      test =
        let
          compliantPolicy = kyverno.mkValidationPolicy {
            name = "well-documented-policy";
            metadata = {
              annotations = { description = "Test policy"; };
            };
            rules = [{
              name = "test-rule";
              match = { resources = { kinds = ["Pod"]; }; };
            }];
          };
          compliance = policyTesting.mkPolicyComplianceTest compliantPolicy;
        in
          # Should verify policy compliance
          (compliance.hasValidStructure == true) &&
          (compliance.isDocumented == true) &&
          (compliance.hasMeaningfulName == true) &&
          (compliance.hasSelectors == true);
      expected = true;
    };

    # Test 60: Policy Testing - Coverage Analysis
    testPolicyTestingCoverageAnalysis = {
      name = "policy testing coverage analysis";
      test =
        let
          policies = [
            (kyverno.mkValidationPolicy {
              name = "policy1";
              rules = [
                { name = "rule1"; match = { resources = { kinds = ["Pod"]; }; }; }
                { name = "rule2"; match = { resources = { kinds = ["Pod"]; }; }; }
              ];
            })
            (kyverno.mkMutationPolicy {
              name = "policy2";
              rules = [
                { name = "rule3"; match = { resources = { kinds = ["Deployment"]; }; }; }
              ];
            })
          ];
          coverage = policyTesting.analyzePolicyCoverage policies;
        in
          # Should analyze coverage correctly
          (coverage.totalPolicies == 2) &&
          (coverage.totalRules == 3) &&
          (coverage.validationPolicies == 1) &&
          (coverage.mutationPolicies == 1) &&
          (coverage.generationPolicies == 0);
      expected = true;
    };

    # Test 61: Policy Testing - Test Fixtures
    testPolicyTestingFixtures = {
      name = "policy testing fixtures";
      test =
        let
          restrictedFixture = policyTesting.fixtures.restrictedPod;
          permissiveFixture = policyTesting.fixtures.permissivePod;
          deploymentFixture = policyTesting.fixtures.standardDeployment;
        in
          # Should provide valid fixtures
          (restrictedFixture.kind == "Pod") &&
          (restrictedFixture.metadata.name == "restricted-pod") &&
          (permissiveFixture.kind == "Pod") &&
          (permissiveFixture.metadata.name == "permissive-pod") &&
          (deploymentFixture.kind == "Deployment") &&
          (deploymentFixture.metadata.name == "standard-app");
      expected = true;
    };

     # Test 62: Policy Testing - Framework Information
     testPolicyTestingFrameworkInfo = {
       name = "policy testing framework information";
       test =
         let
           framework = policyTesting.framework;
         in
           # Should provide framework metadata
           (framework.name == "Nixernetes Policy Testing Framework") &&
           (framework.version == "1.0.0") &&
           (framework.features ? "validation-policy-testing") &&
           (builtins.elem "ClusterPolicy" framework.supportedPolicyTypes) &&
           (builtins.elem "unit" framework.testFrameworks);
       expected = true;
     };

     # Test 63: Helm Integration - Chart Metadata Builder
     testHelmChartMetadata = {
       name = "helm integration chart metadata";
       test =
         let
           metadata = helmIntegration.mkChartMetadata "test-chart" {
             description = "Test chart for validation";
             version = "1.0.0";
             appVersion = "1.0.0";
             keywords = ["test" "validation"];
             maintainers = [{
               name = "Test Team";
               email = "test@example.com";
             }];
           };
         in
           # Should create valid chart metadata
           (metadata.name == "test-chart") &&
           (metadata.version == "1.0.0") &&
           (metadata.appVersion == "1.0.0") &&
           (metadata.type == "application") &&
           (metadata.description == "Test chart for validation") &&
           (builtins.length metadata.keywords == 2) &&
           (metadata.kubeVersion == ">=1.28.0");
       expected = true;
     };

     # Test 64: Helm Integration - Chart Values Builder
     testHelmChartValues = {
       name = "helm integration chart values";
       test =
         let
           values = helmIntegration.mkChartValues "test-app" {
             replicaCount = 3;
             image = {
               repository = "myregistry.azurecr.io/test-app";
               tag = "1.0.0";
               pullPolicy = "Always";
             };
             service = {
               type = "LoadBalancer";
               port = 443;
               targetPort = 8443;
             };
             resources = {
               limits = {
                 cpu = "1000m";
                 memory = "1Gi";
               };
               requests = {
                 cpu = "500m";
                 memory = "512Mi";
               };
             };
           };
         in
           # Should create valid values structure
           (values.replicaCount == 3) &&
           (values.image.repository == "myregistry.azurecr.io/test-app") &&
           (values.image.tag == "1.0.0") &&
           (values.image.pullPolicy == "Always") &&
           (values.service.type == "LoadBalancer") &&
           (values.service.port == 443) &&
           (values.resources.limits.cpu == "1000m") &&
           (values.resources.requests.memory == "512Mi") &&
           (values.autoscaling.enabled == false);
       expected = true;
     };

     # Test 65: Helm Integration - Helm Chart Builder
     testHelmChartBuilder = {
       name = "helm integration chart builder";
       test =
         let
           chart = helmIntegration.mkHelmChart "complete-app" {
             description = "Complete application chart";
             version = "2.0.0";
             appVersion = "2.0.0";
             image = {
               repository = "nginx";
               tag = "1.24-alpine";
             };
             service = {
               type = "ClusterIP";
               port = 80;
               targetPort = 8080;
             };
             replicaCount = 2;
           };
         in
           # Should create valid helm chart
           (chart.name == "complete-app") &&
           (chart.metadata.version == "2.0.0") &&
           (chart.metadata.appVersion == "2.0.0") &&
           (chart.manifest.apiVersion == "v2") &&
           (chart.values.replicaCount == 2) &&
           (chart.values.image.repository == "nginx") &&
           (chart.values.service.port == 80) &&
           (chart.chartPath == "charts/complete-app");
       expected = true;
     };

     # Test 66: Helm Integration - Chart Validation
     testHelmChartValidation = {
       name = "helm integration chart validation";
       test =
         let
           validChart = helmIntegration.mkHelmChart "valid-app" {
             description = "Valid chart";
             version = "1.5.3";
             image = { repository = "app"; tag = "1.0"; };
           };
           validationResult = helmIntegration.validateChart validChart;
           
           invalidChart = helmIntegration.mkHelmChart "invalid-app" {
             description = "";
             version = "invalid-version";
             image = { repository = "app"; tag = "1.0"; };
           };
           invalidationResult = helmIntegration.validateChart invalidChart;
         in
           # Should validate charts correctly
           (validationResult.valid == true) &&
           (builtins.length validationResult.errors == 0) &&
           (invalidationResult.valid == false) &&
           (builtins.length invalidationResult.errors > 0);
       expected = true;
     };

     # Test 67: Helm Integration - Chart Dependency Builder
     testHelmChartDependency = {
       name = "helm integration chart dependency";
       test =
         let
           dep = helmIntegration.mkChartDependency "postgresql" {
             version = "13.0.0";
             repository = "oci://registry.example.com/charts";
             condition = "postgresql.enabled";
             tags = ["database"];
           };
         in
           # Should create valid dependency
           (dep.name == "postgresql") &&
           (dep.version == "13.0.0") &&
           (dep.repository == "oci://registry.example.com/charts") &&
           (dep.condition == "postgresql.enabled") &&
           (builtins.elem "database" dep.tags);
       expected = true;
     };

     # Test 68: Helm Integration - Application to Chart Conversion
     testHelmApplicationConversion = {
       name = "helm integration application conversion";
       test =
         let
           app = {
             name = "my-app";
             image = "myregistry.azurecr.io/my-app:2.0.0";
             replicas = 3;
             port = 3000;
             imagePullPolicy = "IfNotPresent";
             annotations = {
               "prometheus.io/scrape" = "true";
             };
             securityContext = {
               runAsNonRoot = true;
             };
             env = {
               ENV = "production";
               DEBUG = "false";
             };
             resources = {
               limits = { cpu = "500m"; };
               requests = { memory = "256Mi"; };
             };
           };
           chartValues = helmIntegration.applicationToChartValues app;
         in
           # Should convert application to chart values
           (chartValues.replicaCount == 3) &&
           (chartValues.image.repository == "myregistry.azurecr.io/my-app") &&
           (chartValues.image.tag == "2.0.0") &&
           (chartValues.service.port == 3000) &&
           (chartValues.podAnnotations ? "prometheus.io/scrape") &&
           (builtins.length chartValues.env > 0);
       expected = true;
     };

     # Test 69: Helm Integration - Chart Packaging
     testHelmChartPackaging = {
       name = "helm integration chart packaging";
       test =
         let
           chart = helmIntegration.mkHelmChart "packaged-app" {
             description = "App for packaging";
             version = "1.0.0";
             image = { repository = "app"; tag = "1.0"; };
           };
           package = helmIntegration.mkChartPackage chart;
         in
           # Should create valid chart package
           (package.name == "packaged-app") &&
           (package.structure ? "Chart.yaml") &&
           (package.structure ? "values.yaml") &&
           (package.structure ? "templates/deployment.yaml") &&
           (package.structure ? "templates/service.yaml") &&
           (package.structure ? "templates/_helpers.tpl") &&
           (package.structure ? "README.md") &&
           (builtins.match ".*packaged-app.*tgz" package.publishPath != null);
       expected = true;
     };

     # Test 70: Helm Integration - Framework Information
     testHelmIntegrationFrameworkInfo = {
       name = "helm integration framework information";
       test =
         let
           framework = helmIntegration.framework;
         in
           # Should provide framework metadata
           (framework.name == "Nixernetes Helm Integration") &&
           (framework.version == "1.0.0") &&
           (framework.features ? "chart-generation") &&
           (framework.features ? "values-generation") &&
           (framework.features ? "chart-validation") &&
           (framework.features ? "dependency-management") &&
           (framework.features ? "unified-api-integration") &&
           (builtins.elem "3.10+" framework.supportedHelmVersions) &&
           (builtins.elem "1.28" framework.supportedKubernetesVersions);
       expected = true;
     };

     # Test 71: Advanced Orchestration - Workload Affinity Policy
     testAdvancedOrchestrationAffinityPolicy = {
       name = "advanced orchestration affinity policy";
       test =
         let
           policy = advancedOrchestration.mkWorkloadAffinityPolicy "test-affinity" {
             podAffinityPresets = ["web" "cache"];
             nodeAffinityRules = [];
             antiAffinityStrength = "soft";
             topologyKey = "kubernetes.io/hostname";
             spreadKey = "topology.kubernetes.io/zone";
           };
         in
           # Should create valid affinity policy
           (policy.name == "test-affinity") &&
           (policy.antiAffinityStrength == "soft") &&
           (builtins.length policy.podAffinityPresets == 2) &&
           (policy.topologyKey == "kubernetes.io/hostname");
       expected = true;
     };

     # Test 72: Advanced Orchestration - Pod Disruption Budget
     testAdvancedOrchestrationPDB = {
       name = "advanced orchestration pod disruption budget";
       test =
         let
           pdb = advancedOrchestration.mkPodDisruptionBudget "test-pdb" {
             namespace = "production";
             selector = { matchLabels = { app = "test"; }; };
             minAvailable = 2;
             maxUnavailable = 1;
             unhealthyPodEvictionPolicy = "IfHealthyBudget";
           };
         in
           # Should create valid PDB
           (pdb.name == "test-pdb") &&
           (pdb.namespace == "production") &&
           (pdb.minAvailable == 2) &&
           (pdb.maxUnavailable == 1) &&
           (pdb.unhealthyPodEvictionPolicy == "IfHealthyBudget");
       expected = true;
     };

     # Test 73: Advanced Orchestration - Priority Classes
     testAdvancedOrchestrationPriorityClass = {
       name = "advanced orchestration priority class";
       test =
         let
           highPriority = advancedOrchestration.mkPriorityClass "high" {
             value = 1000;
             globalDefault = false;
             description = "High priority";
             preemptionPolicy = "PreemptLowerPriority";
           };
           
           lowPriority = advancedOrchestration.mkPriorityClass "low" {
             value = 100;
             preemptionPolicy = "Never";
           };
         in
           # Should create valid priority classes
           (highPriority.name == "high") &&
           (highPriority.value == 1000) &&
           (highPriority.preemptionPolicy == "PreemptLowerPriority") &&
           (lowPriority.value == 100) &&
           (lowPriority.preemptionPolicy == "Never");
       expected = true;
     };

     # Test 74: Advanced Orchestration - Multi-Cluster Policy
     testAdvancedOrchestrationMultiCluster = {
       name = "advanced orchestration multi-cluster policy";
       test =
         let
           policy = advancedOrchestration.mkMultiClusterPolicy "global-app" {
             clusters = ["us-east-1" "us-west-1" "eu-west-1"];
             distribution = "cost-optimized";
             weights = {
               "us-east-1" = 0.5;
               "us-west-1" = 0.3;
               "eu-west-1" = 0.2;
             };
             failoverChain = ["us-east-1" "us-west-1" "eu-west-1"];
             preferredRegions = ["us"];
             costOptimization = true;
             latencyThreshold = 100;
           };
           
           validation = advancedOrchestration.validateMultiClusterPolicy policy;
         in
           # Should create valid multi-cluster policy
           (policy.name == "global-app") &&
           (builtins.length policy.clusters == 3) &&
           (policy.distribution == "cost-optimized") &&
           (policy.costOptimization == true) &&
           (policy.weights ? "us-east-1") &&
           (validation.valid == true);
       expected = true;
     };

     # Test 75: Advanced Orchestration - Capacity Planner
     testAdvancedOrchestrationCapacityPlanner = {
       name = "advanced orchestration capacity planner";
       test =
         let
           planner = advancedOrchestration.mkCapacityPlanner "prod-cluster" {
             clusterName = "production";
             currentCapacity = {
               nodes = 10;
               cpuPerNode = "16";
               memoryPerNode = "32Gi";
               storagePerNode = "200Gi";
             };
             currentUtilization = {
               cpu = 0.65;
               memory = 0.72;
               storage = 0.55;
             };
             forecastingPeriod = 90;
             targetUtilization = {
               cpu = 0.70;
               memory = 0.75;
               storage = 0.80;
             };
             growthRate = 0.12;
           };
         in
           # Should create valid capacity planner
           (planner.clusterName == "production") &&
           (planner.currentCapacity.nodes == 10) &&
           (planner.currentUtilization.cpu == 0.65) &&
           (planner.forecastingPeriod == 90) &&
           (planner.growthRate == 0.12);
       expected = true;
     };

     # Test 76: Advanced Orchestration - Resource Optimizer
     testAdvancedOrchestrationResourceOptimizer = {
       name = "advanced orchestration resource optimizer";
       test =
         let
           optimizer = advancedOrchestration.mkResourceOptimizer "api-server" {
             workloadName = "api-server";
             workloadType = "deployment";
             analysisWindow = 30;
             recommendationType = "balanced";
             vpaRecommendations = {
               enabled = true;
               updateMode = "Auto";
               minAllowedResources = { cpu = "100m"; memory = "128Mi"; };
               maxAllowedResources = { cpu = "4"; memory = "8Gi"; };
             };
             hpaRecommendations = {
               enabled = true;
               metric = "cpu";
               targetValue = 70;
               minReplicas = 2;
               maxReplicas = 20;
             };
           };
         in
           # Should create valid resource optimizer
           (optimizer.workloadName == "api-server") &&
           (optimizer.workloadType == "deployment") &&
           (optimizer.analysisWindow == 30) &&
           (optimizer.vpaRecommendations.enabled == true) &&
           (optimizer.hpaRecommendations.targetValue == 70);
       expected = true;
     };

     # Test 77: Advanced Orchestration - Topology Strategy
     testAdvancedOrchestrationTopologyStrategy = {
       name = "advanced orchestration topology strategy";
       test =
         let
           strategy = advancedOrchestration.mkTopologyStrategy "zone-spread" {
             strategyType = "zone-spread";
             dimensions = ["topology.kubernetes.io/zone"];
             skewLimit = 1;
             minDomains = 3;
             nodeAffinityPolicy = "Honor";
             nodeTaintsPolicy = "Honor";
             topology = {
               "us-east-1a" = 3;
               "us-east-1b" = 3;
               "us-east-1c" = 3;
             };
           };
         in
           # Should create valid topology strategy
           (strategy.name == "zone-spread") &&
           (strategy.strategyType == "zone-spread") &&
           (builtins.length strategy.dimensions == 1) &&
           (strategy.skewLimit == 1) &&
           (strategy.minDomains == 3) &&
           (strategy.topology ? "us-east-1a");
       expected = true;
     };

     # Test 78: Advanced Orchestration - Framework Information
     testAdvancedOrchestrationFrameworkInfo = {
       name = "advanced orchestration framework information";
       test =
         let
           framework = advancedOrchestration.framework;
         in
           # Should provide framework metadata
           (framework.name == "Nixernetes Advanced Orchestration") &&
           (framework.version == "1.0.0") &&
           (framework.features ? "workload-affinity") &&
           (framework.features ? "pod-disruption-budgets") &&
           (framework.features ? "priority-classes") &&
           (framework.features ? "multi-cluster-distribution") &&
           (framework.features ? "capacity-planning") &&
           (framework.features ? "resource-optimization") &&
           (framework.features ? "topology-aware-scheduling") &&
           (builtins.elem "cost-optimized" framework.supportedStrategies) &&
           (builtins.elem "1.28" framework.supportedKubernetesVersions);
       expected = true;
      };

      # Test 79: Disaster Recovery - Backup Policy
      testDisasterRecoveryBackupPolicy = {
        name = "disaster recovery backup policy";
        test =
          let
            policy = disasterRecovery.mkBackupPolicy "prod-backup" {
              namespace = "production";
              schedule = "0 2 * * *";
              retention = 30;
              backupType = "full";
              storage = {
                type = "s3";
                bucket = "backups";
                region = "us-east-1";
                pathPrefix = "prod";
              };
              encryption = {
                enabled = true;
                algorithm = "AES-256";
              };
            };
          in
            # Should create valid backup policy
            (policy.name == "prod-backup") &&
            (policy.namespace == "production") &&
            (policy.schedule == "0 2 * * *") &&
            (policy.retention == 30) &&
            (policy.backupType == "full") &&
            (policy.storage.type == "s3") &&
            (policy.encryption.enabled == true);
        expected = true;
      };

      # Test 80: Disaster Recovery - Restore Strategy
      testDisasterRecoveryRestoreStrategy = {
        name = "disaster recovery restore strategy";
        test =
          let
            strategy = disasterRecovery.mkRestoreStrategy "prod-backup-20240204" {
              backupName = "prod-backup-20240204";
              namespace = "production";
              resources = {
                deployments = ["app-*"];
                statefulsets = ["db-*"];
                persistentvolumes = true;
              };
              verifyAfterRestore = true;
              skipOwnerReferences = false;
            };
          in
            # Should create valid restore strategy
            (strategy.backupName == "prod-backup-20240204") &&
            (strategy.namespace == "production") &&
            (builtins.length strategy.resources.deployments == 1) &&
            (strategy.verifyAfterRestore == true) &&
            (strategy.skipOwnerReferences == false);
        expected = true;
      };

      # Test 81: Disaster Recovery - Failover Policy
      testDisasterRecoveryFailoverPolicy = {
        name = "disaster recovery failover policy";
        test =
          let
            policy = disasterRecovery.mkFailoverPolicy "multi-region-failover" {
              primaryCluster = "us-east-1-prod";
              secondaryCluster = "us-west-2-standby";
              clusters = {
                "us-east-1-prod" = {
                  region = "us-east-1";
                  priority = 1;
                  healthChecks = ["kube-apiserver" "etcd" "kubelet"];
                };
                "us-west-2-standby" = {
                  region = "us-west-2";
                  priority = 2;
                  healthChecks = ["kube-apiserver" "etcd" "kubelet"];
                };
              };
              failoverTrigger = {
                unhealthyThreshold = 3;
                checkInterval = "10s";
                gracePeriod = "30s";
              };
              replicationMode = "sync";
              rpo = 60;
              rto = 300;
            };
            validation = disasterRecovery.validateFailoverPolicy policy;
          in
            # Should create valid failover policy and pass validation
            (policy.name == "multi-region-failover") &&
            (policy.primaryCluster == "us-east-1-prod") &&
            (policy.secondaryCluster == "us-west-2-standby") &&
            (policy.replicationMode == "sync") &&
            (policy.rpo == 60) &&
            (policy.rto == 300) &&
            (validation.valid == true);
        expected = true;
      };

      # Test 82: Disaster Recovery - RPO
      testDisasterRecoveryRPO = {
        name = "disaster recovery recovery point objective";
        test =
          let
            rpo = disasterRecovery.mkRPO "prod-rpo" {
              maxDataLoss = "15m";
              dataLossTolerance = "acceptable";
              backupFrequency = "5m";
              verificationEnabled = true;
            };
          in
            # Should create valid RPO
            (rpo.name == "prod-rpo") &&
            (rpo.maxDataLoss == "15m") &&
            (rpo.dataLossTolerance == "acceptable") &&
            (rpo.backupFrequency == "5m") &&
            (rpo.verificationEnabled == true);
        expected = true;
      };

      # Test 83: Disaster Recovery - RTO
      testDisasterRecoveryRTO = {
        name = "disaster recovery recovery time objective";
        test =
          let
            rto = disasterRecovery.mkRTO "prod-rto" {
              maxRecoveryTime = "30m";
              recoveryTimeTolerance = "critical";
              testingFrequency = "monthly";
              escalationContacts = ["team@example.com"];
            };
          in
            # Should create valid RTO
            (rto.name == "prod-rto") &&
            (rto.maxRecoveryTime == "30m") &&
            (rto.recoveryTimeTolerance == "critical") &&
            (rto.testingFrequency == "monthly") &&
            (builtins.length rto.escalationContacts == 1);
        expected = true;
      };

      # Test 84: Disaster Recovery - Plan
      testDisasterRecoveryPlan = {
        name = "disaster recovery comprehensive plan";
        test =
          let
            plan = disasterRecovery.mkDisasterRecoveryPlan "prod-dr-plan" {
              criticality = "critical";
              rpo = 60;
              rto = 300;
              backupStrategy = {
                frequency = "daily";
                retention = 30;
                locations = ["us-east-1" "us-west-2"];
              };
              failoverStrategy = {
                type = "active-passive";
                failoverTime = "5m";
                testingSchedule = "monthly";
              };
              procedures = [
                {
                  name = "initial-assessment";
                  steps = ["assess-damage" "identify-affected-services"];
                  estimatedTime = "15m";
                }
                {
                  name = "activation";
                  steps = ["trigger-failover" "verify-services"];
                  estimatedTime = "10m";
                }
              ];
            };
            validation = disasterRecovery.validateDisasterRecoveryPlan plan;
          in
            # Should create valid DR plan and pass validation
            (plan.name == "prod-dr-plan") &&
            (plan.criticality == "critical") &&
            (plan.rpo == 60) &&
            (plan.rto == 300) &&
            (builtins.length plan.procedures == 2) &&
            (validation.valid == true);
        expected = true;
      };

      # Test 85: Disaster Recovery - Data Replication
      testDisasterRecoveryDataReplication = {
        name = "disaster recovery data replication";
        test =
          let
            replication = disasterRecovery.mkDataReplication "prod-replication" {
              sourceCluster = "us-east-1-prod";
              targetCluster = "us-west-2-standby";
              replicationMode = "sync";
              syncBandwidth = "100Mbps";
              conflictResolution = "last-write-wins";
              selectedNamespaces = ["production" "monitoring"];
              excludeResources = ["Events" "Logs"];
            };
          in
            # Should create valid data replication
            (replication.name == "prod-replication") &&
            (replication.sourceCluster == "us-east-1-prod") &&
            (replication.targetCluster == "us-west-2-standby") &&
            (replication.replicationMode == "sync") &&
            (replication.syncBandwidth == "100Mbps") &&
            (replication.conflictResolution == "last-write-wins") &&
            (builtins.length replication.selectedNamespaces == 2);
        expected = true;
      };

      # Test 86: Disaster Recovery - Framework Information
      testDisasterRecoveryFrameworkInfo = {
        name = "disaster recovery framework information";
        test =
          let
            framework = disasterRecovery.framework;
          in
            # Should provide framework metadata
            (framework.name == "Nixernetes Disaster Recovery") &&
            (framework.version == "1.0.0") &&
            (framework.features ? "backup-policies") &&
            (framework.features ? "restore-strategies") &&
            (framework.features ? "failover-policies") &&
            (framework.features ? "rpo-rto-tracking") &&
            (framework.features ? "dr-planning") &&
            (framework.features ? "data-replication") &&
            (framework.features ? "chaos-testing") &&
            (framework.features ? "recovery-runbooks") &&
            (builtins.elem "velero" framework.supportedBackupSystems) &&
            (builtins.elem "s3" framework.supportedStorageBackends);
        expected = true;
      };

      # Test 87: Multi-Tenancy - Tenant Creation
      testMultiTenancyTenantCreation = {
        name = "multi-tenancy tenant creation";
        test =
          let
            tenant = multiTenancy.mkTenant "acme-corp" {
              namespace = "acme-corp";
              displayName = "ACME Corporation";
              description = "Main production tenant";
              cpuQuota = "200";
              memoryQuota = "512Gi";
              storageQuota = "2Ti";
              podQuota = 1000;
              isolationLevel = "standard";
              networkIsolation = true;
              ingressEnabled = true;
              owner = "admin@acme.com";
              admins = ["admin1@acme.com" "admin2@acme.com"];
              billingContact = "billing@acme.com";
              costCenter = "ACME-001";
            };
          in
            # Should create valid tenant
            (tenant.name == "acme-corp") &&
            (tenant.namespace == "acme-corp") &&
            (tenant.displayName == "ACME Corporation") &&
            (tenant.cpuQuota == "200") &&
            (tenant.memoryQuota == "512Gi") &&
            (tenant.isolationLevel == "standard") &&
            (tenant.networkIsolation == true) &&
            (tenant.labels ? "nixernetes.io/tenant");
        expected = true;
      };

      # Test 88: Multi-Tenancy - Namespace Quota
      testMultiTenancyNamespaceQuota = {
        name = "multi-tenancy namespace quota";
        test =
          let
            quota = multiTenancy.mkNamespaceQuota "acme-prod" {
              namespace = "acme-prod";
              cpuQuota = "200";
              memoryQuota = "512Gi";
              storageQuota = "2Ti";
              podQuota = 500;
              deploymentQuota = 100;
              statefulsetQuota = 20;
              pvQuota = 100;
              serviceQuota = 100;
            };
          in
            # Should create valid quota
            (quota.name == "acme-prod") &&
            (quota.namespace == "acme-prod") &&
            (quota.cpuQuota == "200") &&
            (quota.memoryQuota == "512Gi") &&
            (quota.podQuota == 500) &&
            (quota.deploymentQuota == 100) &&
            (quota.statefulsetQuota == 20);
        expected = true;
      };

      # Test 89: Multi-Tenancy - Network Policy
      testMultiTenancyNetworkPolicy = {
        name = "multi-tenancy network policy";
        test =
          let
            policy = multiTenancy.mkTenantNetworkPolicy "acme" {
              namespace = "acme";
              ingressEnabled = true;
              allowFromSameTenant = true;
              allowFromNamespaces = ["ingress-nginx"];
              egressEnabled = true;
              allowToSameTenant = true;
              allowToDns = true;
              allowToExternal = false;
              allowedPorts = [80 443];
            };
          in
            # Should create valid network policy
            (policy.name == "tenant-acme") &&
            (policy.namespace == "acme") &&
            (policy.ingressEnabled == true) &&
            (policy.egressEnabled == true) &&
            (policy.allowToDns == true) &&
            (builtins.length policy.allowedPorts == 2);
        expected = true;
      };

      # Test 90: Multi-Tenancy - RBAC Configuration
      testMultiTenancyRBAC = {
        name = "multi-tenancy rbac configuration";
        test =
          let
            rbac = multiTenancy.mkTenantRBAC "acme" {
              namespace = "acme";
              admins = ["admin@acme.com"];
              developers = ["dev1@acme.com" "dev2@acme.com"];
              viewers = ["viewer@acme.com"];
              serviceAccounts = ["ci-cd" "monitoring"];
            };
          in
            # Should create valid RBAC
            (rbac.name == "acme") &&
            (rbac.namespace == "acme") &&
            (rbac.roles ? "admin") &&
            (rbac.roles ? "developer") &&
            (rbac.roles ? "viewer") &&
            (builtins.length rbac.admins == 1) &&
            (builtins.length rbac.developers == 2) &&
            (builtins.length rbac.serviceAccounts == 2);
        expected = true;
      };

      # Test 91: Multi-Tenancy - Resource Limits
      testMultiTenancyResourceLimits = {
        name = "multi-tenancy resource limits";
        test =
          let
            limits = multiTenancy.mkTenantResourceLimits "acme" {
              namespace = "acme";
              podCpuLimit = "10";
              podMemoryLimit = "32Gi";
              podCpuRequest = "100m";
              podMemoryRequest = "128Mi";
              containerCpuLimit = "8";
              containerMemoryLimit = "16Gi";
              qosClass = "Burstable";
              allowBursting = true;
              minReplicas = 2;
            };
          in
            # Should create valid resource limits
            (limits.name == "acme") &&
            (limits.namespace == "acme") &&
            (limits.podCpuLimit == "10") &&
            (limits.podMemoryLimit == "32Gi") &&
            (limits.containerCpuLimit == "8") &&
            (limits.qosClass == "Burstable") &&
            (limits.allowBursting == true) &&
            (limits.minReplicas == 2);
        expected = true;
      };

      # Test 92: Multi-Tenancy - Billing Configuration
      testMultiTenancyBilling = {
        name = "multi-tenancy billing configuration";
        test =
          let
            billing = multiTenancy.mkTenantBilling "acme" {
              tenantId = "acme-001";
              tenantName = "ACME Corporation";
              billingContact = "billing@acme.com";
              costCenter = "ACME-001";
              billingCycle = "monthly";
              cpuHourlyRate = 0.05;
              memoryHourlyRate = 0.01;
              storageMonthlyRate = 0.10;
              networkEgressRate = 0.02;
              monthlyBudget = 5000;
              budgetAlertThreshold = 0.80;
              budgetEnforcement = true;
            };
          in
            # Should create valid billing
            (billing.tenantId == "acme-001") &&
            (billing.tenantName == "ACME Corporation") &&
            (billing.billingCycle == "monthly") &&
            (billing.cpuHourlyRate == 0.05) &&
            (billing.monthlyBudget == 5000) &&
            (billing.budgetAlertThreshold == 0.80) &&
            (billing.budgetEnforcement == true);
        expected = true;
      };

      # Test 93: Multi-Tenancy - Isolation Policy
      testMultiTenancyIsolationPolicy = {
        name = "multi-tenancy isolation policy";
        test =
          let
            policy = multiTenancy.mkTenantIsolationPolicy "acme" {
              namespace = "acme";
              isolationLevel = "strict";
              networkIsolation = true;
              storageIsolation = true;
              podSecurityPolicy = "restricted";
              secretsEncryption = true;
              encryptionAtRest = true;
              apiAudit = true;
              auditLevel = "Metadata";
              allowedRegistries = ["gcr.io" "docker.io"];
              imageVerification = true;
            };
          in
            # Should create valid isolation policy
            (policy.isolationLevel == "strict") &&
            (policy.networkIsolation == true) &&
            (policy.storageIsolation == true) &&
            (policy.podSecurityPolicy == "restricted") &&
            (policy.secretsEncryption == true) &&
            (policy.encryptionAtRest == true) &&
            (policy.apiAudit == true) &&
            (builtins.length policy.allowedRegistries == 2) &&
            (policy.imageVerification == true);
        expected = true;
      };

      # Test 94: Multi-Tenancy - Framework Information
      testMultiTenancyFrameworkInfo = {
        name = "multi-tenancy framework information";
        test =
          let
            framework = multiTenancy.framework;
          in
            # Should provide framework metadata
            (framework.name == "Nixernetes Multi-Tenancy") &&
            (framework.version == "1.0.0") &&
            (framework.features ? "tenant-management") &&
            (framework.features ? "namespace-quotas") &&
            (framework.features ? "network-policies") &&
            (framework.features ? "rbac") &&
            (framework.features ? "resource-limits") &&
            (framework.features ? "billing") &&
            (framework.features ? "isolation-policies") &&
            (framework.features ? "monitoring") &&
            (framework.features ? "backup-restore") &&
            (framework.features ? "audit") &&
            (builtins.elem "strict" framework.supportedIsolationLevels) &&
            (builtins.elem "monthly" framework.supportedBillingCycles);
        expected = true;
      };

      # Test 95: Service Mesh - Istio Configuration
      testServiceMeshIstio = {
        name = "service mesh istio configuration";
        test =
          let
            mesh = serviceMesh.mkIstioMesh "production" {
              namespace = "istio-system";
              version = "1.17.0";
              installMode = "demo";
              enableIngressGateway = true;
              enableEgressGateway = true;
              enableMtls = true;
              mtlsMode = "STRICT";
              enableAuthorizationPolicy = true;
              enableTracing = true;
              tracingProvider = "jaeger";
              enableKiali = true;
            };
          in
            # Should create valid Istio mesh
            (mesh.name == "production") &&
            (mesh.namespace == "istio-system") &&
            (mesh.version == "1.17.0") &&
            (mesh.installMode == "demo") &&
            (mesh.enableIngressGateway == true) &&
            (mesh.enableEgressGateway == true) &&
            (mesh.mtlsMode == "STRICT") &&
            (mesh.enableAuthorizationPolicy == true) &&
            (mesh.enableKiali == true);
        expected = true;
      };

      # Test 96: Service Mesh - Linkerd Configuration
      testServiceMeshLinkerd = {
        name = "service mesh linkerd configuration";
        test =
          let
            mesh = serviceMesh.mkLinkerdMesh "production" {
              namespace = "linkerd";
              version = "2.14.0";
              installMode = "stable";
              enableControlPlane = true;
              enableDataPlane = true;
              enableViz = true;
              enableMtls = true;
              mtlsRotationDays = 365;
              enableHA = true;
              replicas = 3;
              enableAutoInject = true;
            };
          in
            # Should create valid Linkerd mesh
            (mesh.name == "production") &&
            (mesh.namespace == "linkerd") &&
            (mesh.version == "2.14.0") &&
            (mesh.installMode == "stable") &&
            (mesh.enableControlPlane == true) &&
            (mesh.enableDataPlane == true) &&
            (mesh.enableViz == true) &&
            (mesh.enableMtls == true) &&
            (mesh.enableHA == true) &&
            (mesh.replicas == 3);
        expected = true;
      };

      # Test 97: Service Mesh - Virtual Service
      testServiceMeshVirtualService = {
        name = "service mesh virtual service";
        test =
          let
            vs = serviceMesh.mkVirtualService "web-service" {
              namespace = "production";
              hosts = ["web" "web.svc.cluster.local"];
              timeout = "30s";
              httpRoutes = [];
            };
          in
            # Should create valid virtual service
            (vs.name == "web-service") &&
            (vs.namespace == "production") &&
            (builtins.length vs.hosts == 2) &&
            (vs.timeout == "30s");
        expected = true;
      };

      # Test 98: Service Mesh - Destination Rule
      testServiceMeshDestinationRule = {
        name = "service mesh destination rule";
        test =
          let
            dr = serviceMesh.mkDestinationRule "web-service" {
              namespace = "production";
              host = "web-service";
              
              subsets = [
                { name = "v1"; labels = { version = "v1"; }; }
                { name = "v2"; labels = { version = "v2"; }; }
              ];
            };
          in
            # Should create valid destination rule
            (dr.name == "web-service") &&
            (dr.namespace == "production") &&
            (dr.host == "web-service") &&
            (builtins.length dr.subsets == 2);
        expected = true;
      };

      # Test 99: Service Mesh - Traffic Policy
      testServiceMeshTrafficPolicy = {
        name = "service mesh traffic policy";
        test =
          let
            policy = serviceMesh.mkTrafficPolicy "resilient" {
              circuitBreaker = {
                enabled = true;
                consecutiveErrors = 5;
                interval = "30s";
              };
              retries = {
                enabled = true;
                attempts = 3;
                perTryTimeout = "10s";
              };
              timeout = "30s";
              loadBalancer = "ROUND_ROBIN";
            };
          in
            # Should create valid traffic policy
            (policy.name == "resilient") &&
            (policy.circuitBreaker.enabled == true) &&
            (policy.circuitBreaker.consecutiveErrors == 5) &&
            (policy.retries.enabled == true) &&
            (policy.retries.attempts == 3) &&
            (policy.timeout == "30s") &&
            (policy.loadBalancer == "ROUND_ROBIN");
        expected = true;
      };

      # Test 100: Service Mesh - Authorization Policy
      testServiceMeshAuthorizationPolicy = {
        name = "service mesh authorization policy";
        test =
          let
            policy = serviceMesh.mkAuthorizationPolicy "allow-traffic" {
              namespace = "production";
              action = "ALLOW";
              selector = { "app" = "web"; };
              rules = [];
            };
          in
            # Should create valid authorization policy
            (policy.name == "allow-traffic") &&
            (policy.namespace == "production") &&
            (policy.action == "ALLOW") &&
            (policy.selector ? "app");
        expected = true;
      };

      # Test 101: Service Mesh - Observability Config
      testServiceMeshObservabilityConfig = {
        name = "service mesh observability configuration";
        test =
          let
            obs = serviceMesh.mkObservabilityConfig "production" {
              metricsEnabled = true;
              metricsPort = 15000;
              tracingEnabled = true;
              tracingProvider = "jaeger";
              tracingSamplingRate = 0.05;
              accessLogEnabled = true;
              dashboardEnabled = true;
              dashboardProvider = "kiali";
            };
          in
            # Should create valid observability config
            (obs.name == "production") &&
            (obs.metricsEnabled == true) &&
            (obs.metricsPort == 15000) &&
            (obs.tracingEnabled == true) &&
            (obs.tracingProvider == "jaeger") &&
            (obs.tracingSamplingRate == 0.05) &&
            (obs.accessLogEnabled == true) &&
            (obs.dashboardEnabled == true) &&
            (obs.dashboardProvider == "kiali");
        expected = true;
      };

      # Test 102: Service Mesh - Framework Information
      testServiceMeshFrameworkInfo = {
        name = "service mesh framework information";
        test =
          let
            framework = serviceMesh.framework;
          in
            # Should provide framework metadata
            (framework.name == "Nixernetes Service Mesh Integration") &&
            (framework.version == "1.0.0") &&
            (framework.features ? "istio-support") &&
            (framework.features ? "linkerd-support") &&
            (framework.features ? "virtual-services") &&
            (framework.features ? "destination-rules") &&
            (framework.features ? "traffic-policies") &&
            (framework.features ? "authorization-policies") &&
            (framework.features ? "observability") &&
            (builtins.elem "istio" framework.supportedMeshes) &&
            (builtins.elem "linkerd" framework.supportedMeshes) &&
            (builtins.elem "jaeger" framework.supportedTracingProviders);
        expected = true;
      };

      # Test 103: API Gateway - Traefik Configuration
      testApiGatewayTraefik = {
        name = "api gateway traefik configuration";
        test =
          let
            gateway = apiGateway.mkTraefik "production" {
              namespace = "ingress";
              replicas = 3;
              version = "2.10";
              tls = {
                enabled = true;
                certResolver = "letsencrypt";
              };
            };
          in
            # Should create valid Traefik config
            (gateway.baseName == "production") &&
            (gateway.framework == "traefik") &&
            (gateway.version == "2.10") &&
            (gateway.namespace == "ingress") &&
            (gateway.replicas == 3) &&
            (gateway.api.enabled == true) &&
            (gateway.api.dashboard == true) &&
            (gateway.tls.enabled == true) &&
            (gateway.tls.certResolver == "letsencrypt") &&
            (gateway.labels.framework == "traefik");
        expected = true;
      };

      # Test 104: API Gateway - Kong Configuration
      testApiGatewayKong = {
        name = "api gateway kong configuration";
        test =
          let
            gateway = apiGateway.mkKong "enterprise" {
              namespace = "kong-prod";
              replicas = 5;
              version = "3.4";
              database = {
                host = "kong-db.postgres.svc";
                port = 5432;
                name = "kong-enterprise";
              };
              authentication = {
                oauth2Enabled = true;
              };
              rateLimiting = {
                enabled = true;
                defaultLimit = 1000;
              };
            };
          in
            # Should create valid Kong config
            (gateway.baseName == "enterprise") &&
            (gateway.framework == "kong") &&
            (gateway.version == "3.4") &&
            (gateway.namespace == "kong-prod") &&
            (gateway.replicas == 5) &&
            (gateway.database.host == "kong-db.postgres.svc") &&
            (gateway.database.port == 5432) &&
            (gateway.database.name == "kong-enterprise") &&
            (gateway.admin.enabled == true) &&
            (gateway.authentication.oauth2Enabled == true) &&
            (gateway.rateLimiting.enabled == true) &&
            (gateway.rateLimiting.defaultLimit == 1000);
        expected = true;
      };

      # Test 105: API Gateway - Contour Configuration
      testApiGatewayContour = {
        name = "api gateway contour configuration";
        test =
          let
            gateway = apiGateway.mkContour "edge" {
              namespace = "projectcontour";
              replicas = 2;
              version = "1.28";
              envoy = {
                replicas = 3;
              };
              loadBalancing = {
                strategy = "LeastRequest";
              };
            };
          in
            # Should create valid Contour config
            (gateway.baseName == "edge") &&
            (gateway.framework == "contour") &&
            (gateway.version == "1.28") &&
            (gateway.namespace == "projectcontour") &&
            (gateway.replicas == 2) &&
            (gateway.envoy.replicas == 3) &&
            (gateway.tls.enabled == true) &&
            (gateway.tls.minimumProtocolVersion == "1.2") &&
            (gateway.loadBalancing.strategy == "LeastRequest") &&
            (gateway.metrics.enabled == true);
        expected = true;
      };

      # Test 106: API Gateway - NGINX Configuration
      testApiGatewayNginx = {
        name = "api gateway nginx configuration";
        test =
          let
            gateway = apiGateway.mkNginx "secure" {
              namespace = "ingress-nginx";
              replicas = 3;
              version = "1.9";
              modsecurity = {
                enabled = true;
                securityRulesSet = "owasp";
              };
              https = {
                enabled = true;
              };
            };
          in
            # Should create valid NGINX config
            (gateway.baseName == "secure") &&
            (gateway.framework == "nginx") &&
            (gateway.version == "1.9") &&
            (gateway.namespace == "ingress-nginx") &&
            (gateway.replicas == 3) &&
            (gateway.ingressClass.name == "nginx") &&
            (gateway.ingressClass.isDefault == true) &&
            (gateway.modsecurity.enabled == true) &&
            (gateway.modsecurity.securityRulesSet == "owasp") &&
            (gateway.https.enabled == true) &&
            (gateway.rateLimiting.enabled == true);
        expected = true;
      };

      # Test 107: API Gateway - Rate Limiting Policy
      testApiGatewayRateLimiting = {
        name = "api gateway rate limiting policy";
        test =
          let
            policy = apiGateway.mkRateLimitPolicy "api-limit" {
              limits = {
                requests = 100;
                window = "1m";
                burst = 20;
              };
              keyExtractor = {
                type = "clientIP";
              };
            };
          in
            # Should create valid rate limit policy
            (policy.baseName == "api-limit") &&
            (policy.policyType == "rateLimit") &&
            (policy.limits.requests == 100) &&
            (policy.limits.window == "1m") &&
            (policy.limits.burst == 20) &&
            (policy.keyExtractor.type == "clientIP") &&
            (policy.actions.type == "reject") &&
            (policy.actions.statusCode == 429);
        expected = true;
      };

      # Test 108: API Gateway - Circuit Breaker Policy
      testApiGatewayCircuitBreaker = {
        name = "api gateway circuit breaker policy";
        test =
          let
            policy = apiGateway.mkCircuitBreaker "fault-tolerance" {
              consecutiveErrors = 5;
              errorPercentageThreshold = 50;
              detectionWindow = "30s";
              recoveryTimeout = "60s";
            };
          in
            # Should create valid circuit breaker policy
            (policy.baseName == "fault-tolerance") &&
            (policy.policyType == "circuitBreaker") &&
            (policy.consecutiveErrors == 5) &&
            (policy.errorPercentageThreshold == 50) &&
            (policy.detectionWindow == "30s") &&
            (policy.recoveryTimeout == "60s") &&
            (policy.actions.type == "reject") &&
            (policy.actions.statusCode == 503);
        expected = true;
      };

      # Test 109: API Gateway - Authentication Policy
      testApiGatewayAuthentication = {
        name = "api gateway authentication policy";
        test =
          let
            policy = apiGateway.mkAuthPolicy "oauth-auth" {
              methods = {
                oauth2 = true;
                jwt = false;
              };
              oauth2 = {
                enabled = true;
                clientId = "client-id";
                clientSecret = "client-secret";
                discoveryUrl = "https://auth.example.com/.well-known";
              };
            };
          in
            # Should create valid auth policy
            (policy.baseName == "oauth-auth") &&
            (policy.policyType == "authentication") &&
            (policy.methods.oauth2 == true) &&
            (policy.methods.jwt == false) &&
            (policy.oauth2.enabled == true) &&
            (policy.oauth2.clientId == "client-id") &&
            (policy.oauth2.clientSecret == "client-secret");
        expected = true;
      };

      # Test 110: API Gateway - Framework Information
      testApiGatewayFrameworkInfo = {
        name = "api gateway framework information";
        test =
          let
            framework = apiGateway.framework;
          in
            # Should provide framework metadata
            (framework.name == "api-gateway") &&
            (framework.version == "1.0.0") &&
            (framework.features ? "traefik") &&
            (framework.features ? "kong") &&
            (framework.features ? "contour") &&
            (framework.features ? "nginx") &&
            (framework.features ? "gateway") &&
            (framework.features ? "rateLimiting") &&
            (framework.features ? "circuitBreaker") &&
            (framework.features ? "loadBalancing") &&
            (framework.features ? "authentication") &&
            (builtins.elem "1.26" framework.supportedK8sVersions) &&
            (builtins.elem "1.31" framework.supportedK8sVersions) &&
            (framework.maturity == "stable");
        expected = true;
      };

      # Test 111: Container Registry - Docker Registry Configuration
      testContainerRegistryDocker = {
        name = "container registry docker configuration";
        test =
          let
            registry = containerRegistry.mkDockerRegistry "local" {
              namespace = "registry";
              replicas = 2;
              storage.driver = "s3";
              storage.s3 = {
                enabled = true;
                bucket = "my-registry";
              };
            };
          in
            # Should create valid Docker Registry config
            (registry.baseName == "local") &&
            (registry.framework == "docker-registry") &&
            (registry.version == "2.8") &&
            (registry.namespace == "registry") &&
            (registry.replicas == 2) &&
            (registry.storage.driver == "s3") &&
            (registry.storage.s3.enabled == true) &&
            (registry.storage.s3.bucket == "my-registry") &&
            (registry.http.addr == ":5000") &&
            (registry.auth.enabled == true) &&
            (registry.labels.framework == "docker-registry");
        expected = true;
      };

      # Test 112: Container Registry - Harbor Configuration
      testContainerRegistryHarbor = {
        name = "container registry harbor configuration";
        test =
          let
            registry = containerRegistry.mkHarborRegistry "production" {
              namespace = "harbor";
              coreReplicas = 3;
              registryReplicas = 3;
              database = {
                host = "postgres.harbor.svc";
                port = 5432;
              };
              trivy.enabled = true;
            };
          in
            # Should create valid Harbor config
            (registry.baseName == "production") &&
            (registry.framework == "harbor") &&
            (registry.version == "2.10") &&
            (registry.namespace == "harbor") &&
            (registry.coreReplicas == 3) &&
            (registry.registryReplicas == 3) &&
            (registry.database.host == "postgres.harbor.svc") &&
            (registry.database.port == 5432) &&
            (registry.database.type == "postgresql") &&
            (registry.trivy.enabled == true) &&
            (registry.replication.enabled == true) &&
            (registry.garbageCollection.enabled == true);
        expected = true;
      };

      # Test 113: Container Registry - Nexus Configuration
      testContainerRegistryNexus = {
        name = "container registry nexus configuration";
        test =
          let
            registry = containerRegistry.mkNexusRegistry "enterprise" {
              namespace = "nexus";
              replicas = 2;
              jvm = {
                maxMemory = "2048m";
                minMemory = "512m";
              };
            };
          in
            # Should create valid Nexus config
            (registry.baseName == "enterprise") &&
            (registry.framework == "nexus") &&
            (registry.version == "3.68") &&
            (registry.namespace == "nexus") &&
            (registry.replicas == 2) &&
            (registry.repositories.docker.hosted == true) &&
            (registry.repositories.maven.proxy == true) &&
            (registry.repositories.npm.group == true) &&
            (registry.jvm.maxMemory == "2048m") &&
            (registry.jvm.minMemory == "512m");
        expected = true;
      };

      # Test 114: Container Registry - Artifactory Configuration
      testContainerRegistryArtifactory = {
        name = "container registry artifactory configuration";
        test =
          let
            registry = containerRegistry.mkArtifactoryRegistry "enterprise" {
              namespace = "artifactory";
              replicas = 2;
              database.type = "postgresql";
            };
          in
            # Should create valid Artifactory config
            (registry.baseName == "enterprise") &&
            (registry.framework == "artifactory") &&
            (registry.version == "7.84") &&
            (registry.namespace == "artifactory") &&
            (registry.replicas == 2) &&
            (registry.database.type == "postgresql") &&
            (registry.repositories.docker.local == true) &&
            (registry.repositories.maven.remote == true) &&
            (registry.authentication.enabled == true) &&
            (registry.security.ssl.enabled == true) &&
            (registry.security.encryption.enabled == true);
        expected = true;
      };

      # Test 115: Container Registry - Image Scanning Policy
      testContainerRegistryImageScan = {
        name = "container registry image scanning policy";
        test =
          let
            policy = containerRegistry.mkImageScanPolicy "vulnerability-scan" {
              scanning = {
                enabled = true;
                scanner = "trivy";
                onPull = true;
                onPush = true;
              };
              vulnerabilities.critical.action = "block";
            };
          in
            # Should create valid scanning policy
            (policy.baseName == "vulnerability-scan") &&
            (policy.policyType == "image-scan") &&
            (policy.scanning.enabled == true) &&
            (policy.scanning.scanner == "trivy") &&
            (policy.scanning.onPull == true) &&
            (policy.scanning.onPush == true) &&
            (policy.vulnerabilities.critical.action == "block") &&
            (policy.vulnerabilities.high.action == "warn") &&
            (policy.vulnerabilities.medium.action == "allow");
        expected = true;
      };

      # Test 116: Container Registry - Image Retention Policy
      testContainerRegistryRetention = {
        name = "container registry image retention policy";
        test =
          let
            policy = containerRegistry.mkImageRetentionPolicy "cleanup" {
              retentionDays = 30;
              keepTagged = true;
              keepLatest = true;
              schedule = "0 2 * * *";
            };
          in
            # Should create valid retention policy
            (policy.baseName == "cleanup") &&
            (policy.policyType == "image-retention") &&
            (policy.retentionDays == 30) &&
            (policy.keepTagged == true) &&
            (policy.keepLatest == true) &&
            (policy.schedule == "0 2 * * *");
        expected = true;
      };

      # Test 117: Container Registry - Image Replication Policy
      testContainerRegistryReplication = {
        name = "container registry image replication policy";
        test =
          let
            policy = containerRegistry.mkImageReplicationPolicy "to-dr" {
              source = {
                registry = "docker.io";
                namespace = "my-company";
              };
              destination = {
                registry = "dr-registry.example.com";
              };
              enabled = true;
            };
          in
            # Should create valid replication policy
            (policy.baseName == "to-dr") &&
            (policy.policyType == "image-replication") &&
            (policy.source.registry == "docker.io") &&
            (policy.source.namespace == "my-company") &&
            (policy.destination.registry == "dr-registry.example.com") &&
            (policy.rules.pullImage == true) &&
            (policy.enabled == true);
        expected = true;
      };

      # Test 118: Container Registry - Framework Information
      testContainerRegistryFrameworkInfo = {
        name = "container registry framework information";
        test =
          let
            framework = containerRegistry.framework;
          in
            # Should provide framework metadata
            (framework.name == "container-registry") &&
            (framework.version == "1.0.0") &&
            (framework.features ? "dockerRegistry") &&
            (framework.features ? "harbor") &&
            (framework.features ? "nexus") &&
            (framework.features ? "artifactory") &&
            (framework.features ? "imageScanning") &&
            (framework.features ? "imageRetention") &&
            (framework.features ? "imageReplication") &&
            (builtins.elem "docker" framework.supportedRegistries) &&
            (builtins.elem "harbor" framework.supportedRegistries) &&
            (builtins.elem "nexus" framework.supportedRegistries) &&
            (builtins.elem "1.26" framework.supportedK8sVersions) &&
            (builtins.elem "1.31" framework.supportedK8sVersions) &&
            (framework.maturity == "stable");
        expected = true;
      };

}

