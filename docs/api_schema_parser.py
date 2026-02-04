#!/usr/bin/env python3
"""
Kubernetes OpenAPI Specification Parser

This script parses the upstream Kubernetes OpenAPI (Swagger) specification
and auto-generates a Nix-friendly apiVersionMatrix for different Kubernetes versions.

Usage:
    python3 api_schema_parser.py --download 1.28 1.29 1.30 1.31
    python3 api_schema_parser.py --generate swagger.json
    python3 api_schema_parser.py --generate-nix swagger.json --output api-versions.nix
"""

import json
import sys
import os
import urllib.request
import urllib.error
import argparse
from typing import Dict, List, Tuple
from pathlib import Path


class KubernetesAPIParser:
    """Parser for Kubernetes OpenAPI specification"""

    # Core Kubernetes resource kinds to extract
    CORE_KINDS = {
        # Core API
        "Pod", "Service", "Namespace", "ConfigMap", "Secret",
        "ServiceAccount", "PersistentVolume", "PersistentVolumeClaim",
        
        # Apps API
        "Deployment", "StatefulSet", "DaemonSet", "ReplicaSet",
        
        # Batch API
        "Job", "CronJob",
        
        # Networking API
        "Ingress", "NetworkPolicy", "IngressClass",
        
        # RBAC API
        "Role", "RoleBinding", "ClusterRole", "ClusterRoleBinding",
    }

    # Extended kinds (useful but optional)
    EXTENDED_KINDS = {
        # Kyverno
        "ClusterPolicy", "Policy",
        
        # External Secrets
        "ExternalSecret", "SecretStore", "ClusterSecretStore",
        
        # Cert Manager
        "Certificate", "Issuer", "ClusterIssuer",
    }

    def __init__(self, include_extended: bool = True):
        """Initialize the parser"""
        self.include_extended = include_extended
        self.all_kinds = self.CORE_KINDS.copy()
        if include_extended:
            self.all_kinds.update(self.EXTENDED_KINDS)

    def download_spec(self, version: str) -> Dict:
        """
        Download Kubernetes OpenAPI spec for a specific version
        
        Args:
            version: Kubernetes version (e.g., "1.28" or "1.28.0")
            
        Returns:
            Parsed JSON spec dictionary
        """
        # Try multiple URL formats to handle different version inputs
        # Format 1: v1.28.0 (full release)
        # Format 2: v1.28 (latest patch of minor version)
        # Format 3: release-1.28 (branch name)
        
        url_formats = [
            f"https://raw.githubusercontent.com/kubernetes/kubernetes/v{version}/api/openapi-spec/swagger.json",
            f"https://raw.githubusercontent.com/kubernetes/kubernetes/release-{version}/api/openapi-spec/swagger.json",
        ]
        
        # If version doesn't have patch number, try with .0
        if version.count('.') == 1:
            url_formats.insert(1, f"https://raw.githubusercontent.com/kubernetes/kubernetes/v{version}.0/api/openapi-spec/swagger.json")
        
        last_error = None
        for url in url_formats:
            try:
                print(f"Trying: {url}", file=sys.stderr)
                with urllib.request.urlopen(url, timeout=30) as response:
                    data = response.read()
                    print(f"✓ Downloaded from: {url}", file=sys.stderr)
                    return json.loads(data)
            except urllib.error.URLError as e:
                last_error = e
                continue
            except json.JSONDecodeError as e:
                raise RuntimeError(f"Failed to parse JSON for version {version}: {e}")
        
        # All URLs failed
        raise RuntimeError(f"Failed to download spec for version {version}. Tried: {', '.join(url_formats)}. Error: {last_error}")

    def extract_api_map(self, spec: Dict) -> Dict[str, str]:
        """
        Extract API version mappings from Kubernetes OpenAPI spec
        
        Args:
            spec: Parsed OpenAPI specification
            
        Returns:
            Dictionary mapping kind names to their apiVersion
        """
        api_map = {}
        
        for path, details in spec.get('paths', {}).items():
            # Check both POST and GET operations for x-kubernetes-group-version-kind
            for operation in ['post', 'get', 'put', 'patch', 'delete']:
                if operation not in details:
                    continue
                    
                operation_spec = details[operation]
                gvk = operation_spec.get('x-kubernetes-group-version-kind')
                
                if not gvk:
                    continue
                
                kind = gvk.get('kind')
                group = gvk.get('group', '')
                version = gvk.get('version', '')
                
                # Only include kinds we care about
                if kind not in self.all_kinds:
                    continue
                
                if not version:
                    continue
                
                # Construct apiVersion
                api_version = f"{group}/{version}" if group else version
                
                # Prefer stable versions (v1) over beta/alpha
                if kind not in api_map:
                    api_map[kind] = api_version
                else:
                    # Upgrade to more stable version if available
                    current = api_map[kind]
                    if self._is_more_stable(api_version, current):
                        api_map[kind] = api_version
        
        return api_map

    @staticmethod
    def _is_more_stable(version1: str, version2: str) -> bool:
        """Determine if version1 is more stable than version2"""
        # v1 > v1betaX > v1alphaX
        priority = {'v1': 3, 'beta': 2, 'alpha': 1}
        
        def get_priority(v):
            if 'alpha' in v:
                return priority['alpha']
            elif 'beta' in v:
                return priority['beta']
            else:
                return priority['v1']
        
        return get_priority(version1) > get_priority(version2)

    @staticmethod
    def generate_nix_code(api_maps: Dict[str, Dict[str, str]], 
                         k8s_versions: List[str]) -> str:
        """
        Generate Nix code for apiVersionMatrix
        
        Args:
            api_maps: Dict of version -> (kind -> apiVersion)
            k8s_versions: List of Kubernetes versions
            
        Returns:
            Nix code as string
        """
        lines = [
            "# Auto-generated API version mappings for Kubernetes",
            "# Generated from upstream Kubernetes OpenAPI specifications",
            "# DO NOT EDIT MANUALLY - regenerate using: nix run .#generate-api-versions",
            "#",
            "# This maps Kubernetes resource kinds to their preferred apiVersion",
            "# for each supported Kubernetes version.",
            "",
            "{ lib }:",
            "",
            "let",
            "  inherit (lib) mkDefault;",
            "",
            "  apiVersionMatrix = {",
        ]
        
        # Sort versions for consistent output
        sorted_versions = sorted(k8s_versions, key=lambda v: tuple(map(int, v.split('.'))))
        
        for version in sorted_versions:
            api_map = api_maps.get(version, {})
            
            lines.append(f'    "{version}" = {{')
            
            # Sort kinds alphabetically for consistency
            for kind in sorted(api_map.keys()):
                api_version = api_map[kind]
                lines.append(f'      {kind} = "{api_version}";')
            
            lines.append('    };')
            lines.append('')
        
        lines.extend([
            "  };",
            "",
            "  supportedVersions = builtins.attrNames apiVersionMatrix;",
            "",
            "in",
            "{",
            "  # Resolve apiVersion for a kind given a Kubernetes version",
            "  resolveApiVersion = { kind, kubernetesVersion }:",
            "    let",
            "      versionMap = apiVersionMatrix.${kubernetesVersion}",
            '        or (throw "Unsupported Kubernetes version: ${kubernetesVersion}. Supported: ${builtins.toJSON supportedVersions}");',
            "    in",
            "      versionMap.${kind}",
            '        or (throw "Unknown resource kind: ${kind} for Kubernetes version ${kubernetesVersion}");',
            "",
            "  # Get all supported Kubernetes versions",
            "  getSupportedVersions = supportedVersions;",
            "",
            "  # Check if a version is supported",
            "  isSupportedVersion = version: builtins.elem version supportedVersions;",
            "",
            "  # Get the full API map for a version",
            "  getApiMap = kubernetesVersion:",
            "    apiVersionMatrix.${kubernetesVersion}",
            '      or (throw "Unsupported Kubernetes version: ${kubernetesVersion}");',
            "}",
        ])
        
        return '\n'.join(lines)

    @staticmethod
    def generate_json_output(api_maps: Dict[str, Dict[str, str]]) -> str:
        """Generate JSON output of API mappings"""
        return json.dumps(api_maps, indent=2)


def main():
    parser = argparse.ArgumentParser(
        description="Kubernetes OpenAPI Specification Parser",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Download and parse specs for multiple versions
  python3 api_schema_parser.py --download 1.28 1.29 1.30

  # Parse a local swagger.json file and output JSON
  python3 api_schema_parser.py --parse swagger.json

  # Generate Nix code from swagger.json
  python3 api_schema_parser.py --parse swagger.json --generate-nix

  # Full workflow: download, parse, and generate Nix
  python3 api_schema_parser.py --download 1.28 1.29 --generate-nix --output schema.nix
        """
    )
    
    parser.add_argument('--download', nargs='+', metavar='VERSION',
                       help='Download and parse OpenAPI specs for Kubernetes versions')
    parser.add_argument('--parse', type=str, metavar='FILE',
                       help='Parse a local OpenAPI spec file')
    parser.add_argument('--generate-nix', action='store_true',
                       help='Generate Nix code instead of JSON')
    parser.add_argument('--output', type=str, metavar='FILE',
                       help='Output file (default: stdout)')
    parser.add_argument('--extended', action='store_true', default=True,
                       help='Include extended kinds (Kyverno, ExternalSecrets, etc.)')
    
    args = parser.parse_args()
    
    # Validate arguments
    if not args.download and not args.parse:
        parser.print_help()
        sys.exit(1)
    
    api_parser = KubernetesAPIParser(include_extended=args.extended)
    api_maps = {}
    versions = []
    
    # Download and parse from upstream
    if args.download:
        versions = args.download
        for version in versions:
            try:
                spec = api_parser.download_spec(version)
                api_map = api_parser.extract_api_map(spec)
                api_maps[version] = api_map
                print(f"✓ Parsed Kubernetes {version}", file=sys.stderr)
            except Exception as e:
                print(f"✗ Failed to parse Kubernetes {version}: {e}", file=sys.stderr)
                sys.exit(1)
    
    # Parse local file
    if args.parse:
        try:
            with open(args.parse, 'r') as f:
                spec = json.load(f)
            
            # Try to infer version from file name or metadata
            version = "custom"
            if 'info' in spec and 'version' in spec['info']:
                version = spec['info']['version']
            
            api_map = api_parser.extract_api_map(spec)
            api_maps[version] = api_map
            versions.append(version)
            print(f"✓ Parsed {args.parse}", file=sys.stderr)
        except Exception as e:
            print(f"✗ Failed to parse {args.parse}: {e}", file=sys.stderr)
            sys.exit(1)
    
    # Generate output
    if args.generate_nix:
        output = api_parser.generate_nix_code(api_maps, versions)
    else:
        output = api_parser.generate_json_output(api_maps)
    
    # Write to file or stdout
    if args.output:
        try:
            with open(args.output, 'w') as f:
                f.write(output)
            print(f"✓ Written to {args.output}", file=sys.stderr)
        except IOError as e:
            print(f"✗ Failed to write to {args.output}: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print(output)


if __name__ == "__main__":
    main()
