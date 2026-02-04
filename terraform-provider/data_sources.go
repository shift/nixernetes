package main

import (
	"context"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

// Ensure the implementation satisfies the expected interfaces.
var (
	_ datasource.DataSource              = &NixernetesModulesDataSource{}
	_ datasource.DataSourceWithConfigure = &NixernetesModulesDataSource{}
	_ datasource.DataSource              = &NixernetesProjectsDataSource{}
	_ datasource.DataSourceWithConfigure = &NixernetesProjectsDataSource{}
)

// NewNixernetesModulesDataSource is a helper function to simplify the provider implementation.
func NewNixernetesModulesDataSource() datasource.DataSource {
	return &NixernetesModulesDataSource{}
}

// NixernetesModulesDataSource is the data source implementation.
type NixernetesModulesDataSource struct {
	client *NixernetesClient
}

type NixernetesModulesDataSourceModel struct {
	Modules []NixernetesModuleData `tfsdk:"modules"`
}

type NixernetesModuleData struct {
	ID          types.String `tfsdk:"id"`
	Name        types.String `tfsdk:"name"`
	Description types.String `tfsdk:"description"`
	Version     types.String `tfsdk:"version"`
}

func (d *NixernetesModulesDataSource) Metadata(_ context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_modules"
}

func (d *NixernetesModulesDataSource) Schema(ctx context.Context, _ datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Fetches the list of available Nixernetes modules.",
		Attributes: map[string]schema.Attribute{
			"modules": schema.ListNestedAttribute{
				MarkdownDescription: "List of modules",
				Computed:            true,
				NestedObject: schema.NestedAttributeObject{
					Attributes: map[string]schema.Attribute{
						"id": schema.StringAttribute{
							MarkdownDescription: "Module ID",
							Computed:            true,
						},
						"name": schema.StringAttribute{
							MarkdownDescription: "Module name",
							Computed:            true,
						},
						"description": schema.StringAttribute{
							MarkdownDescription: "Module description",
							Computed:            true,
						},
						"version": schema.StringAttribute{
							MarkdownDescription: "Module version",
							Computed:            true,
						},
					},
				},
			},
		},
	}
}

func (d *NixernetesModulesDataSource) Configure(_ context.Context, req datasource.ConfigureRequest, _ *datasource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	client, ok := req.ProviderData.(*NixernetesClient)
	if !ok {
		return
	}

	d.client = client
}

func (d *NixernetesModulesDataSource) Read(ctx context.Context, _ datasource.ReadRequest, resp *datasource.ReadResponse) {
	var state NixernetesModulesDataSourceModel

	// API call to list modules
	response, err := d.client.Get(ctx, "/modules")
	if err != nil {
		resp.Diagnostics.AddError(
			"Error reading modules",
			"Could not read modules, unexpected error: "+err.Error(),
		)
		return
	}

	modules := response["modules"].([]interface{})
	for _, m := range modules {
		module := m.(map[string]interface{})
		state.Modules = append(state.Modules, NixernetesModuleData{
			ID:          types.StringValue(module["id"].(string)),
			Name:        types.StringValue(module["name"].(string)),
			Description: types.StringValue(module["description"].(string)),
			Version:     types.StringValue(module["version"].(string)),
		})
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &state)...)
}

// ========== Projects Data Source ==========

func NewNixernetesProjectsDataSource() datasource.DataSource {
	return &NixernetesProjectsDataSource{}
}

type NixernetesProjectsDataSource struct {
	client *NixernetesClient
}

type NixernetesProjectsDataSourceModel struct {
	Projects []NixernetesProjectData `tfsdk:"projects"`
}

type NixernetesProjectData struct {
	ID          types.String `tfsdk:"id"`
	Name        types.String `tfsdk:"name"`
	Description types.String `tfsdk:"description"`
	Status      types.String `tfsdk:"status"`
}

func (d *NixernetesProjectsDataSource) Metadata(_ context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_projects"
}

func (d *NixernetesProjectsDataSource) Schema(ctx context.Context, _ datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: "Fetches the list of Nixernetes projects.",
		Attributes: map[string]schema.Attribute{
			"projects": schema.ListNestedAttribute{
				MarkdownDescription: "List of projects",
				Computed:            true,
				NestedObject: schema.NestedAttributeObject{
					Attributes: map[string]schema.Attribute{
						"id": schema.StringAttribute{
							MarkdownDescription: "Project ID",
							Computed:            true,
						},
						"name": schema.StringAttribute{
							MarkdownDescription: "Project name",
							Computed:            true,
						},
						"description": schema.StringAttribute{
							MarkdownDescription: "Project description",
							Computed:            true,
						},
						"status": schema.StringAttribute{
							MarkdownDescription: "Project status",
							Computed:            true,
						},
					},
				},
			},
		},
	}
}

func (d *NixernetesProjectsDataSource) Configure(_ context.Context, req datasource.ConfigureRequest, _ *datasource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	client, ok := req.ProviderData.(*NixernetesClient)
	if !ok {
		return
	}

	d.client = client
}

func (d *NixernetesProjectsDataSource) Read(ctx context.Context, _ datasource.ReadRequest, resp *datasource.ReadResponse) {
	var state NixernetesProjectsDataSourceModel

	// API call to list projects
	response, err := d.client.Get(ctx, "/projects")
	if err != nil {
		resp.Diagnostics.AddError(
			"Error reading projects",
			"Could not read projects, unexpected error: "+err.Error(),
		)
		return
	}

	projects := response["projects"].([]interface{})
	for _, p := range projects {
		project := p.(map[string]interface{})
		state.Projects = append(state.Projects, NixernetesProjectData{
			ID:          types.StringValue(project["id"].(string)),
			Name:        types.StringValue(project["name"].(string)),
			Description: types.StringValue(project["description"].(string)),
			Status:      types.StringValue(project["status"].(string)),
		})
	}

	resp.Diagnostics.Append(resp.State.Set(ctx, &state)...)
}
