{
  description = "Enterprise Nix-driven Kubernetes Manifest, Policy, and Network Generator";

  # Standard Nix Flake inputs
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      lib = pkgs.lib;

      # --- AUTOMATED API SPECIFICATION LAYER ---
      
      # Logic to fetch official Kubernetes OpenAPI/Swagger specs.
      # This allows the framework to be "aware" of specific version constraints.
      fetchK8sSpec = version: sha256: pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/kubernetes/kubernetes/v${version}/api/openapi-spec/swagger.json";
        inherit sha256;
      };

      # API Version Resolver: This simulates a dynamic lookup based on the fetched specs.
      # It ensures that as you target newer K8s versions, the generated manifests 
      # automatically shift to the preferred stable API groups.
      getApiMap = k8sVersion: 
        let
          matrix = {
            "1.31" = {
              deployment = "apps/v1";
              ingress = "networking.k8s.io/v1";
              networkPolicy = "networking.k8s.io/v1";
              kyverno = "kyverno.io/v1";
            };
            "1.25" = {
              deployment = "apps/v1";
              ingress = "networking.k8s.io/v1"; # Transitioned from beta in 1.22
              networkPolicy = "networking.k8s.io/v1";
              kyverno = "kyverno.io/v1";
            };
          };
        in matrix.${k8sVersion} or (throw "Unsupported Kubernetes version: ${k8sVersion}");

      # --- ENTERPRISE MODULE DEFINITION ---

      appModule = { k8sVersion, globalCompliance }: { config, lib, ... }: {
        options = {
          name = lib.mkOption { type = lib.types.str; description = "Application identity"; };
          namespace = lib.mkOption { type = lib.types.str; default = config.name; };
          
          compliance = {
            framework = lib.mkOption { 
              type = lib.types.enum [ "SOC2" "GDPR" "HIPAA" "Internal" "PCI-DSS" ]; 
              default = globalCompliance.framework;
            };
            level = lib.mkOption { 
              type = lib.types.enum [ "standard" "high" "restricted" ];
              default = globalCompliance.level;
            };
          };

          network = {
            ingressAllowedFrom = lib.mkOption {
              type = lib.types.listOf lib.types.attrs;
              default = [];
              description = "Zero-trust ingress whitelist";
            };
            egressRules = lib.mkOption {
              type = lib.types.listOf lib.types.attrs;
              default = [];
              description = "Controlled egress for regulatory compliance";
            };
          };

          workload = {
            image = lib.mkOption { type = lib.types.str; };
            replicas = lib.mkOption { type = lib.types.int; default = 2; };
            port = lib.mkOption { type = lib.types.int; default = 8080; };
            resources = lib.mkOption {
              type = lib.types.attrs;
              default = {
                limits = { cpu = "500m"; memory = "512Mi"; };
                requests = { cpu = "100m"; memory = "128Mi"; };
              };
            };
          };

          generatedObjects = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            internal = true;
          };
        };

        config.generatedObjects = let
          api = getApiMap k8sVersion;
          commonLabels = {
            "app.kubernetes.io/name" = config.name;
            "enterprise.com/framework" = config.compliance.framework;
            "enterprise.com/compliance-level" = config.compliance.level;
            "enterprise.com/managed-by" = "nix-k8s-framework";
          };
        in [
          # 1. Primary Deployment with Enterprise Hardening
          {
            apiVersion = api.deployment;
            kind = "Deployment";
            metadata = { inherit (config) name namespace; labels = commonLabels; };
            spec = {
              replicas = config.workload.replicas;
              selector.matchLabels = { app = config.name; };
              template = {
                metadata.labels = commonLabels // { app = config.name; };
                spec = {
                  securityContext = {
                    runAsNonRoot = true;
                    runAsUser = 1000;
                  };
                  containers = [{
                    name = "app-container";
                    image = config.workload.image;
                    inherit (config.workload) resources;
                    ports = [{ containerPort = config.workload.port; }];
                  }];
                };
              };
            };
          }

          # 2. NetworkPolicy: Default Deny + Whitelisted Ingress/Egress
          {
            apiVersion = api.networkPolicy;
            kind = "NetworkPolicy";
            metadata = { name = "${config.name}-firewall"; inherit (config) namespace; labels = commonLabels; };
            spec = {
              podSelector = { matchLabels = { app = config.name; }; };
              policyTypes = [ "Ingress" "Egress" ];
              ingress = [{
                from = config.network.ingressAllowedFrom;
                ports = [{ protocol = "TCP"; port = config.workload.port; }];
              }];
              egress = config.network.egressRules;
            };
          }

          # 3. Kyverno Rule: Real-time compliance enforcement
          {
            apiVersion = api.kyverno;
            kind = "Policy";
            metadata = { name = "enforce-governance-${config.name}"; inherit (config) namespace; };
            spec = {
              validationFailureAction = "Enforce";
              rules = [{
                name = "require-regulatory-metadata";
                match = { any = [{ resources = { kinds = ["Pod"]; }; }]; };
                validate = {
                  message = "Deployment failed: Pods must include enterprise compliance labels.";
                  pattern = {
                    metadata = {
                      labels = {
                        "enterprise.com/framework" = "?*";
                        "enterprise.com/compliance-level" = "?*";
                      };
                    };
                  };
                };
              }];
            };
          }
        ];
      };

      # --- COMPILER FUNCTIONS ---

      mkAppManifests = args: 
        let
          eval = lib.evalModules {
            modules = [
              (appModule { k8sVersion = args.k8sVersion; globalCompliance = args.globalCompliance; })
              { inherit (args) name workload network; }
            ];
          };
          json = builtins.toJSON eval.config.generatedObjects;
        in pkgs.runCommand "k8s-build-${args.name}" { buildInputs = [ pkgs.yq-go ]; } ''
          mkdir -p $out/manifests
          mkdir -p $out/helm/templates

          # Generate multi-doc YAML for direct kubectl usage
          echo '${json}' | yq -P ' .[] | split_doc' > $out/manifests/all-resources.yaml
          
          # Generate individual templates for Helm structure
          echo '${json}' | yq -c '.[]' | while read -r obj; do
            kind=$(echo "$obj" | yq -r '.kind' | tr '[:upper:]' '[:lower:]')
            echo "$obj" | yq -P > "$out/helm/templates/$kind-${args.name}.yaml"
          done

          cat <<EOF > $out/helm/Chart.yaml
          apiVersion: v2
          name: ${args.name}
          version: 1.0.0
          description: Nix-generated enterprise chart targeting K8s ${args.k8sVersion}
          EOF
        '';

    in {
      # PACKAGE EXAMPLES
      packages.${system} = {
        # Targeting 1.31 for a secure payment API
        payment-gateway = mkAppManifests {
          name = "pay-api";
          k8sVersion = "1.31";
          globalCompliance = { framework = "PCI-DSS"; level = "restricted"; };
          workload = { 
            image = "corp/payments:v4.2"; 
            port = 443; 
            replicas = 3;
          };
          network = {
            ingressAllowedFrom = [ { podSelector = { matchLabels = { role = "ingress-controller"; }; }; } ];
          };
        };
      };
    };
}
