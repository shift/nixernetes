# Event Processing Module

## Overview

The Event Processing module provides comprehensive builders for deploying and managing event-driven systems on Kubernetes. It abstracts the complexity of message brokers, stream processors, and event pipelines, enabling developers to build scalable, real-time data processing systems with minimal configuration.

## Key Capabilities

### Message Brokers
- Apache Kafka with multi-broker clustering
- NATS with JetStream and hierarchical subscriptions
- RabbitMQ with virtual hosts and exchanges
- Apache Pulsar with multi-tenancy and geo-replication

### Topic & Stream Management
- Dynamic topic creation and configuration
- Partition management and rebalancing
- Topic retention policies (time-based, size-based)
- Schema registry integration

### Consumer Groups & Subscriptions
- Consumer group management with automatic rebalancing
- Multiple subscription modes (at-least-once, exactly-once, at-most-once)
- Offset management (earliest, latest, timestamp-based)
- Consumer lag monitoring

### Event Pipelines
- Multi-stage event processing pipelines
- Stream transformations and enrichment
- Windowing and aggregation operations
- Stateful processing with state management

### Dead Letter Queues
- Automatic DLQ configuration
- Retry policies with exponential backoff
- Poison pill message handling
- DLQ monitoring and alerting

### Schema Management
- Avro and Protobuf schema definitions
- Schema versioning and compatibility checking
- Schema evolution support
- Automatic schema validation

### Monitoring & Observability
- Real-time metrics collection
- Consumer lag tracking
- Message throughput monitoring
- End-to-end latency tracking
- Custom business metric support

## Core Builders

### mkKafkaCluster

Creates an Apache Kafka cluster with configurable replication and broker settings.

```nix
eventProcessing.mkKafkaCluster "kafka-production" {
  namespace = "events";
  
  # Cluster configuration
  version = "3.6";
  brokers = 3;
  
  # Storage configuration
  storage = {
    size = "100Gi";
    class = "fast-ssd";
    retainOnDelete = true;
  };
  
  # Broker configuration
  brokerConfig = {
    logRetentionHours = 168;  # 7 days
    logSegmentBytes = "1073741824";  # 1GB
    compressionType = "snappy";
    minInSyncReplicas = 2;
    defaultReplicationFactor = 3;
    offsetsTopicReplicationFactor = 3;
    transactionStateLogMinIsr = 2;
  };
  
  # ZooKeeper configuration (if not using Kraft)
  zookeeper = {
    enabled = false;  # Set to true for KRaft controller
    replicas = 3;
  };
  
  # Network configuration
  network = {
    type = "ClusterIP";  # ClusterIP | NodePort | LoadBalancer
    advertisedListeners = "PLAINTEXT://broker-{0}.kafka.{namespace}.svc.cluster.local:9092";
    securityProtocol = "SASL_SSL";  # PLAINTEXT | SSL | SASL_PLAINTEXT | SASL_SSL
  };
  
  # Security configuration
  security = {
    sasl = {
      enabled = true;
      mechanism = "SCRAM-SHA-512";  # SCRAM-SHA-256 | SCRAM-SHA-512 | PLAIN
      credentialSecret = "kafka-credentials";
    };
    ssl = {
      enabled = true;
      certificateSecret = "kafka-tls";
    };
    acl = {
      enabled = true;
      authorizer = "kafka.security.authorizer.AclAuthorizer";
    };
  };
  
  # Resource allocation
  resources = {
    broker = {
      requests = { cpu = "1000m"; memory = "2Gi"; };
      limits = { cpu = "2000m"; memory = "4Gi"; };
    };
  };
  
  # Monitoring
  monitoring = {
    enabled = true;
    prometheusExporter = true;
    exporterPort = 9308;
    jmxExporter = true;
    jmxPort = 9999;
  };
  
  # Replication configuration
  replication = {
    factorDefault = 3;
    minInSyncReplicas = 2;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| version | string | "3.6" | Kafka version |
| brokers | int | 3 | Number of broker replicas |
| storage | object | {} | Storage configuration |
| brokerConfig | object | {} | Kafka broker settings |
| zookeeper | object | {} | ZooKeeper configuration |
| network | object | {} | Network settings |
| security | object | {} | Security configuration |
| resources | object | {} | Resource allocation |
| monitoring | object | {} | Monitoring settings |
| replication | object | {} | Replication settings |

**Returns:** Kubernetes resources for Kafka cluster

**Usage Examples:**

```nix
# Development Kafka cluster
mkKafkaCluster "dev-kafka" {
  namespace = "dev";
  brokers = 1;
  storage.size = "20Gi";
};

# Production Kafka cluster
mkKafkaCluster "prod-kafka" {
  namespace = "events";
  brokers = 5;
  storage = {
    size = "200Gi";
    class = "fast-ssd";
  };
  security = {
    sasl.enabled = true;
    ssl.enabled = true;
  };
};
```

### mkNATSCluster

Creates a NATS cluster with JetStream support for persistent streaming.

```nix
eventProcessing.mkNATSCluster "nats-cluster" {
  namespace = "events";
  
  # Cluster configuration
  version = "2.10";
  replicas = 3;
  
  # JetStream configuration
  jetstream = {
    enabled = true;
    storage = {
      type = "file";  # file | memory
      size = "50Gi";
      class = "fast-ssd";
    };
    maxMemory = "20Gi";
    maxStore = "50Gi";
  };
  
  # Server configuration
  serverConfig = {
    maxConnections = 100000;
    maxSubs = 1000000;
    maxPayload = "1MB";
    writeDeadline = "10s";
    maxControlLine = "4096";
  };
  
  # Clustering configuration
  clustering = {
    enabled = true;
    name = "nats-cluster";
    routes = [];  # Auto-discovered within namespace
  };
  
  # Authentication
  auth = {
    enabled = true;
    method = "basic";  # basic | nkey | jwt
    users = {
      default = {
        password = { secretRef = "nats-credentials"; secretKey = "password"; };
        permissions = {
          publish = ">";
          subscribe = ">";
        };
      };
    };
  };
  
  # Resource configuration
  resources = {
    requests = { cpu = "500m"; memory = "512Mi"; };
    limits = { cpu = "2"; memory = "2Gi"; };
  };
  
  # Monitoring
  monitoring = {
    enabled = true;
    httpPort = 8222;
    prometheusExporter = true;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| version | string | "2.10" | NATS version |
| replicas | int | 3 | Number of replicas |
| jetstream | object | {} | JetStream settings |
| serverConfig | object | {} | Server configuration |
| clustering | object | {} | Clustering settings |
| auth | object | {} | Authentication |
| resources | object | {} | Resource allocation |
| monitoring | object | {} | Monitoring settings |

**Returns:** Kubernetes resources for NATS cluster

**Usage Examples:**

```nix
# NATS cluster with JetStream
mkNATSCluster "nats-prod" {
  namespace = "events";
  replicas = 5;
  jetstream = {
    enabled = true;
    storage.size = "100Gi";
  };
  monitoring.enabled = true;
};
```

### mkRabbitMQ

Creates a RabbitMQ cluster with high availability configuration.

```nix
eventProcessing.mkRabbitMQ "rabbitmq-cluster" {
  namespace = "events";
  
  # Cluster configuration
  version = "3.12";
  replicas = 3;
  
  # Disk space configuration
  diskFreeLimit = "2GB";
  memoryHighWatermark = 0.6;  # 60% of available memory
  
  # Storage configuration
  storage = {
    size = "50Gi";
    class = "fast-ssd";
  };
  
  # RabbitMQ plugins
  plugins = [
    "rabbitmq_management"
    "rabbitmq_federation"
    "rabbitmq_federation_management"
    "rabbitmq_shovel"
    "rabbitmq_shovel_management"
    "rabbitmq_consistent_hash_exchange"
    "rabbitmq_amqp1_0"
  ];
  
  # Virtual hosts
  virtualHosts = {
    "/" = {
      description = "Default virtual host";
    };
    "production" = {
      description = "Production workloads";
    };
    "staging" = {
      description = "Staging workloads";
    };
  };
  
  # User configuration
  users = {
    guest = {
      password = { secretRef = "rabbitmq-credentials"; secretKey = "guest-password"; };
      tags = [ "administrator" ];
      permissions = {
        "/" = {
          configure = ".*";
          write = ".*";
          read = ".*";
        };
      };
    };
    app_user = {
      password = { secretRef = "rabbitmq-credentials"; secretKey = "app-password"; };
      tags = [];
      permissions = {
        "production" = {
          configure = "^amq\\.";
          write = ".*";
          read = ".*";
        };
      };
    };
  };
  
  # Resource configuration
  resources = {
    requests = { cpu = "500m"; memory = "1Gi"; };
    limits = { cpu = "2"; memory = "2Gi"; };
  };
  
  # Monitoring
  monitoring = {
    enabled = true;
    prometheusExporter = true;
    managementPort = 15672;
  };
  
  # Persistence configuration
  persistence = {
    enabled = true;
    queue = {
      enabled = true;
    };
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| version | string | "3.12" | RabbitMQ version |
| replicas | int | 3 | Number of replicas |
| diskFreeLimit | string | "2GB" | Disk free limit |
| memoryHighWatermark | float | 0.6 | Memory watermark threshold |
| storage | object | {} | Storage configuration |
| plugins | list | [] | Enabled plugins |
| virtualHosts | object | {} | Virtual host definitions |
| users | object | {} | User definitions |
| resources | object | {} | Resource allocation |
| monitoring | object | {} | Monitoring settings |
| persistence | object | {} | Persistence settings |

**Returns:** Kubernetes resources for RabbitMQ cluster

**Usage Examples:**

```nix
# RabbitMQ cluster
mkRabbitMQ "rabbitmq-prod" {
  namespace = "events";
  replicas = 5;
  storage.size = "100Gi";
  monitoring.enabled = true;
};
```

### mkPulsarCluster

Creates an Apache Pulsar cluster with multi-tenancy and geo-replication.

```nix
eventProcessing.mkPulsarCluster "pulsar-cluster" {
  namespace = "events";
  
  # Cluster configuration
  version = "3.1";
  
  # Broker configuration
  brokers = 3;
  brokerResources = {
    requests = { cpu = "1"; memory = "2Gi"; };
    limits = { cpu = "2"; memory = "4Gi"; };
  };
  
  # BookKeeper configuration
  bookkeeper = {
    enabled = true;
    replicas = 3;
    resources = {
      requests = { cpu = "500m"; memory = "1Gi"; };
      limits = { cpu = "1"; memory = "2Gi"; };
    };
  };
  
  # ZooKeeper configuration
  zookeeper = {
    enabled = true;
    replicas = 3;
    resources = {
      requests = { cpu = "250m"; memory = "512Mi"; };
      limits = { cpu = "500m"; memory = "1Gi"; };
    };
  };
  
  # Storage configuration
  storage = {
    ledgers = {
      size = "50Gi";
      class = "fast-ssd";
    };
    journal = {
      size = "20Gi";
      class = "fast-ssd";
    };
  };
  
  # Multi-tenancy configuration
  tenants = {
    default = {
      admin_roles = [ "admin" ];
      allowed_clusters = [ "pulsar-cluster" ];
    };
  };
  
  # Geo-replication
  geoReplication = {
    enabled = false;
    replicationClusters = [];
  };
  
  # Monitoring
  monitoring = {
    enabled = true;
    prometheusExporter = true;
    metricsPort = 8080;
  };
  
  # Authentication
  authentication = {
    enabled = true;
    provider = "org.apache.pulsar.broker.authentication.AuthenticationProviderToken";
    tokenSecretKey = { secretRef = "pulsar-auth"; secretKey = "secret-key"; };
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| version | string | "3.1" | Pulsar version |
| brokers | int | 3 | Number of brokers |
| bookkeeper | object | {} | BookKeeper settings |
| zookeeper | object | {} | ZooKeeper settings |
| storage | object | {} | Storage configuration |
| tenants | object | {} | Tenant definitions |
| geoReplication | object | {} | Geo-replication settings |
| monitoring | object | {} | Monitoring settings |
| authentication | object | {} | Authentication settings |

**Returns:** Kubernetes resources for Pulsar cluster

**Usage Examples:**

```nix
# Pulsar cluster
mkPulsarCluster "pulsar-prod" {
  namespace = "events";
  brokers = 5;
  monitoring.enabled = true;
};
```

### mkKafkaTopic

Creates a Kafka topic with specific configuration and retention policies.

```nix
eventProcessing.mkKafkaTopic "user-events" {
  namespace = "events";
  cluster = "kafka-production";
  
  # Topic configuration
  partitions = 12;
  replicationFactor = 3;
  minInSyncReplicas = 2;
  
  # Retention policy
  retention = {
    timeMs = 604800000;  # 7 days
    bytes = "107374182400";  # 100GB
    policy = "delete";  # delete | compact | compact_delete
  };
  
  # Cleanup policy
  cleanupPolicy = "delete";
  
  # Compression
  compression = "snappy";
  
  # Message configuration
  messageMaxBytes = "1048576";  # 1MB
  segmentMs = "86400000";  # 1 day
  
  # Leader election
  uncleanLeaderElection = false;
  
  # Access control
  acl = [
    {
      principal = "User:app-user";
      operation = "Read";
      resourceName = "user-events";
    }
    {
      principal = "User:producer";
      operation = "Write";
      resourceName = "user-events";
    }
  ];
  
  # Monitoring
  monitoring = {
    enabled = true;
    trackIncomingByteRate = true;
    trackOutgoingByteRate = true;
    trackMessageRate = true;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| cluster | string | required | Kafka cluster name |
| partitions | int | 3 | Number of partitions |
| replicationFactor | int | 3 | Replication factor |
| minInSyncReplicas | int | 2 | Minimum in-sync replicas |
| retention | object | {} | Retention policy |
| compression | string | "snappy" | Compression type |
| messageMaxBytes | string | "1MB" | Maximum message size |
| acl | list | [] | ACL rules |
| monitoring | object | {} | Monitoring settings |

**Returns:** Kafka topic configuration resource

**Usage Examples:**

```nix
# User events topic
mkKafkaTopic "user-events" {
  namespace = "events";
  cluster = "kafka-prod";
  partitions = 24;
  retention.timeMs = 604800000;
};

# Log compaction topic
mkKafkaTopic "config-changelog" {
  namespace = "events";
  cluster = "kafka-prod";
  partitions = 1;
  cleanupPolicy = "compact";
};
```

### mkConsumerGroup

Configures a Kafka consumer group with scaling and offset management.

```nix
eventProcessing.mkConsumerGroup "order-processor" {
  namespace = "events";
  cluster = "kafka-production";
  
  # Consumer group configuration
  groupId = "order-processor";
  topics = [ "orders" "order-updates" ];
  
  # Offset management
  offsetReset = "earliest";  # earliest | latest
  enableAutoCommit = true;
  autoCommitInterval = 5000;  # milliseconds
  sessionTimeout = 30000;
  
  # Consumer configuration
  consumers = {
    maxPollRecords = 500;
    maxPollInterval = 300000;  # 5 minutes
    fetchMinBytes = 1024;  # 1KB
    fetchMaxWaitMs = 500;
  };
  
  # Partition assignment strategy
  partitionAssignment = "range";  # range | roundRobin | sticky | cooperative-sticky
  
  # Performance tuning
  connections = {
    maxIdleMs = 540000;  # 9 minutes
    retries = 2147483647;
    retryBackoffMs = 100;
  };
  
  # Consumer deployment
  deployment = {
    replicas = 3;
    image = "order-processor:v1.0";
    resources = {
      requests = { cpu = "500m"; memory = "512Mi"; };
      limits = { cpu = "1"; memory = "1Gi"; };
    };
  };
  
  # Monitoring
  monitoring = {
    enabled = true;
    lagAlert = {
      threshold = 10000;  # messages
      severity = "warning";
    };
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| cluster | string | required | Kafka cluster name |
| groupId | string | required | Consumer group ID |
| topics | list | required | Topics to consume |
| offsetReset | string | "latest" | Offset reset policy |
| enableAutoCommit | bool | true | Auto-commit offsets |
| autoCommitInterval | int | 5000 | Auto-commit interval (ms) |
| consumers | object | {} | Consumer settings |
| partitionAssignment | string | "range" | Assignment strategy |
| deployment | object | {} | Deployment configuration |
| monitoring | object | {} | Monitoring settings |

**Returns:** Consumer group configuration resources

**Usage Examples:**

```nix
# Order processing consumer group
mkConsumerGroup "order-processor" {
  namespace = "events";
  cluster = "kafka-prod";
  topics = [ "orders" ];
  deployment.replicas = 5;
};
```

### mkDeadLetterQueue

Configures dead letter queue handling for failed messages.

```nix
eventProcessing.mkDeadLetterQueue "order-processor-dlq" {
  namespace = "events";
  broker = "kafka-production";
  
  # Source configuration
  source = {
    topic = "orders";
    consumerGroup = "order-processor";
  };
  
  # DLQ configuration
  dlq = {
    topic = "orders-dlq";
    partitions = 3;
    replicationFactor = 3;
    retention = {
      timeMs = 2592000000;  # 30 days
      bytes = "10737418240";  # 10GB
    };
  };
  
  # Retry policy
  retryPolicy = {
    maxRetries = 3;
    backoffMs = 1000;
    backoffMultiplier = 2.0;
    maxBackoffMs = 32000;
  };
  
  # Error classification
  errorHandling = {
    transientErrors = [
      "TemporaryNetworkFailure"
      "ResourceUnavailable"
      "Timeout"
    ];
    permanentErrors = [
      "InvalidMessage"
      "SchemaValidationFailure"
      "ProcessingError"
    ];
  };
  
  # Processing
  processing = {
    enabled = true;
    handler = "dlq-processor:v1.0";
    resources = {
      requests = { cpu = "200m"; memory = "256Mi"; };
      limits = { cpu = "500m"; memory = "512Mi"; };
    };
  };
  
  # Monitoring and alerting
  monitoring = {
    enabled = true;
    alerts = {
      dlqThreshold = 100;  # messages
      severity = "warning";
    };
    trackDuration = true;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| broker | string | required | Message broker name |
| source | object | required | Source configuration |
| dlq | object | required | DLQ configuration |
| retryPolicy | object | {} | Retry policy settings |
| errorHandling | object | {} | Error classification |
| processing | object | {} | DLQ processing |
| monitoring | object | {} | Monitoring settings |

**Returns:** Dead letter queue configuration resources

**Usage Examples:**

```nix
# DLQ for payment processor
mkDeadLetterQueue "payment-processor-dlq" {
  namespace = "events";
  broker = "kafka-prod";
  source = {
    topic = "payments";
    consumerGroup = "payment-processor";
  };
  retryPolicy.maxRetries = 5;
};
```

### mkSchemaRegistry

Configures schema registry for schema management and validation.

```nix
eventProcessing.mkSchemaRegistry "schema-registry" {
  namespace = "events";
  
  # Schema Registry configuration
  replicas = 3;
  
  # Kafka backend
  kafka = {
    brokers = "kafka-production:9092";
    topic = "_schemas";
    replicationFactor = 3;
  };
  
  # Storage backend (for non-Kafka deployments)
  storage = {
    type = "in-memory";  # in-memory | mysql | postgresql | mongodb
  };
  
  # Compatibility levels
  compatibility = {
    defaultLevel = "BACKWARD_TRANSITIVE";
    levels = [
      "NONE"
      "BACKWARD"
      "FORWARD"
      "FULL"
      "BACKWARD_TRANSITIVE"
      "FORWARD_TRANSITIVE"
      "FULL_TRANSITIVE"
    ];
  };
  
  # Schema formats
  schemaFormats = {
    avro = {
      enabled = true;
    };
    protobuf = {
      enabled = true;
    };
    jsonSchema = {
      enabled = true;
    };
  };
  
  # Authentication
  authentication = {
    enabled = true;
    users = {
      admin = {
        password = { secretRef = "schema-registry-credentials"; secretKey = "admin-password"; };
      };
    };
  };
  
  # Resource configuration
  resources = {
    requests = { cpu = "500m"; memory = "512Mi"; };
    limits = { cpu = "1"; memory = "1Gi"; };
  };
  
  # API server configuration
  apiServer = {
    port = 8081;
    threads = 8;
  };
  
  # Monitoring
  monitoring = {
    enabled = true;
    prometheusExporter = true;
    metricsPort = 9092;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| replicas | int | 3 | Number of replicas |
| kafka | object | required | Kafka backend config |
| compatibility | object | {} | Compatibility settings |
| schemaFormats | object | {} | Supported schema formats |
| authentication | object | {} | Authentication settings |
| resources | object | {} | Resource allocation |
| apiServer | object | {} | API server settings |
| monitoring | object | {} | Monitoring settings |

**Returns:** Schema registry deployment resources

**Usage Examples:**

```nix
# Schema registry with Kafka backend
mkSchemaRegistry "schema-registry" {
  namespace = "events";
  kafka.brokers = "kafka-prod:9092";
  compatibility.defaultLevel = "BACKWARD";
};
```

### mkEventPipeline

Configures an end-to-end event processing pipeline.

```nix
eventProcessing.mkEventPipeline "order-fulfillment" {
  namespace = "events";
  
  # Pipeline metadata
  description = "Order fulfillment event pipeline";
  owner = "fulfillment-team";
  
  # Source configuration
  source = {
    type = "kafka";  # kafka | nats | rabbitmq | pulsar
    cluster = "kafka-production";
    topic = "orders";
    consumerGroup = "order-fulfillment";
    partitions = 12;
    startOffset = "latest";
  };
  
  # Processing stages
  stages = [
    {
      name = "validation";
      type = "filter";
      condition = "payload.status == 'pending'";
      resources = {
        requests = { cpu = "100m"; memory = "128Mi"; };
      };
    }
    {
      name = "enrichment";
      type = "transform";
      transformer = "fulfillment-enricher:v1.0";
      lookupServices = [ "customer-service" "inventory-service" ];
      resources = {
        requests = { cpu = "500m"; memory = "512Mi"; };
        limits = { cpu = "1"; memory = "1Gi"; };
      };
    }
    {
      name = "aggregation";
      type = "window";
      windowSize = "5m";
      windowType = "tumbling";  # tumbling | sliding | session
      aggregation = "count";
      resources = {
        requests = { cpu = "250m"; memory = "256Mi"; };
      };
    }
  ];
  
  # Sink configuration
  sink = {
    type = "kafka";  # kafka | elasticsearch | database | s3
    cluster = "kafka-production";
    topic = "order-events-processed";
    partitionKey = "order_id";
  };
  
  # Stateful processing
  stateManagement = {
    enabled = true;
    backend = "rocksdb";  # rocksdb | redis | kafka
    ttl = "7d";
  };
  
  # Error handling
  errorHandling = {
    dlq = "order-fulfillment-dlq";
    maxRetries = 3;
    onError = "dlq";  # dlq | skip | fail
  };
  
  # Monitoring
  monitoring = {
    enabled = true;
    trackLatency = true;
    trackThroughput = true;
    trackErrors = true;
    metricsInterval = 30;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| description | string | "" | Pipeline description |
| source | object | required | Source configuration |
| stages | list | required | Processing stages |
| sink | object | required | Sink configuration |
| stateManagement | object | {} | State management |
| errorHandling | object | {} | Error handling |
| monitoring | object | {} | Monitoring settings |

**Returns:** Event pipeline deployment resources

**Usage Examples:**

```nix
# Order processing pipeline
mkEventPipeline "order-processor" {
  namespace = "events";
  source = {
    type = "kafka";
    cluster = "kafka-prod";
    topic = "orders";
  };
  stages = [ /* transformation stages */ ];
  sink = {
    type = "kafka";
    topic = "processed-orders";
  };
};
```

### mkEventMonitoring

Configures comprehensive monitoring for event systems.

```nix
eventProcessing.mkEventMonitoring "event-monitoring" {
  namespace = "monitoring";
  
  # Target configuration
  targets = {
    kafka = {
      enabled = true;
      clusters = [ "kafka-production" ];
      brokerMetrics = true;
      topicMetrics = true;
      consumerMetrics = true;
    };
    nats = {
      enabled = false;
      clusters = [];
    };
  };
  
  # Metrics to collect
  metrics = {
    brokers = [
      "kafka.broker:type=ReplicaManager,name=LeaderCount"
      "kafka.broker:type=ReplicaManager,name=UnderReplicatedPartitions"
    ];
    
    topics = [
      "kafka.server:type=BrokerTopicMetrics,name=MessagesInPerSec"
      "kafka.server:type=BrokerTopicMetrics,name=BytesInPerSec"
      "kafka.server:type=BrokerTopicMetrics,name=BytesOutPerSec"
    ];
    
    consumers = [
      "kafka.consumer:type=consumer-fetch-manager-metrics,client-id=*"
      "kafka.consumer:type=consumer-coordinator-metrics,client-id=*"
    ];
  };
  
  # Prometheus integration
  prometheus = {
    enabled = true;
    scrapeInterval = 30;  # seconds
    retention = 15;  # days
  };
  
  # Alert rules
  alerts = {
    brokerDown = {
      enabled = true;
      severity = "critical";
      condition = "up == 0";
      duration = "5m";
    };
    
    highConsumerLag = {
      enabled = true;
      severity = "warning";
      condition = "consumer_lag > 100000";
      duration = "10m";
    };
    
    topicReplicationIssues = {
      enabled = true;
      severity = "critical";
      condition = "replication_factor != in_sync_replicas";
      duration = "2m";
    };
    
    lowThroughput = {
      enabled = true;
      severity = "warning";
      condition = "rate(messages_in[5m]) < 1000";
      duration = "15m";
    };
  };
  
  # Dashboards
  dashboards = {
    enabled = true;
    grafanaEnabled = true;
    dashboards = [
      "kafka-overview"
      "kafka-brokers"
      "kafka-topics"
      "kafka-consumers"
      "event-pipeline-health"
    ];
  };
  
  # Custom metrics
  customMetrics = [
    {
      name = "event_processing_latency";
      type = "histogram";
      buckets = [ 10 50 100 500 1000 5000 ];
    }
    {
      name = "event_processing_errors";
      type = "counter";
    }
  ];
  
  # Tracing
  tracing = {
    enabled = true;
    jaeger = true;
    tracingSampling = 0.1;  # 10% sampling
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| targets | object | {} | Monitoring targets |
| metrics | object | {} | Metrics to collect |
| prometheus | object | {} | Prometheus settings |
| alerts | object | {} | Alert rules |
| dashboards | object | {} | Dashboard settings |
| customMetrics | list | [] | Custom metrics |
| tracing | object | {} | Distributed tracing |

**Returns:** Monitoring configuration resources

**Usage Examples:**

```nix
# Kafka monitoring setup
mkEventMonitoring "kafka-monitoring" {
  namespace = "monitoring";
  targets.kafka = {
    enabled = true;
    clusters = [ "kafka-prod" ];
  };
  alerts.brokerDown.enabled = true;
  dashboards.enabled = true;
};
```

## Integration Patterns

### Kafka to Elasticsearch Pipeline

Stream Kafka events to Elasticsearch:

```nix
let
  kafkaTopic = mkKafkaTopic "user-events" {
    namespace = "events";
    cluster = "kafka-prod";
    partitions = 12;
  };
  
  pipeline = mkEventPipeline "kafka-to-es" {
    namespace = "events";
    source = {
      type = "kafka";
      cluster = "kafka-prod";
      topic = "user-events";
    };
    sink = {
      type = "elasticsearch";
      cluster = "elasticsearch-prod";
      index = "user-events";
    };
  };
in
{ inherit kafkaTopic pipeline; }
```

### Event Driven Architecture

Implement event-driven architecture with microservices:

```nix
{
  kafka = mkKafkaCluster "event-bus" { /* ... */ };
  
  orderService = mkEventPipeline "order-service" {
    source = { type = "kafka"; topic = "order-commands"; };
    sink = { type = "kafka"; topic = "order-events"; };
  };
  
  inventoryService = mkEventPipeline "inventory-service" {
    source = { type = "kafka"; topic = "order-events"; };
    sink = { type = "kafka"; topic = "inventory-events"; };
  };
  
  shippingService = mkEventPipeline "shipping-service" {
    source = { type = "kafka"; topic = "inventory-events"; };
    sink = { type = "kafka"; topic = "shipping-events"; };
  };
}
```

## Best Practices

### Partitioning Strategy

1. **Use natural partition keys** (user_id, order_id, etc.)
2. **Distribute evenly** across partitions
3. **Consider ordering requirements** (same key = same partition)
4. **Monitor partition skew** for hot partitions

### Consumer Group Management

1. **Match consumer replicas to partition count**
2. **Use appropriate offset reset policy**
3. **Monitor consumer lag** continuously
4. **Implement graceful shutdown**

### Schema Management

1. **Use versioned schemas** from registry
2. **Validate all messages** against schema
3. **Plan for schema evolution**
4. **Test compatibility** before deploying

### Error Handling

1. **Implement dead letter queues** for all pipelines
2. **Classify errors** (transient vs permanent)
3. **Use appropriate retry strategies**
4. **Monitor DLQ** for issues

### Performance Optimization

1. **Batch message processing** for throughput
2. **Tune batch size** based on latency requirements
3. **Use compression** (snappy for latency, gzip for throughput)
4. **Monitor and tune resource allocation**

## Troubleshooting Guide

### Consumer Lag Growing

**Symptoms:** Consumer lag continuously increasing

**Solutions:**
- Increase consumer replicas
- Optimize processing logic
- Check for slow external calls
- Monitor and tune resource allocation

### Message Loss

**Symptoms:** Expected messages not received

**Solutions:**
- Check replication factor (should be 3+)
- Verify retention policies
- Confirm min.insync.replicas setting
- Check producer acknowledgments

### High Latency

**Symptoms:** End-to-end latency unacceptable

**Solutions:**
- Reduce batch size
- Optimize processing stages
- Check network latency
- Monitor broker performance

### Leader Election Issues

**Symptoms:** Frequent leader elections, unavailability

**Solutions:**
- Check broker disk space
- Verify network connectivity
- Monitor broker logs
- Check resource allocation

## Related Modules

- **BATCH_PROCESSING**: Event-triggered batch jobs
- **DATABASE_MANAGEMENT**: Event-sourced databases
- **MONITORING**: Event system monitoring

## References

- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [NATS Documentation](https://docs.nats.io/)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)
- [Apache Pulsar Documentation](https://pulsar.apache.org/docs/)
