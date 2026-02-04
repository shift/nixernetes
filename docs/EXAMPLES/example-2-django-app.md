# Example 2: Django + PostgreSQL Application

Deploy a scalable Django web application with PostgreSQL, Redis caching, and production monitoring.

## Overview

This example demonstrates:
- Django application deployment
- PostgreSQL database with persistence
- Redis caching layer
- Database migrations automation
- Static/media file handling
- Environment-specific configuration
- Production monitoring

## Architecture

```
┌─────────────────────────────────────────┐
│          External Users                 │
└──────────────────┬──────────────────────┘
                   │
         ┌─────────▼─────────┐
         │  Nginx Reverse    │
         │  Proxy (Ingress)  │
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────────────┐
         │  Django Application       │
         │  (Multiple Pods)          │
         │  gunicorn + Django        │
         └──────────┬────────┬───────┘
                    │        │
         ┌──────────▼─┐    ┌─▼──────────┐
         │ PostgreSQL │    │   Redis    │
         │ Database   │    │   Cache    │
         └────────────┘    └────────────┘
```

## Configuration

Create `django-app.nix`:

```nix
{ nixernetes, pkgs }:

let
  modules = nixernetes.modules;
in {
  # Namespace
  namespace = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata.name = "django-app";
  };

  # PostgreSQL Database
  postgres = {
    statefulSet = modules.databases.mkPostgreSQL {
      name = "postgres";
      image = "postgres:15-alpine";
      version = "15";
      
      namespace = "django-app";
      
      storage.size = "20Gi";
      storage.storageClassName = "standard";
      
      env = [
        {
          name = "POSTGRES_DB";
          value = "django_db";
        }
        {
          name = "POSTGRES_USER";
          value = "django_user";
        }
        {
          name = "POSTGRES_PASSWORD";
          valueFrom.secretKeyRef = {
            name = "postgres-secret";
            key = "password";
          };
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
    };

    service = modules.services.mkSimpleService {
      name = "postgres";
      namespace = "django-app";
      selector = { app = "postgres"; };
      ports = [{ port = 5432; targetPort = 5432; }];
      clusterIP = "None";
    };

    secret = {
      apiVersion = "v1";
      kind = "Secret";
      metadata = {
        name = "postgres-secret";
        namespace = "django-app";
      };
      type = "Opaque";
      stringData = {
        password = "SecureDjangoPassword123!";
        url = "postgresql://django_user:SecureDjangoPassword123!@postgres.django-app.svc.cluster.local:5432/django_db";
      };
    };
  };

  # Redis Cache
  redis = {
    deployment = modules.caching.mkRedis {
      name = "redis";
      image = "redis:7-alpine";
      namespace = "django-app";
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
    };

    service = modules.services.mkSimpleService {
      name = "redis";
      namespace = "django-app";
      selector = { app = "redis"; };
      ports = [{ port = 6379; targetPort = 6379; }];
    };
  };

  # ConfigMap with Django settings
  djangoConfig = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "django-config";
      namespace = "django-app";
    };
    data = {
      "DJANGO_SETTINGS_MODULE" = "config.settings.production";
      "DEBUG" = "False";
      "ALLOWED_HOSTS" = "myapp.example.com";
      "LOG_LEVEL" = "info";
    };
  };

  # Django Application Deployment
  djangoApp = {
    deployment = modules.deployments.mkSimpleDeployment {
      name = "django-app";
      image = "your-registry.com/django-app:latest";  # Replace with your image
      namespace = "django-app";
      replicas = 3;

      ports = [{
        containerPort = 8000;
        name = "http";
      }];

      # Environment variables
      env = [
        {
          name = "DJANGO_SETTINGS_MODULE";
          valueFrom.configMapKeyRef = {
            name = "django-config";
            key = "DJANGO_SETTINGS_MODULE";
          };
        }
        {
          name = "DATABASE_URL";
          valueFrom.secretKeyRef = {
            name = "postgres-secret";
            key = "url";
          };
        }
        {
          name = "REDIS_URL";
          value = "redis://redis.django-app.svc.cluster.local:6379/0";
        }
        {
          name = "SECRET_KEY";
          valueFrom.secretKeyRef = {
            name = "django-secret";
            key = "secret-key";
          };
        }
        {
          name = "DEBUG";
          valueFrom.configMapKeyRef = {
            name = "django-config";
            key = "DEBUG";
          };
        }
      ];

      # Init container for database migrations
      initContainers = [{
        name = "migrate";
        image = "your-registry.com/django-app:latest";
        command = [ "python" "manage.py" "migrate" "--noinput" ];
        env = [
          {
            name = "DATABASE_URL";
            valueFrom.secretKeyRef = {
              name = "postgres-secret";
              key = "url";
            };
          }
        ];
      }];

      # Run Django with gunicorn
      command = [
        "gunicorn"
        "config.wsgi:application"
        "--bind=0.0.0.0:8000"
        "--workers=4"
        "--worker-class=sync"
        "--timeout=60"
        "--access-logfile=-"
        "--error-logfile=-"
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

      # Startup probe - wait for Django to be ready
      startupProbe = {
        httpGet = {
          path = "/health/";
          port = 8000;
        };
        initialDelaySeconds = 5;
        periodSeconds = 10;
        failureThreshold = 30;
      };

      # Liveness probe
      livenessProbe = {
        httpGet = {
          path = "/health/";
          port = 8000;
        };
        initialDelaySeconds = 20;
        periodSeconds = 10;
      };

      # Readiness probe
      readinessProbe = {
        httpGet = {
          path = "/health/";
          port = 8000;
        };
        initialDelaySeconds = 10;
        periodSeconds = 5;
      };
    };

    service = modules.services.mkSimpleService {
      name = "django-app";
      namespace = "django-app";
      selector = { app = "django-app"; };
      ports = [{
        port = 80;
        targetPort = 8000;
        protocol = "TCP";
      }];
    };

    ingress = {
      apiVersion = "networking.k8s.io/v1";
      kind = "Ingress";
      metadata = {
        name = "django-app";
        namespace = "django-app";
        annotations = {
          "cert-manager.io/cluster-issuer" = "letsencrypt-prod";
          "nginx.ingress.kubernetes.io/ssl-redirect" = "true";
        };
      };
      spec = {
        tls = [{
          hosts = [ "myapp.example.com" ];
          secretName = "django-app-tls";
        }];
        rules = [{
          host = "myapp.example.com";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = {
              name = "django-app";
              port.number = 80;
            };
          }];
        }];
      };
    };
  };

  # Django Secret (update with your values)
  djangoSecret = {
    apiVersion = "v1";
    kind = "Secret";
    metadata = {
      name = "django-secret";
      namespace = "django-app";
    };
    type = "Opaque";
    stringData = {
      "secret-key" = "your-django-secret-key-here";  # Generate with: python -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())'
    };
  };

  # Network Policy
  networkPolicy = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata = {
      name = "django-app";
      namespace = "django-app";
    };
    spec = {
      podSelector = {};
      policyTypes = [ "Ingress" "Egress" ];
      
      # Ingress from Ingress controller
      ingress = [{
        from = [{
          podSelector.matchLabels.app = "nginx-ingress";
        }];
        ports = [{ protocol = "TCP"; port = 8000; }];
      }];
      
      # Egress to database and cache
      egress = [
        # To postgres
        {
          to = [{ podSelector.matchLabels.app = "postgres"; }];
          ports = [{ protocol = "TCP"; port = 5432; }];
        }
        # To redis
        {
          to = [{ podSelector.matchLabels.app = "redis"; }];
          ports = [{ protocol = "TCP"; port = 6379; }];
        }
        # DNS
        {
          to = [{
            namespaceSelector.matchLabels.name = "kube-system";
          }];
          ports = [
            { protocol = "UDP"; port = 53; }
          ];
        }
      ];
    };
  };

  # Horizontal Pod Autoscaler
  autoscaler = {
    apiVersion = "autoscaling/v2";
    kind = "HorizontalPodAutoscaler";
    metadata = {
      name = "django-app";
      namespace = "django-app";
    };
    spec = {
      scaleTargetRef = {
        apiVersion = "apps/v1";
        kind = "Deployment";
        name = "django-app";
      };
      minReplicas = 3;
      maxReplicas = 10;
      metrics = [
        {
          type = "Resource";
          resource = {
            name = "cpu";
            target = {
              type = "Utilization";
              averageUtilization = 70;
            };
          };
        }
        {
          type = "Resource";
          resource = {
            name = "memory";
            target = {
              type = "Utilization";
              averageUtilization = 80;
            };
          };
        }
      ];
    };
  };
}
```

## Deployment Steps

### Step 1: Build Docker Image

Create your Dockerfile:

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt gunicorn

# Copy application
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput || true

# Create health endpoint
RUN echo "from django.http import HttpResponse\ndef health_check(request):\n    return HttpResponse('OK')" > config/health.py

EXPOSE 8000

CMD ["gunicorn", "config.wsgi:application", "--bind=0.0.0.0:8000"]
```

Build and push:

```bash
docker build -t your-registry.com/django-app:latest .
docker push your-registry.com/django-app:latest
```

### Step 2: Validate Configuration

```bash
./bin/nixernetes validate django-app.nix
```

### Step 3: Deploy

```bash
# Create namespace
kubectl create namespace django-app

# Deploy
./bin/nixernetes generate django-app.nix | kubectl apply -f -

# Wait for database
kubectl rollout status statefulset/postgres -n django-app

# Wait for cache
kubectl rollout status deployment/redis -n django-app

# Wait for Django
kubectl rollout status deployment/django-app -n django-app
```

### Step 4: Verify

```bash
# Check all pods
kubectl get pods -n django-app

# Check logs
kubectl logs deployment/django-app -n django-app -f

# Test endpoints
kubectl port-forward svc/django-app 8080:80 -n django-app &
curl http://localhost:8080/health/
curl http://localhost:8080/admin/
```

## Production Considerations

### 1. Static and Media Files

Use S3 or GCS for static/media files:

```python
# settings/production.py
if AWS_STORAGE_BUCKET_NAME:
    STORAGES = {
        "default": {
            "BACKEND": "storages.backends.s3boto3.S3Boto3Storage",
        },
        "staticfiles": {
            "BACKEND": "storages.backends.s3boto3.S3StaticStorage",
        },
    }
```

### 2. Environment Variables

Use external secrets provider:

```bash
# Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace
```

### 3. Database Backups

Add backup CronJob:

```nix
backup = {
  apiVersion = "batch/v1";
  kind = "CronJob";
  metadata = {
    name = "django-backup";
    namespace = "django-app";
  };
  spec = {
    schedule = "0 2 * * *";
    jobTemplate.spec.template.spec = {
      containers = [{
        name = "backup";
        image = "postgres:15-alpine";
        command = [ "/bin/sh" "-c" ];
        args = [ "pg_dump -U django_user -d django_db | gzip > /backups/django-$(date +%Y%m%d).sql.gz" ];
        env = [{
          name = "PGHOST";
          value = "postgres.django-app.svc.cluster.local";
        }];
      }];
      restartPolicy = "OnFailure";
    };
  };
};
```

### 4. Celery for Background Tasks

Add Celery workers:

```nix
celeryWorker = modules.deployments.mkSimpleDeployment {
  name = "celery-worker";
  image = "your-registry.com/django-app:latest";
  replicas = 2;
  command = [ "celery" "-A" "config" "worker" "-l" "info" ];
};
```

## Troubleshooting

### Database connection errors

```bash
# Check pod logs
kubectl logs <pod> -n django-app

# Test database connectivity
kubectl run -it --rm debug --image=postgres:15 --restart=Never \
  -- psql -h postgres.django-app.svc.cluster.local -U django_user -d django_db
```

### Migrations failing

```bash
# Run migrations manually
kubectl exec deployment/django-app -n django-app \
  -- python manage.py migrate
```

### Static files not served

```bash
# Ensure S3/GCS is configured
# Check STATIC_URL and STATIC_ROOT settings
```

### Performance issues

```bash
# Check resource usage
kubectl top pod -n django-app

# Check slow queries
kubectl logs deployment/django-app -n django-app | grep slow
```

## Scaling

```bash
# Manual scaling
kubectl scale deployment django-app --replicas=5 -n django-app

# Auto scaling (configured in HPA)
kubectl get hpa -n django-app -w
```

## Summary

This example demonstrates:
✅ Django application deployment  
✅ PostgreSQL database with persistence  
✅ Redis caching layer  
✅ Database migrations automation  
✅ Environment configuration  
✅ Health checks and probes  
✅ Horizontal scaling  
✅ Network policies  
✅ Production monitoring  

Ready for production deployment!
