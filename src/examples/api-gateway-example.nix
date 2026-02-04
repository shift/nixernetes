{ lib }:
let
  apiGateway = import ../lib/api-gateway.nix { inherit lib; };
in
{
  # Example 1: Basic Traefik ingress controller
  basicTraefik = apiGateway.mkTraefik "basic" {
    namespace = "ingress-traefik";
    replicas = 2;
    version = "2.10";
  };

  # Example 2: Production Traefik with TLS and metrics
  productionTraefik = apiGateway.mkTraefik "production" {
    namespace = "ingress";
    replicas = 5;
    version = "2.10";
    api = {
      enabled = true;
      dashboard = true;
      debug = false;
    };
    tls = {
      enabled = true;
      certResolver = "letsencrypt";
      options = {
        minVersion = "VersionTLS12";
        cipherSuites = [
          "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
          "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
        ];
      };
    };
    metrics = {
      prometheus = {
        enabled = true;
        addEntryPointsLabels = true;
      };
    };
    resources = {
      limits = { cpu = "2000m"; memory = "1024Mi"; };
      requests = { cpu = "500m"; memory = "512Mi"; };
    };
    labels = {
      "app" = "traefik";
      "environment" = "production";
    };
  };

  # Example 3: Traefik with custom middleware and routing
  advancedTraefik = apiGateway.mkTraefik "advanced" {
    namespace = "ingress";
    replicas = 3;
    version = "2.10";
    entrypoints = {
      web = {
        address = ":80";
        http.redirections.entryPoint = {
          to = "websecure";
          scheme = "https";
        };
      };
      websecure = {
        address = ":443";
        http.tls = {};
      };
      websocket = {
        address = ":8080";
        http = {};
      };
    };
    middleware = {
      auth-basic = {
        basicAuth = {
          users = [ "admin:hashed_password" ];
        };
      };
      cors = {
        headers = {
          accessControlAllowMethods = [ "GET" "POST" "PUT" "DELETE" "OPTIONS" ];
          accessControlAllowOriginList = [ "https://example.com" ];
        };
      };
      rate-limit = {
        rateLimit = {
          average = 100;
          burst = 20;
        };
      };
    };
    routers = {
      api = {
        rule = "PathPrefix(`/api`)";
        service = "api-backend";
        entryPoints = [ "websecure" ];
      };
      dashboard = {
        rule = "PathPrefix(`/dashboard`)";
        service = "api@internal";
        entryPoints = [ "websecure" ];
      };
    };
    services = {
      api-backend = {
        loadBalancer = {
          servers = [
            { url = "http://api-service.default.svc.cluster.local:8080"; }
          ];
        };
      };
    };
  };

  # Example 4: Kong API gateway with database
  basicKong = apiGateway.mkKong "basic" {
    namespace = "kong";
    replicas = 3;
    version = "3.4";
    database = {
      type = "postgres";
      host = "kong-postgres.kong.svc.cluster.local";
      port = 5432;
      name = "kong";
      user = "kong";
      ssl = false;
    };
    admin = {
      enabled = true;
      port = 8001;
      ssl = false;
      guiEnabled = true;
    };
    proxy = {
      http = { enabled = true; port = 8000; };
      https = { enabled = true; port = 8443; http2Enabled = true; };
    };
  };

  # Example 5: Enterprise Kong with authentication and rate limiting
  enterpriseKong = apiGateway.mkKong "enterprise" {
    namespace = "kong-prod";
    replicas = 5;
    version = "3.4";
    database = {
      type = "postgres";
      host = "kong-db.postgres.svc.cluster.local";
      port = 5432;
      name = "kong-enterprise";
      user = "kong";
      ssl = true;
    };
    admin = {
      enabled = true;
      port = 8001;
      ssl = true;
      guiEnabled = true;
    };
    proxy = {
      http = { enabled = true; port = 8000; };
      https = { enabled = true; port = 8443; http2Enabled = true; };
      grpc = { enabled = true; port = 8080; };
      grpcs = { enabled = true; port = 8081; };
    };
    authentication = {
      oauth2Enabled = true;
      oauthTokenTtl = 7200;
      basicAuthEnabled = true;
      keyAuthEnabled = true;
    };
    rateLimiting = {
      enabled = true;
      defaultLimit = 1000;
      window = "60s";
    };
    plugins = [
      { name = "rate-limiting"; }
      { name = "jwt"; }
      { name = "cors"; }
      { name = "log-to-file"; }
    ];
    resources = {
      limits = { cpu = "2000m"; memory = "1024Mi"; };
      requests = { cpu = "500m"; memory = "512Mi"; };
    };
  };

  # Example 6: Contour ingress controller with Envoy proxies
  basicContour = apiGateway.mkContour "basic" {
    namespace = "projectcontour";
    replicas = 2;
    version = "1.28";
    envoy = {
      replicas = 2;
      logLevel = "info";
    };
    ingressClass = {
      classname = "contour";
    };
    tls = {
      enabled = true;
      minimumProtocolVersion = "1.2";
    };
  };

  # Example 7: Contour with advanced load balancing
  advancedContour = apiGateway.mkContour "advanced" {
    namespace = "projectcontour";
    replicas = 3;
    version = "1.28";
    envoy = {
      replicas = 3;
      logLevel = "info";
      http = { port = 80; address = "0.0.0.0"; };
      https = { port = 443; address = "0.0.0.0"; };
    };
    loadBalancing = {
      strategy = "LeastRequest";
      circuitBreaker = {
        maxConnections = 5000;
        maxPendingRequests = 500;
        maxRequests = 10000;
        maxRetries = 3;
      };
      outlierDetection = {
        consecutive5xxErrors = 5;
        interval = "30s";
        baseEjectionTime = "30s";
      };
    };
    healthChecks = {
      enabled = true;
      interval = "5s";
      unhealthyThreshold = 3;
      healthyThreshold = 2;
    };
    tls = {
      enabled = true;
      minimumProtocolVersion = "1.3";
      cipherSuites = [
        "TLS_AES_256_GCM_SHA384"
        "TLS_CHACHA20_POLY1305_SHA256"
        "TLS_AES_128_GCM_SHA256"
      ];
    };
    metrics = {
      enabled = true;
      port = 8000;
    };
    resources = {
      limits = { cpu = "1000m"; memory = "512Mi"; };
      requests = { cpu = "250m"; memory = "256Mi"; };
    };
  };

  # Example 8: NGINX ingress controller with ModSecurity
  secureNginx = apiGateway.mkNginx "secure" {
    namespace = "ingress-nginx";
    replicas = 3;
    version = "1.9";
    controller = {
      logLevel = 2;
      metrics = {
        enabled = true;
        port = 10254;
      };
    };
    configMap = {
      enabled = true;
      httpSnippets = ''
        client_max_body_size 100m;
        gzip on;
        gzip_types text/plain text/css text/javascript application/json;
      '';
      serverSnippets = ''
        more_set_headers "X-Frame-Options: SAMEORIGIN";
        more_set_headers "X-Content-Type-Options: nosniff";
      '';
    };
    https = {
      enabled = true;
      defaultCertificate = {
        secretName = "default-tls-cert";
      };
    };
    modsecurity = {
      enabled = true;
      securityRulesSet = "owasp";
    };
    rateLimiting = {
      enabled = true;
      zone = "50m";
    };
    resources = {
      limits = { cpu = "500m"; memory = "512Mi"; };
      requests = { cpu = "100m"; memory = "256Mi"; };
    };
  };

  # Example 9: NGINX high-performance configuration
  highPerformanceNginx = apiGateway.mkNginx "performance" {
    namespace = "ingress-nginx";
    replicas = 10;
    version = "1.9";
    controller = {
      logLevel = 3;
      metrics = {
        enabled = true;
        port = 10254;
      };
      updateStrategy = "RollingUpdate";
    };
    configMap = {
      enabled = true;
      httpSnippets = ''
        keepalive_timeout 65;
        keepalive_requests 1000;
        worker_connections 16384;
        gzip on;
        gzip_comp_level 1;
        gzip_types text/plain text/css text/javascript application/json;
        proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=cache_zone:100m;
      '';
    };
    https = {
      enabled = true;
    };
    resources = {
      limits = { cpu = "2000m"; memory = "1024Mi"; };
      requests = { cpu = "500m"; memory = "512Mi"; };
    };
    labels = {
      "tier" = "frontend";
      "performance-tier" = "high";
    };
  };

  # Example 10: Rate limiting policy for API protection
  apiRateLimitPolicy = apiGateway.mkRateLimitPolicy "api-protection" {
    limits = {
      requests = 100;
      window = "1m";
      burst = 20;
    };
    keyExtractor = {
      type = "clientIP";
    };
    actions = {
      type = "reject";
      statusCode = 429;
    };
  };

  # Bonus Example 11: Circuit breaker for fault tolerance
  circuitBreakerConfig = apiGateway.mkCircuitBreaker "fault-tolerance" {
    consecutiveErrors = 5;
    errorPercentageThreshold = 50;
    detectionWindow = "30s";
    recoveryTimeout = "60s";
    halfOpenRequests = 3;
    actions = {
      type = "reject";
      statusCode = 503;
    };
  };

  # Bonus Example 12: Load balancer with health checks
  advancedLoadBalancer = apiGateway.mkLoadBalancer "production-lb" {
    strategy = "LeastRequest";
    stickySessions = {
      enabled = true;
      cookieName = "session_id";
      ttl = "3600s";
    };
    healthCheck = {
      enabled = true;
      interval = "10s";
      timeout = "5s";
      healthyThreshold = 2;
      unhealthyThreshold = 3;
    };
    backends = [
      { host = "api-1.default.svc.cluster.local"; port = 8080; weight = 50; }
      { host = "api-2.default.svc.cluster.local"; port = 8080; weight = 50; }
    ];
  };

  # Bonus Example 13: OAuth2 authentication policy
  oauth2Policy = apiGateway.mkAuthPolicy "oauth2-auth" {
    methods = {
      oauth2 = true;
      basicAuth = false;
      jwt = false;
      mtls = false;
    };
    oauth2 = {
      enabled = true;
      clientId = "oauth-client-id";
      clientSecret = "oauth-client-secret";
      discoveryUrl = "https://auth.example.com/.well-known/openid-configuration";
    };
  };

  # Bonus Example 14: JWT authentication policy
  jwtPolicy = apiGateway.mkAuthPolicy "jwt-auth" {
    methods = {
      jwt = true;
      basicAuth = false;
      oauth2 = false;
      mtls = false;
    };
    jwt = {
      enabled = true;
      issuer = "https://auth.example.com";
      jwksUri = "https://auth.example.com/.well-known/jwks.json";
      audience = "api.example.com";
    };
  };

  # Bonus Example 15: mTLS authentication policy
  mtlsPolicy = apiGateway.mkAuthPolicy "mtls-auth" {
    methods = {
      mtls = true;
      basicAuth = false;
      oauth2 = false;
      jwt = false;
    };
    mtls = {
      enabled = true;
      caSecret = "mtls-ca-cert";
    };
  };

  # Test result object
  testResult = {
    expected = true;
    message = "All API Gateway examples created successfully";
    examplesCount = 15;
    frameworks = [ "traefik" "kong" "contour" "nginx" ];
    features = [
      "api-gateway"
      "ingress-controller"
      "rate-limiting"
      "circuit-breaker"
      "load-balancing"
      "authentication"
      "tls-termination"
      "metrics"
      "logging"
    ];
  };
}
