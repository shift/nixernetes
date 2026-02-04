package main

import (
	"context"
	"fmt"
	"strings"

	"github.com/hashicorp/terraform-plugin-framework/diag"
	"github.com/hashicorp/terraform-plugin-log/tflog"
)

// ValidationError represents a validation error with field and message
type ValidationError struct {
	Field   string
	Message string
}

// Validator provides validation functionality for resources
type Validator struct {
	Errors []ValidationError
}

// AddError adds a validation error
func (v *Validator) AddError(field, message string) {
	v.Errors = append(v.Errors, ValidationError{
		Field:   field,
		Message: message,
	})
}

// HasErrors returns true if there are any validation errors
func (v *Validator) HasErrors() bool {
	return len(v.Errors) > 0
}

// ToDiagnostics converts validation errors to Terraform diagnostics
func (v *Validator) ToDiagnostics() diag.Diagnostics {
	var diags diag.Diagnostics
	for _, err := range v.Errors {
		diags.AddError(
			fmt.Sprintf("Invalid %s", err.Field),
			err.Message,
		)
	}
	return diags
}

// ValidateConfigModel validates a NixernetesConfigModel
func ValidateConfigModel(ctx context.Context, config *NixernetesConfigModel) *Validator {
	v := &Validator{}

	tflog.Debug(ctx, "Validating config model", map[string]any{
		"name": config.Name.ValueString(),
	})

	// Validate name
	if config.Name.IsNull() || config.Name.ValueString() == "" {
		v.AddError("name", "Name is required and cannot be empty")
	}

	name := config.Name.ValueString()
	if len(name) > 255 {
		v.AddError("name", "Name cannot exceed 255 characters")
	}

	if !isValidName(name) {
		v.AddError("name", "Name must contain only alphanumeric characters, hyphens, and underscores")
	}

	// Validate configuration
	if config.Configuration.IsNull() || config.Configuration.ValueString() == "" {
		v.AddError("configuration", "Configuration content is required and cannot be empty")
	}

	// Validate environment if provided
	if !config.Environment.IsNull() {
		env := config.Environment.ValueString()
		if !isValidEnvironment(env) {
			v.AddError("environment", "Environment must be 'development', 'staging', or 'production'")
		}
	}

	return v
}

// ValidateModuleModel validates a NixernetesModuleModel
func ValidateModuleModel(ctx context.Context, module *NixernetesModuleModel) *Validator {
	v := &Validator{}

	tflog.Debug(ctx, "Validating module model", map[string]any{
		"name": module.Name.ValueString(),
	})

	// Validate name
	if module.Name.IsNull() || module.Name.ValueString() == "" {
		v.AddError("name", "Name is required and cannot be empty")
	}

	name := module.Name.ValueString()
	if len(name) > 255 {
		v.AddError("name", "Name cannot exceed 255 characters")
	}

	if !isValidName(name) {
		v.AddError("name", "Name must contain only alphanumeric characters, hyphens, and underscores")
	}

	// Validate image
	if module.Image.IsNull() || module.Image.ValueString() == "" {
		v.AddError("image", "Container image is required and cannot be empty")
	} else {
		image := module.Image.ValueString()
		if !isValidImage(image) {
			v.AddError("image", "Image must be in format 'registry/repository:tag' or 'repository:tag'")
		}
	}

	// Validate replicas if provided
	if !module.Replicas.IsNull() {
		replicas := module.Replicas.ValueInt64()
		if replicas < 0 {
			v.AddError("replicas", "Replicas cannot be negative")
		}
		if replicas > 100 {
			v.AddError("replicas", "Replicas cannot exceed 100")
		}
	}

	// Validate namespace if provided
	if !module.Namespace.IsNull() {
		ns := module.Namespace.ValueString()
		if !isValidNamespace(ns) {
			v.AddError("namespace", "Namespace must be a valid Kubernetes namespace name")
		}
	}

	return v
}

// ValidateProjectModel validates a NixernetesProjectModel
func ValidateProjectModel(ctx context.Context, project *NixernetesProjectModel) *Validator {
	v := &Validator{}

	tflog.Debug(ctx, "Validating project model", map[string]any{
		"name": project.Name.ValueString(),
	})

	// Validate name
	if project.Name.IsNull() || project.Name.ValueString() == "" {
		v.AddError("name", "Name is required and cannot be empty")
	}

	name := project.Name.ValueString()
	if len(name) > 255 {
		v.AddError("name", "Name cannot exceed 255 characters")
	}

	if !isValidName(name) {
		v.AddError("name", "Name must contain only alphanumeric characters, hyphens, and underscores")
	}

	// Validate description if provided
	if !project.Description.IsNull() {
		desc := project.Description.ValueString()
		if len(desc) > 1000 {
			v.AddError("description", "Description cannot exceed 1000 characters")
		}
	}

	return v
}

// isValidName validates a resource name
func isValidName(name string) bool {
	if len(name) == 0 {
		return false
	}

	// Name must start with a letter or digit
	if !isAlphaNumeric(rune(name[0])) && name[0] != '_' {
		return false
	}

	// Check all characters
	for _, r := range name {
		if !isAlphaNumeric(r) && r != '-' && r != '_' {
			return false
		}
	}

	return true
}

// isValidEnvironment validates an environment name
func isValidEnvironment(env string) bool {
	validEnvs := map[string]bool{
		"development": true,
		"staging":     true,
		"production":  true,
	}
	return validEnvs[strings.ToLower(env)]
}

// isValidImage validates a container image reference
func isValidImage(image string) bool {
	// Basic validation for image format
	if len(image) == 0 {
		return false
	}

	// Check for invalid characters
	invalidChars := []string{"<", ">", "`", "$", "&", "|", ";"}
	for _, char := range invalidChars {
		if strings.Contains(image, char) {
			return false
		}
	}

	// Must contain at least a name
	parts := strings.Split(image, ":")
	if len(parts) > 2 {
		return false // Too many colons
	}

	return true
}

// isValidNamespace validates a Kubernetes namespace name
func isValidNamespace(ns string) bool {
	if len(ns) == 0 || len(ns) > 63 {
		return false
	}

	// Must start and end with alphanumeric
	if !isAlphaNumeric(rune(ns[0])) || !isAlphaNumeric(rune(ns[len(ns)-1])) {
		return false
	}

	// Can only contain lowercase alphanumerics and hyphens
	for _, r := range ns {
		if r < 'a' || r > 'z' && r < '0' || r > '9' && r != '-' {
			return false
		}
	}

	return true
}

// isAlphaNumeric checks if a rune is alphanumeric
func isAlphaNumeric(r rune) bool {
	return (r >= 'a' && r <= 'z') || (r >= 'A' && r <= 'Z') || (r >= '0' && r <= '9')
}

// ValidateHTTPError validates and handles HTTP errors
func ValidateHTTPError(err error) (message string, retryable bool) {
	if err == nil {
		return "", false
	}

	httpErr, ok := err.(*HTTPError)
	if !ok {
		return err.Error(), true
	}

	// Determine if error is retryable based on status code
	switch httpErr.StatusCode {
	case 400: // Bad Request
		return fmt.Sprintf("Invalid request: %s", httpErr.Message), false
	case 401: // Unauthorized
		return fmt.Sprintf("Authentication failed: %s", httpErr.Message), false
	case 403: // Forbidden
		return fmt.Sprintf("Access denied: %s", httpErr.Message), false
	case 404: // Not Found
		return fmt.Sprintf("Resource not found: %s", httpErr.Message), false
	case 409: // Conflict
		return fmt.Sprintf("Resource conflict: %s", httpErr.Message), false
	case 429: // Too Many Requests
		return fmt.Sprintf("Rate limited: %s", httpErr.Message), true
	case 500: // Internal Server Error
		return fmt.Sprintf("Server error: %s", httpErr.Message), true
	case 502, 503, 504: // Bad Gateway, Service Unavailable, Gateway Timeout
		return fmt.Sprintf("Service unavailable: %s", httpErr.Message), true
	default:
		if httpErr.StatusCode >= 500 {
			return fmt.Sprintf("Server error (HTTP %d): %s", httpErr.StatusCode, httpErr.Message), true
		}
		return fmt.Sprintf("Request failed (HTTP %d): %s", httpErr.StatusCode, httpErr.Message), false
	}
}
