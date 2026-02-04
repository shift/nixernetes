{ lib }:
let
  inherit (lib) mkOption types;
in
{
  # Traefik ingress controller configuration
  mkTraefik = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      framework = "traefik";
      version = config.version or "2.10";
      namespace = config.namespace or "kube-system";
      replicas = config.replicas or 3;
      image = config.image or "traefik:2.10";
      
      # Core configuration
      api = {
        enabled = config.api.enabled or true;
        dashboard = config.api.dashboard or true;
        debug = config.api.debug or false;
      };
      
      # Entrypoints for traffic ingestion
      entrypoints = config.entrypoints or {
        web = {
          address = ":80";
          http = { redirections = { entryPoint = { to = "websecure"; scheme = "https"; }; }; };
        };
        websecure = {
          address = ":443";
          http = { tls = config.tls or {}; };
        };
      };
      
      # Router configuration
      routers = config.routers or {};
      
      # Service configuration
      services = config.services or {};
      
      # Middleware configuration
      middleware = config.middleware or {};
      
      # Plugins
      plugins = config.plugins or {};
      
      # TLS configuration
      tls = {
        enabled = config.tls.enabled or true;
        certResolver = config.tls.certResolver or "letsencrypt";
        options = config.tls.options or {};
      };
      
      # Logging
      log = {
        level = config.log.level or "INFO";
        format = config.log.format or "json";
      };
      
      # Access log
      accessLog = {
        enabled = config.accessLog.enabled or true;
        format = config.accessLog.format or "json";
      };
      
      # Metrics
      metrics = {
        prometheus = {
          enabled = config.metrics.prometheus.enabled or true;
          addEntryPointsLabels = config.metrics.prometheus.addEntryPointsLabels or true;
        };
      };
      
      # Health check
      healthcheck = {
        enabled = config.healthcheck.enabled or true;
        path = config.healthcheck.path or "/ping";
        interval = config.healthcheck.interval or "30s";
      };
      
      # Resource limits
      resources = {
        limits = {
          cpu = config.resources.limits.cpu or "1000m";
          memory = config.resources.limits.memory or "512Mi";
        };
        requests = {
          cpu = config.resources.requests.cpu or "100m";
          memory = config.resources.requests.memory or "256Mi";
        };
      };
      
      # Labels and annotations
      labels = (config.labels or {}) // { framework = "traefik"; };
      annotations = (config.annotations or {}) // { "traefik.io/managed" = "true"; };
    };

  # Kong API gateway configuration
  mkKong = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      framework = "kong";
      version = config.version or "3.4";
      namespace = config.namespace or "kong";
      replicas = config.replicas or 3;
      image = config.image or "kong:3.4";
      
      # Database configuration
      database = {
        type = config.database.type or "postgres";
        host = config.database.host or "postgres.kong.svc.cluster.local";
        port = config.database.port or 5432;
        name = config.database.name or "kong";
        user = config.database.user or "kong";
        ssl = config.database.ssl or false;
      };
      
      # Admin API configuration
      admin = {
        enabled = config.admin.enabled or true;
        port = config.admin.port or 8001;
        ssl = config.admin.ssl or false;
        guiEnabled = config.admin.guiEnabled or true;
      };
      
      # Proxy configuration
      proxy = {
        http = {
          enabled = config.proxy.http.enabled or true;
          port = config.proxy.http.port or 8000;
        };
        https = {
          enabled = config.proxy.https.enabled or true;
          port = config.proxy.https.port or 8443;
          http2Enabled = config.proxy.https.http2Enabled or true;
        };
        grpc = {
          enabled = config.proxy.grpc.enabled or false;
          port = config.proxy.grpc.port or 8080;
        };
        grpcs = {
          enabled = config.proxy.grpcs.enabled or false;
          port = config.proxy.grpcs.port or 8081;
        };
      };
      
      # Services
      services = config.services or {};
      
      # Routes
      routes = config.routes or {};
      
      # Plugins
      plugins = config.plugins or {};
      
      # Authentication
      authentication = {
        oauth2Enabled = config.authentication.oauth2Enabled or true;
        oauthTokenTtl = config.authentication.oauthTokenTtl or 3600;
        basicAuthEnabled = config.authentication.basicAuthEnabled or true;
        keyAuthEnabled = config.authentication.keyAuthEnabled or true;
      };
      
      # Rate limiting
      rateLimiting = {
        enabled = config.rateLimiting.enabled or true;
        defaultLimit = config.rateLimiting.defaultLimit or 100;
        window = config.rateLimiting.window or "60s";
      };
      
      # Logging
      logging = {
        enabled = config.logging.enabled or true;
        level = config.logging.level or "notice";
        plugins = config.logging.plugins or [];
      };
      
      # Resource limits
      resources = {
        limits = {
          cpu = config.resources.limits.cpu or "1000m";
          memory = config.resources.limits.memory or "512Mi";
        };
        requests = {
          cpu = config.resources.requests.cpu or "100m";
          memory = config.resources.requests.memory or "256Mi";
        };
      };
      
      # Labels and annotations
      labels = (config.labels or {}) // { framework = "kong"; };
      annotations = (config.annotations or {}) // { "kong.io/managed" = "true"; };
    };

  # Contour ingress controller configuration
  mkContour = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      framework = "contour";
      version = config.version or "1.28";
      namespace = config.namespace or "projectcontour";
      replicas = config.replicas or 2;
      image = config.image or "ghcr.io/projectcontour/contour:v1.28";
      
      # Envoy proxy configuration
      envoy = {
        image = config.envoy.image or "docker.io/envoyproxy/envoy:v1.28";
        replicas = config.envoy.replicas or 2;
        logLevel = config.envoy.logLevel or "info";
        http = {
          port = config.envoy.http.port or 80;
          address = config.envoy.http.address or "0.0.0.0";
        };
        https = {
          port = config.envoy.https.port or 443;
          address = config.envoy.https.address or "0.0.0.0";
        };
      };
      
      # Ingress configuration
      ingress = {
        classname = config.ingress.classname or "contour";
        defaultBackend = config.ingress.defaultBackend or {};
      };
      
      # TLS configuration
      tls = {
        enabled = config.tls.enabled or true;
        minimumProtocolVersion = config.tls.minimumProtocolVersion or "1.2";
        cipherSuites = config.tls.cipherSuites or [];
      };
      
      # Health checks
      healthChecks = config.healthChecks or {
        enabled = true;
        interval = "10s";
        unhealthyThreshold = 3;
        healthyThreshold = 2;
      };
      
      # Load balancing policies
      loadBalancing = {
        strategy = config.loadBalancing.strategy or "RoundRobin";
        circuitBreaker = config.loadBalancing.circuitBreaker or {};
        outlierDetection = config.loadBalancing.outlierDetection or {};
      };
      
      # Virtual host configuration
      virtualHosts = config.virtualHosts or {};
      
      # HTTP route configuration
      httpRoutes = config.httpRoutes or {};
      
      # Metrics
      metrics = {
        enabled = config.metrics.enabled or true;
        port = config.metrics.port or 8000;
      };
      
      # Debug mode
      debug = config.debug or false;
      
      # Resource limits
      resources = {
        limits = {
          cpu = config.resources.limits.cpu or "500m";
          memory = config.resources.limits.memory or "256Mi";
        };
        requests = {
          cpu = config.resources.requests.cpu or "100m";
          memory = config.resources.requests.memory or "128Mi";
        };
      };
      
      # Labels and annotations
      labels = (config.labels or {}) // { framework = "contour"; };
      annotations = (config.annotations or {}) // { "contour.io/managed" = "true"; };
    };

  # NGINX ingress controller configuration
  mkNginx = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      framework = "nginx";
      version = config.version or "1.9";
      namespace = config.namespace or "ingress-nginx";
      replicas = config.replicas or 2;
      image = config.image or "registry.k8s.io/ingress-nginx/controller:v1.9";
      
      # Controller configuration
      controller = {
        logLevel = config.controller.logLevel or 2;
        metrics = {
          enabled = config.controller.metrics.enabled or true;
          port = config.controller.metrics.port or 10254;
        };
        updateStrategy = config.controller.updateStrategy or "RollingUpdate";
      };
      
      # Ingress class
      ingressClass = {
        name = config.ingressClass.name or "nginx";
        isDefault = config.ingressClass.isDefault or true;
        controller = "k8s.io/ingress-nginx";
      };
      
      # Configuration snippet
      configMap = {
        enabled = config.configMap.enabled or true;
        httpSnippets = config.configMap.httpSnippets or "";
        serverSnippets = config.configMap.serverSnippets or "";
        locationSnippets = config.configMap.locationSnippets or "";
      };
      
      # Default backend
      defaultBackend = config.defaultBackend or {};
      
      # HTTPS configuration
      https = {
        enabled = config.https.enabled or true;
        defaultCertificate = config.https.defaultCertificate or {};
      };
      
      # TCP services
      tcpServices = config.tcpServices or {};
      
      # UDP services
      udpServices = config.udpServices or {};
      
      # Rate limiting
      rateLimiting = {
        enabled = config.rateLimiting.enabled or true;
        zone = config.rateLimiting.zone or "10m";
      };
      
      # Modsecurity
      modsecurity = {
        enabled = config.modsecurity.enabled or false;
        securityRulesSet = config.modsecurity.securityRulesSet or "owasp";
      };
      
      # Resource limits
      resources = {
        limits = {
          cpu = config.resources.limits.cpu or "200m";
          memory = config.resources.limits.memory or "256Mi";
        };
        requests = {
          cpu = config.resources.requests.cpu or "100m";
          memory = config.resources.requests.memory or "128Mi";
        };
      };
      
      # Labels and annotations
      labels = (config.labels or {}) // { framework = "nginx"; };
      annotations = (config.annotations or {}) // { "nginx.io/managed" = "true"; };
    };

  # Generic gateway configuration
  mkGateway = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
      gatewayType = config.type or "ingress";
    in
    {
      inherit baseName gatewayType;
      apiVersion = config.apiVersion or "gateway.networking.k8s.io/v1";
      kind = config.kind or "Gateway";
      
      # Gateway class reference
      gatewayClassName = config.gatewayClassName or "standard";
      
      # Listeners
      listeners = config.listeners or [];
      
      # Addresses
      addresses = config.addresses or [];
    };

  # Rate limiting policy
  mkRateLimitPolicy = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      policyType = "rateLimit";
      
      # Rate limit configuration
      limits = {
        requests = config.limits.requests or 100;
        window = config.limits.window or "1m";
        burst = config.limits.burst or 10;
      };
      
      # Key extractor
      keyExtractor = config.keyExtractor or {
        type = "clientIP";
      };
      
      # Actions on limit exceeded
      actions = config.actions or {
        type = "reject";
        statusCode = 429;
      };
    };

  # Circuit breaker configuration
  mkCircuitBreaker = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      policyType = "circuitBreaker";
      
      # Thresholds
      consecutiveErrors = config.consecutiveErrors or 5;
      errorPercentageThreshold = config.errorPercentageThreshold or 50;
      detectionWindow = config.detectionWindow or "30s";
      
      # Recovery
      recoveryTimeout = config.recoveryTimeout or "60s";
      halfOpenRequests = config.halfOpenRequests or 3;
      
      # Actions
      actions = config.actions or {
        type = "reject";
        statusCode = 503;
      };
    };

  # Load balancer configuration
  mkLoadBalancer = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      policyType = "loadBalancing";
      
      # Strategy
      strategy = config.strategy or "RoundRobin";
      
      # Sticky sessions
      stickySessions = {
        enabled = config.stickySessions.enabled or false;
        cookieName = config.stickySessions.cookieName or "lb";
        ttl = config.stickySessions.ttl or "3600s";
      };
      
      # Health check configuration
      healthCheck = {
        enabled = config.healthCheck.enabled or true;
        interval = config.healthCheck.interval or "10s";
        timeout = config.healthCheck.timeout or "5s";
        healthyThreshold = config.healthCheck.healthyThreshold or 2;
        unhealthyThreshold = config.healthCheck.unhealthyThreshold or 3;
      };
      
      # Backend pool
      backends = config.backends or [];
    };

  # Authentication policy
  mkAuthPolicy = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      policyType = "authentication";
      
      # Authentication methods
      methods = config.methods or {
        basicAuth = config.methods.basicAuth or false;
        oauth2 = config.methods.oauth2 or false;
        jwt = config.methods.jwt or false;
        mtls = config.methods.mtls or false;
      };
      
      # OAuth2 configuration
      oauth2 = {
        enabled = config.oauth2.enabled or false;
        clientId = config.oauth2.clientId or "";
        clientSecret = config.oauth2.clientSecret or "";
        discoveryUrl = config.oauth2.discoveryUrl or "";
      };
      
      # JWT configuration
      jwt = {
        enabled = config.jwt.enabled or false;
        issuer = config.jwt.issuer or "";
        jwksUri = config.jwt.jwksUri or "";
        audience = config.jwt.audience or "";
      };
      
      # mTLS configuration
      mtls = {
        enabled = config.mtls.enabled or false;
        caSecret = config.mtls.caSecret or "";
      };
    };

  # Validation and helper functions
  validateGatewayConfig = config: {
    valid = (config.framework or null) != null;
    errors = if (config.framework or null) == null then ["gateway framework must be specified"] else [];
  };

  calculateGatewaySize = config:
    let
      replicas = config.replicas or 1;
      cpuStr = config.resources.requests.cpu or "100m";
      memStr = config.resources.requests.memory or "128Mi";
      cpuValue = builtins.toInt (builtins.head (builtins.split "m" cpuStr));
      memValue = builtins.toInt (builtins.head (builtins.split "M" memStr));
    in
    {
      totalCpu = cpuValue * replicas;
      totalMemory = memValue * replicas;
      estimatedThroughput = (replicas * 10000);
    };

  # Framework metadata
  framework = {
    name = "api-gateway";
    version = "1.0.0";
    description = "Enterprise API gateway and ingress controller management";
    features = {
      traefik = "Modern, dynamic reverse proxy and ingress controller";
      kong = "Enterprise API gateway with advanced plugins";
      contour = "Kubernetes-native ingress controller";
      nginx = "Popular production-grade ingress controller";
      gateway = "Kubernetes Gateway API support";
      rateLimiting = "Per-route and global rate limiting policies";
      circuitBreaker = "Fault tolerance with circuit breaker patterns";
      loadBalancing = "Advanced load balancing strategies";
      authentication = "Multiple authentication mechanisms";
    };
    supportedK8sVersions = [ "1.26" "1.27" "1.28" "1.29" "1.30" "1.31" ];
    maturity = "stable";
  };
}
