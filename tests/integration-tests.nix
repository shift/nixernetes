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
        (builtins.any (rec: rec.type == "cpu_oversizing") recommendations) &&
        # Should detect missing limits
        (builtins.any (rec: rec.type == "missing_limit") recommendations);
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
}

