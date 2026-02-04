# Nixernetes Module Reference

Complete reference guide for all 35 Nixernetes modules with quick lookup by category and function.

## Quick Reference by Category

### Foundation Modules (4)
| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **schema.nix** | API version resolution | `resolveApiVersion`, `getSupportedVersions` |
| **types.nix** | Kubernetes type definitions | `k8sResource`, `k8sMetadata`, `deploymentSpec` |
| **validation.nix** | Configuration validation | `validateManifest`, `validateNamespaces` |
| **output.nix** | YAML and Helm generation | `orderResourcesForApply`, `resourcesToYaml` |

### Core Kubernetes Modules (5)
| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **kubernetes-core.nix** | Basic Kubernetes resources | `mkDeployment`, `mkService`, `mkStatefulSet`, `mkDaemonSet`, `mkConfigMap`, `mkSecret` |
| **container-registry.nix** | Image registry management | `mkDockerRegistry`, `mkHarbor`, `mkNexus`, `mkArtifactory`, `mkImagePullSecret`, `mkImageScan` |
| **helm-integration.nix** | Helm chart management | `mkHelmChart`, `mkHelmRelease`, `mkHelmRepository`, `mkHelmValues` |
| **advanced-orchestration.nix** | Advanced scheduling | `mkPodAffinity`, `mkNodeAffinity`, `mkTolerations`, `mkPriorityClass`, `mkScheduler` |
| **multi-tenancy.nix** | Multi-tenant setup | `mkNamespaceWithQuota`, `mkResourceQuota`, `mkNetworkPolicyForNamespace`, `mkTenantRBAC` |

### Security & Compliance Modules (8)
| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **rbac.nix** | Role-based access control | `mkRole`, `mkRoleBinding`, `mkServiceAccount`, `mkClusterRole`, `mkClusterRoleBinding` |
| **compliance.nix** | Compliance framework | `mkComplianceLabels`, `withComplianceLabels`, `withTraceability`, `validateComplianceLabels` |
| **compliance-enforcement.nix** | Compliance automation | `getComplianceRequirements`, `checkCompliance`, `enforceCompliance`, `generateComplianceReport` |
| **compliance-profiles.nix** | Environment profiles | `getProfile`, `mkEnvironmentCompliance`, `mkMultiEnvironmentDeployment` |
| **secrets-management.nix** | Secret management | `mkSealedSecret`, `mkExternalSecret`, `mkVaultSecretStore`, `mkAWSSecretsManager` |
| **security-scanning.nix** | Security scanning | `mkImageScan`, `mkVulnerabilityScan`, `mkPolicyValidation`, `mkSecurityScanSchedule` |
| **kyverno.nix** | Policy engine | `mkKyvernoPolicy`, `mkClusterPolicy`, `mkClusterPolicyReport`, `mkPolicyExecution` |
| **security-policies.nix** | Security policies | `mkPodSecurityPolicy`, `mkNetworkPolicy`, `mkDefaultDenyPolicy`, `mkEgressPolicy` |

### Observability Modules (6)
| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **performance-analysis.nix** | Performance metrics | `mkPrometheus`, `mkPerformanceMonitoring`, `mkResourceAnalysis`, `mkBottleneckDetection` |
| **policy-visualization.nix** | Visual policy display | `mkPolicyVisualization`, `mkPolicyDashboard`, `mkComplianceDashboard`, `mkPolicyReport` |
| **unified-api.nix** | Unified resource API | `mkUnifiedAPI`, `mkResourceQuery`, `mkGraphQL`, `mkRESTEndpoint` |
| **policy-testing.nix** | Policy validation | `mkPolicyTest`, `mkComplianceTest`, `mkValidationTest`, `mkPolicySimulation` |
| **cost-analysis.nix** | Cost tracking | `mkCostAnalysis`, `mkResourceCostModel`, `mkBudgetAlert`, `mkCostOptimization` |
| **gitops.nix** | GitOps workflow | `mkArgoCD`, `mkFlux`, `mkGitRepository`, `mkSyncPolicy`, `mkAutomation` |

### Data & Event Modules (4)
| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **database-management.nix** | Database management | `mkPostgreSQL`, `mkMySQL`, `mkMongoDB`, `mkRedis`, `mkDatabaseBackup`, `mkReplication`, `mkMigration` |
| **event-processing.nix** | Event streaming | `mkKafkaCluster`, `mkNATSCluster`, `mkRabbitMQ`, `mkPulsarCluster`, `mkTopic`, `mkConsumerGroup`, `mkEventPipeline` |
| **disaster-recovery.nix** | DR and backup | `mkBackupPolicy`, `mkRestorePlan`, `mkSnapshotSchedule`, `mkDisasterRecovery` |
| **multi-tier-deployment.nix** | Multi-tier apps | `mkFrontendDeployment`, `mkMiddlewareDeployment`, `mkDatabaseTier`, `mkCacheTier` |

### Workload Modules (4)
| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **batch-processing.nix** | Batch jobs | `mkKubernetesJob`, `mkCronJob`, `mkAirflowDeployment`, `mkArgoWorkflow`, `mkSparkJob`, `mkJobQueue` |
| **ml-operations.nix** | ML workloads | `mkKubeflow`, `mkSeldonCore`, `mkMLflow`, `mkKServe`, `mkFeatureStore`, `mkAutoML` |
| **ci-cd.nix** | CI/CD pipelines | `mkJenkinsDeployment`, `mkGitlabRunner`, `mkGithubActions`, `mkPipeline` |
| **service-mesh.nix** | Service mesh | `mkIstiodeployment`, `mkLinkerdDeployment`, `mkVirtualService`, `mkDestinationRule`, `mkServiceEntry` |

### Operations Modules (4)
| Module | Purpose | Key Functions |
|--------|---------|---------------|
| **api-gateway.nix** | API gateway | `mkTraefik`, `mkKong`, `mkContour`, `mkNGINX`, `mkRateLimiting`, `mkCircuitBreaker` |
| **generators.nix** | Utility generators | `generateDeployment`, `generateService`, `generateManifest`, `generateDefaults` |
| **policy-generation.nix** | Policy generation | `mkServiceAccountRBAC`, `mkPodSecurityPolicy`, `mkApplicationPolicies`, `mkNetworkPolicies` |
| **policy-visualization.nix** | (see Observability) | Policy dashboard and visualization |

## Module Details

### Foundation: schema.nix

**Purpose**: Manage Kubernetes API schema and version compatibility

**Key Functions**:

```nix
# Resolve API version for resource kind
resolveApiVersion {
  kind = "Deployment";
  kubernetesVersion = "1.30";
}
# Returns: "apps/v1"

# Get all supported Kubernetes versions
getSupportedVersions
# Returns: ["1.28" "1.29" "1.30" "1.31"]

# Check if version is supported
isSupportedVersion "1.30"  # Returns: true

# Get full API map for specific version
getApiMap "1.30"
```

**Common Use Cases**:
- Determine correct API version for resources
- Check Kubernetes version compatibility
- Validate API versions in configurations

**Documentation**: `docs/API.md`

---

### Foundation: types.nix

**Purpose**: Define Nix type system for Kubernetes resources

**Key Types**:

```nix
k8sResource          # Base type for all resources
k8sMetadata          # Resource metadata (name, namespace, labels, annotations)
deploymentSpec       # Deployment specification
serviceSpec          # Service specification
containerSpec        # Container definition
volumeSpec           # Volume definition
```

**Key Functions**:

```nix
mkDeployment { ... }
mkService { ... }
mkStatefulSet { ... }
mkDaemonSet { ... }
mkJob { ... }
mkCronJob { ... }
mkNamespace { ... }
mkConfigMap { ... }
mkSecret { ... }
mkPersistentVolume { ... }
mkPersistentVolumeClaim { ... }
```

---

### Core Kubernetes: kubernetes-core.nix

**Purpose**: Core Kubernetes resource generation

**Key Builders** (10 functions):

```nix
# Deployment with replicas
mkDeployment {
  namespace = "default";
  name = "my-app";
  replicas = 3;
  containers = [{ image = "myapp:1.0"; }];
}

# Service to expose deployment
mkService {
  namespace = "default";
  name = "my-app";
  type = "LoadBalancer";  # ClusterIP, NodePort, LoadBalancer, ExternalName
  ports = [{ port = 80; targetPort = 8080; }];
}

# StatefulSet for stateful apps
mkStatefulSet {
  namespace = "default";
  name = "mysql";
  replicas = 3;
  containers = [{ image = "mysql:5.7"; }];
  serviceName = "mysql-service";
}

# DaemonSet for node-level workloads
mkDaemonSet {
  namespace = "kube-system";
  name = "filebeat";
  containers = [{ image = "filebeat:latest"; }];
}

# Configuration management
mkConfigMap {
  namespace = "default";
  name = "app-config";
  data = { "config.yaml" = "..."; };
}

# Sensitive data management
mkSecret {
  namespace = "default";
  name = "db-password";
  type = "Opaque";  # kubernetes.io/basic-auth, etc.
  data = { password = "..."; };
}

# Storage
mkPersistentVolume { ... }
mkPersistentVolumeClaim { ... }
mkStorageClass { ... }

# Pod management
mkPod { ... }
mkReplicaSet { ... }
```

**Common Parameters**:

```nix
namespace      # Kubernetes namespace (required)
name          # Resource name (required)
labels        # Resource labels for organization
annotations   # Metadata annotations
replicas      # Number of replicas (for Deployment, StatefulSet)
containers    # Container specifications
selector      # Label selector for matching pods
```

---

### Security & Compliance: rbac.nix

**Purpose**: Manage role-based access control

**Key Builders**:

```nix
# Create a role with specific permissions
mkRole {
  namespace = "default";
  name = "pod-reader";
  rules = [
    {
      apiGroups = [""];
      resources = ["pods"];
      verbs = ["get" "list" "watch"];
    }
  ];
}

# Bind role to service account
mkRoleBinding {
  namespace = "default";
  name = "read-pods";
  roleRef = { kind = "Role"; name = "pod-reader"; };
  subjects = [
    { kind = "ServiceAccount"; name = "myapp"; }
  ];
}

# Create service account
mkServiceAccount {
  namespace = "default";
  name = "myapp";
}

# Cluster-wide role
mkClusterRole { ... }
mkClusterRoleBinding { ... }
```

**Pre-built Service Accounts**:

```nix
mkReadOnlyServiceAccount { ... }
mkEditServiceAccount { ... }
mkAdminServiceAccount { ... }
```

---

### Data: database-management.nix

**Purpose**: Database provisioning and management

**Key Builders** (10 functions):

```nix
# PostgreSQL database
mkPostgreSQL {
  namespace = "databases";
  name = "app-db";
  version = "15";
  storage = "10Gi";
  replicas = 1;
  resources = { ... };
}

# MySQL database
mkMySQL {
  namespace = "databases";
  name = "mysql-app";
  version = "8.0";
  storage = "20Gi";
}

# MongoDB
mkMongoDB {
  namespace = "databases";
  name = "mongodb";
  replicas = 3;
  storage = "30Gi";
}

# Redis cache
mkRedis {
  namespace = "caching";
  name = "redis-cache";
  maxmemory = "2Gi";
  persistence = true;
}

# Automated backup
mkDatabaseBackup {
  namespace = "databases";
  name = "backup-policy";
  databases = ["app-db" "mysql-app"];
  schedule = "0 2 * * *";
  retention = "30d";
}

# Database replication
mkReplication {
  namespace = "databases";
  name = "replication";
  primary = "app-db";
  replicas = ["replica1" "replica2"];
}

# Zero-downtime migration
mkDatabaseMigration {
  namespace = "databases";
  source = "old-db";
  target = "new-db";
  strategy = "copy-verify-switch";
}

# Performance tuning
mkPerformanceTuning {
  namespace = "databases";
  target = "app-db";
  optimizations = ["index" "cache" "parallelism"];
}

# Security hardening
mkDatabaseSecurity {
  namespace = "databases";
  target = "app-db";
  encryption = "at-rest";
  networkPolicy = true;
}

# Monitoring
mkDatabaseMonitoring {
  namespace = "databases";
  databases = ["app-db"];
  metrics = ["cpu" "memory" "disk" "connections"];
}
```

---

### Data: event-processing.nix

**Purpose**: Event streaming and message brokers

**Key Builders** (10 functions):

```nix
# Kafka cluster
mkKafkaCluster {
  namespace = "events";
  name = "kafka";
  brokers = 3;
  replicas = 3;
  storage = "50Gi";
}

# NATS cluster
mkNATSCluster {
  namespace = "events";
  name = "nats";
  replicas = 3;
  persistence = true;
}

# RabbitMQ
mkRabbitMQ {
  namespace = "events";
  name = "rabbitmq";
  replicas = 3;
  storage = "20Gi";
}

# Apache Pulsar
mkPulsarCluster {
  namespace = "events";
  name = "pulsar";
  brokers = 3;
  storage = "30Gi";
}

# Kafka topic
mkKafkaTopic {
  namespace = "events";
  cluster = "kafka";
  name = "events";
  partitions = 10;
  replicationFactor = 3;
  retentionMs = 604800000;
}

# Consumer group
mkConsumerGroup {
  namespace = "events";
  cluster = "kafka";
  name = "app-consumer";
  topics = ["events" "logs"];
}

# Dead letter queue
mkDeadLetterQueue {
  namespace = "events";
  cluster = "kafka";
  name = "dlq";
  retention = "30d";
}

# Schema registry
mkSchemaRegistry {
  namespace = "events";
  cluster = "kafka";
  storage = "10Gi";
}

# Event processing pipeline
mkEventPipeline {
  namespace = "events";
  name = "log-pipeline";
  source = { kafka = "events"; };
  processing = [
    { type = "filter"; condition = "level==ERROR"; }
    { type = "transform"; format = "json"; }
  ];
  sink = { elasticsearch = "logs"; };
}

# Event monitoring
mkEventMonitoring {
  namespace = "events";
  brokers = ["kafka" "nats"];
  metrics = ["throughput" "latency" "errors"];
}
```

---

### Workloads: batch-processing.nix

**Purpose**: Batch jobs and workflow orchestration

**Key Builders** (10 functions):

```nix
# Kubernetes Job
mkKubernetesJob {
  namespace = "batch";
  name = "data-processor";
  image = "processor:1.0";
  command = ["/bin/sh" "-c"];
  args = ["python process.py"];
  backoffLimit = 3;
  completions = 1;
  parallelism = 1;
}

# CronJob
mkCronJob {
  namespace = "batch";
  name = "daily-report";
  schedule = "0 2 * * *";
  image = "reporter:1.0";
  command = ["python"];
  args = ["generate_report.py"];
  successfulJobsHistoryLimit = 3;
}

# Airflow deployment
mkAirflowDeployment {
  namespace = "airflow";
  name = "airflow";
  version = "2.0";
  storage = "10Gi";
  dags = [
    { name = "etl-pipeline"; }
    { name = "data-quality"; }
  ];
}

# Argo Workflow
mkArgoWorkflow {
  namespace = "argo";
  name = "data-pipeline";
  entrypoint = "pipeline";
  templates = [
    { name = "pipeline"; dag = { tasks = [...]; }; }
  ];
  parallelism = 4;
}

# Spark job
mkSparkJob {
  namespace = "spark";
  name = "analytics";
  image = "spark:3.0";
  mainClass = "com.example.Analytics";
  cores = 4;
  executors = 8;
  memory = "2g";
}

# Job queue
mkJobQueue {
  namespace = "batch";
  name = "default-queue";
  priority = "normal";
  maxConcurrent = 5;
  maxRetries = 3;
}

# Batch job config
mkBatchJobConfig {
  namespace = "batch";
  name = "standard-config";
  resources = { cpu = "2"; memory = "4Gi"; };
  timeout = 3600;
  retryPolicy = "exponential";
}

# Workflow template
mkWorkflowTemplate {
  namespace = "argo";
  name = "data-processing";
  templates = [...];
  parameters = [
    { name = "image"; default = "processor:latest"; }
  ];
}

# Batch monitoring
mkBatchMonitoring {
  namespace = "batch";
  jobs = ["data-processor" "daily-report"];
  metrics = ["duration" "success-rate" "resource-usage"];
}

# Data pipeline
mkDataPipeline {
  namespace = "batch";
  name = "etl-pipeline";
  source = { type = "s3"; bucket = "raw-data"; };
  processing = [
    { type = "extract"; format = "json"; }
    { type = "transform"; operations = [...]; }
    { type = "load"; target = "datawarehouse"; }
  ];
  schedule = "0 * * * *";
}
```

---

### Workloads: ml-operations.nix

**Purpose**: Machine learning operations

**Key Builders** (10 functions):

```nix
# Kubeflow MLOps
mkKubeflow {
  namespace = "kubeflow";
  name = "kubeflow";
  storage = "50Gi";
}

# Seldon Core model serving
mkSeldonCore {
  namespace = "seldon";
  name = "seldon";
  storage = "20Gi";
}

# MLflow tracking
mkMLflow {
  namespace = "ml";
  name = "mlflow";
  backend = "postgresql";
  artifactStore = "s3";
}

# KServe model serving
mkKServe {
  namespace = "kserve";
  name = "kserve";
  storageClassName = "fast";
}

# Feature store
mkFeatureStore {
  namespace = "ml";
  name = "feast";
  online = "redis";
  offline = "postgresql";
}

# AutoML pipeline
mkAutoML {
  namespace = "ml";
  name = "automl";
  framework = "h2o";
  resources = { cpu = "8"; memory = "16Gi"; };
}

# Distributed training
mkDistributedTraining {
  namespace = "ml";
  name = "training-cluster";
  workers = 8;
  gpusPerWorker = 2;
}

# Model registry
mkModelRegistry {
  namespace = "ml";
  name = "model-registry";
  backend = "postgresql";
}

# Monitoring & drift
mkMonitoringAndDrift {
  namespace = "ml";
  models = ["model-v1" "model-v2"];
  driftThreshold = 0.1;
}

# ML pipeline
mkMLPipeline {
  namespace = "ml";
  name = "training-pipeline";
  stages = [
    { name = "prepare"; image = "prep:1.0"; }
    { name = "train"; image = "train:1.0"; gpu = true; }
    { name = "evaluate"; image = "eval:1.0"; }
  ];
  triggers = ["schedule" "webhook"];
}
```

---

## Quick Usage Patterns

### Deploy a Simple Web Application

```nix
let
  k8s = import ./src/lib/kubernetes-core.nix { inherit lib; };
in
{
  deployment = k8s.mkDeployment {
    namespace = "default";
    name = "web-app";
    replicas = 3;
    containers = [{
      image = "myapp:1.0";
      ports = [{ containerPort = 8080; }];
      resources = {
        requests = { cpu = "100m"; memory = "128Mi"; };
        limits = { cpu = "500m"; memory = "256Mi"; };
      };
    }];
  };
  
  service = k8s.mkService {
    namespace = "default";
    name = "web-app";
    type = "LoadBalancer";
    selector = { app = "web-app"; };
    ports = [{ port = 80; targetPort = 8080; }];
  };
}
```

### Set Up Database with Backups

```nix
let
  db = import ./src/lib/database-management.nix { inherit lib; };
in
{
  postgres = db.mkPostgreSQL {
    namespace = "databases";
    name = "app-db";
    version = "15";
    storage = "10Gi";
  };
  
  backup = db.mkDatabaseBackup {
    namespace = "databases";
    name = "db-backup";
    databases = ["app-db"];
    schedule = "0 2 * * *";
    retention = "30d";
  };
}
```

### Process Streaming Data

```nix
let
  events = import ./src/lib/event-processing.nix { inherit lib; };
in
{
  kafka = events.mkKafkaCluster {
    namespace = "events";
    name = "kafka";
    brokers = 3;
    replicas = 3;
  };
  
  topic = events.mkKafkaTopic {
    namespace = "events";
    cluster = "kafka";
    name = "logs";
    partitions = 10;
  };
  
  pipeline = events.mkEventPipeline {
    namespace = "events";
    name = "log-processing";
    source = { kafka = "logs"; };
    sink = { elasticsearch = "logs"; };
  };
}
```

---

## Finding Help

- **Module Documentation**: Browse `docs/*.md`
- **Examples**: View `src/examples/*.nix`
- **Tests**: Study `tests/integration-tests.nix`
- **API Reference**: See `docs/API.md`
- **Architecture**: Read `ARCHITECTURE.md`

## Module Maintenance

All modules are:
- Validated by nix flake checks
- Tested with integration tests
- Documented with examples
- Version controlled
- Production ready

Modules follow Nixernetes patterns:
- Automatic label injection
- Compliance support
- Framework integration
- Type validation
- Default sensible values

---

## Next Steps

1. **Pick a module** - Choose based on your use case
2. **Review examples** - Study `src/examples/` for your module
3. **Read documentation** - Deep dive in `docs/`
4. **Start small** - Create minimal configuration first
5. **Expand gradually** - Add features as needed
6. **Leverage validation** - Run `nix flake check` to validate

Happy infrastructure building!
