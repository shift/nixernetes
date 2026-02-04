{ lib }:
let
  secretsManagement = import ../lib/secrets-management.nix { inherit lib; };
in
{
  # Example 1: Basic Sealed Secrets
  basicSealedSecrets = secretsManagement.mkSealedSecrets "basic" {
    namespace = "sealed-secrets";
    replicas = 1;
  };

  # Example 2: Production Sealed Secrets with Key Rotation
  productionSealedSecrets = secretsManagement.mkSealedSecrets "production" {
    namespace = "sealed-secrets";
    replicas = 2;
    keys = {
      rotation = true;
      rotationPeriod = "30d";
      encryptionAlgorithm = "aes-gcm-256";
    };
    sealing = {
      scope = "strict";
      allowEmptyData = false;
      allowNamespaceChange = false;
    };
    resources = {
      limits = { cpu = "500m"; memory = "512Mi"; };
      requests = { cpu = "100m"; memory = "256Mi"; };
    };
    labels = {
      "app" = "sealed-secrets";
      "environment" = "production";
    };
  };

  # Example 3: External Secrets with AWS Secrets Manager
  externalSecretsAws = secretsManagement.mkExternalSecrets "aws-integration" {
    namespace = "external-secrets-system";
    replicas = 2;
    backend = {
      type = "aws-secrets-manager";
      region = "us-west-2";
      auth = {
        secretRef = "aws-credentials";
      };
    };
    sync = {
      interval = "15m";
      retryInterval = "1m";
      retryAttempts = 5;
    };
    externalSecret = {
      refreshInterval = "15m";
    };
  };

  # Example 4: External Secrets with Google Secret Manager
  externalSecretsGcp = secretsManagement.mkExternalSecrets "gcp-integration" {
    namespace = "external-secrets-system";
    replicas = 2;
    backend = {
      type = "gcpsm";
      region = "us-central1";
    };
    sync = {
      interval = "10m";
      retryInterval = "30s";
      retryAttempts = 3;
    };
  };

  # Example 5: Basic HashiCorp Vault
  basicVault = secretsManagement.mkVaultSecrets "dev" {
    namespace = "vault";
    replicas = 1;
    server = {
      dataStorage = "5Gi";
    };
    ha.enabled = false;
  };

  # Example 6: Production HashiCorp Vault HA with Raft Storage
  productionVaultRaft = secretsManagement.mkVaultSecrets "production" {
    namespace = "vault";
    replicas = 3;
    version = "1.15";
    server = {
      enabled = true;
      dataStorage = "50Gi";
      logLevel = "info";
    };
    storage = {
      type = "raft";
      raft = {
        path = "/vault/data";
        performanceMultiplier = 8;
      };
    };
    ha = {
      enabled = true;
      replicas = 3;
    };
    auth = {
      kubernetes = true;
      jwt = true;
      ldap = false;
      oidc = false;
    };
    tls = {
      enabled = true;
      certSecret = "vault-tls";
      tlsMinVersion = "1.3";
    };
    ui = {
      enabled = true;
      serviceType = "ClusterIP";
    };
    resources = {
      limits = { cpu = "2000m"; memory = "2048Mi"; };
      requests = { cpu = "1000m"; memory = "1024Mi"; };
    };
  };

  # Example 7: HashiCorp Vault with PostgreSQL Storage
  vaultPostgresql = secretsManagement.mkVaultSecrets "postgresql-backed" {
    namespace = "vault";
    replicas = 3;
    storage = {
      type = "postgresql";
      postgresql = {
        enabled = true;
        connString = "postgres://vault:password@postgres.default.svc:5432/vault";
      };
    };
    ha.enabled = true;
  };

  # Example 8: Vault with AWS KMS Sealing
  vaultAwsKms = secretsManagement.mkVaultSecrets "aws-sealed" {
    namespace = "vault";
    replicas = 3;
    seal = {
      type = "awskms";
      aws = {
        enabled = true;
        kmsKeyId = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012";
      };
    };
    ha.enabled = true;
  };

  # Example 9: AWS Secrets Manager Configuration
  awsSecretsManager = secretsManagement.mkAwsSecretsManager "api-key" {
    aws = {
      region = "us-east-1";
      roleArn = "arn:aws:iam::123456789012:role/vault-role";
    };
    secret = {
      name = "api-key";
      description = "Production API Key";
      secretType = "SecureString";
      kmsKeyId = "alias/aws/secretsmanager";
    };
    rotation = {
      enabled = true;
      rotationDays = 30;
      rotationLambda = "rotate-api-key";
    };
    backup = {
      enabled = true;
      replicaRegion = "us-west-2";
    };
  };

  # Example 10: Secret Rotation Policy
  secretRotationPolicy = secretsManagement.mkSecretRotationPolicy "database-rotation" {
    schedule = "0 0 * * 0";
    rotationDays = 30;
    secrets = [
      "prod-db-password"
      "prod-api-key"
      "prod-tls-cert"
    ];
    method = "automated";
    notifications = {
      enabled = true;
      email = [ "ops@example.com" ];
      slack = "https://hooks.slack.com/services/...";
    };
  };

  # Example 11: Secret Backup Policy
  secretBackupPolicy = secretsManagement.mkSecretBackupPolicy "daily-backup" {
    schedule = "0 2 * * *";
    retentionDays = 30;
    destination = {
      type = "s3";
      bucket = "backup-secrets";
      region = "us-east-1";
    };
    encryption = {
      enabled = true;
      kmsKeyId = "arn:aws:kms:us-east-1:123456789012:key/12345678";
    };
  };

  # Example 12: Aggressive Backup Policy
  aggressiveBackupPolicy = secretsManagement.mkSecretBackupPolicy "hourly-backup" {
    schedule = "0 * * * *";
    retentionDays = 90;
    destination = {
      type = "s3";
      bucket = "secure-backups";
      region = "eu-west-1";
    };
    encryption = {
      enabled = true;
      kmsKeyId = "alias/secure-backup-key";
    };
  };

  # Example 13: Secret Access Control Policy
  secretAccessPolicy = secretsManagement.mkSecretAccessPolicy "app-access" {
    subject = {
      kind = "ServiceAccount";
      name = "my-application";
    };
    secrets = [
      "database-password"
      "api-key"
      "tls-certificate"
    ];
    permissions = [ "get" "list" ];
    timeBasedAccess = {
      enabled = false;
    };
    ipWhitelist = [];
  };

  # Example 14: Time-Restricted Secret Access
  restrictedAccessPolicy = secretsManagement.mkSecretAccessPolicy "restricted-access" {
    subject = {
      kind = "ServiceAccount";
      name = "batch-job";
    };
    secrets = [ "job-api-key" ];
    permissions = [ "get" ];
    timeBasedAccess = {
      enabled = true;
      startTime = "2024-02-01T00:00:00Z";
      endTime = "2024-12-31T23:59:59Z";
    };
    ipWhitelist = [
      "10.0.0.0/8"
      "192.168.1.0/24"
    ];
  };

  # Example 15: Secret Encryption Configuration
  secretEncryption = secretsManagement.mkSecretEncryption "default-encryption" {
    provider = "aes-gcm";
    keyManagement = {
      keyId = "primary-key";
      provider = "local";
    };
    resources = [ "secrets" ];
    atRest = {
      enabled = true;
      algorithm = "AES-256-GCM";
    };
    inTransit = {
      enabled = true;
      tlsVersion = "1.3";
    };
  };

  # Example 16: Vault-Based Key Management
  vaultKeyManagement = secretsManagement.mkSecretEncryption "vault-encryption" {
    provider = "aes-gcm";
    keyManagement = {
      keyId = "vault-transit-engine";
      provider = "vault";
    };
    resources = [ "secrets" "configmaps" ];
    atRest = {
      enabled = true;
      algorithm = "AES-256-GCM";
    };
    inTransit = {
      enabled = true;
      tlsVersion = "1.3";
    };
  };

  # Example 17: Sealed Secret Resource
  sealedSecretResource = secretsManagement.mkSealedSecret "database-credentials" {
    namespace = "production";
    encryptedData = {
      username = "AgB3xK9...";
      password = "AgBk7M2...";
    };
    scope = "strict";
    labels = {
      "app" = "myapp";
      "secret-type" = "database";
    };
  };

  # Example 18: External Secret Resource
  externalSecretResource = secretsManagement.mkExternalSecret "aws-secrets" {
    secretStore = {
      name = "aws-secret-store";
      kind = "SecretStore";
    };
    refreshInterval = "15m";
    data = [
      {
        secretKey = "username";
        remoteRef = { key = "prod/database/username"; };
      }
      {
        secretKey = "password";
        remoteRef = { key = "prod/database/password"; };
      }
    ];
    target = {
      name = "database-credentials";
      creationPolicy = "Owner";
    };
  };

  # Test result object
  testResult = {
    expected = true;
    message = "All Secrets Management examples created successfully";
    examplesCount = 18;
    frameworks = [ "sealed-secrets" "external-secrets" "vault" "aws-secrets-manager" ];
    policyTypes = [
      "secret-rotation"
      "secret-backup"
      "secret-access"
      "secret-encryption"
    ];
    features = [
      "encryption-at-rest"
      "encryption-in-transit"
      "key-rotation"
      "access-control"
      "audit-logging"
      "backup-recovery"
      "multi-backend-support"
      "ha-configuration"
    ];
  };
}
