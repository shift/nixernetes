{
  description = "Nixernetes: Enterprise Nix-driven Kubernetes Manifest Framework";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;

        # Import our custom library modules
        nixernetes = {
          schema = import ./src/lib/schema.nix { inherit lib; };
          compliance = import ./src/lib/compliance.nix { inherit lib; };
          policies = import ./src/lib/policies.nix { inherit lib; };
          output = import ./src/lib/output.nix { inherit lib pkgs; };
        };

      in
      {
        packages = {
          # Example package: Simple microservice deployment
          example-app = pkgs.runCommand "example-app-manifests" {
            buildInputs = with pkgs; [ yq ];
          } ''
            mkdir -p $out
            
            # This is a placeholder - actual manifest generation would use the modules
            cat > $out/manifests.yaml << 'EOF'
            apiVersion: v1
            kind: Namespace
            metadata:
              name: example
              labels:
                nixernetes.io/framework: "SOC2"
            ---
            apiVersion: apps/v1
            kind: Deployment
            metadata:
              name: example-app
              namespace: example
              labels:
                app.kubernetes.io/name: example-app
                nixernetes.io/framework: "SOC2"
                nixernetes.io/compliance-level: "high"
            spec:
              replicas: 2
              selector:
                matchLabels:
                  app.kubernetes.io/name: example-app
              template:
                metadata:
                  labels:
                    app.kubernetes.io/name: example-app
                spec:
                  containers:
                  - name: app
                    image: nginx:latest
                    ports:
                    - containerPort: 8080
                    resources:
                      limits:
                        cpu: "500m"
                        memory: "512Mi"
                      requests:
                        cpu: "100m"
                        memory: "128Mi"
            EOF
          '';
        };

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            nix
            nixpkgs-fmt
            yq
            jq
            python3
            python3Packages.pyyaml
            python3Packages.jsonschema
          ];

          shellHook = ''
            echo "Nixernetes development shell loaded"
            echo "Available tools: nix, yq, jq, python3"
          '';
        };

        # Build checks
        checks = {
          # Format check
          nix-fmt = pkgs.runCommand "nix-fmt-check" {} ''
            ${pkgs.nixpkgs-fmt}/bin/nixpkgs-fmt --check ${self}
            touch $out
          '';

          # Flake lock is up-to-date
          flake-lock = pkgs.runCommand "flake-lock-check" {} ''
            ${pkgs.nix}/bin/nix flake lock --dry-run ${self}
            touch $out
          '';
        };

        # Formatter
        formatter = pkgs.nixpkgs-fmt;
      }
    );
}
