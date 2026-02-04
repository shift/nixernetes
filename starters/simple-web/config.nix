# Simple Web Application Configuration
# This is a basic Nixernetes configuration for a simple web app
# with Nginx, PostgreSQL, and Redis

{
  # Application metadata
  metadata = {
    name = "simple-web";
    namespace = "default";
    labels = {
      app = "simple-web";
      tier = "web";
    };
  };

  # Web server configuration
  web = {
    image = "nginx:latest";
    port = 80;
    replicas = 2;
    
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

    healthCheck = {
      httpGet = {
        path = "/";
        port = 80;
      };
      initialDelaySeconds = 10;
      periodSeconds = 10;
    };

    env = {
      LOG_LEVEL = "info";
      NODE_ENV = "production";
    };
  };

  # Database configuration
  database = {
    type = "postgresql";
    image = "postgres:15-alpine";
    port = 5432;
    replicas = 1;
    
    environment = {
      POSTGRES_DB = "myapp";
      POSTGRES_USER = "appuser";
      # POSTGRES_PASSWORD should come from a secret
    };

    persistence = {
      enabled = true;
      size = "10Gi";
    };

    resources = {
      requests = {
        memory = "256Mi";
        cpu = "100m";
      };
      limits = {
        memory = "512Mi";
        cpu = "1000m";
      };
    };
  };

  # Cache configuration
  cache = {
    type = "redis";
    image = "redis:7-alpine";
    port = 6379;
    replicas = 1;
    
    resources = {
      requests = {
        memory = "128Mi";
        cpu = "50m";
      };
      limits = {
        memory = "256Mi";
        cpu = "500m";
      };
    };
  };

  # Service configuration
  service = {
    type = "LoadBalancer";
    port = 80;
    targetPort = 80;
  };

  # Ingress configuration (optional)
  ingress = {
    enabled = false;
    # Uncomment to enable:
    # className = "nginx";
    # hosts = ["myapp.example.com"];
    # tls = {
    #   enabled = true;
    #   issuer = "letsencrypt-prod";
    # };
  };

  # Network policies
  networkPolicy = {
    enabled = true;
    policyTypes = ["Ingress" "Egress"];
  };
}
