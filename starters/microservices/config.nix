# Microservices Architecture Configuration
# Multiple services with shared infrastructure

{
  metadata = {
    name = "microservices-app";
    namespace = "default";
    labels = {
      app = "microservices";
      tier = "services";
    };
  };

  # Frontend service
  frontend = {
    name = "frontend";
    image = "myrepo/frontend:latest";
    port = 3000;
    replicas = 2;
    
    env = {
      API_URL = "http://api:5000";
      NODE_ENV = "production";
    };

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

    healthCheck = {
      httpGet = {
        path = "/health";
        port = 3000;
      };
      initialDelaySeconds = 15;
      periodSeconds = 10;
    };
  };

  # API service
  api = {
    name = "api";
    image = "myrepo/api:latest";
    port = 5000;
    replicas = 3;
    
    env = {
      NODE_ENV = "production";
      LOG_LEVEL = "info";
      REDIS_URL = "redis://cache:6379";
      RABBITMQ_URL = "amqp://rabbitmq:5672";
    };

    resources = {
      requests = {
        memory = "512Mi";
        cpu = "250m";
      };
      limits = {
        memory = "1Gi";
        cpu = "1000m";
      };
    };

    healthCheck = {
      httpGet = {
        path = "/health";
        port = 5000;
      };
      initialDelaySeconds = 20;
      periodSeconds = 10;
    };

    autoscaling = {
      enabled = true;
      minReplicas = 3;
      maxReplicas = 10;
      targetCPUUtilizationPercentage = 70;
    };
  };

  # Background worker service
  worker = {
    name = "worker";
    image = "myrepo/worker:latest";
    replicas = 2;
    
    env = {
      NODE_ENV = "production";
      LOG_LEVEL = "info";
      RABBITMQ_URL = "amqp://rabbitmq:5672";
    };

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

    autoscaling = {
      enabled = true;
      minReplicas = 2;
      maxReplicas = 8;
      targetCPUUtilizationPercentage = 75;
    };
  };

  # PostgreSQL database
  database = {
    name = "postgres";
    image = "postgres:15-alpine";
    port = 5432;
    replicas = 1;
    
    environment = {
      POSTGRES_DB = "appdb";
      POSTGRES_USER = "appuser";
    };

    persistence = {
      enabled = true;
      size = "50Gi";
    };

    resources = {
      requests = {
        memory = "512Mi";
        cpu = "250m";
      };
      limits = {
        memory = "2Gi";
        cpu = "1000m";
      };
    };

    healthCheck = {
      exec = {
        command = ["pg_isready" "-U" "appuser"];
      };
      initialDelaySeconds = 10;
      periodSeconds = 10;
    };
  };

  # Redis cache
  cache = {
    name = "cache";
    image = "redis:7-alpine";
    port = 6379;
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

    persistence = {
      enabled = true;
      size = "10Gi";
    };
  };

  # RabbitMQ message broker
  rabbitmq = {
    name = "rabbitmq";
    image = "rabbitmq:3-management-alpine";
    port = 5672;
    managementPort = 15672;
    replicas = 1;
    
    environment = {
      RABBITMQ_DEFAULT_USER = "guest";
      RABBITMQ_DEFAULT_PASS = "guest";
    };

    resources = {
      requests = {
        memory = "512Mi";
        cpu = "250m";
      };
      limits = {
        memory = "1Gi";
        cpu = "1000m";
      };
    };

    persistence = {
      enabled = true;
      size = "20Gi";
    };

    healthCheck = {
      httpGet = {
        path = "/api/health/ready";
        port = 15672;
      };
      initialDelaySeconds = 30;
      periodSeconds = 10;
    };
  };

  # Frontend service
  frontendService = {
    name = "frontend";
    type = "LoadBalancer";
    port = 80;
    targetPort = 3000;
    selector = { app = "frontend"; };
  };

  # API service
  apiService = {
    name = "api";
    type = "ClusterIP";
    port = 5000;
    targetPort = 5000;
    selector = { app = "api"; };
  };

  # Network policies
  networkPolicy = {
    enabled = true;
    policyTypes = ["Ingress" "Egress"];
    
    # Frontend can receive from internet
    # Frontend can reach API
    # API can reach DB, Redis, RabbitMQ
    # Worker can reach DB, RabbitMQ
    # DB/Redis/RabbitMQ only respond to services
  };
}
