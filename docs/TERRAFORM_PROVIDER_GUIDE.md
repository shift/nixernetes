# Terraform Provider for Nixernetes - Development Guide

This guide outlines building a Terraform provider for Nixernetes infrastructure management.

## Overview

The Terraform provider enables infrastructure-as-code management of:
- Kubernetes resources via Nixernetes configurations
- Multi-environment deployments
- Resource versioning and state management
- GitOps workflows with Terraform

## Architecture

```
┌─────────────────────────────────┐
│   Terraform Configuration       │
│   (*.tf files with HCL)        │
└──────────────┬──────────────────┘
               │
     ┌─────────▼──────────┐
     │ Terraform Core    │
     │ (state, planning) │
     └─────────┬──────────┘
               │
     ┌─────────▼──────────────────────┐
     │ Nixernetes Terraform Provider  │
     │                                │
     │ - Resource: nixernetes_config  │
     │ - Resource: nixernetes_module  │
     │ - Data source: nixernetes_*    │
     └─────────┬──────────────────────┘
               │
     ┌─────────▼──────────────────┐
     │ Nixernetes CLI             │
     │ (nix derive, validate, etc) │
     └────────────────────────────┘
```

## Features

### Resources

1. **nixernetes_config** - Deploy Nixernetes configuration
2. **nixernetes_module** - Module instantiation
3. **nixernetes_project** - Project management
4. **nixernetes_deployment** - Kubernetes deployment

### Data Sources

1. **nixernetes_modules** - List available modules
2. **nixernetes_module** - Module details
3. **nixernetes_generated_yaml** - Generated manifests

## Project Structure

```
terraform-provider-nixernetes/
├── internal/
│   ├── provider/
│   │   ├── provider.go
│   │   └── provider_test.go
│   ├── services/
│   │   ├── nixernetes_service.go
│   │   ├── validation_service.go
│   │   └── kubernetes_service.go
│   ├── resources/
│   │   ├── config_resource.go
│   │   ├── config_resource_test.go
│   │   ├── module_resource.go
│   │   └── module_resource_test.go
│   └── datasources/
│       ├── modules_datasource.go
│       ├── modules_datasource_test.go
│       ├── module_datasource.go
│       └── module_datasource_test.go
├── examples/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── docs/
│   ├── data-sources/
│   │   ├── modules.md
│   │   └── module.md
│   └── resources/
│       ├── config.md
│       └── module.md
├── main.go
├── go.mod
├── go.sum
├── Makefile
└── terraform.registry.json
```

## Implementation

### Part 1: Project Setup

#### Create main.go

```go
// main.go
package main

import (
	"context"
	"flag"
	"log"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"
	"github.com/nixernetes/terraform-provider-nixernetes/internal/provider"
)

// Run the provider
func main() {
	var debug bool
	flag.BoolVar(&debug, "debug", false, "set to true to run the provider with support for debuggers")
	flag.Parse()

	opts := providerserver.ServeOpts{
		Address: "registry.terraform.io/nixernetes/nixernetes",
		Debug:   debug,
	}

	err := providerserver.Serve(context.Background(), func() provider.Provider {
		return provider.NewProvider()
	}, opts)

	if err != nil {
		log.Fatalf("Error serving provider, got error: %s", err)
	}
}
```

#### Create go.mod

```
module github.com/nixernetes/terraform-provider-nixernetes

go 1.20

require (
	github.com/hashicorp/terraform-plugin-framework v1.3.0
	github.com/hashicorp/terraform-plugin-go v0.16.0
	github.com/hashicorp/terraform-plugin-log v0.8.0
	github.com/hashicorp/terraform-plugin-sdk/v2 v2.28.0
)
```

### Part 2: Provider Definition

#### Create provider.go

```go
// internal/provider/provider.go
package provider

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

var _ provider.Provider = (*NixernetesProvider)(nil)

type NixernetesProvider struct {
	// version is set to the provider version on release, "dev" when the
	// provider is built and ran locally, and "test" when running testing.
	version string
}

type NixernetesProviderModel struct {
	NixPath types.String `tfsdk:"nix_path"`
	Config  types.String `tfsdk:"config"`
}

func (p *NixernetesProvider) Metadata(ctx context.Context, req provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = "nixernetes"
	resp.Version = p.version
}

func (p *NixernetesProvider) Schema(ctx context.Context, req provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema = schema.Schema{
		Attributes: map[string]schema.Attribute{
			"nix_path": schema.StringAttribute{
				MarkdownDescription: "Path to nix executable",
				Optional:            true,
			},
			"config": schema.StringAttribute{
				MarkdownDescription: "Nixernetes configuration",
				Optional:            true,
			},
		},
	}
}

func (p *NixernetesProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
	var config NixernetesProviderModel
	resp.Diagnostics.Append(req.Config.Get(ctx, &config)...)

	if resp.Diagnostics.HasError() {
		return
	}

	// Configuration values are now available
	// Use them to configure provider clients
}

func (p *NixernetesProvider) Resources(ctx context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		NewConfigResource,
		NewModuleResource,
	}
}

func (p *NixernetesProvider) DataSources(ctx context.Context) []func() datasource.DataSource {
	return []func() datasource.DataSource{
		NewModulesDataSource,
		NewModuleDataSource,
	}
}

func NewProvider() provider.Provider {
	return &NixernetesProvider{}
}
```

### Part 3: Resources

#### Create config_resource.go

```go
// internal/resources/config_resource.go
package resources

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

type ConfigResourceModel struct {
	Id             types.String `tfsdk:"id"`
	Name           types.String `tfsdk:"name"`
	Configuration  types.String `tfsdk:"configuration"`
	GeneratedYaml  types.String `tfsdk:"generated_yaml"`
	DeploymentId   types.String `tfsdk:"deployment_id"`
	Environment    types.String `tfsdk:"environment"`
	Version        types.String `tfsdk:"version"`
}

func (r *ConfigResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Nixernetes configuration resource",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed: true,
			},
			"name": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "Configuration name",
			},
			"configuration": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "Nix configuration code",
			},
			"environment": schema.StringAttribute{
				Optional:            true,
				MarkdownDescription: "Environment (dev, staging, prod)",
			},
			"generated_yaml": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "Generated Kubernetes YAML",
			},
			"version": schema.StringAttribute{
				Optional:            true,
				Computed:            true,
				MarkdownDescription: "Configuration version",
			},
		},
	}
}

func (r *ConfigResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan ConfigResourceModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)

	// Generate Kubernetes YAML from Nixernetes config
	yaml, err := r.service.GenerateYAML(ctx, plan.Configuration.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Generation Error", err.Error())
		return
	}

	plan.GeneratedYaml = types.StringValue(yaml)
	plan.Id = types.StringValue("config-" + uuid.New().String())

	resp.Diagnostics.Append(resp.State.Set(ctx, &plan)...)
}

func (r *ConfigResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	// Read state
}

func (r *ConfigResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	// Update state
}

func (r *ConfigResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	// Delete resource
}
```

### Part 4: Data Sources

#### Create modules_datasource.go

```go
// internal/datasources/modules_datasource.go
package datasources

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

type ModulesDataSourceModel struct {
	Modules []ModuleInfo `tfsdk:"modules"`
}

type ModuleInfo struct {
	Name        types.String `tfsdk:"name"`
	Description types.String `tfsdk:"description"`
	Category    types.String `tfsdk:"category"`
	Builders    types.List   `tfsdk:"builders"`
}

func (d *ModulesDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Get list of available Nixernetes modules",
		Attributes: map[string]schema.Attribute{
			"modules": schema.ListNestedAttribute{
				Computed: true,
				NestedObject: schema.NestedAttributeObject{
					Attributes: map[string]schema.Attribute{
						"name": schema.StringAttribute{Computed: true},
						"description": schema.StringAttribute{Computed: true},
						"category": schema.StringAttribute{Computed: true},
						"builders": schema.ListAttribute{
							ElementType: types.StringType,
							Computed:    true,
						},
					},
				},
			},
		},
	}
}

func (d *ModulesDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var state ModulesDataSourceModel

	// Get modules from nixernetes CLI
	modules, err := d.service.GetModules(ctx)
	if err != nil {
		resp.Diagnostics.AddError("Read Error", err.Error())
		return
	}

	// Convert to model
	state.Modules = convertModules(modules)

	resp.Diagnostics.Append(resp.State.Set(ctx, &state)...)
}
```

## Usage Examples

### Basic Configuration

```hcl
# main.tf
terraform {
  required_providers {
    nixernetes = {
      source  = "nixernetes/nixernetes"
      version = "~> 1.0"
    }
  }
}

provider "nixernetes" {
  nix_path = "/usr/bin/nix"
}

resource "nixernetes_config" "web_app" {
  name = "my-web-app"
  configuration = file("${path.module}/config.nix")
  environment = "production"
}

output "generated_yaml" {
  value = nixernetes_config.web_app.generated_yaml
}
```

### With Kubernetes Provider

```hcl
# Deploy using generated YAML
provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_manifest" "deployment" {
  manifest = jsondecode(nixernetes_config.web_app.generated_yaml)
}
```

### Multiple Environments

```hcl
variable "environment" {
  type = string
}

resource "nixernetes_config" "app" {
  name = "app-${var.environment}"
  configuration = templatefile("${path.module}/config.nix", {
    env = var.environment
  })
  environment = var.environment
}

output "yaml" {
  value = nixernetes_config.app.generated_yaml
}
```

## Development Commands

```bash
# Install dependencies
go mod download

# Build provider
go install

# Run tests
go test ./...

# Build for release
go build -o terraform-provider-nixernetes

# Generate docs
go generate ./...
```

## Testing

```go
// config_resource_test.go
package resources_test

import (
	"testing"

	"github.com/hashicorp/terraform-plugin-testing/helper/acctest"
	"github.com/hashicorp/terraform-plugin-testing/helper/resource"
)

func TestAccConfigResource(t *testing.T) {
	name := acctest.RandomWithPrefix("test")

	resource.Test(t, resource.TestCase{
		ProtoV6ProviderFactories: testAccProtoV6ProviderFactories,
		Steps: []resource.TestStep{
			// Create and Read
			{
				Config: testAccConfigResourceConfig(name),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttr("nixernetes_config.test", "name", name),
					resource.TestCheckResourceAttrSet("nixernetes_config.test", "generated_yaml"),
				),
			},
		},
	})
}

func testAccConfigResourceConfig(name string) string {
	return fmt.Sprintf(`
resource "nixernetes_config" "test" {
  name = %[1]q
  configuration = "{ }"
}
`, name)
}
```

## Publishing

### Registry

1. **Sign up** at https://registry.terraform.io
2. **Connect GitHub** account
3. **Create repository** with naming:
   `terraform-provider-nixernetes`
4. **Push releases** with proper Git tags:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
5. **Registry automatically indexes** new releases
6. **Documentation** auto-generated from `docs/` directory

### Directory Structure for Docs

```
docs/
├── index.md                    # Provider overview
├── resources/
│   ├── config.md              # Resource documentation
│   └── module.md
└── data-sources/
    ├── modules.md
    └── module.md
```

## CI/CD Integration

### GitHub Actions Workflow

```yaml
name: Provider Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: 1.20
      
      - run: go test -v -cover ./...
      - run: go build

  docs:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: go generate ./...
      - run: git diff --exit-code
```

## Success Metrics

- ✅ 100% resource coverage (create, read, update, delete)
- ✅ 100% test coverage
- ✅ Complete documentation
- ✅ Published on Terraform Registry
- ✅ <30 second resource creation
- ✅ Support for multiple Kubernetes clusters
- ✅ Proper state management and drift detection

## Getting Started

1. Set up Go development environment
2. Use template above for main.go and provider.go
3. Implement ConfigResource
4. Add ModulesDataSource
5. Write tests for each component
6. Build and test locally
7. Publish to GitHub
8. Submit to Terraform Registry

---

This provider enables Terraform users to leverage Nixernetes
for Kubernetes infrastructure management, bridging the Nix
and Terraform ecosystems.

