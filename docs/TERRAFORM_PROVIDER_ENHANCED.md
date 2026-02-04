# Terraform Provider Development - Complete Implementation Guide

Full Go implementation for Terraform Provider for Nixernetes with resources, data sources, and examples.

## Project Structure

```
terraform-provider-nixernetes/
├── main.go
├── provider/
│   ├── provider.go
│   ├── resources.go
│   ├── datasources.go
│   └── utils.go
├── examples/
│   ├── resources/
│   │   ├── config/
│   │   └── deployment/
│   └── data-sources/
├── docs/
│   ├── index.md
│   ├── resources/
│   └── data-sources/
├── tests/
│   ├── provider_test.go
│   └── resources_test.go
├── go.mod
├── go.sum
├── Makefile
└── .github/
    └── workflows/
        ├── test.yml
        └── release.yml
```

## Main Entry Point

Create `main.go`:

```go
package main

import (
	"context"
	"flag"
	"log"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"
	"terraform-provider-nixernetes/provider"
)

// Run the Terraform Provider
func main() {
	var debug bool

	opts := providerserver.ServeOpts{
		Address: "registry.terraform.io/nixernetes/nixernetes",
		Debug:   debug,
	}

	flag.BoolVar(&debug, "debug", false, "set to true to run the provider with support for debuggers like delve")
	flag.Parse()

	err := providerserver.Serve(context.Background(), provider.New(), opts)
	if err != nil {
		log.Fatal(err)
	}
}
```

## Provider Definition

Create `provider/provider.go`:

```go
package provider

import (
	"context"
	"os"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/path"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/provider/metaschema"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

const (
	version = "1.0.0"
)

var _ provider.Provider = &NixernetesProvider{}

type NixernetesProvider struct {
	version string
}

type NixernetesProviderModel struct {
	Endpoint types.String `tfsdk:"endpoint"`
	Username types.String `tfsdk:"username"`
	Password types.String `tfsdk:"password"`
}

func (p *NixernetesProvider) Metadata(ctx context.Context, req provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = "nixernetes"
	resp.Version = p.version
}

func (p *NixernetesProvider) Schema(ctx context.Context, req provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema = metaschema.Schema{
		Attributes: map[string]metaschema.Attribute{
			"endpoint": metaschema.StringAttribute{
				MarkdownDescription: "Nixernetes API endpoint. Can also be provided via NIXERNETES_ENDPOINT environment variable.",
				Optional:            true,
			},
			"username": metaschema.StringAttribute{
				MarkdownDescription: "Username for Nixernetes API. Can also be provided via NIXERNETES_USERNAME environment variable.",
				Optional:            true,
			},
			"password": metaschema.StringAttribute{
				MarkdownDescription: "Password for Nixernetes API. Can also be provided via NIXERNETES_PASSWORD environment variable.",
				Optional:            true,
				Sensitive:           true,
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
	if config.Endpoint.IsNull() {
		config.Endpoint = types.StringValue(os.Getenv("NIXERNETES_ENDPOINT"))
	}
	if config.Username.IsNull() {
		config.Username = types.StringValue(os.Getenv("NIXERNETES_USERNAME"))
	}
	if config.Password.IsNull() {
		config.Password = types.StringValue(os.Getenv("NIXERNETES_PASSWORD"))
	}

	// Make the config available during DataSource and Resource type Configure methods
	resp.DataSourceData = &config
	resp.ResourceData = &config
}

func (p *NixernetesProvider) Resources(ctx context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		NewConfigResource,
		NewModuleResource,
		NewProjectResource,
	}
}

func (p *NixernetesProvider) DataSources(ctx context.Context) []func() datasource.DataSource {
	return []func() datasource.DataSource{
		NewModulesDataSource,
		NewProjectsDataSource,
	}
}

func New() func() provider.Provider {
	return func() provider.Provider {
		return &NixernetesProvider{
			version: version,
		}
	}
}
```

## Resources Implementation

Create `provider/resources.go`:

```go
package provider

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

// ConfigResource defines the resource implementation
type ConfigResource struct {
	client *APIClient
}

// ConfigResourceModel describes the resource data model
type ConfigResourceModel struct {
	ID              types.String `tfsdk:"id"`
	Name            types.String `tfsdk:"name"`
	Configuration   types.String `tfsdk:"configuration"`
	Environment     types.String `tfsdk:"environment"`
	Namespace       types.String `tfsdk:"namespace"`
	GeneratedYAML   types.String `tfsdk:"generated_yaml"`
	DeploymentID    types.String `tfsdk:"deployment_id"`
	Status          types.String `tfsdk:"status"`
	CreatedAt       types.String `tfsdk:"created_at"`
}

func NewConfigResource() resource.Resource {
	return &ConfigResource{}
}

func (r *ConfigResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_config"
}

func (r *ConfigResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Manages a Nixernetes configuration deployment.",

		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "Configuration ID",
			},
			"name": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "Name of the Nixernetes configuration",
			},
			"configuration": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "Nix configuration content",
			},
			"environment": schema.StringAttribute{
				Optional:            true,
				MarkdownDescription: "Environment (dev, staging, prod)",
			},
			"namespace": schema.StringAttribute{
				Optional:            true,
				MarkdownDescription: "Kubernetes namespace",
			},
			"generated_yaml": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "Generated Kubernetes YAML",
			},
			"deployment_id": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "ID of the deployment",
			},
			"status": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "Deployment status",
			},
			"created_at": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "Creation timestamp",
			},
		},
	}
}

func (r *ConfigResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	// The provider data contains the configuration from the provider block
	providerConfig, ok := req.ProviderData.(*NixernetesProviderModel)
	if !ok {
		resp.Diagnostics.AddError(
			"Unexpected Resource Configure Type",
			fmt.Sprintf("Expected *NixernetesProviderModel, got: %T", req.ProviderData),
		)
		return
	}

	r.client = &APIClient{
		Endpoint: providerConfig.Endpoint.ValueString(),
		Username: providerConfig.Username.ValueString(),
		Password: providerConfig.Password.ValueString(),
	}
}

func (r *ConfigResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan ConfigResourceModel

	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	// Call API to create configuration
	config, err := r.client.CreateConfig(ctx, &ConfigRequest{
		Name:          plan.Name.ValueString(),
		Configuration: plan.Configuration.ValueString(),
		Environment:   plan.Environment.ValueString(),
		Namespace:     plan.Namespace.ValueString(),
	})
	if err != nil {
		resp.Diagnostics.AddError("Failed to create configuration", err.Error())
		return
	}

	plan.ID = types.StringValue(config.ID)
	plan.Status = types.StringValue(config.Status)
	plan.GeneratedYAML = types.StringValue(config.GeneratedYAML)
	plan.DeploymentID = types.StringValue(config.DeploymentID)
	plan.CreatedAt = types.StringValue(config.CreatedAt)

	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *ConfigResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state ConfigResourceModel

	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	// Call API to read configuration
	config, err := r.client.GetConfig(ctx, state.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Failed to read configuration", err.Error())
		return
	}

	state.Status = types.StringValue(config.Status)
	state.GeneratedYAML = types.StringValue(config.GeneratedYAML)

	resp.Diagnostics.Append(resp.State.Set(ctx, state)...)
}

func (r *ConfigResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan ConfigResourceModel

	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	// Call API to update configuration
	config, err := r.client.UpdateConfig(ctx, plan.ID.ValueString(), &ConfigRequest{
		Name:          plan.Name.ValueString(),
		Configuration: plan.Configuration.ValueString(),
		Environment:   plan.Environment.ValueString(),
		Namespace:     plan.Namespace.ValueString(),
	})
	if err != nil {
		resp.Diagnostics.AddError("Failed to update configuration", err.Error())
		return
	}

	plan.Status = types.StringValue(config.Status)
	plan.GeneratedYAML = types.StringValue(config.GeneratedYAML)

	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *ConfigResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state ConfigResourceModel

	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	err := r.client.DeleteConfig(ctx, state.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Failed to delete configuration", err.Error())
		return
	}

	// State is automatically removed
}

// ModuleResource for instantiating modules
type ModuleResource struct {
	client *APIClient
}

type ModuleResourceModel struct {
	ID          types.String `tfsdk:"id"`
	Name        types.String `tfsdk:"name"`
	ModuleType  types.String `tfsdk:"module_type"`
	Replicas    types.Int64  `tfsdk:"replicas"`
	ConfigID    types.String `tfsdk:"config_id"`
	Status      types.String `tfsdk:"status"`
}

func NewModuleResource() resource.Resource {
	return &ModuleResource{}
}

func (r *ModuleResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_module"
}

func (r *ModuleResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Manages a Nixernetes module instance.",

		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "Module instance ID",
			},
			"name": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "Name of the module instance",
			},
			"module_type": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "Type of module (e.g., postgresql, redis, nginx)",
			},
			"replicas": schema.Int64Attribute{
				Optional:            true,
				MarkdownDescription: "Number of replicas",
			},
			"config_id": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "ID of parent configuration",
			},
			"status": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "Module status",
			},
		},
	}
}

func (r *ModuleResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	providerConfig, ok := req.ProviderData.(*NixernetesProviderModel)
	if !ok {
		resp.Diagnostics.AddError("Unexpected Resource Configure Type", "Expected *NixernetesProviderModel")
		return
	}

	r.client = &APIClient{
		Endpoint: providerConfig.Endpoint.ValueString(),
		Username: providerConfig.Username.ValueString(),
		Password: providerConfig.Password.ValueString(),
	}
}

func (r *ModuleResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan ModuleResourceModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	module, err := r.client.CreateModule(ctx, &ModuleRequest{
		Name:       plan.Name.ValueString(),
		ModuleType: plan.ModuleType.ValueString(),
		Replicas:   int(plan.Replicas.ValueInt64()),
		ConfigID:   plan.ConfigID.ValueString(),
	})
	if err != nil {
		resp.Diagnostics.AddError("Failed to create module", err.Error())
		return
	}

	plan.ID = types.StringValue(module.ID)
	plan.Status = types.StringValue(module.Status)

	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *ModuleResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state ModuleResourceModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	module, err := r.client.GetModule(ctx, state.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Failed to read module", err.Error())
		return
	}

	state.Status = types.StringValue(module.Status)
	resp.Diagnostics.Append(resp.State.Set(ctx, state)...)
}

func (r *ModuleResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan ModuleResourceModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	module, err := r.client.UpdateModule(ctx, plan.ID.ValueString(), &ModuleRequest{
		Name:       plan.Name.ValueString(),
		ModuleType: plan.ModuleType.ValueString(),
		Replicas:   int(plan.Replicas.ValueInt64()),
		ConfigID:   plan.ConfigID.ValueString(),
	})
	if err != nil {
		resp.Diagnostics.AddError("Failed to update module", err.Error())
		return
	}

	plan.Status = types.StringValue(module.Status)
	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *ModuleResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state ModuleResourceModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	err := r.client.DeleteModule(ctx, state.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Failed to delete module", err.Error())
		return
	}
}

// ProjectResource for managing projects
type ProjectResource struct {
	client *APIClient
}

type ProjectResourceModel struct {
	ID          types.String `tfsdk:"id"`
	Name        types.String `tfsdk:"name"`
	Description types.String `tfsdk:"description"`
	Status      types.String `tfsdk:"status"`
}

func NewProjectResource() resource.Resource {
	return &ProjectResource{}
}

func (r *ProjectResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_project"
}

func (r *ProjectResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Manages a Nixernetes project.",

		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "Project ID",
			},
			"name": schema.StringAttribute{
				Required:            true,
				MarkdownDescription: "Project name",
			},
			"description": schema.StringAttribute{
				Optional:            true,
				MarkdownDescription: "Project description",
			},
			"status": schema.StringAttribute{
				Computed:            true,
				MarkdownDescription: "Project status",
			},
		},
	}
}

func (r *ProjectResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	providerConfig, ok := req.ProviderData.(*NixernetesProviderModel)
	if !ok {
		resp.Diagnostics.AddError("Unexpected Resource Configure Type", "Expected *NixernetesProviderModel")
		return
	}

	r.client = &APIClient{
		Endpoint: providerConfig.Endpoint.ValueString(),
		Username: providerConfig.Username.ValueString(),
		Password: providerConfig.Password.ValueString(),
	}
}

func (r *ProjectResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan ProjectResourceModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	project, err := r.client.CreateProject(ctx, &ProjectRequest{
		Name:        plan.Name.ValueString(),
		Description: plan.Description.ValueString(),
	})
	if err != nil {
		resp.Diagnostics.AddError("Failed to create project", err.Error())
		return
	}

	plan.ID = types.StringValue(project.ID)
	plan.Status = types.StringValue(project.Status)

	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *ProjectResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state ProjectResourceModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	project, err := r.client.GetProject(ctx, state.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Failed to read project", err.Error())
		return
	}

	state.Status = types.StringValue(project.Status)
	resp.Diagnostics.Append(resp.State.Set(ctx, state)...)
}

func (r *ProjectResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan ProjectResourceModel
	resp.Diagnostics.Append(req.Plan.Get(ctx, &plan)...)
	if resp.Diagnostics.HasError() {
		return
	}

	project, err := r.client.UpdateProject(ctx, plan.ID.ValueString(), &ProjectRequest{
		Name:        plan.Name.ValueString(),
		Description: plan.Description.ValueString(),
	})
	if err != nil {
		resp.Diagnostics.AddError("Failed to update project", err.Error())
		return
	}

	plan.Status = types.StringValue(project.Status)
	resp.Diagnostics.Append(resp.State.Set(ctx, plan)...)
}

func (r *ProjectResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state ProjectResourceModel
	resp.Diagnostics.Append(req.State.Get(ctx, &state)...)
	if resp.Diagnostics.HasError() {
		return
	}

	err := r.client.DeleteProject(ctx, state.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Failed to delete project", err.Error())
		return
	}
}
```

## Data Sources Implementation

Create `provider/datasources.go`:

```go
package provider

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

type ModulesDataSource struct {
	client *APIClient
}

type ModulesDataSourceModel struct {
	Modules []ModuleInfo `tfsdk:"modules"`
}

type ModuleInfo struct {
	Name        types.String `tfsdk:"name"`
	Description types.String `tfsdk:"description"`
	Category    types.String `tfsdk:"category"`
	Version     types.String `tfsdk:"version"`
}

func NewModulesDataSource() datasource.DataSource {
	return &ModulesDataSource{}
}

func (d *ModulesDataSource) Metadata(ctx context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_modules"
}

func (d *ModulesDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "List available Nixernetes modules.",

		Attributes: map[string]schema.Attribute{
			"modules": schema.ListNestedAttribute{
				Computed:            true,
				MarkdownDescription: "List of available modules",
				NestedObject: schema.NestedAttributeObject{
					Attributes: map[string]schema.Attribute{
						"name": schema.StringAttribute{
							Computed:            true,
							MarkdownDescription: "Module name",
						},
						"description": schema.StringAttribute{
							Computed:            true,
							MarkdownDescription: "Module description",
						},
						"category": schema.StringAttribute{
							Computed:            true,
							MarkdownDescription: "Module category",
						},
						"version": schema.StringAttribute{
							Computed:            true,
							MarkdownDescription: "Module version",
						},
					},
				},
			},
		},
	}
}

func (d *ModulesDataSource) Configure(ctx context.Context, req datasource.ConfigureRequest, resp *datasource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	providerConfig, ok := req.ProviderData.(*NixernetesProviderModel)
	if !ok {
		resp.Diagnostics.AddError("Unexpected DataSource Configure Type", "Expected *NixernetesProviderModel")
		return
	}

	d.client = &APIClient{
		Endpoint: providerConfig.Endpoint.ValueString(),
		Username: providerConfig.Username.ValueString(),
		Password: providerConfig.Password.ValueString(),
	}
}

func (d *ModulesDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var config ModulesDataSourceModel

	modules, err := d.client.ListModules(ctx)
	if err != nil {
		resp.Diagnostics.AddError("Failed to list modules", err.Error())
		return
	}

	for _, m := range modules {
		config.Modules = append(config.Modules, ModuleInfo{
			Name:        types.StringValue(m.Name),
			Description: types.StringValue(m.Description),
			Category:    types.StringValue(m.Category),
			Version:     types.StringValue(m.Version),
		})
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &config)...)
}

type ProjectsDataSource struct {
	client *APIClient
}

type ProjectsDataSourceModel struct {
	Projects []ProjectInfo `tfsdk:"projects"`
}

type ProjectInfo struct {
	ID          types.String `tfsdk:"id"`
	Name        types.String `tfsdk:"name"`
	Description types.String `tfsdk:"description"`
}

func NewProjectsDataSource() datasource.DataSource {
	return &ProjectsDataSource{}
}

func (d *ProjectsDataSource) Metadata(ctx context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_projects"
}

func (d *ProjectsDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "List Nixernetes projects.",

		Attributes: map[string]schema.Attribute{
			"projects": schema.ListNestedAttribute{
				Computed:            true,
				MarkdownDescription: "List of projects",
				NestedObject: schema.NestedAttributeObject{
					Attributes: map[string]schema.Attribute{
						"id": schema.StringAttribute{
							Computed:            true,
							MarkdownDescription: "Project ID",
						},
						"name": schema.StringAttribute{
							Computed:            true,
							MarkdownDescription: "Project name",
						},
						"description": schema.StringAttribute{
							Computed:            true,
							MarkdownDescription: "Project description",
						},
					},
				},
			},
		},
	}
}

func (d *ProjectsDataSource) Configure(ctx context.Context, req datasource.ConfigureRequest, resp *datasource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	providerConfig, ok := req.ProviderData.(*NixernetesProviderModel)
	if !ok {
		resp.Diagnostics.AddError("Unexpected DataSource Configure Type", "Expected *NixernetesProviderModel")
		return
	}

	d.client = &APIClient{
		Endpoint: providerConfig.Endpoint.ValueString(),
		Username: providerConfig.Username.ValueString(),
		Password: providerConfig.Password.ValueString(),
	}
}

func (d *ProjectsDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var config ProjectsDataSourceModel

	projects, err := d.client.ListProjects(ctx)
	if err != nil {
		resp.Diagnostics.AddError("Failed to list projects", err.Error())
		return
	}

	for _, p := range projects {
		config.Projects = append(config.Projects, ProjectInfo{
			ID:          types.StringValue(p.ID),
			Name:        types.StringValue(p.Name),
			Description: types.StringValue(p.Description),
		})
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &config)...)
}
```

## Terraform Configuration Examples

Create `examples/resources/config/resource.tf`:

```hcl
terraform {
  required_providers {
    nixernetes = {
      source  = "nixernetes/nixernetes"
      version = "~> 1.0"
    }
  }
}

provider "nixernetes" {
  endpoint = "http://localhost:3000"
  username = "admin"
  password = var.nixernetes_password
}

# Create a project
resource "nixernetes_project" "web_app" {
  name        = "web-app-project"
  description = "Web application infrastructure"
}

# Create a Nixernetes configuration
resource "nixernetes_config" "web_stack" {
  name          = "web-app-config"
  configuration = file("${path.module}/config.nix")
  environment   = "production"
  namespace     = "default"
}

# Add PostgreSQL module
resource "nixernetes_module" "database" {
  name        = "web-app-db"
  module_type = "postgresql"
  replicas    = 3
  config_id   = nixernetes_config.web_stack.id
}

# Add Nginx module
resource "nixernetes_module" "web_server" {
  name        = "web-app-nginx"
  module_type = "nginx"
  replicas    = 2
  config_id   = nixernetes_config.web_stack.id
}

# Output the generated YAML
output "generated_yaml" {
  value = nixernetes_config.web_stack.generated_yaml
}

output "deployment_id" {
  value = nixernetes_config.web_stack.deployment_id
}

output "status" {
  value = nixernetes_config.web_stack.status
}
```

Create `examples/data-sources/modules/data-source.tf`:

```hcl
data "nixernetes_modules" "available" {}

output "available_modules" {
  value = data.nixernetes_modules.available.modules
}

data "nixernetes_projects" "all" {}

output "projects" {
  value = data.nixernetes_projects.all.projects
}
```

## API Client

Create `provider/utils.go`:

```go
package provider

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
)

type APIClient struct {
	Endpoint string
	Username string
	Password string
	client   *http.Client
}

// Request/Response models
type ConfigRequest struct {
	Name          string `json:"name"`
	Configuration string `json:"configuration"`
	Environment   string `json:"environment"`
	Namespace     string `json:"namespace"`
}

type ConfigResponse struct {
	ID            string `json:"id"`
	Name          string `json:"name"`
	Configuration string `json:"configuration"`
	GeneratedYAML string `json:"generated_yaml"`
	DeploymentID  string `json:"deployment_id"`
	Status        string `json:"status"`
	CreatedAt     string `json:"created_at"`
}

type ModuleRequest struct {
	Name       string `json:"name"`
	ModuleType string `json:"module_type"`
	Replicas   int    `json:"replicas"`
	ConfigID   string `json:"config_id"`
}

type ModuleResponse struct {
	ID         string `json:"id"`
	Name       string `json:"name"`
	ModuleType string `json:"module_type"`
	Replicas   int    `json:"replicas"`
	ConfigID   string `json:"config_id"`
	Status     string `json:"status"`
}

type ProjectRequest struct {
	Name        string `json:"name"`
	Description string `json:"description"`
}

type ProjectResponse struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Description string `json:"description"`
	Status      string `json:"status"`
}

type ModuleRegistry struct {
	Name        string `json:"name"`
	Description string `json:"description"`
	Category    string `json:"category"`
	Version     string `json:"version"`
}

func (c *APIClient) CreateConfig(ctx context.Context, req *ConfigRequest) (*ConfigResponse, error) {
	return c.doRequest(ctx, "POST", "/api/configs", req)
}

func (c *APIClient) GetConfig(ctx context.Context, id string) (*ConfigResponse, error) {
	return c.doRequest(ctx, "GET", fmt.Sprintf("/api/configs/%s", id), nil)
}

func (c *APIClient) UpdateConfig(ctx context.Context, id string, req *ConfigRequest) (*ConfigResponse, error) {
	return c.doRequest(ctx, "PUT", fmt.Sprintf("/api/configs/%s", id), req)
}

func (c *APIClient) DeleteConfig(ctx context.Context, id string) error {
	_, err := c.doRequest(ctx, "DELETE", fmt.Sprintf("/api/configs/%s", id), nil)
	return err
}

func (c *APIClient) CreateModule(ctx context.Context, req *ModuleRequest) (*ModuleResponse, error) {
	return c.doRequest(ctx, "POST", "/api/modules", req)
}

func (c *APIClient) GetModule(ctx context.Context, id string) (*ModuleResponse, error) {
	return c.doRequest(ctx, "GET", fmt.Sprintf("/api/modules/%s", id), nil)
}

func (c *APIClient) UpdateModule(ctx context.Context, id string, req *ModuleRequest) (*ModuleResponse, error) {
	return c.doRequest(ctx, "PUT", fmt.Sprintf("/api/modules/%s", id), req)
}

func (c *APIClient) DeleteModule(ctx context.Context, id string) error {
	_, err := c.doRequest(ctx, "DELETE", fmt.Sprintf("/api/modules/%s", id), nil)
	return err
}

func (c *APIClient) CreateProject(ctx context.Context, req *ProjectRequest) (*ProjectResponse, error) {
	return c.doRequest(ctx, "POST", "/api/projects", req)
}

func (c *APIClient) GetProject(ctx context.Context, id string) (*ProjectResponse, error) {
	return c.doRequest(ctx, "GET", fmt.Sprintf("/api/projects/%s", id), nil)
}

func (c *APIClient) UpdateProject(ctx context.Context, id string, req *ProjectRequest) (*ProjectResponse, error) {
	return c.doRequest(ctx, "PUT", fmt.Sprintf("/api/projects/%s", id), req)
}

func (c *APIClient) DeleteProject(ctx context.Context, id string) error {
	_, err := c.doRequest(ctx, "DELETE", fmt.Sprintf("/api/projects/%s", id), nil)
	return err
}

func (c *APIClient) ListModules(ctx context.Context) ([]ModuleRegistry, error) {
	// Implementation
	return nil, nil
}

func (c *APIClient) ListProjects(ctx context.Context) ([]ProjectResponse, error) {
	// Implementation
	return nil, nil
}

func (c *APIClient) doRequest(ctx context.Context, method, path string, body interface{}) (interface{}, error) {
	var reqBody io.Reader
	if body != nil {
		jsonBody, err := json.Marshal(body)
		if err != nil {
			return nil, err
		}
		reqBody = bytes.NewBuffer(jsonBody)
	}

	req, err := http.NewRequestWithContext(ctx, method, c.Endpoint+path, reqBody)
	if err != nil {
		return nil, err
	}

	req.Header.Set("Content-Type", "application/json")
	if c.Username != "" && c.Password != "" {
		req.SetBasicAuth(c.Username, c.Password)
	}

	if c.client == nil {
		c.client = &http.Client{}
	}

	resp, err := c.client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, err
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("API error: %s", string(respBody))
	}

	return respBody, nil
}
```

## Makefile for Building

Create `Makefile`:

```makefile
.PHONY: build test install install-dev publish

build:
	@echo "Building terraform-provider-nixernetes..."
	go build -o terraform-provider-nixernetes

test:
	@echo "Running tests..."
	go test -v ./...

install: build
	@echo "Installing provider..."
	mkdir -p ~/.terraform.d/plugins/registry.terraform.io/nixernetes/nixernetes/1.0.0/linux_amd64
	cp terraform-provider-nixernetes ~/.terraform.d/plugins/registry.terraform.io/nixernetes/nixernetes/1.0.0/linux_amd64/

install-dev: build
	@echo "Installing provider for development..."
	cp terraform-provider-nixernetes ~/.terraform.d/plugins/nixernetes.com/nixernetes/nixernetes/1.0.0/linux_amd64/terraform-provider-nixernetes_v1.0.0

publish:
	@echo "Publishing to Terraform Registry..."
	goreleaser release --rm-dist
```

## Documentation

Create `docs/index.md`:

```markdown
# Terraform Provider for Nixernetes

Manage Nixernetes configurations and deployments using Terraform.

## Installation

```hcl
terraform {
  required_providers {
    nixernetes = {
      source  = "nixernetes/nixernetes"
      version = "~> 1.0"
    }
  }
}
```

## Configuration

```hcl
provider "nixernetes" {
  endpoint = "http://localhost:3000"
  username = "admin"
  password = var.password
}
```

## Resources

- `nixernetes_config` - Manage configurations
- `nixernetes_module` - Manage modules
- `nixernetes_project` - Manage projects

## Data Sources

- `nixernetes_modules` - List available modules
- `nixernetes_projects` - List projects

See documentation for detailed examples and attributes.
```

## Testing

Create `tests/provider_test.go`:

```go
package provider

import (
	"testing"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"
	"github.com/hashicorp/terraform-plugin-go/tfprotov6"
	"github.com/hashicorp/terraform-plugin-testing/helper/acctest"
	"github.com/hashicorp/terraform-plugin-testing/helper/resource"
)

const (
	providerConfig = `
provider "nixernetes" {
  endpoint = "http://localhost:3000"
  username = "admin"
  password = "admin"
}
`
)

func testAccPreCheck(t *testing.T) {
	// Add pre-check logic here
}

func testAccProtoV6ProviderFactories() map[string]func() (tfprotov6.ProviderServer, error) {
	return map[string]func() (tfprotov6.ProviderServer, error){
		"nixernetes": providerserver.NewProtocol6WithError(New()()),
	}
}

func TestAccConfigResource(t *testing.T) {
	rName := acctest.RandomWithPrefix("tf-test")

	resource.Test(t, resource.TestCase{
		PreCheck:                 func() { testAccPreCheck(t) },
		ProtoV6ProviderFactories: testAccProtoV6ProviderFactories(),
		Steps: []resource.TestStep{
			{
				Config: testAccConfigResourceConfig(rName),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttr("nixernetes_config.test", "name", rName),
				),
			},
		},
	})
}

func testAccConfigResourceConfig(name string) string {
	return providerConfig + `
resource "nixernetes_config" "test" {
  name = "` + name + `"
  configuration = <<-EOT
{ lib }: {
  deployment = {
    apiVersion = "apps/v1";
    kind = "Deployment";
  };
}
EOT
  environment = "test"
}
`
}
```

## CI/CD Workflow

Create `.github/workflows/test.yml`:

```yaml
name: Tests

on:
  push:
    branches: [main]
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.20'
      - run: go test -v -cover ./...

  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.20'
      - run: go build -o terraform-provider-nixernetes
```

## Publishing

Create `.github/workflows/release.yml`:

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-go@v4
        with:
          go-version: '1.20'
      - uses: goreleaser/goreleaser-action@v4
        with:
          args: release --rm-dist
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Development

### Building

```bash
make build
```

### Testing

```bash
make test
```

### Installation

```bash
make install
```

### Running Examples

```bash
cd examples/resources/config
terraform init
terraform plan
terraform apply
```

## Support

- GitHub Issues: https://github.com/nixernetes/terraform-provider-nixernetes/issues
- Documentation: https://registry.terraform.io/providers/nixernetes/nixernetes/latest
