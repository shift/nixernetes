# Batch Processing Module

## Overview

The Batch Processing module provides comprehensive builders for managing batch jobs, scheduled tasks, data pipelines, and workflow orchestration on Kubernetes. It abstracts away the complexity of configuring Kubernetes Jobs, CronJobs, and workflow engines, enabling developers to define sophisticated batch workloads with minimal configuration.

## Key Capabilities

### Workload Management
- Native Kubernetes Job execution with configurable retry policies
- Scheduled job execution using CronJobs
- Multi-step workflow orchestration with Argo Workflows
- Apache Airflow DAG deployment and management
- Spark distributed computing jobs
- Async job queue management with background workers

### Scheduling & Orchestration
- Flexible cron expression support
- Advanced scheduling policies (time windows, backoff strategies)
- Job dependency management and DAG construction
- Workflow templates with reusable components
- Parallel task execution with resource coordination

### Data Pipeline Features
- End-to-end data pipeline definitions
- Schema validation and data quality checks
- Source and destination connector management
- Transformation step configuration
- Error handling and retry mechanisms

### Monitoring & Observability
- Real-time job execution metrics
- Success/failure rate tracking
- Job duration and resource utilization monitoring
- Integration with Prometheus for metrics collection
- AlertManager integration for alerting on job failures

### Reliability & Recovery
- Automatic job retry with exponential backoff
- Backoff limit configuration
- Active deadline specifications
- Job completion tracking and cleanup policies
- Dead letter queue handling for failed jobs

## Core Builders

### mkKubernetesJob

Creates a native Kubernetes Job with configurable execution parameters.

```nix
batchProcessing.mkKubernetesJob "data-processor" {
  namespace = "batch";
  image = "python:3.11-slim";
  command = [ "python" "/app/processor.py" ];
  args = [ "--input-file" "/data/input.csv" ];
  
  # Execution configuration
  backoffLimit = 3;
  activeDeadlineSeconds = 3600;  # 1 hour timeout
  ttlSecondsAfterFinished = 86400;  # Delete after 24h
  
  # Resource limits
  resources = {
    limits = {
      cpu = "2";
      memory = "4Gi";
    };
    requests = {
      cpu = "1";
      memory = "2Gi";
    };
  };
  
  # Pod template configuration
  labels = { "batch.io/tier" = "processing"; };
  annotations = { "prometheus.io/scrape" = "true"; };
  
  # Volume mounts
  volumeMounts = {
    data = "/data";
    output = "/output";
  };
  
  # Environment variables
  environment = {
    LOG_LEVEL = "INFO";
    BATCH_SIZE = "1000";
  };
  
  # RestartPolicy
  restartPolicy = "Never";  # Never | OnFailure
  
  # Parallelism and completions
  parallelism = 1;
  completions = 1;
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace for job |
| image | string | required | Container image for job execution |
| command | list | [] | Container command |
| args | list | [] | Container command arguments |
| backoffLimit | int | 3 | Max retries before job is marked failed |
| activeDeadlineSeconds | int | null | Timeout for job execution |
| ttlSecondsAfterFinished | int | 86400 | Seconds before completed job is garbage collected |
| resources | object | {} | CPU and memory limits/requests |
| labels | object | {} | Pod labels |
| annotations | object | {} | Pod annotations |
| volumeMounts | object | {} | Volume mount mappings |
| environment | object | {} | Environment variables |
| restartPolicy | string | "Never" | Pod restart behavior |
| parallelism | int | 1 | Number of parallel pods |
| completions | int | 1 | Number of successful completions required |
| securityContext | object | {} | Pod security settings |
| imagePullSecrets | list | [] | Private registry credentials |

**Returns:** Kubernetes Job resource manifest

**Usage Examples:**

```nix
# Simple data processing job
mkKubernetesJob "daily-extract" {
  namespace = "etl";
  image = "etl:v1.2";
  command = [ "./run-extract.sh" ];
  backoffLimit = 2;
};

# Parallel processing job
mkKubernetesJob "batch-transform" {
  namespace = "etl";
  image = "transform-service:v2.0";
  parallelism = 4;
  completions = 4;
  resources = {
    requests = { cpu = "500m"; memory = "512Mi"; };
    limits = { cpu = "1"; memory = "1Gi"; };
  };
};

# Long-running computation with timeout
mkKubernetesJob "model-training" {
  namespace = "ml";
  image = "pytorch:gpu";
  command = [ "python" "train.py" ];
  activeDeadlineSeconds = 86400;  # 24 hour limit
  resources = {
    limits = { cpu = "4"; memory = "16Gi"; };
  };
};
```

### mkCronJob

Creates a scheduled Kubernetes CronJob with cron expression support.

```nix
batchProcessing.mkCronJob "hourly-sync" {
  namespace = "batch";
  schedule = "0 * * * *";  # Every hour
  
  # Job configuration
  jobTemplate = {
    spec = {
      backoffLimit = 2;
      activeDeadlineSeconds = 1800;
      template = {
        spec = {
          containers = [{
            name = "sync";
            image = "sync-service:v1.0";
            command = [ "sync-data" ];
            env = [ 
              { name = "SYNC_SOURCE"; value = "database"; }
              { name = "SYNC_DEST"; value = "cache"; }
            ];
          }];
          restartPolicy = "OnFailure";
        };
      };
    };
  };
  
  # Cron configuration
  timezone = "UTC";
  concurrencyPolicy = "Forbid";  # Forbid | Allow | Replace
  successfulJobsHistoryLimit = 3;
  failedJobsHistoryLimit = 5;
  startingDeadlineSeconds = 300;
  
  # Resource configuration
  labels = { "batch.io/frequency" = "hourly"; };
  annotations = { "description" = "Hourly data sync"; };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| schedule | string | required | Cron schedule expression |
| timezone | string | "UTC" | Timezone for schedule interpretation |
| concurrencyPolicy | string | "Allow" | How to handle concurrent executions |
| successfulJobsHistoryLimit | int | 3 | History retention for successful jobs |
| failedJobsHistoryLimit | int | 1 | History retention for failed jobs |
| startingDeadlineSeconds | int | 300 | Deadline for job start |
| jobTemplate | object | required | Job template specification |
| suspend | bool | false | Whether to suspend the cron schedule |
| labels | object | {} | CronJob labels |
| annotations | object | {} | CronJob annotations |

**Cron Schedule Examples:**

```
0 * * * *           # Every hour
0 0 * * *           # Daily at midnight
0 2 * * 0           # Weekly on Sunday at 2am
0 0 1 * *           # Monthly on 1st at midnight
0 */6 * * *         # Every 6 hours
0 9-17 * * 1-5      # Weekdays 9am-5pm
*/5 * * * *         # Every 5 minutes
```

**Returns:** Kubernetes CronJob resource manifest

**Usage Examples:**

```nix
# Daily backup job
mkCronJob "nightly-backup" {
  namespace = "backup";
  schedule = "0 2 * * *";  # 2am daily
  jobTemplate = {
    spec = {
      template.spec.containers = [{
        name = "backup";
        image = "postgres-backup:v1.0";
        env = [ { name = "BACKUP_DIR"; value = "/backups"; } ];
      }];
      template.spec.restartPolicy = "Never";
    };
  };
  successfulJobsHistoryLimit = 7;
  failedJobsHistoryLimit = 3;
};

# Weekly report generation
mkCronJob "weekly-report" {
  namespace = "reports";
  schedule = "0 0 * * 0";  # Sunday midnight
  concurrencyPolicy = "Forbid";
  jobTemplate = {
    spec = {
      activeDeadlineSeconds = 3600;
      template.spec.containers = [{
        name = "reporter";
        image = "report-gen:v2.0";
      }];
    };
  };
};

# Hourly health check
mkCronJob "health-check" {
  namespace = "monitoring";
  schedule = "0 * * * *";
  startingDeadlineSeconds = 60;
  jobTemplate = {
    spec = {
      template.spec.containers = [{
        name = "health";
        image = "health-checker:v1.0";
      }];
    };
  };
};
```

### mkAirflowDeployment

Deploys Apache Airflow with DAG management and scheduler configuration.

```nix
batchProcessing.mkAirflowDeployment "data-pipeline" {
  namespace = "airflow";
  
  # Airflow configuration
  version = "2.7";
  executor = "KubernetesExecutor";  # LocalExecutor | CeleryExecutor | KubernetesExecutor
  
  # Database configuration
  database = {
    type = "postgres";
    host = "postgres.default.svc.cluster.local";
    port = 5432;
    name = "airflow";
    secretRef = "airflow-db-secret";  # Secret with 'username' and 'password' keys
  };
  
  # UI configuration
  webserver = {
    replicas = 2;
    port = 8080;
    resources = {
      requests = { cpu = "500m"; memory = "512Mi"; };
      limits = { cpu = "1"; memory = "1Gi"; };
    };
    rbac = true;
  };
  
  # Scheduler configuration
  scheduler = {
    replicas = 2;
    dagsInterval = 30;  # Check for new DAGs every 30 seconds
    resources = {
      requests = { cpu = "250m"; memory = "256Mi"; };
      limits = { cpu = "500m"; memory = "512Mi"; };
    };
  };
  
  # Worker configuration (for CeleryExecutor)
  workers = {
    replicas = 3;
    resources = {
      requests = { cpu = "500m"; memory = "512Mi"; };
      limits = { cpu = "2"; memory = "2Gi"; };
    };
  };
  
  # DAG configuration
  dags = {
    volume = "dags-volume";
    path = "/opt/airflow/dags";
  };
  
  # Logging configuration
  logs = {
    volume = "logs-volume";
    path = "/opt/airflow/logs";
    level = "INFO";
  };
  
  # Configuration parameters
  config = {
    "core.load_examples" = false;
    "core.dags_are_paused_at_creation" = true;
    "scheduler.max_active_tasks_per_dag" = 16;
  };
  
  # Environment variables
  environment = {
    AIRFLOW_HOME = "/opt/airflow";
  };
  
  # Monitoring
  monitoring = {
    prometheus = true;
    statsd = false;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| version | string | "2.7" | Airflow version |
| executor | string | "LocalExecutor" | Task execution strategy |
| database | object | required | Database connection settings |
| webserver | object | {} | Web UI configuration |
| scheduler | object | {} | Scheduler configuration |
| workers | object | {} | Worker configuration |
| dags | object | {} | DAG storage configuration |
| logs | object | {} | Log storage configuration |
| config | object | {} | Airflow configuration parameters |
| environment | object | {} | Environment variables |
| monitoring | object | {} | Monitoring configuration |

**Returns:** Kubernetes resources for Airflow deployment

**Usage Examples:**

```nix
# Development Airflow setup
mkAirflowDeployment "dev-airflow" {
  namespace = "airflow-dev";
  executor = "LocalExecutor";
  database = {
    type = "postgres";
    host = "postgres.airflow-dev.svc.cluster.local";
    port = 5432;
    name = "airflow_dev";
    secretRef = "airflow-db-secret";
  };
  webserver = {
    replicas = 1;
    resources = {
      requests = { cpu = "250m"; memory = "256Mi"; };
    };
  };
};

# Production Airflow with HA
mkAirflowDeployment "prod-airflow" {
  namespace = "airflow-prod";
  executor = "KubernetesExecutor";
  database = {
    type = "postgres";
    host = "postgres-ha.airflow-prod.svc.cluster.local";
    port = 5432;
    name = "airflow_prod";
    secretRef = "airflow-db-secret";
  };
  webserver = {
    replicas = 3;
    resources = {
      requests = { cpu = "1"; memory = "1Gi"; };
      limits = { cpu = "2"; memory = "2Gi"; };
    };
  };
  scheduler = {
    replicas = 2;
    resources = {
      requests = { cpu = "500m"; memory = "512Mi"; };
      limits = { cpu = "1"; memory = "1Gi"; };
    };
  };
  monitoring = {
    prometheus = true;
    statsd = true;
  };
};
```

### mkArgoWorkflow

Creates an Argo Workflow for complex multi-step orchestration.

```nix
batchProcessing.mkArgoWorkflow "data-processing-flow" {
  namespace = "argo";
  
  # Workflow configuration
  serviceAccount = "argo";
  
  # Workflow entrypoint and templates
  spec = {
    entrypoint = "pipeline";
    
    templates = [
      # Pipeline template with DAG
      {
        name = "pipeline";
        dag = {
          tasks = [
            {
              name = "extract";
              template = "extract-task";
            }
            {
              name = "validate";
              template = "validate-task";
              depends = "extract";
            }
            {
              name = "transform";
              template = "transform-task";
              depends = "validate";
            }
            {
              name = "load";
              template = "load-task";
              depends = "transform";
            }
          ];
        };
      }
      
      # Individual task templates
      {
        name = "extract-task";
        container = {
          image = "extract:v1.0";
          command = [ "python" "extract.py" ];
          resources = {
            requests = { cpu = "500m"; memory = "512Mi"; };
          };
        };
      }
      
      {
        name = "validate-task";
        container = {
          image = "validate:v1.0";
          command = [ "python" "validate.py" ];
        };
      }
      
      {
        name = "transform-task";
        container = {
          image = "transform:v1.0";
          command = [ "python" "transform.py" ];
          resources = {
            requests = { cpu = "1"; memory = "2Gi"; };
            limits = { cpu = "2"; memory = "4Gi"; };
          };
        };
      }
      
      {
        name = "load-task";
        container = {
          image = "load:v1.0";
          command = [ "python" "load.py" ];
        };
      }
    ];
  };
  
  # Argo configuration
  activeDeadlineSeconds = 86400;
  ttlStrategy = {
    secondsAfterFinished = 86400;
  };
  
  # Labels and annotations
  labels = { "app.kubernetes.io/name" = "data-pipeline"; };
  annotations = { "description" = "ETL pipeline"; };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| serviceAccount | string | "default" | Service account for workflow |
| spec | object | required | Workflow specification |
| activeDeadlineSeconds | int | null | Workflow timeout |
| ttlStrategy | object | {} | Cleanup strategy for completed workflows |
| labels | object | {} | Workflow labels |
| annotations | object | {} | Workflow annotations |
| volumeClaims | list | [] | Persistent volume claims |
| arguments | object | {} | Workflow arguments |

**Returns:** Kubernetes Workflow resource manifest

**Usage Examples:**

```nix
# Simple sequential pipeline
mkArgoWorkflow "simple-pipeline" {
  namespace = "argo";
  spec = {
    entrypoint = "steps";
    templates = [
      {
        name = "steps";
        steps = [
          [ { name = "step1"; template = "task1"; } ]
          [ { name = "step2"; template = "task2"; } ]
        ];
      }
      {
        name = "task1";
        container = {
          image = "task1:v1.0";
        };
      }
      {
        name = "task2";
        container = {
          image = "task2:v1.0";
        };
      }
    ];
  };
};

# Parallel task execution
mkArgoWorkflow "parallel-pipeline" {
  namespace = "argo";
  spec = {
    entrypoint = "parallel";
    templates = [
      {
        name = "parallel";
        steps = [
          [
            { name = "parallel1"; template = "worker"; arguments.parameters = [{ name = "id"; value = "1"; }]; }
            { name = "parallel2"; template = "worker"; arguments.parameters = [{ name = "id"; value = "2"; }]; }
            { name = "parallel3"; template = "worker"; arguments.parameters = [{ name = "id"; value = "3"; }]; }
          ]
        ];
      }
      {
        name = "worker";
        inputs.parameters = [ { name = "id"; } ];
        container = {
          image = "worker:v1.0";
          args = [ "{{inputs.parameters.id}}" ];
        };
      }
    ];
  };
};
```

### mkSparkJob

Creates Apache Spark job configurations for distributed computing.

```nix
batchProcessing.mkSparkJob "data-analytics" {
  namespace = "spark";
  
  # Spark job configuration
  image = "spark:3.4-scala2.12";
  mainApplicationFile = "local:///opt/spark/jobs/analytics.jar";
  mainClass = "com.example.Analytics";
  
  # Application arguments
  arguments = [
    "--input-path"
    "s3://bucket/data"
    "--output-path"
    "s3://bucket/results"
  ];
  
  # Spark configuration
  sparkConf = {
    "spark.cores.max" = "8";
    "spark.executor.instances" = "4";
    "spark.executor.cores" = "2";
    "spark.executor.memory" = "4g";
    "spark.driver.memory" = "2g";
    "spark.driver.cores" = "1";
  };
  
  # Driver configuration
  driver = {
    cores = 1;
    memory = "2g";
    serviceAccount = "spark";
    
    resources = {
      limits = {
        cpu = "1";
        memory = "2Gi";
      };
      requests = {
        cpu = "500m";
        memory = "1Gi";
      };
    };
  };
  
  # Executor configuration
  executor = {
    cores = 2;
    instances = 4;
    memory = "4g";
    
    resources = {
      limits = {
        cpu = "2";
        memory = "4Gi";
      };
      requests = {
        cpu = "1";
        memory = "2Gi";
      };
    };
  };
  
  # Python support
  pythonVersion = "3";
  
  # Dependencies
  packages = [
    "com.google.cloud:google-cloud-bigquery-spark_2.12:0.31.0"
  ];
  
  # Monitoring
  monitoring = {
    exposeDriverMetrics = true;
    metricsPort = 4040;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| image | string | "spark:latest" | Spark Docker image |
| mainApplicationFile | string | required | Path to JAR or Python file |
| mainClass | string | "" | Main class for JAR files |
| arguments | list | [] | Application arguments |
| sparkConf | object | {} | Spark configuration |
| driver | object | required | Driver pod configuration |
| executor | object | required | Executor pod configuration |
| pythonVersion | string | "2" | Python version (if using PySpark) |
| packages | list | [] | Maven packages |
| monitoring | object | {} | Monitoring configuration |

**Returns:** Kubernetes SparkApplication resource manifest

**Usage Examples:**

```nix
# Scala/Java Spark job
mkSparkJob "spark-batch" {
  namespace = "spark";
  image = "spark:3.4";
  mainApplicationFile = "local:///opt/spark/jobs/batch.jar";
  mainClass = "com.example.BatchProcessor";
  arguments = [ "--mode" "batch" ];
  sparkConf = {
    "spark.cores.max" = "16";
    "spark.executor.instances" = "4";
  };
};

# PySpark job
mkSparkJob "pyspark-ml" {
  namespace = "spark";
  image = "spark:3.4-python";
  mainApplicationFile = "local:///opt/spark/jobs/ml_pipeline.py";
  pythonVersion = "3";
  arguments = [ "--model-path" "/models/latest" ];
  sparkConf = {
    "spark.sql.shuffle.partitions" = "200";
    "spark.dynamicAllocation.enabled" = "true";
  };
};
```

### mkJobQueue

Creates a job queue system for managing async workload distribution.

```nix
batchProcessing.mkJobQueue "background-tasks" {
  namespace = "queues";
  
  # Queue configuration
  queueName = "background-tasks";
  queueType = "rabbitmq";  # rabbitmq | kafka | sqs
  
  # Message broker settings
  broker = {
    host = "rabbitmq.queues.svc.cluster.local";
    port = 5672;
    vhost = "/";
    credentialSecret = "rabbitmq-credentials";
  };
  
  # Queue properties
  queue = {
    durable = true;
    exclusive = false;
    autoDelete = false;
    arguments = {
      "x-max-length" = 1000000;
      "x-message-ttl" = 86400000;  # 24 hours
    };
  };
  
  # Dead letter queue
  deadLetterQueue = {
    enabled = true;
    name = "background-tasks-dlq";
    exchange = "background-tasks-dlx";
    maxRetries = 3;
  };
  
  # Workers configuration
  workers = {
    replicas = 3;
    image = "background-worker:v1.0";
    concurrency = 5;  # Messages processed concurrently per worker
    
    resources = {
      limits = {
        cpu = "1";
        memory = "512Mi";
      };
      requests = {
        cpu = "250m";
        memory = "256Mi";
      };
    };
  };
  
  # Message configuration
  messages = {
    maxRetries = 3;
    retryBackoff = "exponential";
    retryDelay = 60;  # seconds
    timeout = 3600;  # seconds
  };
  
  # Monitoring
  monitoring = {
    prometheus = true;
    metricsPort = 9090;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| queueName | string | required | Queue name |
| queueType | string | "rabbitmq" | Message broker type |
| broker | object | required | Broker connection settings |
| queue | object | {} | Queue properties |
| deadLetterQueue | object | {} | DLQ configuration |
| workers | object | required | Worker deployment config |
| messages | object | {} | Message handling configuration |
| monitoring | object | {} | Monitoring configuration |

**Returns:** Kubernetes resources for job queue system

**Usage Examples:**

```nix
# RabbitMQ queue with 3 workers
mkJobQueue "email-queue" {
  namespace = "services";
  queueName = "email-tasks";
  queueType = "rabbitmq";
  broker = {
    host = "rabbitmq.services.svc.cluster.local";
    port = 5672;
    vhost = "/";
    credentialSecret = "rabbitmq-creds";
  };
  workers = {
    replicas = 3;
    image = "email-sender:v2.0";
    concurrency = 10;
    resources = {
      requests = { cpu = "200m"; memory = "128Mi"; };
    };
  };
};

# Kafka queue with DLQ
mkJobQueue "event-processing" {
  namespace = "events";
  queueName = "events-topic";
  queueType = "kafka";
  broker = {
    host = "kafka.events.svc.cluster.local";
    port = 9092;
    credentialSecret = "kafka-creds";
  };
  deadLetterQueue = {
    enabled = true;
    name = "events-dlq";
    maxRetries = 5;
  };
  workers = {
    replicas = 5;
    image = "event-processor:v1.0";
    concurrency = 3;
    resources = {
      requests = { cpu = "500m"; memory = "512Mi"; };
      limits = { cpu = "1"; memory = "1Gi"; };
    };
  };
};
```

### mkBatchJobConfig

Creates reusable batch job configurations with templating support.

```nix
batchProcessing.mkBatchJobConfig "etl-job-template" {
  # Template metadata
  description = "Base ETL job template";
  version = "1.0";
  
  # Default image configuration
  image = {
    repository = "etl-service";
    tag = "latest";
    pullPolicy = "IfNotPresent";
  };
  
  # Default resources
  resources = {
    default = {
      limits = {
        cpu = "2";
        memory = "2Gi";
      };
      requests = {
        cpu = "500m";
        memory = "512Mi";
      };
    };
    small = {
      limits = {
        cpu = "500m";
        memory = "512Mi";
      };
      requests = {
        cpu = "100m";
        memory = "128Mi";
      };
    };
    large = {
      limits = {
        cpu = "4";
        memory = "8Gi";
      };
      requests = {
        cpu = "2";
        memory = "4Gi";
      };
    };
  };
  
  # Default environment
  environment = {
    LOG_LEVEL = "INFO";
    BATCH_SIZE = "1000";
  };
  
  # Default retry policy
  retryPolicy = {
    maxAttempts = 3;
    backoffMultiplier = 2;
    initialDelaySeconds = 60;
    maxDelaySeconds = 3600;
  };
  
  # Default timeout
  timeout = 3600;  # 1 hour
  
  # Volume templates
  volumes = {
    data = {
      type = "emptyDir";  # emptyDir | persistentVolumeClaim
      sizeLimit = "10Gi";
    };
    cache = {
      type = "emptyDir";
    };
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| description | string | "" | Template description |
| version | string | "1.0" | Template version |
| image | object | {} | Default image settings |
| resources | object | {} | Resource presets |
| environment | object | {} | Default environment variables |
| retryPolicy | object | {} | Retry configuration |
| timeout | int | 3600 | Default timeout in seconds |
| volumes | object | {} | Volume templates |

**Returns:** Batch job configuration template

**Usage Examples:**

```nix
# Define reusable template
let
  etlTemplate = mkBatchJobConfig "etl-template" {
    image = { repository = "etl"; tag = "v2.0"; };
    resources.default = {
      requests = { cpu = "1"; memory = "1Gi"; };
    };
    environment = {
      LOG_LEVEL = "INFO";
      RETRY_COUNT = "3";
    };
  };
in
{
  # Use template for specific job
  dailyJob = mkKubernetesJob "daily-etl" {
    inherit (etlTemplate) image resources environment;
    command = [ "python" "daily.py" ];
  };
}
```

### mkWorkflowTemplate

Creates reusable Argo Workflow templates for multi-step pipelines.

```nix
batchProcessing.mkWorkflowTemplate "data-pipeline-template" {
  namespace = "argo";
  
  # Template definition
  spec = {
    entrypoint = "main";
    
    # Template arguments
    arguments = {
      parameters = [
        { name = "input-path"; default = "/data/input"; }
        { name = "output-path"; default = "/data/output"; }
        { name = "parallel-tasks"; default = "4"; }
      ];
    };
    
    templates = [
      {
        name = "main";
        dag = {
          tasks = [
            {
              name = "process";
              template = "process-step";
              arguments.parameters = [
                { name = "input"; value = "{{workflow.parameters.input-path}}"; }
                { name = "output"; value = "{{workflow.parameters.output-path}}"; }
              ];
            }
            {
              name = "validate";
              template = "validate-step";
              depends = "process";
            }
          ];
        };
      }
      
      {
        name = "process-step";
        inputs.parameters = [ { name = "input"; } { name = "output"; } ];
        container = {
          image = "processor:v1.0";
          args = [ "{{inputs.parameters.input}}" "{{inputs.parameters.output}}" ];
        };
      }
      
      {
        name = "validate-step";
        container = {
          image = "validator:v1.0";
        };
      }
    ];
  };
  
  # Template configuration
  ttlStrategy = {
    secondsAfterFinished = 86400;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| spec | object | required | Workflow specification |
| ttlStrategy | object | {} | Cleanup strategy |
| labels | object | {} | Template labels |
| annotations | object | {} | Template annotations |

**Returns:** Kubernetes WorkflowTemplate resource manifest

**Usage Examples:**

```nix
# Create reusable template and use it
let
  template = mkWorkflowTemplate "etl-template" {
    namespace = "argo";
    spec = {
      entrypoint = "etl";
      templates = [ /* template definitions */ ];
    };
  };
  
  # Reference template in workflow
  workflow = mkArgoWorkflow "my-etl" {
    namespace = "argo";
    spec.entrypoint = "etl";
    spec.templates = template.spec.templates;
  };
in
{ inherit template workflow; }
```

### mkBatchMonitoring

Configures monitoring and alerting for batch jobs.

```nix
batchProcessing.mkBatchMonitoring "batch-monitoring" {
  namespace = "monitoring";
  
  # Monitoring scrape configuration
  scrape = {
    interval = 30;  # seconds
    timeout = 10;
  };
  
  # Job success metrics
  jobSuccessMetrics = {
    enabled = true;
    recordInterval = 60;
  };
  
  # Job duration tracking
  jobDurationTracking = {
    enabled = true;
    buckets = [ 60 300 600 1800 3600 ];  # seconds
  };
  
  # Resource utilization metrics
  resourceMetrics = {
    trackCpuUsage = true;
    trackMemoryUsage = true;
    trackDiskUsage = true;
  };
  
  # Alerting rules
  alerts = {
    jobFailures = {
      enabled = true;
      threshold = 3;
      timeWindow = 300;  # 5 minutes
      severity = "warning";
    };
    
    jobTimeout = {
      enabled = true;
      severity = "critical";
    };
    
    jobResourcesExceeded = {
      enabled = true;
      cpuThreshold = 95;
      memoryThreshold = 95;
      severity = "warning";
    };
  };
  
  # Grafana dashboards
  dashboards = {
    enabled = true;
    includeJobSuccess = true;
    includeJobDuration = true;
    includeResourceUtilization = true;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| scrape | object | {} | Scrape configuration |
| jobSuccessMetrics | object | {} | Success metric settings |
| jobDurationTracking | object | {} | Duration tracking config |
| resourceMetrics | object | {} | Resource metric settings |
| alerts | object | {} | Alert rule configuration |
| dashboards | object | {} | Grafana dashboard settings |

**Returns:** Monitoring configuration resources

**Usage Examples:**

```nix
# Comprehensive batch monitoring
mkBatchMonitoring "prod-monitoring" {
  namespace = "monitoring";
  scrape.interval = 15;
  alerts.jobFailures = {
    enabled = true;
    threshold = 2;
    severity = "critical";
  };
  dashboards.enabled = true;
};
```

### mkDataPipeline

Orchestrates end-to-end data pipelines with source, transformation, and destination stages.

```nix
batchProcessing.mkDataPipeline "customer-analytics" {
  namespace = "data-pipelines";
  
  # Pipeline metadata
  description = "Customer analytics data pipeline";
  owner = "analytics-team";
  
  # Schedule
  schedule = "0 2 * * *";  # Daily at 2am
  
  # Source configuration
  source = {
    type = "database";  # database | api | s3 | kafka
    connector = "postgresql";
    
    config = {
      host = "postgres.data.svc.cluster.local";
      port = 5432;
      database = "production";
      query = ''
        SELECT * FROM customers 
        WHERE updated_at > @last_run_time
      '';
      secretRef = "source-db-credentials";
    };
  };
  
  # Transformation stages
  transformations = [
    {
      name = "cleanup";
      type = "spark";
      image = "spark-jobs:v1.0";
      mainClass = "com.example.Cleanup";
      config = {
        removeNulls = true;
        deduplicateBy = [ "customer_id" ];
      };
    }
    {
      name = "enrich";
      type = "python";
      image = "enrichment-service:v1.0";
      script = "enrich.py";
      config = {
        lookupService = "enrichment-api:8080";
      };
    }
    {
      name = "validate";
      type = "dbt";
      image = "dbt:1.5";
      models = [ "customers_staging" ];
      config = {
        testQueries = true;
      };
    }
  ];
  
  # Destination configuration
  destination = {
    type = "warehouse";  # warehouse | api | database | s3
    connector = "snowflake";
    
    config = {
      account = "xy12345.us-east-1";
      database = "analytics";
      schema = "customers";
      table = "customers_processed";
      secretRef = "snowflake-credentials";
      mode = "upsert";
    };
  };
  
  # Quality checks
  qualityChecks = {
    enabled = true;
    checks = [
      {
        name = "record-count";
        type = "row-count";
        minRows = 1000;
        maxRows = 10000000;
      }
      {
        name = "duplicate-check";
        type = "uniqueness";
        columns = [ "customer_id" ];
      }
      {
        name = "null-check";
        type = "not-null";
        columns = [ "customer_id" "email" ];
      }
    ];
  };
  
  # Error handling
  errorHandling = {
    onFailure = "dlq";  # dlq | retry | abort
    maxRetries = 3;
    retryDelay = 300;
  };
  
  # Monitoring
  monitoring = {
    enabled = true;
    trackRecordCounts = true;
    trackExecutionTime = true;
    trackDataQuality = true;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| description | string | "" | Pipeline description |
| owner | string | "" | Pipeline owner |
| schedule | string | required | Cron schedule |
| source | object | required | Source configuration |
| transformations | list | [] | Transformation stages |
| destination | object | required | Destination configuration |
| qualityChecks | object | {} | Data quality validation |
| errorHandling | object | {} | Error handling strategy |
| monitoring | object | {} | Monitoring configuration |

**Returns:** Kubernetes resources for data pipeline

**Usage Examples:**

```nix
# Simple ETL pipeline
mkDataPipeline "simple-etl" {
  namespace = "etl";
  schedule = "0 * * * *";  # Hourly
  source = {
    type = "api";
    connector = "rest";
    config.url = "https://api.example.com/data";
  };
  transformations = [
    {
      name = "parse";
      type = "python";
      image = "parser:v1.0";
    }
  ];
  destination = {
    type = "database";
    connector = "postgresql";
    config = {
      host = "postgres.default.svc.cluster.local";
      database = "dwh";
      table = "raw_events";
    };
  };
};

# Complex data warehouse pipeline
mkDataPipeline "warehouse-etl" {
  namespace = "data-warehouse";
  schedule = "0 3 * * *";
  source = {
    type = "database";
    connector = "postgresql";
    config.query = "SELECT * FROM production_db.transactions";
  };
  transformations = [
    {
      name = "stage";
      type = "dbt";
      models = [ "transactions_stg" ];
    }
    {
      name = "transform";
      type = "dbt";
      models = [ "transactions_fct" "customer_dim" ];
    }
  ];
  destination = {
    type = "warehouse";
    connector = "snowflake";
    config.table = "transactions";
  };
  qualityChecks.enabled = true;
};
```

## Integration Patterns

### Kubernetes Jobs with ConfigMaps

Pass configuration to batch jobs via ConfigMaps:

```nix
let
  config = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata.name = "job-config";
    metadata.namespace = "batch";
    data = {
      "config.json" = builtins.toJSON {
        batchSize = 1000;
        timeout = 3600;
      };
    };
  };
  
  job = mkKubernetesJob "data-job" {
    namespace = "batch";
    image = "processor:v1.0";
    volumeMounts.config = "/etc/config";
    # ConfigMap mounted as volume
  };
in
{ inherit config job; }
```

### CronJob with Secret Management

Securely pass credentials to scheduled jobs:

```nix
mkCronJob "secure-sync" {
  namespace = "batch";
  schedule = "0 * * * *";
  jobTemplate.spec.template.spec = {
    serviceAccountName = "batch-service-account";
    containers = [{
      name = "sync";
      image = "sync:v1.0";
      envFrom = [{
        secretRef.name = "sync-credentials";
      }];
    }];
    restartPolicy = "OnFailure";
  };
}
```

### Multi-Stage Pipeline with Argo Workflows

Chain multiple jobs with Argo Workflows:

```nix
mkArgoWorkflow "multi-stage" {
  namespace = "argo";
  spec = {
    entrypoint = "pipeline";
    templates = [
      {
        name = "pipeline";
        dag.tasks = [
          { name = "extract"; template = "extract"; }
          { name = "validate"; template = "validate"; depends = "extract"; }
          { name = "load"; template = "load"; depends = "validate"; }
        ];
      }
      # Template definitions...
    ];
  };
}
```

## Best Practices

### Resource Management

1. **Always specify resource requests and limits** to ensure proper scheduling
2. **Use appropriate backoffLimit** values (typically 2-5 for production)
3. **Set activeDeadlineSeconds** to prevent runaway jobs
4. **Configure ttlSecondsAfterFinished** to clean up completed jobs

### Scheduling

1. **Use time windows** for CronJobs to avoid peak load times
2. **Implement exponential backoff** for retry policies
3. **Set concurrencyPolicy to "Forbid"** for critical jobs to prevent overlaps
4. **Monitor job duration** to detect performance regressions

### Data Pipelines

1. **Implement schema validation** at each stage
2. **Use dead letter queues** for failed messages
3. **Track data lineage** for compliance and debugging
4. **Validate data quality** before loading to destination

### Error Handling

1. **Distinguish between retryable and fatal errors**
2. **Log all errors with context** for debugging
3. **Implement circuit breakers** for external service calls
4. **Use dead letter queues** for unprocessable messages

### Monitoring

1. **Track key metrics**: success rate, duration, resource utilization
2. **Set up alerts** for job failures and timeouts
3. **Create dashboards** for pipeline health visibility
4. **Implement distributed tracing** for multi-step pipelines

## Performance Considerations

### Job Parallelism

- **Start with small parallelism** (1-2) and increase gradually
- **Monitor cluster resources** to avoid overwhelming nodes
- **Use Pod Disruption Budgets** to maintain minimum availability

### Memory and CPU

- **Profile jobs locally** to determine actual resource needs
- **Allocate 20-30% overhead** beyond measured consumption
- **Monitor actual usage** and adjust allocation over time
- **Use VPA for optimization** in production

### Network Considerations

- **Batch network requests** to reduce overhead
- **Use connection pooling** for database connections
- **Implement request deduplication** for idempotency
- **Monitor network latency** for remote data sources

## Troubleshooting Guide

### Job Not Scheduling

**Symptoms:** Job created but pods not starting

**Diagnostics:**
```bash
# Check job status
kubectl get job job-name -n namespace

# View events
kubectl describe job job-name -n namespace

# Check resource availability
kubectl top nodes
kubectl describe nodes
```

**Solutions:**
- Increase cluster resources
- Reduce job resource requests
- Check node selectors and affinity rules

### Job Timeout

**Symptoms:** Job killed after activeDeadlineSeconds

**Diagnostics:**
```bash
# Check job status reason
kubectl get job -o wide job-name -n namespace

# View pod logs
kubectl logs -n namespace pod-name
```

**Solutions:**
- Increase activeDeadlineSeconds
- Optimize job logic for performance
- Break into smaller parallel jobs

### High Memory Usage

**Symptoms:** Container killed with OOMKilled

**Diagnostics:**
```bash
# Check resource usage
kubectl top pod pod-name -n namespace

# View memory metrics
kubectl get events --sort-by='.lastTimestamp'
```

**Solutions:**
- Increase memory limit
- Optimize memory usage in job logic
- Process data in smaller batches

### Job Hangs

**Symptoms:** Job stuck without completion or failure

**Diagnostics:**
```bash
# Check pod state
kubectl get pod -o yaml pod-name -n namespace

# View recent logs
kubectl logs pod-name -n namespace --tail=100
```

**Solutions:**
- Set shorter activeDeadlineSeconds
- Add timeout logic in job code
- Check for deadlocks or infinite loops

## Related Modules

- **DATABASE_MANAGEMENT**: Database backups and maintenance jobs
- **EVENT_PROCESSING**: Real-time stream processing pipelines
- **MONITORING**: Job health and performance monitoring
- **MULTI_TIER_DEPLOYMENT**: Complex application deployments

## References

- [Kubernetes Job Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/job/)
- [Kubernetes CronJob Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/)
- [Argo Workflows Documentation](https://argoproj.github.io/argo-workflows/)
- [Apache Airflow Documentation](https://airflow.apache.org/)
- [Apache Spark Documentation](https://spark.apache.org/docs/)
