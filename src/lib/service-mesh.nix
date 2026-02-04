# Nixernetes Service Mesh Integration Module
#
# Provides comprehensive service mesh support for Kubernetes clusters including:
# - Istio installation and configuration
# - Linkerd installation and configuration
# - Traffic management (routing, load balancing, retries)
# - Security policies (mTLS, authorization)
# - Observability (metrics, tracing, logging)
# - Circuit breaking and resilience patterns
# - Service-to-service communication management
#
# This module enables secure, observable, and resilient service communication
# with support for both Istio and Linkerd service meshes.

{ lib }:

let
  inherit (lib) mkOption types;
in

{
  # Create Istio service mesh configuration
  mkIstioMesh = name: config:
    let
      cfg = {
        name = name;
        enabled = config.enabled or true;
        namespace = config.namespace or "istio-system";
        version = config.version or "1.17.0";
        
        # Installation mode
        installMode = config.installMode or "demo";
        profile = config.profile or "default";
        
        # Core components
        enableIngressGateway = config.enableIngressGateway or true;
        enableEgressGateway = config.enableEgressGateway or true;
        enableIstiod = config.enableIstiod or true;
        
        # Traffic management
        enableVirtualService = config.enableVirtualService or true;
        enableDestinationRule = config.enableDestinationRule or true;
        enableGateway = config.enableGateway or true;
        
        # Security
        enableMtls = config.enableMtls or true;
        mtlsMode = config.mtlsMode or "PERMISSIVE";
        enableAuthorizationPolicy = config.enableAuthorizationPolicy or true;
        enablePeerAuthentication = config.enablePeerAuthentication or true;
        
        # Observability
        enableMetrics = config.enableMetrics or true;
        enableTracing = config.enableTracing or true;
        tracingProvider = config.tracingProvider or "jaeger";
        enableKiali = config.enableKiali or true;
        enablePrometheus = config.enablePrometheus or true;
        
        # Advanced features
        enableRateLimiting = config.enableRateLimiting or true;
        enableCircuitBreaking = config.enableCircuitBreaking or true;
        enableRetries = config.enableRetries or true;
        enableTimeouts = config.enableTimeouts or true;
        
        # Resource configuration
        cpuRequest = config.cpuRequest or "100m";
        memoryRequest = config.memoryRequest or "256Mi";
        cpuLimit = config.cpuLimit or "2000m";
        memoryLimit = config.memoryLimit or "1024Mi";
        
        # Sidecar injection
        enableSidecarInjection = config.enableSidecarInjection or true;
        sidecarInjectionNamespaces = config.sidecarInjectionNamespaces or [];
        sidecarProxyImage = config.sidecarProxyImage or "proxyv2";
        
        # Networking
        enableServiceEntry = config.enableServiceEntry or true;
        enableWorkloadEntry = config.enableWorkloadEntry or true;
        enableNetworkPolicy = config.enableNetworkPolicy or false;
        
        # Labels for identification
        labels = (config.labels or {}) // {
          "nixernetes.io/service-mesh" = "istio";
          "istio-version" = config.version or "1.17.0";
        };
        
        # Annotations
        annotations = config.annotations or {};
      };
    in
      cfg;

  # Create Linkerd service mesh configuration
  mkLinkerdMesh = name: config:
    let
      cfg = {
        name = name;
        enabled = config.enabled or true;
        namespace = config.namespace or "linkerd";
        version = config.version or "2.14.0";
        
        # Installation type
        installMode = config.installMode or "stable";
        controlPlaneVersion = config.controlPlaneVersion or "2.14.0";
        
        # Core components
        enableControlPlane = config.enableControlPlane or true;
        enableDataPlane = config.enableDataPlane or true;
        enableViz = config.enableViz or true;
        enableJaeger = config.enableJaeger or true;
        
        # Proxy configuration
        proxyImage = config.proxyImage or "linkerd-proxy";
        proxyImageVersion = config.proxyImageVersion or "2.14.0";
        cpuRequest = config.cpuRequest or "10m";
        cpuLimit = config.cpuLimit or "100m";
        memoryRequest = config.memoryRequest or "32Mi";
        memoryLimit = config.memoryLimit or "250Mi";
        
        # Security
        enableMtls = config.enableMtls or true;
        mtlsRotationDays = config.mtlsRotationDays or 365;
        enablePolicy = config.enablePolicy or true;
        
        # Observability
        enableMetrics = config.enableMetrics or true;
        enableTracing = config.enableTracing or true;
        tracingCollector = config.tracingCollector or "jaeger";
        enableServiceTopology = config.enableServiceTopology or true;
        
        # High availability
        enableHA = config.enableHA or false;
        replicas = config.replicas or (if config.enableHA or false then 3 else 1);
        
        # Auto-injection
        enableAutoInject = config.enableAutoInject or true;
        injectAnnotation = config.injectAnnotation or "linkerd.io/inject";
        excludeNamespaces = config.excludeNamespaces or ["kube-system" "kube-public"];
        
        # Network policies
        enableNetworkPolicy = config.enableNetworkPolicy or false;
        policyControllerReplicas = config.policyControllerReplicas or 1;
        
        # Labels for identification
        labels = (config.labels or {}) // {
          "nixernetes.io/service-mesh" = "linkerd";
          "linkerd-version" = config.version or "2.14.0";
        };
        
        # Annotations
        annotations = config.annotations or {};
      };
    in
      cfg;

  # Create virtual service configuration (Istio)
  mkVirtualService = name: config:
    let
      cfg = {
        name = name;
        namespace = config.namespace or "default";
        
        # Host configuration
        hosts = config.hosts or [name];
        
        # HTTP routing
        httpRoutes = config.httpRoutes or [];
        
        # TCP routing
        tcpRoutes = config.tcpRoutes or [];
        
        # TLS routing
        tlsRoutes = config.tlsRoutes or [];
        
        # Timeout configuration
        timeout = config.timeout or "30s";
        
        # Retry configuration
        retries = config.retries or {
          attempts = 3;
          perTryTimeout = "10s";
        };
        
        # Export to namespaces
        exportTo = config.exportTo or [];
        
        # Labels
        labels = config.labels or {};
      };
    in
      cfg;

  # Create destination rule configuration (Istio)
  mkDestinationRule = name: config:
    let
      cfg = {
        name = name;
        namespace = config.namespace or "default";
        host = config.host or name;
        
        # Traffic policy
        trafficPolicy = config.trafficPolicy or {
          connectionPool = {
            tcp = { maxConnections = 100; };
            http = { http1MaxPendingRequests = 100; };
          };
          outlierDetection = {
            consecutiveErrors = 5;
            interval = "30s";
            baseEjectionTime = "30s";
          };
        };
        
        # Subsets for canary/traffic splitting
        subsets = config.subsets or [];
        
        # Export to namespaces
        exportTo = config.exportTo or [];
        
        # Labels
        labels = config.labels or {};
      };
    in
      cfg;

  # Create traffic policy for resilience
  mkTrafficPolicy = name: config:
    let
      cfg = {
        name = name;
        
        # Circuit breaking
        circuitBreaker = config.circuitBreaker or {
          enabled = true;
          consecutiveErrors = 5;
          interval = "30s";
          baseEjectionTime = "30s";
          maxEjectionPercent = 50;
          minRequestVolume = 5;
        };
        
        # Retries
        retries = config.retries or {
          enabled = true;
          attempts = 3;
          perTryTimeout = "10s";
          retryOn = "5xx,reset,connect-failure,retriable-4xx";
        };
        
        # Timeouts
        timeout = config.timeout or "30s";
        
        # Connection pool
        connectionPool = config.connectionPool or {
          tcp = { maxConnections = 100; };
          http = {
            http1MaxPendingRequests = 100;
            maxRequestsPerConnection = 2;
            h2UpgradePolicy = "UPGRADE";
          };
        };
        
        # Load balancer
        loadBalancer = config.loadBalancer or "ROUND_ROBIN";
        
        # Rate limiting
        rateLimiting = config.rateLimiting or {
          enabled = false;
          actions = [];
        };
      };
    in
      cfg;

  # Create authorization policy (Istio)
  mkAuthorizationPolicy = name: config:
    let
      cfg = {
        name = name;
        namespace = config.namespace or "default";
        
        # Rules for allowed traffic
        rules = config.rules or [];
        
        # Policy action: ALLOW, DENY
        action = config.action or "ALLOW";
        
        # Selector for pods
        selector = config.selector or {};
        
        # Provider configuration
        provider = config.provider or null;
        
        # Labels
        labels = config.labels or {};
      };
    in
      cfg;

  # Create peer authentication (Istio mTLS)
  mkPeerAuthentication = name: config:
    let
      cfg = {
        name = name;
        namespace = config.namespace or "default";
        
        # mTLS mode: UNSET, DISABLE, PERMISSIVE, STRICT
        mtlsMode = config.mtlsMode or "STRICT";
        
        # Port-level mTLS settings
        portLevelMtls = config.portLevelMtls or {};
        
        # Selector for pods
        selector = config.selector or {};
        
        # Labels
        labels = config.labels or {};
      };
    in
      cfg;

  # Create service entry for external services
  mkServiceEntry = name: config:
    let
      cfg = {
        name = name;
        namespace = config.namespace or "default";
        
        # Hosts to define
        hosts = config.hosts or [name];
        
        # Location: MESH_INTERNAL, MESH_EXTERNAL
        location = config.location or "MESH_EXTERNAL";
        
        # Protocol: HTTP, HTTPS, GRPC, TCP, TLS
        ports = config.ports or [];
        
        # Resolution: NONE, STATIC, DNS, DNS_ROUND_ROBIN
        resolution = config.resolution or "STATIC";
        
        # Endpoints for static resolution
        endpoints = config.endpoints or [];
        
        # Export configuration
        exportTo = config.exportTo or [];
        
        # Subject alternative names for TLS
        subjectAltNames = config.subjectAltNames or [];
        
        # Labels
        labels = config.labels or {};
      };
    in
      cfg;

  # Create observability configuration
  mkObservabilityConfig = name: config:
    let
      cfg = {
        name = name;
        
        # Metrics
        metricsEnabled = config.metricsEnabled or true;
        metricsPort = config.metricsPort or 15000;
        prometheusEnabled = config.prometheusEnabled or true;
        prometheusPort = config.prometheusPort or 9090;
        
        # Tracing
        tracingEnabled = config.tracingEnabled or true;
        tracingProvider = config.tracingProvider or "jaeger";
        tracingPort = config.tracingPort or 6831;
        tracingSamplingRate = config.tracingSamplingRate or 0.01;
        tracingCollectorAddress = config.tracingCollectorAddress or "jaeger-collector:14268";
        
        # Logging
        accessLogEnabled = config.accessLogEnabled or true;
        accessLogFormat = config.accessLogFormat or "default";
        logLevel = config.logLevel or "info";
        
        # Dashboard
        dashboardEnabled = config.dashboardEnabled or true;
        dashboardProvider = config.dashboardProvider or "kiali";
        dashboardPort = config.dashboardPort or 20001;
        
        # Service topology
        topologyEnabled = config.topologyEnabled or true;
      };
    in
      cfg;

  # Create mesh-wide configuration
  mkMeshConfig = name: config:
    let
      cfg = {
        name = name;
        meshType = config.meshType or "istio";
        
        # Protocol detection
        protocolDetectionEnabled = config.protocolDetectionEnabled or true;
        
        # Gateway configuration
        gatewaySelector = config.gatewaySelector or { "istio" = "ingressgateway"; };
        
        # Service discovery
        serviceDiscoveryType = config.serviceDiscoveryType or "kubernetes";
        
        # Circuit breaking defaults
        defaultCircuitBreakerPolicy = config.defaultCircuitBreakerPolicy or {
          consecutiveErrors = 5;
          interval = "30s";
          baseEjectionTime = "30s";
        };
        
        # Retry defaults
        defaultRetryPolicy = config.defaultRetryPolicy or {
          attempts = 3;
          perTryTimeout = "10s";
        };
        
        # Timeout defaults
        defaultTimeout = config.defaultTimeout or "30s";
        
        # Mutual TLS defaults
        defaultMtlsPolicy = config.defaultMtlsPolicy or "PERMISSIVE";
        
        # Workload entry cleanup
        enableWorkloadEntryCleanup = config.enableWorkloadEntryCleanup or true;
        workloadEntryCleanupAge = config.workloadEntryCleanupAge or "24h";
      };
    in
      cfg;

  # Validate service mesh configuration
  validateServiceMesh = mesh:
    let
      errors = [];
      checks = {
        validMeshType = builtins.elem mesh.meshType ["istio" "linkerd"];
        validMtlsMode = if mesh ? mtlsMode then
          builtins.elem mesh.mtlsMode ["UNSET" "DISABLE" "PERMISSIVE" "STRICT"]
        else true;
        validNamespace = mesh.namespace != "";
        versionNotEmpty = mesh.version != "";
      };
      errorList = lib.optional (!checks.validMeshType) "Invalid mesh type: ${mesh.meshType}"
                ++ lib.optional (!checks.validMtlsMode) "Invalid mTLS mode: ${mesh.mtlsMode or "unknown"}"
                ++ lib.optional (!checks.validNamespace) "Mesh namespace cannot be empty"
                ++ lib.optional (!checks.versionNotEmpty) "Mesh version cannot be empty";
    in
      {
        valid = builtins.length errorList == 0;
        errors = errorList;
        checks = checks;
      };

  # Calculate sidecar resource overhead
  calculateSidecarOverhead = cpuRequest: memoryRequest:
    {
      cpuOverhead = cpuRequest;
      memoryOverhead = memoryRequest;
      estimatedLatencyMs = 5;
      estimatedThroughputImpact = "< 5%";
    };

  # Framework metadata
  framework = {
    name = "Nixernetes Service Mesh Integration";
    version = "1.0.0";
    description = "Comprehensive service mesh support for Istio and Linkerd";
    
    features = {
      "istio-support" = "Istio service mesh installation and configuration";
      "linkerd-support" = "Linkerd service mesh installation and configuration";
      "virtual-services" = "Istio VirtualService management";
      "destination-rules" = "Istio DestinationRule management";
      "traffic-policies" = "Circuit breaking, retries, timeouts";
      "authorization-policies" = "Fine-grained access control";
      "peer-authentication" = "Mutual TLS configuration";
      "service-entries" = "External service integration";
      "observability" = "Metrics, tracing, and logging";
      "traffic-management" = "Routing, load balancing, canary deployments";
      "security-policies" = "mTLS, authorization, and authentication";
      "resilience" = "Circuit breaking, retries, bulkheads";
    };
    
    supportedMeshes = ["istio" "linkerd"];
    supportedIstioVersions = ["1.16" "1.17" "1.18" "1.19"];
    supportedLinkerdVersions = ["2.13" "2.14" "2.15"];
    supportedTracingProviders = ["jaeger" "zipkin" "datadog"];
    supportedDashboards = ["kiali" "grafana" "linkerd-viz"];
    
    kubernetesVersions = ["1.24" "1.25" "1.26" "1.27" "1.28" "1.29"];
  };
}
