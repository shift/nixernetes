# Tutorial 3: Complete Microservices Stack

Build a production-grade microservices platform with frontend, API, database, caching, messaging, and monitoring.

## What You'll Learn

- Multi-tier microservices architecture
- Frontend deployment with Nginx
- API backend with Node.js
- PostgreSQL with backups
- Redis caching layer
- RabbitMQ message queue
- Prometheus monitoring
- Grafana dashboards
- Service-to-service communication
- Complex network policies
- Production deployment patterns

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    External Users                           │
└────────────────────────────┬────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │  Load Balancer  │
                    │   (Ingress)     │
                    └────────┬────────┘
          ┌─────────────────┬───────────────────┐
          │                 │                   │
    ┌─────▼─────┐   ┌─────▼─────┐  ┌──────────▼──────┐
    │  Frontend  │   │    API    │  │    Admin        │
    │  (Nginx)   │   │  (Node)   │  │    Dashboard    │
    └────┬───────┘   └────┬──────┘  └─────────────────┘
         │                │
         │                ▼
         │          ┌──────────────┐
         │          │  Redis Cache │
         │          └──────────────┘
         │
         └──────────┬─────────────────────┐
                    │                     │
            ┌───────▼────────┐  ┌─────────▼────────┐
            │  PostgreSQL    │  │   RabbitMQ       │
            │  (Database)    │  │   (Message Queue)│
            └────────────────┘  └──────────────────┘
                                       │
                                  ┌────▼────┐
                                  │ Workers  │
                                  │ (Jobs)   │
                                  └──────────┘

┌──────────────────────────────────────────────────────────────┐
│                    Observability Stack                       │
├──────────────────────────────────────────────────────────────┤
│  Prometheus │ AlertManager │ Grafana │ Loki │ Jaeger         │
└──────────────────────────────────────────────────────────────┘
```

## Prerequisites

- Completed Tutorials 1 and 2
- Kubernetes 1.28+
- 8GB RAM and 4 CPU cores for cluster
- Storage provisioner (local-path, EBS, GCE PD, etc.)

## Step 1: Project Structure

```bash
mkdir -p microservices-platform/{nix-config,apps/{frontend,api,worker}}
cd microservices-platform

# Create organized config structure
mkdir -p nix-config/{core,services,observability}
```

## Step 2: Core Services Configuration

Create `nix-config/core/postgres.nix`:

```nix
{ nixernetes }:

let
  modules = nixernetes.modules;
in {
  postgres = {
    name = "postgres";
    namespace = "default";
    
    statefulSet = modules.databases.mkPostgreSQL {
      name = "postgres";
      image = "postgres:16-alpine";
      version = "16";
      
      storage = {
        size = "20Gi";
        storageClassName = "standard";
      };
      
      env = [
        {
          name = "POSTGRES_DB";
          value = "platform_db";
        }
        {
          name = "POSTGRES_USER";
          value = "platform_user";
        }
        {
          name = "POSTGRES_PASSWORD";
          valueFrom.secretKeyRef = {
            name = "postgres-secret";
            key = "password";
          };
        }
        {
          name = "POSTGRES_INITDB_ARGS";
          value = "-c shared_buffers=256MB -c max_connections=100";
        }
      ];
      
      resources = {
        requests = {
          memory = "512Mi";
          cpu = "500m";
        };
        limits = {
          memory = "1Gi";
          cpu = "1000m";
        };
      };
      
      livenessProbe = {
        exec.command = [ "pg_isready" "-U" "platform_user" ];
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };
      
      readinessProbe = {
        exec.command = [ "pg_isready" "-U" "platform_user" ];
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };
    };
    
    service = modules.services.mkSimpleService {
      name = "postgres";
      selector = { app = "postgres"; };
      ports = [{
        port = 5432;
        targetPort = 5432;
      }];
      clusterIP = "None";
    };
    
    backup = {
      apiVersion = "v1";
      kind = "CronJob";
      metadata = {
        name = "postgres-backup";
        namespace = "default";
      };
      spec = {
        schedule = "0 2 * * *"; # Daily at 2 AM
        jobTemplate.spec.template.spec = {
          serviceAccountName = "postgres-backup";
          containers = [{
            name = "backup";
            image = "postgres:16-alpine";
            command = [
              "/bin/sh" "-c"
              "pg_dump -U platform_user -d platform_db | gzip > /backups/postgres-$(date +%Y%m%d-%H%M%S).sql.gz"
            ];
            env = [
              {
                name = "PGHOST";
                value = "postgres.default.svc.cluster.local";
              }
              {
                name = "PGPASSWORD";
                valueFrom.secretKeyRef = {
                  name = "postgres-secret";
                  key = "password";
                };
              }
            ];
            volumeMounts = [{
              name = "backup-storage";
              mountPath = "/backups";
            }];
          }];
          volumes = [{
            name = "backup-storage";
            persistentVolumeClaim.claimName = "postgres-backups";
          }];
          restartPolicy = "OnFailure";
        };
      };
    };
  };
  
  postgresSecret = {
    apiVersion = "v1";
    kind = "Secret";
    metadata = {
      name = "postgres-secret";
      namespace = "default";
    };
    type = "Opaque";
    stringData = {
      password = "SecurePassword123!";
      username = "platform_user";
    };
  };
  
  backupPVC = {
    apiVersion = "v1";
    kind = "PersistentVolumeClaim";
    metadata = {
      name = "postgres-backups";
      namespace = "default";
    };
    spec = {
      accessModes = [ "ReadWriteOnce" ];
      storageClassName = "standard";
      resources.requests.storage = "10Gi";
    };
  };
}
```

Create `nix-config/core/redis.nix`:

```nix
{ nixernetes }:

let
  modules = nixernetes.modules;
in {
  redis = {
    name = "redis";
    namespace = "default";
    
    deployment = modules.caching.mkRedis {
      name = "redis";
      image = "redis:7-alpine";
      replicas = 1;
      
      resources = {
        requests = {
          memory = "256Mi";
          cpu = "100m";
        };
        limits = {
          memory = "512Mi";
          cpu = "500m";
        };
      };
      
      livenessProbe = {
        exec.command = [ "redis-cli" "ping" ];
        initialDelaySeconds = 5;
        periodSeconds = 10;
      };
      
      readinessProbe = {
        exec.command = [ "redis-cli" "ping" ];
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };
    };
    
    service = modules.services.mkSimpleService {
      name = "redis";
      selector = { app = "redis"; };
      ports = [{
        port = 6379;
        targetPort = 6379;
      }];
    };
  };
}
```

Create `nix-config/core/rabbitmq.nix`:

```nix
{ nixernetes }:

let
  modules = nixernetes.modules;
in {
  rabbitmq = {
    name = "rabbitmq";
    namespace = "default";
    
    deployment = modules.messageQueues.mkRabbitMQ {
      name = "rabbitmq";
      image = "rabbitmq:3.12-management-alpine";
      replicas = 1;
      
      resources = {
        requests = {
          memory = "512Mi";
          cpu = "250m";
        };
        limits = {
          memory = "1Gi";
          cpu = "500m";
        };
      };
      
      ports = [
        { containerPort = 5672; name = "amqp"; }
        { containerPort = 15672; name = "management"; }
      ];
      
      env = [
        {
          name = "RABBITMQ_DEFAULT_USER";
          value = "admin";
        }
        {
          name = "RABBITMQ_DEFAULT_PASS";
          valueFrom.secretKeyRef = {
            name = "rabbitmq-secret";
            key = "password";
          };
        }
      ];
      
      livenessProbe = {
        exec.command = [ "rabbitmq-diagnostics" "ping" ];
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };
    };
    
    service = modules.services.mkSimpleService {
      name = "rabbitmq";
      selector = { app = "rabbitmq"; };
      ports = [
        { port = 5672; targetPort = 5672; name = "amqp"; }
        { port = 15672; targetPort = 15672; name = "management"; }
      ];
    };
    
    rabbitmqSecret = {
      apiVersion = "v1";
      kind = "Secret";
      metadata = {
        name = "rabbitmq-secret";
        namespace = "default";
      };
      type = "Opaque";
      stringData = {
        password = "RabbitPassword123!";
      };
    };
  };
}
```

## Step 3: Service Deployments

Create `nix-config/services/frontend.nix`:

```nix
{ nixernetes }:

let
  modules = nixernetes.modules;
in {
  frontend = {
    name = "frontend";
    namespace = "default";
    
    deployment = modules.deployments.mkSimpleDeployment {
      name = "frontend";
      image = "nginx:1.25-alpine";
      replicas = 3;
      
      configMap = {
        apiVersion = "v1";
        kind = "ConfigMap";
        metadata = {
          name = "nginx-config";
        };
        data = {
          "nginx.conf" = ''
            user nginx;
            worker_processes auto;
            events { worker_connections 1024; }
            http {
              upstream api {
                server api.default.svc.cluster.local:80;
              }
              server {
                listen 80;
                server_name _;
                
                location / {
                  root /usr/share/nginx/html;
                  try_files $uri /index.html;
                }
                
                location /api/ {
                  proxy_pass http://api/;
                  proxy_set_header Host $host;
                  proxy_set_header X-Real-IP $remote_addr;
                }
              }
            }
          '';
        };
      };
      
      ports = [{
        containerPort = 80;
        name = "http";
      }];
      
      volumeMounts = [{
        name = "nginx-config";
        mountPath = "/etc/nginx/nginx.conf";
        subPath = "nginx.conf";
      }];
      
      resources = {
        requests = {
          memory = "64Mi";
          cpu = "50m";
        };
        limits = {
          memory = "128Mi";
          cpu = "200m";
        };
      };
      
      livenessProbe = {
        httpGet = {
          path = "/";
          port = 80;
        };
        initialDelaySeconds = 10;
        periodSeconds = 10;
      };
    };
    
    service = modules.services.mkSimpleService {
      name = "frontend";
      selector = { app = "frontend"; };
      ports = [{
        port = 80;
        targetPort = 80;
      }];
    };
    
    ingress = modules.ingress.mkSimpleIngress {
      name = "platform";
      hosts = [{
        host = "platform.example.com";
        paths = [{
          path = "/";
          pathType = "Prefix";
          backend = {
            service = {
              name = "frontend";
              port = { number = 80; };
            };
          };
        }];
      }];
    };
  };
}
```

Create `nix-config/services/api.nix`:

```nix
{ nixernetes }:

let
  modules = nixernetes.modules;
in {
  api = {
    name = "api";
    namespace = "default";
    
    deployment = modules.deployments.mkSimpleDeployment {
      name = "api";
      image = "node:20-alpine";
      replicas = 3;
      
      ports = [{
        containerPort = 3000;
        name = "http";
      }];
      
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
          value = "platform_db";
        }
        {
          name = "REDIS_HOST";
          value = "redis.default.svc.cluster.local";
        }
        {
          name = "REDIS_PORT";
          value = "6379";
        }
        {
          name = "RABBITMQ_HOST";
          value = "rabbitmq.default.svc.cluster.local";
        }
        {
          name = "DATABASE_PASSWORD";
          valueFrom.secretKeyRef = {
            name = "postgres-secret";
            key = "password";
          };
        }
      ];
      
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
      
      livenessProbe = {
        httpGet = {
          path = "/health";
          port = 3000;
        };
        initialDelaySeconds = 15;
        periodSeconds = 10;
      };
      
      readinessProbe = {
        httpGet = {
          path = "/ready";
          port = 3000;
        };
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };
    };
    
    service = modules.services.mkSimpleService {
      name = "api";
      selector = { app = "api"; };
      ports = [{
        port = 80;
        targetPort = 3000;
      }];
    };
  };
}
```

## Step 4: Observability Stack

Create `nix-config/observability/prometheus.nix`:

```nix
{ nixernetes }:

let
  modules = nixernetes.modules;
in {
  prometheus = {
    name = "prometheus";
    namespace = "default";
    
    configMap = {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "prometheus-config";
      };
      data = {
        "prometheus.yml" = ''
          global:
            scrape_interval: 15s
            evaluation_interval: 15s
          scrape_configs:
          - job_name: 'kubernetes-pods'
            kubernetes_sd_configs:
            - role: pod
            relabel_configs:
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
              action: keep
              regex: true
            - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
              action: replace
              target_label: __metrics_path__
              regex: (.+)
            - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
              action: replace
              regex: ([^:]+)(?::\d+)?;(\d+)
              replacement: $1:$2
              target_label: __address__
        '';
      };
    };
    
    statefulSet = {
      apiVersion = "apps/v1";
      kind = "StatefulSet";
      metadata = {
        name = "prometheus";
      };
      spec = {
        serviceName = "prometheus";
        replicas = 1;
        selector.matchLabels.app = "prometheus";
        template = {
          metadata.labels.app = "prometheus";
          spec = {
            serviceAccountName = "prometheus";
            containers = [{
              name = "prometheus";
              image = "prom/prometheus:latest";
              ports = [{ containerPort = 9090; }];
              args = [
                "--config.file=/etc/prometheus/prometheus.yml"
                "--storage.tsdb.path=/prometheus"
                "--storage.tsdb.retention.time=30d"
              ];
              volumeMounts = [
                {
                  name = "prometheus-config";
                  mountPath = "/etc/prometheus";
                }
                {
                  name = "prometheus-storage";
                  mountPath = "/prometheus";
                }
              ];
            }];
            volumes = [{
              name = "prometheus-config";
              configMap.name = "prometheus-config";
            }];
          };
        };
        volumeClaimTemplates = [{
          metadata.name = "prometheus-storage";
          spec = {
            accessModes = [ "ReadWriteOnce" ];
            storageClassName = "standard";
            resources.requests.storage = "50Gi";
          };
        }];
      };
    };
    
    service = {
      apiVersion = "v1";
      kind = "Service";
      metadata.name = "prometheus";
      spec = {
        clusterIP = "None";
        selector.app = "prometheus";
        ports = [{ port = 9090; targetPort = 9090; }];
      };
    };
  };
}
```

Create `nix-config/observability/grafana.nix`:

```nix
{ nixernetes }:

let
  modules = nixernetes.modules;
in {
  grafana = {
    name = "grafana";
    namespace = "default";
    
    deployment = {
      apiVersion = "apps/v1";
      kind = "Deployment";
      metadata = {
        name = "grafana";
      };
      spec = {
        replicas = 1;
        selector.matchLabels.app = "grafana";
        template = {
          metadata.labels.app = "grafana";
          spec = {
            containers = [{
              name = "grafana";
              image = "grafana/grafana:10";
              ports = [{ containerPort = 3000; }];
              env = [
                {
                  name = "GF_SECURITY_ADMIN_PASSWORD";
                  valueFrom.secretKeyRef = {
                    name = "grafana-secret";
                    key = "admin-password";
                  };
                }
              ];
              volumeMounts = [{
                name = "grafana-storage";
                mountPath = "/var/lib/grafana";
              }];
            }];
            volumes = [{
              name = "grafana-storage";
              emptyDir = {};
            }];
          };
        };
      };
    };
    
    service = {
      apiVersion = "v1";
      kind = "Service";
      metadata.name = "grafana";
      spec = {
        selector.app = "grafana";
        ports = [{ port = 3000; targetPort = 3000; }];
      };
    };
    
    ingress = {
      apiVersion = "networking.k8s.io/v1";
      kind = "Ingress";
      metadata.name = "grafana";
      spec = {
        rules = [{
          host = "grafana.example.com";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend = {
              service = {
                name = "grafana";
                port.number = 3000;
              };
            };
          }];
        }];
      };
    };
    
    grafanaSecret = {
      apiVersion = "v1";
      kind = "Secret";
      metadata.name = "grafana-secret";
      type = "Opaque";
      stringData.passwordLockfile = "admin-password=GrafanaPassword123!";
    };
  };
}
```

## Step 5: Network Policies

Create `nix-config/network-policies.nix`:

```nix
{ nixernetes }:

{
  # Frontend to API
  frontendToApi = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata = {
      name = "frontend-to-api";
    };
    spec = {
      podSelector.matchLabels.app = "api";
      policyTypes = [ "Ingress" ];
      ingress = [{
        from = [{
          podSelector.matchLabels.app = "frontend";
        }];
        ports = [{ protocol = "TCP"; port = 3000; }];
      }];
    };
  };
  
  # API to PostgreSQL
  apiToPostgres = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata.name = "api-to-postgres";
    spec = {
      podSelector.matchLabels.app = "postgres";
      policyTypes = [ "Ingress" ];
      ingress = [{
        from = [{
          podSelector.matchLabels.app = "api";
        }];
        ports = [{ protocol = "TCP"; port = 5432; }];
      }];
    };
  };
  
  # API to Redis
  apiToRedis = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata.name = "api-to-redis";
    spec = {
      podSelector.matchLabels.app = "redis";
      policyTypes = [ "Ingress" ];
      ingress = [{
        from = [{
          podSelector.matchLabels.app = "api";
        }];
        ports = [{ protocol = "TCP"; port = 6379; }];
      }];
    };
  };
  
  # API to RabbitMQ
  apiToRabbitmq = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata.name = "api-to-rabbitmq";
    spec = {
      podSelector.matchLabels.app = "rabbitmq";
      policyTypes = [ "Ingress" ];
      ingress = [{
        from = [{
          podSelector.matchLabels.app = "api";
        }];
        ports = [{ protocol = "TCP"; port = 5672; }];
      }];
    };
  };
  
  # Prometheus scraping
  prometheusToAll = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata.name = "prometheus-scrape";
    spec = {
      podSelector = {};
      policyTypes = [ "Ingress" ];
      ingress = [{
        from = [{
          podSelector.matchLabels.app = "prometheus";
        }];
      }];
    };
  };
}
```

## Step 6: RBAC Configuration

Create `nix-config/rbac.nix`:

```nix
{ nixernetes }:

{
  prometheusRBAC = {
    serviceAccount = {
      apiVersion = "v1";
      kind = "ServiceAccount";
      metadata = {
        name = "prometheus";
      };
    };
    
    clusterRole = {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "ClusterRole";
      metadata.name = "prometheus";
      rules = [
        {
          apiGroups = [ "" ];
          resources = [ "nodes", "nodes/proxy", "services", "endpoints", "pods" ];
          verbs = [ "get", "list", "watch" ];
        }
        {
          apiGroups = [ "extensions" ];
          resources = [ "ingresses" ];
          verbs = [ "get", "list", "watch" ];
        }
      ];
    };
    
    clusterRoleBinding = {
      apiVersion = "rbac.authorization.k8s.io/v1";
      kind = "ClusterRoleBinding";
      metadata.name = "prometheus";
      roleRef = {
        apiGroup = "rbac.authorization.k8s.io";
        kind = "ClusterRole";
        name = "prometheus";
      };
      subjects = [{
        kind = "ServiceAccount";
        name = "prometheus";
        namespace = "default";
      }];
    };
  };
}
```

## Step 7: Deployment Script

Create `deploy.sh`:

```bash
#!/bin/bash
set -e

echo "Deploying Microservices Platform..."

# Deploy core services (order matters)
echo "1. Deploying PostgreSQL..."
./bin/nixernetes deploy nix-config/core/postgres.nix
kubectl rollout status statefulset/postgres

echo "2. Deploying Redis..."
./bin/nixernetes deploy nix-config/core/redis.nix
kubectl rollout status deployment/redis

echo "3. Deploying RabbitMQ..."
./bin/nixernetes deploy nix-config/core/rabbitmq.nix
kubectl rollout status deployment/rabbitmq

# Deploy application services
echo "4. Deploying API..."
./bin/nixernetes deploy nix-config/services/api.nix
kubectl rollout status deployment/api

echo "5. Deploying Frontend..."
./bin/nixernetes deploy nix-config/services/frontend.nix
kubectl rollout status deployment/frontend

# Deploy observability
echo "6. Deploying Prometheus..."
./bin/nixernetes deploy nix-config/observability/prometheus.nix
kubectl rollout status statefulset/prometheus

echo "7. Deploying Grafana..."
./bin/nixernetes deploy nix-config/observability/grafana.nix
kubectl rollout status deployment/grafana

# Deploy network policies
echo "8. Deploying Network Policies..."
./bin/nixernetes deploy nix-config/network-policies.nix

# Deploy RBAC
echo "9. Deploying RBAC..."
./bin/nixernetes deploy nix-config/rbac.nix

echo ""
echo "✅ Microservices platform deployed successfully!"
echo ""
echo "Access points:"
echo "  Frontend:  http://platform.example.com"
echo "  Grafana:   http://grafana.example.com"
echo "  Prometheus: http://prometheus.default.svc.cluster.local:9090"
echo ""
echo "Test with:"
echo "  kubectl port-forward svc/frontend 8080:80"
```

## Step 8: Deploy the Platform

```bash
chmod +x deploy.sh
./deploy.sh

# Or deploy individually
kubectl apply -f <(./bin/nixernetes generate nix-config/core/postgres.nix)
kubectl apply -f <(./bin/nixernetes generate nix-config/core/redis.nix)
kubectl apply -f <(./bin/nixernetes generate nix-config/core/rabbitmq.nix)
kubectl apply -f <(./bin/nixernetes generate nix-config/services/api.nix)
kubectl apply -f <(./bin/nixernetes generate nix-config/services/frontend.nix)
kubectl apply -f <(./bin/nixernetes generate nix-config/observability/prometheus.nix)
kubectl apply -f <(./bin/nixernetes generate nix-config/observability/grafana.nix)
```

## Step 9: Verify Deployment

```bash
# Check all pods are running
kubectl get pods

# Check services
kubectl get svc

# Check ingress
kubectl get ingress

# Check network policies
kubectl get networkpolicies

# View logs
kubectl logs -f deployment/api
kubectl logs -f deployment/frontend

# Port forward to test
kubectl port-forward svc/frontend 8080:80 &
curl http://localhost:8080

# Access Prometheus
kubectl port-forward svc/prometheus 9090:9090 &
# Visit http://localhost:9090

# Access Grafana
kubectl port-forward svc/grafana 3000:3000 &
# Visit http://localhost:3000 (admin/GrafanaPassword123!)
```

## Step 10: Production Considerations

For production deployment, add:

1. **Certificate Management**
   ```nix
   cert-manager.io/cluster-issuer = "letsencrypt-prod";
   ```

2. **Resource Quotas**
   ```nix
   resourceQuota = {
     requests.cpu = "10";
     requests.memory = "20Gi";
     limits.cpu = "20";
   };
   ```

3. **Pod Disruption Budgets**
   ```nix
   podDisruptionBudget = {
     minAvailable = 2;
   };
   ```

4. **Backup and Restore**
   ```bash
   # Automated backups for all databases
   ```

5. **Multi-region Deployment**
   - Use cloud-specific deployment guides

## Summary

You've built a production-grade microservices platform with:

✅ PostgreSQL database with backups
✅ Redis caching layer
✅ RabbitMQ message queue
✅ Node.js API backend
✅ Nginx frontend
✅ Prometheus monitoring
✅ Grafana dashboards
✅ Comprehensive network policies
✅ RBAC with least privilege
✅ Service discovery and health checks
✅ Persistent storage
✅ Observability stack
✅ Fully documented and testable

## Next Steps

- Deploy to production cloud (AWS EKS, GCP GKE, Azure AKS)
- Set up CI/CD pipeline
- Implement secrets management (Vault, AWS Secrets Manager)
- Add automated scaling
- Set up disaster recovery
- Implement GitOps with ArgoCD

See the cloud deployment guides:
- [AWS EKS Guide](../DEPLOY_AWS_EKS.md)
- [GCP GKE Guide](../DEPLOY_GCP_GKE.md)
- [Azure AKS Guide](../DEPLOY_AZURE_AKS.md)

## Troubleshooting

See individual tutorials for service-specific troubleshooting. For multi-service issues:

```bash
# Check all pod logs
kubectl logs -l app --all-containers=true

# Check event
kubectl get events --sort-by='.lastTimestamp'

# Check resource usage
kubectl top pods
kubectl top nodes

# Debug network connectivity
kubectl run -it debug --image=busybox --rm -- /bin/sh
# Inside: ping postgres, redis, api, etc.
```
