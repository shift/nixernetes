# ML Operations Module Examples
# 18 production-ready ML platform configurations

{ lib }:

let
  mlOps = import ../lib/ml-operations.nix { inherit lib; };
in {
  # Example 1: Basic Kubeflow Pipelines setup
  kubeflowBasic = mlOps.mkKubeflowPipelines {
    name = "kubeflow-pipelines";
    namespace = "kubeflow";
    version = "1.8.0";
  };

  # Example 2: Production Kubeflow with S3 backend
  kubeflowProduction = mlOps.mkKubeflowPipelines {
    name = "kubeflow-pipelines";
    namespace = "kubeflow";
    version = "1.8.0";
    storage = {
      backend = "s3";
      bucket = "org-kubeflow-artifacts";
      path = "/pipelines";
      retentionDays = 90;
    };
    metadata = {
      database = "postgresql";
      host = "postgres.kubeflow.svc";
      port = 5432;
      username = "mlpipeline";
    };
    ui = {
      enabled = true;
      replicas = 3;
      resources = {
        cpu = "1000m";
        memory = "1Gi";
      };
    };
  };

  # Example 3: Basic Seldon Core deployment
  seldonBasic = mlOps.mkSeldonCore {
    name = "iris-model";
    namespace = "seldon";
    models = [
      {
        name = "classifier";
        type = "sklearn";
        uri = "docker.io/seldon/mock_classifier:latest";
      }
    ];
    replicas = 2;
  };

  # Example 4: Production Seldon with autoscaling
  seldonProduction = mlOps.mkSeldonCore {
    name = "production-models";
    namespace = "seldon";
    version = "1.15.0";
    models = [
      {
        name = "primary-classifier";
        type = "pytorch";
        uri = "s3://models/classifier:v2.1";
      }
      {
        name = "fallback-classifier";
        type = "sklearn";
        uri = "s3://models/classifier:v1.9";
      }
    ];
    replicas = 5;
    resources = {
      cpu = "2000m";
      memory = "2Gi";
      limits = {
        cpu = "4000m";
        memory = "4Gi";
      };
    };
    autoscaling = {
      enabled = true;
      minReplicas = 3;
      maxReplicas = 20;
      targetCPUUtilization = 70;
    };
    monitoring = {
      enabled = true;
      prometheus = true;
    };
  };

  # Example 5: Basic MLflow tracking
  mlflowBasic = mlOps.mkMLflowTracking {
    namespace = "mlflow";
    trackingUri = "http://mlflow.mlflow.svc:5000";
  };

  # Example 6: Production MLflow with PostgreSQL
  mlflowProduction = mlOps.mkMLflowTracking {
    namespace = "mlflow";
    version = "2.0.0";
    trackingUri = "http://mlflow-prod.mlflow.svc:5000";
    backend = {
      type = "postgresql";
      host = "postgres.mlflow.svc";
      port = 5432;
      username = "mlflow";
      database = "mlflow_prod";
    };
    artifactStore = {
      type = "s3";
      bucket = "org-mlflow-artifacts";
      path = "/experiments";
    };
    ui = {
      enabled = true;
      replicas = 3;
      port = 5000;
      resources = {
        cpu = "500m";
        memory = "512Mi";
      };
    };
    auth = {
      enabled = true;
      type = "oidc";
    };
  };

  # Example 7: Basic KServe inference
  kserveBasic = mlOps.mkKServeInference {
    name = "iris-predictor";
    namespace = "kserve";
    predictor = {
      spec = {
        containers = [
          {
            name = "iris";
            image = "kserve/sklearn-model:latest";
            ports = [{ containerPort = 8080; }];
          }
        ];
      };
    };
  };

  # Example 8: Production KServe with transformers
  kserveProduction = mlOps.mkKServeInference {
    name = "nlp-inference";
    namespace = "kserve";
    predictor = {
      spec = {
        containers = [
          {
            name = "bert-model";
            image = "s3://models/bert:v1";
            ports = [{ containerPort = 8080; }];
            resources = {
              requests = {
                cpu = "2000m";
                memory = "4Gi";
              };
              limits = {
                cpu = "4000m";
                memory = "8Gi";
              };
            };
          }
        ];
      };
    };
    transformer = {
      spec = {
        containers = [
          {
            name = "feature-transformer";
            image = "transformers:v1";
            ports = [{ containerPort = 8080; }];
          }
        ];
      };
    };
    minReplicas = 2;
    maxReplicas = 10;
  };

  # Example 9: Feature store - offline only
  featureStoreOffline = mlOps.mkFeatureStore {
    name = "offline-features";
    namespace = "feature-store";
    type = "offline";
    backend = {
      offline = "s3";
    };
    storage = {
      path = "/features";
      format = "parquet";
      retention = 180;
    };
  };

  # Example 10: Feature store - online and offline
  featureStoreHybrid = mlOps.mkFeatureStore {
    name = "hybrid-features";
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
  };

  # Example 11: Distributed TensorFlow training
  distributedTensorFlow = mlOps.mkDistributedTraining {
    name = "tf-training";
    namespace = "ml-training";
    framework = "tensorflow";
    workers = 8;
    parameterServers = 2;
    gpuPerWorker = 2;
    cpuPerWorker = 8;
    memoryPerWorker = "32Gi";
    networking = {
      backend = "horovod";
      communicationBackend = "nccl";
    };
  };

  # Example 12: Distributed PyTorch training
  distributedPyTorch = mlOps.mkDistributedTraining {
    name = "pytorch-training";
    namespace = "ml-training";
    framework = "pytorch";
    workers = 4;
    parameterServers = 0;
    gpuPerWorker = 4;
    cpuPerWorker = 16;
    memoryPerWorker = "64Gi";
    networking = {
      backend = "nccl";
      communicationBackend = "nccl";
    };
    monitoring = {
      enabled = true;
      tensorboard = true;
    };
  };

  # Example 13: Basic AutoML
  automlBasic = mlOps.mkAutoML {
    name = "quick-ml";
    namespace = "automl";
    objective = "classification";
    timeLimit = 1800;
  };

  # Example 14: Production AutoML
  automlProduction = mlOps.mkAutoML {
    name = "comprehensive-search";
    namespace = "automl";
    objective = "regression";
    timeLimit = 86400;
    budget = {
      maxTrials = 500;
      maxParallel = 20;
    };
    algorithms = {
      enabled = [
        "grid-search"
        "random-search"
        "bayesian"
        "hyperband"
        "evolutionary"
      ];
    };
    preprocessors = {
      scaling = true;
      encoding = true;
      featureSelection = true;
    };
    validation = {
      strategy = "timeseries";
      folds = 5;
    };
  };

  # Example 15: Model registry with versioning
  modelRegistry = mlOps.mkModelRegistry {
    name = "model-registry";
    namespace = "model-registry";
    backend = "postgresql";
    host = "postgres.model-registry.svc";
    port = 5432;
    database = "model_registry";
    storage = {
      type = "s3";
      bucket = "org-model-artifacts";
      path = "/models";
    };
    ui = {
      enabled = true;
      replicas = 2;
      port = 8080;
    };
    versioning = {
      enabled = true;
      maxVersions = 20;
      retentionPolicy = "keep-last-n";
    };
    validation = {
      schemaValidation = true;
      codeSignature = true;
    };
  };

  # Example 16: Production model monitoring
  modelMonitoring = mlOps.mkModelMonitoring {
    name = "prod-monitoring";
    namespace = "ml-monitoring";
    enabled = true;
    metricsStorage = {
      type = "prometheus";
      retention = "90d";
    };
    driftDetection = {
      enabled = true;
      method = "kolmogorov-smirnov";
      threshold = 0.15;
      checkFrequency = "hourly";
    };
    dataQuality = {
      enabled = true;
      checks = [
        "missing-values"
        "outliers"
        "distribution-shift"
        "schema-violations"
        "type-errors"
        "range-violations"
      ];
    };
    alerting = {
      enabled = true;
      rules = [
        "accuracy-drop"
        "latency-increase"
        "error-rate-spike"
        "data-drift"
        "distribution-shift"
        "missing-data"
      ];
    };
  };

  # Example 17: Development Jupyter notebooks
  jupyterDev = mlOps.mkJupyterNotebooks {
    name = "data-science-lab";
    namespace = "notebooks";
    version = "1.5.0";
    storage = {
      size = "20Gi";
      storageClass = "standard";
      path = "/home/jovyan";
    };
    resources = {
      cpu = "2000m";
      memory = "4Gi";
      limits = {
        cpu = "4000m";
        memory = "8Gi";
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
      "jupyterlab-execute-time"
    ];
    auth = {
      enabled = true;
      type = "oauth";
    };
  };

  # Example 18: GPU-enabled Jupyter notebooks
  jupyterGPU = mlOps.mkJupyterNotebooks {
    name = "gpu-research-lab";
    namespace = "notebooks";
    version = "1.5.0";
    storage = {
      size = "100Gi";
      storageClass = "fast-ssd";
      path = "/home/jovyan";
    };
    resources = {
      cpu = "8000m";
      memory = "32Gi";
      limits = {
        cpu = "16000m";
        memory = "64Gi";
      };
    };
    kernels = [
      "python3"
      "julia"
    ];
    extensions = [
      "jupyterlab-git"
      "jupyterlab-variable-inspector"
      "jupyterlab-toc"
      "jupyterlab-system-monitor"
      "jupyterlab-execute-time"
    ];
    auth = {
      enabled = true;
      type = "oauth";
    };
    gpu = {
      enabled = true;
      type = "nvidia";
    };
  };
}
