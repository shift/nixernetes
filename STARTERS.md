# Nixernetes Starter Kits

Quick-start templates for common deployment patterns. Each starter kit includes a complete configuration, documentation, and examples.

## Available Starters

### Simple Web Application
**Directory:** `starters/simple-web/`

Basic setup for a single web application with database and cache.

**Includes:**
- Nginx web server
- PostgreSQL database
- Redis cache
- Health checks
- Auto-scaling configuration

**Best for:**
- Single-service applications
- Monolithic architectures
- Learning Nixernetes basics

**Get Started:**
```bash
cp -r starters/simple-web my-app
cd my-app
nix build && kubectl apply -f result/manifest.yaml
```

---

### Microservices Architecture
**Directory:** `starters/microservices/`

Complete microservices setup with multiple independent services.

**Includes:**
- Frontend service (React/Vue)
- API service (Node.js/Python)
- Background worker
- PostgreSQL database
- Redis cache
- RabbitMQ message broker
- Service discovery
- Service-to-service communication

**Best for:**
- Complex applications
- Independent service teams
- Asynchronous processing needs
- Event-driven architectures

**Get Started:**
```bash
cp -r starters/microservices my-app
cd my-app
nix build && kubectl apply -f result/manifest.yaml
```

---

### Static Site
**Directory:** `starters/static-site/`

Optimized for static content (docs, blogs, marketing sites).

**Includes:**
- Nginx static server
- Compression and caching
- HTTPS/TLS ready
- CDN-friendly headers
- Minimal resource usage

**Best for:**
- Blogs and content sites
- Documentation
- Marketing websites
- JAMstack applications

**Get Started:**
```bash
cp -r starters/static-site my-site
cd my-site
nix build && kubectl apply -f result/manifest.yaml
```

---

## Customization Guide

### Change Image References

Edit `config.nix` and update container images:

```nix
web = {
  image = "your-registry/your-app:latest";
  # ... rest of config
};
```

### Add Environment Variables

```nix
web = {
  env = {
    DATABASE_URL = "postgresql://...";
    API_KEY = "your-key";
    LOG_LEVEL = "debug";
  };
};
```

### Configure Persistence

Enable database persistence:

```nix
database = {
  persistence = {
    enabled = true;
    size = "50Gi";  # Adjust size
  };
};
```

### Setup Autoscaling

```nix
api = {
  autoscaling = {
    enabled = true;
    minReplicas = 2;
    maxReplicas = 10;
    targetCPUUtilizationPercentage = 70;
  };
};
```

### Enable Ingress

For public access with custom domain:

```nix
ingress = {
  enabled = true;
  className = "nginx";
  hosts = ["myapp.example.com"];
  tls = {
    enabled = true;
    issuer = "letsencrypt-prod";
  };
};
```

### Configure Resource Limits

```nix
web = {
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
```

## Common Modifications

### Add a Database Migration

```nix
api = {
  initContainers = [{
    name = "migrate";
    image = "your-app:latest";
    command = ["npm" "run" "migrate"];
    env = { DATABASE_URL = "postgresql://..."; };
  }];
};
```

### Add Health Checks

```nix
web = {
  healthCheck = {
    httpGet = {
      path = "/health";
      port = 8080;
    };
    initialDelaySeconds = 10;
    periodSeconds = 30;
  };
};
```

### Setup Network Policies

```nix
networkPolicy = {
  enabled = true;
  policyTypes = ["Ingress" "Egress"];
  # Define specific allow rules
};
```

### Add Secrets

```bash
# Create secret in Kubernetes
kubectl create secret generic app-secrets \
  --from-literal=DB_PASSWORD=secret123

# Reference in config.nix
api = {
  env = [
    {
      name = "DB_PASSWORD";
      valueFrom = {
        secretKeyRef = {
          name = "app-secrets";
          key = "DB_PASSWORD";
        };
      };
    }
  ];
};
```

## Deployment Steps

1. **Copy starter kit:**
   ```bash
   cp -r starters/<kit-name> my-app
   cd my-app
   ```

2. **Customize configuration:**
   ```bash
   # Edit config.nix with your settings
   nano config.nix
   ```

3. **Verify configuration:**
   ```bash
   nix flake check --offline
   ```

4. **Build manifests:**
   ```bash
   nix build
   ```

5. **Apply to Kubernetes:**
   ```bash
   kubectl apply -f result/manifest.yaml
   ```

6. **Verify deployment:**
   ```bash
   kubectl get pods
   kubectl get svc
   ```

## Testing Locally

### Port Forward

```bash
# Forward to web service
kubectl port-forward svc/web 8080:80

# Access at http://localhost:8080
```

### Check Logs

```bash
# View service logs
kubectl logs -f deployment/web

# Check specific pod
kubectl logs pod/<pod-name>
```

### Execute Commands

```bash
# Run command in pod
kubectl exec -it pod/<pod-name> -- bash

# Check database
kubectl exec -it pod/postgres-0 -- psql -U appuser -d appdb
```

## Learning Resources

- **Getting Started:** [GETTING_STARTED.md](../GETTING_STARTED.md)
- **Module Reference:** [MODULE_REFERENCE.md](../MODULE_REFERENCE.md)
- **Examples:** [docs/EXAMPLES/](../docs/EXAMPLES/)
- **Troubleshooting:** [Help Wanted Discussions](https://github.com/anomalyco/nixernetes/discussions/categories/help-wanted)

## Next Steps After Deployment

1. **Setup monitoring** - Add Prometheus, Grafana, or other monitoring tools
2. **Enable logging** - Configure centralized logging (ELK, Loki, etc.)
3. **Setup backups** - Automate database backups
4. **Configure CI/CD** - Automate deployments with GitHub Actions
5. **Scale up** - Adjust resource limits and replica counts for production
6. **Add security** - Setup network policies, RBAC, and pod security policies

## Get Help

- **Questions?** Ask in [Discussions](https://github.com/anomalyco/nixernetes/discussions)
- **Found a bug?** [Report it](https://github.com/anomalyco/nixernetes/issues/new?template=bug_report.yml)
- **Have an idea?** [Suggest it](https://github.com/anomalyco/nixernetes/issues/new?template=feature_request.yml)

---

**Happy deploying with Nixernetes!**
