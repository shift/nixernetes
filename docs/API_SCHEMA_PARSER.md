# API Schema Parser Documentation

## Overview

The API Schema Parser is a tool that automatically generates Nixernetes' `apiVersionMatrix` from upstream Kubernetes OpenAPI specifications. This ensures that the framework stays synchronized with the latest Kubernetes API versions across different release cycles.

## What It Does

The parser:
1. **Downloads** Kubernetes OpenAPI (Swagger JSON) specifications from official GitHub repositories
2. **Parses** the specifications to extract resource kind → apiVersion mappings
3. **Generates** Nix code that defines the `apiVersionMatrix` for supported Kubernetes versions
4. **Maintains** consistency across multiple Kubernetes versions

## Why This Matters

Previously, the `apiVersionMatrix` was hardcoded and duplicated across versions. This created:
- **Maintenance burden** - changes had to be made in multiple places
- **Version drift** - risk of inconsistencies between versions
- **Manual overhead** - no automation to keep up with upstream changes

The parser solves these by:
- **Automating** the entire process of extracting API versions
- **Reducing duplication** by generating consistent output
- **Ensuring correctness** by parsing official sources instead of manual entry

## Installation & Setup

### Prerequisites

The parser requires Python 3.6+ and is included in the Nixernetes development environment:

```bash
# Enter the development shell
nix develop

# Python and all dependencies are available
python3 --version
```

### Location

The parser script is located at:
```
docs/api_schema_parser.py
```

## Usage

### 1. Generate from Upstream Kubernetes Specs

Download and parse official Kubernetes releases:

```bash
# Using nix run (recommended)
nix run .#generate-api-versions

# Or directly with Python
python3 docs/api_schema_parser.py \
  --download 1.28 1.29 1.30 1.31 \
  --generate-nix \
  --output src/lib/api-versions-generated.nix
```

### 2. Parse Local Swagger JSON File

If you have a Swagger JSON file locally:

```bash
python3 docs/api_schema_parser.py \
  --parse path/to/swagger.json \
  --generate-nix \
  --output src/lib/api-versions-generated.nix
```

### 3. Generate JSON Output

For debugging or integration with other tools:

```bash
python3 docs/api_schema_parser.py \
  --download 1.28 1.29 \
  --output mappings.json
```

### 4. Include Extended Kinds

By default, the parser includes core Kubernetes resources plus extended kinds (Kyverno, ExternalSecrets, Cert-Manager, etc.):

```bash
python3 docs/api_schema_parser.py \
  --download 1.28 1.29 \
  --generate-nix \
  --extended  # Default: true
```

To only include core Kubernetes resources:

```bash
python3 docs/api_schema_parser.py \
  --download 1.28 1.29 \
  --generate-nix \
  --extended false
```

## Command-Line Reference

```
usage: api_schema_parser.py [-h] [--download VERSION [VERSION ...]]
                            [--parse FILE] [--generate-nix] [--output FILE]
                            [--extended]

options:
  -h, --help            Show this help message
  --download VERSION [VERSION ...]
                        Download and parse OpenAPI specs for Kubernetes
                        versions (e.g., 1.28 1.29 1.30)
  --parse FILE          Parse a local OpenAPI spec file
  --generate-nix        Generate Nix code instead of JSON output
  --output FILE         Write output to file (default: stdout)
  --extended            Include extended kinds like Kyverno, ExternalSecrets
                        (default: true)
```

## Workflow: Updating API Versions

When Kubernetes releases a new minor version (e.g., 1.32), follow this workflow:

### Step 1: Regenerate with New Version

```bash
cd /home/shift/code/ideas/nixernetes
nix run .#generate-api-versions 1.28 1.29 1.30 1.31 1.32
```

This command:
- Downloads the OpenAPI spec for each version from GitHub
- Parses the specifications
- Generates Nix code
- Writes to `src/lib/api-versions-generated.nix`

### Step 2: Review Changes

```bash
git diff src/lib/api-versions-generated.nix
```

Look for:
- New resource kinds added in the new version
- API version changes for existing resources
- Deprecations or removals

### Step 3: Validate

```bash
nix flake check
```

This runs all checks including:
- Syntax validation of the generated Nix file
- Module load tests
- API version resolution tests

### Step 4: Test Integration

Run the test suite to ensure nothing broke:

```bash
nix flake check
```

### Step 5: Commit

```bash
git add src/lib/api-versions-generated.nix CHANGELOG.md
git commit -m "chore: Update apiVersionMatrix for Kubernetes 1.32

- Added Kubernetes 1.32 support
- Updated API versions from upstream specifications
- Regenerated using api_schema_parser.py"
```

## Output Format

### Generated Nix File Structure

The parser generates a Nix file with this structure:

```nix
# src/lib/api-versions-generated.nix

{ lib }:

let
  apiVersionMatrix = {
    "1.28" = {
      Deployment = "apps/v1";
      StatefulSet = "apps/v1";
      # ... more resources
    };
    "1.29" = {
      # ...
    };
    # ...
  };
  supportedVersions = builtins.attrNames apiVersionMatrix;
in
{
  resolveApiVersion = { kind, kubernetesVersion }: ...;
  getSupportedVersions = ...;
  isSupportedVersion = version: ...;
  getApiMap = kubernetesVersion: ...;
}
```

### JSON Output Format

When using `--generate-nix false` or by default without the flag:

```json
{
  "1.28": {
    "Deployment": "apps/v1",
    "StatefulSet": "apps/v1",
    "Pod": "v1",
    ...
  },
  "1.29": {
    ...
  }
}
```

## Implementation Details

### Resource Kinds Extracted

The parser extracts these resource kinds:

**Core Kubernetes:**
- Pod, Service, Namespace, ConfigMap, Secret
- Deployment, StatefulSet, DaemonSet, ReplicaSet
- Job, CronJob
- Ingress, NetworkPolicy, IngressClass
- Role, RoleBinding, ClusterRole, ClusterRoleBinding
- PersistentVolume, PersistentVolumeClaim
- ServiceAccount

**Extended (Optional):**
- ClusterPolicy, Policy (Kyverno)
- ExternalSecret, SecretStore, ClusterSecretStore (External Secrets)
- Certificate, Issuer, ClusterIssuer (Cert-Manager)

### Version Preference Logic

When multiple API versions exist for a resource, the parser prefers:
1. **Stable versions** (v1) over beta/alpha
2. **First occurrence** if multiple stable versions exist

Example: If a resource exists as `v1`, `v1beta1`, and `v1alpha1`, the parser will choose `v1`.

### How It Works

1. **Download**: Fetches from `github.com/kubernetes/kubernetes` releases
2. **Parse**: Extracts `x-kubernetes-group-version-kind` metadata from paths
3. **Deduplicate**: Keeps stable version when multiple exist
4. **Format**: Generates Nix code with consistent structure
5. **Output**: Writes to file or stdout

## Troubleshooting

### Download Failures

**Error: "Failed to download spec for version X.Y.Z"**

Possible causes:
- Network connectivity issue
- Version doesn't exist (check latest releases)
- GitHub API rate limiting

Solutions:
```bash
# Check if version exists
curl -I https://raw.githubusercontent.com/kubernetes/kubernetes/v1.28.0/api/openapi-spec/swagger.json

# Try again later if rate-limited
# Or use --parse with local file instead
```

### Parse Errors

**Error: "Failed to parse JSON for version X.Y.Z"**

The OpenAPI spec may have changed format. Check:
- Kubernetes version number is valid
- OpenAPI spec structure hasn't radically changed

### Generated File Issues

**Generated file has unexpected content or missing resources**

Check:
- Were the correct versions specified?
- Are all required resources being parsed?
- Do you need to extend the CORE_KINDS or EXTENDED_KINDS lists?

## Integration with CI/CD

### GitHub Actions

Add to `.github/workflows/validate.yml`:

```yaml
- name: Validate API versions
  run: |
    nix run .#generate-api-versions
    git diff --exit-code src/lib/api-versions-generated.nix
```

This ensures the generated file is up-to-date before merging.

### Pre-commit Hooks

Add to `.pre-commit-config.yaml`:

```yaml
- repo: local
  hooks:
    - id: check-api-versions
      name: Check API versions generated
      entry: nix run .#generate-api-versions
      language: system
      files: docs/api_schema_parser.py
      pass_filenames: false
```

## Performance Considerations

### Download Time

- Downloading and parsing a single Kubernetes version takes ~30-60 seconds
- Multiple versions add roughly 30-60 seconds per version
- Plan accordingly for CI/CD pipelines

### Network Requirements

- Requires HTTPS access to `raw.githubusercontent.com`
- Typical spec file size: 5-10 MB per version
- No proxies or authentication needed

## Maintenance

### When to Regenerate

- When Kubernetes releases a new minor or major version
- When external CRDs change their default API versions
- When adding new extended kinds to support

### When NOT to Manually Edit

Don't manually edit `src/lib/api-versions-generated.nix`:
- Changes will be lost when regenerating
- Inconsistencies may be introduced
- Use the parser instead

If the parser produces incorrect output, fix it in the Python script and regenerate.

## Advanced: Extending the Parser

### Adding New Resource Kinds

Edit `KubernetesAPIParser` class in `docs/api_schema_parser.py`:

```python
EXTENDED_KINDS = {
    # ... existing kinds ...
    "CustomResource",  # Add your kind here
}
```

Then regenerate:
```bash
python3 docs/api_schema_parser.py --download 1.28 --generate-nix
```

### Custom OpenAPI Source

Modify the `download_spec()` method to use your own OpenAPI source:

```python
def download_spec(self, version: str) -> Dict:
    url = f"https://your-registry.example.com/k8s-{version}/swagger.json"
    # ... rest of implementation
```

### Filtering by API Group

The parser currently includes all API groups. To filter:

```python
# In extract_api_map(), check the group:
if group in ['', 'apps', 'batch', 'rbac.authorization.k8s.io']:
    # Only process these groups
```

## Related Files

- `src/lib/schema.nix` - Imports the generated file
- `src/lib/api-versions-generated.nix` - Generated output file
- `docs/api_schema_parser.py` - Parser script
- `.flake.nix` - Defines `generate-api-versions` app

## Further Reading

- [Kubernetes API Documentation](https://kubernetes.io/docs/reference/)
- [Kubernetes API Group Conventions](https://kubernetes.io/docs/reference/using-api/#api-groups)
- [Kubernetes OpenAPI Specification](https://github.com/kubernetes/kubernetes/tree/master/api/openapi-spec)

## Support

For issues or improvements:
1. Check the troubleshooting section above
2. Review script output for error messages
3. Open an issue on GitHub with:
   - Command used
   - Kubernetes version
   - Error message
   - Python version
