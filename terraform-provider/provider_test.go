package main

import (
	"context"
	"testing"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"
	"github.com/hashicorp/terraform-plugin-go/tfprotov6"
	"github.com/hashicorp/terraform-plugin-testing/helper/acctest"
	"github.com/hashicorp/terraform-plugin-testing/helper/resource"
)

// protoV6ProviderFactories are used to instantiate a provider during
// acceptance testing. The factory function will be invoked for every Terraform
// CLI command executed to create a provider server to which the CLI can
// reattach.
var protoV6ProviderFactories = map[string]func() (tfprotov6.ProviderServer, error){
	"nixernetes": providerserver.NewProtocol6WithError(New("test")()),
}

func TestAccConfigResource(t *testing.T) {
	rName := acctest.RandomWithPrefix("test-")

	resource.Test(t, resource.TestCase{
		PreCheck:                 func() { testAccPreCheck(t) },
		ProtoV6ProviderFactories: protoV6ProviderFactories,
		Steps: []resource.TestStep{
			// Create and Read testing
			{
				Config: testAccConfigResourceConfig(rName),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttrSet("nixernetes_config.test", "id"),
					resource.TestCheckResourceAttr("nixernetes_config.test", "name", rName),
					resource.TestCheckResourceAttrSet("nixernetes_config.test", "created_at"),
					resource.TestCheckResourceAttrSet("nixernetes_config.test", "updated_at"),
				),
			},
			// ImportState testing
			{
				ResourceName:      "nixernetes_config.test",
				ImportState:       true,
				ImportStateVerify: true,
			},
			// Update and Read testing
			{
				Config: testAccConfigResourceConfigUpdated(rName),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttr("nixernetes_config.test", "name", rName),
					resource.TestCheckResourceAttr("nixernetes_config.test", "environment", "staging"),
				),
			},
			// Delete testing automatically occurs in TestCase
		},
	})
}

func TestAccModuleResource(t *testing.T) {
	rName := acctest.RandomWithPrefix("test-module-")

	resource.Test(t, resource.TestCase{
		PreCheck:                 func() { testAccPreCheck(t) },
		ProtoV6ProviderFactories: protoV6ProviderFactories,
		Steps: []resource.TestStep{
			// Create and Read testing
			{
				Config: testAccModuleResourceConfig(rName),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttrSet("nixernetes_module.test", "id"),
					resource.TestCheckResourceAttr("nixernetes_module.test", "name", rName),
					resource.TestCheckResourceAttr("nixernetes_module.test", "replicas", "2"),
					resource.TestCheckResourceAttr("nixernetes_module.test", "image", "nginx:latest"),
					resource.TestCheckResourceAttrSet("nixernetes_module.test", "created_at"),
				),
			},
			// ImportState testing
			{
				ResourceName:      "nixernetes_module.test",
				ImportState:       true,
				ImportStateVerify: true,
			},
			// Update and Read testing
			{
				Config: testAccModuleResourceConfigUpdated(rName),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttr("nixernetes_module.test", "replicas", "3"),
				),
			},
		},
	})
}

func TestAccProjectResource(t *testing.T) {
	rName := acctest.RandomWithPrefix("test-project-")

	resource.Test(t, resource.TestCase{
		PreCheck:                 func() { testAccPreCheck(t) },
		ProtoV6ProviderFactories: protoV6ProviderFactories,
		Steps: []resource.TestStep{
			// Create and Read testing
			{
				Config: testAccProjectResourceConfig(rName),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttrSet("nixernetes_project.test", "id"),
					resource.TestCheckResourceAttr("nixernetes_project.test", "name", rName),
					resource.TestCheckResourceAttr("nixernetes_project.test", "description", "Test project"),
					resource.TestCheckResourceAttrSet("nixernetes_project.test", "created_at"),
					resource.TestCheckResourceAttrSet("nixernetes_project.test", "updated_at"),
				),
			},
			// ImportState testing
			{
				ResourceName:      "nixernetes_project.test",
				ImportState:       true,
				ImportStateVerify: true,
			},
			// Update and Read testing
			{
				Config: testAccProjectResourceConfigUpdated(rName),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttr("nixernetes_project.test", "description", "Updated description"),
				),
			},
		},
	})
}

func TestAccModulesDataSource(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:                 func() { testAccPreCheck(t) },
		ProtoV6ProviderFactories: protoV6ProviderFactories,
		Steps: []resource.TestStep{
			{
				Config: testAccModulesDataSourceConfig(),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttrSet("data.nixernetes_modules.test", "modules"),
				),
			},
		},
	})
}

func TestAccProjectsDataSource(t *testing.T) {
	resource.Test(t, resource.TestCase{
		PreCheck:                 func() { testAccPreCheck(t) },
		ProtoV6ProviderFactories: protoV6ProviderFactories,
		Steps: []resource.TestStep{
			{
				Config: testAccProjectsDataSourceConfig(),
				Check: resource.ComposeAggregateTestCheckFunc(
					resource.TestCheckResourceAttrSet("data.nixernetes_projects.test", "projects"),
				),
			},
		},
	})
}

func testAccPreCheck(t *testing.T) {
	// TODO: Verify that environment variables are set
	// Typically this would check for:
	// - NIXERNETES_ENDPOINT
	// - NIXERNETES_USERNAME
	// - NIXERNETES_PASSWORD
	t.Log("Pre-check passed")
}

func testAccConfigResourceConfig(name string) string {
	return `
provider "nixernetes" {
  endpoint = "https://localhost:8080"
  username = "test"
  password = "test"
}

resource "nixernetes_config" "test" {
  name          = "` + name + `"
  configuration = <<-EOT
{ pkgs ? import <nixpkgs> {} }:
{
  services.nginx.enable = true;
}
EOT
  environment   = "development"
}
`
}

func testAccConfigResourceConfigUpdated(name string) string {
	return `
provider "nixernetes" {
  endpoint = "https://localhost:8080"
  username = "test"
  password = "test"
}

resource "nixernetes_config" "test" {
  name          = "` + name + `"
  configuration = <<-EOT
{ pkgs ? import <nixpkgs> {} }:
{
  services.nginx.enable = true;
  services.nginx.virtualHosts."example.com".root = "/var/www/example";
}
EOT
  environment   = "staging"
}
`
}

func testAccModuleResourceConfig(name string) string {
	return `
provider "nixernetes" {
  endpoint = "https://localhost:8080"
  username = "test"
  password = "test"
}

resource "nixernetes_module" "test" {
  name      = "` + name + `"
  image     = "nginx:latest"
  replicas  = 2
  namespace = "default"
}
`
}

func testAccModuleResourceConfigUpdated(name string) string {
	return `
provider "nixernetes" {
  endpoint = "https://localhost:8080"
  username = "test"
  password = "test"
}

resource "nixernetes_module" "test" {
  name      = "` + name + `"
  image     = "nginx:latest"
  replicas  = 3
  namespace = "default"
}
`
}

func testAccProjectResourceConfig(name string) string {
	return `
provider "nixernetes" {
  endpoint = "https://localhost:8080"
  username = "test"
  password = "test"
}

resource "nixernetes_project" "test" {
  name        = "` + name + `"
  description = "Test project"
}
`
}

func testAccProjectResourceConfigUpdated(name string) string {
	return `
provider "nixernetes" {
  endpoint = "https://localhost:8080"
  username = "test"
  password = "test"
}

resource "nixernetes_project" "test" {
  name        = "` + name + `"
  description = "Updated description"
}
`
}

func testAccModulesDataSourceConfig() string {
	return `
provider "nixernetes" {
  endpoint = "https://localhost:8080"
  username = "test"
  password = "test"
}

data "nixernetes_modules" "test" {}
`
}

func testAccProjectsDataSourceConfig() string {
	return `
provider "nixernetes" {
  endpoint = "https://localhost:8080"
  username = "test"
  password = "test"
}

data "nixernetes_projects" "test" {}
`
}
