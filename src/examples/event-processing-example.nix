# Event Processing Examples
#
# This file contains 18+ production-ready configuration examples for event processing systems
# including Kafka, NATS, RabbitMQ, Pulsar deployments with various configurations
# for clustering, replication, and stream processing.

{ lib, ... }:

{
  # Example 1: Kafka Cluster - Development
  kafkaClusterDev = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = {
      name = "events";
    };
  };

  kafkaBrokerDev = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "kafka-broker-dev";
      namespace = "events";
    };
    spec = {
      replicas = 1;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "kafka";
          "app.kubernetes.io/tier" = "broker";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "kafka";
            "app.kubernetes.io/tier" = "broker";
          };
        };
        spec = {
          containers = [{
            name = "kafka";
            image = "confluentinc/cp-kafka:7.5.0";
            
            env = [
              { name = "KAFKA_BROKER_ID"; value = "1"; }
              { name = "KAFKA_ZOOKEEPER_CONNECT"; value = "zookeeper:2181"; }
              { name = "KAFKA_ADVERTISED_LISTENERS"; value = "PLAINTEXT://kafka:9092"; }
              { name = "KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR"; value = "1"; }
              { name = "KAFKA_TRANSACTION_STATE_LOG_MIN_ISR"; value = "1"; }
              { name = "KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR"; value = "1"; }
              { name = "KAFKA_LOG_RETENTION_HOURS"; value = "168"; }
              { name = "KAFKA_AUTO_CREATE_TOPICS_ENABLE"; value = "true"; }
            ];
            
            ports = [
              { containerPort = 9092; name = "broker"; }
            ];
            
            resources = {
              requests = {
                cpu = "250m";
                memory = "512Mi";
              };
              limits = {
                cpu = "500m";
                memory = "1Gi";
              };
            };
            
            volumeMounts = [
              { name = "data"; mountPath = "/var/lib/kafka/data"; }
            ];
          }];
          
          volumes = [
            {
              name = "data";
              emptyDir = {};
            }
          ];
        };
      };
    };
  };

  kafkaZookeeperDev = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "zookeeper-dev";
      namespace = "events";
    };
    spec = {
      replicas = 1;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "zookeeper";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "zookeeper";
          };
        };
        spec = {
          containers = [{
            name = "zookeeper";
            image = "confluentinc/cp-zookeeper:7.5.0";
            
            env = [
              { name = "ZOO_CFG_EXTRA"; value = "dataDir=/var/lib/zookeeper/data"; }
            ];
            
            ports = [
              { containerPort = 2181; name = "client"; }
              { containerPort = 2888; name = "server"; }
              { containerPort = 3888; name = "leader-election"; }
            ];
            
            resources = {
              requests = {
                cpu = "100m";
                memory = "256Mi";
              };
              limits = {
                cpu = "250m";
                memory = "512Mi";
              };
            };
            
            volumeMounts = [
              { name = "data"; mountPath = "/var/lib/zookeeper/data"; }
            ];
          }];
          
          volumes = [
            { name = "data"; emptyDir = {}; }
          ];
        };
      };
    };
  };

  # Example 2: Kafka Cluster - Production HA
  kafkaProducerConfigMap = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "kafka-broker-config";
      namespace = "events";
    };
    data = {
      "server.properties" = ''
        # Broker configuration
        broker.id=1
        listeners=PLAINTEXT://:9092,CONTROLLER://:9093
        advertised.listeners=PLAINTEXT://kafka-broker-0.kafka.events.svc.cluster.local:9092
        controller.quorum.voters=1@kafka-broker-0.kafka.events.svc.cluster.local:9093
        
        # Log configuration
        log.dirs=/var/lib/kafka/data
        num.network.threads=8
        num.io.threads=8
        socket.send.buffer.bytes=102400
        socket.receive.buffer.bytes=102400
        socket.request.max.bytes=104857600
        
        # Replication
        min.insync.replicas=2
        default.replication.factor=3
        offsets.topic.replication.factor=3
        
        # Retention
        log.retention.hours=168
        log.segment.bytes=1073741824
        
        # Performance
        compression.type=snappy
        linger.ms=10
        batch.size=16384
        
        # Security
        security.inter.broker.protocol.version=3.6-IV0
      '';
    };
  };

  kafkaStatefulSetProd = {
    apiVersion = "apps/v1";
    kind = "StatefulSet";
    metadata = {
      name = "kafka";
      namespace = "events";
    };
    spec = {
      serviceName = "kafka";
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "kafka";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "kafka";
          };
          annotations = {
            "prometheus.io/scrape" = "true";
            "prometheus.io/port" = "9308";
          };
        };
        spec = {
          serviceAccountName = "kafka";
          affinity = {
            podAntiAffinity = {
              requiredDuringSchedulingIgnoredDuringExecution = [
                {
                  labelSelector = {
                    matchExpressions = [
                      {
                        key = "app.kubernetes.io/name";
                        operator = "In";
                        values = [ "kafka" ];
                      }
                    ];
                  };
                  topologyKey = "kubernetes.io/hostname";
                }
              ];
            };
          };
          
          containers = [
            {
              name = "kafka";
              image = "confluentinc/cp-kafka:7.5.0";
              imagePullPolicy = "IfNotPresent";
              
              env = [
                { name = "KAFKA_BROKER_ID"; valueFrom.fieldRef = { fieldPath = "metadata.name"; }; }
                { name = "KAFKA_ZOOKEEPER_CONNECT"; value = "zookeeper:2181"; }
                { name = "KAFKA_LOG_DIRS"; value = "/var/lib/kafka/data"; }
              ];
              
              ports = [
                { containerPort = 9092; name = "plaintext"; }
                { containerPort = 9999; name = "jmx"; }
              ];
              
              livenessProbe = {
                exec = {
                  command = [ "kafka-broker-api-versions.sh" "--bootstrap-server=localhost:9092" ];
                };
                initialDelaySeconds = 30;
                periodSeconds = 30;
                timeoutSeconds = 10;
              };
              
              readinessProbe = {
                exec = {
                  command = [ "kafka-broker-api-versions.sh" "--bootstrap-server=localhost:9092" ];
                };
                initialDelaySeconds = 10;
                periodSeconds = 10;
              };
              
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
              
              volumeMounts = [
                { name = "data"; mountPath = "/var/lib/kafka/data"; }
                { name = "config"; mountPath = "/etc/kafka"; }
              ];
            }
            
            {
              name = "jmx-exporter";
              image = "sscaling/jmx-exporter:latest";
              
              ports = [
                { containerPort = 5556; }
              ];
              
              resources = {
                requests = {
                  cpu = "50m";
                  memory = "64Mi";
                };
                limits = {
                  cpu = "100m";
                  memory = "128Mi";
                };
              };
            }
          ];
          
          volumes = [
            {
              name = "config";
              configMap = {
                name = "kafka-broker-config";
              };
            }
          ];
        };
      };
      
      volumeClaimTemplates = [
        {
          metadata = {
            name = "data";
          };
          spec = {
            accessModes = [ "ReadWriteOnce" ];
            storageClassName = "fast-ssd";
            resources = {
              requests = {
                storage = "100Gi";
              };
            };
          };
        }
      ];
    };
  };

  kafkaHeadlessService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "kafka";
      namespace = "events";
    };
    spec = {
      clusterIP = "None";
      selector = {
        "app.kubernetes.io/name" = "kafka";
      };
      ports = [
        { port = 9092; targetPort = 9092; name = "plaintext"; }
      ];
    };
  };

  # Example 3: Kafka Topic Configuration
  kafkaTopicUserEvents = {
    apiVersion = "kafka.strimzi.io/v1beta2";
    kind = "KafkaTopic";
    metadata = {
      name = "user-events";
      namespace = "events";
    };
    spec = {
      partitions = 12;
      replicas = 3;
      config = {
        "retention.ms" = "604800000";  # 7 days
        "retention.bytes" = "107374182400";  # 100GB
        "compression.type" = "snappy";
        "min.insync.replicas" = "2";
        "cleanup.policy" = "delete";
        "segment.ms" = "86400000";  # 1 day
      };
    };
  };

  kafkaTopicCompact = {
    apiVersion = "kafka.strimzi.io/v1beta2";
    kind = "KafkaTopic";
    metadata = {
      name = "config-store";
      namespace = "events";
    };
    spec = {
      partitions = 1;
      replicas = 3;
      config = {
        "cleanup.policy" = "compact";
        "min.cleanable.dirty.ratio" = "0.5";
        "delete.retention.ms" = "86400000";
        "segment.ms" = "3600000";
      };
    };
  };

  # Example 4: NATS Cluster
  natsStatefulSet = {
    apiVersion = "apps/v1";
    kind = "StatefulSet";
    metadata = {
      name = "nats";
      namespace = "events";
    };
    spec = {
      serviceName = "nats";
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "nats";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "nats";
          };
        };
        spec = {
          containers = [{
            name = "nats";
            image = "nats:2.10-alpine";
            
            command = [
              "nats-server"
              "-c"
              "/etc/nats-config/nats.conf"
            ];
            
            ports = [
              { containerPort = 4222; name = "client"; }
              { containerPort = 6222; name = "route"; }
              { containerPort = 8222; name = "monitor"; }
            ];
            
            resources = {
              requests = {
                cpu = "250m";
                memory = "512Mi";
              };
              limits = {
                cpu = "1";
                memory = "1Gi";
              };
            };
            
            volumeMounts = [
              { name = "config"; mountPath = "/etc/nats-config"; }
              { name = "jetstream"; mountPath = "/data"; }
            ];
          }];
          
          volumes = [
            {
              name = "config";
              configMap = {
                name = "nats-config";
              };
            }
          ];
        };
      };
      
      volumeClaimTemplates = [
        {
          metadata = {
            name = "jetstream";
          };
          spec = {
            accessModes = [ "ReadWriteOnce" ];
            storageClassName = "fast-ssd";
            resources = {
              requests = {
                storage = "50Gi";
              };
            };
          };
        }
      ];
    };
  };

  natsHeadlessService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "nats";
      namespace = "events";
    };
    spec = {
      clusterIP = "None";
      selector = {
        "app.kubernetes.io/name" = "nats";
      };
      ports = [
        { port = 4222; targetPort = 4222; name = "client"; }
        { port = 6222; targetPort = 6222; name = "route"; }
        { port = 8222; targetPort = 8222; name = "monitor"; }
      ];
    };
  };

  natsConfig = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "nats-config";
      namespace = "events";
    };
    data = {
      "nats.conf" = ''
        port: 4222
        max_connections: 100000
        max_payload: 1MB
        
        jetstream {
          store_dir: /data
          max_mem: 20Gi
          max_file: 50Gi
        }
        
        cluster {
          port: 6222
          routes = [
            "nats://nats-0.nats.events.svc.cluster.local:6222"
            "nats://nats-1.nats.events.svc.cluster.local:6222"
            "nats://nats-2.nats.events.svc.cluster.local:6222"
          ]
        }
        
        http_port: 8222
        
        accounts {
          $SYS { }
          APP {
            jetstream: enabled
            users = [
              {
                user: app_user
                pass: secure_password
                permissions {
                  publish: [">"]
                  subscribe: [">"]
                }
              }
            ]
          }
        }
        
        system_account: $SYS
      '';
    };
  };

  # Example 5: RabbitMQ Cluster
  rabbitmqStatefulSet = {
    apiVersion = "apps/v1";
    kind = "StatefulSet";
    metadata = {
      name = "rabbitmq";
      namespace = "events";
    };
    spec = {
      serviceName = "rabbitmq";
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "rabbitmq";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "rabbitmq";
          };
        };
        spec = {
          serviceAccountName = "rabbitmq";
          
          initContainers = [{
            name = "setup";
            image = "busybox:1.35";
            command = [
              "sh"
              "-c"
              "echo 'rabbitmq' > /var/lib/rabbitmq/.erlang.cookie && chmod 600 /var/lib/rabbitmq/.erlang.cookie"
            ];
            volumeMounts = [{
              name = "data";
              mountPath = "/var/lib/rabbitmq";
            }];
          }];
          
          containers = [{
            name = "rabbitmq";
            image = "rabbitmq:3.12-management-alpine";
            
            env = [
              { name = "RABBITMQ_DEFAULT_USER"; value = "guest"; }
              {
                name = "RABBITMQ_DEFAULT_PASS";
                valueFrom.secretKeyRef = {
                  name = "rabbitmq-credentials";
                  key = "password";
                };
              }
              { name = "RABBITMQ_ERLANG_COOKIE"; value = "rabbitmq"; }
            ];
            
            ports = [
              { containerPort = 5672; name = "amqp"; }
              { containerPort = 15672; name = "management"; }
              { containerPort = 25672; name = "dist"; }
            ];
            
            livenessProbe = {
              exec = {
                command = [ "rabbitmq-diagnostics" "ping" ];
              };
              initialDelaySeconds = 30;
              periodSeconds = 30;
              timeoutSeconds = 10;
            };
            
            readinessProbe = {
              exec = {
                command = [ "rabbitmq-diagnostics" "status" ];
              };
              initialDelaySeconds = 10;
              periodSeconds = 10;
            };
            
            resources = {
              requests = {
                cpu = "500m";
                memory = "1Gi";
              };
              limits = {
                cpu = "2";
                memory = "2Gi";
              };
            };
            
            volumeMounts = [
              { name = "data"; mountPath = "/var/lib/rabbitmq"; }
              { name = "config"; mountPath = "/etc/rabbitmq"; }
            ];
          }];
          
          volumes = [{
            name = "config";
            configMap = {
              name = "rabbitmq-config";
            };
          }];
        };
      };
      
      volumeClaimTemplates = [{
        metadata = {
          name = "data";
        };
        spec = {
          accessModes = [ "ReadWriteOnce" ];
          storageClassName = "fast-ssd";
          resources = {
            requests = {
              storage = "50Gi";
            };
          };
        };
      }];
    };
  };

  rabbitmqHeadlessService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "rabbitmq";
      namespace = "events";
    };
    spec = {
      clusterIP = "None";
      selector = {
        "app.kubernetes.io/name" = "rabbitmq";
      };
      ports = [
        { port = 5672; targetPort = 5672; name = "amqp"; }
        { port = 15672; targetPort = 15672; name = "management"; }
      ];
    };
  };

  rabbitmqManagementService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "rabbitmq-management";
      namespace = "events";
    };
    spec = {
      type = "LoadBalancer";
      selector = {
        "app.kubernetes.io/name" = "rabbitmq";
      };
      ports = [{
        port = 15672;
        targetPort = 15672;
        protocol = "TCP";
      }];
    };
  };

  rabbitmqConfig = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "rabbitmq-config";
      namespace = "events";
    };
    data = {
      "rabbitmq.conf" = ''
        # Clustering
        cluster_formation.peer_discovery_backend = kubernetes
        cluster_formation.k8s.host = kubernetes.default.svc.cluster.local
        cluster_formation.k8s.address_type = hostname
        
        # Memory
        vm_memory_high_watermark.relative = 0.6
        vm_memory_high_watermark_paging_ratio = 0.75
        
        # Networking
        max_connections = 100000
        channel_max = 2048
        
        # Management plugin
        management.tcp.port = 15672
        
        # Performance
        channel_operation_timeout = 15000
      '';
    };
  };

  # Example 6: Consumer Group - Order Processing
  kafkaConsumerOrderProcessor = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "order-processor";
      namespace = "events";
    };
    spec = {
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "order-processor";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "order-processor";
          };
        };
        spec = {
          serviceAccountName = "order-processor";
          
          containers = [{
            name = "processor";
            image = "order-processor:v1.0";
            imagePullPolicy = "IfNotPresent";
            
            env = [
              { name = "KAFKA_BROKERS"; value = "kafka-0.kafka.events.svc.cluster.local:9092,kafka-1.kafka.events.svc.cluster.local:9092,kafka-2.kafka.events.svc.cluster.local:9092"; }
              { name = "KAFKA_GROUP_ID"; value = "order-processor"; }
              { name = "KAFKA_TOPICS"; value = "orders"; }
              { name = "KAFKA_AUTO_OFFSET_RESET"; value = "earliest"; }
              { name = "KAFKA_ENABLE_AUTO_COMMIT"; value = "true"; }
              { name = "KAFKA_AUTO_COMMIT_INTERVAL_MS"; value = "5000"; }
              { name = "PROCESSOR_THREADS"; value = "4"; }
              { name = "LOG_LEVEL"; value = "INFO"; }
            ];
            
            ports = [{
              containerPort = 8080;
              name = "http";
            }];
            
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
                path = "/ready";
                port = 8080;
              };
              initialDelaySeconds = 10;
              periodSeconds = 5;
            };
            
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
          }];
        };
      };
    };
  };

  # Example 7: Dead Letter Queue
  dlqTopic = {
    apiVersion = "kafka.strimzi.io/v1beta2";
    kind = "KafkaTopic";
    metadata = {
      name = "order-processor-dlq";
      namespace = "events";
    };
    spec = {
      partitions = 3;
      replicas = 3;
      config = {
        "retention.ms" = "2592000000";  # 30 days
        "cleanup.policy" = "delete";
      };
    };
  };

  dlqProcessor = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "dlq-processor";
      namespace = "events";
    };
    spec = {
      replicas = 1;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "dlq-processor";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "dlq-processor";
          };
        };
        spec = {
          containers = [{
            name = "processor";
            image = "dlq-processor:v1.0";
            
            env = [
              { name = "KAFKA_BROKERS"; value = "kafka:9092"; }
              { name = "DLQ_TOPIC"; value = "order-processor-dlq"; }
              { name = "ALERT_WEBHOOK"; valueFrom.secretKeyRef = {
                  name = "dlq-alerts";
                  key = "webhook-url";
                };
              }
            ];
            
            resources = {
              requests = {
                cpu = "100m";
                memory = "128Mi";
              };
              limits = {
                cpu = "500m";
                memory = "512Mi";
              };
            };
          }];
        };
      };
    };
  };

  # Example 8: Schema Registry
  schemaRegistryDeployment = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "schema-registry";
      namespace = "events";
    };
    spec = {
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "schema-registry";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "schema-registry";
          };
        };
        spec = {
          containers = [{
            name = "schema-registry";
            image = "confluentinc/cp-schema-registry:7.5.0";
            
            env = [
              { name = "SCHEMA_REGISTRY_HOST_NAME"; value = "schema-registry"; }
              { name = "SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS"; value = "kafka:9092"; }
              { name = "SCHEMA_REGISTRY_LISTENERS"; value = "http://0.0.0.0:8081"; }
            ];
            
            ports = [{ containerPort = 8081; }];
            
            livenessProbe = {
              httpGet = {
                path = "/subjects";
                port = 8081;
              };
              initialDelaySeconds = 30;
              periodSeconds = 10;
            };
            
            resources = {
              requests = {
                cpu = "250m";
                memory = "512Mi";
              };
              limits = {
                cpu = "500m";
                memory = "1Gi";
              };
            };
          }];
        };
      };
    };
  };

  schemaRegistryService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "schema-registry";
      namespace = "events";
    };
    spec = {
      type = "ClusterIP";
      selector = {
        "app.kubernetes.io/name" = "schema-registry";
      };
      ports = [{
        port = 8081;
        targetPort = 8081;
        protocol = "TCP";
      }];
    };
  };

  # Example 9: Stream Processing - Kafka Streams
  streamProcessorDeployment = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "stream-processor";
      namespace = "events";
    };
    spec = {
      replicas = 2;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "stream-processor";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "stream-processor";
          };
        };
        spec = {
          containers = [{
            name = "processor";
            image = "stream-processor:v1.0";
            
            env = [
              { name = "KAFKA_BROKERS"; value = "kafka:9092"; }
              { name = "KAFKA_APPLICATION_ID"; value = "stream-processor"; }
              { name = "INPUT_TOPIC"; value = "events"; }
              { name = "OUTPUT_TOPIC"; value = "processed-events"; }
              { name = "STATE_DIR"; value = "/tmp/kafka-streams"; }
            ];
            
            ports = [{
              containerPort = 8080;
              name = "metrics";
            }];
            
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
            
            volumeMounts = [{
              name = "state";
              mountPath = "/tmp/kafka-streams";
            }];
          }];
          
          volumes = [{
            name = "state";
            emptyDir = {};
          }];
        };
      };
    };
  };

  # Example 10: Event Monitoring with Prometheus
  kafkaMonitoringPrometheusConfig = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "kafka-monitoring-config";
      namespace = "monitoring";
    };
    data = {
      "prometheus-rules.yaml" = ''
        groups:
        - name: kafka
          interval: 30s
          rules:
          - alert: KafkaBrokerDown
            expr: up{job="kafka"} == 0
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Kafka broker {{ $labels.instance }} is down"
          
          - alert: HighConsumerLag
            expr: kafka_consumer_lag_sum > 100000
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "Consumer group {{ $labels.consumergroup }} has high lag"
              value: "{{ $value }}"
          
          - alert: ReplicationIssues
            expr: kafka_topic_partition_in_sync_replica_count < kafka_topic_partition_replica_count
            for: 5m
            labels:
              severity: critical
            annotations:
              summary: "Topic {{ $labels.topic }} replication issues"
          
          - alert: LowBrokerDiskSpace
            expr: kafka_broker_disk_free_bytes / kafka_broker_disk_total_bytes < 0.1
            for: 10m
            labels:
              severity: warning
            annotations:
              summary: "Broker {{ $labels.broker }} disk space low"
      '';
    };
  };

  # Example 11: Pulsar Cluster
  pulsarBrokerDeployment = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "pulsar-broker";
      namespace = "events";
    };
    spec = {
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "pulsar-broker";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "pulsar-broker";
          };
        };
        spec = {
          containers = [{
            name = "broker";
            image = "apachepulsar/pulsar:3.1";
            
            command = [
              "sh"
              "-c"
              "bin/pulsar broker"
            ];
            
            env = [
              { name = "PULSAR_LOG_LEVEL"; value = "info"; }
            ];
            
            ports = [
              { containerPort = 6650; name = "pulsar"; }
              { containerPort = 8080; name = "http"; }
            ];
            
            livenessProbe = {
              httpGet = {
                path = "/admin/v2/brokers/healthcheck";
                port = 8080;
              };
              initialDelaySeconds = 30;
              periodSeconds = 30;
            };
            
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
          }];
        };
      };
    };
  };

  # Example 12: Message Batch Processing
  batchMessageProcessor = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "event-batch-processor";
      namespace = "events";
    };
    spec = {
      schedule = "0 2 * * *";
      concurrencyPolicy = "Forbid";
      
      jobTemplate = {
        spec = {
          activeDeadlineSeconds = 3600;
          
          template = {
            spec = {
              containers = [{
                name = "processor";
                image = "event-batch-processor:v1.0";
                
                env = [
                  { name = "KAFKA_BROKERS"; value = "kafka:9092"; }
                  { name = "INPUT_TOPIC"; value = "events"; }
                  { name = "OUTPUT_PATH"; value = "s3://bucket/events/"; }
                  { name = "BATCH_SIZE"; value = "100000"; }
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
              }];
              
              restartPolicy = "OnFailure";
            };
          };
        };
      };
    };
  };

  # Example 13: Event Streaming to Elasticsearch
  elasticsearchSinkConnector = {
    apiVersion = "kafka.strimzi.io/v1beta2";
    kind = "KafkaConnector";
    metadata = {
      name = "elasticsearch-sink";
      namespace = "events";
    };
    spec = {
      class = "io.confluent.connect.elasticsearch.ElasticsearchSinkConnector";
      tasksMax = 4;
      config = {
        "connection.url" = "http://elasticsearch:9200";
        "topics" = "events";
        "key.converter" = "org.apache.kafka.connect.storage.StringConverter";
        "value.converter" = "io.confluent.connect.avro.AvroConverter";
        "value.converter.schema.registry.url" = "http://schema-registry:8081";
      };
    };
  };

  # Example 14: Message Queuing with TTL
  messageQueueConfigMap = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "queue-policies";
      namespace = "events";
    };
    data = {
      "policies.json" = ''
        {
          "queues": [
            {
              "name": "short-lived-events",
              "ttl": 3600,
              "maxRetries": 3
            },
            {
              "name": "persistent-events",
              "ttl": 604800,
              "maxRetries": 5
            },
            {
              "name": "high-priority-events",
              "ttl": 1800,
              "maxRetries": 10
            }
          ]
        }
      '';
    };
  };

  # Example 15: Event Enrichment Service
  eventEnrichmentService = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "event-enrichment";
      namespace = "events";
    };
    spec = {
      replicas = 2;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "event-enrichment";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "event-enrichment";
          };
        };
        spec = {
          containers = [{
            name = "enricher";
            image = "event-enrichment:v1.0";
            
            env = [
              { name = "KAFKA_INPUT_TOPIC"; value = "raw-events"; }
              { name = "KAFKA_OUTPUT_TOPIC"; value = "enriched-events"; }
              { name = "LOOKUP_SERVICE_URL"; value = "http://lookup-service:8080"; }
              { name = "CACHE_SIZE"; value = "10000"; }
            ];
            
            ports = [{
              containerPort = 8080;
              name = "http";
            }];
            
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
          }];
        };
      };
    };
  };

  # Example 16: Event Notification Handler
  notificationHandler = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "notification-handler";
      namespace = "events";
    };
    spec = {
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "notification-handler";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "notification-handler";
          };
        };
        spec = {
          containers = [{
            name = "handler";
            image = "notification-handler:v1.0";
            
            env = [
              { name = "MESSAGE_BROKER"; value = "rabbitmq"; }
              { name = "RABBITMQ_HOST"; value = "rabbitmq"; }
              { name = "RABBITMQ_PORT"; value = "5672"; }
              { name = "QUEUE_NAME"; value = "notifications"; }
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
          }];
        };
      };
    };
  };

  # Example 17: Event Audit Log
  auditLogConfiguration = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "audit-log-config";
      namespace = "events";
    };
    data = {
      "audit.yaml" = ''
        audit:
          enabled: true
          topics:
            - name: "audit-log"
              partitions: 6
              retention_days: 365
          retention_policy: "immutable"
          encryption: "AES256"
          compression: "gzip"
          indexing:
            enabled: true
            service: "elasticsearch"
      '';
    };
  };

  # Example 18: Cross-Cluster Replication
  kafkaMirrorMaker = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "kafka-mirror-maker";
      namespace = "events";
    };
    spec = {
      replicas = 2;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "kafka-mirror-maker";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "kafka-mirror-maker";
          };
        };
        spec = {
          containers = [{
            name = "mirror-maker";
            image = "confluentinc/cp-kafka:7.5.0";
            
            command = [
              "kafka-mirror-maker.sh"
              "--consumer.config"
              "/etc/kafka/source.properties"
              "--producer.config"
              "/etc/kafka/target.properties"
              "--whitelist"
              ".*"
            ];
            
            env = [
              { name = "KAFKA_HEAP_OPTS"; value = "-Xmx2G -Xms2G"; }
            ];
            
            resources = {
              requests = {
                cpu = "500m";
                memory = "2Gi";
              };
              limits = {
                cpu = "1";
                memory = "4Gi";
              };
            };
            
            volumeMounts = [{
              name = "config";
              mountPath = "/etc/kafka";
            }];
          }];
          
          volumes = [{
            name = "config";
            configMap = {
              name = "mirror-maker-config";
            };
          }];
        };
      };
    };
  };
}
