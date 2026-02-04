package main

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
	"github.com/hashicorp/terraform-plugin-log/tflog"
)

// Ensure the implementation satisfies the expected interfaces.
var (
	_ resource.Resource              = &NixernetesConfigResource{}
	_ resource.ResourceWithConfigure = &NixernetesConfigResource{}
	_ resource.Resource              = &NixernetesModuleResource{}
	_ resource.ResourceWithConfigure = &NixernetesModuleResource{}
	_ resource.Resource              = &NixernetesProjectResource{}
	_ resource.ResourceWithConfigure = &NixernetesProjectResource{}
)

// NewNixernetesConfigResource is a helper function to simplify the provider implementation.
func NewNixernetesConfigResource() resource.Resource {
	return &NixernetesConfigResource{}
}

// NixernetesConfigResource is the resource implementation.
type NixernetesConfigResource struct {
	client *NixernetesClient
}

// NixernetesConfigModel describes the resource data model.
type NixernetesConfigModel struct {
	ID            types.String `tfsdk:"id"`
	Name          types.String `tfsdk:"name"`
	Configuration types.String `tfsdk:"configuration"`
	Environment   types.String `tfsdk:"environment"`
	CreatedAt     types.String `tfsdk:"created_at"`
	UpdatedAt     types.String `tfsdk:"updated_at"`
}

// Metadata returns the resource type name.
func (r *NixernetesConfigResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_config"
}

// Schema defines the schema for the resource.
func (r *NixernetesConfigResource) Schema(ctx context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Manages a Nixernetes configuration deployment.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				MarkdownDescription: "Configuration ID",
				Computed:            true,
			},
			"name": schema.StringAttribute{
				MarkdownDescription: "Configuration name",
				Required:            true,
			},
			"configuration": schema.StringAttribute{
				MarkdownDescription: "Nix configuration content",
				Required:            true,
			},
			"environment": schema.StringAttribute{
				MarkdownDescription: "Deployment environment (development, staging, production)",
				Optional:            true,
				Computed:            true,
			},
			"created_at": schema.StringAttribute{
				MarkdownDescription: "Creation timestamp",
				Computed:            true,
			},
			"updated_at": schema.StringAttribute{
				MarkdownDescription: "Last update timestamp",
				Computed:            true,
			},
		},
	}
}

// Configure adds the provider configured client to the resource.
func (r *NixernetesConfigResource) Configure(_ context.Context, req resource.ConfigureRequest, _ *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	client, ok := req.ProviderData.(*NixernetesClient)
	if !ok {
		return
	}

	r.client = client
}

// Create creates a new configuration.
func (r *NixernetesConfigResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan NixernetesConfigModel

	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	// API call to create configuration
	body := map[string]interface{}{
		"name":          plan.Name.ValueString(),
		"configuration": plan.Configuration.ValueString(),
		"environment":   plan.Environment.ValueString(),
	}

	response, err := r.client.Post(ctx, "/configs", body)
	if err != nil {
		resp.Diagnostics.AddError(
			"Error creating configuration",
			"Could not create configuration, unexpected error: "+err.Error(),
		)
		return
	}

	plan.ID = types.StringValue(response["id"].(string))
	plan.CreatedAt = types.StringValue(response["created_at"].(string))
	plan.UpdatedAt = types.StringValue(response["updated_at"].(string))

	tflog.Trace(ctx, "Created configuration", map[string]any{"id": plan.ID.ValueString()})

	diags = resp.State.Set(ctx, plan)
	resp.Diagnostics.Append(diags...)
}

// Read refreshes the configuration state.
func (r *NixernetesConfigResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state NixernetesConfigModel

	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	// API call to get configuration
	response, err := r.client.Get(ctx, "/configs/"+state.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError(
			"Error reading configuration",
			"Could not read configuration "+state.ID.ValueString()+": "+err.Error(),
		)
		return
	}

	state.Name = types.StringValue(response["name"].(string))
	state.Configuration = types.StringValue(response["configuration"].(string))
	state.Environment = types.StringValue(response["environment"].(string))
	state.UpdatedAt = types.StringValue(response["updated_at"].(string))

	diags = resp.State.Set(ctx, state)
	resp.Diagnostics.Append(diags...)
}

// Update updates the configuration.
func (r *NixernetesConfigResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan NixernetesConfigModel

	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	// API call to update configuration
	body := map[string]interface{}{
		"name":          plan.Name.ValueString(),
		"configuration": plan.Configuration.ValueString(),
		"environment":   plan.Environment.ValueString(),
	}

	response, err := r.client.Put(ctx, "/configs/"+plan.ID.ValueString(), body)
	if err != nil {
		resp.Diagnostics.AddError(
			"Error updating configuration",
			"Could not update configuration, unexpected error: "+err.Error(),
		)
		return
	}

	plan.UpdatedAt = types.StringValue(response["updated_at"].(string))

	diags = resp.State.Set(ctx, plan)
	resp.Diagnostics.Append(diags...)
}

// Delete deletes the configuration.
func (r *NixernetesConfigResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state NixernetesConfigModel

	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	// API call to delete configuration
	err := r.client.Delete(ctx, "/configs/"+state.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError(
			"Error deleting configuration",
			"Could not delete configuration, unexpected error: "+err.Error(),
		)
		return
	}

	tflog.Trace(ctx, "Deleted configuration", map[string]any{"id": state.ID.ValueString()})
}

// ========== Module Resource ==========

func NewNixernetesModuleResource() resource.Resource {
	return &NixernetesModuleResource{}
}

type NixernetesModuleResource struct {
	client *NixernetesClient
}

type NixernetesModuleModel struct {
	ID        types.String `tfsdk:"id"`
	Name      types.String `tfsdk:"name"`
	Replicas  types.Int64  `tfsdk:"replicas"`
	Image     types.String `tfsdk:"image"`
	Namespace types.String `tfsdk:"namespace"`
	CreatedAt types.String `tfsdk:"created_at"`
}

func (r *NixernetesModuleResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_module"
}

func (r *NixernetesModuleResource) Schema(ctx context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Manages a Nixernetes module instance.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				MarkdownDescription: "Module instance ID",
				Computed:            true,
			},
			"name": schema.StringAttribute{
				MarkdownDescription: "Module instance name",
				Required:            true,
			},
			"replicas": schema.Int64Attribute{
				MarkdownDescription: "Number of replicas",
				Optional:            true,
				Computed:            true,
			},
			"image": schema.StringAttribute{
				MarkdownDescription: "Container image",
				Required:            true,
			},
			"namespace": schema.StringAttribute{
				MarkdownDescription: "Kubernetes namespace",
				Optional:            true,
				Computed:            true,
			},
			"created_at": schema.StringAttribute{
				MarkdownDescription: "Creation timestamp",
				Computed:            true,
			},
		},
	}
}

func (r *NixernetesModuleResource) Configure(_ context.Context, req resource.ConfigureRequest, _ *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	client, ok := req.ProviderData.(*NixernetesClient)
	if !ok {
		return
	}

	r.client = client
}

func (r *NixernetesModuleResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan NixernetesModuleModel

	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	body := map[string]interface{}{
		"name":      plan.Name.ValueString(),
		"replicas":  plan.Replicas.ValueInt64(),
		"image":     plan.Image.ValueString(),
		"namespace": plan.Namespace.ValueString(),
	}

	response, err := r.client.Post(ctx, "/modules", body)
	if err != nil {
		resp.Diagnostics.AddError("Error creating module", "Could not create module: "+err.Error())
		return
	}

	plan.ID = types.StringValue(response["id"].(string))
	plan.CreatedAt = types.StringValue(response["created_at"].(string))

	diags = resp.State.Set(ctx, plan)
	resp.Diagnostics.Append(diags...)
}

func (r *NixernetesModuleResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state NixernetesModuleModel

	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	response, err := r.client.Get(ctx, "/modules/"+state.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Error reading module", "Could not read module: "+err.Error())
		return
	}

	state.Name = types.StringValue(response["name"].(string))
	state.Replicas = types.Int64Value(int64(response["replicas"].(float64)))
	state.Image = types.StringValue(response["image"].(string))
	state.Namespace = types.StringValue(response["namespace"].(string))

	diags = resp.State.Set(ctx, state)
	resp.Diagnostics.Append(diags...)
}

func (r *NixernetesModuleResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan NixernetesModuleModel

	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	body := map[string]interface{}{
		"name":      plan.Name.ValueString(),
		"replicas":  plan.Replicas.ValueInt64(),
		"image":     plan.Image.ValueString(),
		"namespace": plan.Namespace.ValueString(),
	}

	_, err := r.client.Put(ctx, "/modules/"+plan.ID.ValueString(), body)
	if err != nil {
		resp.Diagnostics.AddError("Error updating module", "Could not update module: "+err.Error())
		return
	}

	diags = resp.State.Set(ctx, plan)
	resp.Diagnostics.Append(diags...)
}

func (r *NixernetesModuleResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state NixernetesModuleModel

	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	err := r.client.Delete(ctx, "/modules/"+state.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Error deleting module", "Could not delete module: "+err.Error())
		return
	}
}

// ========== Project Resource ==========

func NewNixernetesProjectResource() resource.Resource {
	return &NixernetesProjectResource{}
}

type NixernetesProjectResource struct {
	client *NixernetesClient
}

type NixernetesProjectModel struct {
	ID          types.String `tfsdk:"id"`
	Name        types.String `tfsdk:"name"`
	Description types.String `tfsdk:"description"`
	Status      types.String `tfsdk:"status"`
	CreatedAt   types.String `tfsdk:"created_at"`
	UpdatedAt   types.String `tfsdk:"updated_at"`
}

func (r *NixernetesProjectResource) Metadata(_ context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_project"
}

func (r *NixernetesProjectResource) Schema(ctx context.Context, _ resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Manages a Nixernetes project.",
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				MarkdownDescription: "Project ID",
				Computed:            true,
			},
			"name": schema.StringAttribute{
				MarkdownDescription: "Project name",
				Required:            true,
			},
			"description": schema.StringAttribute{
				MarkdownDescription: "Project description",
				Optional:            true,
			},
			"status": schema.StringAttribute{
				MarkdownDescription: "Project status",
				Computed:            true,
			},
			"created_at": schema.StringAttribute{
				MarkdownDescription: "Creation timestamp",
				Computed:            true,
			},
			"updated_at": schema.StringAttribute{
				MarkdownDescription: "Last update timestamp",
				Computed:            true,
			},
		},
	}
}

func (r *NixernetesProjectResource) Configure(_ context.Context, req resource.ConfigureRequest, _ *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	client, ok := req.ProviderData.(*NixernetesClient)
	if !ok {
		return
	}

	r.client = client
}

func (r *NixernetesProjectResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan NixernetesProjectModel

	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	body := map[string]interface{}{
		"name":        plan.Name.ValueString(),
		"description": plan.Description.ValueString(),
	}

	response, err := r.client.Post(ctx, "/projects", body)
	if err != nil {
		resp.Diagnostics.AddError("Error creating project", "Could not create project: "+err.Error())
		return
	}

	plan.ID = types.StringValue(response["id"].(string))
	plan.Status = types.StringValue(response["status"].(string))
	plan.CreatedAt = types.StringValue(response["created_at"].(string))
	plan.UpdatedAt = types.StringValue(response["updated_at"].(string))

	diags = resp.State.Set(ctx, plan)
	resp.Diagnostics.Append(diags...)
}

func (r *NixernetesProjectResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state NixernetesProjectModel

	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	response, err := r.client.Get(ctx, "/projects/"+state.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Error reading project", "Could not read project: "+err.Error())
		return
	}

	state.Name = types.StringValue(response["name"].(string))
	state.Description = types.StringValue(response["description"].(string))
	state.Status = types.StringValue(response["status"].(string))
	state.UpdatedAt = types.StringValue(response["updated_at"].(string))

	diags = resp.State.Set(ctx, state)
	resp.Diagnostics.Append(diags...)
}

func (r *NixernetesProjectResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan NixernetesProjectModel

	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	body := map[string]interface{}{
		"name":        plan.Name.ValueString(),
		"description": plan.Description.ValueString(),
	}

	response, err := r.client.Put(ctx, "/projects/"+plan.ID.ValueString(), body)
	if err != nil {
		resp.Diagnostics.AddError("Error updating project", "Could not update project: "+err.Error())
		return
	}

	plan.UpdatedAt = types.StringValue(response["updated_at"].(string))

	diags = resp.State.Set(ctx, plan)
	resp.Diagnostics.Append(diags...)
}

func (r *NixernetesProjectResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state NixernetesProjectModel

	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	err := r.client.Delete(ctx, "/projects/"+state.ID.ValueString())
	if err != nil {
		resp.Diagnostics.AddError("Error deleting project", "Could not delete project: "+err.Error())
		return
	}
}
