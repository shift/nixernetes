# Advanced Security Hardening Guide

Complete guide for securing Nixernetes deployments for production environments.

## Table of Contents

1. [Authentication & Authorization](#authentication--authorization)
2. [Network Security](#network-security)
3. [Container Security](#container-security)
4. [Secret Management](#secret-management)
5. [Compliance & Auditing](#compliance--auditing)
6. [Security Checklist](#security-checklist)

## Authentication & Authorization

### Kubernetes RBAC

```nix
let
  rbac = import ./src/lib/rbac.nix { inherit lib; };
in
{
  # Create least-privilege service account
  appServiceAccount = rbac.mkServiceAccount {
    namespace = "production";
    name = "myapp";
  };
  
  # Create role with minimal permissions
  appRole = rbac.mkRole {
    namespace = "production";
    name = "myapp-role";
    
    rules = [
      {
        # Only allow reading ConfigMaps
        apiGroups = [""];
        resources = ["configmaps"];
        verbs = ["get"];
        resourceNames = ["myapp-config"];
      }
      {
        # Allow reading secrets (specific ones)
        apiGroups = [""];
        resources = ["secrets"];
        verbs = ["get"];
        resourceNames = ["myapp-secrets"];
      }
    ];
  };
  
  # Bind role to service account
  appRoleBinding = rbac.mkRoleBinding {
    namespace = "production";
    name = "myapp-role-binding";
    
    roleRef = { kind = "Role"; name = "myapp-role"; };
    subjects = [{
      kind = "ServiceAccount";
      name = "myapp";
      namespace = "production";
    }];
  };
}
```

### API Server Security

```nix
{
  apiServerConfig = {
    apiVersion = "apiserver.config.k8s.io/v1";
    kind = "EncryptionConfiguration";
    
    # Encrypt secrets at rest
    resources = [{
      resources = ["secrets"];
      providers = [
        { aescbc = { keys = [{ name = "key1"; secret = "..."; }]; }; }
        { identity = {}; }  # Fallback
      ];
    }];
  };
}
```

## Network Security

### Network Policies

```nix
let
  security = import ./src/lib/security-policies.nix { inherit lib; };
in
{
  # Default deny all traffic
  denyAll = security.mkDefaultDenyNetworkPolicy {
    namespace = "production";
    name = "default-deny-all";
  };
  
  # Allow only specific traffic
  allowFrontendToBackend = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata = {
      namespace = "production";
      name = "allow-frontend-to-backend";
    };
    spec = {
      podSelector = {
        matchLabels = { tier = "backend"; };
      };
      policyTypes = ["Ingress"];
      ingress = [{
        from = [{
          podSelector = {
            matchLabels = { tier = "frontend"; };
          };
        }];
        ports = [{
          protocol = "TCP";
          port = 8080;
        }];
      }];
    };
  };
  
  # Egress control
  egressControl = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata = {
      namespace = "production";
      name = "egress-control";
    };
    spec = {
      podSelector = {};
      policyTypes = ["Egress"];
      egress = [
        # Allow DNS
        {
          to = [{ podSelector = { matchLabels = { "k8s-app" = "kube-dns"; }; }; }];
          ports = [{ protocol = "UDP"; port = 53; }];
        }
        # Allow external databases
        {
          to = [{ ipBlock = { cidr = "10.0.0.0/8"; }; }];
          ports = [{ protocol = "TCP"; port = 5432; }];
        }
      ];
    };
  };
}
```

## Container Security

### Pod Security Standards

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  # Restricted pod security
  deployment = k8s.mkDeployment {
    namespace = "production";
    name = "secure-app";
    
    containers = [{
      image = "myapp:latest";
      
      securityContext = {
        # Run as non-root user
        runAsNonRoot = true;
        runAsUser = 1000;
        
        # Prevent privilege escalation
        allowPrivilegeEscalation = false;
        
        # Drop dangerous capabilities
        capabilities = {
          drop = ["ALL"];
        };
        
        # Read-only root filesystem
        readOnlyRootFilesystem = true;
        
        # SELinux policy
        seLinuxOptions = {
          level = "s0:c123,c456";
        };
      };
      
      # Resource limits prevent DOS
      resources = {
        limits = {
          cpu = "1000m";
          memory = "1Gi";
        };
        requests = {
          cpu = "500m";
          memory = "512Mi";
        };
      };
      
      # Health checks
      livenessProbe = {
        httpGet = { path = "/health"; port = 8080; };
        initialDelaySeconds = 30;
        timeoutSeconds = 5;
      };
      
      readinessProbe = {
        httpGet = { path = "/ready"; port = 8080; };
        initialDelaySeconds = 10;
        timeoutSeconds = 3;
      };
    }];
    
    # Pod-level security
    podSecurityContext = {
      fsGroup = 2000;
      seccompProfile = {
        type = "RuntimeDefault";
      };
    };
  };
}
```

### Image Security

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
  registry = import ./src/lib/container-registry.nix { inherit lib; };
in
{
  # Force specific registry
  imagePullPolicy = registry.mkImagePullSecret {
    namespace = "production";
    name = "registry-secret";
    
    registryUrl = "myregistry.azurecr.io";
    username = "serviceaccount";
    password = "secret-from-vault";
  };
  
  # Deployment with image security
  deployment = k8s.mkDeployment {
    namespace = "production";
    name = "app";
    
    imagePullSecrets = [{
      name = "registry-secret";
    }];
    
    containers = [{
      # Use specific image tag (not latest)
      image = "myregistry.azurecr.io/myapp:v1.2.3";
      
      # Enforce image pull policy
      imagePullPolicy = "Always";
    }];
  };
}
```

## Secret Management

### Vault Integration

```nix
let
  secrets = import ./src/lib/secrets-management.nix { inherit lib; };
in
{
  # Vault secret store
  vaultSecretStore = secrets.mkVaultSecretStore {
    namespace = "production";
    name = "vault";
    
    server = "https://vault.example.com";
    path = "secret";
    
    # Kubernetes authentication
    auth = {
      kubernetes = {
        mountPath = "kubernetes";
        role = "myapp";
      };
    };
  };
  
  # External secret from Vault
  dbSecret = secrets.mkExternalSecret {
    namespace = "production";
    name = "database";
    
    secretStoreRef = {
      name = "vault";
      kind = "SecretStore";
    };
    
    data = [
      {
        secretKey = "host";
        remoteRef = { key = "database/host"; };
      }
      {
        secretKey = "password";
        remoteRef = { key = "database/password"; };
      }
    ];
  };
}
```

### Secret Rotation

```bash
#!/bin/bash

# Rotate database password
vault kv put secret/database password="new-secure-password"

# K8s will sync automatically
# Trigger pod restart to apply new secrets
kubectl rollout restart deployment/myapp -n production
```

## Compliance & Auditing

### Audit Logging

```nix
{
  auditPolicy = {
    apiVersion = "audit.k8s.io/v1";
    kind = "Policy";
    
    rules = [
      # Log all requests at RequestResponse level
      {
        level = "RequestResponse";
        omitStages = ["RequestReceived"];
      }
      
      # Log system accounts at Metadata level
      {
        level = "Metadata";
        userGroups = ["system:serviceaccounts"];
      }
      
      # Don't log watch requests
      {
        level = "None";
        verbs = ["watch"];
      }
      
      # Don't log health checks
      {
        level = "None";
        nonResourceURLs = ["/healthz*"];
      }
    ];
  };
}
```

### Kyverno Policies

```nix
let
  kyverno = import ./src/lib/kyverno.nix { inherit lib; };
in
{
  # Require resource limits
  resourceLimitsPolicy = kyverno.mkKyvernoPolicy {
    namespace = "production";
    name = "require-resource-limits";
    
    validationFailureAction = "enforce";
    
    rules = [{
      name = "check-resource-limits";
      match = {
        resources = {
          kinds = ["Pod"];
        };
      };
      validate = {
        message = "CPU and memory limits required";
        pattern = {
          spec = {
            containers = [{
              resources = {
                limits = {
                  cpu = "?*";
                  memory = "?*";
                };
              };
            }];
          };
        };
      };
    }];
  };
  
  # Require security context
  securityContextPolicy = kyverno.mkKyvernoPolicy {
    namespace = "production";
    name = "require-security-context";
    
    validationFailureAction = "enforce";
    
    rules = [{
      name = "check-security-context";
      match = {
        resources = {
          kinds = ["Pod"];
        };
      };
      validate = {
        message = "Security context required";
        pattern = {
          spec = {
            securityContext = {
              runAsNonRoot = true;
              fsGroup = "?*";
            };
            containers = [{
              securityContext = {
                allowPrivilegeEscalation = false;
                readOnlyRootFilesystem = true;
              };
            }];
          };
        };
      };
    }];
  };
}
```

## Security Checklist

### Pre-Deployment

- ✓ Image from trusted registry
- ✓ Image vulnerability scan completed
- ✓ No hardcoded secrets
- ✓ Secrets in Vault/external manager
- ✓ RBAC rules minimal
- ✓ Network policies defined
- ✓ Security context configured
- ✓ Resource limits set

### Deployment

- ✓ Pod security policy enforced
- ✓ Kyverno policies in place
- ✓ Audit logging enabled
- ✓ Monitoring configured
- ✓ Secrets rotated regularly
- ✓ Backups configured
- ✓ Incident response plan documented

### Post-Deployment

- ✓ Security scans running
- ✓ Compliance checks passing
- ✓ Audit logs reviewed
- ✓ Alerts configured
- ✓ Penetration testing completed
- ✓ Security patches applied

## Summary

Secure production deployment requires:

1. **Least privilege access** - RBAC, service accounts
2. **Network isolation** - Network policies, firewalls
3. **Container hardening** - Security context, read-only FS
4. **Secret protection** - Vault, encryption, rotation
5. **Compliance tracking** - Audit logs, Kyverno
6. **Continuous monitoring** - Scanning, alerting, logging

See `docs/SECURITY_POLICIES.md` for additional security features and policies.

