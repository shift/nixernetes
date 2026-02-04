# Example: Comprehensive Multi-Tier Application
#
# This example demonstrates a production-grade multi-tier application deployment
# using Nixernetes with:
# - Frontend (Nginx)
# - Backend API (Node.js)
# - PostgreSQL Database
# - Redis Cache
# - RabbitMQ Message Queue
# - Prometheus Monitoring
# - Grafana Dashboards
#
# All with automatic compliance enforcement, security policies, and observability

{ lib, ... }:

{
  framework = {
    kubernetesVersion = "1.30";
    namespace = "production";
    
    # Global compliance settings
    compliance = {
      framework = "SOC2";
      level = "strict";
      owner = "platform-eng";
      dataClassification = "confidential";
      auditRequired = true;
    };

    # Zero-trust networking
    network = {
      policyMode = "deny-all";
      defaultDenyIngress = true;
      defaultDenyEgress = true;
    };

    # All secrets from Vault
    secrets = {
      backend = "external-secret";
      vaultAddress = "https://vault.internal:8200";
      vaultAuth = "kubernetes";
    };

    # Observability enabled globally
    observability = {
      enabled = true;
      prometheus = true;
      tracing = true;
    };
  };

  # Layer 3: High-level application declarations
  applications = {
    
    # Frontend: Nginx serving React SPA
    frontend = {
      name = "frontend";
      image = "nginx:1.24-alpine";
      replicas = 3;
      ports = [ 80 443 ];
      
      compliance = {
        framework = "SOC2";
        level = "strict";
        owner = "frontend-team";
        dataClassification = "internal";
      };

      dependencies = [ "api-gateway" ];

      resources = {
        limits = {
          cpu = "250m";
          memory = "256Mi";
        };
        requests = {
          cpu = "50m";
          memory = "64Mi";
        };
      };

      # ConfigMap for nginx configuration
      configMap = {
        "nginx.conf" = ''
          server {
            listen 80;
            root /usr/share/nginx/html;
            index index.html;
            
            location / {
              try_files $uri $uri/ /index.html;
            }
            
            location /api/ {
              proxy_pass http://api-gateway:8080;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
            }
          }
        '';
      };

      # Health checks
      livenessProbe = {
        httpGet.path = "/";
        httpGet.port = 80;
        initialDelaySeconds = 10;
        periodSeconds = 10;
      };

      readinessProbe = {
        httpGet.path = "/";
        httpGet.port = 80;
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };
    };

    # Backend API: Node.js application
    api-gateway = {
      name = "api-gateway";
      image = "node:18-alpine";
      replicas = 2;
      ports = [ 8080 ];
      
      compliance = {
        framework = "SOC2";
        level = "strict";
        owner = "backend-team";
        dataClassification = "confidential";
      };

      dependencies = [ "postgres" "redis" "rabbitmq" ];

      resources = {
        limits = {
          cpu = "1000m";
          memory = "1Gi";
        };
        requests = {
          cpu = "500m";
          memory = "512Mi";
        };
      };

      # Environment variables
      env = {
        NODE_ENV = "production";
        DATABASE_HOST = "postgres";
        DATABASE_PORT = "5432";
        REDIS_URL = "redis://redis:6379";
        RABBITMQ_URL = "amqp://guest:guest@rabbitmq:5672";
      };

      # Secrets from Vault
      secrets = {
        db_password = {
          backend = "external-secret";
          secretStore = "vault";
          secretKey = "postgres-password";
          vaultPath = "secret/data/app/postgres";
        };
        api_key = {
          backend = "external-secret";
          secretStore = "vault";
          secretKey = "api-key";
          vaultPath = "secret/data/app/api";
        };
        jwt_secret = {
          backend = "external-secret";
          secretStore = "vault";
          secretKey = "jwt-secret";
          vaultPath = "secret/data/app/security";
        };
      };

      # Health checks
      livenessProbe = {
        httpGet.path = "/health";
        httpGet.port = 8080;
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };

      readinessProbe = {
        httpGet.path = "/health/ready";
        httpGet.port = 8080;
        initialDelaySeconds = 10;
        periodSeconds = 5;
      };

      # Monitoring
      monitoring = {
        prometheus = true;
        metricsPort = 9090;
        metricsPath = "/metrics";
      };
    };

    # PostgreSQL Database
    postgres = {
      name = "postgres";
      image = "postgres:15-alpine";
      replicas = 1;
      ports = [ 5432 ];
      
      compliance = {
        framework = "SOC2";
        level = "strict";
        owner = "data-team";
        dataClassification = "confidential";
        auditRequired = true;
      };

      dependencies = [];

      resources = {
        limits = {
          cpu = "2000m";
          memory = "4Gi";
        };
        requests = {
          cpu = "1000m";
          memory = "2Gi";
        };
      };

      # Environment
      env = {
        POSTGRES_DB = "appdb";
        PGDATA = "/var/lib/postgresql/data/pgdata";
      };

      # Secrets
      secrets = {
        postgres_password = {
          backend = "external-secret";
          secretStore = "vault";
          secretKey = "postgres-password";
          vaultPath = "secret/data/database/postgres";
        };
      };

      # Persistent storage
      storage = {
        enabled = true;
        size = "50Gi";
        storageClass = "fast-ssd";
        mountPath = "/var/lib/postgresql/data";
      };

      # Health checks
      livenessProbe = {
        exec.command = [ "pg_isready" "-U" "postgres" ];
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };

      readinessProbe = {
        exec.command = [ "pg_isready" "-U" "postgres" ];
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };

      # Monitoring
      monitoring = {
        postgres_exporter = true;
        metricsPort = 9187;
      };
    };

    # Redis Cache
    redis = {
      name = "redis";
      image = "redis:7-alpine";
      replicas = 1;
      ports = [ 6379 ];
      
      compliance = {
        framework = "SOC2";
        level = "strict";
        owner = "platform-team";
        dataClassification = "internal";
      };

      dependencies = [];

      resources = {
        limits = {
          cpu = "500m";
          memory = "1Gi";
        };
        requests = {
          cpu = "250m";
          memory = "512Mi";
        };
      };

      # Redis configuration
      configMap = {
        "redis.conf" = ''
          maxmemory 1gb
          maxmemory-policy allkeys-lru
          save 900 1
          save 300 10
          save 60 10000
          appendonly yes
        '';
      };

      # Health checks
      livenessProbe = {
        exec.command = [ "redis-cli" "ping" ];
        initialDelaySeconds = 10;
        periodSeconds = 10;
      };

      readinessProbe = {
        exec.command = [ "redis-cli" "ping" ];
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };

      # Monitoring
      monitoring = {
        redis_exporter = true;
        metricsPort = 9121;
      };
    };

    # RabbitMQ Message Queue
    rabbitmq = {
      name = "rabbitmq";
      image = "rabbitmq:3.12-management-alpine";
      replicas = 1;
      ports = [ 5672 15672 ];
      
      compliance = {
        framework = "SOC2";
        level = "strict";
        owner = "platform-team";
        dataClassification = "internal";
      };

      dependencies = [];

      resources = {
        limits = {
          cpu = "1000m";
          memory = "2Gi";
        };
        requests = {
          cpu = "500m";
          memory = "1Gi";
        };
      };

      # Environment
      env = {
        RABBITMQ_DEFAULT_USER = "guest";
        RABBITMQ_DEFAULT_VHOST = "/";
      };

      # Secrets
      secrets = {
        rabbitmq_password = {
          backend = "external-secret";
          secretStore = "vault";
          secretKey = "rabbitmq-password";
          vaultPath = "secret/data/messaging/rabbitmq";
        };
      };

      # Persistent storage
      storage = {
        enabled = true;
        size = "20Gi";
        storageClass = "standard";
        mountPath = "/var/lib/rabbitmq";
      };

      # Health checks
      livenessProbe = {
        exec.command = [ "rabbitmq-diagnostics" "-q" "ping" ];
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };

      readinessProbe = {
        exec.command = [ "rabbitmq-diagnostics" "-q" "ping" ];
        initialDelaySeconds = 10;
        periodSeconds = 5;
      };

      # Monitoring
      monitoring = {
        rabbitmq_exporter = true;
        metricsPort = 15692;
      };
    };

    # Prometheus Monitoring
    prometheus = {
      name = "prometheus";
      image = "prom/prometheus:v2.45.0";
      replicas = 1;
      ports = [ 9090 ];
      
      compliance = {
        framework = "SOC2";
        level = "standard";
        owner = "platform-team";
        dataClassification = "internal";
      };

      dependencies = [];

      resources = {
        limits = {
          cpu = "500m";
          memory = "2Gi";
        };
        requests = {
          cpu = "250m";
          memory = "1Gi";
        };
      };

      # Prometheus configuration
      configMap = {
        "prometheus.yml" = ''
          global:
            scrape_interval: 15s
            evaluation_interval: 15s
          
          scrape_configs:
            - job_name: 'api-gateway'
              static_configs:
                - targets: ['api-gateway:9090']
            
            - job_name: 'postgres'
              static_configs:
                - targets: ['postgres:9187']
            
            - job_name: 'redis'
              static_configs:
                - targets: ['redis:9121']
            
            - job_name: 'rabbitmq'
              static_configs:
                - targets: ['rabbitmq:15692']
        '';
      };

      # Persistent storage
      storage = {
        enabled = true;
        size = "100Gi";
        storageClass = "fast-ssd";
        mountPath = "/prometheus";
      };

      # Health checks
      livenessProbe = {
        httpGet.path = "/-/healthy";
        httpGet.port = 9090;
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };

      readinessProbe = {
        httpGet.path = "/-/ready";
        httpGet.port = 9090;
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };
    };

    # Grafana Dashboards
    grafana = {
      name = "grafana";
      image = "grafana/grafana:10.0.0";
      replicas = 1;
      ports = [ 3000 ];
      
      compliance = {
        framework = "SOC2";
        level = "standard";
        owner = "platform-team";
        dataClassification = "internal";
      };

      dependencies = [ "prometheus" ];

      resources = {
        limits = {
          cpu = "500m";
          memory = "512Mi";
        };
        requests = {
          cpu = "250m";
          memory = "256Mi";
        };
      };

      # Environment
      env = {
        GF_SECURITY_ADMIN_PASSWORD = "changeme";
        GF_USERS_ALLOW_SIGN_UP = "false";
        GF_ANALYTICS_REPORTING_ENABLED = "false";
      };

      # Secrets
      secrets = {
        admin_password = {
          backend = "external-secret";
          secretStore = "vault";
          secretKey = "grafana-admin-password";
          vaultPath = "secret/data/monitoring/grafana";
        };
      };

      # ConfigMap for data sources
      configMap = {
        "datasources.yaml" = ''
          apiVersion: 1
          
          datasources:
            - name: Prometheus
              type: prometheus
              url: http://prometheus:9090
              access: proxy
              isDefault: true
        '';
      };

      # Health checks
      livenessProbe = {
        httpGet.path = "/api/health";
        httpGet.port = 3000;
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };

      readinessProbe = {
        httpGet.path = "/api/health";
        httpGet.port = 3000;
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };
    };
  };

  # Service definitions (Layer 2 conveniences)
  services = {
    frontend = {
      selector = { app = "frontend"; };
      ports = [ { port = 80; targetPort = 80; } ];
      type = "LoadBalancer";
    };

    api-gateway = {
      selector = { app = "api-gateway"; };
      ports = [ { port = 8080; targetPort = 8080; } ];
      type = "ClusterIP";
    };

    postgres = {
      selector = { app = "postgres"; };
      ports = [ { port = 5432; targetPort = 5432; } ];
      type = "ClusterIP";
      clusterIP = "None"; # Headless service for StatefulSet
    };

    redis = {
      selector = { app = "redis"; };
      ports = [ { port = 6379; targetPort = 6379; } ];
      type = "ClusterIP";
    };

    rabbitmq = {
      selector = { app = "rabbitmq"; };
      ports = [
        { port = 5672; targetPort = 5672; }
        { port = 15672; targetPort = 15672; }
      ];
      type = "ClusterIP";
    };

    prometheus = {
      selector = { app = "prometheus"; };
      ports = [ { port = 9090; targetPort = 9090; } ];
      type = "ClusterIP";
    };

    grafana = {
      selector = { app = "grafana"; };
      ports = [ { port = 3000; targetPort = 3000; } ];
      type = "ClusterIP";
    };
  };

  # Ingress configuration
  ingress = {
    enabled = true;
    className = "nginx";
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt-prod";
      "nginx.ingress.kubernetes.io/ssl-redirect" = "true";
    };
    
    hosts = [
      {
        host = "app.example.com";
        paths = [
          { path = "/"; pathType = "Prefix"; service = "frontend"; }
        ];
      }
      {
        host = "grafana.example.com";
        paths = [
          { path = "/"; pathType = "Prefix"; service = "grafana"; }
        ];
      }
    ];
    
    tls = [
      {
        secretName = "app-tls";
        hosts = [ "app.example.com" "grafana.example.com" ];
      }
    ];
  };
}
