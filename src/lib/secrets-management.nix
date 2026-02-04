{ lib }:
let
  inherit (lib) mkOption types;
in
{
  # Sealed Secrets configuration
  mkSealedSecrets = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      framework = "sealed-secrets";
      version = config.version or "0.24";
      namespace = config.namespace or "kube-system";
      replicas = config.replicas or 1;
      image = config.image or "ghcr.io/getsops/sealed-secrets-controller:v0.24";
      
      # Key management
      keys = {
        rotation = config.keys.rotation or false;
        rotationPeriod = config.keys.rotationPeriod or "30d";
        encryptionAlgorithm = config.keys.encryptionAlgorithm or "aes-gcm-256";
      };
      
      # Sealing configuration
      sealing = {
        scope = config.sealing.scope or "strict";
        allowEmptyData = config.sealing.allowEmptyData or false;
        allowNamespaceChange = config.sealing.allowNamespaceChange or false;
        allowNameChange = config.sealing.allowNameName or false;
      };
      
      # Update strategy
      updateStrategy = {
        type = config.updateStrategy.type or "RollingUpdate";
        rollingUpdate = {
          maxUnavailable = config.updateStrategy.rollingUpdate.maxUnavailable or 1;
        };
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
      
      # Logging
      log = {
        level = config.log.level or "info";
        format = config.log.format or "json";
      };
      
      # Labels and annotations
      labels = (config.labels or {}) // { framework = "sealed-secrets"; };
      annotations = (config.annotations or {}) // { "sealedsecrets.bitnami.com/managed" = "true"; };
    };

  # External Secrets configuration
  mkExternalSecrets = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      framework = "external-secrets";
      version = config.version or "0.9";
      namespace = config.namespace or "external-secrets-system";
      replicas = config.replicas or 2;
      image = config.image or "ghcr.io/external-secrets/external-secrets:v0.9";
      
      # Backend storage configuration
      backend = {
        type = config.backend.type or "aws-secrets-manager";
        region = config.backend.region or "us-east-1";
        auth = {
          secretRef = config.backend.auth.secretRef or "aws-credentials";
        };
      };
      
      # Secret store configuration
      secretStore = {
        enabled = config.secretStore.enabled or true;
        kind = config.secretStore.kind or "SecretStore";
        name = config.secretStore.name or "default-secret-store";
      };
      
      # Sync configuration
      sync = {
        interval = config.sync.interval or "15m";
        retryInterval = config.sync.retryInterval or "1m";
        retryAttempts = config.sync.retryAttempts or 5;
      };
      
      # External secret template
      externalSecret = {
        refreshInterval = config.externalSecret.refreshInterval or "15m";
        secretStoreRef = config.externalSecret.secretStoreRef or "default-secret-store";
        target = config.externalSecret.target or {
          name = "external-secret";
          creationPolicy = "Owner";
        };
      };
      
      # Update strategy
      updateStrategy = {
        type = config.updateStrategy.type or "RollingUpdate";
        rollingUpdate = {
          maxUnavailable = config.updateStrategy.rollingUpdate.maxUnavailable or 1;
        };
      };
      
      # Resource limits
      resources = {
        limits = {
          cpu = config.resources.limits.cpu or "500m";
          memory = config.resources.limits.memory or "512Mi";
        };
        requests = {
          cpu = config.resources.requests.cpu or "100m";
          memory = config.resources.requests.memory or "256Mi";
        };
      };
      
      # Logging
      log = {
        level = config.log.level or "info";
        format = config.log.format or "json";
      };
      
      # Labels and annotations
      labels = (config.labels or {}) // { framework = "external-secrets"; };
      annotations = (config.annotations or {}) // { "externalsecrets.io/managed" = "true"; };
    };

  # HashiCorp Vault configuration
  mkVaultSecrets = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      framework = "vault";
      version = config.version or "1.15";
      namespace = config.namespace or "vault";
      replicas = config.replicas or 3;
      image = config.image or "vault:1.15";
      
      # Server configuration
      server = {
        enabled = config.server.enabled or true;
        dataStorage = config.server.dataStorage or "10Gi";
        logLevel = config.server.logLevel or "info";
      };
      
      # Storage backend
      storage = {
        type = config.storage.type or "raft";
        raft = {
          path = config.storage.raft.path or "/vault/data";
          performanceMultiplier = config.storage.raft.performanceMultiplier or 8;
        };
        postgresql = {
          enabled = config.storage.postgresql.enabled or false;
          connString = config.storage.postgresql.connString or "";
        };
      };
      
      # High availability
      ha = {
        enabled = config.ha.enabled or true;
        replicas = config.ha.replicas or 3;
      };
      
      # Authentication methods
      auth = {
        kubernetes = config.auth.kubernetes or true;
        jwt = config.auth.jwt or false;
        ldap = config.auth.ldap or false;
        oidc = config.auth.oidc or false;
      };
      
      # TLS configuration
      tls = {
        enabled = config.tls.enabled or true;
        certSecret = config.tls.certSecret or "vault-tls";
        tlsMinVersion = config.tls.tlsMinVersion or "1.2";
      };
      
      # Seal configuration
      seal = {
        type = config.seal.type or "shamir";
        aws = {
          enabled = config.seal.aws.enabled or false;
          kmsKeyId = config.seal.aws.kmsKeyId or "";
        };
      };
      
      # UI configuration
      ui = {
        enabled = config.ui.enabled or true;
        serviceType = config.ui.serviceType or "ClusterIP";
      };
      
      # Resource limits
      resources = {
        limits = {
          cpu = config.resources.limits.cpu or "1000m";
          memory = config.resources.limits.memory or "1024Mi";
        };
        requests = {
          cpu = config.resources.requests.cpu or "500m";
          memory = config.resources.requests.memory or "512Mi";
        };
      };
      
      # Labels and annotations
      labels = (config.labels or {}) // { framework = "vault"; };
      annotations = (config.annotations or {}) // { "vault.io/managed" = "true"; };
    };

  # AWS Secrets Manager configuration
  mkAwsSecretsManager = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      framework = "aws-secrets-manager";
      
      # AWS configuration
      aws = {
        region = config.aws.region or "us-east-1";
        roleArn = config.aws.roleArn or "";
        externalId = config.aws.externalId or "";
      };
      
      # Secret configuration
      secret = {
        name = config.secret.name or "";
        description = config.secret.description or "";
        secretType = config.secret.secretType or "SecureString";
        kmsKeyId = config.secret.kmsKeyId or "alias/aws/secretsmanager";
      };
      
      # Rotation policy
      rotation = {
        enabled = config.rotation.enabled or false;
        rotationDays = config.rotation.rotationDays or 30;
        rotationLambda = config.rotation.rotationLambda or "";
      };
      
      # Backup configuration
      backup = {
        enabled = config.backup.enabled or false;
        replicaRegion = config.backup.replicaRegion or "";
      };
    };

  # Sealed secret configuration
  mkSealedSecret = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      secretType = "sealed-secret";
      
      # Secret data (encrypted)
      encryptedData = config.encryptedData or {};
      
      # Sealing scope
      scope = config.scope or "strict";
      
      # Namespace
      namespace = config.namespace or "default";
      
      # Labels
      labels = config.labels or {};
    };

  # External secret resource
  mkExternalSecret = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      resourceType = "external-secret";
      
      # Secret store reference
      secretStore = config.secretStore or {
        name = "default";
        kind = "SecretStore";
      };
      
      # Refresh interval
      refreshInterval = config.refreshInterval or "15m";
      
      # Secret data mapping
      data = config.data or [];
      
      # Target secret name
      target = config.target or {
        name = "external-secret";
        creationPolicy = "Owner";
      };
      
      # Template
      template = config.template or {};
    };

  # Secret rotation policy
  mkSecretRotationPolicy = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      policyType = "secret-rotation";
      
      # Rotation schedule
      schedule = config.schedule or "0 0 * * 0";
      rotationDays = config.rotationDays or 30;
      
      # Affected secrets
      secrets = config.secrets or [];
      
      # Rotation method
      method = config.method or "automated";
      
      # Notification configuration
      notifications = {
        enabled = config.notifications.enabled or true;
        email = config.notifications.email or [];
        slack = config.notifications.slack or "";
      };
    };

  # Secret backup policy
  mkSecretBackupPolicy = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      policyType = "secret-backup";
      
      # Backup schedule
      schedule = config.schedule or "0 2 * * *";
      retentionDays = config.retentionDays or 30;
      
      # Backup destination
      destination = {
        type = config.destination.type or "s3";
        bucket = config.destination.bucket or "";
        region = config.destination.region or "us-east-1";
      };
      
      # Encryption
      encryption = {
        enabled = config.encryption.enabled or true;
        kmsKeyId = config.encryption.kmsKeyId or "";
      };
    };

  # Secret access policy
  mkSecretAccessPolicy = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      policyType = "secret-access";
      
      # Subject
      subject = config.subject or {
        kind = "ServiceAccount";
        name = "";
      };
      
      # Resources
      secrets = config.secrets or [];
      
      # Permissions
      permissions = config.permissions or [
        "get"
        "list"
      ];
      
      # Time-based access
      timeBasedAccess = {
        enabled = config.timeBasedAccess.enabled or false;
        startTime = config.timeBasedAccess.startTime or "";
        endTime = config.timeBasedAccess.endTime or "";
      };
      
      # IP whitelist
      ipWhitelist = config.ipWhitelist or [];
    };

  # Secret encryption configuration
  mkSecretEncryption = name: config:
    let
      baseName = if config.name or null != null then config.name else name;
    in
    {
      inherit baseName;
      configType = "secret-encryption";
      
      # Encryption provider
      provider = config.provider or "aes-gcm";
      
      # Key management
      keyManagement = {
        keyId = config.keyManagement.keyId or "";
        provider = config.keyManagement.provider or "local";
      };
      
      # Resources to encrypt
      resources = config.resources or [
        "secrets"
      ];
      
      # At-rest encryption
      atRest = {
        enabled = config.atRest.enabled or true;
        algorithm = config.atRest.algorithm or "AES-256-GCM";
      };
      
      # In-transit encryption
      inTransit = {
        enabled = config.inTransit.enabled or true;
        tlsVersion = config.inTransit.tlsVersion or "1.3";
      };
    };

  # Validation and helper functions
  validateSecretsConfig = config: {
    valid = (config.framework or null) != null;
    errors = if (config.framework or null) == null then ["secrets framework must be specified"] else [];
  };

  calculateSecretsStorageRequirements = config:
    let
      baseMemory = if config.framework == "vault" then 512 else 256;
      replicas = config.replicas or 1;
    in
    {
      totalMemory = baseMemory * replicas;
      estimatedSecretCount = 1000;
      estimatedDataSize = 100;
    };

  # Framework metadata
  framework = {
    name = "secrets-management";
    version = "1.0.0";
    description = "Enterprise secrets management and encryption framework";
    features = {
      sealedSecrets = "Sealed Secrets controller for Kubernetes-native encryption";
      externalSecrets = "External Secrets Operator for multi-backend support";
      vault = "HashiCorp Vault for centralized secrets management";
      awsSecretsManager = "AWS Secrets Manager integration";
      secretRotation = "Automated secret rotation policies";
      secretBackup = "Backup and recovery for secrets";
      secretAccess = "Fine-grained access control policies";
      secretEncryption = "At-rest and in-transit encryption";
    };
    supportedK8sVersions = [ "1.26" "1.27" "1.28" "1.29" "1.30" "1.31" ];
    supportedBackends = [ "aws-secrets-manager" "vault" "google-secret-manager" "azure-keyvault" "kubernetes" ];
    maturity = "stable";
  };
}
