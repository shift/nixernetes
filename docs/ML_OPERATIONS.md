# ML Operations Module Documentation

## Overview

The ML Operations module provides comprehensive support for machine learning workloads on Kubernetes, integrating leading ML platforms including Kubeflow, Seldon Core, MLflow, KServe, and feature stores. This module enables enterprises to deploy and manage complete ML pipelines, from experiment tracking and model training through serving and monitoring.

## Module Statistics

- **Total Lines**: 500+
- **Builder Functions**: 10
- **Supported Frameworks**: Kubeflow, Seldon Core, MLflow, KServe, Feature Stores
- **Integration Scope**: Complete ML lifecycle management

## Core Features

### 1. Kubeflow Pipelines Integration
- Native Kubernetes-based ML workflow orchestration
- Component-based pipeline design
- Artifact management and tracking
- Multi-step pipeline execution
- Dynamic pipeline generation

### 2. Seldon Core Model Serving
- Production-grade model serving infrastructure
- Multi-model and multi-framework support
- Advanced deployment patterns (blue-green, canary)
- Request/response logging and monitoring
- Automatic scaling based on metrics

### 3. MLflow Experiment Tracking
- Comprehensive experiment management
- Metrics, parameters, and artifact tracking
- Model registry and versioning
- Hyperparameter optimization tracking
- Integration with notebook environments

### 4. KServe Inference Services
- Modern inference service architecture
- Predictive and explanatory models
- Request transformers and response processing
- Traffic splitting and A/B testing
- Model explainability integration

### 5. Feature Store Management
- Offline and online feature storage
- Feature engineering and transformation
- Feature discovery and governance
- Point-in-time correctness
- Drift and quality monitoring

### 6. Distributed Training
- Multi-worker and multi-GPU support
- Framework-agnostic orchestration
- Parameter server architectures
- Communication backend selection
- Resource management and isolation

### 7. AutoML Pipelines
- Automated algorithm selection
- Hyperparameter optimization
- Feature engineering automation
- Model ensembling
- Validation strategy management

### 8. Model Registry
- Centralized model management
- Version control and lineage
- Artifact storage and retrieval
- Model metadata and documentation
- Promotion workflows

### 9. Production Monitoring
- Model performance tracking
- Data and prediction drift detection
- Data quality monitoring
- Automated alerting
- Performance dashboards

### 10. Jupyter Notebook Management
- Multi-user notebook environments
- GPU and accelerator support
- Integrated authentication
- Storage and persistence
- Extension management

## Builder Functions

### mkKubeflowPipelines

Configures Kubeflow Pipelines for orchestrating complex ML workflows.

```nix
mkKubeflowPipelines {
  name = "kubeflow-pipelines";
  namespace = "kubeflow";
  version = "1.8.0";
  storage = {
    backend = "minio";
    bucket = "kubeflow-artifacts";
    path = "/artifacts";
    retentionDays = 30;
  };
  metadata = {
    database = "mysql";
    host = "mysql.kubeflow.svc";
    port = 3306;
    username = "mlpipeline";
  };
  ui = {
    enabled = true;
    replicas = 3;
    resources = {
      cpu = "500m";
      memory = "512Mi";
    };
  };
  logging = {
    enabled = true;
    level = "info";
  };
}
```

**Configuration Options:**

- `name` (required): Pipeline deployment name
- `namespace` (default: "kubeflow"): Kubernetes namespace
- `version` (default: "1.8.0"): Kubeflow version
- `storage.backend` (default: "minio"): Artifact storage backend (minio, s3, gcs)
- `storage.bucket`: Artifact bucket name
- `storage.path`: Artifact storage path
- `storage.retentionDays`: Artifact retention period
- `metadata.database`: Metadata database type
- `ui.enabled`: Enable Kubeflow UI
- `ui.replicas`: Number of UI replicas
- `logging.enabled`: Enable component logging

**Use Cases:**

- Complex multi-step ML workflows
- Pipeline component composition
- Large-scale batch processing
- DAG-based orchestration
- Cross-team collaboration

### mkSeldonCore

Deploys Seldon Core for production model serving.

```nix
mkSeldonCore {
  name = "example-model";
  namespace = "seldon";
  version = "1.15.0";
  models = [
    {
      name = "classifier";
      type = "sklearn";
      uri = "s3://models/classifier:1.0";
    }
  ];
  replicas = 3;
  autoscaling = {
    enabled = true;
    minReplicas = 2;
    maxReplicas = 10;
    targetCPUUtilization = 70;
  };
  monitoring = {
    enabled = true;
    prometheus = true;
  };
}
```

**Configuration Options:**

- `name` (required): Deployment name
- `namespace` (default: "seldon"): Kubernetes namespace
- `version` (default: "1.15.0"): Seldon Core version
- `models` (required): Model specifications
- `replicas`: Default replica count
- `autoscaling.enabled`: Enable horizontal pod autoscaling
- `autoscaling.minReplicas`: Minimum replicas
- `autoscaling.maxReplicas`: Maximum replicas
- `autoscaling.targetCPUUtilization`: Target CPU percentage

**Use Cases:**

- Production model inference
- Blue-green deployments
- Canary model releases
- Multi-model serving
- Online prediction serving

### mkMLflowTracking

Configures MLflow for experiment tracking and model registry.

```nix
mkMLflowTracking {
  namespace = "mlflow";
  version = "2.0.0";
  trackingUri = "http://mlflow.mlflow.svc:5000";
  backend = {
    type = "postgresql";
    host = "postgres-mlflow.mlflow.svc";
    port = 5432;
    username = "mlflow";
    database = "mlflow";
  };
  artifactStore = {
    type = "s3";
    bucket = "mlflow-artifacts";
    path = "/mlflow";
  };
  ui = {
    enabled = true;
    replicas = 2;
    port = 5000;
  };
}
```

**Configuration Options:**

- `namespace` (required): Kubernetes namespace
- `version` (default: "2.0.0"): MLflow version
- `trackingUri` (required): MLflow tracking server URI
- `backend.type`: Metadata backend (postgresql, mysql, sqlite)
- `backend.host`: Database hostname
- `backend.port`: Database port
- `artifactStore.type`: Artifact storage (s3, gcs, azure, local)
- `artifactStore.bucket`: Artifact bucket name
- `ui.enabled`: Enable MLflow UI
- `auth.enabled`: Enable authentication

**Use Cases:**

- Experiment tracking and logging
- Model parameter comparison
- Artifact versioning
- Model registry management
- Metrics visualization

### mkKServeInference

Deploys KServe InferenceService for modern ML model serving.

```nix
mkKServeInference {
  name = "iris-predictor";
  namespace = "kserve";
  predictor = {
    spec = {
      containers = [
        {
          name = "classifier";
          image = "sklearn-model:latest";
          ports = [{ containerPort = 8080; }];
        }
      ];
    };
  };
  transformer = {
    spec = {
      containers = [
        {
          name = "transformer";
          image = "feature-transformer:latest";
        }
      ];
    };
  };
  minReplicas = 1;
  maxReplicas = 10;
}
```

**Configuration Options:**

- `name` (required): InferenceService name
- `namespace` (default: "kserve"): Kubernetes namespace
- `predictor` (required): Predictor specification
- `transformer`: Optional request transformer
- `explainer`: Optional explainer service
- `canaryTraffic`: Canary traffic percentage
- `minReplicas`: Minimum replicas
- `maxReplicas`: Maximum replicas

**Use Cases:**

- Modern inference serving
- Request/response transformation
- Model explainability
- Traffic splitting
- Serverless model serving

### mkFeatureStore

Configures feature store for feature engineering and management.

```nix
mkFeatureStore {
  name = "online-features";
  namespace = "feature-store";
  type = "both";
  backend = {
    offline = "s3";
    online = "redis";
  };
  storage = {
    path = "/features";
    format = "parquet";
    retention = 90;
  };
  registry = {
    enabled = true;
    type = "postgres";
  };
  monitoring = {
    enabled = true;
    dataQuality = true;
    driftDetection = true;
  };
}
```

**Configuration Options:**

- `name` (required): Feature store name
- `namespace` (default: "feature-store"): Kubernetes namespace
- `type` (required): Store type (offline, online, both)
- `backend.offline`: Offline storage backend
- `backend.online`: Online storage backend
- `storage.format`: Data format (parquet, csv, delta)
- `storage.retention`: Retention period in days
- `registry.enabled`: Enable feature registry
- `monitoring.enabled`: Enable monitoring
- `monitoring.dataQuality`: Enable quality checks

**Use Cases:**

- Feature engineering at scale
- Real-time and batch feature serving
- Feature discovery and documentation
- Data quality monitoring
- Feature lineage tracking

### mkDistributedTraining

Configures distributed training infrastructure for large-scale model training.

```nix
mkDistributedTraining {
  name = "distributed-bert";
  namespace = "ml-training";
  framework = "pytorch";
  workers = 4;
  parameterServers = 2;
  gpuPerWorker = 2;
  cpuPerWorker = 8;
  memoryPerWorker = "16Gi";
  networking = {
    backend = "horovod";
    communicationBackend = "nccl";
  };
}
```

**Configuration Options:**

- `name` (required): Training job name
- `namespace` (default: "ml-training"): Kubernetes namespace
- `framework` (required): Training framework (tensorflow, pytorch, horovod)
- `workers`: Number of worker nodes
- `parameterServers`: Number of parameter servers
- `gpuPerWorker`: GPUs per worker
- `cpuPerWorker`: CPUs per worker
- `memoryPerWorker`: Memory per worker
- `networking.backend`: Networking backend (horovod, mpi, nccl)

**Use Cases:**

- Large-scale distributed training
- Multi-GPU training jobs
- Parameter server architectures
- Distributed deep learning
- Accelerated training

### mkAutoML

Configures AutoML pipeline for automated model selection and hyperparameter tuning.

```nix
mkAutoML {
  name = "automl-classification";
  namespace = "automl";
  objective = "classification";
  timeLimit = 3600;
  budget = {
    maxTrials = 100;
    maxParallel = 10;
  };
  algorithms = {
    enabled = [
      "grid-search"
      "random-search"
      "bayesian"
      "hyperband"
    ];
  };
  validation = {
    strategy = "kfold";
    folds = 5;
  };
}
```

**Configuration Options:**

- `name` (required): AutoML job name
- `namespace` (default: "automl"): Kubernetes namespace
- `objective` (required): Problem type (regression, classification, timeseries)
- `timeLimit`: Maximum search time in seconds
- `budget.maxTrials`: Maximum number of trials
- `budget.maxParallel`: Maximum parallel trials
- `algorithms.enabled`: List of search algorithms
- `validation.strategy`: Cross-validation strategy
- `validation.folds`: Number of folds

**Use Cases:**

- Automated model selection
- Hyperparameter optimization
- Baseline model generation
- Feature engineering automation
- Algorithm benchmarking

### mkModelRegistry

Deploys centralized model registry for model versioning and management.

```nix
mkModelRegistry {
  name = "model-registry";
  namespace = "model-registry";
  backend = "postgresql";
  host = "postgres.model-registry.svc";
  storage = {
    type = "s3";
    bucket = "model-artifacts";
    path = "/models";
  };
  ui = {
    enabled = true;
    replicas = 2;
    port = 8080;
  };
  versioning = {
    enabled = true;
    maxVersions = 10;
    retentionPolicy = "keep-last-n";
  };
}
```

**Configuration Options:**

- `name` (required): Registry name
- `namespace` (default: "model-registry"): Kubernetes namespace
- `backend`: Metadata backend (postgresql, mysql)
- `host`: Database hostname
- `storage.type`: Artifact storage (s3, gcs, local)
- `storage.bucket`: Storage bucket name
- `ui.enabled`: Enable registry UI
- `versioning.enabled`: Enable versioning
- `versioning.maxVersions`: Maximum versions to keep
- `validation.schemaValidation`: Enable schema validation
- `validation.codeSignature`: Enable code signing

**Use Cases:**

- Model versioning and rollback
- Model lineage tracking
- Team collaboration
- Model governance
- Production model management

### mkModelMonitoring

Configures comprehensive monitoring and drift detection for production models.

```nix
mkModelMonitoring {
  name = "production-monitoring";
  namespace = "ml-monitoring";
  enabled = true;
  metricsStorage = {
    type = "prometheus";
    retention = "30d";
  };
  driftDetection = {
    enabled = true;
    method = "kolmogorov-smirnov";
    threshold = 0.1;
    checkFrequency = "daily";
  };
  dataQuality = {
    enabled = true;
    checks = [
      "missing-values"
      "outliers"
      "distribution-shift"
      "schema-violations"
    ];
  };
  alerting = {
    enabled = true;
    rules = [
      "accuracy-drop"
      "latency-increase"
      "error-rate-spike"
      "data-drift"
    ];
  };
}
```

**Configuration Options:**

- `name` (required): Monitoring configuration name
- `namespace` (default: "ml-monitoring"): Kubernetes namespace
- `enabled` (default: true): Enable monitoring
- `metricsStorage.type`: Storage backend (prometheus, influxdb)
- `metricsStorage.retention`: Metrics retention period
- `driftDetection.enabled`: Enable drift detection
- `driftDetection.method`: Detection method (kolmogorov-smirnov, psi, js)
- `driftDetection.threshold`: Drift alert threshold
- `dataQuality.enabled`: Enable quality checks
- `dataQuality.checks`: List of quality checks
- `alerting.enabled`: Enable alerting
- `alerting.rules`: List of alert rules

**Use Cases:**

- Production model monitoring
- Data drift detection
- Performance degradation alerts
- Data quality tracking
- Model health dashboards

### mkJupyterNotebooks

Sets up managed Jupyter notebook environments for data scientists.

```nix
mkJupyterNotebooks {
  name = "data-science-lab";
  namespace = "notebooks";
  version = "1.5.0";
  storage = {
    size = "10Gi";
    storageClass = "standard";
    path = "/home/jovyan";
  };
  resources = {
    cpu = "1000m";
    memory = "2Gi";
    limits = {
      cpu = "2000m";
      memory = "4Gi";
    };
  };
  kernels = [
    "python3"
    "julia"
    "r"
  ];
  extensions = [
    "jupyterlab-git"
    "jupyterlab-variable-inspector"
    "jupyterlab-toc"
  ];
  gpu = {
    enabled = true;
    type = "nvidia";
  };
}
```

**Configuration Options:**

- `name` (required): Notebook environment name
- `namespace` (default: "notebooks"): Kubernetes namespace
- `version` (default: "1.5.0"): JupyterLab version
- `storage.size`: Persistent storage size
- `storage.storageClass`: Storage class name
- `storage.path`: Mount path
- `resources.cpu`: CPU request
- `resources.memory`: Memory request
- `kernels`: Available kernels
- `extensions`: JupyterLab extensions
- `auth.enabled`: Enable authentication
- `gpu.enabled`: Enable GPU support
- `gpu.type`: GPU type (nvidia, amd)

**Use Cases:**

- Interactive data exploration
- Model development
- Collaborative analysis
- Prototyping and experimentation
- Educational environments

## Integration Patterns

### End-to-End ML Workflow

```nix
let
  mlOps = import ./src/lib/ml-operations.nix { inherit lib; };
in {
  # Track experiments
  mlflow = mlOps.mkMLflowTracking {
    namespace = "ml-platform";
    trackingUri = "http://mlflow.ml-platform.svc:5000";
  };

  # Manage training data
  featureStore = mlOps.mkFeatureStore {
    name = "production-features";
    namespace = "ml-platform";
    type = "both";
  };

  # Run distributed training
  training = mlOps.mkDistributedTraining {
    name = "model-training";
    namespace = "ml-platform";
    framework = "pytorch";
    workers = 4;
  };

  # Serve production models
  serving = mlOps.mkSeldonCore {
    name = "production-model";
    namespace = "ml-platform";
    replicas = 3;
  };

  # Monitor in production
  monitoring = mlOps.mkModelMonitoring {
    name = "production-monitor";
    namespace = "ml-platform";
  };
}
```

### MLOps Platform Stack

```nix
let
  mlOps = import ./src/lib/ml-operations.nix { inherit lib; };
in {
  # Development environment
  notebooks = mlOps.mkJupyterNotebooks {
    name = "ds-notebooks";
    namespace = "ml-dev";
    gpu = { enabled = true; };
  };

  # Experiment tracking
  mlflow = mlOps.mkMLflowTracking {
    namespace = "ml-dev";
    trackingUri = "http://mlflow.ml-dev.svc:5000";
  };

  # Kubeflow pipelines
  pipelines = mlOps.mkKubeflowPipelines {
    namespace = "ml-dev";
    name = "kubeflow-pipelines";
  };

  # AutoML for quick iteration
  automl = mlOps.mkAutoML {
    name = "fast-iteration";
    namespace = "ml-dev";
    objective = "classification";
  };

  # Model registry
  registry = mlOps.mkModelRegistry {
    name = "model-registry";
    namespace = "ml-ops";
  };

  # Production serving
  serving = mlOps.mkKServeInference {
    name = "production-inference";
    namespace = "ml-prod";
  };

  # Production monitoring
  monitoring = mlOps.mkModelMonitoring {
    name = "prod-monitoring";
    namespace = "ml-prod";
  };
}
```

## Best Practices

### Model Development

1. **Version Control**: Track all experiments in MLflow
2. **Reproducibility**: Use fixed random seeds and dependencies
3. **Feature Management**: Centralize features in feature store
4. **Data Validation**: Implement data quality checks
5. **Model Cards**: Document model purpose and limitations

### Model Training

1. **Distributed Training**: Use for large datasets and models
2. **Resource Management**: Request appropriate CPU/GPU/memory
3. **Checkpointing**: Save intermediate model states
4. **Early Stopping**: Monitor validation metrics
5. **Hyperparameter Search**: Use systematic optimization

### Model Serving

1. **Production Readiness**: Test models before production
2. **Versioning**: Maintain model version history
3. **Load Testing**: Validate performance under load
4. **Gradual Rollout**: Use canary and blue-green deployments
5. **API Documentation**: Document model inputs/outputs

### Monitoring and Operations

1. **Baseline Metrics**: Establish production baselines
2. **Drift Monitoring**: Track data and prediction drift
3. **Alert Thresholds**: Set appropriate alert levels
4. **Retraining Pipeline**: Automate periodic retraining
5. **Incident Response**: Document response procedures

### Security and Compliance

1. **Access Control**: Restrict model and data access
2. **Audit Logging**: Track all model changes
3. **Encryption**: Encrypt data in transit and at rest
4. **Model Signatures**: Sign model artifacts
5. **Compliance**: Document compliance with standards

## Performance Considerations

### Training Performance

- **Multi-GPU Training**: Reduces training time significantly
- **Data Pipeline**: Optimize data loading and preprocessing
- **Batch Size**: Balance between memory and convergence
- **Communication Overhead**: Monitor gradient synchronization
- **Resource Utilization**: Monitor CPU and GPU utilization

### Inference Performance

- **Model Optimization**: Use quantization and pruning
- **Batch Inference**: Aggregate requests when possible
- **Caching**: Cache frequent predictions
- **Replica Scaling**: Use autoscaling for traffic spikes
- **Latency Targets**: Monitor end-to-end latency

### Monitoring Performance

- **Metric Storage**: Archive old metrics to cost-effective storage
- **Query Performance**: Optimize metric queries
- **Alert Evaluation**: Minimize alert latency
- **Storage Efficiency**: Compress historical data
- **Drift Detection**: Balance accuracy and computational cost

## Troubleshooting

### Training Failures

- Check resource requests vs. node capacity
- Verify data pipeline and input validation
- Monitor distributed training synchronization
- Check logs for specific errors
- Use monitoring to identify bottlenecks

### Serving Issues

- Monitor request latency and error rates
- Check model accuracy in production
- Verify data preprocessing correctness
- Monitor resource utilization
- Check dependent service availability

### Monitoring Gaps

- Verify metric collection is working
- Check storage space and retention
- Validate alert rules and thresholds
- Monitor monitoring system health
- Document known limitations

## Framework Version Support

- **Kubeflow**: 1.6+
- **Seldon Core**: 1.13+
- **MLflow**: 2.0+
- **KServe**: 0.9+
- **Feature Store**: Open Feature Store compatible

## Related Modules

- **API Gateway**: Expose ML models via APIs
- **Container Registry**: Manage ML model images
- **Secrets Management**: Secure ML credentials
- **Service Mesh**: Advanced routing for ML services
- **Performance Analysis**: Monitor ML system performance
- **Security Scanning**: Scan model artifacts
- **Disaster Recovery**: Backup ML models and data
- **Multi-Tenancy**: Isolate ML workloads by team

## Additional Resources

- [Kubeflow Documentation](https://www.kubeflow.org/docs/)
- [Seldon Core Guide](https://docs.seldon.io/)
- [MLflow Documentation](https://mlflow.org/docs/)
- [KServe Documentation](https://kserve.github.io/website/)
- [Kubernetes ML Patterns](https://kubernetes.io/docs/)
