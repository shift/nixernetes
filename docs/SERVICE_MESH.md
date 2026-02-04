# Nixernetes Service Mesh Integration Module

## Overview

The Service Mesh Integration module provides comprehensive support for deploying and managing service meshes in Kubernetes clusters. It supports both Istio and Linkerd, enabling secure, observable, and resilient service-to-service communication with traffic management, security policies, and advanced observability.

## Key Features

- **Multi-Mesh Support**: Istio and Linkerd integration
- **Traffic Management**: Routing, load balancing, canary deployments
- **Security Policies**: mTLS, authorization, peer authentication
- **Resilience Patterns**: Circuit breaking, retries, timeouts, bulkheads
- **Observability**: Metrics, tracing, logging, service topology
- **External Services**: ServiceEntry integration for external workloads
- **Advanced Features**: Rate limiting, virtual services, destination rules
- **Auto-Injection**: Automatic sidecar proxy injection
- **Monitoring**: Built-in dashboards and observability tools

## Builders

### mkIstioMesh

Create an Istio service mesh configuration.

```nix
mkIstioMesh "production" {
  namespace = "istio-system";
  version = "1.17.0";
  
  installMode = "demo";
  profile = "default";
  
  enableIngressGateway = true;
  enableEgressGateway = true;
  enableIstiod = true;
  
  enableMtls = true;
  mtlsMode = "STRICT";
  enableAuthorizationPolicy = true;
  
  enableTracing = true;
  tracingProvider = "jaeger";
  enableKiali = true;
  
  enableRateLimiting = true;
  enableCircuitBreaking = true;
  
  enableSidecarInjection = true;
  sidecarInjectionNamespaces = ["default" "production"];
}
```

**Parameters**:
- `namespace`: Istio system namespace (default: `"istio-system"`)
- `version`: Istio version (default: `"1.17.0"`)
- `installMode`: `"demo"`, `"production"`, or `"minimal"`
- `profile`: Configuration profile
- `enableIngressGateway`: Enable ingress gateway
- `enableEgressGateway`: Enable egress gateway
- `enableIstiod`: Enable control plane
- `enableMtls`: Enable mutual TLS
- `mtlsMode`: `"PERMISSIVE"` or `"STRICT"`
- `enableAuthorizationPolicy`: Enable authorization policies
- `enableTracing`: Enable distributed tracing
- `tracingProvider`: `"jaeger"`, `"zipkin"`, or `"datadog"`
- `enableKiali`: Enable Kiali dashboard
- `enablePrometheus`: Enable Prometheus metrics
- `enableRateLimiting`: Enable rate limiting
- `enableCircuitBreaking`: Enable circuit breaking
- `enableSidecarInjection`: Enable automatic injection
- `sidecarInjectionNamespaces`: Namespaces for auto-injection

### mkLinkerdMesh

Create a Linkerd service mesh configuration.

```nix
mkLinkerdMesh "production" {
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
  
  enableTracing = true;
  tracingCollector = "jaeger";
  
  enableHA = true;
  replicas = 3;
  
  enableAutoInject = true;
  excludeNamespaces = ["kube-system" "kube-public"];
}
```

**Parameters**:
- `namespace`: Linkerd namespace (default: `"linkerd"`)
- `version`: Linkerd version (default: `"2.14.0"`)
- `installMode`: `"stable"` or `"edge"`
- `enableControlPlane`: Install control plane
- `enableDataPlane`: Install data plane proxies
- `enableViz`: Enable visualization UI
- `enableJaeger`: Enable Jaeger tracing
- `enableMtls`: Enable mutual TLS
- `mtlsRotationDays`: Certificate rotation period
- `enablePolicy`: Enable policy engine
- `enableTracing`: Enable tracing
- `enableHA`: Enable high availability
- `replicas`: Number of replicas for HA
- `enableAutoInject`: Enable auto-injection
- `excludeNamespaces`: Namespaces to exclude from injection

### mkVirtualService

Create Istio VirtualService for traffic routing.

```nix
mkVirtualService "web-service" {
  namespace = "production";
  hosts = ["web" "web.svc.cluster.local"];
  
  httpRoutes = [
    {
      match = [{ uri = { prefix = "/v2"; }; }];
      route = [
        {
          destination = {
            host = "web";
            subset = "v2";
            port = { number = 8080; };
          };
          weight = 10;
        }
        {
          destination = {
            host = "web";
            subset = "v1";
            port = { number = 8080; };
          };
          weight = 90;
        }
      ];
      timeout = "30s";
      retries = { attempts = 3; perTryTimeout = "10s"; };
    }
  ];
  
  timeout = "30s";
}
```

**Parameters**:
- `namespace`: Kubernetes namespace
- `hosts`: VirtualService hosts
- `httpRoutes`: HTTP routing rules
- `tcpRoutes`: TCP routing rules
- `timeout`: Request timeout
- `retries`: Retry configuration
- `exportTo`: Export to other namespaces

### mkDestinationRule

Create Istio DestinationRule for load balancing and circuit breaking.

```nix
mkDestinationRule "web-service" {
  namespace = "production";
  host = "web";
  
  trafficPolicy = {
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
  
  subsets = [
    {
      name = "v1";
      labels = { version = "v1"; };
    }
    {
      name = "v2";
      labels = { version = "v2"; };
    }
  ];
}
```

**Parameters**:
- `namespace`: Kubernetes namespace
- `host`: Destination host
- `trafficPolicy`: Load balancing and circuit breaking
- `subsets`: Destination subsets for traffic splitting
- `exportTo`: Export to other namespaces

### mkTrafficPolicy

Define traffic resilience policies.

```nix
mkTrafficPolicy "default-policy" {
  circuitBreaker = {
    enabled = true;
    consecutiveErrors = 5;
    interval = "30s";
    baseEjectionTime = "30s";
    maxEjectionPercent = 50;
  };
  
  retries = {
    enabled = true;
    attempts = 3;
    perTryTimeout = "10s";
    retryOn = "5xx,reset,connect-failure";
  };
  
  timeout = "30s";
  
  connectionPool = {
    tcp = { maxConnections = 100; };
    http = { http1MaxPendingRequests = 100; };
  };
  
  loadBalancer = "ROUND_ROBIN";
}
```

**Parameters**:
- `circuitBreaker`: Circuit breaking configuration
- `retries`: Retry policy
- `timeout`: Request timeout
- `connectionPool`: Connection pooling limits
- `loadBalancer`: Load balancing algorithm
- `rateLimiting`: Rate limiting configuration

### mkAuthorizationPolicy

Create Istio authorization policies for access control.

```nix
mkAuthorizationPolicy "allow-traffic" {
  namespace = "production";
  action = "ALLOW";
  
  selector = { "app" = "web"; };
  
  rules = [
    {
      from = [
        { source = { principals = ["cluster.local/ns/production/sa/frontend"]; }; }
      ];
      to = [
        { operation = { methods = ["GET" "POST"]; }; }
      ];
    }
  ];
}
```

**Parameters**:
- `namespace`: Kubernetes namespace
- `action`: `"ALLOW"` or `"DENY"`
- `rules`: Authorization rules
- `selector`: Pod selector
- `provider`: Custom provider

### mkPeerAuthentication

Create Istio PeerAuthentication for mTLS configuration.

```nix
mkPeerAuthentication "default-mtls" {
  namespace = "production";
  mtlsMode = "STRICT";
  
  selector = { "app" = "web"; };
  
  portLevelMtls = {
    "8443" = { mode = "STRICT"; };
    "8080" = { mode = "PERMISSIVE"; };
  };
}
```

**Parameters**:
- `namespace`: Kubernetes namespace
- `mtlsMode`: `"UNSET"`, `"DISABLE"`, `"PERMISSIVE"`, or `"STRICT"`
- `selector`: Pod selector
- `portLevelMtls`: Per-port mTLS settings

### mkServiceEntry

Create ServiceEntry for external services.

```nix
mkServiceEntry "external-api" {
  namespace = "production";
  
  hosts = ["api.example.com"];
  
  location = "MESH_EXTERNAL";
  
  ports = [
    { name = "https"; number = 443; protocol = "HTTPS"; }
  ];
  
  resolution = "DNS";
  
  subjectAltNames = ["api.example.com"];
}
```

**Parameters**:
- `namespace`: Kubernetes namespace
- `hosts`: External service hosts
- `location`: `"MESH_INTERNAL"` or `"MESH_EXTERNAL"`
- `ports`: Service ports
- `resolution`: `"NONE"`, `"STATIC"`, or `"DNS"`
- `endpoints`: Endpoint configuration
- `subjectAltNames`: SANs for TLS

### mkObservabilityConfig

Configure mesh observability.

```nix
mkObservabilityConfig "production" {
  metricsEnabled = true;
  prometheusEnabled = true;
  prometheusPort = 9090;
  
  tracingEnabled = true;
  tracingProvider = "jaeger";
  tracingCollectorAddress = "jaeger-collector:14268";
  tracingSamplingRate = 0.01;
  
  accessLogEnabled = true;
  accessLogFormat = "default";
  logLevel = "info";
  
  dashboardEnabled = true;
  dashboardProvider = "kiali";
  dashboardPort = 20001;
  
  topologyEnabled = true;
}
```

**Parameters**:
- `metricsEnabled`: Enable metrics collection
- `prometheusEnabled`: Enable Prometheus
- `tracingEnabled`: Enable distributed tracing
- `tracingProvider`: Tracing backend
- `tracingSamplingRate`: Sampling rate (0-1)
- `accessLogEnabled`: Enable access logging
- `dashboardEnabled`: Enable UI dashboards
- `topologyEnabled`: Enable service topology

### mkMeshConfig

Create mesh-wide configuration.

```nix
mkMeshConfig "production" {
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
}
```

**Parameters**:
- `meshType`: `"istio"` or `"linkerd"`
- `protocolDetectionEnabled`: Enable protocol detection
- `serviceDiscoveryType`: Discovery method
- `defaultCircuitBreakerPolicy`: Default circuit breaker
- `defaultRetryPolicy`: Default retry policy
- `defaultTimeout`: Default timeout
- `defaultMtlsPolicy`: Default mTLS mode

## Validation Functions

### validateServiceMesh

Validates service mesh configuration.

```nix
let
  result = validateServiceMesh mesh;
in
  if result.valid then "OK" else builtins.concatStringsSep ", " result.errors
```

Returns object with:
- `valid`: Boolean indicating validity
- `errors`: List of error messages
- `checks`: Detailed validation checks

## Helper Functions

### calculateSidecarOverhead

Calculate resource overhead of service mesh sidecars.

```nix
let
  overhead = calculateSidecarOverhead "100m" "256Mi";
in
  "CPU: ${overhead.cpuOverhead}, Memory: ${overhead.memoryOverhead}"
```

## Framework Metadata

The framework object provides metadata about the module:

```nix
{
  name = "Nixernetes Service Mesh Integration";
  version = "1.0.0";
  
  features = {
    istio-support = "...";
    linkerd-support = "...";
    traffic-management = "...";
    security-policies = "...";
    observability = "...";
  };
  
  supportedMeshes = ["istio" "linkerd"];
  supportedIstioVersions = ["1.16" "1.17" "1.18" "1.19"];
  supportedLinkerdVersions = ["2.13" "2.14" "2.15"];
  supportedTracingProviders = ["jaeger" "zipkin" "datadog"];
}
```

## Integration Examples

### Istio with Strict mTLS

```nix
let
  mesh = mkIstioMesh "prod" {
    version = "1.17.0";
    mtlsMode = "STRICT";
    enableKiali = true;
    tracingProvider = "jaeger";
  };
  
  authPolicy = mkAuthorizationPolicy "default" {
    namespace = "production";
    action = "ALLOW";
  };
in
  { inherit mesh authPolicy; }
```

### Linkerd with High Availability

```nix
let
  mesh = mkLinkerdMesh "prod" {
    version = "2.14.0";
    enableHA = true;
    replicas = 3;
    enableViz = true;
    enableJaeger = true;
  };
in
  mesh
```

### Canary Deployment with Traffic Splitting

```nix
let
  vs = mkVirtualService "app" {
    namespace = "production";
    hosts = ["app"];
    
    httpRoutes = [{
      match = [{ uri = { prefix = "/"; }; }];
      route = [
        {
          destination = {
            host = "app";
            subset = "v1";
          };
          weight = 90;
        }
        {
          destination = {
            host = "app";
            subset = "v2";
          };
          weight = 10;
        }
      ];
    }];
  };
  
  dr = mkDestinationRule "app" {
    namespace = "production";
    host = "app";
    subsets = [
      { name = "v1"; labels = { version = "v1"; }; }
      { name = "v2"; labels = { version = "v2"; }; }
    ];
  };
in
  { inherit vs dr; }
```

### Circuit Breaking and Resilience

```nix
let
  policy = mkTrafficPolicy "resilient" {
    circuitBreaker = {
      consecutiveErrors = 5;
      interval = "30s";
      baseEjectionTime = "30s";
    };
    
    retries = {
      attempts = 3;
      perTryTimeout = "10s";
      retryOn = "5xx,reset,connect-failure";
    };
    
    timeout = "30s";
  };
in
  policy
```

## Best Practices

### Mesh Selection

1. **Istio** for advanced traffic management and security
2. **Linkerd** for lightweight, high-performance deployments
3. Consider operational complexity vs. feature richness

### mTLS Configuration

1. Start with `PERMISSIVE` mode during migration
2. Enforce `STRICT` mode in production
3. Monitor certificate expiration
4. Automate certificate rotation

### Traffic Management

1. Use VirtualServices for HTTP traffic
2. Define DestinationRules for load balancing
3. Implement circuit breaking for resilience
4. Set reasonable timeout values
5. Configure retry policies

### Security

1. Implement authorization policies by default
2. Use least privilege principles
3. Enable API audit logging
4. Rotate credentials regularly
5. Monitor policy violations

### Observability

1. Enable distributed tracing
2. Collect metrics from all services
3. Set up alerting on key metrics
4. Create dashboards for visibility
5. Review traces and metrics regularly

### Performance

1. Monitor sidecar resource usage
2. Optimize sampling rates for tracing
3. Use namespace-level policies
4. Consider rate limiting carefully
5. Profile impact on latency

## Performance Considerations

- Istio sidecars: 100m CPU, 256Mi memory minimum
- Linkerd proxies: 10m CPU, 32Mi memory minimum
- Traffic inspection adds 1-5% latency
- Distributed tracing has < 1% overhead with sampling
- mTLS has minimal overhead (~1-2%)
- Circuit breaking prevents cascading failures

## Supported Kubernetes Versions

- 1.24+
- 1.25+
- 1.26+
- 1.27+
- 1.28+
- 1.29+

## Deployment Checklist

- [ ] Service mesh selected (Istio or Linkerd)
- [ ] Resource quotas planned
- [ ] mTLS mode configured
- [ ] Authorization policies defined
- [ ] Observability stack prepared
- [ ] Distributed tracing configured
- [ ] Service discovery verified
- [ ] Ingress gateway configured
- [ ] Monitoring dashboards created
- [ ] Runbooks prepared
- [ ] Team training completed
- [ ] Rollback procedures documented
