# Performance Tuning & Optimization Guide

## Table of Contents

1. [Resource Optimization](#resource-optimization)
2. [Network Performance](#network-performance)
3. [Database Optimization](#database-optimization)
4. [Caching Strategies](#caching-strategies)
5. [Scalability](#scalability)
6. [Monitoring Performance](#monitoring-performance)
7. [Best Practices](#best-practices)

## Resource Optimization

### Right-sizing Containers

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  # Wrong: No resource limits
  unoptimized = k8s.mkDeployment {
    name = "app";
    containers = [{
      image = "myapp:latest";
      # Missing: requests and limits
    }];
  };
  
  # Correct: Properly sized resources
  optimized = k8s.mkDeployment {
    name = "app";
    replicas = 3;
    
    # Set requests to match typical usage
    # Set limits to prevent resource hogging
    containers = [{
      image = "myapp:latest";
      
      resources = {
        # Requests: what K8s allocates
        requests = {
          cpu = "100m";      # 0.1 CPU = 1/10th of core
          memory = "128Mi";  # 128 megabytes
        };
        
        # Limits: maximum the pod can use
        limits = {
          cpu = "500m";      # 1/2 CPU core
          memory = "512Mi";  # 512 megabytes
        };
      };
    }];
  };
}
```

**Sizing Guidelines:**

| Workload Type | CPU Request | CPU Limit | Memory Request | Memory Limit |
|---------------|------------|-----------|----------------|--------------|
| Web API       | 100m       | 500m      | 128Mi          | 512Mi        |
| Heavy compute | 500m       | 2000m     | 512Mi          | 2Gi          |
| Background job| 50m        | 200m      | 64Mi           | 256Mi        |
| Database      | 500m       | 4000m     | 1Gi            | 4Gi          |
| Cache (Redis) | 100m       | 1000m     | 256Mi          | 2Gi          |

### Pod Density Optimization

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  # Low density: Few replicas, high resources
  lowDensity = k8s.mkDeployment {
    name = "app";
    replicas = 1;
    nodeSelector = { workload = "compute"; };
    
    containers = [{
      image = "myapp:latest";
      resources = {
        requests = { cpu = "2"; memory = "4Gi"; };
        limits = { cpu = "4"; memory = "8Gi"; };
      };
    }];
  };
  
  # High density: Many replicas, lower resources per pod
  highDensity = k8s.mkDeployment {
    name = "app";
    replicas = 10;
    nodeSelector = { workload = "general"; };
    
    containers = [{
      image = "myapp:latest";
      resources = {
        requests = { cpu = "100m"; memory = "256Mi"; };
        limits = { cpu = "200m"; memory = "512Mi"; };
      };
    }];
  };
}
```

## Network Performance

### Using NodePort vs LoadBalancer

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  # Internal traffic: Use ClusterIP (fast, no external overhead)
  internal = k8s.mkService {
    name = "internal-api";
    type = "ClusterIP";  # Default, best for internal traffic
    ports = [{ port = 8080; targetPort = 8080; }];
  };
  
  # Development: Use NodePort (for local testing)
  development = k8s.mkService {
    name = "dev-api";
    type = "NodePort";   # Exposes on node port 30000-32767
    ports = [{ port = 80; targetPort = 8080; }];
  };
  
  # Production external: Use LoadBalancer or Ingress
  production = k8s.mkService {
    name = "prod-api";
    type = "LoadBalancer";  # Cloud provider LB
    ports = [{ port = 80; targetPort = 8080; }];
  };
}
```

### Connection Pool Settings

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  deployment = k8s.mkDeployment {
    name = "app";
    
    containers = [{
      image = "myapp:latest";
      
      # Environment variables for connection pooling
      env = [
        # Database connections
        { name = "DB_POOL_SIZE"; value = "20"; }
        { name = "DB_MAX_OVERFLOW"; value = "10"; }
        { name = "DB_POOL_TIMEOUT"; value = "30"; }
        
        # HTTP client settings
        { name = "HTTP_MAX_CONNECTIONS"; value = "100"; }
        { name = "HTTP_TIMEOUT"; value = "30"; }
        
        # Cache settings
        { name = "CACHE_TTL"; value = "3600"; }
        { name = "CACHE_SIZE"; value = "1000"; }
      ];
    }];
  };
}
```

## Database Optimization

### Connection Pooling

```nix
let
  db = import ./src/lib/database-management.nix { inherit lib; };
in
{
  postgres = db.mkPostgreSQL {
    name = "app-db";
    
    # Performance tuning parameters
    parameters = {
      # Memory settings
      shared_buffers = "4GB";      # 25% of system memory
      effective_cache_size = "12GB"; # 75% of system memory
      work_mem = "10MB";           # Per-operation memory
      
      # Connection settings
      max_connections = "200";
      max_prepared_transactions = "100";
      
      # WAL settings
      wal_buffers = "16MB";
      default_statistics_target = "100";
    };
  };
}
```

### Query Optimization

```sql
-- Good: Uses indexes
SELECT id, name FROM users WHERE user_id = 123;

-- Bad: Full table scan
SELECT id, name FROM users WHERE name LIKE '%john%';

-- Good: Optimized with index
SELECT id, name FROM users WHERE name LIKE 'john%';
```

## Caching Strategies

### Application-Level Caching

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  db = import ./src/lib/database-management.nix { inherit lib; };
in
{
  # Redis for caching
  cache = db.mkRedis {
    name = "app-cache";
    maxmemory = "2Gi";
    maxmemoryPolicy = "allkeys-lru";  # Evict least recently used
    
    persistence = false;  # Cache can be recreated
  };
  
  # Application with cache
  app = k8s.mkDeployment {
    name = "app";
    
    containers = [{
      image = "myapp:latest";
      
      env = [
        { name = "CACHE_ENABLED"; value = "true"; }
        { name = "CACHE_TTL"; value = "3600"; }
        { name = "CACHE_HOST"; value = "app-cache"; }
        { name = "CACHE_PORT"; value = "6379"; }
      ];
    }];
  };
}
```

### HTTP Caching

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  deployment = k8s.mkDeployment {
    name = "web-server";
    
    containers = [{
      image = "nginx:latest";
      
      volumeMounts = [{
        name = "nginx-config";
        mountPath = "/etc/nginx/conf.d";
      }];
    }];
    
    volumes = [{
      name = "nginx-config";
      configMap = {
        name = "nginx-cache-config";
      };
    }];
  };
}
```

Create `nginx-cache-config.nix`:

```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=http_cache:10m max_size=1g inactive=60m use_temp_path=off;

server {
    listen 80;
    
    # Cache GET requests
    proxy_cache http_cache;
    proxy_cache_key "$scheme$request_method$host$request_uri";
    proxy_cache_valid 200 10m;
    proxy_cache_valid 404 1m;
    
    # Add cache status header
    add_header X-Cache-Status $upstream_cache_status;
    
    location / {
        proxy_pass http://backend;
        proxy_cache_bypass $http_pragma $http_authorization;
    }
}
```

## Scalability

### Horizontal Pod Autoscaling

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  deployment = k8s.mkDeployment {
    name = "scalable-app";
    
    # Start with 3 replicas
    replicas = 3;
    
    containers = [{
      image = "myapp:latest";
      
      resources = {
        requests = { cpu = "500m"; memory = "512Mi"; };
        limits = { cpu = "1000m"; memory = "1Gi"; };
      };
    }];
  };
  
  # Auto-scale based on CPU
  hpa = {
    apiVersion = "autoscaling/v2";
    kind = "HorizontalPodAutoscaler";
    metadata = {
      name = "scalable-app-hpa";
    };
    spec = {
      scaleTargetRef = {
        apiVersion = "apps/v1";
        kind = "Deployment";
        name = "scalable-app";
      };
      
      minReplicas = 2;
      maxReplicas = 20;
      
      metrics = [
        {
          type = "Resource";
          resource = {
            name = "cpu";
            target = { type = "Utilization"; averageUtilization = 70; };
          };
        }
        {
          type = "Resource";
          resource = {
            name = "memory";
            target = { type = "Utilization"; averageUtilization = 80; };
          };
        }
      ];
      
      behavior = {
        scaleDown = {
          stabilizationWindowSeconds = 300;
          policies = [{
            type = "Percent";
            value = 50;
            periodSeconds = 60;
          }];
        };
        
        scaleUp = {
          stabilizationWindowSeconds = 0;
          policies = [{
            type = "Percent";
            value = 100;
            periodSeconds = 30;
          }];
        };
      };
    };
  };
}
```

### Vertical Pod Autoscaling (Right-sizing)

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  vpa = {
    apiVersion = "autoscaling.k8s.io/v1";
    kind = "VerticalPodAutoscaler";
    metadata = {
      name = "app-vpa";
    };
    spec = {
      targetRef = {
        apiVersion = "apps/v1";
        kind = "Deployment";
        name = "myapp";
      };
      
      updatePolicy = {
        updateMode = "Auto";  # Auto-update and restart pods
      };
      
      resourcePolicy = {
        containerPolicies = [{
          containerName = "*";
          minAllowed = {
            cpu = "50m";
            memory = "64Mi";
          };
          maxAllowed = {
            cpu = "2";
            memory = "4Gi";
          };
        }];
      };
    };
  };
}
```

## Monitoring Performance

### Key Metrics to Track

```nix
let
  perf = import ./src/lib/performance-analysis.nix { inherit lib; };
in
{
  monitoring = perf.mkPerformanceAnalysis {
    namespace = "monitoring";
    name = "app-perf";
    
    # Track these metrics
    metrics = [
      # Container metrics
      "container_cpu_usage_seconds_total"
      "container_memory_usage_bytes"
      "container_network_receive_bytes_total"
      "container_network_transmit_bytes_total"
      
      # Pod metrics
      "pod_cpu_usage_seconds_total"
      "pod_memory_usage_bytes"
      
      # Application metrics
      "http_requests_total"
      "http_request_duration_seconds"
      "database_connections_active"
      "cache_hits_total"
      "cache_misses_total"
    ];
    
    # Set up alerts
    alerts = [
      {
        name = "HighCpuUsage";
        threshold = 80;  # percent
        duration = "5m";
      }
      {
        name = "HighMemoryUsage";
        threshold = 85;  # percent
        duration = "5m";
      }
      {
        name = "PodRestarts";
        threshold = 3;
        duration = "1h";
      }
    ];
  };
}
```

### Performance Benchmarking

```bash
#!/bin/bash

# Load test with wrk
wrk -t12 -c400 -d30s http://myapp.example.com

# Database performance
pgbench -U postgres -d mydb -c 10 -j 2 -T 60

# Network performance
iperf3 -c 10.0.0.1 -t 60 -R

# Container metrics
kubectl top nodes
kubectl top pods -A
```

## Best Practices

### 1. Always Set Resource Requests

```nix
# Bad: No requests
containers = [{
  image = "app:latest";
  # Missing resources
}];

# Good: Defined requests and limits
containers = [{
  image = "app:latest";
  resources = {
    requests = { cpu = "100m"; memory = "128Mi"; };
    limits = { cpu = "500m"; memory = "512Mi"; };
  };
}];
```

### 2. Use ReadinessProbes for Traffic

```nix
containers = [{
  image = "app:latest";
  
  # Readiness: Can the pod serve traffic?
  readinessProbe = {
    httpGet = { path = "/health/ready"; port = 8080; };
    initialDelaySeconds = 10;
    periodSeconds = 5;
  };
  
  # Liveness: Is the pod alive?
  livenessProbe = {
    httpGet = { path = "/health/live"; port = 8080; };
    initialDelaySeconds = 30;
    periodSeconds = 10;
  };
}];
```

### 3. Implement Pod Disruption Budgets

```nix
{
  pdb = {
    apiVersion = "policy/v1";
    kind = "PodDisruptionBudget";
    metadata = {
      name = "app-pdb";
    };
    spec = {
      minAvailable = 2;  # Keep at least 2 pods running
      selector = {
        matchLabels = { app = "myapp"; };
      };
    };
  };
}
```

### 4. Use Node Affinity for Performance

```nix
containers = [{
  image = "compute-heavy:latest";
}];

affinity = {
  nodeAffinity = {
    preferredDuringSchedulingIgnoredDuringExecution = [{
      weight = 100;
      preference = {
        matchExpressions = [{
          key = "node.kubernetes.io/instance-type";
          operator = "In";
          values = ["c5.xlarge" "c5.2xlarge"];  # Compute-optimized
        }];
      };
    }];
  };
};
```

### 5. Monitor and Adjust

1. **Baseline**: Measure current performance
2. **Profile**: Identify bottlenecks  
3. **Optimize**: Make targeted improvements
4. **Validate**: Measure improvement
5. **Iterate**: Continue optimizing

### Performance Checklist

- ✓ Resource requests set correctly
- ✓ Resource limits prevent OOMkill
- ✓ Readiness/liveness probes configured
- ✓ Horizontal pod autoscaling enabled
- ✓ Database connections pooled
- ✓ Caching implemented
- ✓ Network policies optimized
- ✓ Monitoring and alerting in place
- ✓ Regular performance testing
- ✓ Scaling tested

