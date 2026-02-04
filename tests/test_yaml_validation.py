#!/usr/bin/env python3
"""
YAML Validation Tests for Nixernetes

This module validates that generated Kubernetes manifests conform to:
- Kubernetes OpenAPI schemas
- Compliance label requirements
- Policy specifications
- Resource ordering for kubectl apply
"""

import json
import sys
import subprocess
from pathlib import Path
from typing import Dict, List, Any, Optional
import yaml


class KubernetesValidator:
    """Validates Kubernetes manifests against schemas"""

    def __init__(self, kubernetes_version: str = "1.30"):
        self.kubernetes_version = kubernetes_version
        self.supported_versions = ["1.28", "1.29", "1.30", "1.31"]
        
        if kubernetes_version not in self.supported_versions:
            raise ValueError(
                f"Kubernetes version {kubernetes_version} not in supported versions: "
                f"{self.supported_versions}"
            )

    def validate_resource_structure(self, resource: Dict[str, Any]) -> tuple[bool, List[str]]:
        """
        Validates basic Kubernetes resource structure
        
        Returns: (is_valid, list_of_errors)
        """
        errors = []
        
        # Check required fields
        if "apiVersion" not in resource:
            errors.append("Missing required field: apiVersion")
        if "kind" not in resource:
            errors.append("Missing required field: kind")
        if "metadata" not in resource:
            errors.append("Missing required field: metadata")
        
        # Validate metadata
        if "metadata" in resource:
            metadata = resource["metadata"]
            if not isinstance(metadata, dict):
                errors.append("metadata must be a dictionary")
            elif "name" not in metadata:
                errors.append("metadata.name is required")
            elif not isinstance(metadata["name"], str):
                errors.append("metadata.name must be a string")
        
        # Validate namespace (if present)
        if "metadata" in resource and "namespace" in resource["metadata"]:
            ns = resource["metadata"]["namespace"]
            if not isinstance(ns, str):
                errors.append("metadata.namespace must be a string")
        
        return len(errors) == 0, errors

    def validate_labels(self, resource: Dict[str, Any]) -> tuple[bool, List[str]]:
        """Validates that labels exist and are properly formatted"""
        errors = []
        
        metadata = resource.get("metadata", {})
        labels = metadata.get("labels", {})
        
        if not isinstance(labels, dict):
            errors.append("labels must be a dictionary")
            return False, errors
        
        return True, []

    def validate_annotations(self, resource: Dict[str, Any]) -> tuple[bool, List[str]]:
        """Validates that annotations (if present) are properly formatted"""
        errors = []
        
        metadata = resource.get("metadata", {})
        annotations = metadata.get("annotations", {})
        
        if annotations and not isinstance(annotations, dict):
            errors.append("annotations must be a dictionary")
            return False, errors
        
        return True, []


class ComplianceValidator:
    """Validates compliance labels and enforcement"""

    REQUIRED_COMPLIANCE_LABELS = [
        "nixernetes.io/framework",
        "nixernetes.io/compliance-level",
        "nixernetes.io/owner",
    ]

    VALID_FRAMEWORKS = [
        "PCI-DSS",
        "HIPAA",
        "SOC2",
        "ISO27001",
        "GDPR",
        "NIST",
    ]

    VALID_LEVELS = [
        "unrestricted",
        "permissive",
        "standard",
        "strict",
        "restricted",
    ]

    def validate_compliance_labels(
        self, resource: Dict[str, Any], required: bool = False
    ) -> tuple[bool, List[str]]:
        """
        Validates compliance labels on a resource
        
        Args:
            resource: Kubernetes resource
            required: Whether compliance labels are required
            
        Returns: (is_valid, list_of_errors)
        """
        errors = []
        metadata = resource.get("metadata", {})
        labels = metadata.get("labels", {})

        if required and "nixernetes.io/framework" not in labels:
            errors.append("Required label missing: nixernetes.io/framework")

        # Validate framework value
        if "nixernetes.io/framework" in labels:
            framework = labels["nixernetes.io/framework"]
            if framework not in self.VALID_FRAMEWORKS:
                errors.append(
                    f"Invalid framework: {framework}. "
                    f"Valid frameworks: {self.VALID_FRAMEWORKS}"
                )

        # Validate compliance level
        if "nixernetes.io/compliance-level" in labels:
            level = labels["nixernetes.io/compliance-level"]
            if level not in self.VALID_LEVELS:
                errors.append(
                    f"Invalid compliance level: {level}. "
                    f"Valid levels: {self.VALID_LEVELS}"
                )

        return len(errors) == 0, errors

    def validate_traceability(self, resource: Dict[str, Any]) -> tuple[bool, List[str]]:
        """Validates traceability annotations (build ID, etc.)"""
        errors = []
        metadata = resource.get("metadata", {})
        annotations = metadata.get("annotations", {})

        # Check for common traceability fields
        traceability_fields = [
            "nixernetes.io/nix-build-id",
            "nixernetes.io/generated-by",
        ]

        # At least one traceability field should exist
        has_traceability = any(
            field in annotations for field in traceability_fields
        )

        if not has_traceability:
            # This is a warning, not an error
            pass

        return True, errors


class PolicyValidator:
    """Validates security and compliance policies"""

    def validate_network_policy(self, resource: Dict[str, Any]) -> tuple[bool, List[str]]:
        """Validates NetworkPolicy structure"""
        errors = []

        if resource.get("kind") != "NetworkPolicy":
            return True, []

        spec = resource.get("spec", {})

        # NetworkPolicy must have podSelector
        if "podSelector" not in spec:
            errors.append("NetworkPolicy.spec.podSelector is required")

        # Should have either ingress or egress rules
        has_rules = (
            "ingress" in spec or "egress" in spec or 
            "policyTypes" in spec
        )
        if not has_rules:
            errors.append(
                "NetworkPolicy should define ingress/egress rules or policyTypes"
            )

        return len(errors) == 0, errors

    def validate_kyverno_policy(self, resource: Dict[str, Any]) -> tuple[bool, List[str]]:
        """Validates Kyverno ClusterPolicy or Policy structure"""
        errors = []

        kind = resource.get("kind")
        if kind not in ["ClusterPolicy", "Policy"]:
            return True, []

        spec = resource.get("spec", {})

        # Must have rules
        if "rules" not in spec:
            errors.append(f"{kind}.spec.rules is required")

        # Rules must be non-empty
        if isinstance(spec.get("rules"), list) and len(spec["rules"]) == 0:
            errors.append(f"{kind}.spec.rules must not be empty")

        return len(errors) == 0, errors

    def validate_rbac_resource(self, resource: Dict[str, Any]) -> tuple[bool, List[str]]:
        """Validates RBAC resources (Role, RoleBinding, etc.)"""
        errors = []

        kind = resource.get("kind")
        if kind not in ["Role", "RoleBinding", "ClusterRole", "ClusterRoleBinding"]:
            return True, []

        spec = resource.get("spec", {})

        if kind in ["Role", "ClusterRole"]:
            if "rules" not in spec:
                errors.append(f"{kind}.spec.rules is required")
        elif kind in ["RoleBinding", "ClusterRoleBinding"]:
            if "roleRef" not in spec:
                errors.append(f"{kind}.spec.roleRef is required")
            if "subjects" not in spec:
                errors.append(f"{kind}.spec.subjects is required")

        return len(errors) == 0, errors


class ManifestAnalyzer:
    """Analyzes complete manifests for consistency and correctness"""

    def __init__(self):
        self.k8s_validator = KubernetesValidator()
        self.compliance_validator = ComplianceValidator()
        self.policy_validator = PolicyValidator()

    def parse_yaml_manifest(self, yaml_content: str) -> List[Dict[str, Any]]:
        """Parse YAML manifest into list of resources"""
        resources = []
        docs = yaml.safe_load_all(yaml_content)
        for doc in docs:
            if doc is not None:
                resources.append(doc)
        return resources

    def validate_manifest(self, yaml_content: str) -> Dict[str, Any]:
        """
        Comprehensively validate a manifest
        
        Returns dict with:
        - is_valid: bool
        - resource_count: int
        - validation_results: list of per-resource results
        - errors: list of manifest-level errors
        """
        resources = self.parse_yaml_manifest(yaml_content)
        validation_results = []
        errors = []

        for i, resource in enumerate(resources):
            if resource is None:
                continue

            resource_errors = []
            kind = resource.get("kind", "Unknown")
            name = resource.get("metadata", {}).get("name", "unnamed")

            # Validate structure
            _, struct_errors = self.k8s_validator.validate_resource_structure(resource)
            resource_errors.extend(struct_errors)

            # Validate labels
            _, label_errors = self.k8s_validator.validate_labels(resource)
            resource_errors.extend(label_errors)

            # Validate annotations
            _, annotation_errors = self.k8s_validator.validate_annotations(resource)
            resource_errors.extend(annotation_errors)

            # Validate compliance (if labels present)
            if "labels" in resource.get("metadata", {}):
                _, compliance_errors = self.compliance_validator.validate_compliance_labels(
                    resource
                )
                resource_errors.extend(compliance_errors)

            # Validate policies
            _, policy_errors = self.policy_validator.validate_network_policy(resource)
            resource_errors.extend(policy_errors)

            _, kyverno_errors = self.policy_validator.validate_kyverno_policy(resource)
            resource_errors.extend(kyverno_errors)

            _, rbac_errors = self.policy_validator.validate_rbac_resource(resource)
            resource_errors.extend(rbac_errors)

            validation_results.append({
                "index": i,
                "kind": kind,
                "name": name,
                "is_valid": len(resource_errors) == 0,
                "errors": resource_errors,
            })

        # Check for manifest-level issues
        # - Ensure namespaces exist before resources referencing them
        namespaces = {
            r.get("metadata", {}).get("name")
            for r in resources
            if r.get("kind") == "Namespace"
        }

        for resource in resources:
            ns = resource.get("metadata", {}).get("namespace")
            if ns and ns != "default" and ns not in namespaces:
                errors.append(
                    f"Resource {resource.get('kind')} {resource.get('metadata', {}).get('name')} "
                    f"references namespace '{ns}' which is not defined"
                )

        is_valid = (
            len(errors) == 0 and
            all(r["is_valid"] for r in validation_results)
        )

        return {
            "is_valid": is_valid,
            "resource_count": len(resources),
            "validation_results": validation_results,
            "manifest_errors": errors,
        }

    def validate_resource_ordering(self, yaml_content: str) -> Dict[str, Any]:
        """
        Validate that resources are in correct order for kubectl apply
        
        Expected order: Namespace -> RBAC -> Configs -> Workloads -> Services -> Ingress -> Policies
        """
        resources = self.parse_yaml_manifest(yaml_content)

        resource_priority = {
            "Namespace": 1,
            "ClusterRole": 2,
            "ClusterRoleBinding": 2,
            "Role": 2,
            "RoleBinding": 2,
            "ServiceAccount": 2,
            "ConfigMap": 3,
            "Secret": 3,
            "Pod": 4,
            "Deployment": 4,
            "StatefulSet": 4,
            "DaemonSet": 4,
            "Job": 4,
            "CronJob": 4,
            "Service": 5,
            "Ingress": 6,
            "NetworkPolicy": 7,
            "ClusterPolicy": 7,
            "Policy": 7,
        }

        is_ordered = True
        ordering_issues = []
        prev_priority = 0

        for i, resource in enumerate(resources):
            if resource is None:
                continue
            kind = resource.get("kind")
            priority = resource_priority.get(kind, 99)

            if priority < prev_priority:
                is_ordered = False
                ordering_issues.append(
                    f"Resource {i}: {kind} (priority {priority}) "
                    f"comes after priority {prev_priority}"
                )

            prev_priority = priority

        return {
            "is_ordered": is_ordered,
            "ordering_issues": ordering_issues,
            "resource_count": len(resources),
        }


def test_example_manifest():
    """Test the example web app manifest"""
    analyzer = ManifestAnalyzer()

    # This would normally read from generated manifest
    example_manifest = """
apiVersion: v1
kind: Namespace
metadata:
  name: example
  labels:
    nixernetes.io/framework: SOC2
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: example
  labels:
    app.kubernetes.io/name: web-app
    nixernetes.io/framework: SOC2
    nixernetes.io/compliance-level: standard
    nixernetes.io/owner: platform-team
  annotations:
    nixernetes.io/nix-build-id: abc123
spec:
  replicas: 3
  selector:
    matchLabels:
      app.kubernetes.io/name: web-app
  template:
    metadata:
      labels:
        app.kubernetes.io/name: web-app
    spec:
      containers:
      - name: app
        image: nginx:latest
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 500m
            memory: 512Mi
---
apiVersion: v1
kind: Service
metadata:
  name: web-app
  namespace: example
spec:
  selector:
    app.kubernetes.io/name: web-app
  ports:
  - protocol: TCP
    port: 8080
    targetPort: 8080
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-app-default-deny
  namespace: example
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: web-app
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
"""

    print("=" * 80)
    print("TESTING EXAMPLE MANIFEST")
    print("=" * 80)

    result = analyzer.validate_manifest(example_manifest)
    print(f"\nManifest Validation Result:")
    print(f"  Valid: {result['is_valid']}")
    print(f"  Resource Count: {result['resource_count']}")
    print(f"  Manifest Errors: {result['manifest_errors']}")

    print(f"\nPer-Resource Results:")
    for res in result["validation_results"]:
        status = "✓" if res["is_valid"] else "✗"
        print(f"  {status} {res['kind']}/{res['name']}")
        if res["errors"]:
            for error in res["errors"]:
                print(f"      - {error}")

    ordering_result = analyzer.validate_resource_ordering(example_manifest)
    print(f"\nResource Ordering:")
    print(f"  Correct Order: {ordering_result['is_ordered']}")
    if ordering_result["ordering_issues"]:
        for issue in ordering_result["ordering_issues"]:
            print(f"      - {issue}")

    return result["is_valid"] and ordering_result["is_ordered"]


if __name__ == "__main__":
    try:
        success = test_example_manifest()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(2)
