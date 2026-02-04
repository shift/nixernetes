# Nixernetes CLI Reference

Complete reference for the Nixernetes command-line tool.

## Installation

The CLI is included in the `bin/` directory:

```bash
# Add to PATH
export PATH="./bin:$PATH"

# Or run directly
./bin/nixernetes --help
```

## Commands

### validate

Validate Nixernetes configuration and module syntax.

```bash
nixernetes validate
```

**What it does:**
- Checks `flake.nix` syntax
- Validates all module files
- Evaluates modules for errors
- Reports any issues

**Example:**
```bash
$ nixernetes validate
Running Nixernetes validation...
✓ Checking flake.nix...
running 24 flake checks...
✓ Checking module syntax...
Found 35 modules
✓ Evaluating modules...
  - kubernetes-core... OK
  - batch-processing... OK
  ...
✓ All validations passed!
```

### init

Initialize a new Nixernetes project.

```bash
nixernetes init [project-name]
```

**Creates:**
- `flake.nix` - Project definition
- `.envrc` - direnv configuration
- `config/main.nix` - Main configuration file
- `modules/` - Directory for custom modules

**Example:**
```bash
$ nixernetes init my-platform
Initializing Nixernetes project: my-platform
✓ Project initialized in my-platform

Next steps:
  cd my-platform
  direnv allow
  nix flake update
```

### generate

Generate Kubernetes YAML from Nixernetes configuration.

```bash
nixernetes generate [--config FILE] [--output FILE]
```

**Options:**
- `--config, -c` - Configuration file (default: `config/main.nix`)
- `--output, -o` - Output file (default: `resources.yaml`)

**Example:**
```bash
$ nixernetes generate --config config/main.nix --output deployment.yaml
Generating YAML from config/main.nix...
✓ Generated deployment.yaml
  Resources: 5
```

### deploy

Deploy configuration to Kubernetes cluster.

```bash
nixernetes deploy [--config FILE] [--namespace NAMESPACE] [--dry-run]
```

**Options:**
- `--config, -c` - Configuration file (default: `config/main.nix`)
- `--namespace, -n` - Kubernetes namespace (default: `default`)
- `--dry-run` - Show what would be deployed without making changes

**Example:**
```bash
$ nixernetes deploy --config config/production.nix --namespace prod --dry-run
Deploying from config/production.nix to namespace prod...
(DRY RUN - no changes will be applied)
Generating YAML from config/production.nix...
✓ Generated resources.yaml
  Resources: 12

deployment.apps/myapp created (dry run)
service/myapp created (dry run)
...
```

### test

Run Nixernetes test suite.

```bash
nixernetes test
```

**Runs:**
- Integration tests
- Module validation
- Flake checks

**Example:**
```bash
$ nixernetes test
Running Nixernetes tests...
✓ Running integration tests...
✓ All tests passed!
```

### list

List available modules.

```bash
nixernetes list
```

**Shows:**
- Module names
- File sizes
- Total count

**Example:**
```bash
$ nixernetes list
Available Nixernetes modules:

  api-gateway                      (18452 bytes)
  advanced-orchestration           (15678 bytes)
  batch-processing                 (22341 bytes)
  compliance                       (19876 bytes)
  compliance-enforcement           (21345 bytes)
  ...

Total: 35 modules
```

### docs

Browse module documentation.

```bash
nixernetes docs [MODULE_NAME]
```

**Without module name:** Lists available documentation
**With module name:** Opens documentation in `less` pager

**Example:**
```bash
$ nixernetes docs
Available documentation:

  - API_GATEWAY
  - BATCH_PROCESSING
  - DATABASE_MANAGEMENT
  - EVENT_PROCESSING
  ...

Run 'nixernetes docs MODULE_NAME' to view module documentation

$ nixernetes docs BATCH_PROCESSING
# Opens BATCH_PROCESSING.md in less
```

## Usage Patterns

### Initialize and Deploy New Project

```bash
# Create project
nixernetes init my-app
cd my-app

# Enable dev environment
direnv allow

# Edit configuration
vim config/main.nix

# Validate
nixernetes validate

# Test deployment
nixernetes deploy --dry-run

# Deploy
nixernetes deploy
```

### Develop Multi-Environment Setup

```bash
# Create base configuration
cp config/main.nix config/base.nix

# Create environment-specific configs
cp config/base.nix config/development.nix
cp config/base.nix config/staging.nix
cp config/base.nix config/production.nix

# Deploy to development
nixernetes deploy --config config/development.nix --namespace dev

# Deploy to staging
nixernetes deploy --config config/staging.nix --namespace staging

# Deploy to production
nixernetes deploy --config config/production.nix --namespace prod --dry-run
# Review output, then:
nixernetes deploy --config config/production.nix --namespace prod
```

### Troubleshoot Configuration

```bash
# Validate configuration
nixernetes validate

# Generate and review YAML
nixernetes generate --output review.yaml
cat review.yaml

# Test in dry-run mode
nixernetes deploy --dry-run

# Check cluster state
kubectl get all -A
```

### Browse Documentation

```bash
# Find module for your use case
nixernetes list

# Read documentation
nixernetes docs BATCH_PROCESSING

# See examples
ls src/examples/batch-processing-example.nix
```

## Troubleshooting

### Error: Could not find project root

**Solution:** Run from the project directory containing `flake.nix`

```bash
# Wrong
cd /tmp && nixernetes validate

# Right
cd /path/to/nixernetes/project && nixernetes validate
```

### Error: nix command not found

**Solution:** Ensure Nix is installed and in PATH

```bash
# Check installation
which nix
nix --version

# Install if needed
curl -L https://nixos.org/nix/install | sh
```

### Error: kubectl not found

**Solution:** Enter dev environment

```bash
direnv allow
# or
nix develop
```

### Error: Config file not found

**Solution:** Verify file path

```bash
# Use absolute path
nixernetes generate --config $(pwd)/config/main.nix

# Or from project root
cd /path/to/project
nixernetes generate
```

## Integration with CI/CD

### GitHub Actions

```yaml
name: Nixernetes Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - uses: cachix/install-nix-action@v22
      
      - name: Validate
        run: ./bin/nixernetes validate
      
      - name: Test
        run: ./bin/nixernetes test
      
      - name: Deploy
        run: ./bin/nixernetes deploy --namespace production
        if: github.ref == 'refs/heads/main'
```

### GitLab CI

```yaml
stages:
  - validate
  - deploy

validate:
  stage: validate
  script:
    - ./bin/nixernetes validate
    - ./bin/nixernetes test

deploy:
  stage: deploy
  script:
    - ./bin/nixernetes deploy --namespace production
  only:
    - main
```

## Advanced Usage

### Custom Project Structure

```
my-platform/
├── flake.nix
├── config/
│   ├── base.nix           # Shared config
│   ├── development.nix
│   ├── staging.nix
│   └── production.nix
├── modules/
│   ├── networking.nix     # Custom modules
│   ├── databases.nix
│   └── monitoring.nix
└── scripts/
    ├── deploy.sh
    └── validate.sh
```

### Scripted Deployments

```bash
#!/bin/bash

set -e

ENVIRONMENT=${1:-staging}
CONFIG="config/${ENVIRONMENT}.nix"

echo "Validating $ENVIRONMENT..."
nixernetes validate

echo "Generating YAML..."
nixernetes generate --config $CONFIG

echo "Deploying to $ENVIRONMENT..."
nixernetes deploy --config $CONFIG --namespace $ENVIRONMENT --dry-run

read -p "Continue with deployment? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    nixernetes deploy --config $CONFIG --namespace $ENVIRONMENT
fi
```

## CLI Roadmap

Planned enhancements:

- `diff` - Show changes before deployment
- `rollback` - Revert to previous configuration
- `scale` - Adjust replica counts
- `logs` - Stream pod logs
- `exec` - Execute commands in pods
- `port-forward` - Local port forwarding
- `version` - Display framework and CLI versions
- `upgrade` - Update to new framework version

