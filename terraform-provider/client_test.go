package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestPostRequest(t *testing.T) {
	// Create a mock server
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/configs" {
			t.Errorf("Expected request to /configs, got %s", r.URL.Path)
		}
		if r.Method != "POST" {
			t.Errorf("Expected POST method, got %s", r.Method)
		}

		// Check authentication
		username, password, ok := r.BasicAuth()
		if !ok || username != "testuser" || password != "testpass" {
			t.Error("Expected valid basic auth credentials")
		}

		// Send response
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"id":         "config-123",
			"name":       "test-config",
			"created_at": "2024-02-04T00:00:00Z",
			"updated_at": "2024-02-04T00:00:00Z",
		})
	}))
	defer server.Close()

	client := &NixernetesClient{
		Endpoint: server.URL,
		Username: "testuser",
		Password: "testpass",
	}

	body := map[string]interface{}{
		"name":          "test-config",
		"configuration": "{ test }",
		"environment":   "development",
	}

	result, err := client.Post(context.Background(), "/configs", body)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if result["id"] != "config-123" {
		t.Errorf("Expected id 'config-123', got %v", result["id"])
	}
}

func TestGetRequest(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "GET" {
			t.Errorf("Expected GET method, got %s", r.Method)
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"id":            "config-123",
			"name":          "test-config",
			"configuration": "{ test }",
			"environment":   "development",
			"updated_at":    "2024-02-04T00:00:00Z",
		})
	}))
	defer server.Close()

	client := &NixernetesClient{
		Endpoint: server.URL,
		Username: "testuser",
		Password: "testpass",
	}

	result, err := client.Get(context.Background(), "/configs/config-123")
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if result["id"] != "config-123" {
		t.Errorf("Expected id 'config-123', got %v", result["id"])
	}
}

func TestPutRequest(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "PUT" {
			t.Errorf("Expected PUT method, got %s", r.Method)
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]interface{}{
			"updated_at": "2024-02-04T01:00:00Z",
		})
	}))
	defer server.Close()

	client := &NixernetesClient{
		Endpoint: server.URL,
		Username: "testuser",
		Password: "testpass",
	}

	body := map[string]interface{}{
		"name": "updated-config",
	}

	result, err := client.Put(context.Background(), "/configs/config-123", body)
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}

	if result["updated_at"] != "2024-02-04T01:00:00Z" {
		t.Errorf("Expected updated_at to be updated")
	}
}

func TestDeleteRequest(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != "DELETE" {
			t.Errorf("Expected DELETE method, got %s", r.Method)
		}
		w.WriteHeader(http.StatusNoContent)
	}))
	defer server.Close()

	client := &NixernetesClient{
		Endpoint: server.URL,
		Username: "testuser",
		Password: "testpass",
	}

	err := client.Delete(context.Background(), "/configs/config-123")
	if err != nil {
		t.Fatalf("Unexpected error: %v", err)
	}
}

func TestErrorHandling(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusInternalServerError)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": "Internal server error",
		})
	}))
	defer server.Close()

	client := &NixernetesClient{
		Endpoint: server.URL,
		Username: "testuser",
		Password: "testpass",
	}

	_, err := client.Get(context.Background(), "/configs/invalid")
	if err == nil {
		t.Error("Expected error for failed request")
	}

	httpErr, ok := err.(*HTTPError)
	if !ok {
		t.Fatalf("Expected HTTPError, got %T", err)
	}

	if httpErr.StatusCode != 500 {
		t.Errorf("Expected status code 500, got %d", httpErr.StatusCode)
	}
}

func TestAuthenticationFailure(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusUnauthorized)
		json.NewEncoder(w).Encode(map[string]interface{}{
			"error": "Unauthorized",
		})
	}))
	defer server.Close()

	client := &NixernetesClient{
		Endpoint: server.URL,
		Username: "wronguser",
		Password: "wrongpass",
	}

	_, err := client.Get(context.Background(), "/configs")
	if err == nil {
		t.Error("Expected authentication error")
	}
}

func TestContextCancellation(t *testing.T) {
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Simulate slow response
		select {}
	}))
	defer server.Close()

	client := &NixernetesClient{
		Endpoint: server.URL,
		Username: "testuser",
		Password: "testpass",
	}

	ctx, cancel := context.WithCancel(context.Background())
	cancel() // Cancel immediately

	_, err := client.Get(ctx, "/configs")
	if err == nil {
		t.Error("Expected context cancellation error")
	}
}
