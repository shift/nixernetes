package main

import (
	"context"
	"flag"
	"log"
	"os"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"
)

// Run the provider. Called from the generated code in the plugin SDK.
func main() {
	var debug bool

	opts := providerserver.ServeOpts{
		// NOTE: This is not a typical Terraform registry provider setup and may require
		// additional configuration depending on how the provider is used.
		Address: "registry.terraform.io/anomalyco/nixernetes",
		Debug:   debug,
	}

	err := providerserver.Serve(context.Background(), New("1.0.0"), opts)
	if err != nil {
		log.Fatal(err)
	}
}

func init() {
	// TODO: Set the 'providerVersion' in client.go if a provider version constant is used.

	// Enable provider logging. Available environment variables are:
	// TF_LOG: Set to DEBUG, INFO, WARN or ERROR for terraform logging
	// TF_LOG_PATH: Set to a file path to log to that file instead of stderr
}
