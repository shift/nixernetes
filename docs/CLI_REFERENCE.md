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

### template

Manage and use pre-built deployment templates.

```bash
nixernetes template [list|show|create] [options]
```

**Subcommands:**

#### list
List all available templates with descriptions.

```bash
nixernetes template list
```

Shows templates like:
- `simple-web` - Single container with database
- `microservices` - Multi-service architecture
- `static-site` - Static site hosting
- `minimal` - Minimal single container
- `ml-pipeline` - Machine learning pipeline
- `realtime-chat` - Real-time chat application
- `iot-pipeline` - IoT data collection pipeline

#### show
Display detailed information about a template.

```bash
nixernetes template show microservices
```

**Example Output:**
```
Template: microservices
Description: Complete microservices architecture with multiple services
Services: frontend, api, worker
Infrastructure: PostgreSQL, Redis, RabbitMQ
Version: 1.0
```

#### create
Create a new project from a template.

```bash
nixernetes template create <template-name> [project-name] [options]
```

**Options:**
- `--output, -o` - Output directory
- `--with-examples` - Include example configurations
- `--skip-git` - Skip git initialization

**Example:**
```bash
$ nixernetes template create microservices my-app --with-examples
Creating project from microservices template...
✓ Project created in my-app/
✓ Configuration files generated
✓ Example code created

Next steps:
  cd my-app
  direnv allow
  nixernetes validate
```

### generate-project

Generate a complete project boilerplate with flake.nix and configurations.

```bash
nixernetes generate-project <project-name> [options]
```

**Options:**
- `--template <template>` - Use specific template
- `--description <text>` - Project description
- `--author <name>` - Author name
- `--with-tests` - Include test configuration
- `--with-ci` - Include CI/CD workflows

**Example:**
```bash
$ nixernetes generate-project my-platform --template microservices --with-ci
Generating project boilerplate...
✓ Created flake.nix
✓ Created config/ directory with examples
✓ Created .github/workflows/ with CI/CD
✓ Created tests/ with example tests

Project ready at: my-platform/
```

## New Commands (v1.2+)

### scale

Adjust replica counts for deployments.

```bash
nixernetes scale <deployment> <replicas> [--namespace NAMESPACE]
```

**Example:**
```bash
$ nixernetes scale api 5
Scaling api to 5 replicas...
✓ Deployment scaled
```

### logs

Stream logs from deployments and pods.

```bash
nixernetes logs <deployment> [--follow] [--tail N]
```

**Options:**
- `--follow, -f` - Follow log output (like tail -f)
- `--tail <N>` - Show last N lines
- `--since <duration>` - Show logs since duration (5m, 1h, etc)
- `--container <name>` - Specific container
- `--previous` - Show previous container logs

**Example:**
```bash
$ nixernetes logs api -f --tail 50
Streaming logs from api deployment...
[2024-02-04 10:15:23] Starting API server
[2024-02-04 10:15:24] Connected to database
...
```

### exec

Execute commands in running containers.

```bash
nixernetes exec <pod|deployment> <command> [--interactive] [--tty]
```

**Example:**
```bash
$ nixernetes exec api bash
Connected to pod api-5d4f7c2b9...
bash-5.1$
```

### port-forward

Forward local port to pod.

```bash
nixernetes port-forward <pod|deployment> <local-port>:<pod-port>
```

**Example:**
```bash
$ nixernetes port-forward api 8080:5000
Forwarding localhost:8080 -> pod:5000
curl http://localhost:8080
```

### diff

Show configuration differences before deployment.

```bash
nixernetes diff [--config FILE] [--namespace NAMESPACE]
```

**Example:**
```bash
$ nixernetes diff
Calculating differences...

+ deployment.apps/api
  - replicas: 1 -> 3
  - image: myrepo/api:v1.0 -> myrepo/api:v1.1

- service/old-service (will be removed)

? pod/pending (status unknown)
```

### rollback

Revert to previous configuration.

```bash
nixernetes rollback [--steps N] [--config FILE]
```

**Example:**
```bash
$ nixernetes rollback --steps 1
Rolling back to previous configuration...
✓ Rollback complete
```

### version

Display version information.

```bash
nixernetes version [--detail]
```

**Example:**
```bash
$ nixernetes version
Nixernetes CLI v1.2.0
Framework: v1.2.0
Modules: 35
Last updated: 2024-02-04
```

### upgrade

Update Nixernetes to latest version.

```bash
nixernetes upgrade [--to-version VERSION] [--dry-run]
```

**Example:**
```bash
$ nixernetes upgrade
Checking for updates...
✓ Update available: v1.2.1
✓ Downloaded (12.5 MB)
✓ Installation complete
```

## CLI Roadmap

Implemented features:
- [x] `validate` - Configuration validation
- [x] `init` - Project initialization
- [x] `generate` - YAML generation
- [x] `deploy` - Kubernetes deployment
- [x] `template` - Template management
- [x] `generate-project` - Project generation
- [x] `logs` - Log streaming
- [x] `exec` - Container execution
- [x] `port-forward` - Port forwarding
- [x] `diff` - Configuration diffing
- [x] `version` - Version information

Planned for future releases:
- `rollback` - Configuration rollback
- `scale` - Dynamic scaling
- `status` - Deployment status
- `delete` - Resource deletion
- `upgrade` - Framework updates
- Shell completion (bash, zsh, fish)
- Config file support
- Interactive mode

