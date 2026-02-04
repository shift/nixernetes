API Reference

Complete documentation for Nixernetes REST API endpoints.

Base URL: http://localhost:8080 (development)

Table of Contents

1. Health & Status
2. Projects API
3. Manifests API
4. Configurations API
5. Activity API
6. Error Responses

1. HEALTH & STATUS

Get API Health Status

GET /health

Response: 200 OK
{
  "status": "ok"
}

Get Cluster Information

GET /api/cluster/info

Response: 200 OK
{
  "version": "1.27.0",
  "nodes": 3,
  "namespaces": 8,
  "pods": 45,
  "services": 12
}

2. PROJECTS API

List All Projects

GET /api/projects?status=active

Query Parameters:
- status (optional): Filter by status (active, archived, error)

Response: 200 OK
[
  {
    "id": "proj-123",
    "name": "Production Cluster",
    "description": "Main production deployment",
    "status": "active",
    "owner": "admin",
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-20T14:45:00Z"
  }
]

Create Project

POST /api/projects

Request Body:
{
  "name": "New Project",
  "description": "Project description",
  "owner": "user@example.com"
}

Response: 201 Created
{
  "id": "proj-new-123",
  "name": "New Project",
  "description": "Project description",
  "status": "active",
  "owner": "user@example.com",
  "createdAt": "2024-01-20T15:00:00Z",
  "updatedAt": "2024-01-20T15:00:00Z"
}

Get Project Details

GET /api/projects/:id

Path Parameters:
- id: Project ID

Response: 200 OK
{
  "id": "proj-123",
  "name": "Production Cluster",
  "description": "Main production deployment",
  "status": "active",
  "owner": "admin",
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-20T14:45:00Z",
  "resourceCount": 45,
  "manifestCount": 23,
  "manifests": [
    {
      "id": "mf-456",
      "name": "nginx-config",
      "kind": "ConfigMap",
      "valid": true
    }
  ],
  "config": {}
}

Update Project

PUT /api/projects/:id

Request Body:
{
  "name": "Updated Name",
  "description": "New description",
  "status": "archived"
}

Response: 200 OK
{
  "id": "proj-123",
  "name": "Updated Name",
  ...
}

Delete Project

DELETE /api/projects/:id

Response: 200 OK
{
  "message": "Project deleted"
}

3. MANIFESTS API

List Manifests for Project

GET /api/manifests?projectId=proj-123

Query Parameters:
- projectId (required): Project ID

Response: 200 OK
[
  {
    "id": "mf-123",
    "projectId": "proj-123",
    "name": "app-config",
    "kind": "ConfigMap",
    "apiVersion": "v1",
    "namespace": "default",
    "data": {
      "app.conf": "key=value"
    },
    "valid": true,
    "createdAt": "2024-01-15T10:30:00Z",
    "updatedAt": "2024-01-20T14:45:00Z"
  }
]

Create Manifest

POST /api/manifests

Request Body:
{
  "projectId": "proj-123",
  "name": "nginx-deployment",
  "kind": "Deployment",
  "apiVersion": "apps/v1",
  "namespace": "default",
  "data": {
    "spec": {
      "replicas": 3,
      "selector": {
        "matchLabels": {
          "app": "nginx"
        }
      }
    }
  },
  "valid": false
}

Response: 201 Created
{
  "id": "mf-new-789",
  "projectId": "proj-123",
  "name": "nginx-deployment",
  ...
}

Get Manifest Details

GET /api/manifests/:id

Path Parameters:
- id: Manifest ID

Response: 200 OK
{
  "id": "mf-123",
  "projectId": "proj-123",
  "name": "app-config",
  "kind": "ConfigMap",
  "apiVersion": "v1",
  "namespace": "default",
  "data": {
    "app.conf": "key=value"
  },
  "valid": true,
  "createdAt": "2024-01-15T10:30:00Z",
  "updatedAt": "2024-01-20T14:45:00Z"
}

Update Manifest

PUT /api/manifests/:id

Request Body:
{
  "name": "updated-config",
  "data": {
    "app.conf": "new=config"
  },
  "valid": true
}

Response: 200 OK
{
  "id": "mf-123",
  ...
}

Delete Manifest

DELETE /api/manifests/:id

Response: 200 OK
{
  "message": "Manifest deleted"
}

Validate Manifest

POST /api/manifests/:id/validate

Response: 200 OK
{
  "valid": true,
  "errors": [],
  "warnings": [
    {
      "field": "apiVersion",
      "message": "apiVersion should be specified"
    }
  ]
}

Validation Error Example:

{
  "valid": false,
  "errors": [
    {
      "field": "kind",
      "message": "kind is required"
    },
    {
      "field": "metadata.name",
      "message": "metadata.name is required"
    }
  ],
  "warnings": []
}

4. CONFIGURATIONS API

List Configurations

GET /api/configs?namespace=default&kind=ConfigMap

Query Parameters:
- namespace (optional): Filter by namespace
- kind (optional): Filter by kind

Response: 200 OK
[
  {
    "id": "cfg-123",
    "name": "app-config",
    "kind": "ConfigMap",
    "namespace": "default",
    "created": "2024-01-15T10:30:00Z",
    "updated": "2024-01-20T14:45:00Z",
    "size": 1024
  }
]

Create Configuration

POST /api/configs

Request Body:
{
  "name": "database-config",
  "kind": "Secret",
  "namespace": "default",
  "data": {
    "password": "secret123",
    "username": "admin"
  }
}

Response: 201 Created
{
  "id": "cfg-new-456",
  "name": "database-config",
  ...
}

Delete Configuration

DELETE /api/configs/:id

Response: 200 OK
{
  "message": "Config deleted"
}

5. ACTIVITY API

Get Recent Activity

GET /api/activity?limit=50

Query Parameters:
- limit (optional): Number of recent activities (default: 50)

Response: 200 OK
[
  {
    "id": "act-123",
    "type": "create",
    "resourceType": "manifest",
    "resourceId": "mf-456",
    "user": "admin",
    "description": "Manifest 'nginx' created",
    "metadata": {
      "kind": "Deployment"
    },
    "createdAt": "2024-01-20T15:30:00Z"
  },
  {
    "id": "act-122",
    "type": "update",
    "resourceType": "manifest",
    "resourceId": "mf-456",
    "user": "admin",
    "description": "Manifest updated",
    "metadata": null,
    "createdAt": "2024-01-20T15:25:00Z"
  },
  {
    "id": "act-121",
    "type": "validate",
    "resourceType": "manifest",
    "resourceId": "mf-456",
    "user": null,
    "description": "Manifest passed validation",
    "metadata": {
      "valid": true,
      "errors": [],
      "warnings": []
    },
    "createdAt": "2024-01-20T15:20:00Z"
  }
]

Activity Types:
- create: Resource created
- update: Resource updated
- delete: Resource deleted
- validate: Manifest validation performed

6. ERROR RESPONSES

All errors follow this format:

{
  "error": "Error description",
  "message": "Detailed error message (development only)"
}

Common Status Codes:

200 OK
Request succeeded

201 Created
Resource created successfully

400 Bad Request
Invalid request parameters

Example:
{
  "error": "name and kind are required"
}

404 Not Found
Resource not found

Example:
{
  "error": "Project not found"
}

500 Internal Server Error
Server error

Example:
{
  "error": "Failed to create project",
  "message": "Database connection error (development only)"
}

Rate Limiting

Current implementation has no rate limiting. For production, consider:
- Express rate-limit middleware
- Per-IP or per-user limits
- Exponential backoff for retries

Authentication

Current implementation has no authentication. For production:
- Add JWT bearer token validation
- Implement user roles and permissions
- Add API key support

CORS

Allowed origins can be configured via CORS_ORIGIN environment variable.

Default (development): http://localhost:5173

Example for Production:

CORS_ORIGIN=https://example.com npm run start

Testing Endpoints

Using curl:

Get health status:
  curl http://localhost:8080/health

List projects:
  curl http://localhost:8080/api/projects

Create project:
  curl -X POST http://localhost:8080/api/projects \
    -H "Content-Type: application/json" \
    -d '{"name":"Test","owner":"admin"}'

Using VS Code REST Client:

Create a file test.http:

@baseUrl = http://localhost:8080

### Health check
GET {{baseUrl}}/health

### List projects
GET {{baseUrl}}/api/projects?status=active

### Create project
POST {{baseUrl}}/api/projects
Content-Type: application/json

{
  "name": "Test Project",
  "owner": "admin"
}

Then use the "Send Request" CodeLens to test.

Pagination

Current implementation returns all results. For production, add:

GET /api/projects?page=1&limit=20

Response includes:
{
  "data": [...],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 100,
    "pages": 5
  }
}

Filtering and Sorting

Consider adding for future versions:

GET /api/manifests?projectId=proj-123&kind=Deployment&sort=name&order=asc

Bulk Operations

Consider implementing for future versions:

POST /api/manifests/batch
DELETE /api/manifests/batch
