# Container Registry Module Documentation

## Overview

The **Container Registry module** provides comprehensive configuration and deployment management for enterprise container image registries and artifact repositories. It supports multiple popular registry implementations including Docker Registry, Harbor, Nexus Repository Manager, and JFrog Artifactory.

This module enables organizations to:
- Deploy and manage container image registries with a unified interface
- Implement vulnerability scanning and security policies
- Configure image replication and synchronization across registries
- Manage image retention and cleanup policies
- Implement role-based access control and authentication
- Monitor and observe registry activity and performance
- Integrate with Kubernetes for seamless image pulling

## Key Features

### Multi-Registry Support
- **Docker Registry**: Simple, open-source V2 registry implementation
- **Harbor**: Enterprise-grade registry with scanning, replication, and governance
- **Nexus Repository Manager**: Universal artifact management platform
- **JFrog Artifactory**: Enterprise repository with multi-format support

### Image Management
- Image storage and retrieval with optimized caching
- Image tagging and versioning
- Layer deduplication for efficient storage
- Multi-architecture image support

### Security
- Vulnerability scanning with Trivy integration
- Image signing and verification
- Role-based access control (RBAC)
- Network policies and firewall rules
- Encryption at rest and in transit

### Replication & Synchronization
- Multi-registry replication policies
- Scheduled synchronization
- Cross-cloud image mirroring
- Bandwidth-efficient updates

### Observability
- Comprehensive logging and auditing
- Metrics collection and monitoring
- Image pull/push statistics
- Registry health monitoring

## Builder Functions

### mkDockerRegistry

Creates a Docker Registry V2 configuration for simple, lightweight image storage.

**Signature:**
```nix
mkDockerRegistry = name: config: { ... }
```

**Parameters:**
- `name` (string): Registry name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "registry";                   # Registry name
  version = "2.8";                     # Registry version
  namespace = "registry";              # Deployment namespace
  replicas = 1;                        # Number of replicas
  image = "registry:2.8";              # Container image
  
  storage = {
    driver = "filesystem";             # Storage backend
    filesystem = {
      rootdirectory = "/var/lib/registry";
      maxthreads = 100;
    };
    s3 = {
      enabled = false;                 # Enable S3 backend
      accesskey = "";
      secretkey = "";
      region = "us-east-1";
      bucket = "registry";
      encrypt = true;
      secure = true;
    };
  };
  
  http = {
    addr = ":5000";                    # Listen address
    net = "tcp";
    tlsenabled = false;                # Enable TLS
    tlscertificate = "";
    tlskey = "";
  };
  
  auth = {
    enabled = true;                    # Enable authentication
    scheme = "bearer";
    token = {
      realm = "https://auth.docker.io/v2/token";
      service = "registry";
      issuer = "registry-token-issuer";
      rootcertbundle = "/etc/registry/root.crt";
    };
  };
  
  middleware = {
    storage = [];                      # Storage middleware
    registry = [];                     # Registry middleware
  };
  
  log = {
    level = "info";
    format = "json";
  };
  
  notifications = { };                 # Webhook notifications
  
  resources = {
    limits = { cpu = "1000m"; memory = "512Mi"; };
    requests = { cpu = "100m"; memory = "256Mi"; };
  };
  
  labels = { };                        # Custom labels
  annotations = { };                   # Custom annotations
}
```

**Returns:**
Configuration object with framework metadata and auto-applied labels.

**Example:**
```nix
mkDockerRegistry "local" {
  storage.driver = "s3";
  storage.s3 = {
    enabled = true;
    bucket = "my-registry";
  };
}
```

### mkHarborRegistry

Creates a Harbor enterprise registry configuration with advanced features.

**Signature:**
```nix
mkHarborRegistry = name: config: { ... }
```

**Parameters:**
- `name` (string): Registry name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "harbor";                     # Registry name
  version = "2.10";                    # Harbor version
  namespace = "harbor";                # Deployment namespace
  coreReplicas = 1;                    # Core service replicas
  jobserviceReplicas = 1;              # Job service replicas
  registryReplicas = 1;                # Registry service replicas
  
  database = {
    type = "postgresql";               # Database type
    host = "harbor-postgresql.harbor.svc.cluster.local";
    port = 5432;
    username = "postgres";
    passwordSecret = "harbor-db-password";
    maxConnections = 1024;
  };
  
  redis = {
    enabled = true;                    # Enable Redis cache
    host = "harbor-redis.harbor.svc.cluster.local";
    port = 6379;
    db = 0;
    passwordSecret = "harbor-redis-password";
  };
  
  storage = {
    type = "s3";                       # Storage backend type
    s3 = {
      endpoint = "";
      accesskey = "";
      secretkey = "";
      bucket = "harbor";
      region = "us-east-1";
      secure = true;
    };
    azure = {
      accountname = "";
      accountkey = "";
      container = "harbor";
    };
  };
  
  core = {
    tokenExpiration = 30;              # Token expiration (days)
    jobServiceTokenExpiration = 30;
  };
  
  authentication = {
    mode = "db_auth";                  # Authentication mode
    ldap = {
      enabled = false;
      url = "";
      baseDn = "";
    };
    oidc = {
      enabled = false;
      name = "OIDC";
      endpoint = "";
      clientId = "";
    };
  };
  
  trivy = {
    enabled = true;                    # Enable Trivy scanning
    image = "goharbor/trivy-adapter-scanner:latest";
    skipUpdate = false;
    insecure = false;
  };
  
  replication = {
    enabled = true;                    # Enable replication
    schedule = "0 0 * * *";            # Cron schedule
  };
  
  garbageCollection = {
    enabled = true;                    # Enable GC
    schedule = "0 2 * * *";
    deleteUntagged = true;
  };
  
  resources = {
    limits = { cpu = "2000m"; memory = "1024Mi"; };
    requests = { cpu = "500m"; memory = "512Mi"; };
  };
  
  labels = { };
  annotations = { };
}
```

**Returns:**
Configuration with Harbor-specific settings and metadata.

**Example:**
```nix
mkHarborRegistry "production" {
  coreReplicas = 3;
  registryReplicas = 3;
  database.host = "postgres.default.svc";
  trivy.enabled = true;
}
```

### mkNexusRegistry

Creates a Nexus Repository Manager configuration for universal artifact management.

**Signature:**
```nix
mkNexusRegistry = name: config: { ... }
```

**Parameters:**
- `name` (string): Registry name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "nexus";                      # Registry name
  version = "3.68";                    # Nexus version
  namespace = "nexus";                 # Deployment namespace
  replicas = 1;                        # Number of replicas
  image = "sonatype/nexus3:3.68";
  
  storage = {
    dataPath = "/nexus-data";
    logPath = "/nexus-data/log";
    tempPath = "/nexus-data/tmp";
    blobstores = [];                   # Custom blobstores
  };
  
  repositories = {
    docker = {
      hosted = true;                   # Hosted repository
      proxy = true;                    # Proxy repository
      group = true;                    # Group repository
    };
    maven = {
      hosted = true;
      proxy = true;
      group = true;
    };
    npm = {
      hosted = true;
      proxy = true;
      group = true;
    };
    helm = {
      hosted = true;
      proxy = true;
      group = true;
    };
  };
  
  authentication = {
    enabled = true;
    realm = "NexusAuthenticatingRealm";
    ldap = {
      enabled = false;
      connection = "";
    };
  };
  
  security = {
    enableAnonymousAccess = false;
    enableRealmsLogging = false;
  };
  
  jvm = {
    maxMemory = "1024m";
    minMemory = "256m";
    directMemory = "512m";
  };
  
  resources = {
    limits = { cpu = "2000m"; memory = "2048Mi"; };
    requests = { cpu = "500m"; memory = "1024Mi"; };
  };
  
  labels = { };
  annotations = { };
}
```

**Returns:**
Configuration with Nexus-specific repository and JVM settings.

**Example:**
```nix
mkNexusRegistry "enterprise" {
  replicas = 2;
  jvm.maxMemory = "2048m";
  repositories.docker.hosted = true;
}
```

### mkArtifactoryRegistry

Creates a JFrog Artifactory configuration for enterprise artifact management.

**Signature:**
```nix
mkArtifactoryRegistry = name: config: { ... }
```

**Parameters:**
- `name` (string): Registry name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "artifactory";
  version = "7.84";
  namespace = "artifactory";
  replicas = 1;
  image = "releases-docker.jfrog.io/jfrog/artifactory-oss:latest";
  
  database = {
    type = "postgresql";
    url = "jdbc:postgresql://postgres:5432/artdb";
    username = "artifactory";
  };
  
  repositories = {
    docker = { local = true; remote = true; virtual = true; };
    maven = { local = true; remote = true; virtual = true; };
    npm = { local = true; remote = true; virtual = true; };
    helm = { local = true; remote = true; virtual = true; };
    generic = { local = true; remote = true; virtual = true; };
  };
  
  authentication = {
    enabled = true;
    saml = {
      enabled = false;
      loginUrl = "";
    };
    oauth = {
      enabled = false;
      type = "oauth2";
    };
  };
  
  security = {
    ssl = {
      enabled = true;
      certificate = "";
    };
    encryption = {
      enabled = true;
      algorithm = "AES256";
    };
  };
  
  resources = {
    limits = { cpu = "2000m"; memory = "2048Mi"; };
    requests = { cpu = "500m"; memory = "1024Mi"; };
  };
  
  labels = { };
  annotations = { };
}
```

### mkImagePullSecret

Creates a Kubernetes image pull secret for private registry access.

**Signature:**
```nix
mkImagePullSecret = name: config: { ... }
```

**Parameters:**
- `name` (string): Secret name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "docker-registry-secret";
  
  registry = {
    server = "docker.io";              # Registry server
    username = "";                     # Registry username
    password = "";                     # Registry password
    email = "";                        # Email address
  };
  
  namespace = "default";               # Target namespace
  secretName = "docker-registry-secret";
}
```

### mkImageScanPolicy

Creates an image vulnerability scanning policy.

**Signature:**
```nix
mkImageScanPolicy = name: config: { ... }
```

**Parameters:**
- `name` (string): Policy name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "image-scan";
  
  scanning = {
    enabled = true;
    scanner = "trivy";                 # Scanner type
    scanInterval = "24h";
    onPull = true;                     # Scan on pull
    onPush = true;                     # Scan on push
  };
  
  vulnerabilities = {
    critical = {
      enabled = true;
      action = "block";                # Block, warn, or allow
    };
    high = {
      enabled = true;
      action = "warn";
    };
    medium = {
      enabled = true;
      action = "allow";
    };
  };
  
  exemptions = [];                     # Exempt images
}
```

### mkImageRetentionPolicy

Creates an image retention and cleanup policy.

**Signature:**
```nix
mkImageRetentionPolicy = name: config: { ... }
```

**Parameters:**
- `name` (string): Policy name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "image-retention";
  
  retentionDays = 30;                  # Keep images for N days
  keepTagged = true;                   # Keep tagged images
  keepLatest = true;                   # Keep latest tag
  
  repositories = [];                   # Target repositories
  images = [];                         # Target images
  
  schedule = "0 2 * * *";              # Cleanup schedule
}
```

### mkImageReplicationPolicy

Creates a multi-registry replication policy.

**Signature:**
```nix
mkImageReplicationPolicy = name: config: { ... }
```

**Parameters:**
- `name` (string): Policy name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "image-replication";
  
  source = {
    registry = "docker.io";            # Source registry
    namespace = "";
    repository = "";
  };
  
  destination = {
    registry = "registry.local";       # Destination registry
    namespace = "";
  };
  
  rules = {
    pullImage = true;                  # Pull images
    deleteImage = false;               # Delete images
  };
  
  schedule = "0 */6 * * *";            # Replication schedule
  enabled = true;
}
```

### mkImageBuildConfig

Creates an image build and caching configuration.

**Signature:**
```nix
mkImageBuildConfig = name: config: { ... }
```

**Parameters:**
- `name` (string): Configuration name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "image-build";
  
  buildSystem = "docker";              # Build system type
  
  cache = {
    enabled = true;
    type = "registry";                 # Cache type
    maxSize = "10Gi";                  # Maximum cache size
  };
  
  context = {
    source = "git";                    # Source type
    repository = "";                   # Git repository
    branch = "main";                   # Git branch
  };
  
  credentials = {
    registrySecret = "";               # Registry secret
    gitSecret = "";                    # Git secret
  };
}
```

## Validation Functions

### validateRegistryConfig

Validates that a registry configuration is properly structured.

**Signature:**
```nix
validateRegistryConfig = config: { valid = bool; errors = [ string ]; }
```

**Returns:**
Object with validation status and error list.

## Helper Functions

### calculateStorageRequirements

Calculates resource requirements for a registry configuration.

**Signature:**
```nix
calculateStorageRequirements = config: { totalCpu = int; totalMemory = int; estimatedThroughput = int; }
```

**Returns:**
Object with CPU, memory, and throughput estimates.

## Integration Examples

### Example 1: Simple Docker Registry

```nix
let
  registry = containerRegistry.mkDockerRegistry "local" {
    namespace = "registry";
    storage.driver = "filesystem";
  };
in
{
  inherit registry;
}
```

### Example 2: Production Harbor Registry

```nix
let
  registry = containerRegistry.mkHarborRegistry "production" {
    coreReplicas = 3;
    registryReplicas = 3;
    database.host = "postgres.default.svc";
    trivy.enabled = true;
  };
in
{
  inherit registry;
}
```

### Example 3: Nexus with Multi-Format Support

```nix
let
  registry = containerRegistry.mkNexusRegistry "enterprise" {
    replicas = 2;
    jvm.maxMemory = "2048m";
  };
in
{
  inherit registry;
}
```

### Example 4: Image Scanning Policy

```nix
let
  scanPolicy = containerRegistry.mkImageScanPolicy "vulnerability-scan" {
    scanning = {
      enabled = true;
      scanner = "trivy";
      onPush = true;
      onPull = true;
    };
    vulnerabilities.critical.action = "block";
  };
in
{
  inherit scanPolicy;
}
```

### Example 5: Image Retention Policy

```nix
let
  retentionPolicy = containerRegistry.mkImageRetentionPolicy "cleanup" {
    retentionDays = 30;
    keepTagged = true;
    keepLatest = true;
    schedule = "0 2 * * *";
  };
in
{
  inherit retentionPolicy;
}
```

## Best Practices

### Registry Selection

1. **Docker Registry**: Choose for:
   - Simple, lightweight deployments
   - Private registry on single node
   - Minimal operational overhead
   - Cost-sensitive environments

2. **Harbor**: Choose for:
   - Enterprise deployments
   - Multi-project governance
   - Image scanning and compliance
   - Replication requirements

3. **Nexus**: Choose for:
   - Multi-format artifact management
   - Maven, npm, helm, docker support
   - Complex repository hierarchies
   - Existing Sonatype ecosystem

4. **Artifactory**: Choose for:
   - Extensive artifact formats
   - Advanced build integration
   - Enterprise support requirements
   - DevOps automation needs

### Configuration Best Practices

- **Storage**: Use object storage (S3, Azure) for scalability
- **Database**: Use managed databases for reliability
- **Replication**: Configure for disaster recovery
- **Scanning**: Enable automatic vulnerability scanning
- **Retention**: Implement cleanup policies to manage costs
- **Authentication**: Use LDAP/OIDC for centralized management
- **Backup**: Schedule regular backups of registry data
- **Monitoring**: Track registry metrics and health

### Security Considerations

- Enable TLS for all registry communication
- Use network policies to restrict access
- Implement RBAC for users and service accounts
- Scan images for vulnerabilities regularly
- Sign images to verify authenticity
- Rotate credentials regularly
- Audit all registry operations
- Encrypt sensitive data at rest

### Performance Tuning

- **Caching**: Enable layer caching for faster pulls
- **Replication**: Schedule during low-traffic periods
- **Garbage Collection**: Configure appropriate schedules
- **Database**: Tune connection pools and indexes
- **Storage**: Choose appropriate backend based on workload
- **Networking**: Use CDN for geo-distributed access

## Kubernetes Version Support

This module supports Kubernetes versions 1.26 through 1.31:
- Full support on all versions
- Image pull secret support on all versions
- RBAC integration on all versions

## Integration with Other Modules

### With RBAC Module
```nix
rbac = rbacModule.mkRBACPolicy "registry-admin" {
  subjects = [{
    kind = "ServiceAccount";
    name = "registry-admin";
  }];
  resources = [ "secrets" "configmaps" ];
};
```

### With Security Scanning
```nix
scanning = securityScanning.mkSecurityScan {
  scanType = "image-scan";
  scanTargets = [ "registry" ];
};
```

### With Cost Analysis
```nix
costAnalysis = costModule.mkCostAllocation {
  registryName = "production";
  costCenter = "platform";
  chargeback = true;
};
```

## Deployment Checklist

Before deploying a registry:

- [ ] Verify registry type is supported
- [ ] Configure storage backend
- [ ] Set up database (if required)
- [ ] Configure authentication
- [ ] Enable image scanning
- [ ] Set retention policies
- [ ] Configure backups
- [ ] Plan scaling strategy
- [ ] Set up monitoring and alerting
- [ ] Test failover procedures
- [ ] Document configuration
- [ ] Schedule maintenance windows

## Troubleshooting

### Registry Not Responding
1. Check pod status: `kubectl get pods -n <namespace>`
2. View logs: `kubectl logs -n <namespace> <pod>`
3. Check service endpoints: `kubectl get svc -n <namespace>`
4. Verify storage access

### Image Pull Failures
1. Check image pull secret: `kubectl get secrets -n <namespace>`
2. Verify registry connectivity
3. Check authentication credentials
4. Review registry logs for errors

### Storage Issues
1. Check disk space: `df -h`
2. Verify storage backend connectivity
3. Check storage configuration
4. Review storage backend logs

## Performance Considerations

- **CPU Usage**: Typically 100-500m per replica
- **Memory Usage**: Typically 256-512Mi per replica
- **Throughput**: Single replica: 100-500 images/day
- **Latency**: Image pull: 2-10s, push: 5-30s
- **Scalability**: Linear scaling with replica count

## API Stability

The Container Registry module maintains backward compatibility for:
- Builder function signatures
- Configuration schema structure
- Validation rules
- Helper function outputs
