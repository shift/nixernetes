{ lib }:
let
  inherit (lib) mkOption types;
in
{
  # Docker Registry V2 configuration
  mkDockerRegistry = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      framework = "docker-registry";
      version = config.version or "2.8";
      namespace = config.namespace or "registry";
      replicas = config.replicas or 1;
      image = config.image or "registry:2.8";
      
      # Storage backend configuration
      storage = {
        driver = config.storage.driver or "filesystem";
        filesystem = {
          rootdirectory = config.storage.filesystem.rootdirectory or "/var/lib/registry";
          maxthreads = config.storage.filesystem.maxthreads or 100;
        };
        s3 = {
          enabled = config.storage.s3.enabled or false;
          accesskey = config.storage.s3.accesskey or "";
          secretkey = config.storage.s3.secretkey or "";
          region = config.storage.s3.region or "us-east-1";
          bucket = config.storage.s3.bucket or "registry";
          encrypt = config.storage.s3.encrypt or true;
          secure = config.storage.s3.secure or true;
        };
      };
      
      # HTTP configuration
      http = {
        addr = config.http.addr or ":5000";
        net = config.http.net or "tcp";
        tlsenabled = config.http.tlsenabled or false;
        tlscertificate = config.http.tlscertificate or "";
        tlskey = config.http.tlskey or "";
      };
      
      # Authentication
      auth = {
        enabled = config.auth.enabled or true;
        scheme = config.auth.scheme or "bearer";
        token = {
          realm = config.auth.token.realm or "https://auth.docker.io/v2/token";
          service = config.auth.token.service or "registry";
          issuer = config.auth.token.issuer or "registry-token-issuer";
          rootcertbundle = config.auth.token.rootcertbundle or "/etc/registry/root.crt";
        };
      };
      
      # Storage middleware (caching)
      middleware = {
        storage = config.middleware.storage or [];
        registry = config.middleware.registry or [];
      };
      
      # Logging
      log = {
        level = config.log.level or "info";
        format = config.log.format or "json";
      };
      
      # Notifications
      notifications = config.notifications or {};
      
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
      labels = (config.labels or {}) // { framework = "docker-registry"; };
      annotations = (config.annotations or {}) // { "registry.io/managed" = "true"; };
    };

  # Harbor registry configuration
  mkHarborRegistry = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      framework = "harbor";
      version = config.version or "2.10";
      namespace = config.namespace or "harbor";
      coreReplicas = config.coreReplicas or 1;
      jobserviceReplicas = config.jobserviceReplicas or 1;
      registryReplicas = config.registryReplicas or 1;
      
      # Database configuration
      database = {
        type = config.database.type or "postgresql";
        host = config.database.host or "harbor-postgresql.harbor.svc.cluster.local";
        port = config.database.port or 5432;
        username = config.database.username or "postgres";
        passwordSecret = config.database.passwordSecret or "harbor-db-password";
        maxConnections = config.database.maxConnections or 1024;
      };
      
      # Redis configuration
      redis = {
        enabled = config.redis.enabled or true;
        host = config.redis.host or "harbor-redis.harbor.svc.cluster.local";
        port = config.redis.port or 6379;
        db = config.redis.db or 0;
        passwordSecret = config.redis.passwordSecret or "harbor-redis-password";
      };
      
      # Storage configuration
      storage = {
        type = config.storage.type or "s3";
        s3 = {
          endpoint = config.storage.s3.endpoint or "";
          accesskey = config.storage.s3.accesskey or "";
          secretkey = config.storage.s3.secretkey or "";
          bucket = config.storage.s3.bucket or "harbor";
          region = config.storage.s3.region or "us-east-1";
          secure = config.storage.s3.secure or true;
        };
        azure = {
          accountname = config.storage.azure.accountname or "";
          accountkey = config.storage.azure.accountkey or "";
          container = config.storage.azure.container or "harbor";
        };
      };
      
      # Core API configuration
      core = {
        tokenExpiration = config.core.tokenExpiration or 30;
        jobServiceTokenExpiration = config.core.jobServiceTokenExpiration or 30;
      };
      
      # Authentication
      authentication = {
        mode = config.authentication.mode or "db_auth";
        ldap = {
          enabled = config.authentication.ldap.enabled or false;
          url = config.authentication.ldap.url or "";
          baseDn = config.authentication.ldap.baseDn or "";
        };
        oidc = {
          enabled = config.authentication.oidc.enabled or false;
          name = config.authentication.oidc.name or "OIDC";
          endpoint = config.authentication.oidc.endpoint or "";
          clientId = config.authentication.oidc.clientId or "";
        };
      };
      
      # Security scanning
      trivy = {
        enabled = config.trivy.enabled or true;
        image = config.trivy.image or "goharbor/trivy-adapter-scanner:latest";
        skipUpdate = config.trivy.skipUpdate or false;
        insecure = config.trivy.insecure or false;
      };
      
      # Replication rules
      replication = {
        enabled = config.replication.enabled or true;
        schedule = config.replication.schedule or "0 0 * * *";
      };
      
      # Garbage collection
      garbageCollection = {
        enabled = config.garbageCollection.enabled or true;
        schedule = config.garbageCollection.schedule or "0 2 * * *";
        deleteUntagged = config.garbageCollection.deleteUntagged or true;
      };
      
      # Resource limits
      resources = {
        limits = {
          cpu = config.resources.limits.cpu or "2000m";
          memory = config.resources.limits.memory or "1024Mi";
        };
        requests = {
          cpu = config.resources.requests.cpu or "500m";
          memory = config.resources.requests.memory or "512Mi";
        };
      };
      
      # Labels and annotations
      labels = (config.labels or {}) // { framework = "harbor"; };
      annotations = (config.annotations or {}) // { "harbor.io/managed" = "true"; };
    };

  # Nexus Repository Manager configuration
  mkNexusRegistry = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      framework = "nexus";
      version = config.version or "3.68";
      namespace = config.namespace or "nexus";
      replicas = config.replicas or 1;
      image = config.image or "sonatype/nexus3:3.68";
      
      # Storage configuration
      storage = {
        dataPath = config.storage.dataPath or "/nexus-data";
        logPath = config.storage.logPath or "/nexus-data/log";
        tempPath = config.storage.tempPath or "/nexus-data/tmp";
        blobstores = config.storage.blobstores or [];
      };
      
      # Repository configuration
      repositories = {
        docker = config.repositories.docker or { hosted = true; proxy = true; group = true; };
        maven = config.repositories.maven or { hosted = true; proxy = true; group = true; };
        npm = config.repositories.npm or { hosted = true; proxy = true; group = true; };
        helm = config.repositories.helm or { hosted = true; proxy = true; group = true; };
      };
      
      # Authentication
      authentication = {
        enabled = config.authentication.enabled or true;
        realm = config.authentication.realm or "NexusAuthenticatingRealm";
        ldap = {
          enabled = config.authentication.ldap.enabled or false;
          connection = config.authentication.ldap.connection or "";
        };
      };
      
      # Security
      security = {
        enableAnonymousAccess = config.security.enableAnonymousAccess or false;
        enableRealmsLogging = config.security.enableRealmsLogging or false;
      };
      
      # JVM configuration
      jvm = {
        maxMemory = config.jvm.maxMemory or "1024m";
        minMemory = config.jvm.minMemory or "256m";
        directMemory = config.jvm.directMemory or "512m";
      };
      
      # Resource limits
      resources = {
        limits = {
          cpu = config.resources.limits.cpu or "2000m";
          memory = config.resources.limits.memory or "2048Mi";
        };
        requests = {
          cpu = config.resources.requests.cpu or "500m";
          memory = config.resources.requests.memory or "1024Mi";
        };
      };
      
      # Labels and annotations
      labels = (config.labels or {}) // { framework = "nexus"; };
      annotations = (config.annotations or {}) // { "nexus.io/managed" = "true"; };
    };

  # JFrog Artifactory configuration
  mkArtifactoryRegistry = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      framework = "artifactory";
      version = config.version or "7.84";
      namespace = config.namespace or "artifactory";
      replicas = config.replicas or 1;
      image = config.image or "releases-docker.jfrog.io/jfrog/artifactory-oss:latest";
      
      # Database configuration
      database = {
        type = config.database.type or "postgresql";
        url = config.database.url or "jdbc:postgresql://postgres:5432/artdb";
        username = config.database.username or "artifactory";
      };
      
      # Repository configuration
      repositories = {
        docker = config.repositories.docker or { local = true; remote = true; virtual = true; };
        maven = config.repositories.maven or { local = true; remote = true; virtual = true; };
        npm = config.repositories.npm or { local = true; remote = true; virtual = true; };
        helm = config.repositories.helm or { local = true; remote = true; virtual = true; };
        generic = config.repositories.generic or { local = true; remote = true; virtual = true; };
      };
      
      # Authentication
      authentication = {
        enabled = config.authentication.enabled or true;
        saml = {
          enabled = config.authentication.saml.enabled or false;
          loginUrl = config.authentication.saml.loginUrl or "";
        };
        oauth = {
          enabled = config.authentication.oauth.enabled or false;
          type = config.authentication.oauth.type or "oauth2";
        };
      };
      
      # Security
      security = {
        ssl = {
          enabled = config.security.ssl.enabled or true;
          certificate = config.security.ssl.certificate or "";
        };
        encryption = {
          enabled = config.security.encryption.enabled or true;
          algorithm = config.security.encryption.algorithm or "AES256";
        };
      };
      
      # Resource limits
      resources = {
        limits = {
          cpu = config.resources.limits.cpu or "2000m";
          memory = config.resources.limits.memory or "2048Mi";
        };
        requests = {
          cpu = config.resources.requests.cpu or "500m";
          memory = config.resources.requests.memory or "1024Mi";
        };
      };
      
      # Labels and annotations
      labels = (config.labels or {}) // { framework = "artifactory"; };
      annotations = (config.annotations or {}) // { "artifactory.io/managed" = "true"; };
    };

  # Image pull secret configuration
  mkImagePullSecret = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      secretType = "image-pull";
      
      # Registry credentials
      registry = {
        server = config.registry.server or "docker.io";
        username = config.registry.username or "";
        password = config.registry.password or "";
        email = config.registry.email or "";
      };
      
      # Namespace scope
      namespace = config.namespace or "default";
      
      # Secret reference
      secretName = config.secretName or "docker-registry-secret";
    };

  # Image scanning policy
  mkImageScanPolicy = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      policyType = "image-scan";
      
      # Scanning configuration
      scanning = {
        enabled = config.scanning.enabled or true;
        scanner = config.scanning.scanner or "trivy";
        scanInterval = config.scanning.scanInterval or "24h";
        onPull = config.scanning.onPull or true;
        onPush = config.scanning.onPush or true;
      };
      
      # Vulnerability thresholds
      vulnerabilities = {
        critical = {
          enabled = config.vulnerabilities.critical.enabled or true;
          action = config.vulnerabilities.critical.action or "block";
        };
        high = {
          enabled = config.vulnerabilities.high.enabled or true;
          action = config.vulnerabilities.high.action or "warn";
        };
        medium = {
          enabled = config.vulnerabilities.medium.enabled or true;
          action = config.vulnerabilities.medium.action or "allow";
        };
      };
      
      # Exemptions
      exemptions = config.exemptions or [];
    };

  # Image retention policy
  mkImageRetentionPolicy = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      policyType = "image-retention";
      
      # Retention rules
      retentionDays = config.retentionDays or 30;
      keepTagged = config.keepTagged or true;
      keepLatest = config.keepLatest or true;
      
      # Repository scope
      repositories = config.repositories or [];
      images = config.images or [];
      
      # Cleanup schedule
      schedule = config.schedule or "0 2 * * *";
    };

  # Image replication policy
  mkImageReplicationPolicy = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      policyType = "image-replication";
      
      # Source registry
      source = {
        registry = config.source.registry or "docker.io";
        namespace = config.source.namespace or "";
        repository = config.source.repository or "";
      };
      
      # Destination registry
      destination = {
        registry = config.destination.registry or "registry.local";
        namespace = config.destination.namespace or "";
      };
      
      # Replication rules
      rules = config.rules or {
        pullImage = true;
        deleteImage = false;
      };
      
      # Schedule
      schedule = config.schedule or "0 */6 * * *";
      enabled = config.enabled or true;
    };

  # Image build configuration
  mkImageBuildConfig = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      configType = "image-build";
      
      # Build system
      buildSystem = config.buildSystem or "docker";
      
      # Cache configuration
      cache = {
        enabled = config.cache.enabled or true;
        type = config.cache.type or "registry";
        maxSize = config.cache.maxSize or "10Gi";
      };
      
      # Build context
      context = {
        source = config.context.source or "git";
        repository = config.context.repository or "";
        branch = config.context.branch or "main";
      };
      
      # Credentials
      credentials = {
        registrySecret = config.credentials.registrySecret or "";
        gitSecret = config.credentials.gitSecret or "";
      };
    };

  # Validation and helper functions
  validateRegistryConfig = config: {
    valid = (config.framework or null) != null;
    errors = if (config.framework or null) == null then ["registry framework must be specified"] else [];
  };

  calculateStorageRequirements = config:
    let
      baseCpu = if config.framework == "harbor" then 500 else 100;
      baseMemory = if config.framework == "harbor" then 512 else 256;
      replicas = config.replicas or config.coreReplicas or 1;
    in
    {
      totalCpu = baseCpu * replicas;
      totalMemory = baseMemory * replicas;
      estimatedThroughput = (replicas * 100);
    };

  # Framework metadata
  framework = {
    name = "container-registry";
    version = "1.0.0";
    description = "Enterprise container image registry and artifact management";
    features = {
      dockerRegistry = "Simple Docker Registry V2 implementation";
      harbor = "Enterprise-grade registry with scanning and replication";
      nexus = "Universal artifact repository manager";
      artifactory = "Enterprise artifact repository platform";
      imagePullSecrets = "Kubernetes image pull secret management";
      imageScanning = "Vulnerability scanning and compliance policies";
      imageRetention = "Automated image cleanup and retention";
      imageReplication = "Multi-registry replication and synchronization";
      imageBuild = "Container image build configuration";
    };
    supportedK8sVersions = [ "1.26" "1.27" "1.28" "1.29" "1.30" "1.31" ];
    supportedRegistries = [ "docker" "harbor" "nexus" "artifactory" "quay" "gcr" "ecr" ];
    maturity = "stable";
  };
}
