# Tutorial 2: Database + API Deployment

Build on [Tutorial 1](TUTORIAL_1_FIRST_DEPLOYMENT.md) to create a complete backend system with a database and REST API.

## What You'll Learn

- Deploying a PostgreSQL database
- Deploying a Node.js REST API
- Managing persistent data with PersistentVolumeClaims
- Connecting microservices with environment variables
- Managing secrets for database credentials
- Health checks for databases
- Scaling multi-tier applications

## Prerequisites

- Completed Tutorial 1
- Understanding of databases and APIs
- PostgreSQL knowledge (basic)
- Node.js or Python knowledge (basic)

## Architecture

We'll deploy:

```
┌─────────────────────────────────────────┐
│        External Client                  │
└────────────────┬────────────────────────┘
                 │
                 ▼
        ┌─────────────────┐
        │  API Service    │
        │  (Node.js)      │
        │  port 3000      │
        └────────┬────────┘
                 │
                 ▼ (port 5432)
        ┌─────────────────┐
        │  PostgreSQL     │
        │  (Database)     │
        │  Persistent     │
        └─────────────────┘
```

## Step 1: Create Project Structure

```bash
# Create the tutorial project directory
mkdir -p tutorial-2-database-api
cd tutorial-2-database-api

# Create subdirectories
mkdir -p nix-config
mkdir -p api-src

# Initialize Nixernetes project
cd nix-config
../bin/nixernetes init .
cd ..
```

## Step 2: Create PostgreSQL Configuration

Create `nix-config/postgres.nix`:

```nix
{ nixernetes }:

let
  modules = nixernetes.modules;
in {
  # PostgreSQL StatefulSet for persistent data
  postgres = {
    name = "postgres";
    namespace = "default";
    
    # StatefulSet for persistent database
    statefulSet = modules.databases.mkPostgreSQL {
      name = "postgres";
      image = "postgres:16-alpine";
      version = "16";
      
      # Persistent storage
      storage = {
        size = "10Gi";
        storageClassName = "standard"; # Use your cluster's storage class
      };
      
      # Environment variables from secret
      env = [
        {
          name = "POSTGRES_DB";
          value = "app_db";
        }
        {
          name = "POSTGRES_USER";
          value = "app_user";
        }
        {
          name = "POSTGRES_PASSWORD";
          valueFrom.secretKeyRef = {
            name = "postgres-credentials";
            key = "password";
          };
        }
      ];
      
      # Resource limits
      resources = {
        requests = {
          memory = "256Mi";
          cpu = "250m";
        };
        limits = {
          memory = "512Mi";
          cpu = "500m";
        };
      };
      
      # Health checks
      livenessProbe = {
        exec.command = [ "pg_isready" "-U" "app_user" ];
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };
      
      readinessProbe = {
        exec.command = [ "pg_isready" "-U" "app_user" ];
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };
    };
    
    # Kubernetes Service for database access
    service = modules.services.mkSimpleService {
      name = "postgres";
      selector = { app = "postgres"; };
      ports = [{
        port = 5432;
        targetPort = 5432;
        protocol = "TCP";
      }];
      clusterIP = "None"; # Headless service for StatefulSet
    };
  };
  
  # Create the database credentials secret
  secrets = {
    postgresCredentials = {
      apiVersion = "v1";
      kind = "Secret";
      metadata = {
        name = "postgres-credentials";
        namespace = "default";
      };
      type = "Opaque";
      stringData = {
        # In production, use external secrets manager!
        password = "changeme123!";
        username = "app_user";
      };
    };
  };
}
```

## Step 3: Create Node.js API Configuration

Create `nix-config/api.nix`:

```nix
{ nixernetes }:

let
  modules = nixernetes.modules;
in {
  # Node.js API Deployment
  api = {
    name = "api";
    namespace = "default";
    
    deployment = modules.deployments.mkSimpleDeployment {
      name = "api";
      image = "node:20-alpine";
      replicas = 3;
      
      # Build your image with your code
      # In production, use your built image: "my-registry.com/my-api:v1.0"
      
      # Container port
      ports = [{
        containerPort = 3000;
        name = "http";
      }];
      
      # Pass database connection as environment variables
      env = [
        {
          name = "NODE_ENV";
          value = "production";
        }
        {
          name = "DATABASE_HOST";
          value = "postgres.default.svc.cluster.local";
        }
        {
          name = "DATABASE_PORT";
          value = "5432";
        }
        {
          name = "DATABASE_NAME";
          value = "app_db";
        }
        {
          name = "DATABASE_USER";
          value = "app_user";
        }
        {
          name = "DATABASE_PASSWORD";
          valueFrom.secretKeyRef = {
            name = "postgres-credentials";
            key = "password";
          };
        }
        {
          name = "LOG_LEVEL";
          value = "info";
        }
      ];
      
      # Resource limits
      resources = {
        requests = {
          memory = "128Mi";
          cpu = "100m";
        };
        limits = {
          memory = "256Mi";
          cpu = "500m";
        };
      };
      
      # Application health checks
      livenessProbe = {
        httpGet = {
          path = "/health";
          port = 3000;
        };
        initialDelaySeconds = 15;
        periodSeconds = 10;
        timeoutSeconds = 5;
      };
      
      readinessProbe = {
        httpGet = {
          path = "/ready";
          port = 3000;
        };
        initialDelaySeconds = 5;
        periodSeconds = 5;
        timeoutSeconds = 3;
      };
    };
    
    # Service to expose API
    service = modules.services.mkSimpleService {
      name = "api";
      selector = { app = "api"; };
      ports = [{
        port = 80;
        targetPort = 3000;
        protocol = "TCP";
      }];
      type = "ClusterIP";
    };
    
    # Ingress to expose externally
    ingress = modules.ingress.mkSimpleIngress {
      name = "api";
      hosts = [{
        host = "api.example.com";
        paths = [{
          path = "/";
          pathType = "Prefix";
          backend = {
            service = {
              name = "api";
              port = { number = 80; };
            };
          };
        }];
      }];
    };
  };
}
```

## Step 4: Create Combined Configuration

Create `nix-config/app.nix` that combines both:

```nix
{ nixernetes }:

let
  postgres = import ./postgres.nix { inherit nixernetes; };
  api = import ./api.nix { inherit nixernetes; };
in {
  # Combine all resources
  resources = 
    postgres.resources ++
    api.resources;
}
```

Or use individual files:

```nix
# nix-config/flake.nix
{
  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nixernetes = import ./src/lib { inherit pkgs; };
      in {
        packages = {
          postgres = import ./postgres.nix { inherit nixernetes; };
          api = import ./api.nix { inherit nixernetes; };
          all = import ./app.nix { inherit nixernetes; };
        };
      }
    );
}
```

## Step 5: Validate Configuration

```bash
# Validate both configurations
./bin/nixernetes validate nix-config/postgres.nix
./bin/nixernetes validate nix-config/api.nix

# All checks should pass
```

## Step 6: Generate Manifests

```bash
# Generate database manifests
./bin/nixernetes generate nix-config/postgres.nix > postgres.yaml

# Generate API manifests
./bin/nixernetes generate nix-config/api.nix > api.yaml

# Combine them
cat postgres.yaml api.yaml > all.yaml

# View the generated manifests
kubectl apply -f all.yaml --dry-run=client
```

## Step 7: Deploy Database First

Always deploy the database before the API:

```bash
# Deploy PostgreSQL
kubectl apply -f postgres.yaml

# Wait for database to be ready
kubectl rollout status statefulset/postgres -w

# Verify PostgreSQL is running
kubectl get pods -l app=postgres
kubectl logs statefulset/postgres

# Test database connection
kubectl exec -it postgres-0 -- psql -U app_user -d app_db -c "SELECT 1;"
```

## Step 8: Deploy API

```bash
# Deploy API
kubectl apply -f api.yaml

# Wait for API deployment
kubectl rollout status deployment/api -w

# Check API pods
kubectl get pods -l app=api

# View API logs
kubectl logs -f deployment/api
```

## Step 9: Test the Connection

```bash
# Port-forward to the API
kubectl port-forward svc/api 8080:80 &

# Test API endpoint (assuming /health exists)
curl http://localhost:8080/health

# Test database query endpoint
curl http://localhost:8080/api/users

# Kill port-forward
jobs
kill %1
```

## Step 10: Verify Data Persistence

```bash
# Get current pod name
POD=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')

# Connect to database
kubectl exec -it $POD -- psql -U app_user -d app_db

# Create a test table
CREATE TABLE test (id SERIAL PRIMARY KEY, name VARCHAR(100));
INSERT INTO test (name) VALUES ('Hello World');
SELECT * FROM test;
\q

# Delete the pod to test persistence
kubectl delete pod $POD

# Wait for new pod to start
kubectl get pods -w -l app=postgres

# Connect again and verify data persists
POD=$(kubectl get pods -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl exec -it $POD -- psql -U app_user -d app_db -c "SELECT * FROM test;"

# Output should show your data still exists!
```

## Step 11: Scale the API

```nix
# Update api.nix: increase replicas
replicas = 5;

# Redeploy
./bin/nixernetes deploy nix-config/api.nix

# Watch new pods start
kubectl get pods -w -l app=api

# Database automatically supports multiple connections
```

## Step 12: Add Network Policy

Create `nix-config/network-policy.nix`:

```nix
{ nixernetes }:

let
  modules = nixernetes.modules;
in {
  # Allow API to PostgreSQL
  apiToPostgres = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata = {
      name = "api-to-postgres";
      namespace = "default";
    };
    spec = {
      podSelector = {
        matchLabels = { app = "postgres"; };
      };
      policyTypes = [ "Ingress" ];
      ingress = [{
        from = [{ podSelector = { matchLabels = { app = "api"; }; }; }];
        ports = [{
          protocol = "TCP";
          port = 5432;
        }];
      }];
    };
  };
  
  # Allow Ingress to API
  ingressToApi = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata = {
      name = "ingress-to-api";
      namespace = "default";
    };
    spec = {
      podSelector = {
        matchLabels = { app = "api"; };
      };
      policyTypes = [ "Ingress" ];
      ingress = [{
        from = [{ namespaceSelector = {}; }];
        ports = [{
          protocol = "TCP";
          port = 3000;
        }];
      }];
    };
  };
}
```

Deploy network policies:

```bash
./bin/nixernetes generate nix-config/network-policy.nix | kubectl apply -f -
```

## Summary

You've now deployed:
✅ PostgreSQL database with persistent storage
✅ Node.js API connected to database
✅ Secrets management for credentials
✅ Health checks for both services
✅ Service discovery between pods
✅ Network policies for security
✅ Data persistence verification
✅ Scaling independent services

## Next Steps

- **[Tutorial 3: Complete Microservices Stack](TUTORIAL_3_MICROSERVICES.md)** - Add frontend, caching, monitoring
- **[Database Management Guide](../docs/DATABASE_MANAGEMENT.md)** - Advanced database patterns
- **[Security Hardening](../SECURITY_HARDENING.md)** - Secure your deployment
- **[Production Deployment](../DEPLOY_AWS_EKS.md)** - Deploy to AWS, GCP, or Azure

## Troubleshooting

### API can't connect to database
```bash
# Check database is running
kubectl get statefulset postgres

# Check secret exists
kubectl get secret postgres-credentials

# Verify network policy isn't blocking traffic
kubectl get networkpolicies

# Check logs
kubectl logs deployment/api
kubectl logs statefulset/postgres
```

### Database won't start
```bash
# Check storage class exists
kubectl get storageclass

# Check PVC
kubectl get pvc

# Check pod events
kubectl describe pod postgres-0
```

### Data not persisting
```bash
# Verify PVC is bound
kubectl get pvc

# Check volume
kubectl get pv

# Check storage backend is working
# This depends on your storage provider
```
