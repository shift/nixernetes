# Batch Processing Examples
#
# This file contains 18+ production-ready configuration examples for the batch-processing module.
# Examples include basic and production Kubernetes Jobs, CronJobs, Airflow deployments,
# Argo Workflows, Spark jobs, and complete data pipeline configurations.

{ lib, ... }:

{
  # Example 1: Basic Kubernetes Job
  basicKubernetesJob = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "simple-job";
      namespace = "default";
    };
    spec = {
      template = {
        spec = {
          containers = [{
            name = "job";
            image = "busybox:latest";
            command = [ "sh" "-c" "echo 'Hello, World!' && sleep 10" ];
          }];
          restartPolicy = "Never";
        };
      };
    };
  };

  # Example 2: Production Kubernetes Job with resource limits
  productionKubernetesJob = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "production-processor";
      namespace = "batch";
      labels = {
        "app.kubernetes.io/name" = "processor";
        "app.kubernetes.io/version" = "1.0.0";
        "app.kubernetes.io/component" = "batch";
      };
    };
    spec = {
      backoffLimit = 3;
      activeDeadlineSeconds = 3600;
      ttlSecondsAfterFinished = 86400;
      parallelism = 1;
      completions = 1;
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "processor";
          };
        };
        spec = {
          serviceAccountName = "batch-processor";
          securityContext = {
            runAsNonRoot = true;
            runAsUser = 1000;
            fsGroup = 2000;
          };
          
          containers = [{
            name = "processor";
            image = "etl-processor:v1.2.0";
            imagePullPolicy = "IfNotPresent";
            
            command = [ "python" "-m" "processor" ];
            args = [
              "--input-path"
              "s3://bucket/input"
              "--output-path"
              "s3://bucket/output"
              "--batch-size"
              "5000"
            ];
            
            env = [
              { name = "LOG_LEVEL"; value = "INFO"; }
              { name = "WORKERS"; value = "4"; }
              {
                name = "AWS_ACCESS_KEY_ID";
                valueFrom.secretKeyRef = {
                  name = "aws-credentials";
                  key = "access-key";
                };
              }
              {
                name = "AWS_SECRET_ACCESS_KEY";
                valueFrom.secretKeyRef = {
                  name = "aws-credentials";
                  key = "secret-key";
                };
              }
            ];
            
            resources = {
              requests = {
                cpu = "1000m";
                memory = "2Gi";
              };
              limits = {
                cpu = "2000m";
                memory = "4Gi";
              };
            };
            
            securityContext = {
              allowPrivilegeEscalation = false;
              readOnlyRootFilesystem = false;
              capabilities.drop = [ "ALL" ];
            };
            
            volumeMounts = [
              { name = "data"; mountPath = "/data"; }
              { name = "tmp"; mountPath = "/tmp"; }
            ];
          }];
          
          volumes = [
            {
              name = "data";
              emptyDir = {
                sizeLimit = "10Gi";
              };
            }
            {
              name = "tmp";
              emptyDir = {};
            }
          ];
          
          restartPolicy = "Never";
          imagePullSecrets = [{ name = "registry-credentials"; }];
        };
      };
    };
  };

  # Example 3: Daily CronJob
  dailyCronJob = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "daily-backup";
      namespace = "backup";
    };
    spec = {
      schedule = "0 2 * * *";  # 2am daily
      timezone = "UTC";
      concurrencyPolicy = "Forbid";
      successfulJobsHistoryLimit = 7;
      failedJobsHistoryLimit = 3;
      startingDeadlineSeconds = 300;
      
      jobTemplate = {
        spec = {
          backoffLimit = 2;
          activeDeadlineSeconds = 1800;
          
          template = {
            spec = {
              serviceAccountName = "backup-job";
              
              containers = [{
                name = "backup";
                image = "postgres-backup:v2.0";
                
                env = [
                  { name = "PGHOST"; value = "postgres.database.svc.cluster.local"; }
                  { name = "PGPORT"; value = "5432"; }
                  { name = "PGDATABASE"; value = "production"; }
                  {
                    name = "PGPASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "postgres-credentials";
                      key = "password";
                    };
                  }
                  { name = "BACKUP_PATH"; value = "/backups"; }
                  { name = "RETENTION_DAYS"; value = "30"; }
                ];
                
                resources = {
                  requests = {
                    cpu = "500m";
                    memory = "512Mi";
                  };
                  limits = {
                    cpu = "1";
                    memory = "1Gi";
                  };
                };
                
                volumeMounts = [
                  { name = "backup-storage"; mountPath = "/backups"; }
                ];
              }];
              
              volumes = [
                {
                  name = "backup-storage";
                  persistentVolumeClaim = {
                    claimName = "backup-pvc";
                  };
                }
              ];
              
              restartPolicy = "OnFailure";
            };
          };
        };
      };
    };
  };

  # Example 4: Hourly CronJob with status checks
  hourlyStatusCheckJob = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "hourly-health-check";
      namespace = "monitoring";
      labels = {
        "app.kubernetes.io/name" = "health-check";
      };
    };
    spec = {
      schedule = "0 * * * *";
      timezone = "UTC";
      concurrencyPolicy = "Allow";
      successfulJobsHistoryLimit = 3;
      failedJobsHistoryLimit = 5;
      
      jobTemplate = {
        spec = {
          activeDeadlineSeconds = 600;
          
          template = {
            spec = {
              containers = [{
                name = "health-check";
                image = "health-checker:v1.0";
                
                command = [ "health-check" ];
                args = [
                  "--endpoints"
                  "https://api.example.com"
                  "--timeout"
                  "30"
                ];
                
                resources = {
                  requests = {
                    cpu = "100m";
                    memory = "64Mi";
                  };
                  limits = {
                    cpu = "500m";
                    memory = "256Mi";
                  };
                };
              }];
              
              restartPolicy = "OnFailure";
            };
          };
        };
      };
    };
  };

  # Example 5: Weekly CronJob with notification
  weeklyReportJob = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "weekly-report";
      namespace = "reporting";
    };
    spec = {
      schedule = "0 0 * * 0";  # Sunday midnight
      timezone = "America/New_York";
      concurrencyPolicy = "Forbid";
      
      jobTemplate = {
        spec = {
          backoffLimit = 1;
          activeDeadlineSeconds = 3600;
          
          template = {
            spec = {
              serviceAccountName = "report-generator";
              
              containers = [{
                name = "report";
                image = "report-generator:v3.0";
                
                env = [
                  { name = "REPORT_TYPE"; value = "weekly"; }
                  { name = "NOTIFICATION_WEBHOOK"; valueFrom.secretKeyRef = {
                      name = "slack-webhook";
                      key = "url";
                    };
                  }
                ];
                
                resources = {
                  requests = {
                    cpu = "250m";
                    memory = "256Mi";
                  };
                  limits = {
                    cpu = "1";
                    memory = "1Gi";
                  };
                };
              }];
              
              restartPolicy = "Never";
            };
          };
        };
      };
    };
  };

  # Example 6: Airflow Deployment - Development
  airflowDevelopment = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = {
      name = "airflow-dev";
    };
  };

  airflowDevDeployment = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "airflow";
      namespace = "airflow-dev";
      labels = {
        "app.kubernetes.io/name" = "airflow";
        "app.kubernetes.io/component" = "webserver";
      };
    };
    spec = {
      replicas = 1;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "airflow";
          "app.kubernetes.io/component" = "webserver";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "airflow";
            "app.kubernetes.io/component" = "webserver";
          };
        };
        spec = {
          serviceAccountName = "airflow";
          
          containers = [{
            name = "webserver";
            image = "apache/airflow:2.7.3";
            
            command = [ "airflow" "webserver" ];
            
            ports = [{ containerPort = 8080; name = "http"; }];
            
            env = [
              { name = "AIRFLOW_HOME"; value = "/opt/airflow"; }
              { name = "AIRFLOW__CORE__LOAD_EXAMPLES"; value = "false"; }
              { name = "AIRFLOW__CORE__DAGS_ARE_PAUSED_AT_CREATION"; value = "true"; }
              { name = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN"; valueFrom.secretKeyRef = {
                  name = "airflow-db";
                  key = "connection";
                };
              }
            ];
            
            resources = {
              requests = {
                cpu = "250m";
                memory = "256Mi";
              };
              limits = {
                cpu = "500m";
                memory = "512Mi";
              };
            };
            
            livenessProbe = {
              httpGet = {
                path = "/health";
                port = 8080;
              };
              initialDelaySeconds = 30;
              periodSeconds = 10;
            };
            
            readinessProbe = {
              httpGet = {
                path = "/health";
                port = 8080;
              };
              initialDelaySeconds = 10;
              periodSeconds = 5;
            };
            
            volumeMounts = [
              { name = "dags"; mountPath = "/opt/airflow/dags"; }
              { name = "logs"; mountPath = "/opt/airflow/logs"; }
            ];
          }];
          
          volumes = [
            { name = "dags"; configMap = { name = "airflow-dags"; }; }
            { name = "logs"; emptyDir = {}; }
          ];
        };
      };
    };
  };

  # Example 7: Airflow Scheduler
  airflowScheduler = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "airflow-scheduler";
      namespace = "airflow-dev";
      labels = {
        "app.kubernetes.io/name" = "airflow";
        "app.kubernetes.io/component" = "scheduler";
      };
    };
    spec = {
      replicas = 1;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "airflow";
          "app.kubernetes.io/component" = "scheduler";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "airflow";
            "app.kubernetes.io/component" = "scheduler";
          };
        };
        spec = {
          serviceAccountName = "airflow";
          
          containers = [{
            name = "scheduler";
            image = "apache/airflow:2.7.3";
            
            command = [ "airflow" "scheduler" ];
            
            env = [
              { name = "AIRFLOW_HOME"; value = "/opt/airflow"; }
              { name = "AIRFLOW__CORE__LOAD_EXAMPLES"; value = "false"; }
              { name = "AIRFLOW__DATABASE__SQL_ALCHEMY_CONN"; valueFrom.secretKeyRef = {
                  name = "airflow-db";
                  key = "connection";
                };
              }
            ];
            
            resources = {
              requests = {
                cpu = "250m";
                memory = "256Mi";
              };
              limits = {
                cpu = "500m";
                memory = "512Mi";
              };
            };
            
            volumeMounts = [
              { name = "dags"; mountPath = "/opt/airflow/dags"; }
              { name = "logs"; mountPath = "/opt/airflow/logs"; }
            ];
          }];
          
          volumes = [
            { name = "dags"; configMap = { name = "airflow-dags"; }; }
            { name = "logs"; emptyDir = {}; }
          ];
        };
      };
    };
  };

  # Example 8: Argo Workflow - Sequential Pipeline
  argoSequentialPipeline = {
    apiVersion = "argoproj.io/v1alpha1";
    kind = "Workflow";
    metadata = {
      name = "etl-pipeline";
      namespace = "argo";
      labels = {
        "workflows.argoproj.io/phase" = "Running";
      };
    };
    spec = {
      entrypoint = "etl";
      serviceAccountName = "argo";
      ttlStrategy = {
        secondsAfterFinished = 86400;
      };
      
      templates = [
        {
          name = "etl";
          steps = [
            [
              {
                name = "extract";
                template = "extract-data";
              }
            ]
            [
              {
                name = "validate";
                template = "validate-data";
              }
            ]
            [
              {
                name = "transform";
                template = "transform-data";
              }
            ]
            [
              {
                name = "load";
                template = "load-data";
              }
            ]
          ];
        }
        
        {
          name = "extract-data";
          container = {
            image = "python:3.11";
            command = [ "python" ];
            args = [ "extract.py" ];
            volumeMounts = [
              { name = "scripts"; mountPath = "/scripts"; }
              { name = "data"; mountPath = "/data"; }
            ];
          };
        }
        
        {
          name = "validate-data";
          container = {
            image = "python:3.11";
            command = [ "python" ];
            args = [ "validate.py" ];
            volumeMounts = [
              { name = "scripts"; mountPath = "/scripts"; }
              { name = "data"; mountPath = "/data"; }
            ];
          };
        }
        
        {
          name = "transform-data";
          container = {
            image = "python:3.11";
            command = [ "python" ];
            args = [ "transform.py" ];
            resources = {
              requests = {
                cpu = "1";
                memory = "2Gi";
              };
              limits = {
                cpu = "2";
                memory = "4Gi";
              };
            };
            volumeMounts = [
              { name = "scripts"; mountPath = "/scripts"; }
              { name = "data"; mountPath = "/data"; }
            ];
          };
        }
        
        {
          name = "load-data";
          container = {
            image = "python:3.11";
            command = [ "python" ];
            args = [ "load.py" ];
            volumeMounts = [
              { name = "scripts"; mountPath = "/scripts"; }
              { name = "data"; mountPath = "/data"; }
            ];
          };
        }
      ];
      
      volumes = [
        { name = "scripts"; configMap = { name = "etl-scripts"; }; }
        { name = "data"; emptyDir = { sizeLimit = "10Gi"; }; }
      ];
    };
  };

  # Example 9: Argo Workflow - Parallel Processing
  argoParallelPipeline = {
    apiVersion = "argoproj.io/v1alpha1";
    kind = "Workflow";
    metadata = {
      name = "parallel-processing";
      namespace = "argo";
    };
    spec = {
      entrypoint = "main";
      serviceAccountName = "argo";
      arguments = {
        parameters = [
          { name = "num-partitions"; value = "4"; }
        ];
      };
      
      templates = [
        {
          name = "main";
          steps = [
            [
              {
                name = "process-partition";
                template = "process-worker";
                arguments = {
                  parameters = [
                    { name = "partition-id"; value = "0"; }
                  ];
                };
              }
              {
                name = "process-partition";
                template = "process-worker";
                arguments = {
                  parameters = [
                    { name = "partition-id"; value = "1"; }
                  ];
                };
              }
              {
                name = "process-partition";
                template = "process-worker";
                arguments = {
                  parameters = [
                    { name = "partition-id"; value = "2"; }
                  ];
                };
              }
              {
                name = "process-partition";
                template = "process-worker";
                arguments = {
                  parameters = [
                    { name = "partition-id"; value = "3"; }
                  ];
                };
              }
            ]
            [
              {
                name = "aggregate";
                template = "aggregate-results";
              }
            ]
          ];
        }
        
        {
          name = "process-worker";
          inputs = {
            parameters = [ { name = "partition-id"; } ];
          };
          container = {
            image = "processor:v1.0";
            args = [ "{{inputs.parameters.partition-id}}" ];
            resources = {
              requests = {
                cpu = "500m";
                memory = "512Mi";
              };
            };
          };
        }
        
        {
          name = "aggregate-results";
          container = {
            image = "aggregator:v1.0";
            command = [ "aggregate" ];
          };
        }
      ];
    };
  };

  # Example 10: Spark Job - Scala/Java
  sparkScalaJob = {
    apiVersion = "sparkoperator.k8s.io/v1beta2";
    kind = "SparkApplication";
    metadata = {
      name = "spark-batch-job";
      namespace = "spark";
    };
    spec = {
      type = "Scala";
      mode = "cluster";
      image = "spark:3.4-scala2.12";
      imagePullPolicy = "IfNotPresent";
      
      mainApplicationFile = "s3://bucket/spark-jobs/batch.jar";
      mainClass = "com.example.BatchProcessor";
      arguments = [
        "--input-path"
        "s3://bucket/input"
        "--output-path"
        "s3://bucket/output"
        "--mode"
        "batch"
      ];
      
      sparkConf = {
        "spark.driver.extraJavaOptions" = "-Dcom.sun.management.jmxremote=true";
        "spark.executor.extraJavaOptions" = "-Dcom.sun.management.jmxremote=true";
      };
      
      driver = {
        cores = 1;
        memory = "2g";
        labels = {
          "spark.io/role" = "driver";
        };
        serviceAccount = "spark-driver";
        resources = {
          requests = {
            cpu = "500m";
            memory = "1Gi";
          };
          limits = {
            cpu = "1";
            memory = "2Gi";
          };
        };
      };
      
      executor = {
        cores = 2;
        instances = 4;
        memory = "4g";
        labels = {
          "spark.io/role" = "executor";
        };
        resources = {
          requests = {
            cpu = "1";
            memory = "2Gi";
          };
          limits = {
            cpu = "2";
            memory = "4Gi";
          };
        };
      };
      
      restartPolicy = {
        type = "Never";
      };
    };
  };

  # Example 11: PySpark Job
  pysparkJob = {
    apiVersion = "sparkoperator.k8s.io/v1beta2";
    kind = "SparkApplication";
    metadata = {
      name = "pyspark-ml-job";
      namespace = "spark";
    };
    spec = {
      type = "Python";
      mode = "cluster";
      image = "spark:3.4-python";
      imagePullPolicy = "IfNotPresent";
      
      mainApplicationFile = "s3://bucket/spark-jobs/ml_pipeline.py";
      arguments = [
        "--model-path"
        "/models/latest"
        "--output-format"
        "parquet"
      ];
      
      sparkConf = {
        "spark.sql.shuffle.partitions" = "200";
        "spark.dynamicAllocation.enabled" = "true";
        "spark.dynamicAllocation.minExecutors" = "2";
        "spark.dynamicAllocation.maxExecutors" = "10";
      };
      
      driver = {
        cores = 2;
        memory = "4g";
        coreLimit = "2000m";
        memoryOverhead = "1g";
        resources = {
          requests = {
            cpu = "2";
            memory = "4Gi";
          };
          limits = {
            cpu = "2500m";
            memory = "5Gi";
          };
        };
      };
      
      executor = {
        cores = 4;
        instances = 3;
        memory = "8g";
        coreLimit = "4000m";
        memoryOverhead = "2g";
        resources = {
          requests = {
            cpu = "4";
            memory = "8Gi";
          };
          limits = {
            cpu = "4500m";
            memory = "10Gi";
          };
        };
      };
    };
  };

  # Example 12: Job Queue - RabbitMQ
  rabbitMQJobQueue = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "job-queue-config";
      namespace = "queues";
    };
    data = {
      "queue-config.json" = builtins.toJSON {
        broker = {
          type = "rabbitmq";
          host = "rabbitmq.queues.svc.cluster.local";
          port = 5672;
          vhost = "/";
        };
        queues = {
          "background-tasks" = {
            durable = true;
            exclusive = false;
            autoDelete = false;
            deadLetterExchange = "background-tasks-dlx";
            maxLength = 1000000;
            messageTtl = 86400000;
          };
        };
        workers = {
          replicas = 3;
          concurrency = 5;
          prefetch = 10;
        };
      };
    };
  };

  jobQueueWorkers = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "job-queue-workers";
      namespace = "queues";
    };
    spec = {
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "job-queue-worker";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "job-queue-worker";
          };
        };
        spec = {
          containers = [{
            name = "worker";
            image = "job-queue-worker:v2.0";
            
            env = [
              { name = "RABBITMQ_HOST"; value = "rabbitmq.queues.svc.cluster.local"; }
              { name = "RABBITMQ_PORT"; value = "5672"; }
              { name = "QUEUE_NAME"; value = "background-tasks"; }
              { name = "WORKER_CONCURRENCY"; value = "5"; }
              {
                name = "RABBITMQ_USER";
                valueFrom.secretKeyRef = {
                  name = "rabbitmq-credentials";
                  key = "username";
                };
              }
              {
                name = "RABBITMQ_PASSWORD";
                valueFrom.secretKeyRef = {
                  name = "rabbitmq-credentials";
                  key = "password";
                };
              }
            ];
            
            resources = {
              requests = {
                cpu = "250m";
                memory = "256Mi";
              };
              limits = {
                cpu = "1";
                memory = "512Mi";
              };
            };
            
            livenessProbe = {
              exec = {
                command = [ "health-check" ];
              };
              initialDelaySeconds = 30;
              periodSeconds = 10;
            };
          }];
        };
      };
    };
  };

  # Example 13: Data Pipeline - Simple ETL
  simpleDataPipeline = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "simple-etl-pipeline";
      namespace = "data-pipelines";
    };
    spec = {
      schedule = "0 * * * *";  # Hourly
      concurrencyPolicy = "Forbid";
      
      jobTemplate = {
        spec = {
          activeDeadlineSeconds = 3600;
          
          template = {
            spec = {
              serviceAccountName = "etl-runner";
              
              initContainers = [
                {
                  name = "extract";
                  image = "etl-tools:v1.0";
                  command = [ "extract" ];
                  args = [
                    "--source"
                    "postgresql://postgres:5432/source_db"
                    "--query"
                    "SELECT * FROM events WHERE created_at > NOW() - INTERVAL '1 hour'"
                    "--output"
                    "/data/raw/events.parquet"
                  ];
                  env = [
                    {
                      name = "DB_PASSWORD";
                      valueFrom.secretKeyRef = {
                        name = "source-db-secret";
                        key = "password";
                      };
                    }
                  ];
                  volumeMounts = [
                    { name = "data"; mountPath = "/data"; }
                  ];
                }
              ];
              
              containers = [
                {
                  name = "transform";
                  image = "etl-tools:v1.0";
                  command = [ "transform" ];
                  args = [
                    "--input"
                    "/data/raw/events.parquet"
                    "--output"
                    "/data/processed/events.parquet"
                    "--schema"
                    "/config/schema.json"
                  ];
                  volumeMounts = [
                    { name = "data"; mountPath = "/data"; }
                    { name = "config"; mountPath = "/config"; }
                  ];
                }
                {
                  name = "load";
                  image = "etl-tools:v1.0";
                  command = [ "load" ];
                  args = [
                    "--input"
                    "/data/processed/events.parquet"
                    "--destination"
                    "postgresql://postgres:5432/target_db"
                    "--table"
                    "processed_events"
                    "--mode"
                    "upsert"
                  ];
                  env = [
                    {
                      name = "DB_PASSWORD";
                      valueFrom.secretKeyRef = {
                        name = "target-db-secret";
                        key = "password";
                      };
                    }
                  ];
                  volumeMounts = [
                    { name = "data"; mountPath = "/data"; }
                  ];
                }
              ];
              
              volumes = [
                { name = "data"; emptyDir = { sizeLimit = "5Gi"; }; }
                { name = "config"; configMap = { name = "etl-config"; }; }
              ];
              
              restartPolicy = "Never";
            };
          };
        };
      };
    };
  };

  # Example 14: Data Pipeline - Complex with Quality Checks
  complexDataPipeline = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "complex-etl-pipeline";
      namespace = "data-pipelines";
      labels = {
        "pipeline.io/tier" = "production";
        "pipeline.io/frequency" = "daily";
      };
    };
    spec = {
      schedule = "0 3 * * *";  # Daily at 3am
      timezone = "America/New_York";
      concurrencyPolicy = "Forbid";
      successfulJobsHistoryLimit = 30;
      failedJobsHistoryLimit = 10;
      
      jobTemplate = {
        spec = {
          backoffLimit = 1;
          activeDeadlineSeconds = 21600;  # 6 hours
          ttlSecondsAfterFinished = 604800;  # 7 days
          
          template = {
            metadata = {
              labels = {
                "pipeline.io/tier" = "production";
              };
            };
            spec = {
              serviceAccountName = "etl-service";
              securityContext = {
                runAsNonRoot = true;
                runAsUser = 1000;
              };
              
              containers = [
                {
                  name = "extract";
                  image = "etl-pipeline:v2.0";
                  command = [ "python" "-m" "etl.extract" ];
                  args = [
                    "--source"
                    "postgresql"
                    "--config"
                    "/etc/etl/extract-config.yaml"
                  ];
                  
                  env = [
                    { name = "LOG_LEVEL"; value = "INFO"; }
                    { name = "STAGE"; value = "extract"; }
                    {
                      name = "DATABASE_URL";
                      valueFrom.secretKeyRef = {
                        name = "source-db";
                        key = "url";
                      };
                    }
                  ];
                  
                  resources = {
                    requests = {
                      cpu = "500m";
                      memory = "512Mi";
                    };
                    limits = {
                      cpu = "2";
                      memory = "2Gi";
                    };
                  };
                  
                  volumeMounts = [
                    { name = "data"; mountPath = "/data"; }
                    { name = "config"; mountPath = "/etc/etl"; }
                  ];
                }
                
                {
                  name = "validate";
                  image = "etl-pipeline:v2.0";
                  command = [ "python" "-m" "etl.validate" ];
                  args = [
                    "--input"
                    "/data/raw"
                    "--schema"
                    "/etc/etl/schema.json"
                    "--output"
                    "/data/validation-report.json"
                  ];
                  
                  env = [
                    { name = "LOG_LEVEL"; value = "INFO"; }
                    { name = "STAGE"; value = "validate"; }
                  ];
                  
                  resources = {
                    requests = {
                      cpu = "250m";
                      memory = "512Mi";
                    };
                    limits = {
                      cpu = "1";
                      memory = "2Gi";
                    };
                  };
                  
                  volumeMounts = [
                    { name = "data"; mountPath = "/data"; }
                    { name = "config"; mountPath = "/etc/etl"; }
                  ];
                }
                
                {
                  name = "transform";
                  image = "etl-pipeline:v2.0";
                  command = [ "python" "-m" "etl.transform" ];
                  args = [
                    "--input"
                    "/data/raw"
                    "--output"
                    "/data/processed"
                    "--rules"
                    "/etc/etl/transform-rules.yaml"
                  ];
                  
                  env = [
                    { name = "LOG_LEVEL"; value = "INFO"; }
                    { name = "STAGE"; value = "transform"; }
                    { name = "PARALLELISM"; value = "4"; }
                  ];
                  
                  resources = {
                    requests = {
                      cpu = "2";
                      memory = "4Gi";
                    };
                    limits = {
                      cpu = "4";
                      memory = "8Gi";
                    };
                  };
                  
                  volumeMounts = [
                    { name = "data"; mountPath = "/data"; }
                    { name = "config"; mountPath = "/etc/etl"; }
                  ];
                }
                
                {
                  name = "load";
                  image = "etl-pipeline:v2.0";
                  command = [ "python" "-m" "etl.load" ];
                  args = [
                    "--input"
                    "/data/processed"
                    "--destination"
                    "snowflake"
                    "--config"
                    "/etc/etl/load-config.yaml"
                  ];
                  
                  env = [
                    { name = "LOG_LEVEL"; value = "INFO"; }
                    { name = "STAGE"; value = "load"; }
                    {
                      name = "SNOWFLAKE_ACCOUNT";
                      valueFrom.secretKeyRef = {
                        name = "snowflake-creds";
                        key = "account";
                      };
                    }
                  ];
                  
                  resources = {
                    requests = {
                      cpu = "1";
                      memory = "2Gi";
                    };
                    limits = {
                      cpu = "2";
                      memory = "4Gi";
                    };
                  };
                  
                  volumeMounts = [
                    { name = "data"; mountPath = "/data"; }
                    { name = "config"; mountPath = "/etc/etl"; }
                  ];
                }
              ];
              
              volumes = [
                { name = "data"; emptyDir = { sizeLimit = "50Gi"; }; }
                { name = "config"; configMap = { name = "etl-pipeline-config"; }; }
              ];
              
              restartPolicy = "Never";
              imagePullSecrets = [ { name = "registry-credentials"; } ];
            };
          };
        };
      };
    };
  };

  # Example 15: Monitoring Configuration
  batchMonitoring = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "batch-monitoring-config";
      namespace = "monitoring";
    };
    data = {
      "prometheus-rules.yaml" = ''
        groups:
        - name: batch-jobs
          interval: 30s
          rules:
          - alert: BatchJobFailureRate
            expr: rate(batch_job_failures_total[5m]) > 0.1
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "High batch job failure rate"
              description: "Job failure rate is {{ $value }}"
          
          - alert: BatchJobTimeout
            expr: batch_job_duration_seconds > 3600
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Batch job exceeded timeout"
              description: "Job {{ $labels.job_name }} running for {{ $value }}s"
          
          - alert: BatchJobResourcesExceeded
            expr: |
              (container_memory_usage_bytes{pod=~"batch-job-.*"} / 
               container_spec_memory_limit_bytes{pod=~"batch-job-.*"}) > 0.95
            for: 5m
            labels:
              severity: warning
            annotations:
              summary: "Batch job memory usage high"
              description: "Pod {{ $labels.pod }} memory usage at {{ $value }}"
      '';
    };
  };

  # Example 16: Batch Job with Monitoring Sidecar
  batchJobWithMonitoring = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "monitored-batch-job";
      namespace = "batch";
    };
    spec = {
      backoffLimit = 2;
      activeDeadlineSeconds = 7200;
      
      template = {
        metadata = {
          labels = {
            "monitoring.io/enabled" = "true";
          };
          annotations = {
            "prometheus.io/scrape" = "true";
            "prometheus.io/port" = "9090";
            "prometheus.io/path" = "/metrics";
          };
        };
        spec = {
          containers = [
            {
              name = "job";
              image = "batch-processor:v1.0";
              
              env = [
                { name = "METRICS_PORT"; value = "9090"; }
              ];
              
              resources = {
                requests = {
                  cpu = "1";
                  memory = "2Gi";
                };
                limits = {
                  cpu = "2";
                  memory = "4Gi";
                };
              };
              
              ports = [
                { name = "metrics"; containerPort = 9090; }
              ];
            }
            
            {
              name = "prometheus-sidecar";
              image = "prom/prometheus:latest";
              command = [ "prometheus" ];
              args = [
                "--config.file=/etc/prometheus/prometheus.yml"
                "--storage.tsdb.path=/prometheus"
                "--storage.tsdb.retention.time=1h"
              ];
              
              resources = {
                requests = {
                  cpu = "100m";
                  memory = "128Mi";
                };
                limits = {
                  cpu = "200m";
                  memory = "256Mi";
                };
              };
              
              volumeMounts = [
                { name = "prometheus-config"; mountPath = "/etc/prometheus"; }
              ];
            }
          ];
          
          volumes = [
            { name = "prometheus-config"; configMap = { name = "prometheus-sidecar-config"; }; }
          ];
          
          restartPolicy = "Never";
        };
      };
    };
  };

  # Example 17: Parallel Map-Reduce Style Job
  mapReduceJob = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "map-reduce-job";
      namespace = "batch";
    };
    spec = {
      parallelism = 10;
      completions = 10;
      backoffLimit = 3;
      
      template = {
        spec = {
          containers = [{
            name = "mapper";
            image = "map-reduce:v1.0";
            
            env = [
              {
                name = "JOB_ID";
                valueFrom.fieldRef = {
                  fieldPath = "metadata.uid";
                };
              }
              {
                name = "POD_INDEX";
                valueFrom.fieldRef = {
                  fieldPath = "metadata.name";
                };
              }
            ];
            
            command = [ "python" ];
            args = [ "mapper.py" ];
            
            resources = {
              requests = {
                cpu = "500m";
                memory = "512Mi";
              };
              limits = {
                cpu = "1";
                memory = "1Gi";
              };
            };
            
            volumeMounts = [
              { name = "data"; mountPath = "/data"; }
            ];
          }];
          
          volumes = [
            {
              name = "data";
              persistentVolumeClaim = {
                claimName = "map-reduce-data";
              };
            }
          ];
          
          restartPolicy = "Never";
        };
      };
    };
  };

  # Example 18: Long-Running Batch Job with Progress Tracking
  longRunningJob = {
    apiVersion = "batch/v1";
    kind = "Job";
    metadata = {
      name = "long-running-ml-job";
      namespace = "ml-batch";
    };
    spec = {
      backoffLimit = 1;
      activeDeadlineSeconds = 259200;  # 72 hours
      ttlSecondsAfterFinished = 604800;  # 7 days
      
      template = {
        metadata = {
          labels = {
            "job.io/type" = "ml-training";
          };
        };
        spec = {
          serviceAccountName = "ml-training";
          securityContext = {
            runAsNonRoot = true;
            runAsUser = 1000;
            fsGroup = 2000;
          };
          
          containers = [{
            name = "trainer";
            image = "pytorch:gpu-v2.0";
            
            command = [ "python" ];
            args = [
              "-m"
              "trainer.train"
              "--model"
              "resnet50"
              "--epochs"
              "100"
              "--batch-size"
              "256"
              "--checkpoint-dir"
              "/checkpoints"
            ];
            
            env = [
              { name = "CUDA_VISIBLE_DEVICES"; value = "0,1"; }
              { name = "PYTHONUNBUFFERED"; value = "1"; }
              { name = "LOG_LEVEL"; value = "INFO"; }
              { name = "CHECKPOINT_INTERVAL"; value = "10"; }
            ];
            
            resources = {
              requests = {
                cpu = "8";
                memory = "32Gi";
                "nvidia.com/gpu" = "2";
              };
              limits = {
                cpu = "8";
                memory = "32Gi";
                "nvidia.com/gpu" = "2";
              };
            };
            
            volumeMounts = [
              { name = "training-data"; mountPath = "/data"; }
              { name = "checkpoints"; mountPath = "/checkpoints"; }
            ];
            
            securityContext = {
              allowPrivilegeEscalation = false;
              readOnlyRootFilesystem = false;
            };
          }];
          
          volumes = [
            {
              name = "training-data";
              persistentVolumeClaim = {
                claimName = "training-data-pvc";
              };
            }
            {
              name = "checkpoints";
              persistentVolumeClaim = {
                claimName = "ml-checkpoints-pvc";
              };
            }
          ];
          
          restartPolicy = "Never";
          nodeSelector = {
            "workload-type" = "gpu-compute";
          };
          
          tolerations = [
            {
              key = "nvidia.com/gpu";
              operator = "Exists";
              effect = "NoSchedule";
            }
          ];
        };
      };
    };
  };
}
