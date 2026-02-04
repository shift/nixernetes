package main

import (
	"context"
	"testing"

	"github.com/hashicorp/terraform-plugin-framework/types"
)

func TestValidateConfigModel(t *testing.T) {
	tests := []struct {
		name      string
		model     *NixernetesConfigModel
		wantError bool
		errorMsg  string
	}{
		{
			name: "valid config",
			model: &NixernetesConfigModel{
				Name:          types.StringValue("my-config"),
				Configuration: types.StringValue("{ services.nginx.enable = true; }"),
				Environment:   types.StringValue("production"),
			},
			wantError: false,
		},
		{
			name: "empty name",
			model: &NixernetesConfigModel{
				Name:          types.StringValue(""),
				Configuration: types.StringValue("{ test }"),
			},
			wantError: true,
			errorMsg:  "Name is required",
		},
		{
			name: "null name",
			model: &NixernetesConfigModel{
				Name:          types.StringNull(),
				Configuration: types.StringValue("{ test }"),
			},
			wantError: true,
			errorMsg:  "Name is required",
		},
		{
			name: "invalid name characters",
			model: &NixernetesConfigModel{
				Name:          types.StringValue("my config!"),
				Configuration: types.StringValue("{ test }"),
			},
			wantError: true,
			errorMsg:  "Name must contain only alphanumeric",
		},
		{
			name: "name too long",
			model: &NixernetesConfigModel{
				Name:          types.StringValue(string(make([]byte, 300))),
				Configuration: types.StringValue("{ test }"),
			},
			wantError: true,
			errorMsg:  "Name cannot exceed 255",
		},
		{
			name: "empty configuration",
			model: &NixernetesConfigModel{
				Name:          types.StringValue("my-config"),
				Configuration: types.StringValue(""),
			},
			wantError: true,
			errorMsg:  "Configuration content is required",
		},
		{
			name: "invalid environment",
			model: &NixernetesConfigModel{
				Name:          types.StringValue("my-config"),
				Configuration: types.StringValue("{ test }"),
				Environment:   types.StringValue("testing"),
			},
			wantError: true,
			errorMsg:  "Environment must be",
		},
		{
			name: "valid environment staging",
			model: &NixernetesConfigModel{
				Name:          types.StringValue("my-config"),
				Configuration: types.StringValue("{ test }"),
				Environment:   types.StringValue("staging"),
			},
			wantError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			v := ValidateConfigModel(context.Background(), tt.model)
			if tt.wantError && !v.HasErrors() {
				t.Error("Expected validation error but got none")
			}
			if !tt.wantError && v.HasErrors() {
				t.Errorf("Unexpected validation errors: %v", v.Errors)
			}
		})
	}
}

func TestValidateModuleModel(t *testing.T) {
	tests := []struct {
		name      string
		model     *NixernetesModuleModel
		wantError bool
		errorMsg  string
	}{
		{
			name: "valid module",
			model: &NixernetesModuleModel{
				Name:      types.StringValue("api"),
				Image:     types.StringValue("nginx:latest"),
				Replicas:  types.Int64Value(2),
				Namespace: types.StringValue("default"),
			},
			wantError: false,
		},
		{
			name: "empty name",
			model: &NixernetesModuleModel{
				Name:  types.StringValue(""),
				Image: types.StringValue("nginx:latest"),
			},
			wantError: true,
			errorMsg:  "Name is required",
		},
		{
			name: "empty image",
			model: &NixernetesModuleModel{
				Name:  types.StringValue("api"),
				Image: types.StringValue(""),
			},
			wantError: true,
			errorMsg:  "Container image is required",
		},
		{
			name: "invalid image with shell characters",
			model: &NixernetesModuleModel{
				Name:  types.StringValue("api"),
				Image: types.StringValue("nginx:latest; rm -rf /"),
			},
			wantError: true,
			errorMsg:  "Image must be",
		},
		{
			name: "negative replicas",
			model: &NixernetesModuleModel{
				Name:     types.StringValue("api"),
				Image:    types.StringValue("nginx:latest"),
				Replicas: types.Int64Value(-1),
			},
			wantError: true,
			errorMsg:  "Replicas cannot be negative",
		},
		{
			name: "too many replicas",
			model: &NixernetesModuleModel{
				Name:     types.StringValue("api"),
				Image:    types.StringValue("nginx:latest"),
				Replicas: types.Int64Value(200),
			},
			wantError: true,
			errorMsg:  "Replicas cannot exceed 100",
		},
		{
			name: "invalid namespace",
			model: &NixernetesModuleModel{
				Name:      types.StringValue("api"),
				Image:     types.StringValue("nginx:latest"),
				Namespace: types.StringValue("INVALID"),
			},
			wantError: true,
			errorMsg:  "Namespace must be a valid",
		},
		{
			name: "valid namespace",
			model: &NixernetesModuleModel{
				Name:      types.StringValue("api"),
				Image:     types.StringValue("nginx:latest"),
				Namespace: types.StringValue("kube-system"),
			},
			wantError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			v := ValidateModuleModel(context.Background(), tt.model)
			if tt.wantError && !v.HasErrors() {
				t.Error("Expected validation error but got none")
			}
			if !tt.wantError && v.HasErrors() {
				t.Errorf("Unexpected validation errors: %v", v.Errors)
			}
		})
	}
}

func TestValidateProjectModel(t *testing.T) {
	tests := []struct {
		name      string
		model     *NixernetesProjectModel
		wantError bool
		errorMsg  string
	}{
		{
			name: "valid project",
			model: &NixernetesProjectModel{
				Name:        types.StringValue("production"),
				Description: types.StringValue("Production environment"),
			},
			wantError: false,
		},
		{
			name: "empty name",
			model: &NixernetesProjectModel{
				Name: types.StringValue(""),
			},
			wantError: true,
			errorMsg:  "Name is required",
		},
		{
			name: "invalid name characters",
			model: &NixernetesProjectModel{
				Name: types.StringValue("my project!"),
			},
			wantError: true,
			errorMsg:  "Name must contain only alphanumeric",
		},
		{
			name: "description too long",
			model: &NixernetesProjectModel{
				Name:        types.StringValue("prod"),
				Description: types.StringValue(string(make([]byte, 1500))),
			},
			wantError: true,
			errorMsg:  "Description cannot exceed 1000",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			v := ValidateProjectModel(context.Background(), tt.model)
			if tt.wantError && !v.HasErrors() {
				t.Error("Expected validation error but got none")
			}
			if !tt.wantError && v.HasErrors() {
				t.Errorf("Unexpected validation errors: %v", v.Errors)
			}
		})
	}
}

func TestIsValidName(t *testing.T) {
	tests := []struct {
		name      string
		input     string
		wantValid bool
	}{
		{"valid lowercase", "myconfig", true},
		{"valid with hyphen", "my-config", true},
		{"valid with underscore", "my_config", true},
		{"valid with numbers", "config123", true},
		{"valid mixed", "my-config_v1", true},
		{"empty string", "", false},
		{"starts with hyphen", "-config", false},
		{"contains space", "my config", false},
		{"contains special chars", "my@config", false},
		{"contains uppercase", "MyConfig", true},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := isValidName(tt.input)
			if got != tt.wantValid {
				t.Errorf("isValidName(%q) = %v, want %v", tt.input, got, tt.wantValid)
			}
		})
	}
}

func TestIsValidEnvironment(t *testing.T) {
	tests := []struct {
		name      string
		input     string
		wantValid bool
	}{
		{"development", "development", true},
		{"staging", "staging", true},
		{"production", "production", true},
		{"Development", "Development", true},
		{"PRODUCTION", "PRODUCTION", true},
		{"testing", "testing", false},
		{"demo", "demo", false},
		{"", "", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := isValidEnvironment(tt.input)
			if got != tt.wantValid {
				t.Errorf("isValidEnvironment(%q) = %v, want %v", tt.input, got, tt.wantValid)
			}
		})
	}
}

func TestIsValidImage(t *testing.T) {
	tests := []struct {
		name      string
		input     string
		wantValid bool
	}{
		{"simple image", "nginx", true},
		{"image with tag", "nginx:latest", true},
		{"image with registry", "docker.io/nginx:latest", true},
		{"image with port", "localhost:5000/myimage:tag", true},
		{"empty string", "", false},
		{"with semicolon", "nginx:latest;", false},
		{"with shell pipe", "nginx|bash", false},
		{"with backtick", "nginx`ls`", false},
		{"too many colons", "registry:5000:80/image:tag", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := isValidImage(tt.input)
			if got != tt.wantValid {
				t.Errorf("isValidImage(%q) = %v, want %v", tt.input, got, tt.wantValid)
			}
		})
	}
}

func TestIsValidNamespace(t *testing.T) {
	tests := []struct {
		name      string
		input     string
		wantValid bool
	}{
		{"default", "default", true},
		{"kube-system", "kube-system", true},
		{"my-namespace", "my-namespace", true},
		{"a", "a", true},
		{"63 chars", string(make([]byte, 63)), false}, // All nulls - invalid
		{"64 chars", string(make([]byte, 64)), false},
		{"UPPERCASE", "UPPERCASE", false},
		{"with_underscore", "with_underscore", false},
		{"starts with dash", "-namespace", false},
		{"ends with dash", "namespace-", false},
		{"empty", "", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := isValidNamespace(tt.input)
			if got != tt.wantValid {
				t.Errorf("isValidNamespace(%q) = %v, want %v", tt.input, got, tt.wantValid)
			}
		})
	}
}

func TestValidateHTTPError(t *testing.T) {
	tests := []struct {
		name          string
		err           error
		wantRetryable bool
		wantNonRetry  bool
	}{
		{
			name:          "400 bad request",
			err:           &HTTPError{StatusCode: 400, Message: "Invalid"},
			wantRetryable: false,
		},
		{
			name:          "401 unauthorized",
			err:           &HTTPError{StatusCode: 401, Message: "Invalid credentials"},
			wantRetryable: false,
		},
		{
			name:          "404 not found",
			err:           &HTTPError{StatusCode: 404, Message: "Not found"},
			wantRetryable: false,
		},
		{
			name:          "429 rate limited",
			err:           &HTTPError{StatusCode: 429, Message: "Rate limited"},
			wantRetryable: true,
		},
		{
			name:          "500 server error",
			err:           &HTTPError{StatusCode: 500, Message: "Internal error"},
			wantRetryable: true,
		},
		{
			name:          "503 unavailable",
			err:           &HTTPError{StatusCode: 503, Message: "Service unavailable"},
			wantRetryable: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, retryable := ValidateHTTPError(tt.err)
			if retryable != tt.wantRetryable {
				t.Errorf("ValidateHTTPError retryable = %v, want %v", retryable, tt.wantRetryable)
			}
		})
	}
}
