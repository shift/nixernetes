package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"

	"context"
	"github.com/hashicorp/terraform-plugin-log/tflog"
)

// HTTPError represents an error from the Nixernetes API
type HTTPError struct {
	StatusCode int
	Body       string
	Message    string
}

func (e *HTTPError) Error() string {
	return fmt.Sprintf("API error (HTTP %d): %s", e.StatusCode, e.Message)
}

// Post sends a POST request to the Nixernetes API
func (c *NixernetesClient) Post(ctx context.Context, endpoint string, body map[string]interface{}) (map[string]interface{}, error) {
	return c.doRequest(ctx, "POST", endpoint, body)
}

// Get sends a GET request to the Nixernetes API
func (c *NixernetesClient) Get(ctx context.Context, endpoint string) (map[string]interface{}, error) {
	return c.doRequest(ctx, "GET", endpoint, nil)
}

// Put sends a PUT request to the Nixernetes API
func (c *NixernetesClient) Put(ctx context.Context, endpoint string, body map[string]interface{}) (map[string]interface{}, error) {
	return c.doRequest(ctx, "PUT", endpoint, body)
}

// Delete sends a DELETE request to the Nixernetes API
func (c *NixernetesClient) Delete(ctx context.Context, endpoint string) error {
	_, err := c.doRequest(ctx, "DELETE", endpoint, nil)
	return err
}

// doRequest performs the actual HTTP request
func (c *NixernetesClient) doRequest(ctx context.Context, method string, endpoint string, body map[string]interface{}) (map[string]interface{}, error) {
	// Build the URL
	url := fmt.Sprintf("%s%s", strings.TrimSuffix(c.Endpoint, "/"), endpoint)

	tflog.Debug(ctx, "Making API request", map[string]any{
		"method": method,
		"url":    url,
	})

	// Create request
	var reqBody io.Reader
	if body != nil {
		jsonBody, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal request body: %w", err)
		}
		reqBody = bytes.NewBuffer(jsonBody)
	}

	req, err := http.NewRequestWithContext(ctx, method, url, reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	// Set headers
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "application/json")
	req.Header.Set("User-Agent", "terraform-provider-nixernetes/1.0")

	// Set authentication
	if c.Username != "" && c.Password != "" {
		req.SetBasicAuth(c.Username, c.Password)
	}

	// Send request
	client := &http.Client{}
	resp, err := client.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to send request: %w", err)
	}
	defer resp.Body.Close()

	// Read response body
	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response body: %w", err)
	}

	// Check for error responses
	if resp.StatusCode < 200 || resp.StatusCode >= 300 {
		var errMsg string
		var errResp map[string]interface{}
		if err := json.Unmarshal(respBody, &errResp); err == nil {
			if msg, ok := errResp["message"]; ok {
				errMsg = fmt.Sprintf("%v", msg)
			} else if msg, ok := errResp["error"]; ok {
				errMsg = fmt.Sprintf("%v", msg)
			}
		}
		if errMsg == "" {
			errMsg = string(respBody)
		}

		tflog.Error(ctx, "API request failed", map[string]any{
			"status_code": resp.StatusCode,
			"error":       errMsg,
		})

		return nil, &HTTPError{
			StatusCode: resp.StatusCode,
			Body:       string(respBody),
			Message:    errMsg,
		}
	}

	// Parse response
	var result map[string]interface{}
	if len(respBody) > 0 {
		if err := json.Unmarshal(respBody, &result); err != nil {
			return nil, fmt.Errorf("failed to parse response: %w", err)
		}
	} else {
		result = make(map[string]interface{})
	}

	tflog.Debug(ctx, "API request successful", map[string]any{
		"status_code": resp.StatusCode,
		"method":      method,
		"url":         url,
	})

	return result, nil
}
