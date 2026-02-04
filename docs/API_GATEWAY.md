# API Gateway Module Documentation

## Overview

The **API Gateway module** provides comprehensive configuration and deployment management for enterprise API gateways and Kubernetes ingress controllers. It supports multiple popular frameworks including Traefik, Kong, Contour, and NGINX, as well as the Kubernetes Gateway API standard.

This module enables organizations to:
- Deploy and manage API gateways with a unified interface
- Configure advanced routing, load balancing, and traffic management
- Implement authentication, authorization, and rate limiting policies
- Monitor and observe gateway traffic and performance
- Enforce security policies at the network edge
- Support multi-cloud and hybrid deployments

## Key Features

### Multi-Gateway Support
- **Traefik**: Modern, dynamic reverse proxy with automatic configuration
- **Kong**: Enterprise API gateway with extensive plugin ecosystem
- **Contour**: Kubernetes-native ingress controller with advanced routing
- **NGINX**: Production-proven, high-performance ingress controller

### Traffic Management
- Advanced routing rules and path-based routing
- Request/response modification with middleware
- Load balancing strategies (Round Robin, Least Connections, etc.)
- Traffic splitting for canary deployments
- Virtual host and domain management

### Security
- Multiple authentication methods (OAuth2, JWT, mTLS, Basic Auth)
- Fine-grained authorization policies
- TLS/SSL certificate management with automatic renewal
- Rate limiting and throttling
- Circuit breaker for fault tolerance

### Observability
- Comprehensive logging (access logs, debug logs)
- Metrics collection (Prometheus integration)
- Distributed tracing support
- Real-time health checks and monitoring
- Performance analytics

### Enterprise Features
- Multi-tenant support with namespace isolation
- Compliance label injection
- Cost tracking and optimization
- GitOps integration
- Backup and disaster recovery

## Builder Functions

### mkTraefik

Creates a Traefik ingress controller configuration.

**Signature:**
```nix
mkTraefik = name: config: { ... }
```

**Parameters:**
- `name` (string): Gateway name (overridden by `config.name`)
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "traefik";                    # Gateway name
  version = "2.10";                    # Traefik version
  namespace = "kube-system";           # Deployment namespace
  replicas = 3;                        # Number of replicas
  image = "traefik:2.10";              # Container image
  
  api = {
    enabled = true;                    # Enable Traefik API
    dashboard = true;                  # Enable web dashboard
    debug = false;                     # Enable debug mode
  };
  
  entrypoints = {                      # Traffic entry points
    web = {
      address = ":80";
      http.redirections.entryPoint = {
        to = "websecure";
        scheme = "https";
      };
    };
    websecure = {
      address = ":443";
      http.tls = { /* TLS config */ };
    };
  };
  
  routers = { };                       # Router definitions
  services = { };                      # Service definitions
  middleware = { };                    # Middleware definitions
  plugins = { };                       # Plugin configurations
  
  tls = {
    enabled = true;
    certResolver = "letsencrypt";
    options = { };
  };
  
  log = {
    level = "INFO";
    format = "json";
  };
  
  accessLog = {
    enabled = true;
    format = "json";
  };
  
  metrics = {
    prometheus = {
      enabled = true;
      addEntryPointsLabels = true;
    };
  };
  
  healthcheck = {
    enabled = true;
    path = "/ping";
    interval = "30s";
  };
  
  resources = {
    limits = {
      cpu = "1000m";
      memory = "512Mi";
    };
    requests = {
      cpu = "100m";
      memory = "256Mi";
    };
  };
  
  labels = { };                        # Custom labels
  annotations = { };                   # Custom annotations
}
```

**Returns:**
Configuration object with framework metadata, all specified options, and auto-applied labels/annotations.

**Example:**
```nix
mkTraefik "main" {
  namespace = "ingress";
  replicas = 5;
  tls = {
    certResolver = "acme";
  };
}
```

### mkKong

Creates a Kong API gateway configuration with full plugin support.

**Signature:**
```nix
mkKong = name: config: { ... }
```

**Parameters:**
- `name` (string): Gateway name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "kong";                       # Gateway name
  version = "3.4";                     # Kong version
  namespace = "kong";                  # Deployment namespace
  replicas = 3;                        # Number of replicas
  image = "kong:3.4";                  # Container image
  
  database = {
    type = "postgres";                 # Database type
    host = "postgres.kong.svc";        # Database host
    port = 5432;                       # Database port
    name = "kong";                     # Database name
    user = "kong";                     # Database user
    ssl = false;                       # Use SSL for DB
  };
  
  admin = {
    enabled = true;                    # Enable Admin API
    port = 8001;                       # Admin port
    ssl = false;                       # Use SSL for Admin
    guiEnabled = true;                 # Enable Manager GUI
  };
  
  proxy = {
    http = {
      enabled = true;
      port = 8000;
    };
    https = {
      enabled = true;
      port = 8443;
      http2Enabled = true;
    };
    grpc = {
      enabled = false;
      port = 8080;
    };
    grpcs = {
      enabled = false;
      port = 8081;
    };
  };
  
  services = { };                      # Service definitions
  routes = { };                        # Route definitions
  plugins = { };                       # Plugins
  
  authentication = {
    oauth2Enabled = true;
    oauthTokenTtl = 3600;
    basicAuthEnabled = true;
    keyAuthEnabled = true;
  };
  
  rateLimiting = {
    enabled = true;
    defaultLimit = 100;
    window = "60s";
  };
  
  logging = {
    enabled = true;
    level = "notice";
    plugins = [ ];
  };
  
  resources = {
    limits = {
      cpu = "1000m";
      memory = "512Mi";
    };
    requests = {
      cpu = "100m";
      memory = "256Mi";
    };
  };
  
  labels = { };                        # Custom labels
  annotations = { };                   # Custom annotations
}
```

**Returns:**
Configuration object with Kong-specific settings and metadata.

**Example:**
```nix
mkKong "enterprise" {
  database = {
    host = "kong-db.postgres.svc";
    name = "kong-prod";
  };
  authentication.oauth2Enabled = true;
}
```

### mkContour

Creates a Contour ingress controller configuration with Envoy proxies.

**Signature:**
```nix
mkContour = name: config: { ... }
```

**Parameters:**
- `name` (string): Gateway name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "contour";                    # Gateway name
  version = "1.28";                    # Contour version
  namespace = "projectcontour";        # Deployment namespace
  replicas = 2;                        # Contour replicas
  image = "ghcr.io/projectcontour/contour:v1.28";
  
  envoy = {
    image = "docker.io/envoyproxy/envoy:v1.28";
    replicas = 2;                      # Envoy replicas
    logLevel = "info";
    http = {
      port = 80;
      address = "0.0.0.0";
    };
    https = {
      port = 443;
      address = "0.0.0.0";
    };
  };
  
  ingress = {
    classname = "contour";
    defaultBackend = { };
  };
  
  tls = {
    enabled = true;
    minimumProtocolVersion = "1.2";
    cipherSuites = [ ];
  };
  
  healthChecks = {
    enabled = true;
    interval = "10s";
    unhealthyThreshold = 3;
    healthyThreshold = 2;
  };
  
  loadBalancing = {
    strategy = "RoundRobin";
    circuitBreaker = { };
    outlierDetection = { };
  };
  
  virtualHosts = { };                  # Virtual host configs
  httpRoutes = { };                    # HTTP route configs
  
  metrics = {
    enabled = true;
    port = 8000;
  };
  
  debug = false;                       # Enable debug mode
  
  resources = {
    limits = {
      cpu = "500m";
      memory = "256Mi";
    };
    requests = {
      cpu = "100m";
      memory = "128Mi";
    };
  };
  
  labels = { };                        # Custom labels
  annotations = { };                   # Custom annotations
}
```

**Returns:**
Configuration with Contour and Envoy proxy setup.

**Example:**
```nix
mkContour "edge" {
  envoy.replicas = 5;
  loadBalancing.strategy = "LeastRequest";
}
```

### mkNginx

Creates an NGINX ingress controller configuration.

**Signature:**
```nix
mkNginx = name: config: { ... }
```

**Parameters:**
- `name` (string): Gateway name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "nginx";                      # Gateway name
  version = "1.9";                     # NGINX version
  namespace = "ingress-nginx";         # Deployment namespace
  replicas = 2;                        # Number of replicas
  image = "registry.k8s.io/ingress-nginx/controller:v1.9";
  
  controller = {
    logLevel = 2;                      # Log level (0-5)
    metrics = {
      enabled = true;
      port = 10254;
    };
    updateStrategy = "RollingUpdate";
  };
  
  ingressClass = {
    name = "nginx";
    isDefault = true;
    controller = "k8s.io/ingress-nginx";
  };
  
  configMap = {
    enabled = true;
    httpSnippets = "";                 # HTTP config snippets
    serverSnippets = "";               # Server config snippets
    locationSnippets = "";             # Location config snippets
  };
  
  defaultBackend = { };                # Default backend service
  
  https = {
    enabled = true;
    defaultCertificate = { };          # Default TLS certificate
  };
  
  tcpServices = { };                   # TCP service mapping
  udpServices = { };                   # UDP service mapping
  
  rateLimiting = {
    enabled = true;
    zone = "10m";
  };
  
  modsecurity = {
    enabled = false;
    securityRulesSet = "owasp";
  };
  
  resources = {
    limits = {
      cpu = "200m";
      memory = "256Mi";
    };
    requests = {
      cpu = "100m";
      memory = "128Mi";
    };
  };
  
  labels = { };                        # Custom labels
  annotations = { };                   # Custom annotations
}
```

**Returns:**
Configuration object with NGINX controller setup.

**Example:**
```nix
mkNginx "standard" {
  replicas = 3;
  modsecurity.enabled = true;
}
```

### mkGateway

Creates a Kubernetes Gateway API configuration for standard gateway definitions.

**Signature:**
```nix
mkGateway = name: config: { ... }
```

**Parameters:**
- `name` (string): Gateway name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "api-gateway";                # Gateway name
  type = "ingress";                    # Gateway type
  apiVersion = "gateway.networking.k8s.io/v1";
  kind = "Gateway";
  
  gatewayClassName = "standard";       # Gateway class
  listeners = [ ];                     # Listener definitions
  addresses = [ ];                     # Published addresses
}
```

### mkRateLimitPolicy

Creates a rate limiting policy for gateway routes.

**Signature:**
```nix
mkRateLimitPolicy = name: config: { ... }
```

**Parameters:**
- `name` (string): Policy name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "api-rate-limit";
  
  limits = {
    requests = 100;                    # Requests per window
    window = "1m";                     # Time window
    burst = 10;                        # Burst allowance
  };
  
  keyExtractor = {
    type = "clientIP";                 # Extraction method
  };
  
  actions = {
    type = "reject";
    statusCode = 429;
  };
}
```

### mkCircuitBreaker

Creates a circuit breaker policy for fault tolerance.

**Signature:**
```nix
mkCircuitBreaker = name: config: { ... }
```

**Parameters:**
- `name` (string): Policy name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "circuit-breaker";
  
  consecutiveErrors = 5;               # Error threshold
  errorPercentageThreshold = 50;       # Percentage threshold
  detectionWindow = "30s";             # Detection time
  
  recoveryTimeout = "60s";             # Recovery wait time
  halfOpenRequests = 3;                # Requests in half-open
  
  actions = {
    type = "reject";
    statusCode = 503;
  };
}
```

### mkLoadBalancer

Creates a load balancer configuration with advanced policies.

**Signature:**
```nix
mkLoadBalancer = name: config: { ... }
```

**Parameters:**
- `name` (string): Configuration name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "lb-config";
  
  strategy = "RoundRobin";             # Strategy type
  
  stickySessions = {
    enabled = false;
    cookieName = "lb";
    ttl = "3600s";
  };
  
  healthCheck = {
    enabled = true;
    interval = "10s";
    timeout = "5s";
    healthyThreshold = 2;
    unhealthyThreshold = 3;
  };
  
  backends = [ ];                      # Backend pool
}
```

### mkAuthPolicy

Creates an authentication policy with multiple methods.

**Signature:**
```nix
mkAuthPolicy = name: config: { ... }
```

**Parameters:**
- `name` (string): Policy name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "auth-policy";
  
  methods = {
    basicAuth = false;
    oauth2 = false;
    jwt = false;
    mtls = false;
  };
  
  oauth2 = {
    enabled = false;
    clientId = "";
    clientSecret = "";
    discoveryUrl = "";
  };
  
  jwt = {
    enabled = false;
    issuer = "";
    jwksUri = "";
    audience = "";
  };
  
  mtls = {
    enabled = false;
    caSecret = "";
  };
}
```

## Validation Functions

### validateGatewayConfig

Validates that a gateway configuration is properly structured.

**Signature:**
```nix
validateGatewayConfig = config: { valid = bool; errors = [ string ]; }
```

**Returns:**
Object with:
- `valid` (bool): Whether configuration is valid
- `errors` (list): List of validation errors

## Helper Functions

### calculateGatewaySize

Calculates resource requirements for a gateway configuration.

**Signature:**
```nix
calculateGatewaySize = config: { totalCpu = int; totalMemory = int; estimatedThroughput = int; }
```

**Returns:**
Object with:
- `totalCpu` (int): Total CPU allocation in millicores
- `totalMemory` (int): Total memory allocation in megabytes
- `estimatedThroughput` (int): Estimated requests per second

## Integration Examples

### Example 1: Basic Traefik Setup

```nix
let
  gateway = apiGateway.mkTraefik "main" {
    namespace = "ingress";
    replicas = 3;
    version = "2.10";
  };
in
{
  inherit gateway;
}
```

### Example 2: Production Kong Deployment

```nix
let
  gateway = apiGateway.mkKong "production" {
    database = {
      host = "kong-db.postgres.svc.cluster.local";
      port = 5432;
      name = "kong-prod";
    };
    authentication = {
      oauth2Enabled = true;
      jwtEnabled = true;
    };
    rateLimiting = {
      enabled = true;
      defaultLimit = 1000;
    };
  };
in
{
  inherit gateway;
}
```

### Example 3: NGINX with ModSecurity

```nix
let
  gateway = apiGateway.mkNginx "secure" {
    replicas = 5;
    modsecurity = {
      enabled = true;
      securityRulesSet = "owasp";
    };
    https.enabled = true;
  };
in
{
  inherit gateway;
}
```

### Example 4: Contour with Custom Routing

```nix
let
  gateway = apiGateway.mkContour "edge" {
    envoy.replicas = 3;
    loadBalancing = {
      strategy = "LeastRequest";
      circuitBreaker = {
        maxConnections = 1000;
        maxPendingRequests = 100;
      };
    };
  };
in
{
  inherit gateway;
}
```

### Example 5: Rate Limiting Policy

```nix
let
  rateLimitPolicy = apiGateway.mkRateLimitPolicy "api-rate-limit" {
    limits = {
      requests = 100;
      window = "1m";
      burst = 20;
    };
    keyExtractor = { type = "clientIP"; };
    actions = {
      type = "reject";
      statusCode = 429;
    };
  };
in
{
  inherit rateLimitPolicy;
}
```

## Best Practices

### Gateway Selection

1. **Traefik**: Choose for:
   - Dynamic configuration from Kubernetes annotations
   - Simpler deployments with fewer customization needs
   - Rapid iteration and frequent configuration changes
   - Docker/Kubernetes-native workloads

2. **Kong**: Choose for:
   - Enterprise API gateway requirements
   - Extensive plugin ecosystem needs
   - Complex routing and traffic policies
   - Multi-tenant API management

3. **Contour**: Choose for:
   - Kubernetes-native deployments
   - Advanced traffic splitting and routing
   - Integration with Envoy proxy ecosystem
   - Multi-cluster scenarios

4. **NGINX**: Choose for:
   - Proven production stability
   - Familiar NGINX configuration
   - High-performance requirements
   - Cost-optimized deployments

### Configuration Best Practices

- **Resource Allocation**: Set requests based on expected traffic patterns
- **Health Checks**: Configure aggressive health checks for production
- **TLS**: Always enable TLS in production environments
- **Metrics**: Enable Prometheus metrics for observability
- **Logging**: Configure structured logging for debugging
- **Rate Limiting**: Implement rate limiting to prevent abuse
- **Circuit Breaking**: Enable circuit breakers for fault tolerance
- **Authentication**: Require authentication on all sensitive routes

### Security Considerations

- Enable mTLS between gateway and backends
- Use network policies to restrict traffic
- Implement WAF rules (ModSecurity for NGINX)
- Rotate certificates regularly
- Monitor authentication failures
- Implement DDoS protection
- Use rate limiting strategically
- Audit all gateway traffic

### Performance Tuning

- Adjust replica count based on traffic patterns
- Enable connection pooling
- Configure appropriate timeouts
- Use sticky sessions for stateful services
- Implement compression for responses
- Cache responses where appropriate
- Monitor latency metrics

## Kubernetes Version Support

This module supports Kubernetes versions 1.26 through 1.31:
- Full support for all features on 1.28+
- Limited Gateway API support on 1.26-1.27
- Deprecation warnings for features removed in 1.31+

## Integration with Other Modules

### With RBAC Module
```nix
rbac = rbacModule.mkRBACPolicy "gateway-admin" {
  subjects = [{
    kind = "ServiceAccount";
    name = "traefik";
  }];
  resources = [ "ingresses" "services" ];
};
```

### With Compliance Module
```nix
compliance = complianceModule.mkComplianceLabel {
  framework = "SOC2";
  owner = "platform-team";
  dataClassification = "internal";
};
```

### With Cost Analysis Module
```nix
costAnalysis = costModule.mkCostAllocation {
  gatewayName = "production";
  costCenter = "platform";
  chargeback = true;
};
```

### With Monitoring
```nix
monitoring = {
  prometheus = {
    enabled = true;
    scrapeInterval = "30s";
  };
  alerts = [ /* alert rules */ ];
};
```

## Deployment Checklist

Before deploying a gateway configuration:

- [ ] Verify gateway type is supported in your cluster
- [ ] Confirm namespace exists or will be created
- [ ] Review resource limits and requests
- [ ] Test TLS certificate configuration
- [ ] Validate authentication policy configuration
- [ ] Configure health checks appropriately
- [ ] Plan rollout strategy (canary, blue-green)
- [ ] Set up monitoring and alerting
- [ ] Document configuration decisions
- [ ] Perform load testing
- [ ] Test failover scenarios
- [ ] Plan backup and recovery procedures

## Troubleshooting

### Gateway Not Responding
1. Check pod status: `kubectl get pods -n <namespace>`
2. View logs: `kubectl logs -n <namespace> <pod>`
3. Check service endpoints: `kubectl get endpoints -n <namespace>`
4. Verify ingress configuration: `kubectl get ingress -A`

### High Latency
1. Check replica count and load distribution
2. Review circuit breaker settings
3. Check backend health
4. Monitor resource utilization
5. Review timeout configurations

### Authentication Failures
1. Verify OAuth2/JWT configuration
2. Check certificate validity
3. Review authentication policy rules
4. Check error logs for details
5. Validate key/credential distribution

### Certificate Errors
1. Verify certificate exists and is valid
2. Check TLS configuration
3. Review certificate renewal process
4. Check certificate expiration dates
5. Verify SNI configuration

## Performance Considerations

- **CPU Usage**: Typically 100-500m per replica depending on traffic
- **Memory Usage**: Typically 256-512Mi per replica
- **Throughput**: Single replica can handle 5-10k requests/second
- **Latency**: Added latency typically 1-5ms per request
- **Scalability**: Linear scaling with replica count up to 10+ replicas

For high-traffic deployments (>100k req/s), consider:
- Horizontal pod autoscaling
- Multiple gateway replicas across nodes
- Backend connection pooling
- Response caching
- Traffic shaping and rate limiting

## API Stability

The API Gateway module maintains backward compatibility for:
- Builder function signatures
- Configuration schema structure
- Validation rules
- Helper function outputs

Breaking changes will be announced in release notes and documented in migration guides.
