# API Schema Parser - Quick Start Guide

## 5-Minute Overview

The API Schema Parser automatically generates Nixernetes' Kubernetes API version mappings from official Kubernetes specifications. No more manual updates!

### What It Does

```
Kubernetes OpenAPI Specs (1.28, 1.29, 1.30, 1.31)
              ↓
        Parse Python Script
              ↓
    Extract Resource → API Version Mappings
              ↓
     Generate Nix Code (api-versions-generated.nix)
              ↓
    Use in Manifest Generation & Validation
```

### Key Benefits

- ✅ **Automatic** - Download and parse official specs
- ✅ **Accurate** - Extract directly from upstream sources
- ✅ **Consistent** - Eliminate manual duplication
- ✅ **Maintainable** - Single source of truth
- ✅ **Testable** - Validate before committing

## Installation

### Prerequisites

Python 3.6+ is required. Check your version:

```bash
python3 --version
# Expected: Python 3.6 or higher
```

### The Script

The parser is located at:

```
docs/api_schema_parser.py
```

It's already executable:

```bash
chmod +x docs/api_schema_parser.py
python3 docs/api_schema_parser.py --help
```

## Common Tasks

### 1. Generate Current API Versions

Generate mappings for currently supported Kubernetes versions:

```bash
python3 docs/api_schema_parser.py \
  --download 1.28 1.29 1.30 1.31 \
  --generate-nix \
  --output src/lib/api-versions-generated.nix
```

**Output:**
```
✓ Downloaded from: https://raw.githubusercontent.com/.../v1.28.0/api/openapi-spec/swagger.json
✓ Parsed Kubernetes 1.28
✓ Downloaded from: https://raw.githubusercontent.com/.../v1.29.0/api/openapi-spec/swagger.json
✓ Parsed Kubernetes 1.29
... (repeats for 1.30, 1.31)
✓ Written to src/lib/api-versions-generated.nix
```

### 2. Add Support for New Kubernetes Version

When Kubernetes 1.32 is released:

```bash
python3 docs/api_schema_parser.py \
  --download 1.28 1.29 1.30 1.31 1.32 \
  --generate-nix \
  --output src/lib/api-versions-generated.nix
```

Then verify and commit:

```bash
git diff src/lib/api-versions-generated.nix
nix-instantiate --parse src/lib/api-versions-generated.nix
git add src/lib/api-versions-generated.nix
git commit -m "chore: Add Kubernetes 1.32 support"
```

### 3. Parse Local Swagger File

If you have a local OpenAPI spec:

```bash
python3 docs/api_schema_parser.py \
  --parse /path/to/swagger.json \
  --generate-nix \
  --output output.nix
```

### 4. Debug: Generate JSON Output

For debugging or inspection:

```bash
python3 docs/api_schema_parser.py \
  --download 1.28 \
  --output mappings.json

# View what was extracted
cat mappings.json | python3 -m json.tool | head -50
```

### 5. Check Only Core Resources

Exclude extended CRDs (Kyverno, ExternalSecrets, etc.):

```bash
python3 docs/api_schema_parser.py \
  --download 1.28 \
  --generate-nix \
  --output core-only.nix
  # Note: --extended false is default with no flag
```

## Command Reference

### Basic Usage

```bash
python3 docs/api_schema_parser.py [OPTIONS]
```

### Options

| Option | Description | Example |
|--------|-------------|---------|
| `--download VERSION [VERSION ...]` | Download from GitHub | `--download 1.28 1.29 1.30` |
| `--parse FILE` | Parse local file | `--parse swagger.json` |
| `--generate-nix` | Output Nix code (default: JSON) | `--generate-nix` |
| `--output FILE` | Write to file (default: stdout) | `--output schema.nix` |
| `--extended` | Include extended CRDs (default: true) | `--extended` |
| `--help` | Show this message | `--help` |

### Examples

**Download multiple versions, generate Nix, save to file:**
```bash
python3 docs/api_schema_parser.py \
  --download 1.28 1.29 1.30 1.31 \
  --generate-nix \
  --output src/lib/api-versions-generated.nix
```

**Parse local file, output JSON to stdout:**
```bash
python3 docs/api_schema_parser.py \
  --parse swagger.json
```

**Download single version, view result on terminal:**
```bash
python3 docs/api_schema_parser.py \
  --download 1.28 \
  --generate-nix
```

**Parse file, output JSON to file:**
```bash
python3 docs/api_schema_parser.py \
  --parse swagger.json \
  --output mappings.json
```

## Understanding the Output

### Generated Nix File Structure

The output file (`api-versions-generated.nix`) contains:

```nix
# Header (auto-generation notice)
{ lib }:

let
  apiVersionMatrix = {
    "1.28" = {
      Pod = "v1";
      Deployment = "apps/v1";
      # ... ~30 resources per version
    };
    "1.29" = { /* ... */ };
    # ... more versions
  };

in
{
  resolveApiVersion = { ... };
  getSupportedVersions = [ "1.28" "1.29" "1.30" "1.31" ];
  isSupportedVersion = ...;
  getApiMap = ...;
}
```

### Resources Extracted

**Core Kubernetes (always included):**
- Pod, Service, Namespace, ConfigMap, Secret
- Deployment, StatefulSet, DaemonSet, ReplicaSet
- Job, CronJob
- Ingress, NetworkPolicy, IngressClass
- Role, RoleBinding, ClusterRole, ClusterRoleBinding
- PersistentVolume, PersistentVolumeClaim, ServiceAccount

**Extended CRDs (included by default):**
- Kyverno: ClusterPolicy, Policy
- ExternalSecrets: ExternalSecret, SecretStore, ClusterSecretStore
- Cert-Manager: Certificate, Issuer, ClusterIssuer

## Troubleshooting

### Problem: "Failed to download spec for version 1.28"

**Solutions:**
1. Check internet connection
2. Verify version exists: `curl -I https://github.com/kubernetes/kubernetes/releases/tag/v1.28.0`
3. Try different version format: `1.28.0` instead of `1.28`
4. Wait for GitHub rate limit to reset (15 min)

### Problem: Generated file doesn't compile

**Solutions:**
1. Validate syntax: `nix-instantiate --parse api-versions-generated.nix`
2. Check for special characters: `grep -v '^[a-zA-Z0-9_=-]' api-versions-generated.nix`
3. Ensure file ends with `}`: `tail -1 api-versions-generated.nix`

### Problem: Missing resources in output

**Solutions:**
1. Check if resource is in CORE_KINDS: `grep "Pod\|Deployment" docs/api_schema_parser.py`
2. Try parsing local file: `python3 docs/api_schema_parser.py --parse swagger.json --output out.json`
3. Search parsed output: `grep -c "kind" out.json`

## Integration with Nixernetes

### Using in Modules

The `schema.nix` module imports the generated file:

```nix
# src/lib/schema.nix
generatedVersions = import ./api-versions-generated.nix { inherit lib; };
```

This exposes functions to all modules:

```nix
# In any module
{ nixernetes, ... }:
let
  apiVersion = nixernetes.schema.resolveApiVersion {
    kind = "Deployment";
    kubernetesVersion = "1.28";
  };
in
# Use apiVersion: "apps/v1"
```

### Testing Changes

After generating new versions:

```bash
# 1. Validate syntax
nix-instantiate --parse src/lib/api-versions-generated.nix

# 2. Check it loads
nix eval --file src/lib/schema.nix 'getSupportedVersions'

# 3. Test a specific lookup
nix eval --file src/lib/schema.nix 'resolveApiVersion {
  kind = "Deployment";
  kubernetesVersion = "1.28";
}'
```

## Performance Tips

### Reduce Download Time

- Only download versions you need: `--download 1.31` (not all)
- Use a cached version if available locally
- Parallel downloads in CI/CD (future feature)

### Local Testing

If you have the OpenAPI spec locally:

```bash
# Download once, reuse many times
curl -o /tmp/k8s-1.28.json \
  https://raw.githubusercontent.com/kubernetes/kubernetes/v1.28.0/api/openapi-spec/swagger.json

# Use locally (much faster)
python3 docs/api_schema_parser.py \
  --parse /tmp/k8s-1.28.json \
  --generate-nix \
  --output output.nix
```

## Advanced Usage

### Custom OpenAPI Source

To use a different OpenAPI source (air-gapped, private registry):

1. Edit `docs/api_schema_parser.py`
2. Find `download_spec()` method
3. Modify URL construction:

```python
def download_spec(self, version: str) -> Dict:
    url = f"https://my-registry.example.com/k8s-{version}/swagger.json"
    # ... rest remains same
```

### Adding New Resource Kinds

To track additional resource types:

1. Edit `docs/api_schema_parser.py`
2. Add to `EXTENDED_KINDS`:

```python
EXTENDED_KINDS = {
    # ... existing ...
    "MyCustomResource",  # Add this
}
```

3. Regenerate:

```bash
python3 docs/api_schema_parser.py \
  --download 1.28 1.29 1.30 1.31 \
  --generate-nix \
  --output src/lib/api-versions-generated.nix
```

### Filtering API Groups

To only include certain API groups:

Edit `extract_api_map()` in the parser and add group filtering:

```python
# Only include core and apps APIs
if group not in ['', 'apps', 'batch']:
    continue
```

## Automation

### GitHub Actions Workflow

Check for outdated API versions automatically:

```yaml
# .github/workflows/check-api-versions.yml
name: Check API Versions
on:
  schedule:
    - cron: '0 0 1 * *'  # Monthly

jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v22
      - name: Regenerate API versions
        run: |
          nix develop -c python3 docs/api_schema_parser.py \
            --download 1.28 1.29 1.30 1.31 \
            --generate-nix \
            --output /tmp/new.nix
      - name: Check for changes
        run: |
          diff -u src/lib/api-versions-generated.nix /tmp/new.nix || echo "Updates available"
```

### Pre-commit Hook

Validate before committing:

```bash
# .githooks/pre-commit
#!/bin/bash
if git diff --cached --name-only | grep -q api_schema_parser.py; then
  python3 docs/api_schema_parser.py \
    --download 1.28 1.29 1.30 1.31 \
    --generate-nix \
    --output /tmp/check.nix
  nix-instantiate --parse /tmp/check.nix || exit 1
fi
```

## Maintenance Calendar

| Task | Frequency | Command |
|------|-----------|---------|
| Update for new K8s patch | Weekly | `--download 1.28 1.29 1.30 1.31` |
| Add new minor version | Monthly (K8s release) | Add version to download list |
| Validate existing versions | Monthly | `--download 1.28 --parse /local/swagger.json` |
| Add new CRD type | As needed | Edit EXTENDED_KINDS |

## Getting Help

### Check Documentation

- Full guide: `docs/API_SCHEMA_PARSER.md`
- Implementation details: `docs/API_SCHEMA_PARSER_IMPLEMENTATION.md`
- Troubleshooting: See below

### Debug Output

Run with stderr to see detailed messages:

```bash
python3 docs/api_schema_parser.py \
  --download 1.28 \
  --generate-nix 2>&1 | tee debug.log
```

### File Issues

If you find bugs, please report with:
1. Command that failed
2. Output/error message
3. Kubernetes version you were using
4. Python version: `python3 --version`

## FAQ

**Q: How often should I run this?**  
A: When Kubernetes releases new versions (typically monthly). Subscribe to [K8s releases](https://github.com/kubernetes/kubernetes/releases).

**Q: Does it work offline?**  
A: Only for `--parse` mode. `--download` requires GitHub access.

**Q: Can I customize which resources are tracked?**  
A: Yes! Edit CORE_KINDS or EXTENDED_KINDS in the script.

**Q: What if GitHub is down?**  
A: Use `--parse` with a local OpenAPI spec if available.

**Q: Can I run this in CI/CD?**  
A: Yes! See GitHub Actions example above.

**Q: How long does it take?**  
A: ~30-60 seconds per version (mostly network I/O).

**Q: Does it require authentication?**  
A: No, uses public GitHub repository.

**Q: Can I modify the generated file?**  
A: Not recommended - regenerate instead. Manual edits will be overwritten.

## Next Steps

1. **Try it:** `python3 docs/api_schema_parser.py --help`
2. **Generate:** `python3 docs/api_schema_parser.py --download 1.31 --generate-nix`
3. **Commit:** Use in your workflows
4. **Automate:** Set up scheduled regeneration

## See Also

- [API Schema Parser Implementation](./API_SCHEMA_PARSER_IMPLEMENTATION.md)
- [Kubernetes API Documentation](https://kubernetes.io/docs/reference/)
- [OpenAPI Specification](https://spec.openapis.org/)

---

**Questions?** Check the troubleshooting section above or review the detailed implementation guide.
