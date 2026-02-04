package main

import (
	"context"
	"os"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/provider/metaschema"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/types"
	"github.com/hashicorp/terraform-plugin-log/tflog"
)

// Ensure provider is defined with compile-time check
var _ provider.Provider = &NixernetesProvider{}

// New is a helper function to simplify provider server initialization.
func New(version string) func() provider.Provider {
	return func() provider.Provider {
		return &NixernetesProvider{
			version: version,
		}
	}
}

// NixernetesProvider defines the provider implementation.
type NixernetesProvider struct {
	// version is set to the provider version on release, "dev" when the
	// provider is built and ran locally, and "test" when running testing.
	version string
}

// NixernetesProviderModel describes the provider data model.
type NixernetesProviderModel struct {
	Endpoint types.String `tfsdk:"endpoint"`
	Username types.String `tfsdk:"username"`
	Password types.String `tfsdk:"password"`
}

// Metadata returns the provider type name.
func (p *NixernetesProvider) Metadata(ctx context.Context, req provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = "nixernetes"
	resp.Version = p.version
}

// Schema defines the provider-level schema for configuration data.
func (p *NixernetesProvider) Schema(ctx context.Context, req provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema = metaschema.Schema{
		Attributes: map[string]metaschema.Attribute{
			"endpoint": metaschema.StringAttribute{
				MarkdownDescription: "URI of the Nixernetes API server. Can also be provided via NIXERNETES_ENDPOINT environment variable.",
				Optional:            true,
			},
			"username": metaschema.StringAttribute{
				MarkdownDescription: "Username for Nixernetes API authentication. Can also be provided via NIXERNETES_USERNAME environment variable.",
				Optional:            true,
				Sensitive:           true,
			},
			"password": metaschema.StringAttribute{
				MarkdownDescription: "Password for Nixernetes API authentication. Can also be provided via NIXERNETES_PASSWORD environment variable.",
				Optional:            true,
				Sensitive:           true,
			},
		},
	}.GetSchemaBlock()
}

// Configure prepares a Nixernetes API client for data sources and resources.
func (p *NixernetesProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
	var config NixernetesProviderModel

	resp.Diagnostics.Append(req.Config.Get(ctx, &config)...)

	if resp.Diagnostics.HasError() {
		return
	}

	// Configuration values are now available.
	// Get values from configuration, environment variables, or set defaults

	endpoint := os.Getenv("NIXERNETES_ENDPOINT")
	if !config.Endpoint.IsNull() {
		endpoint = config.Endpoint.ValueString()
	}

	username := os.Getenv("NIXERNETES_USERNAME")
	if !config.Username.IsNull() {
		username = config.Username.ValueString()
	}

	password := os.Getenv("NIXERNETES_PASSWORD")
	if !config.Password.IsNull() {
		password = config.Password.ValueString()
	}

	if endpoint == "" {
		resp.Diagnostics.AddAttributeError(
			"Missing API Endpoint",
			"The provider cannot create the Nixernetes API client as there is a missing or empty value for the API endpoint. "+
				"Set the endpoint value in the configuration or use the NIXERNETES_ENDPOINT environment variable. "+
				"If either is already set, ensure the value is not empty.",
			nil,
		)
	}

	if username == "" {
		resp.Diagnostics.AddAttributeError(
			"Missing API Username",
			"The provider cannot create the Nixernetes API client as there is a missing or empty value for the API username. "+
				"Set the username value in the configuration or use the NIXERNETES_USERNAME environment variable. "+
				"If either is already set, ensure the value is not empty.",
			nil,
		)
	}

	if password == "" {
		resp.Diagnostics.AddAttributeError(
			"Missing API Password",
			"The provider cannot create the Nixernetes API client as there is a missing or empty value for the API password. "+
				"Set the password value in the configuration or use the NIXERNETES_PASSWORD environment variable. "+
				"If either is already set, ensure the value is not empty.",
			nil,
		)
	}

	if resp.Diagnostics.HasError() {
		return
	}

	ctx = tflog.SetField(ctx, "nixernetes_endpoint", endpoint)
	ctx = tflog.SetField(ctx, "nixernetes_username", username)
	ctx = tflog.MaskFieldValues(ctx, "nixernetes_password")
	tflog.Debug(ctx, "Creating Nixernetes client")

	// Create and configure the client
	client := &NixernetesClient{
		Endpoint: endpoint,
		Username: username,
		Password: password,
	}

	// Make the client available during DataSource and Resource type Configure methods.
	resp.DataSourceData = client
	resp.ResourceData = client

	tflog.Info(ctx, "Configured Nixernetes provider", map[string]any{"success": true})
}

// Resources defines the resources implemented in the provider.
func (p *NixernetesProvider) Resources(ctx context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		NewNixernetesConfigResource,
		NewNixernetesModuleResource,
		NewNixernetesProjectResource,
	}
}

// DataSources defines the data sources implemented in the provider.
func (p *NixernetesProvider) DataSources(ctx context.Context) []func() datasource.DataSource {
	return []func() datasource.DataSource{
		NewNixernetesModulesDataSource,
		NewNixernetesProjectsDataSource,
	}
}

// NixernetesClient provides the Nixernetes API client.
type NixernetesClient struct {
	Endpoint string
	Username string
	Password string
}
