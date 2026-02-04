# Secrets Management Module Documentation

## Overview

The **Secrets Management module** provides comprehensive configuration and deployment management for enterprise secrets handling, encryption, and access control. It supports multiple popular secrets management solutions including Sealed Secrets, External Secrets, HashiCorp Vault, and AWS Secrets Manager.

This module enables organizations to:
- Encrypt secrets at rest and in transit
- Manage secrets across multiple backends
- Automate secret rotation and lifecycle
- Implement fine-grained access control
- Integrate with Kubernetes for seamless secret injection
- Audit and monitor all secret access
- Backup and recover secrets safely

## Key Features

### Multi-Backend Support
- **Sealed Secrets**: Kubernetes-native encryption with asymmetric cryptography
- **External Secrets**: Unified interface for multiple secret backends
- **HashiCorp Vault**: Centralized, highly available secrets management
- **AWS Secrets Manager**: Cloud-native secrets with AWS integration

### Security
- Encryption at rest with configurable algorithms
- TLS encryption in transit with version control
- Asymmetric cryptography for Sealed Secrets
- Key rotation policies with automation
- Fine-grained RBAC for secret access

### Operations
- Automated secret rotation on schedule
- Backup and disaster recovery
- Multi-region replication
- High availability configurations
- Comprehensive audit logging

### Integration
- Kubernetes native resources
- ServiceAccount-based authentication
- External secret injection
- Multiple secret formats support
- Template-based secret transformation

## Builder Functions

### mkSealedSecrets

Creates a Sealed Secrets controller configuration for Kubernetes-native secret encryption.

**Signature:**
```nix
mkSealedSecrets = name: config: { ... }
```

**Parameters:**
- `name` (string): Controller name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "sealed-secrets";                # Controller name
  version = "0.24";                       # Version
  namespace = "kube-system";              # Deployment namespace
  replicas = 1;                           # Number of replicas
  image = "ghcr.io/getsops/sealed-secrets-controller:v0.24";
  
  keys = {
    rotation = false;                     # Enable key rotation
    rotationPeriod = "30d";               # Rotation period
    encryptionAlgorithm = "aes-gcm-256";  # Encryption algorithm
  };
  
  sealing = {
    scope = "strict";                     # Sealing scope (strict, namespace, name)
    allowEmptyData = false;               # Allow empty data
    allowNamespaceChange = false;         # Allow namespace changes
    allowNameChange = false;              # Allow name changes
  };
  
  updateStrategy = {
    type = "RollingUpdate";
    rollingUpdate = {
      maxUnavailable = 1;
    };
  };
  
  resources = {
    limits = { cpu = "200m"; memory = "256Mi"; };
    requests = { cpu = "100m"; memory = "128Mi"; };
  };
  
  log = {
    level = "info";
    format = "json";
  };
  
  labels = { };                           # Custom labels
  annotations = { };                      # Custom annotations
}
```

**Returns:**
Configuration object with controller metadata and auto-applied labels.

**Example:**
```nix
mkSealedSecrets "primary" {
  namespace = "sealed-secrets";
  keys.rotation = true;
  keys.rotationPeriod = "30d";
}
```

### mkExternalSecrets

Creates an External Secrets Operator configuration for multi-backend secret management.

**Signature:**
```nix
mkExternalSecrets = name: config: { ... }
```

**Parameters:**
- `name` (string): Operator name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "external-secrets";
  version = "0.9";
  namespace = "external-secrets-system";
  replicas = 2;
  image = "ghcr.io/external-secrets/external-secrets:v0.9";
  
  backend = {
    type = "aws-secrets-manager";         # Backend type
    region = "us-east-1";
    auth = {
      secretRef = "aws-credentials";      # Credentials reference
    };
  };
  
  secretStore = {
    enabled = true;
    kind = "SecretStore";
    name = "default-secret-store";
  };
  
  sync = {
    interval = "15m";                     # Sync interval
    retryInterval = "1m";
    retryAttempts = 5;
  };
  
  externalSecret = {
    refreshInterval = "15m";
    secretStoreRef = "default-secret-store";
    target = {
      name = "external-secret";
      creationPolicy = "Owner";
    };
  };
  
  updateStrategy = {
    type = "RollingUpdate";
    rollingUpdate = {
      maxUnavailable = 1;
    };
  };
  
  resources = {
    limits = { cpu = "500m"; memory = "512Mi"; };
    requests = { cpu = "100m"; memory = "256Mi"; };
  };
  
  log = {
    level = "info";
    format = "json";
  };
  
  labels = { };
  annotations = { };
}
```

**Returns:**
Configuration with External Secrets-specific settings.

**Example:**
```nix
mkExternalSecrets "production" {
  replicas = 3;
  backend = {
    type = "aws-secrets-manager";
    region = "us-west-2";
  };
}
```

### mkVaultSecrets

Creates a HashiCorp Vault configuration for centralized secrets management.

**Signature:**
```nix
mkVaultSecrets = name: config: { ... }
```

**Parameters:**
- `name` (string): Vault instance name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "vault";
  version = "1.15";
  namespace = "vault";
  replicas = 3;
  image = "vault:1.15";
  
  server = {
    enabled = true;
    dataStorage = "10Gi";
    logLevel = "info";
  };
  
  storage = {
    type = "raft";                        # Storage backend type
    raft = {
      path = "/vault/data";
      performanceMultiplier = 8;
    };
    postgresql = {
      enabled = false;
      connString = "";
    };
  };
  
  ha = {
    enabled = true;                       # High availability
    replicas = 3;
  };
  
  auth = {
    kubernetes = true;                    # Kubernetes auth method
    jwt = false;                          # JWT auth method
    ldap = false;                         # LDAP auth method
    oidc = false;                         # OIDC auth method
  };
  
  tls = {
    enabled = true;
    certSecret = "vault-tls";
    tlsMinVersion = "1.2";
  };
  
  seal = {
    type = "shamir";                      # Sealing method
    aws = {
      enabled = false;
      kmsKeyId = "";
    };
  };
  
  ui = {
    enabled = true;
    serviceType = "ClusterIP";
  };
  
  resources = {
    limits = { cpu = "1000m"; memory = "1024Mi"; };
    requests = { cpu = "500m"; memory = "512Mi"; };
  };
  
  labels = { };
  annotations = { };
}
```

**Returns:**
Configuration with Vault-specific settings and HA support.

**Example:**
```nix
mkVaultSecrets "production" {
  replicas = 3;
  ha.enabled = true;
  storage.type = "raft";
  seal.type = "shamir";
}
```

### mkAwsSecretsManager

Creates AWS Secrets Manager configuration for cloud-native secret management.

**Signature:**
```nix
mkAwsSecretsManager = name: config: { ... }
```

**Parameters:**
- `name` (string): Configuration name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "aws-secrets";
  
  aws = {
    region = "us-east-1";
    roleArn = "";                         # IAM role ARN
    externalId = "";                      # External ID for cross-account
  };
  
  secret = {
    name = "";                            # Secret name
    description = "";                     # Description
    secretType = "SecureString";          # Type: String or SecureString
    kmsKeyId = "alias/aws/secretsmanager";
  };
  
  rotation = {
    enabled = false;
    rotationDays = 30;
    rotationLambda = "";
  };
  
  backup = {
    enabled = false;
    replicaRegion = "";                   # Replica region
  };
}
```

### mkSealedSecret

Creates a Sealed Secret resource for storing encrypted data.

**Signature:**
```nix
mkSealedSecret = name: config: { ... }
```

**Parameters:**
- `name` (string): Secret name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "my-secret";
  
  encryptedData = { };                    # Encrypted key-value pairs
  scope = "strict";                       # Sealing scope
  namespace = "default";                  # Target namespace
  labels = { };                           # Custom labels
}
```

### mkExternalSecret

Creates an External Secret resource for syncing secrets from backends.

**Signature:**
```nix
mkExternalSecret = name: config: { ... }
```

**Parameters:**
- `name` (string): Resource name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "my-external-secret";
  
  secretStore = {
    name = "default";
    kind = "SecretStore";
  };
  
  refreshInterval = "15m";
  data = [];                              # Data to sync
  
  target = {
    name = "external-secret";
    creationPolicy = "Owner";
  };
  
  template = { };                         # Template for transformation
}
```

### mkSecretRotationPolicy

Creates a secret rotation policy for automated key management.

**Signature:**
```nix
mkSecretRotationPolicy = name: config: { ... }
```

**Parameters:**
- `name` (string): Policy name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "rotation-policy";
  
  schedule = "0 0 * * 0";                 # Cron schedule (weekly)
  rotationDays = 30;                      # Rotation period
  secrets = [];                           # Secrets to rotate
  
  method = "automated";                   # Manual or automated
  
  notifications = {
    enabled = true;
    email = [];
    slack = "";
  };
}
```

### mkSecretBackupPolicy

Creates a secret backup policy for disaster recovery.

**Signature:**
```nix
mkSecretBackupPolicy = name: config: { ... }
```

**Parameters:**
- `name` (string): Policy name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "backup-policy";
  
  schedule = "0 2 * * *";                 # Daily backup at 2 AM
  retentionDays = 30;                     # Retention period
  
  destination = {
    type = "s3";
    bucket = "";
    region = "us-east-1";
  };
  
  encryption = {
    enabled = true;
    kmsKeyId = "";
  };
}
```

### mkSecretAccessPolicy

Creates RBAC policy for secret access control.

**Signature:**
```nix
mkSecretAccessPolicy = name: config: { ... }
```

**Parameters:**
- `name` (string): Policy name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "access-policy";
  
  subject = {
    kind = "ServiceAccount";
    name = "";
  };
  
  secrets = [];                           # Secrets to grant access
  
  permissions = [
    "get"
    "list"
  ];
  
  timeBasedAccess = {
    enabled = false;
    startTime = "";
    endTime = "";
  };
  
  ipWhitelist = [];                       # IP addresses allowed
}
```

### mkSecretEncryption

Creates encryption configuration for secrets.

**Signature:**
```nix
mkSecretEncryption = name: config: { ... }
```

**Parameters:**
- `name` (string): Configuration name
- `config` (object): Configuration object

**Config Options:**
```nix
{
  name = "encryption-config";
  
  provider = "aes-gcm";                   # Encryption provider
  
  keyManagement = {
    keyId = "";
    provider = "local";                   # local, kms, vault
  };
  
  resources = [
    "secrets"
  ];
  
  atRest = {
    enabled = true;
    algorithm = "AES-256-GCM";
  };
  
  inTransit = {
    enabled = true;
    tlsVersion = "1.3";
  };
}
```

## Integration Examples

### Example 1: Sealed Secrets Setup

```nix
let
  controller = secretsManagement.mkSealedSecrets "main" {
    namespace = "sealed-secrets";
    keys.rotation = true;
  };
in
{
  inherit controller;
}
```

### Example 2: External Secrets with AWS

```nix
let
  operator = secretsManagement.mkExternalSecrets "aws-integration" {
    replicas = 2;
    backend = {
      type = "aws-secrets-manager";
      region = "us-west-2";
    };
  };
in
{
  inherit operator;
}
```

### Example 3: HashiCorp Vault HA

```nix
let
  vault = secretsManagement.mkVaultSecrets "production" {
    replicas = 3;
    ha.enabled = true;
    storage.type = "raft";
  };
in
{
  inherit vault;
}
```

### Example 4: Secret Rotation Policy

```nix
let
  rotationPolicy = secretsManagement.mkSecretRotationPolicy "database-rotation" {
    schedule = "0 0 * * 0";
    rotationDays = 30;
    secrets = [ "db-password" "api-key" ];
  };
in
{
  inherit rotationPolicy;
}
```

### Example 5: Secret Access Control

```nix
let
  accessPolicy = secretsManagement.mkSecretAccessPolicy "app-access" {
    subject = {
      kind = "ServiceAccount";
      name = "my-app";
    };
    secrets = [ "api-credentials" "database-password" ];
    permissions = [ "get" "list" ];
  };
in
{
  inherit accessPolicy;
}
```

## Best Practices

### Secrets Framework Selection

1. **Sealed Secrets**: Choose for:
   - Kubernetes-native deployments
   - Simple encryption at rest
   - No external dependencies needed
   - GitOps-friendly workflows

2. **External Secrets**: Choose for:
   - Multiple secret backends
   - Cloud provider integration
   - Advanced synchronization
   - Existing secret stores

3. **HashiCorp Vault**: Choose for:
   - Enterprise requirements
   - Dynamic secrets generation
   - Advanced authentication
   - Multi-cloud deployments

4. **AWS Secrets Manager**: Choose for:
   - AWS-only deployments
   - Native AWS integration
   - Compliance requirements
   - Existing AWS infrastructure

### Security Best Practices

- **Encryption**: Always encrypt secrets at rest and in transit
- **Access Control**: Use RBAC with least privilege principles
- **Rotation**: Implement automated secret rotation
- **Auditing**: Enable comprehensive audit logging
- **Backup**: Regular backups with encryption
- **Isolation**: Use separate secrets per environment
- **Credentials**: Never store credentials in code or git
- **Scanning**: Scan for exposed secrets regularly

### Operational Best Practices

- **Monitoring**: Alert on secret access and modifications
- **Backup**: Test backup and recovery procedures
- **Disaster Recovery**: Plan for secrets recovery
- **Documentation**: Document secret management procedures
- **Training**: Train team on secrets handling
- **Compliance**: Meet regulatory requirements
- **Automation**: Automate secret injection and rotation
- **Versioning**: Version and track secret changes

### Performance Considerations

- **Caching**: Cache secret lookups when possible
- **TTL**: Set appropriate TTLs for secret validity
- **Refresh**: Balance between freshness and performance
- **Resources**: Allocate sufficient CPU/memory
- **Replication**: Use replication for high availability
- **Bandwidth**: Monitor network usage for large secrets

## Kubernetes Version Support

This module supports Kubernetes versions 1.26 through 1.31:
- Full support on all versions
- RBAC integration on all versions
- ServiceAccount authentication on all versions

## Integration with Other Modules

### With RBAC Module
```nix
rbac = rbacModule.mkRBACPolicy "secret-reader" {
  subjects = [{
    kind = "ServiceAccount";
    name = "my-app";
  }];
  resources = [ "secrets" ];
  permissions = [ "get" "list" ];
};
```

### With Compliance Module
```nix
compliance = complianceModule.mkComplianceLabel {
  framework = "SOC2";
  dataClassification = "confidential";
  encryption = "required";
};
```

## Deployment Checklist

Before deploying secrets management:

- [ ] Choose appropriate secrets framework
- [ ] Configure encryption keys
- [ ] Set up authentication methods
- [ ] Configure backup procedures
- [ ] Plan secret rotation schedule
- [ ] Implement access controls
- [ ] Set up audit logging
- [ ] Test recovery procedures
- [ ] Document procedures
- [ ] Plan monitoring and alerting
- [ ] Train team members
- [ ] Verify compliance requirements

## Troubleshooting

### Sealed Secrets Issues
1. Verify controller is running
2. Check sealing scope matches
3. Verify encryption key exists
4. Review controller logs

### External Secrets Issues
1. Check backend connectivity
2. Verify credentials
3. Check secret store configuration
4. Review operator logs

### Vault Issues
1. Check Vault status
2. Verify TLS certificates
3. Check authentication configuration
4. Review Vault logs

## Performance Considerations

- **CPU Usage**: Typically 50-500m depending on secret throughput
- **Memory Usage**: Typically 128-512Mi per instance
- **Sync Latency**: 1-15m depending on refresh interval
- **Encryption Overhead**: Minimal (<1% CPU)
- **Scalability**: Supports thousands of secrets

## API Stability

The Secrets Management module maintains backward compatibility for:
- Builder function signatures
- Configuration schema structure
- Validation rules
- Helper function outputs
