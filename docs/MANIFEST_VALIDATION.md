# Manifest Validation System

This document describes the Kubernetes manifest validation framework that ensures only valid manifests are generated for each resource kind.

## Overview

The manifest validation system provides:
- **Schema validation**: Verify that manifests conform to Kubernetes API schemas
- **Type checking**: Ensure fields have correct types
- **Required field validation**: Verify all required fields are present
- **Kind/version matching**: Ensure kind and apiVersion are compatible
- **Batch validation**: Validate multiple manifests at once

## Architecture

The system consists of three main components:

### 1. Auto-Generated Validators (`src/lib/validators-generated.nix`)

Generated from Kubernetes OpenAPI specifications using `docs/api_schema_parser.py`.

**Features:**
- 20+ resource validators (Pod, Deployment, Service, etc.)
- Each validator checks:
  - Required fields presence
  - Field type correctness
  - Metadata validity (name, namespace)
  - Kind and apiVersion matching
- Helper function `validateManifest()` for basic structure validation
- Dispatcher function `getValidator(kind)` to lookup kind-specific validators

**Example validator output:**
```nix
Pod_validator = manifest:
  let
    # Basic structure checks
    kind = manifest.kind or "";
    apiVersion = manifest.apiVersion or "";
    metadata = manifest.metadata or {};
    
    # Required fields for Pod
    requiredFields = [ "metadata" "spec" ];
    
    # Validation logic
    validateRequired = builtins.all (field:
      builtins.hasAttr field manifest
    ) requiredFields;
    
    metadataValid = (metadata.name or null) != null && 
                    (builtins.typeOf metadata.name == "string");
    
    kindMatches = kind == "Pod";
    apiVersionMatches = apiVersion == "v1";
  in
  {
    valid = validateRequired && metadataValid && kindMatches && apiVersionMatches;
    errors = lib.optionals (!validateRequired) [...];
  };
```

### 2. Manifest Validation Utilities (`src/lib/manifest-validation.nix`)

Provides high-level validation functions built on top of the auto-generated validators.

**Main Functions:**

- **`validateManifestStrict(manifest)`**: Comprehensive validation
  - Performs basic structural validation
  - Applies kind-specific validator
  - Returns `{ valid: bool; errors: [string]; }`

- **`validateManifests(manifests)`**: Batch validation
  - Validates array of manifests
  - Returns summary with counts and per-manifest details
  - Returns `{ valid: bool; errors: [string]; count: {...}; details: [...]; }`

- **`validateWithReport(manifest)`**: Detailed validation report
  - Includes manifest metadata in result
  - Shows kind, apiVersion, and name
  - Useful for debugging and error messages

- **`isKindSupported(kind)`**: Check if kind is supported
  - Returns boolean
  - Useful for filtering manifests before validation

- **`getKindInfo(kind)`**: Get information about a kind
  - Returns `{ supported: bool; validator: fn; ... }`
  - Lists available kinds if unsupported

### 3. Kubernetes Schema Module (`src/lib/kubernetes-schema.nix`)

Unified interface combining API versions and manifest validation.

**Exports:**

From API versions:
- `resolveApiVersion(kind, version)`: Get correct apiVersion for a kind
- `getSupportedVersions()`: List all Kubernetes versions
- `isSupportedVersion(version)`: Check if version is supported
- `getApiMap(version)`: Get kind→apiVersion mapping for a version

From validators:
- `validateManifestStrict`, `validateManifests`, `validateWithReport`
- `isKindSupported`, `getKindInfo`
- `supportedKinds`: List of supported resource kinds

## Usage Examples

### Basic Validation

```nix
let
  lib = (import <nixpkgs> {}).lib;
  k8sSchema = import ./src/lib/kubernetes-schema.nix { inherit lib; };
  
  myManifest = {
    kind = "Pod";
    apiVersion = "v1";
    metadata = {
      name = "my-pod";
      namespace = "default";
    };
  };
in
  k8sSchema.validateManifestStrict myManifest
```

Returns:
```nix
{
  valid = true;
  errors = [];
}
```

### Batch Validation

```nix
let
  manifests = [
    { kind = "Pod"; apiVersion = "v1"; metadata = { name = "pod1"; }; }
    { kind = "Service"; apiVersion = "v1"; metadata = { name = "svc1"; }; spec = { selector = { app = "test"; }; ports = [ { port = 80; } ]; }; }
  ];
in
  k8sSchema.validateManifests manifests
```

Returns:
```nix
{
  valid = true;
  errors = [];
  count = {
    total = 2;
    valid = 2;
    invalid = 0;
  };
  details = [ {...}, {...} ];
}
```

### Check Manifest Type

```nix
let
  k8sSchema = import ./src/lib/kubernetes-schema.nix { inherit lib; };
  kind = "Pod";
in
  k8sSchema.isKindSupported kind  # Returns true
```

### Get Kind Information

```nix
let
  info = k8sSchema.getKindInfo "Pod";
in
  info
  # Returns:
  # {
  #   supported = true;
  #   validator = <function>;
  # }
```

## Supported Resource Kinds

The validation system currently supports 20+ Kubernetes resource kinds:

**Core API:**
- Pod
- Service
- Namespace
- ConfigMap
- Secret
- ServiceAccount
- PersistentVolume
- PersistentVolumeClaim

**Apps API:**
- Deployment
- StatefulSet
- DaemonSet
- ReplicaSet

**Batch API:**
- Job
- CronJob

**Networking API:**
- Ingress
- NetworkPolicy
- IngressClass

**RBAC API:**
- Role
- RoleBinding
- ClusterRole
- ClusterRoleBinding

**Extended (Optional):**
- Certificate (cert-manager)
- ExternalSecret
- ClusterPolicy (Kyverno)

## Regenerating Validators

The validators are auto-generated from Kubernetes OpenAPI specifications.

### Generate for a single version:

```bash
cd /home/shift/code/ideas/nixernetes
nix develop -c -- python3 docs/api_schema_parser.py \
  --download 1.28 \
  --generate-validators \
  --output src/lib/validators-generated.nix
```

### Generate for multiple versions:

The current implementation generates validators for the latest stable Kubernetes version (1.28). To generate for multiple versions, you can:

1. Modify the `api_schema_parser.py` to support versioned validators
2. Generate separate validator files for each version
3. Import the appropriate version in your manifests

### Update API versions and validators together:

```bash
nix develop -c -- python3 docs/api_schema_parser.py \
  --download 1.28 1.29 1.30 1.31 \
  --generate-nix \
  --output src/lib/api-versions-generated.nix
```

## Validation Error Examples

### Missing Required Field

```nix
{
  kind = "Pod";
  apiVersion = "v1";
  # metadata field is missing!
}
```

Result:
```nix
{
  valid = false;
  errors = [
    "Missing required fields: [\"metadata\" \"spec\"]"
    "Invalid metadata: requires name (string)"
  ];
}
```

### Wrong API Version

```nix
{
  kind = "Deployment";
  apiVersion = "v1";  # Should be "apps/v1"
  metadata = { name = "my-deployment"; };
  spec = {};
}
```

Result:
```nix
{
  valid = false;
  errors = [
    "API version mismatch for Deployment"
  ];
}
```

### Unsupported Kind

```nix
{
  kind = "CustomResource";
  apiVersion = "v1";
  metadata = { name = "custom"; };
}
```

Result:
```nix
{
  valid = false;
  errors = [
    "No validator for kind: CustomResource"
  ];
  available = [
    "Pod", "Service", "Deployment", ...
  ];
}
```

## Integration with Nixernetes

The manifest validation system integrates with:

1. **Module configuration**: Validate user-provided manifests before deployment
2. **Resource generation**: Ensure generated manifests are valid
3. **Web UI**: Client-side validation before submission
4. **Terraform provider**: Manifest validation before applying

## Performance Characteristics

- **Single manifest validation**: O(n) where n is number of fields
- **Batch validation**: O(m*n) where m is number of manifests
- **No external dependencies**: Pure Nix evaluation
- **Lazy evaluation**: Only required fields are checked

## Future Enhancements

1. **Custom validators**: Allow users to define custom validation rules
2. **Schema evolution**: Support different validation rules per Kubernetes version
3. **OpenAPI schema integration**: Use full OpenAPI schemas for validation
4. **YAML lint integration**: Combine with format/style validation
5. **Policy enforcement**: Integrate with Kyverno/CEL policies

## Testing

The validation system includes comprehensive tests in `tests/manifest-validation-test.nix`:

Run tests:
```bash
cd /home/shift/code/ideas/nixernetes
nix develop -c -- nix-instantiate -E 'import ./tests/manifest-validation-test.nix {}'
```

Test coverage includes:
- Valid manifests of different types
- Missing required fields
- Invalid kind and apiVersion
- Batch validation
- Optional fields

## Troubleshooting

### "No validator for kind" error

This means the kind is not yet supported. Check the list of supported kinds or request support for new kinds.

### "Invalid metadata: requires name (string)"

The metadata.name field is missing or not a string. All manifests require:
```nix
metadata = {
  name = "your-resource-name";
  # namespace is optional for cluster-scoped resources
}
```

### Validation passes but manifest fails in Kubernetes

The validator ensures basic structure and required fields but doesn't validate:
- Field value constraints (e.g., replicas > 0)
- Spec validity (e.g., image pull policies)
- Dynamic constraints (e.g., label selectors match)

These are handled by Kubernetes itself during admission.

## See Also

- `docs/API_SCHEMA_PARSER_QUICKSTART.md` - Quick start for parser
- `docs/API_SCHEMA_PARSER_IMPLEMENTATION.md` - Implementation details
- `src/lib/validators-generated.nix` - Generated validators
- `tests/manifest-validation-test.nix` - Test suite
