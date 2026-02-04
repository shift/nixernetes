Technical Requirements: Nix-Driven Kubernetes Manifest Framework

1. Project Goal

The primary objective is to engineer a Nix-based configuration system that abstracts the inherent complexities of Kubernetes into high-level, strictly-typed, and data-driven modules. This framework will serve as a single source of truth, ensuring that every generated manifest adheres to enterprise-grade compliance standards and is precision-targeted for specific Kubernetes API versions. By leveraging the Nix module system, we aim to provide a declarative interface that eliminates common YAML pitfalls while providing robust validation before any resources are applied to a cluster.

2. Core Functional Requirements

2.1 Automated API Specification & Evolution

Dynamic Schema Parsing: The framework must be capable of consuming official Kubernetes OpenAPI/Swagger specifications (e.g., from the kubernetes/kubernetes repository).

Version-to-API Mapping: Instead of manual mapping, the system will auto-parse the specification for a requested k8sVersion to identify:

Preferred apiVersion for each kind.

Deprecated and removed APIs for the specific version target.

Required fields and type constraints for every resource.

Automatic Manifest Adjustment: When a version is bumped (e.g., 1.29 -> 1.31), the framework will automatically adjust the output structure based on the schema changes, raising build-time errors if the user's data-driven config violates the new schema.

2.2 Enterprise Compliance, Labeling & Regulatory Governance

Mandatory Labeling Engine: A central compliance engine intercepts every resource definition to inject standardized labels for observability and auditability (e.g., enterprise.com/compliance-level, enterprise.com/regulatory-framework, enterprise.com/owner-team).

Build-Time Enforcement: Utilizing Nix's lib.types, the framework implements strict validation. Evaluation fails immediately if required compliance fields are missing.

Traceability Annotations: Every resource is automatically annotated with the Nix derivation hash (nix-build-id), linking the running resource back to the specific git commit.

2.3 Policy & Security Generation (Zero Trust)

Automated NetworkPolicies:

Default Deny: For every application module, the framework automatically generates a "Default Deny All" NetworkPolicy within the namespace.

Intra-App Communication: Generates ingress rules allowing traffic only to specified ports from authorized sources.

Cross-App Dependencies: Modules define dependencies (e.g., consumes = [ "db" ]) which resolve into precise podSelector rules.

Kyverno Policy-as-Code:

Validation Rules: Generates Kyverno ClusterPolicy to enforce enterprise labels at admission time.

Mutation Rules: Automatically injects sidecars or modifies imagePullPolicy based on environment.

2.4 Dual Output Generation Modes

Manifest Mode (Raw YAML): Generates a single, monolithic manifest.yaml with logically ordered resources.

Helm Mode (Chart Templating): Generates a fully compliant Helm Chart directory structure, including Chart.yaml, values.yaml, and templates.

3. Technical Stack & Architecture

Language & Packaging: Nix (Flakes enabled).

Module System: lib.evalModules from Nixpkgs.

Dynamic Data: builtins.fromJSON paired with fetched OpenAPI specs.

Serialization: Native Nix attribute sets converted to JSON then formatted to YAML via pkgs.yq.

4. Operational & Security Design

Compliance Wrapper Logic: Intercepts high-level abstractions to apply PodSecurityContext and validate metadata.

Secret Strategy: Generates ExternalSecret or SealedSecret manifests.

Pre-Deployment Validation: Integration with kubeconform or polaris during the Nix build phase.
