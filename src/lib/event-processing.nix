# Nixernetes Event Processing Module
# Enterprise event streaming and pub/sub infrastructure

{ lib }:

let
  inherit (lib) attrValues filterAttrs mapAttrs mkDefault mkIf mkMerge types;

  framework = {
    name = "event-processing";
    version = "1.0.0";
    description = "Enterprise event streaming and pub/sub infrastructure";
    features = [
      "Apache Kafka cluster deployment"
      "NATS messaging system"
      "RabbitMQ message broker"
      "Apache Pulsar streaming"
      "Event topic management"
      "Consumer group configuration"
      "Retention policies"
      "Partition and replication"
      "Dead letter queues"
      "Monitoring and metrics"
      "Event schema registry"
      "Async communication patterns"
    ];
  };

  mkFrameworkLabels = {
    "nixernetes.io/framework" = "event-processing";
    "nixernetes.io/event-layer" = "messaging";
    "app.kubernetes.io/component" = "event-processing";
  };

  validateKafkaConfig = config:
    assert lib.assertMsg (config.name != null) "Kafka requires name";
    assert lib.assertMsg (config.replicas != null) "Kafka requires replicas";
    config;

  validateNATSConfig = config:
    assert lib.assertMsg (config.name != null) "NATS requires name";
    config;

  validateRabbitMQConfig = config:
    assert lib.assertMsg (config.name != null) "RabbitMQ requires name";
    config;

  validatePulsarConfig = config:
    assert lib.assertMsg (config.name != null) "Pulsar requires name";
    config;

in {
  inherit framework;

  # Builder 1: Apache Kafka Cluster
  mkKafkaCluster = config: validateKafkaConfig (
    let
      cfg = {
        name = null;
        namespace = "kafka";
        version = "3.5.0";
        replicas = 3;
        brokerResources = {
          cpu = "1000m";
          memory = "2Gi";
          limits = {
            cpu = "2000m";
            memory = "4Gi";
          };
        };
        storage = {
          size = "100Gi";
          storageClass = "fast-ssd";
          type = "persistent";
        };
        replication = {
          enabled = true;
          factor = 3;
          minInsyncReplicas = 2;
        };
        retention = {
          size = "100Gi";
          time = "604800s"; # 7 days
          cleanupPolicy = "delete"; # delete, compact
        };
        monitoring = {
          enabled = true;
          metricsPort = 9308;
        };
        security = {
          tls = true;
          sasl = true;
          saslMechanism = "SCRAM-SHA-512";
        };
      } // config;
    in {
      apiVersion = "kafka.strimzi.io/v1beta2";
      kind = "Kafka";
      metadata = {
        name = cfg.name;
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/event-type" = "kafka";
          "nixernetes.io/event-version" = cfg.version;
        };
      };
      spec = {
        kafka = {
          version = cfg.version;
          replicas = cfg.replicas;
          storage = {
            type = "persistent-claim";
            size = cfg.storage.size;
            class = cfg.storage.storageClass;
          };
          config = {
            log.retention.bytes = 107374182400; # 100GB
            log.retention.ms = 604800000; # 7 days
            log.cleanup.policy = cfg.retention.cleanupPolicy;
            min.insync.replicas = cfg.replication.minInsyncReplicas;
            default.replication.factor = cfg.replication.factor;
          };
          resources = {
            requests = {
              cpu = cfg.brokerResources.cpu;
              memory = cfg.brokerResources.memory;
            };
            limits = cfg.brokerResources.limits;
          };
          metrics = mkIf cfg.monitoring.enabled [
            {
              lowercaseOutputName = true;
              rules = [];
            }
          ];
        };
        zookeeper = {
          replicas = 3;
          storage = {
            type = "persistent-claim";
            size = "10Gi";
            class = cfg.storage.storageClass;
          };
        };
      };
    }
  );

  # Builder 2: NATS Server Cluster
  mkNATSCluster = config: validateNATSConfig (
    let
      cfg = {
        name = null;
        namespace = "nats";
        version = "2.10.0";
        replicas = 3;
        jetstream = {
          enabled = true;
          storage = "100Gi";
          storageClass = "standard";
        };
        resources = {
          cpu = "500m";
          memory = "1Gi";
          limits = {
            cpu = "1000m";
            memory = "2Gi";
          };
        };
        clustering = {
          enabled = true;
          routes = 3;
        };
        security = {
          tls = true;
          auth = true;
        };
        monitoring = {
          enabled = true;
          port = 8222;
        };
      } // config;
    in {
      apiVersion = "nats.io/v1alpha2";
      kind = "NatsCluster";
      metadata = {
        name = cfg.name;
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/event-type" = "nats";
          "nixernetes.io/event-version" = cfg.version;
        };
      };
      spec = {
        size = cfg.replicas;
        version = cfg.version;
        pod = {
          resources = {
            requests = {
              cpu = cfg.resources.cpu;
              memory = cfg.resources.memory;
            };
            limits = cfg.resources.limits;
          };
        };
        serverImage = "nats:${cfg.version}-alpine";
      };
    }
  );

  # Builder 3: RabbitMQ Broker
  mkRabbitMQ = config: validateRabbitMQConfig (
    let
      cfg = {
        name = null;
        namespace = "rabbitmq";
        version = "3.12.0";
        replicas = 3;
        resources = {
          cpu = "1000m";
          memory = "2Gi";
          limits = {
            cpu = "2000m";
            memory = "4Gi";
          };
        };
        storage = {
          size = "100Gi";
          storageClass = "standard";
        };
        clustering = {
          enabled = true;
          partition_mode = "autoheal";
        };
        plugins = [
          "rabbitmq_management"
          "rabbitmq_management_agent"
          "rabbitmq_amqp1_0"
        ];
        security = {
          tls = true;
          tlsMode = "automatic";
        };
      } // config;
    in {
      apiVersion = "rabbitmq.com/v1beta1";
      kind = "RabbitmqCluster";
      metadata = {
        name = cfg.name;
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/event-type" = "rabbitmq";
          "nixernetes.io/event-version" = cfg.version;
        };
      };
      spec = {
        image = "rabbitmq:${cfg.version}-management-alpine";
        replicas = cfg.replicas;
        persistence = {
          storage = cfg.storage.size;
          storageClassName = cfg.storage.storageClass;
        };
        resources = {
          requests = {
            cpu = cfg.resources.cpu;
            memory = cfg.resources.memory;
          };
          limits = cfg.resources.limits;
        };
        rabbitmq = {
          additionalConfig = "cluster_partition_handling = autoheal\n";
          advancedConfig = "[]";
        };
      };
    }
  );

  # Builder 4: Apache Pulsar Cluster
  mkPulsarCluster = config: validatePulsarConfig (
    let
      cfg = {
        name = null;
        namespace = "pulsar";
        version = "3.0.0";
        replicas = 3;
        brokerResources = {
          cpu = "1000m";
          memory = "2Gi";
          limits = {
            cpu = "2000m";
            memory = "4Gi";
          };
        };
        storage = {
          size = "100Gi";
          storageClass = "standard";
        };
        functions = {
          enabled = true;
          workerReplicas = 2;
        };
        tieredStorage = {
          enabled = false;
          type = "s3";
        };
        replication = {
          enabled = true;
          factor = 3;
        };
      } // config;
    in {
      apiVersion = "pulsar.apache.org/v1alpha1";
      kind = "PulsarCluster";
      metadata = {
        name = cfg.name;
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/event-type" = "pulsar";
          "nixernetes.io/event-version" = cfg.version;
        };
      };
      spec = {
        image = "apachepulsar/pulsar:v${cfg.version}";
        pulsar = {
          version = cfg.version;
        };
        broker = {
          replicas = cfg.replicas;
          resources = {
            requests = {
              cpu = cfg.brokerResources.cpu;
              memory = cfg.brokerResources.memory;
            };
            limits = cfg.brokerResources.limits;
          };
        };
        bookkeeper = {
          replicas = cfg.replicas;
          storage = {
            size = cfg.storage.size;
            class = cfg.storage.storageClass;
          };
        };
        zookeeper = {
          replicas = cfg.replicas;
        };
      };
    }
  );

  # Builder 5: Kafka Topic Configuration
  mkKafkaTopic = config:
    let
      cfg = {
        name = null;
        cluster = null;
        namespace = "kafka";
        partitions = 3;
        replicationFactor = 3;
        minInsyncReplicas = 2;
        retention = {
          time = "604800000"; # 7 days
          size = "1073741824"; # 1GB
          cleanupPolicy = "delete";
        };
        compression = "snappy";
        config = {};
      } // config;
    in {
      apiVersion = "kafka.strimzi.io/v1beta2";
      kind = "KafkaTopic";
      metadata = {
        name = cfg.name;
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/event-type" = "kafka-topic";
          "strimzi.io/cluster" = cfg.cluster;
        };
      };
      spec = {
        partitions = cfg.partitions;
        replication.factor = cfg.replicationFactor;
        config = {
          "min.insync.replicas" = builtins.toString cfg.minInsyncReplicas;
          "retention.ms" = cfg.retention.time;
          "retention.bytes" = cfg.retention.size;
          "cleanup.policy" = cfg.retention.cleanupPolicy;
          "compression.type" = cfg.compression;
        } // cfg.config;
      };
    };

  # Builder 6: Consumer Group Configuration
  mkConsumerGroup = config:
    let
      cfg = {
        name = null;
        namespace = "kafka";
        brokers = [];
        topics = [];
        consumerCount = 1;
        sessionTimeout = 30000;
        heartbeatInterval = 10000;
        offsetReset = "earliest";
        parallelism = 1;
      } // config;
    in {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "${cfg.name}-consumer-config";
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/event-type" = "consumer-group";
        };
      };
      data = {
        CONSUMER_GROUP = cfg.name;
        BOOTSTRAP_SERVERS = lib.concatStringsSep "," cfg.brokers;
        TOPICS = lib.concatStringsSep "," cfg.topics;
        SESSION_TIMEOUT = builtins.toString cfg.sessionTimeout;
        HEARTBEAT_INTERVAL = builtins.toString cfg.heartbeatInterval;
        AUTO_OFFSET_RESET = cfg.offsetReset;
        PARALLELISM = builtins.toString cfg.parallelism;
      };
    };

  # Builder 7: Dead Letter Queue Configuration
  mkDeadLetterQueue = config:
    let
      cfg = {
        name = null;
        namespace = "kafka";
        sourceTopics = [];
        maxRetries = 3;
        retryBackoff = 5000; # milliseconds
        destination = "dlq-${cfg.name}";
        monitoring = {
          enabled = true;
          alertThreshold = 100;
        };
      } // config;
    in {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "${cfg.name}-dlq-config";
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/event-type" = "dead-letter-queue";
        };
      };
      data = {
        DLQ_NAME = cfg.name;
        SOURCE_TOPICS = lib.concatStringsSep "," cfg.sourceTopics;
        MAX_RETRIES = builtins.toString cfg.maxRetries;
        RETRY_BACKOFF = builtins.toString cfg.retryBackoff;
        DESTINATION_TOPIC = cfg.destination;
        MONITORING_ENABLED = builtins.toString cfg.monitoring.enabled;
      };
    };

  # Builder 8: Event Schema Registry
  mkSchemaRegistry = config:
    let
      cfg = {
        name = null;
        namespace = "kafka";
        version = "7.5.0";
        replicas = 2;
        kafkaBootstrap = "kafka-cluster:9092";
        compatibility = {
          level = "BACKWARD"; # BACKWARD, FORWARD, FULL, NONE
          mode = "CREATE"; # CREATE, MODIFY, READ_ONLY
        };
        storage = {
          type = "kafka";
        };
        resources = {
          cpu = "500m";
          memory = "512Mi";
        };
      } // config;
    in {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "${cfg.name}-schema-registry-config";
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/event-type" = "schema-registry";
        };
      };
      data = {
        SCHEMA_REGISTRY_HOST_NAME = "${cfg.name}-schema-registry";
        SCHEMA_REGISTRY_KAFKASTORE_BOOTSTRAP_SERVERS = cfg.kafkaBootstrap;
        SCHEMA_REGISTRY_COMPATIBILITY_LEVEL = cfg.compatibility.level;
        SCHEMA_REGISTRY_MODE_MUTABILITY = cfg.compatibility.mode;
      };
    };

  # Builder 9: Event Streaming Pipeline
  mkEventPipeline = config:
    let
      cfg = {
        name = null;
        namespace = "kafka";
        eventType = "streaming"; # streaming, batch, hybrid
        source = {
          type = "kafka";
          topics = [];
        };
        transformations = [];
        sink = {
          type = "database";
          destination = null;
        };
        errorHandling = {
          strategy = "dlq"; # dlq, retry, skip
          maxRetries = 3;
        };
      } // config;
    in {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "${cfg.name}-pipeline-config";
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/event-type" = "event-pipeline";
          "nixernetes.io/pipeline-type" = cfg.eventType;
        };
      };
      data = {
        PIPELINE_NAME = cfg.name;
        SOURCE_TYPE = cfg.source.type;
        SOURCE_TOPICS = lib.concatStringsSep "," cfg.source.topics;
        SINK_TYPE = cfg.sink.type;
        ERROR_HANDLING_STRATEGY = cfg.errorHandling.strategy;
        MAX_RETRIES = builtins.toString cfg.errorHandling.maxRetries;
      };
    };

  # Builder 10: Event Monitoring and Metrics
  mkEventMonitoring = config:
    let
      cfg = {
        name = null;
        namespace = "kafka";
        enabled = true;
        metrics = {
          brokerMetrics = true;
          topicMetrics = true;
          consumerMetrics = true;
          producerMetrics = true;
        };
        logging = {
          enabled = true;
          level = "INFO";
          format = "json";
        };
        alerts = {
          enabled = true;
          highLatency = true;
          consumerLag = true;
          brokerDown = true;
        };
      } // config;
    in {
      apiVersion = "v1";
      kind = "ConfigMap";
      metadata = {
        name = "${cfg.name}-monitoring-config";
        namespace = cfg.namespace;
        labels = mkFrameworkLabels // {
          "nixernetes.io/event-type" = "monitoring";
        };
      };
      data = {
        MONITORING_ENABLED = builtins.toString cfg.enabled;
        BROKER_METRICS_ENABLED = builtins.toString cfg.metrics.brokerMetrics;
        TOPIC_METRICS_ENABLED = builtins.toString cfg.metrics.topicMetrics;
        CONSUMER_METRICS_ENABLED = builtins.toString cfg.metrics.consumerMetrics;
        PRODUCER_METRICS_ENABLED = builtins.toString cfg.metrics.producerMetrics;
        LOGGING_ENABLED = builtins.toString cfg.logging.enabled;
        LOGGING_LEVEL = cfg.logging.level;
        ALERTS_ENABLED = builtins.toString cfg.alerts.enabled;
      };
    };

  mkFramework = {
    name = framework.name;
    version = framework.version;
    description = framework.description;
    features = framework.features;
  };
}
