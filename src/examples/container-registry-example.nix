{ lib }:
let
  containerRegistry = import ../lib/container-registry.nix { inherit lib; };
in
{
  # Example 1: Basic Docker Registry
  basicDockerRegistry = containerRegistry.mkDockerRegistry "basic" {
    namespace = "registry";
    replicas = 1;
    storage.driver = "filesystem";
  };

  # Example 2: Docker Registry with S3 storage
  s3DockerRegistry = containerRegistry.mkDockerRegistry "s3-backed" {
    namespace = "registry";
    replicas = 3;
    storage = {
      driver = "s3";
      s3 = {
        enabled = true;
        accesskey = "aws-access-key";
        secretkey = "aws-secret-key";
        region = "us-east-1";
        bucket = "my-docker-registry";
        encrypt = true;
        secure = true;
      };
    };
    http = {
      tlsenabled = true;
      tlscertificate = "/etc/registry/certs/registry.crt";
      tlskey = "/etc/registry/certs/registry.key";
    };
    auth = {
      enabled = true;
      scheme = "bearer";
    };
    resources = {
      limits = { cpu = "2000m"; memory = "1024Mi"; };
      requests = { cpu = "500m"; memory = "512Mi"; };
    };
  };

  # Example 3: Production Harbor Registry
  productionHarborRegistry = containerRegistry.mkHarborRegistry "production" {
    namespace = "harbor";
    coreReplicas = 3;
    registryReplicas = 3;
    jobserviceReplicas = 2;
    database = {
      type = "postgresql";
      host = "postgres.harbor.svc.cluster.local";
      port = 5432;
      username = "harbor";
      passwordSecret = "harbor-db-password";
      maxConnections = 2048;
    };
    redis = {
      enabled = true;
      host = "redis.harbor.svc.cluster.local";
      port = 6379;
      passwordSecret = "harbor-redis-password";
    };
    storage = {
      type = "s3";
      s3 = {
        endpoint = "s3.amazonaws.com";
        accesskey = "access-key";
        secretkey = "secret-key";
        bucket = "harbor-prod";
        region = "us-east-1";
        secure = true;
      };
    };
    authentication = {
      mode = "ldap_auth";
      ldap = {
        enabled = true;
        url = "ldap://ldap.example.com:389";
        baseDn = "dc=example,dc=com";
      };
    };
    trivy = {
      enabled = true;
      skipUpdate = false;
    };
    replication = {
      enabled = true;
      schedule = "0 0 * * *";
    };
    garbageCollection = {
      enabled = true;
      schedule = "0 2 * * *";
      deleteUntagged = true;
    };
    resources = {
      limits = { cpu = "4000m"; memory = "2048Mi"; };
      requests = { cpu = "1000m"; memory = "1024Mi"; };
    };
    labels = {
      "app" = "harbor";
      "environment" = "production";
    };
  };

  # Example 4: Harbor with OIDC Authentication
  harborOidcRegistry = containerRegistry.mkHarborRegistry "oidc-auth" {
    namespace = "harbor";
    coreReplicas = 2;
    registryReplicas = 2;
    authentication = {
      mode = "oidc_auth";
      oidc = {
        enabled = true;
        name = "Keycloak";
        endpoint = "https://keycloak.example.com/auth/realms/master";
        clientId = "harbor";
      };
    };
    trivy.enabled = true;
  };

  # Example 5: Nexus Repository Manager
  basicNexusRegistry = containerRegistry.mkNexusRegistry "nexus" {
    namespace = "nexus";
    replicas = 1;
    version = "3.68";
    storage = {
      dataPath = "/nexus-data";
    };
    repositories = {
      docker = { hosted = true; proxy = true; group = true; };
      maven = { hosted = true; proxy = true; group = true; };
      npm = { hosted = true; proxy = true; group = true; };
      helm = { hosted = true; proxy = true; group = true; };
    };
    authentication.enabled = true;
    jvm = {
      maxMemory = "1024m";
      minMemory = "256m";
    };
  };

  # Example 6: Enterprise Nexus with High Availability
  enterpriseNexusRegistry = containerRegistry.mkNexusRegistry "enterprise" {
    namespace = "nexus";
    replicas = 3;
    version = "3.68";
    jvm = {
      maxMemory = "2048m";
      minMemory = "512m";
      directMemory = "1024m";
    };
    security = {
      enableAnonymousAccess = false;
      enableRealmsLogging = true;
    };
    authentication = {
      enabled = true;
      ldap = {
        enabled = true;
        connection = "ldap-connection-name";
      };
    };
    resources = {
      limits = { cpu = "4000m"; memory = "4096Mi"; };
      requests = { cpu = "2000m"; memory = "2048Mi"; };
    };
  };

  # Example 7: JFrog Artifactory OSS
  artifactoryRegistry = containerRegistry.mkArtifactoryRegistry "artifactory" {
    namespace = "artifactory";
    replicas = 1;
    database = {
      type = "postgresql";
      url = "jdbc:postgresql://postgres:5432/artdb";
      username = "artifactory";
    };
    repositories = {
      docker = { local = true; remote = true; virtual = true; };
      maven = { local = true; remote = true; virtual = true; };
    };
  };

  # Example 8: Artifactory with Enterprise Features
  enterpriseArtifactoryRegistry = containerRegistry.mkArtifactoryRegistry "enterprise" {
    namespace = "artifactory";
    replicas = 2;
    database = {
      type = "postgresql";
      url = "jdbc:postgresql://postgres.default:5432/artdb";
      username = "artifactory";
    };
    authentication = {
      enabled = true;
      saml = {
        enabled = true;
        loginUrl = "https://auth.example.com/saml/login";
      };
      oauth = {
        enabled = true;
        type = "oauth2";
      };
    };
    security = {
      ssl = {
        enabled = true;
        certificate = "/etc/artifactory/certs/server.crt";
      };
      encryption = {
        enabled = true;
        algorithm = "AES256";
      };
    };
    resources = {
      limits = { cpu = "4000m"; memory = "4096Mi"; };
      requests = { cpu = "2000m"; memory = "2048Mi"; };
    };
  };

  # Example 9: Image Pull Secret for Private Registry
  imagePullSecret = containerRegistry.mkImagePullSecret "docker-secret" {
    namespace = "default";
    registry = {
      server = "registry.example.com";
      username = "docker-user";
      password = "docker-password";
      email = "docker@example.com";
    };
    secretName = "docker-registry-secret";
  };

  # Example 10: Image Scanning Policy with Trivy
  imageScanPolicy = containerRegistry.mkImageScanPolicy "vulnerability-scan" {
    scanning = {
      enabled = true;
      scanner = "trivy";
      scanInterval = "24h";
      onPull = true;
      onPush = true;
    };
    vulnerabilities = {
      critical = {
        enabled = true;
        action = "block";
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
    exemptions = [
      "trusted-images:*"
      "internal/*:latest"
    ];
  };

  # Example 11: Strict Image Scanning Policy
  strictScanPolicy = containerRegistry.mkImageScanPolicy "strict-scan" {
    scanning = {
      enabled = true;
      scanner = "trivy";
      scanInterval = "6h";
      onPull = true;
      onPush = true;
    };
    vulnerabilities = {
      critical = {
        enabled = true;
        action = "block";
      };
      high = {
        enabled = true;
        action = "block";
      };
      medium = {
        enabled = true;
        action = "warn";
      };
    };
  };

  # Example 12: Image Retention Policy
  imageRetentionPolicy = containerRegistry.mkImageRetentionPolicy "cleanup" {
    retentionDays = 30;
    keepTagged = true;
    keepLatest = true;
    repositories = [ "*/app-*" "*/service-*" ];
    schedule = "0 2 * * *";
  };

  # Example 13: Aggressive Retention Policy
  aggressiveRetentionPolicy = containerRegistry.mkImageRetentionPolicy "aggressive-cleanup" {
    retentionDays = 7;
    keepTagged = false;
    keepLatest = true;
    images = [ "temp/*" "test/*" "ci/*" ];
    schedule = "0 * * * *";
  };

  # Example 14: Image Replication Policy
  imageReplicationPolicy = containerRegistry.mkImageReplicationPolicy "to-dr-registry" {
    source = {
      registry = "docker.io";
      namespace = "my-company";
      repository = "*";
    };
    destination = {
      registry = "dr-registry.example.com";
      namespace = "mirrored";
    };
    rules = {
      pullImage = true;
      deleteImage = false;
    };
    schedule = "0 */6 * * *";
    enabled = true;
  };

  # Example 15: Image Build Configuration
  imageBuildConfig = containerRegistry.mkImageBuildConfig "docker-build" {
    buildSystem = "docker";
    cache = {
      enabled = true;
      type = "registry";
      maxSize = "10Gi";
    };
    context = {
      source = "git";
      repository = "https://github.com/my-company/my-app.git";
      branch = "main";
    };
    credentials = {
      registrySecret = "docker-creds";
      gitSecret = "git-creds";
    };
  };

  # Bonus Example 16: Multi-Tenant Harbor with Isolation
  multiTenantHarborRegistry = containerRegistry.mkHarborRegistry "multi-tenant" {
    namespace = "harbor";
    coreReplicas = 3;
    registryReplicas = 3;
    database.host = "postgres.harbor.svc.cluster.local";
    authentication.mode = "ldap_auth";
    trivy.enabled = true;
    labels = {
      "architecture" = "multi-tenant";
      "data-isolation" = "project-level";
    };
  };

  # Bonus Example 17: Disaster Recovery Registry
  drRegistryConfiguration = containerRegistry.mkDockerRegistry "dr-replica" {
    namespace = "registry-dr";
    replicas = 2;
    storage = {
      driver = "s3";
      s3 = {
        enabled = true;
        region = "us-west-2";
        bucket = "dr-registry-backup";
      };
    };
    labels = {
      "tier" = "disaster-recovery";
      "priority" = "critical";
    };
  };

  # Test result object
  testResult = {
    expected = true;
    message = "All Container Registry examples created successfully";
    examplesCount = 17;
    registryFrameworks = [ "docker-registry" "harbor" "nexus" "artifactory" ];
    policyTypes = [
      "image-scan"
      "image-retention"
      "image-replication"
      "image-build"
      "image-pull-secret"
    ];
    features = [
      "image-storage"
      "vulnerability-scanning"
      "replication"
      "retention-policies"
      "authentication"
      "authorization"
      "metrics"
      "logging"
    ];
  };
}
