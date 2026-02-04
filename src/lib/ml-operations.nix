# Nixernetes ML Operations Module
# Enterprise machine learning and AI/ML workload management for Kubernetes
# Supports Kubeflow, Seldon Core, MLflow, KServe, and other ML frameworks

{ lib }:

let
  inherit (lib) attrValues filterAttrs mapAttrs mkDefault mkIf mkMerge types;

  # Framework metadata
  framework = {
    name = "ml-operations";
    version = "1.0.0";
    description = "Enterprise ML/AI operations and model management";
    features = [
      "Kubeflow pipelines and components"
      "Seldon Core model serving"
      "MLflow experiment tracking"
      "KServe inference services"
      "Model training orchestration"
      "Distributed training support"
      "Model versioning and registry"
      "A/B testing and canary deployments"
      "Model monitoring and drift detection"
      "Feature store integration"
      "AutoML capabilities"
      "Jupyter notebook management"
    ];
  };

  # Helper function to generate framework labels
  mkFrameworkLabels = {
    "nixernetes.io/framework" = "ml-operations";
    "nixernetes.io/ml-type" = "machine-learning";
    "app.kubernetes.io/component" = "ml-operations";
  };

  # Validation helpers
  validateKubeflowConfig = config:
    assert lib.assertMsg (config.name != null) "Kubeflow configuration requires name";
    assert lib.assertMsg (config.namespace != null) "Kubeflow configuration requires namespace";
    config;

  validateSeldonConfig = config:
    assert lib.assertMsg (config.name != null) "Seldon configuration requires name";
    assert lib.assertMsg (config.models != null) "Seldon configuration requires models";
    config;

  validateMLflowConfig = config:
    assert lib.assertMsg (config.namespace != null) "MLflow configuration requires namespace";
    assert lib.assertMsg (config.trackingUri != null) "MLflow configuration requires trackingUri";
    config;

  validateKServeConfig = config:
    assert lib.assertMsg (config.name != null) "KServe configuration requires name";
    assert lib.assertMsg (config.predictor != null) "KServe configuration requires predictor";
    config;

  validateFeatureStoreConfig = config:
    assert lib.assertMsg (config.name != null) "Feature store configuration requires name";
    assert lib.assertMsg (config.type != null) "Feature store configuration requires type (offline/online/both)";
    config;

  validateAutoMLConfig = config:
    assert lib.assertMsg (config.name != null) "AutoML configuration requires name";
    assert lib.assertMsg (config.objective != null) "AutoML configuration requires objective";
    config;

in {
  inherit framework;

  # Builder 1: Kubeflow Pipelines and Components
  mkKubeflowPipelines = config: validateKubeflowConfig (
    let
      cfg = {
        name = null;
        namespace = "kubeflow";
        version = "1.8.0";
        storage = {
          backend = "minio"; # minio, s3, gcs
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
      } // config;
    in {
      apiVersion = "v1";
      kind = "Namespace";
      metadata = {
        name = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/ml-framework" = "kubeflow";
        };
      };
    } // (mkIf cfg.ui.enabled {
      spec = {
        kubeflow = {
          pipelines = {
            version = cfg.version;
            storage = cfg.storage;
            metadata = cfg.metadata;
            ui = cfg.ui;
            logging = cfg.logging;
          };
        };
      };
    })
  );

  # Builder 2: Seldon Core Model Serving
  mkSeldonCore = config: validateSeldonConfig (
    let
      cfg = {
        name = null;
        namespace = "seldon";
        version = "1.15.0";
        models = null;
        replicas = 3;
        resources = {
          cpu = "500m";
          memory = "512Mi";
          limits = {
            cpu = "1000m";
            memory = "1Gi";
          };
        };
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
        logging = {
          enabled = true;
          level = "info";
        };
      } // config;
    in {
      apiVersion = "machinelearning.seldon.io/v1";
      kind = "SeldonDeployment";
      metadata = {
        name = cfg.name;
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/ml-framework" = "seldon-core";
          "nixernetes.io/serving-type" = "model-serving";
        };
      };
      spec = {
        replicas = cfg.replicas;
        predictors = cfg.models;
      };
    }
  );

  # Builder 3: MLflow Tracking and Registry
  mkMLflowTracking = config: validateMLflowConfig (
    let
      cfg = {
        namespace = null;
        version = "2.0.0";
        trackingUri = null;
        backend = {
          type = "postgresql"; # postgresql, mysql, sqlite
          host = "postgres-mlflow.mlflow.svc";
          port = 5432;
          username = "mlflow";
          database = "mlflow";
        };
        artifactStore = {
          type = "s3"; # s3, gcs, azure, local
          bucket = "mlflow-artifacts";
          path = "/mlflow";
        };
        ui = {
          enabled = true;
          replicas = 2;
          port = 5000;
          resources = {
            cpu = "250m";
            memory = "256Mi";
          };
        };
        auth = {
          enabled = false;
          type = "oidc";
        };
      } // config;
    in {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "mlflow-config";
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/ml-framework" = "mlflow";
          "nixernetes.io/tracking-type" = "experiment-tracking";
        };
      };
      data = {
        MLFLOW_TRACKING_URI = cfg.trackingUri;
        BACKEND_TYPE = cfg.backend.type;
        ARTIFACT_STORE = cfg.artifactStore.type;
        ARTIFACT_BUCKET = cfg.artifactStore.bucket;
      };
    }
  );

  # Builder 4: KServe Inference Services
  mkKServeInference = config: validateKServeConfig (
    let
      cfg = {
        name = null;
        namespace = "kserve";
        predictor = null;
        transformer = null;
        explainer = null;
        canaryTraffic = null;
        minReplicas = 1;
        maxReplicas = 10;
        resources = {
          cpu = "500m";
          memory = "512Mi";
          limits = {
            cpu = "1000m";
            memory = "1Gi";
          };
        };
        logging = {
          enabled = true;
          level = "info";
        };
      } // config;
    in {
      apiVersion = "serving.kserve.io/v1beta1";
      kind = "InferenceService";
      metadata = {
        name = cfg.name;
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/ml-framework" = "kserve";
          "nixernetes.io/serving-type" = "inference";
        };
      };
      spec = {
        predictor = cfg.predictor;
        transformer = cfg.transformer;
        explainer = cfg.explainer;
      };
    }
  );

  # Builder 5: Feature Store Integration
  mkFeatureStore = config: validateFeatureStoreConfig (
    let
      cfg = {
        name = null;
        namespace = "feature-store";
        type = null; # offline, online, both
        backend = {
          offline = "s3"; # s3, gcs, hive
          online = "redis"; # redis, cassandra, postgresql
        };
        storage = {
          path = "/features";
          format = "parquet";
          retention = 90; # days
        };
        registry = {
          enabled = true;
          type = "postgres"; # postgres, hive, snowflake
        };
        monitoring = {
          enabled = true;
          dataQuality = true;
          driftDetection = true;
        };
      } // config;
    in {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "${cfg.name}-config";
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/ml-framework" = "feature-store";
          "nixernetes.io/feature-type" = cfg.type;
        };
      };
      data = {
        FEATURE_STORE_TYPE = cfg.type;
        OFFLINE_STORE = cfg.backend.offline;
        ONLINE_STORE = cfg.backend.online;
        FEATURE_RETENTION_DAYS = builtins.toString cfg.storage.retention;
      };
    }
  );

  # Builder 6: Distributed Training Configuration
  mkDistributedTraining = config:
    let
      cfg = {
        name = null;
        namespace = "ml-training";
        framework = "tensorflow"; # tensorflow, pytorch, horovod
        workers = 4;
        parameterServers = 2;
        gpuPerWorker = 1;
        cpuPerWorker = 4;
        memoryPerWorker = "8Gi";
        resources = {
          limits = {
            cpu = "4000m";
            memory = "8Gi";
            "nvidia.com/gpu" = 1;
          };
        };
        networking = {
          backend = "horovod"; # horovod, mpi, nccl
          communicationBackend = "nccl";
        };
        monitoring = {
          enabled = true;
          tensorboard = true;
        };
      } // config;
    in {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "${cfg.name}-training-config";
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/ml-framework" = "distributed-training";
          "nixernetes.io/training-type" = cfg.framework;
        };
      };
      data = {
        FRAMEWORK = cfg.framework;
        NUM_WORKERS = builtins.toString cfg.workers;
        NUM_PS = builtins.toString cfg.parameterServers;
        GPU_PER_WORKER = builtins.toString cfg.gpuPerWorker;
        BACKEND = cfg.networking.backend;
      };
    };

  # Builder 7: AutoML Pipeline
  mkAutoML = config: validateAutoMLConfig (
    let
      cfg = {
        name = null;
        namespace = "automl";
        objective = null; # regression, classification, timeseries
        timeLimit = 3600; # seconds
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
        preprocessors = {
          scaling = true;
          encoding = true;
          featureSelection = true;
        };
        validation = {
          strategy = "kfold"; # kfold, stratified, timeseries
          folds = 5;
        };
      } // config;
    in {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "${cfg.name}-automl-config";
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/ml-framework" = "automl";
          "nixernetes.io/automl-objective" = cfg.objective;
        };
      };
      data = {
        OBJECTIVE = cfg.objective;
        TIME_LIMIT = builtins.toString cfg.timeLimit;
        MAX_TRIALS = builtins.toString cfg.budget.maxTrials;
        MAX_PARALLEL = builtins.toString cfg.budget.maxParallel;
        VALIDATION_STRATEGY = cfg.validation.strategy;
      };
    }
  );

  # Builder 8: Model Registry and Versioning
  mkModelRegistry = config:
    let
      cfg = {
        name = null;
        namespace = "model-registry";
        backend = "postgresql"; # postgresql, mysql
        host = "postgres.model-registry.svc";
        port = 5432;
        database = "model_registry";
        storage = {
          type = "s3"; # s3, gcs, local
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
        validation = {
          schemaValidation = true;
          codeSignature = true;
        };
      } // config;
    in {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "${cfg.name}-registry-config";
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/ml-framework" = "model-registry";
          "nixernetes.io/registry-type" = "model-management";
        };
      };
      data = {
        REGISTRY_BACKEND = cfg.backend;
        STORAGE_TYPE = cfg.storage.type;
        STORAGE_BUCKET = cfg.storage.bucket;
        MAX_VERSIONS = builtins.toString cfg.versioning.maxVersions;
      };
    };

  # Builder 9: Model Monitoring and Drift Detection
  mkModelMonitoring = config:
    let
      cfg = {
        name = null;
        namespace = "ml-monitoring";
        enabled = true;
        metricsStorage = {
          type = "prometheus"; # prometheus, influxdb
          retention = "30d";
        };
        driftDetection = {
          enabled = true;
          method = "kolmogorov-smirnov"; # kolmogorov-smirnov, psi, js
          threshold = 0.1;
          checkFrequency = "daily"; # hourly, daily, weekly
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
      } // config;
    in {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "${cfg.name}-monitoring-config";
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/ml-framework" = "model-monitoring";
          "nixernetes.io/monitoring-type" = "production";
        };
      };
      data = {
        DRIFT_DETECTION_ENABLED = builtins.toString cfg.driftDetection.enabled;
        DRIFT_METHOD = cfg.driftDetection.method;
        DRIFT_THRESHOLD = builtins.toString cfg.driftDetection.threshold;
        DATA_QUALITY_ENABLED = builtins.toString cfg.dataQuality.enabled;
      };
    };

  # Builder 10: Jupyter Notebook Environment
  mkJupyterNotebooks = config:
    let
      cfg = {
        name = null;
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
        auth = {
          enabled = true;
          type = "oauth"; # oauth, ldap, local
        };
        gpu = {
          enabled = false;
          type = "nvidia"; # nvidia, amd
        };
      } // config;
    in {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "${cfg.name}-jupyter-config";
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/ml-framework" = "jupyter";
          "nixernetes.io/notebook-type" = "development";
        };
      };
      data = {
        JUPYTER_VERSION = cfg.version;
        STORAGE_SIZE = cfg.storage.size;
        DEFAULT_KERNELS = lib.concatStringsSep "," cfg.kernels;
        GPU_ENABLED = builtins.toString cfg.gpu.enabled;
      };
    };

  # Validation function
  validateMLOpsConfig = config: config;

  # Framework metadata
  mkFramework = {
    name = framework.name;
    version = framework.version;
    description = framework.description;
    features = framework.features;
  };
}
