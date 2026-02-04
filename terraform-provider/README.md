# Terraform Provider for Nixernetes

A Terraform provider for managing Nixernetes deployments, configurations, and projects. This provider enables infrastructure-as-code management of your Nixernetes infrastructure.

## Requirements

- [Terraform](https://www.terraform.io/downloads.html) >= 1.0
- [Go](https://golang.org/doc/install) 1.21+ (for building from source)
- Nixernetes API server with endpoint, username, and password

## Installation

### Using Pre-built Binaries

1. Download the latest release from GitHub
2. Extract the binary to your Terraform plugins directory:
   ```bash
   mkdir -p ~/.terraform.d/plugins/registry.terraform.io/anomalyco/nixernetes/1.0.0/linux_amd64
   cp terraform-provider-nixernetes_v1.0.0_linux_amd64 \
     ~/.terraform.d/plugins/registry.terraform.io/anomalyco/nixernetes/1.0.0/linux_amd64/terraform-provider-nixernetes_v1.0.0
   chmod +x ~/.terraform.d/plugins/registry.terraform.io/anomalyco/nixernetes/1.0.0/linux_amd64/terraform-provider-nixernetes_v1.0.0
   ```

### Building from Source

```bash
# Clone the repository
git clone https://github.com/anomalyco/terraform-provider-nixernetes.git
cd terraform-provider-nixernetes

# Build using make
make dev

# Or build manually
go mod download
go build -o terraform-provider-nixernetes_v1.0.0
```

## Configuration

Configure the provider with your Nixernetes API endpoint and credentials:

```hcl
terraform {
  required_providers {
    nixernetes = {
      source  = "anomalyco/nixernetes"
      version = "~> 1.0"
    }
  }
}

provider "nixernetes" {
  endpoint = "https://api.nixernetes.example.com"
  username = var.nixernetes_username
  password = var.nixernetes_password
}
```

### Authentication

You can provide credentials in multiple ways:

#### 1. Provider Configuration (Highest Priority)
```hcl
provider "nixernetes" {
  endpoint = "https://api.example.com"
  username = "admin"
  password = "secret"
}
```

#### 2. Environment Variables
```bash
export NIXERNETES_ENDPOINT="https://api.example.com"
export NIXERNETES_USERNAME="admin"
export NIXERNETES_PASSWORD="secret"
terraform apply
```

#### 3. Terraform Variables
```hcl
variable "nixernetes_endpoint" {
  description = "Nixernetes API endpoint"
  type        = string
}

variable "nixernetes_username" {
  description = "Nixernetes API username"
  type        = string
  sensitive   = true
}

variable "nixernetes_password" {
  description = "Nixernetes API password"
  type        = string
  sensitive   = true
}

provider "nixernetes" {
  endpoint = var.nixernetes_endpoint
  username = var.nixernetes_username
  password = var.nixernetes_password
}
```

## Resources

### nixernetes_config

Manages a Nixernetes configuration deployment.

#### Example Usage
```hcl
resource "nixernetes_config" "example" {
  name          = "my-config"
  configuration = file("${path.module}/config.nix")
  environment   = "production"
}
```

#### Argument Reference
- `name` (Required) - Configuration name
- `configuration` (Required) - Nix configuration content
- `environment` (Optional) - Deployment environment (development, staging, production)

#### Attribute Reference
- `id` - Configuration ID
- `created_at` - Creation timestamp
- `updated_at` - Last update timestamp

### nixernetes_module

Manages a Nixernetes module instance.

#### Example Usage
```hcl
resource "nixernetes_module" "api" {
  name      = "api-service"
  image     = "myregistry.azurecr.io/api:latest"
  replicas  = 3
  namespace = "default"
}
```

#### Argument Reference
- `name` (Required) - Module instance name
- `image` (Required) - Container image
- `replicas` (Optional) - Number of replicas (default: 1)
- `namespace` (Optional) - Kubernetes namespace (default: default)

#### Attribute Reference
- `id` - Module instance ID
- `created_at` - Creation timestamp

### nixernetes_project

Manages a Nixernetes project.

#### Example Usage
```hcl
resource "nixernetes_project" "main" {
  name        = "my-project"
  description = "Main production project"
}
```

#### Argument Reference
- `name` (Required) - Project name
- `description` (Optional) - Project description

#### Attribute Reference
- `id` - Project ID
- `status` - Project status
- `created_at` - Creation timestamp
- `updated_at` - Last update timestamp

## Data Sources

### nixernetes_modules

Fetches the list of available Nixernetes modules.

#### Example Usage
```hcl
data "nixernetes_modules" "available" {}

output "available_modules" {
  value = data.nixernetes_modules.available.modules
}
```

#### Attribute Reference
- `modules` - List of available modules with:
  - `id` - Module ID
  - `name` - Module name
  - `description` - Module description
  - `version` - Module version

### nixernetes_projects

Fetches the list of Nixernetes projects.

#### Example Usage
```hcl
data "nixernetes_projects" "all" {}

output "projects" {
  value = data.nixernetes_projects.all.projects
}
```

#### Attribute Reference
- `projects` - List of projects with:
  - `id` - Project ID
  - `name` - Project name
  - `status` - Project status

## Complete Example

```hcl
terraform {
  required_providers {
    nixernetes = {
      source  = "anomalyco/nixernetes"
      version = "~> 1.0"
    }
  }
}

provider "nixernetes" {
  endpoint = var.api_endpoint
  username = var.api_username
  password = var.api_password
}

# Create a project
resource "nixernetes_project" "prod" {
  name        = "production"
  description = "Production environment"
}

# Get available modules
data "nixernetes_modules" "available" {}

# Deploy a configuration
resource "nixernetes_config" "app" {
  name          = "app-config"
  configuration = file("${path.module}/app.nix")
  environment   = "production"
}

# Deploy a module
resource "nixernetes_module" "web" {
  name      = "web-server"
  image     = "nginx:latest"
  replicas  = 3
  namespace = "default"
}

# Output the created resources
output "project_id" {
  value = nixernetes_project.prod.id
}

output "config_id" {
  value = nixernetes_config.app.id
}

output "module_id" {
  value = nixernetes_module.web.id
}
```

## Development

### Building

```bash
# Download dependencies
go mod download

# Build for current OS
make build

# Build for all platforms
make build-all
```

### Testing

```bash
# Run unit tests
make test

# Run acceptance tests (requires Nixernetes API)
make testacc

# Format and lint
make fmt
make lint
```

### Project Structure

```
terraform-provider-nixernetes/
├── main.go              # Provider entry point
├── provider.go          # Provider configuration
├── resources.go         # Resource implementations (config, module, project)
├── data_sources.go      # Data source implementations (modules, projects)
├── client.go            # HTTP client for API communication
├── go.mod              # Go module definition
├── Makefile            # Build and development tasks
└── README.md           # This file
```

## API Reference

### HTTP Methods

All API calls use basic authentication (username:password).

#### POST /configs
Create a new configuration.
- Body: `{ "name": "string", "configuration": "string", "environment": "string" }`
- Response: `{ "id": "string", "created_at": "timestamp", "updated_at": "timestamp" }`

#### GET /configs/{id}
Read a configuration.
- Response: `{ "id": "string", "name": "string", "configuration": "string", "environment": "string", "updated_at": "timestamp" }`

#### PUT /configs/{id}
Update a configuration.
- Body: `{ "name": "string", "configuration": "string", "environment": "string" }`
- Response: `{ "updated_at": "timestamp" }`

#### DELETE /configs/{id}
Delete a configuration.
- Response: `{}`

#### POST /modules
Create a new module instance.
- Body: `{ "name": "string", "replicas": "integer", "image": "string", "namespace": "string" }`
- Response: `{ "id": "string", "created_at": "timestamp" }`

#### GET /modules/{id}
Read a module instance.
- Response: `{ "id": "string", "name": "string", "replicas": "integer", "image": "string", "namespace": "string" }`

#### PUT /modules/{id}
Update a module instance.
- Body: `{ "name": "string", "replicas": "integer", "image": "string", "namespace": "string" }`
- Response: `{}`

#### DELETE /modules/{id}
Delete a module instance.
- Response: `{}`

#### GET /modules
List all available modules.
- Response: `{ "modules": [ { "id": "string", "name": "string", "description": "string", "version": "string" } ] }`

#### POST /projects
Create a new project.
- Body: `{ "name": "string", "description": "string" }`
- Response: `{ "id": "string", "status": "string", "created_at": "timestamp", "updated_at": "timestamp" }`

#### GET /projects/{id}
Read a project.
- Response: `{ "id": "string", "name": "string", "description": "string", "status": "string", "updated_at": "timestamp" }`

#### PUT /projects/{id}
Update a project.
- Body: `{ "name": "string", "description": "string" }`
- Response: `{ "updated_at": "timestamp" }`

#### DELETE /projects/{id}
Delete a project.
- Response: `{}`

#### GET /projects
List all projects.
- Response: `{ "projects": [ { "id": "string", "name": "string", "status": "string" } ] }`

## Error Handling

The provider handles common API errors and returns descriptive error messages:

- **4xx errors**: Client errors (invalid input, authentication failures)
- **5xx errors**: Server errors (API failures)

All error responses include:
- HTTP status code
- Error message from the API or raw response body
- Terraform diagnostic messages

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines.

## License

Mozilla Public License v2.0 - see [LICENSE](../LICENSE) for details.

## Support

For issues, feature requests, or questions:
- GitHub Issues: https://github.com/anomalyco/terraform-provider-nixernetes/issues
- Documentation: https://github.com/anomalyco/nixernetes/docs
- Community: See [COMMUNITY.md](../COMMUNITY.md)
