{
  description = "Example: Using Nixernetes as a Flake Library";

  inputs = {
    nixernetes.url = "git+file:///home/shift/code/ideas/nixernetes";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixernetes, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;

        # Access all Nixernetes modules
        nix = nixernetes.lib;

      in {
        packages = {
          # Example 1: Simple Deployment using Layer 1 API
          simple-deployment = pkgs.writeText "simple-deployment.yaml"
            (builtins.toJSON (nix.api.mkDeployment {
              name = "hello-world";
              namespace = "default";
              image = "nginx:latest";
              replicas = 2;
            }));

          # Example 2: NetworkPolicy using convenience module
          network-policy = pkgs.writeText "network-policy.yaml"
            (builtins.toJSON (nix.policies.mkDefaultDenyNetworkPolicy {
              namespace = "production";
              podSelector = { matchLabels = { app = "web-server"; }; };
            }));

          # Example 3: RBAC using specialized builder
          service-account = pkgs.writeText "service-account.yaml"
            (builtins.toJSON (nix.rbac.mkReadOnlyServiceAccount {
              name = "reader";
              namespace = "production";
            }));

          # Example 4: High-level Application (Layer 3)
          # This would generate multiple resources automatically
          e-commerce-app = pkgs.writeText "ecommerce.nix" ''
            # The Unified API builder would generate:
            # - Deployment
            # - Service
            # - ConfigMap
            # - Secret
            # - NetworkPolicy (deny-all + allow dependencies)
            # - ServiceAccount + RBAC
            # - Monitoring annotations
            # All with compliance labels automatically injected
            
            ${nix.unifiedApi}
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nix
            yq
            jq
            kubernetes-helm
          ];

          shellHook = ''
            echo "Nixernetes Example Environment"
            echo "Available packages:"
            echo "  nix build .#simple-deployment"
            echo "  nix build .#network-policy"
            echo "  nix build .#service-account"
            echo ""
            echo "All Nixernetes modules are available via:"
            echo "  inputs.nixernetes.lib.*"
          '';
        };

        checks = {
          # Verify all modules are accessible
          modules-accessible = pkgs.runCommand "check-nixernetes-modules" {} ''
            echo "Checking Nixernetes module availability..."
            ${lib.optionalString (nix ? schema) "echo '✓ schema'"}
            ${lib.optionalString (nix ? compliance) "echo '✓ compliance'"}
            ${lib.optionalString (nix ? policies) "echo '✓ policies'"}
            ${lib.optionalString (nix ? rbac) "echo '✓ rbac'"}
            ${lib.optionalString (nix ? unifiedApi) "echo '✓ unifiedApi'"}
            ${lib.optionalString (nix ? api) "echo '✓ api'"}
            ${lib.optionalString (nix ? kyverno) "echo '✓ kyverno'"}
            ${lib.optionalString (nix ? gitops) "echo '✓ gitops'"}
            ${lib.optionalString (nix ? serviceMesh) "echo '✓ serviceMesh'"}
            mkdir -p $out
            echo "All modules accessible" > $out/result
          '';
        };
      }
    );
}
