# Example: Helm Integration Module
#
# This example demonstrates comprehensive usage of the Nixernetes Helm Integration
# module for generating production-grade Helm charts from Nix configurations.
#
# The Helm Integration module provides:
# - Chart generation and validation
# - Values file generation and composition
# - Seamless unified API integration
# - Dependency management
# - Chart packaging and publishing
# - Template helpers for common resources

{ lib, ... }:

let
  helmIntegration = import ../src/lib/helm-integration.nix { inherit lib; };

in
{
  # ============================================================================
  # Example 1: Basic Web Application Chart
  # ============================================================================
  
  basic_web_chart = helmIntegration.mkHelmChart "nginx-web" {
    description = "Simple Nginx web server";
    version = "1.0.0";
    appVersion = "1.24.0";
    
    image = {
      repository = "nginx";
      tag = "1.24-alpine";
      pullPolicy = "IfNotPresent";
    };
    
    service = {
      type = "ClusterIP";
      port = 80;
      targetPort = 8080;
    };
    
    replicaCount = 2;
  };

  # ============================================================================
  # Example 2: Database Chart with Full Configuration
  # ============================================================================
  
  postgresql_chart = helmIntegration.mkHelmChart "postgresql-db" {
    description = "PostgreSQL database server";
    version = "2.0.0";
    appVersion = "15.2";
    
    image = {
      repository = "postgres";
      tag = "15.2-alpine";
    };
    
    service = {
      type = "ClusterIP";
      port = 5432;
      targetPort = 5432;
    };
    
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
    
    # Environment variables for PostgreSQL
    env = [
      { name = "POSTGRES_DB"; value = "appdb"; }
      { name = "POSTGRES_USER"; value = "postgres"; }
    ];
    
    # Health checks
    livenessProbe = {
      exec = {
        command = ["pg_isready" "-U" "postgres"];
      };
      initialDelaySeconds = 30;
      periodSeconds = 10;
    };
    
    readinessProbe = {
      exec = {
        command = ["pg_isready" "-U" "postgres"];
      };
      initialDelaySeconds = 5;
      periodSeconds = 5;
    };
    
    replicaCount = 1;
  };

  # ============================================================================
  # Example 3: Multi-Application Chart Repository
  # ============================================================================
  
  # Parent chart with dependencies
  multi_app_chart = helmIntegration.mkHelmChart "microservices-stack" {
    description = "Complete microservices stack with multiple components";
    version = "3.0.0";
    appVersion = "1.0.0";
    type = "application";
    keywords = ["microservices" "kubernetes" "helm"];
    
    dependencies = [
      {
        name = "nginx-web";
        version = "1.0.0";
        repository = "oci://registry.example.com/charts";
      }
      {
        name = "postgresql-db";
        version = "2.0.0";
        repository = "oci://registry.example.com/charts";
      }
    ];
    
    image = {
      repository = "myapp";
      tag = "1.2.3";
    };
    
    service = {
      type = "LoadBalancer";
      port = 443;
      targetPort = 8443;
    };
    
    replicaCount = 3;
  };

  # ============================================================================
  # Example 4: Chart with Dependencies and Overrides
  # ============================================================================
  
  api_gateway_chart = helmIntegration.mkHelmChart "api-gateway" {
    description = "Kong API Gateway with managed dependencies";
    version = "1.5.0";
    appVersion = "3.1.0";
    
    dependencies = [
      (helmIntegration.mkChartDependency "postgresql" {
        version = "2.0.0";
        repository = "oci://registry.example.com/charts";
        condition = "postgresql.enabled";
      })
      (helmIntegration.mkChartDependency "redis" {
        version = "1.0.0";
        repository = "oci://registry.example.com/charts";
        tags = ["cache"];
      })
    ];
    
    image = {
      repository = "kong";
      tag = "3.1.0-alpine";
      pullPolicy = "IfNotPresent";
    };
    
    service = {
      type = "ClusterIP";
      port = 8000;
      targetPort = 8000;
    };
    
    ingress = {
      enabled = true;
      className = "nginx";
      hosts = [
        {
          host = "api.example.com";
          paths = [
            {
              path = "/";
              pathType = "Prefix";
            }
          ];
        }
      ];
      tls = [
        {
          secretName = "api-gateway-tls";
          hosts = ["api.example.com"];
        }
      ];
    };
    
    autoscaling = {
      enabled = true;
      minReplicas = 3;
      maxReplicas = 10;
      targetCPUUtilizationPercentage = 70;
    };
    
    replicaCount = 3;
  };

  # ============================================================================
  # Example 5: Production-Grade Application Chart
  # ============================================================================
  
  production_backend_chart = helmIntegration.mkHelmChart "api-server" {
    description = "Production-grade API server with security and observability";
    version = "4.2.0";
    appVersion = "2.1.5";
    
    # Metadata
    keywords = ["api" "backend" "production"];
    maintainers = [
      {
        name = "Engineering Team";
        email = "eng@example.com";
      }
    ];
    home = "https://github.com/example/api-server";
    sources = ["https://github.com/example/api-server"];
    kubeVersion = ">=1.28.0";
    
    image = {
      repository = "myregistry.azurecr.io/api-server";
      tag = "2.1.5";
      pullPolicy = "IfNotPresent";
    };
    
    imagePullSecrets = [
      { name = "registry-credentials"; }
    ];
    
    # Service account
    serviceAccount = {
      create = true;
      annotations = {
        "eks.amazonaws.com/role-arn" = "arn:aws:iam::123456789:role/api-server";
      };
      name = "";
    };
    
    # Pod configuration
    podAnnotations = {
      "prometheus.io/scrape" = "true";
      "prometheus.io/port" = "8000";
      "prometheus.io/path" = "/metrics";
    };
    
    podSecurityContext = {
      runAsNonRoot = true;
      runAsUser = 1000;
      runAsGroup = 3000;
      fsGroup = 2000;
    };
    
    securityContext = {
      allowPrivilegeEscalation = false;
      capabilities = {
        drop = ["ALL"];
      };
      readOnlyRootFilesystem = true;
    };
    
    # Service and networking
    service = {
      type = "ClusterIP";
      port = 8000;
      targetPort = 8000;
      annotations = {
        "cloud.google.com/neg" = ''{"ingress": true}'';
      };
    };
    
    ingress = {
      enabled = true;
      className = "nginx";
      annotations = {
        "cert-manager.io/cluster-issuer" = "letsencrypt-prod";
        "nginx.ingress.kubernetes.io/rate-limit" = "100";
      };
      hosts = [
        {
          host = "api.production.example.com";
          paths = [
            {
              path = "/";
              pathType = "Prefix";
            }
          ];
        }
      ];
      tls = [
        {
          secretName = "api-server-tls";
          hosts = ["api.production.example.com"];
        }
      ];
    };
    
    # Resource management
    resources = {
      limits = {
        cpu = "2000m";
        memory = "2Gi";
      };
      requests = {
        cpu = "1000m";
        memory = "1Gi";
      };
    };
    
    # Auto-scaling
    autoscaling = {
      enabled = true;
      minReplicas = 3;
      maxReplicas = 20;
      targetCPUUtilizationPercentage = 60;
    };
    
    # Node affinity and tolerations
    nodeSelector = {
      "workload-type" = "backend";
    };
    
    affinity = {
      podAntiAffinity = {
        preferredDuringSchedulingIgnoredDuringExecution = [
          {
            weight = 100;
            podAffinityTerm = {
              labelSelector = {
                matchExpressions = [
                  {
                    key = "app";
                    operator = "In";
                    values = ["api-server"];
                  }
                ];
              };
              topologyKey = "kubernetes.io/hostname";
            };
          }
        ];
      };
    };
    
    tolerations = [
      {
        key = "dedicated";
        operator = "Equal";
        value = "backend";
        effect = "NoSchedule";
      }
    ];
    
    # Environment configuration
    env = [
      { name = "ENVIRONMENT"; value = "production"; }
      { name = "LOG_LEVEL"; value = "info"; }
      { name = "METRICS_ENABLED"; value = "true"; }
      { name = "TRACING_ENABLED"; value = "true"; }
    ];
    
    # Health probes
    livenessProbe = {
      httpGet = {
        path = "/health/live";
        port = 8000;
      };
      initialDelaySeconds = 30;
      periodSeconds = 10;
      timeoutSeconds = 5;
      failureThreshold = 3;
    };
    
    readinessProbe = {
      httpGet = {
        path = "/health/ready";
        port = 8000;
      };
      initialDelaySeconds = 5;
      periodSeconds = 5;
      timeoutSeconds = 3;
      failureThreshold = 1;
    };
    
    replicaCount = 3;
  };

  # ============================================================================
  # Example 6: Multi-Tenant SaaS Chart
  # ============================================================================
  
  saas_platform_chart = helmIntegration.mkHelmChart "saas-platform" {
    description = "Multi-tenant SaaS platform with advanced configuration";
    version = "1.0.0";
    appVersion = "1.0.0";
    
    keywords = ["saas" "multi-tenant" "production"];
    maintainers = [
      {
        name = "Platform Team";
        email = "platform@example.com";
      }
    ];
    
    image = {
      repository = "gcr.io/saas-platform/app";
      tag = "1.0.0";
      pullPolicy = "IfNotPresent";
    };
    
    # Multi-environment support
    service = {
      type = "ClusterIP";
      port = 443;
      targetPort = 8443;
      annotations = {
        "cloud.google.com/neg" = ''{"ingress": true}'';
        "cloud.google.com/backend-config" = "api-backend-config";
      };
    };
    
    ingress = {
      enabled = true;
      className = "gce";
      annotations = {
        "networking.gke.io/managed-certificates" = "saas-platform-cert";
        "kubernetes.io/ingress.class" = "gce";
      };
      hosts = [
        {
          host = "platform.example.com";
          paths = [
            {
              path = "/*";
              pathType = "ImplementationSpecific";
            }
          ];
        }
        {
          host = "*.example.com";
          paths = [
            {
              path = "/*";
              pathType = "ImplementationSpecific";
            }
          ];
        }
      ];
    };
    
    # Resource management for multi-tenant
    resources = {
      limits = {
        cpu = "4000m";
        memory = "4Gi";
      };
      requests = {
        cpu = "2000m";
        memory = "2Gi";
      };
    };
    
    autoscaling = {
      enabled = true;
      minReplicas = 5;
      maxReplicas = 50;
      targetCPUUtilizationPercentage = 50;
    };
    
    # Tenant isolation
    podSecurityContext = {
      runAsNonRoot = true;
      runAsUser = 1000;
      fsGroup = 1000;
    };
    
    replicaCount = 5;
  };

  # ============================================================================
  # Example 7: Chart Validation and Packaging
  # ============================================================================
  
  chart_validation_example = 
    let
      chart = helmIntegration.mkHelmChart "validated-app" {
        description = "Application with full validation";
        version = "1.0.0";
        appVersion = "1.0.0";
        
        image = {
          repository = "myapp";
          tag = "1.0.0";
        };
        
        service = {
          type = "ClusterIP";
          port = 80;
          targetPort = 8080;
        };
      };
      
      validation = helmIntegration.validateChart chart;
    in
    {
      inherit chart validation;
      
      # Package the chart for distribution
      package = helmIntegration.mkChartPackage chart;
    };

  # ============================================================================
  # Example 8: Values Override and Composition
  # ============================================================================
  
  values_override_example = 
    let
      baseChart = helmIntegration.mkHelmChart "base-app" {
        description = "Base application";
        version = "1.0.0";
        
        image = {
          repository = "nginx";
          tag = "1.24";
        };
        
        service = {
          type = "ClusterIP";
          port = 80;
          targetPort = 8080;
        };
        
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
      };
      
      # Production overrides
      productionOverride = helmIntegration.mkValuesOverride {
        replicaCount = 5;
        imageRepository = "myregistry.azurecr.io/nginx";
        imageTag = "1.24-production";
        imagePullPolicy = "IfNotPresent";
        serviceType = "LoadBalancer";
        servicePort = 443;
        ingressEnabled = true;
        ingressHosts = [
          { host = "app.production.com"; paths = []; }
        ];
        resourceLimitsCpu = "2000m";
        resourceLimitsMemory = "2Gi";
        resourceRequestsCpu = "1000m";
        resourceRequestsMemory = "1Gi";
      };
      
      # Staging overrides
      stagingOverride = helmIntegration.mkValuesOverride {
        replicaCount = 2;
        imageRepository = "myregistry.azurecr.io/nginx";
        imageTag = "1.24-staging";
        serviceType = "ClusterIP";
        ingressEnabled = true;
        ingressHosts = [
          { host = "app.staging.com"; paths = []; }
        ];
        resourceLimitsCpu = "1000m";
        resourceLimitsMemory = "1Gi";
        resourceRequestsCpu = "500m";
        resourceRequestsMemory = "512Mi";
      };
    in
    {
      inherit baseChart productionOverride stagingOverride;
    };

  # ============================================================================
  # Framework information
  # ============================================================================
  
  framework_info = helmIntegration.framework;
}
