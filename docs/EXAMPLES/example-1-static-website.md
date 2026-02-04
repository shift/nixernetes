# Example 1: Static Website Hosting

Deploy a modern static website with caching, CDN integration, and SSL/TLS security.

## Overview

This example demonstrates:
- Nginx web server for static content
- CloudFront CDN integration (AWS)
- Automatic SSL/TLS with cert-manager
- Cache headers and compression
- Security headers
- Production monitoring

## Architecture

```
┌──────────────────┐
│   Users          │
└────────┬─────────┘
         │
┌────────▼──────────────┐
│  CloudFront CDN       │  (AWS)
│  (Edge Locations)     │
└────────┬──────────────┘
         │
┌────────▼──────────────┐
│  Load Balancer       │  (Ingress)
│  (HTTPS/TLS)         │
└────────┬──────────────┘
         │
┌────────▼──────────────┐
│  Nginx                │
│  (Static Content)     │  (2 replicas)
└───────────────────────┘
```

## Configuration

Create `static-website.nix`:

```nix
{ nixernetes, pkgs }:

let
  modules = nixernetes.modules;
in {
  # ConfigMap with Nginx configuration
  nginxConfig = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "nginx-config";
      namespace = "default";
    };
    data = {
      "nginx.conf" = ''
        user nginx;
        worker_processes auto;
        error_log /var/log/nginx/error.log warn;
        pid /var/run/nginx.pid;

        events {
          worker_connections 1024;
        }

        http {
          include /etc/nginx/mime.types;
          default_type application/octet-stream;

          log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';

          access_log /var/log/nginx/access.log main;

          sendfile on;
          tcp_nopush on;
          tcp_nodelay on;
          keepalive_timeout 65;
          types_hash_max_size 2048;
          client_max_body_size 20M;

          # Gzip compression
          gzip on;
          gzip_vary on;
          gzip_proxied any;
          gzip_comp_level 6;
          gzip_types text/plain text/css text/xml text/javascript 
                     application/json application/javascript application/xml+rss 
                     application/rss+xml font/truetype font/opentype 
                     application/vnd.ms-fontobject image/svg+xml;

          server {
            listen 8080 default_server;
            server_name _;

            # Security headers
            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
            add_header X-Content-Type-Options "nosniff" always;
            add_header X-Frame-Options "SAMEORIGIN" always;
            add_header X-XSS-Protection "1; mode=block" always;
            add_header Referrer-Policy "no-referrer-when-downgrade" always;
            add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;

            # Cache control
            location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
              expires 1y;
              add_header Cache-Control "public, immutable";
            }

            # HTML files - no cache
            location ~* \.html?$ {
              expires -1;
              add_header Cache-Control "no-cache, no-store, must-revalidate";
            }

            # Root content
            location / {
              root /usr/share/nginx/html;
              try_files $uri $uri/ /index.html;
              add_header Cache-Control "public, max-age=3600";
            }

            # Health check endpoint
            location /health {
              access_log off;
              return 200 "healthy\n";
              add_header Content-Type text/plain;
            }

            # Status page (restricted)
            location /nginx-status {
              stub_status on;
              access_log off;
              allow 127.0.0.1;
              allow 10.0.0.0/8;
              deny all;
            }

            # Disable access to hidden files
            location ~ /\. {
              deny all;
              access_log off;
              log_not_found off;
            }
          }
        }
      '';
    };
  };

  # Deployment with 2 replicas
  deployment = modules.deployments.mkSimpleDeployment {
    name = "static-website";
    image = "nginx:1.25-alpine";
    replicas = 2;

    ports = [{
      containerPort = 8080;
      name = "http";
    }];

    # Mount ConfigMap
    volumeMounts = [{
      name = "nginx-config";
      mountPath = "/etc/nginx/nginx.conf";
      subPath = "nginx.conf";
    }];

    # Mount content volume
    volumes = [
      {
        name = "nginx-config";
        configMap.name = "nginx-config";
      }
      {
        name = "html-content";
        emptyDir = {};
      }
    ];

    # Copy website content (example - use init container in production)
    initContainers = [{
      name = "copy-content";
      image = "busybox:1.35";
      command = [ "sh" "-c" ];
      args = [
        "echo '<h1>Welcome to My Website</h1><p>Deployed with Nixernetes</p>' > /usr/share/nginx/html/index.html"
      ];
      volumeMounts = [{
        name = "html-content";
        mountPath = "/usr/share/nginx/html";
      }];
    }];

    resources = {
      requests = {
        memory = "32Mi";
        cpu = "50m";
      };
      limits = {
        memory = "128Mi";
        cpu = "200m";
      };
    };

    # Liveness probe
    livenessProbe = {
      httpGet = {
        path = "/health";
        port = 8080;
      };
      initialDelaySeconds = 5;
      periodSeconds = 10;
    };

    # Readiness probe
    readinessProbe = {
      httpGet = {
        path = "/health";
        port = 8080;
      };
      initialDelaySeconds = 3;
      periodSeconds = 5;
    };
  };

  # Service
  service = modules.services.mkSimpleService {
    name = "static-website";
    selector = { app = "static-website"; };
    ports = [{
      port = 80;
      targetPort = 8080;
      protocol = "TCP";
    }];
    type = "ClusterIP";
  };

  # Ingress with TLS
  ingress = {
    apiVersion = "networking.k8s.io/v1";
    kind = "Ingress";
    metadata = {
      name = "static-website";
      namespace = "default";
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod";
        "nginx.ingress.kubernetes.io/ssl-redirect" = "true";
        "nginx.ingress.kubernetes.io/force-ssl-redirect" = "true";
      };
    };
    spec = {
      tls = [{
        hosts = [ "mysite.example.com" "www.mysite.example.com" ];
        secretName = "static-website-tls";
      }];
      rules = [
        {
          host = "mysite.example.com";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = {
              name = "static-website";
              port.number = 80;
            };
          }];
        }
        {
          host = "www.mysite.example.com";
          http.paths = [{
            path = "/";
            pathType = "Prefix";
            backend.service = {
              name = "static-website";
              port.number = 80;
            };
          }];
        }
      ];
    };
  };

  # Network Policy - allow ingress only
  networkPolicy = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata = {
      name = "static-website";
      namespace = "default";
    };
    spec = {
      podSelector.matchLabels.app = "static-website";
      policyTypes = [ "Ingress" ];
      ingress = [{
        from = [{
          podSelector.matchLabels.app = "nginx-ingress";
        }];
        ports = [{
          protocol = "TCP";
          port = 8080;
        }];
      }];
    };
  };

  # Pod Disruption Budget for availability
  podDisruptionBudget = {
    apiVersion = "policy/v1";
    kind = "PodDisruptionBudget";
    metadata = {
      name = "static-website";
      namespace = "default";
    };
    spec = {
      minAvailable = 1;
      selector.matchLabels.app = "static-website";
    };
  };

  # Service Monitor for Prometheus
  serviceMonitor = {
    apiVersion = "monitoring.coreos.com/v1";
    kind = "ServiceMonitor";
    metadata = {
      name = "static-website";
      namespace = "default";
    };
    spec = {
      selector.matchLabels.app = "static-website";
      endpoints = [{
        port = "metrics";
        interval = "30s";
        path = "/nginx-status";
      }];
    };
  };

  # Horizontal Pod Autoscaler
  autoscaler = {
    apiVersion = "autoscaling/v2";
    kind = "HorizontalPodAutoscaler";
    metadata = {
      name = "static-website";
      namespace = "default";
    };
    spec = {
      scaleTargetRef = {
        apiVersion = "apps/v1";
        kind = "Deployment";
        name = "static-website";
      };
      minReplicas = 2;
      maxReplicas = 10;
      metrics = [{
        type = "Resource";
        resource = {
          name = "cpu";
          target = {
            type = "Utilization";
            averageUtilization = 70;
          };
        };
      }];
    };
  };
}
```

## Deployment Steps

### Step 1: Prepare Your Content

Create your website content (HTML, CSS, JavaScript):

```bash
mkdir -p website-content
cat > website-content/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
  <title>My Website</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; }
    h1 { color: #333; }
  </style>
</head>
<body>
  <h1>Welcome to My Website</h1>
  <p>Deployed with Nixernetes on Kubernetes</p>
</body>
</html>
EOF
```

### Step 2: Create ConfigMap with Content

```bash
kubectl create configmap website-content --from-file=website-content/
```

### Step 3: Validate Configuration

```bash
./bin/nixernetes validate static-website.nix
```

### Step 4: Generate Manifests

```bash
./bin/nixernetes generate static-website.nix > manifests.yaml
cat manifests.yaml
```

### Step 5: Deploy

```bash
# Dry run first
kubectl apply -f manifests.yaml --dry-run=client

# Deploy
kubectl apply -f manifests.yaml

# Wait for deployment
kubectl rollout status deployment/static-website
```

### Step 6: Verify

```bash
# Check pods
kubectl get pods -l app=static-website

# Check service
kubectl get svc static-website

# Check ingress
kubectl get ingress static-website

# Port forward for testing
kubectl port-forward svc/static-website 8080:80 &
curl http://localhost:8080
```

## Production Considerations

### 1. Content Management

**Option A: ConfigMap (small sites)**
```bash
kubectl create configmap website-content --from-file=./site/
```

**Option B: GitOps (recommended)**
```bash
# Use ArgoCD to sync from git repository
# Every commit triggers automatic deployment
```

**Option C: PersistentVolume**
```nix
persistentVolume = {
  size = "5Gi";
  storageClass = "standard";
};
```

### 2. CloudFront Integration (AWS)

```bash
# Create CloudFront distribution pointing to ALB
aws cloudfront create-distribution \
  --origin-domain-name mysite.example.com \
  --default-root-object index.html
```

### 3. Security Headers

Already included in the configuration:
- HSTS - Enforces HTTPS
- CSP - Content Security Policy
- X-Frame-Options - Click-jacking protection
- X-Content-Type-Options - MIME sniffing protection

### 4. Performance Optimization

The configuration includes:
- Gzip compression
- Browser caching with proper headers
- Nginx worker optimization
- Resource limits to prevent hogging

### 5. Monitoring

Add Prometheus scraping:

```bash
kubectl annotate service static-website \
  prometheus.io/scrape=true \
  prometheus.io/port=80 \
  prometheus.io/path=/nginx-status
```

### 6. SSL/TLS

Uses cert-manager for automatic certificates:

```bash
# Install cert-manager first
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.crds.yaml
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
kubectl apply -f - << 'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

## Troubleshooting

### Pods not running

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Ingress not working

```bash
kubectl describe ingress static-website
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller
```

### Slow performance

```bash
# Check response times
kubectl logs deployment/static-website | grep response_time

# Check resource usage
kubectl top pod -l app=static-website

# Check Nginx cache
kubectl exec <pod> -- nginx -T
```

### Certificate issues

```bash
kubectl get certificate
kubectl describe certificate static-website-tls
kubectl get certificaterequests
```

## Scaling

The configuration includes HPA that automatically scales based on CPU:

```bash
# Monitor scaling
kubectl get hpa -w

# Manual scaling
kubectl scale deployment static-website --replicas=5
```

## Next Steps

1. **Add monitoring** - Use Prometheus + Grafana
2. **Add caching** - Use Redis for dynamic content
3. **Add authentication** - Use OAuth2-Proxy
4. **Multi-region** - Deploy to multiple clouds
5. **Custom domain** - Configure your own domain

## Summary

This example demonstrates:
✅ Nginx web server configuration  
✅ Static content serving with caching  
✅ TLS/SSL with cert-manager  
✅ Security headers and policies  
✅ Horizontal scaling  
✅ Health monitoring  
✅ Network policies  
✅ Production readiness  

The configuration is ready for production deployment to AWS, GCP, or Azure!
