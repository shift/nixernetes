# Nixernetes Service Mesh Integration Examples
#
# Comprehensive examples demonstrating service mesh configurations
# for different use cases and requirements.

{ lib }:

let
  serviceMesh = import ./service-mesh.nix { inherit lib; };
in

{
  # Example 1: Basic Istio Installation
  exampleBasicIstio = serviceMesh.mkIstioMesh "basic" {
    namespace = "istio-system";
    version = "1.17.0";
    installMode = "demo";
    profile = "default";
    
    enableIngressGateway = true;
    enableEgressGateway = false;
    enableIstiod = true;
    
    enableMtls = true;
    mtlsMode = "PERMISSIVE";
    
    enableTracing = true;
    tracingProvider = "jaeger";
    
    enableSidecarInjection = true;
    sidecarInjectionNamespaces = ["default" "production"];
  };

  # Example 2: Production Istio with Strict mTLS
  exampleProductionIstio = {
    mesh = serviceMesh.mkIstioMesh "production" {
      namespace = "istio-system";
      version = "1.17.0";
      installMode = "production";
      profile = "default";
      
      enableIngressGateway = true;
      enableEgressGateway = true;
      enableIstiod = true;
      
      enableMtls = true;
      mtlsMode = "STRICT";
      enableAuthorizationPolicy = true;
      enablePeerAuthentication = true;
      
      enableMetrics = true;
      enableTracing = true;
      tracingProvider = "jaeger";
      enableKiali = true;
      enablePrometheus = true;
      
      enableRateLimiting = true;
      enableCircuitBreaking = true;
      enableRetries = true;
      enableTimeouts = true;
      
      cpuRequest = "200m";
      memoryRequest = "512Mi";
      cpuLimit = "2000m";
      memoryLimit = "1024Mi";
      
      enableSidecarInjection = true;
      sidecarInjectionNamespaces = ["default" "production" "staging"];
    };
    
    peerAuth = serviceMesh.mkPeerAuthentication "default-mtls" {
      namespace = "istio-system";
      mtlsMode = "STRICT";
    };
    
    authPolicy = serviceMesh.mkAuthorizationPolicy "default-allow" {
      namespace = "istio-system";
      action = "ALLOW";
    };
    
    observability = serviceMesh.mkObservabilityConfig "production" {
      metricsEnabled = true;
      prometheusEnabled = true;
      tracingEnabled = true;
      tracingProvider = "jaeger";
      tracingSamplingRate = 0.1;
      dashboardEnabled = true;
      dashboardProvider = "kiali";
      topologyEnabled = true;
    };
  };

  # Example 3: Lightweight Linkerd Installation
  exampleLinkerdLight = serviceMesh.mkLinkerdMesh "lightweight" {
    namespace = "linkerd";
    version = "2.14.0";
    installMode = "stable";
    
    enableControlPlane = true;
    enableDataPlane = true;
    enableViz = true;
    enableJaeger = false;
    
    enableMtls = true;
    mtlsRotationDays = 365;
    enablePolicy = false;
    
    enableMetrics = true;
    enableTracing = false;
    
    enableHA = false;
    replicas = 1;
    
    enableAutoInject = true;
    excludeNamespaces = ["kube-system" "kube-public" "kube-node-lease"];
  };

  # Example 4: Linkerd with High Availability and Tracing
  exampleLinkerdHA = {
    mesh = serviceMesh.mkLinkerdMesh "ha" {
      namespace = "linkerd";
      version = "2.14.0";
      installMode = "stable";
      
      enableControlPlane = true;
      enableDataPlane = true;
      enableViz = true;
      enableJaeger = true;
      
      enableMtls = true;
      mtlsRotationDays = 365;
      enablePolicy = true;
      
      enableMetrics = true;
      enableTracing = true;
      tracingCollector = "jaeger";
      enableServiceTopology = true;
      
      enableHA = true;
      replicas = 3;
      
      enableAutoInject = true;
      excludeNamespaces = ["kube-system"];
      
      cpuRequest = "50m";
      cpuLimit = "200m";
      memoryRequest = "64Mi";
      memoryLimit = "500Mi";
    };
    
    observability = serviceMesh.mkObservabilityConfig "ha" {
      metricsEnabled = true;
      tracingEnabled = true;
      tracingProvider = "jaeger";
      tracingSamplingRate = 0.05;
      accessLogEnabled = true;
      dashboardEnabled = true;
      dashboardProvider = "linkerd-viz";
      topologyEnabled = true;
    };
  };

  # Example 5: Canary Deployment with Traffic Splitting
  exampleCanaryDeployment = {
    virtualService = serviceMesh.mkVirtualService "app-service" {
      namespace = "production";
      hosts = ["app" "app.production.svc.cluster.local"];
      
      httpRoutes = [
        {
          name = "canary";
          match = [{ uri = { prefix = "/"; }; }];
          route = [
            {
              destination = {
                host = "app-service";
                subset = "stable";
                port = { number = 8080; };
              };
              weight = 90;
            }
            {
              destination = {
                host = "app-service";
                subset = "canary";
                port = { number = 8080; };
              };
              weight = 10;
            }
          ];
          timeout = "30s";
          retries = {
            attempts = 3;
            perTryTimeout = "10s";
          };
        }
      ];
    };
    
    destinationRule = serviceMesh.mkDestinationRule "app-service" {
      namespace = "production";
      host = "app-service";
      
      trafficPolicy = {
        connectionPool = {
          tcp = { maxConnections = 100; };
          http = { http1MaxPendingRequests = 100; };
        };
        outlierDetection = {
          consecutiveErrors = 5;
          interval = "30s";
          baseEjectionTime = "30s";
          maxEjectionPercent = 50;
        };
      };
      
      subsets = [
        {
          name = "stable";
          labels = { version = "v1"; };
        }
        {
          name = "canary";
          labels = { version = "v2"; };
        }
      ];
    };
  };

  # Example 6: Resilient Service with Circuit Breaking
  exampleResilientService = {
    trafficPolicy = serviceMesh.mkTrafficPolicy "resilient-policy" {
      circuitBreaker = {
        enabled = true;
        consecutiveErrors = 5;
        interval = "30s";
        baseEjectionTime = "30s";
        maxEjectionPercent = 50;
        minRequestVolume = 5;
      };
      
      retries = {
        enabled = true;
        attempts = 3;
        perTryTimeout = "10s";
        retryOn = "5xx,reset,connect-failure,retriable-4xx";
      };
      
      timeout = "30s";
      
      connectionPool = {
        tcp = { maxConnections = 100; };
        http = {
          http1MaxPendingRequests = 100;
          maxRequestsPerConnection = 2;
          h2UpgradePolicy = "UPGRADE";
        };
      };
      
      loadBalancer = "ROUND_ROBIN";
    };
    
    destinationRule = serviceMesh.mkDestinationRule "resilient-service" {
      namespace = "production";
      host = "resilient-service";
      
      trafficPolicy = {
        connectionPool = {
          tcp = { maxConnections = 100; };
          http = { http1MaxPendingRequests = 100; };
        };
        outlierDetection = {
          consecutiveErrors = 5;
          interval = "30s";
          baseEjectionTime = "30s";
          maxEjectionPercent = 50;
          minRequestVolume = 5;
        };
      };
    };
  };

  # Example 7: Secure Service with Authorization Policies
  exampleSecureService = {
    peerAuth = serviceMesh.mkPeerAuthentication "strict-mtls" {
      namespace = "production";
      mtlsMode = "STRICT";
      selector = { "app" = "api"; };
    };
    
    authPolicy = serviceMesh.mkAuthorizationPolicy "api-authz" {
      namespace = "production";
      action = "ALLOW";
      selector = { "app" = "api"; };
      
      rules = [
        {
          from = [
            {
              source = {
                principals = [
                  "cluster.local/ns/production/sa/frontend"
                  "cluster.local/ns/production/sa/mobile-app"
                ];
              };
            }
          ];
          to = [
            {
              operation = {
                methods = ["GET" "POST" "PUT"];
                paths = ["/api/v1/*" "/api/v2/*"];
              };
            }
          ];
        }
      ];
    };
    
    serviceEntry = serviceMesh.mkServiceEntry "external-payment-api" {
      namespace = "production";
      hosts = ["payment.external.com"];
      location = "MESH_EXTERNAL";
      
      ports = [
        { name = "https"; number = 443; protocol = "HTTPS"; }
      ];
      
      resolution = "DNS";
      subjectAltNames = ["payment.external.com"];
    };
  };

  # Example 8: Complete Mesh with Observability
  exampleCompleteObservableMesh = {
    istioMesh = serviceMesh.mkIstioMesh "observable" {
      namespace = "istio-system";
      version = "1.17.0";
      installMode = "production";
      
      enableIngressGateway = true;
      enableEgressGateway = true;
      
      enableMtls = true;
      mtlsMode = "STRICT";
      enableAuthorizationPolicy = true;
      
      enableMetrics = true;
      enableTracing = true;
      tracingProvider = "jaeger";
      enableKiali = true;
      enablePrometheus = true;
      
      enableRateLimiting = true;
      enableCircuitBreaking = true;
    };
    
    observability = serviceMesh.mkObservabilityConfig "complete" {
      metricsEnabled = true;
      metricsPort = 15000;
      prometheusEnabled = true;
      prometheusPort = 9090;
      
      tracingEnabled = true;
      tracingProvider = "jaeger";
      tracingPort = 6831;
      tracingSamplingRate = 0.05;
      tracingCollectorAddress = "jaeger-collector.observability:14268";
      
      accessLogEnabled = true;
      accessLogFormat = "default";
      logLevel = "info";
      
      dashboardEnabled = true;
      dashboardProvider = "kiali";
      dashboardPort = 20001;
      
      topologyEnabled = true;
    };
    
    meshConfig = serviceMesh.mkMeshConfig "complete" {
      meshType = "istio";
      protocolDetectionEnabled = true;
      serviceDiscoveryType = "kubernetes";
      
      defaultCircuitBreakerPolicy = {
        consecutiveErrors = 5;
        interval = "30s";
        baseEjectionTime = "30s";
      };
      
      defaultRetryPolicy = {
        attempts = 3;
        perTryTimeout = "10s";
      };
      
      defaultTimeout = "30s";
      defaultMtlsPolicy = "PERMISSIVE";
      
      enableWorkloadEntryCleanup = true;
      workloadEntryCleanupAge = "24h";
    };
  };

  # Example 9: Multi-Cluster Mesh Setup
  exampleMultiClusterSetup = {
    primary = serviceMesh.mkIstioMesh "primary" {
      namespace = "istio-system";
      version = "1.17.0";
      installMode = "production";
      
      enableIngressGateway = true;
      enableEgressGateway = true;
      enableIstiod = true;
      
      labels = {
        "topology.istio.io/network" = "network1";
      };
    };
    
    secondary = serviceMesh.mkIstioMesh "secondary" {
      namespace = "istio-system";
      version = "1.17.0";
      installMode = "production";
      
      enableIngressGateway = true;
      enableEgressGateway = true;
      enableIstiod = false;
      
      labels = {
        "topology.istio.io/network" = "network2";
      };
    };
  };

  # Example 10: Development Environment Setup
  exampleDevelopmentSetup = {
    mesh = serviceMesh.mkIstioMesh "dev" {
      namespace = "istio-system";
      version = "1.17.0";
      installMode = "demo";
      profile = "default";
      
      enableIngressGateway = true;
      enableEgressGateway = false;
      enableIstiod = true;
      
      enableMtls = true;
      mtlsMode = "PERMISSIVE";
      enableAuthorizationPolicy = false;
      
      enableMetrics = true;
      enableTracing = true;
      tracingProvider = "jaeger";
      enableKiali = true;
      
      enableSidecarInjection = true;
      sidecarInjectionNamespaces = ["default"];
      
      cpuRequest = "50m";
      memoryRequest = "128Mi";
      cpuLimit = "500m";
      memoryLimit = "256Mi";
    };
    
    observability = serviceMesh.mkObservabilityConfig "dev" {
      metricsEnabled = true;
      tracingEnabled = true;
      tracingProvider = "jaeger";
      tracingSamplingRate = 1.0;
      dashboardEnabled = true;
      dashboardProvider = "kiali";
    };
  };
}
