# Example 4: Machine Learning Pipeline

Deploy a complete ML workflow with Jupyter notebooks, TensorFlow training, model versioning, and batch inference.

## Overview

This example demonstrates:
- Jupyter Lab for interactive development and experimentation
- TensorFlow for model training
- PostgreSQL for metadata and results storage
- MinIO for model artifact storage
- MLflow for experiment tracking and model registry
- Batch job processing for training and inference
- Resource requests for GPU workloads (optional)

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Data Scientists                      │
└────────────────┬────────────────────────────────────────┘
                 │
        ┌────────▼────────────┐
        │   Jupyter Lab       │
        │   (Experimentation) │
        └────────┬────────────┘
                 │
    ┌────────────┼────────────────┐
    │            │                │
┌───▼──┐    ┌────▼─────┐    ┌────▼──┐
│MinIO │    │PostgreSQL │    │MLflow │
│Model │    │(Metadata) │    │(Track)│
│Store │    └───────────┘    └───┬───┘
└──┬───┘                          │
   │         ┌──────────────────┬─┘
   │         │                  │
┌──▼──────────┼──────┐    ┌──────▼──────┐
│Training Job │      │    │Inference Job│
│(TensorFlow) │      │    │(Batch)      │
└─────────────┘      │    └─────────────┘
                     │
                ┌────▼──────┐
                │ Results DB │
                └────────────┘
```

## Configuration

Create `ml-pipeline.nix`:

```nix
{ nixernetes, pkgs }:

let
  modules = nixernetes.modules;
in

{
  # PostgreSQL for Metadata and Results
  postgres = modules.database.postgresql {
    name = "ml-postgres";
    namespace = "default";
    version = "15-alpine";
    resources = {
      requests = { memory = "512Mi"; cpu = "250m"; };
      limits = { memory = "1Gi"; cpu = "1000m"; };
    };
    persistence = {
      size = "20Gi";
      storageClass = "fast-ssd";
    };
    backupSchedule = "0 2 * * *";
  };

  # MinIO Object Storage for Models
  minio = modules.storage.objectstorage {
    name = "ml-minio";
    namespace = "default";
    version = "latest";
    replicas = 3;
    resources = {
      requests = { memory = "256Mi"; cpu = "100m"; };
      limits = { memory = "512Mi"; cpu = "500m"; };
    };
    persistence = {
      size = "50Gi";
      storageClass = "fast-ssd";
    };
    credentials = {
      accessKey = "minioadmin";
      secretKey = "minioadmin";
    };
  };

  # Jupyter Lab for Development
  jupyter = modules.workload.statefulset {
    name = "jupyter-lab";
    namespace = "default";
    replicas = 1;
    
    containers = [{
      name = "jupyter";
      image = "jupyter/datascience-notebook:latest";
      ports = [{ name = "http"; containerPort = 8888; }];
      
      env = [
        { name = "JUPYTER_ENABLE_LAB"; value = "yes"; }
        { name = "POSTGRES_HOST"; value = "ml-postgres"; }
        { name = "POSTGRES_DB"; value = "ml_workspace"; }
        { name = "MINIO_ENDPOINT"; value = "ml-minio:9000"; }
        { name = "MINIO_ACCESS_KEY"; value = "minioadmin"; }
        { name = "MINIO_SECRET_KEY"; value = "minioadmin"; }
        { name = "MLFLOW_TRACKING_URI"; value = "http://mlflow:5000"; }
      ];

      resources = {
        requests = { memory = "2Gi"; cpu = "1000m"; };
        limits = { memory = "4Gi"; cpu = "2000m"; };
      };

      volumeMounts = [
        { name = "notebooks"; mountPath = "/home/jovyan/work"; }
        { name = "data"; mountPath = "/home/jovyan/data"; }
      ];
    }];

    volumeClaimTemplates = [
      {
        metadata = { name = "notebooks"; };
        spec = {
          accessModes = ["ReadWriteOnce"];
          storageClassName = "fast-ssd";
          resources = { requests = { storage = "10Gi"; }; };
        };
      }
      {
        metadata = { name = "data"; };
        spec = {
          accessModes = ["ReadWriteOnce"];
          storageClassName = "standard";
          resources = { requests = { storage = "50Gi"; }; };
        };
      }
    ];
  };

  # MLflow Tracking Server
  mlflow = modules.workload.deployment {
    name = "mlflow";
    namespace = "default";
    image = "ghcr.io/mlflow/mlflow:latest";
    replicas = 1;
    
    containers = [{
      name = "mlflow";
      image = "ghcr.io/mlflow/mlflow:latest";
      ports = [{ name = "http"; containerPort = 5000; }];
      
      args = [
        "mlflow"
        "server"
        "--backend-store-uri"
        "postgresql://user:password@ml-postgres:5432/mlflow"
        "--default-artifact-root"
        "s3://mlflow/artifacts"
        "--host"
        "0.0.0.0"
      ];

      env = [
        { name = "AWS_ACCESS_KEY_ID"; value = "minioadmin"; }
        { name = "AWS_SECRET_ACCESS_KEY"; value = "minioadmin"; }
        { name = "MLFLOW_S3_ENDPOINT_URL"; value = "http://ml-minio:9000"; }
      ];

      resources = {
        requests = { memory = "256Mi"; cpu = "100m"; };
        limits = { memory = "512Mi"; cpu = "500m"; };
      };
    }];
  };

  # Training Job (CronJob for scheduled training)
  trainingJob = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = { name = "ml-training-job"; namespace = "default"; };
    spec = {
      schedule = "0 2 * * *";  # 2 AM daily
      jobTemplate = {
        spec = {
          template = {
            spec = {
              containers = [{
                name = "trainer";
                image = "tensorflow/tensorflow:latest-gpu";
                command = ["/bin/bash" "-c"];
                args = ["python /ml/train.py"];
                
                env = [
                  { name = "POSTGRES_HOST"; value = "ml-postgres"; }
                  { name = "MINIO_ENDPOINT"; value = "ml-minio:9000"; }
                  { name = "MLFLOW_TRACKING_URI"; value = "http://mlflow:5000"; }
                  { name = "CUDA_VISIBLE_DEVICES"; value = "0"; }
                ];

                resources = {
                  requests = { memory = "4Gi"; cpu = "2000m"; "nvidia.com/gpu" = "1"; };
                  limits = { memory = "8Gi"; cpu = "4000m"; "nvidia.com/gpu" = "1"; };
                };

                volumeMounts = [
                  { name = "training-script"; mountPath = "/ml"; }
                  { name = "data"; mountPath = "/data"; }
                ];
              }];

              volumes = [
                {
                  name = "training-script";
                  configMap = {
                    name = "ml-training-script";
                    defaultMode = 0o755;
                  };
                }
                {
                  name = "data";
                  persistentVolumeClaim = { claimName = "ml-training-data"; };
                }
              ];

              restartPolicy = "OnFailure";
            };
          };
        };
      };
    };
  };

  # Inference Job (Batch processing)
  inferenceJob = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = { name = "ml-inference-job"; namespace = "default"; };
    spec = {
      parallelism = 4;
      completions = 4;
      template = {
        spec = {
          containers = [{
            name = "inferencer";
            image = "tensorflow/tensorflow:latest";
            command = ["/bin/bash" "-c"];
            args = ["python /ml/infer.py"];
            
            env = [
              { name = "POSTGRES_HOST"; value = "ml-postgres"; }
              { name = "MINIO_ENDPOINT"; value = "ml-minio:9000"; }
              { name = "JOB_INDEX"; valueFrom = { fieldRef = { fieldPath = "metadata.annotations['batch.kubernetes.io/job-completion-index']"; }; }; }
            ];

            resources = {
              requests = { memory = "2Gi"; cpu = "1000m"; };
              limits = { memory = "4Gi"; cpu = "2000m"; };
            };

            volumeMounts = [
              { name = "inference-script"; mountPath = "/ml"; }
              { name = "results"; mountPath = "/results"; }
            ];
          }];

          volumes = [
            {
              name = "inference-script";
              configMap = {
                name = "ml-inference-script";
                defaultMode = 0o755;
              };
            }
            {
              name = "results";
              persistentVolumeClaim = { claimName = "ml-results"; };
            }
          ];

          restartPolicy = "Never";
        };
      };
    };
  };

  # ConfigMap for training script
  trainingScript = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = { name = "ml-training-script"; namespace = "default"; };
    data = {
      "train.py" = ''
        import os
        import tensorflow as tf
        import mlflow
        import psycopg2
        from minio import Minio

        # Initialize clients
        mlflow.set_tracking_uri(os.environ['MLFLOW_TRACKING_URI'])
        postgres = psycopg2.connect(
          host=os.environ['POSTGRES_HOST'],
          database='ml_workspace',
          user='user',
          password='password'
        )
        minio = Minio(
          os.environ['MINIO_ENDPOINT'].split(':')[0],
          access_key='minioadmin',
          secret_key='minioadmin'
        )

        # Load data
        (x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data()
        x_train = x_train.astype('float32') / 255
        x_test = x_test.astype('float32') / 255

        with mlflow.start_run():
          # Log parameters
          mlflow.log_param('epochs', 10)
          mlflow.log_param('batch_size', 128)

          # Build model
          model = tf.keras.Sequential([
            tf.keras.layers.Flatten(input_shape=(28, 28)),
            tf.keras.layers.Dense(128, activation='relu'),
            tf.keras.layers.Dropout(0.2),
            tf.keras.layers.Dense(10, activation='softmax')
          ])

          model.compile(
            optimizer='adam',
            loss='sparse_categorical_crossentropy',
            metrics=['accuracy']
          )

          # Train model
          history = model.fit(x_train, y_train, epochs=10, batch_size=128, validation_split=0.2)

          # Evaluate
          test_loss, test_acc = model.evaluate(x_test, y_test)
          mlflow.log_metric('test_accuracy', test_acc)

          # Save model
          model.save('/tmp/model.h5')
          minio.fput_object('models', 'mnist-model.h5', '/tmp/model.h5')

          # Save metadata
          cursor = postgres.cursor()
          cursor.execute("""
            INSERT INTO training_runs (model_name, test_accuracy, timestamp)
            VALUES (%s, %s, NOW())
          """, ('mnist', test_acc))
          postgres.commit()

        print("Training complete!")
      '';
    };
  };

  # ConfigMap for inference script
  inferenceScript = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = { name = "ml-inference-script"; namespace = "default"; };
    data = {
      "infer.py" = ''
        import os
        import tensorflow as tf
        import numpy as np
        from minio import Minio
        import psycopg2

        # Initialize clients
        minio = Minio(
          os.environ['MINIO_ENDPOINT'].split(':')[0],
          access_key='minioadmin',
          secret_key='minioadmin'
        )
        postgres = psycopg2.connect(
          host=os.environ['POSTGRES_HOST'],
          database='ml_workspace',
          user='user',
          password='password'
        )

        # Load model
        minio.fget_object('models', 'mnist-model.h5', '/tmp/model.h5')
        model = tf.keras.models.load_model('/tmp/model.h5')

        # Generate dummy predictions (in production, load real data)
        x_test = np.random.rand(100, 28, 28).astype('float32')

        # Make predictions
        predictions = model.predict(x_test)
        predicted_classes = np.argmax(predictions, axis=1)

        # Save results
        cursor = postgres.cursor()
        for i, pred in enumerate(predicted_classes):
          cursor.execute("""
            INSERT INTO predictions (image_id, predicted_class, confidence, timestamp)
            VALUES (%s, %s, %s, NOW())
          """, (i, int(pred), float(np.max(predictions[i]))))

        postgres.commit()
        print(f"Inference complete! Processed 100 samples.")
      '';
    };
  };

  # Persistent Volume Claims
  trainingDataPVC = {
    apiVersion = "v1";
    kind = "PersistentVolumeClaim";
    metadata = { name = "ml-training-data"; namespace = "default"; };
    spec = {
      accessModes = ["ReadWriteOnce"];
      storageClassName = "standard";
      resources = { requests = { storage = "100Gi"; }; };
    };
  };

  resultsPVC = {
    apiVersion = "v1";
    kind = "PersistentVolumeClaim";
    metadata = { name = "ml-results"; namespace = "default"; };
    spec = {
      accessModes = ["ReadWriteMany"];
      storageClassName = "standard";
      resources = { requests = { storage = "50Gi"; }; };
    };
  };

  # Services
  jupyterService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "jupyter-lab"; namespace = "default"; };
    spec = {
      type = "LoadBalancer";
      selector = { app = "jupyter-lab"; };
      ports = [{ name = "http"; port = 8888; targetPort = 8888; }];
    };
  };

  mlflowService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "mlflow"; namespace = "default"; };
    spec = {
      type = "ClusterIP";
      selector = { app = "mlflow"; };
      ports = [{ name = "http"; port = 5000; targetPort = 5000; }];
    };
  };

  minioService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "ml-minio"; namespace = "default"; };
    spec = {
      type = "ClusterIP";
      selector = { app = "ml-minio"; };
      ports = [
        { name = "api"; port = 9000; targetPort = 9000; }
        { name = "console"; port = 9001; targetPort = 9001; }
      ];
    };
  };
}
```

## Step-by-Step Deployment

### 1. Prepare the Environment

```bash
# Create project
mkdir my-ml-pipeline
cd my-ml-pipeline

# Create flake.nix
cat > flake.nix << 'EOF'
{
  description = "ML Pipeline with Nixernetes";
  
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    nixernetes.url = "github:nixernetes/nixernetes";
  };

  outputs = { self, nixpkgs, flake-utils, nixernetes }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
        buildInputs = with nixpkgs.legacyPackages.${system}; [
          kubectl
          python311
          python311Packages.tensorflow
          python311Packages.mlflow
          python311Packages.psycopg2
          python311Packages.minio
        ];
      };
    });
}
EOF

nix flake update
```

### 2. Deploy the Infrastructure

```bash
nix develop
cp ml-pipeline.nix config.nix
nix eval --apply "builtins.toJSON" -f config.nix > manifests.json
kubectl apply -f manifests.json
```

### 3. Access Jupyter Lab

```bash
# Get external IP
kubectl get svc jupyter-lab

# Port-forward for local access
kubectl port-forward svc/jupyter-lab 8888:8888

# Access at http://localhost:8888
# Get token from logs
kubectl logs pod/jupyter-lab-0
```

### 4. Monitor Training

```bash
# Watch training job
kubectl get cronjob
kubectl get job

# View training logs
kubectl logs job/ml-training-job-xxx

# Access MLflow UI
kubectl port-forward svc/mlflow 5000:5000
# http://localhost:5000
```

## Notebook Example

Create a notebook in Jupyter Lab:

```python
import tensorflow as tf
import mlflow
import pandas as pd
from minio import Minio

# Initialize MLflow
mlflow.set_experiment('mnist')

# Load MNIST data
(x_train, y_train), (x_test, y_test) = tf.keras.datasets.mnist.load_data()
x_train = x_train.astype('float32') / 255
x_test = x_test.astype('float32') / 255

# Define model
model = tf.keras.Sequential([
    tf.keras.layers.Flatten(input_shape=(28, 28)),
    tf.keras.layers.Dense(128, activation='relu'),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.Dense(64, activation='relu'),
    tf.keras.layers.Dropout(0.2),
    tf.keras.layers.Dense(10, activation='softmax')
])

model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
    loss='sparse_categorical_crossentropy',
    metrics=['accuracy']
)

# Train with MLflow tracking
with mlflow.start_run():
    mlflow.log_param('optimizer', 'adam')
    mlflow.log_param('learning_rate', 0.001)
    mlflow.log_param('epochs', 10)
    
    history = model.fit(
        x_train, y_train,
        epochs=10,
        batch_size=128,
        validation_split=0.2,
        verbose=1
    )
    
    # Evaluate
    test_loss, test_acc = model.evaluate(x_test, y_test)
    mlflow.log_metric('test_accuracy', test_acc)
    mlflow.log_metric('test_loss', test_loss)
    
    # Register model
    mlflow.keras.log_model(model, 'model')

print(f"Training complete! Test accuracy: {test_acc:.3f}")
```

## Running Inference

```bash
# Trigger inference job
kubectl apply -f inference-job.yaml

# Monitor
kubectl get job -w

# View results
kubectl logs job/ml-inference-job-xxx
```

## Troubleshooting

### GPU Support Issues

```bash
# Check GPU availability
kubectl describe nodes
# Should show nvidia.com/gpu in allocatable

# Check pod GPU access
kubectl exec -it pod/ml-training-job-xxx -- nvidia-smi

# Install GPU plugin if needed
kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/master/nvidia-device-plugin.yml
```

### Storage Issues

```bash
# Check PVC status
kubectl get pvc

# Check MinIO connectivity
kubectl exec -it pod/jupyter-lab-0 -- bash
mc ls minio/models

# Check database connectivity
kubectl exec -it pod/ml-postgres-0 -- psql -U user -d ml_workspace
```

### Training Job Failures

```bash
# View job status
kubectl describe job ml-training-job-xxx

# View logs
kubectl logs job/ml-training-job-xxx

# Check resource availability
kubectl top nodes
kubectl top pods
```

## Production Considerations

### 1. Resource Allocation
- Use GPU node pools for training
- Set CPU/memory limits appropriately
- Use node affinity to schedule workloads

### 2. Data Management
- Use persistent volumes for large datasets
- Implement data versioning
- Backup training results

### 3. Model Registry
- Use MLflow Model Registry for versioning
- Implement model validation
- Track model lineage

### 4. Monitoring
- Monitor training metrics in MLflow
- Set up alerts for failed jobs
- Track resource utilization

### 5. Security
- Use secrets for database credentials
- Implement RBAC for cluster access
- Encrypt stored models and data

## Advanced Patterns

### Hyperparameter Tuning

```python
from optuna import create_study
from optuna.samplers import TPESampler

def objective(trial):
    learning_rate = trial.suggest_float('lr', 1e-4, 1e-2)
    batch_size = trial.suggest_int('batch_size', 32, 256)
    
    model = build_model(learning_rate)
    history = model.fit(x_train, y_train, batch_size=batch_size, epochs=10)
    
    return history.history['val_accuracy'][-1]

study = create_study(sampler=TPESampler())
study.optimize(objective, n_trials=20)
```

### Distributed Training

```python
strategy = tf.distribute.MirroredStrategy()

with strategy.scope():
    model = tf.keras.Sequential([...])
    model.compile(...)

model.fit(x_train, y_train, epochs=10)
```

## Next Steps

1. Implement automated model testing and validation
2. Set up A/B testing pipeline for model deployment
3. Create model serving endpoints with TensorFlow Serving
4. Implement feature store for data management
5. Set up automated retraining triggers

## Support

- See [MLflow Documentation](https://mlflow.org/docs/latest/)
- Review [TensorFlow Documentation](https://www.tensorflow.org/docs)
- Check [PostgreSQL Module Docs](../../MODULE_REFERENCE.md#database-management)
