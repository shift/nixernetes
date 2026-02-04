# Database Management Module

## Overview

The Database Management module provides comprehensive builders for deploying, configuring, and managing production-grade databases on Kubernetes. It abstracts away the complexity of database configuration, high availability setup, backup strategies, and performance tuning, enabling operators to deploy resilient data systems with minimal configuration.

## Key Capabilities

### Database Support
- PostgreSQL with streaming replication and logical decoding
- MySQL with Group Replication and semi-synchronous replication
- MongoDB with replica sets and sharded clusters
- Redis with sentinel and cluster modes
- Multi-version support for all databases

### High Availability & Replication
- Master-slave replication with automatic failover
- Multi-master replication with conflict resolution
- Synchronous and asynchronous replication options
- Read replicas with load balancing
- Failover management with health checks

### Backup & Recovery
- Point-in-time recovery (PITR) capabilities
- Incremental and full backups
- Multiple backup destinations (S3, GCS, local storage)
- Backup verification and testing
- Automated backup scheduling
- Disaster recovery procedures

### Security
- TLS/SSL encryption for data in transit
- Encryption at rest with key management
- Role-based access control (RBAC)
- Network policies and firewalls
- Secret management for credentials
- Audit logging

### Performance & Monitoring
- Connection pooling and query optimization
- Indexing strategies and optimization
- Resource allocation and scaling
- Real-time performance metrics
- Query analysis and slow query logging
- Custom alerts and health checks

## Core Builders

### mkPostgreSQL

Creates a PostgreSQL database deployment with configurable replication and HA setup.

```nix
databaseManagement.mkPostgreSQL "production-db" {
  namespace = "databases";
  
  # PostgreSQL configuration
  version = "15";
  replicas = 3;
  
  # Storage configuration
  storage = {
    size = "50Gi";
    class = "fast-ssd";
    retainOnDelete = true;
  };
  
  # Database configuration
  databases = {
    primary = {
      name = "production";
      owner = "app_user";
      encoding = "UTF8";
      locale = "en_US.UTF-8";
    };
  };
  
  # User configuration
  users = {
    app_user = {
      password = { secretRef = "postgres-passwords"; secretKey = "app_user"; };
      roles = [ "CREATEDB" "CONNECT" ];
      databases = [ "production" ];
    };
    replication_user = {
      password = { secretRef = "postgres-passwords"; secretKey = "replication_user"; };
      roles = [ "REPLICATION" "CONNECT" ];
    };
  };
  
  # Replication configuration
  replication = {
    type = "streaming";  # streaming | logical
    mode = "synchronous";  # synchronous | asynchronous
    maxWalSenders = 10;
    walKeepSize = "1GB";
    synchronousCommit = "on";
  };
  
  # Backup configuration
  backup = {
    enabled = true;
    schedule = "0 2 * * *";  # Daily at 2am
    retentionDays = 30;
    destination = {
      type = "s3";
      bucket = "database-backups";
      prefix = "postgres/";
      credentialSecret = "s3-credentials";
    };
  };
  
  # Connection pooling
  connectionPool = {
    enabled = true;
    minConnections = 10;
    maxConnections = 100;
    idleTimeout = 300;
    validationQuery = "SELECT 1";
  };
  
  # Performance tuning
  performance = {
    sharedBuffers = "8GB";
    effectiveCacheSize = "24GB";
    maintenanceWorkMemory = "2GB";
    walBuffers = "16MB";
    workMem = "20MB";
    maxParallelWorkers = 8;
  };
  
  # Monitoring configuration
  monitoring = {
    enabled = true;
    prometheusExporter = true;
    exporterPort = 9187;
  };
  
  # Security configuration
  security = {
    sslEnabled = true;
    sslMode = "require";
    requireAuth = true;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| version | string | "15" | PostgreSQL version |
| replicas | int | 1 | Number of replicas |
| storage.size | string | "10Gi" | PVC size |
| storage.class | string | "default" | Storage class name |
| databases | object | {} | Database definitions |
| users | object | {} | User definitions |
| replication | object | {} | Replication settings |
| backup | object | {} | Backup configuration |
| connectionPool | object | {} | Connection pool settings |
| performance | object | {} | Performance tuning |
| monitoring | object | {} | Monitoring configuration |
| security | object | {} | Security settings |

**Returns:** Kubernetes resources for PostgreSQL deployment

**Usage Examples:**

```nix
# Single instance PostgreSQL
mkPostgreSQL "dev-db" {
  namespace = "dev";
  version = "14";
  replicas = 1;
  storage.size = "10Gi";
};

# Production HA PostgreSQL
mkPostgreSQL "prod-db" {
  namespace = "production";
  version = "15";
  replicas = 3;
  storage = {
    size = "100Gi";
    class = "fast-ssd";
  };
  replication = {
    type = "streaming";
    mode = "synchronous";
  };
  backup = {
    enabled = true;
    schedule = "0 2 * * *";
  };
};
```

### mkMySQL

Creates a MySQL database deployment with Group Replication or traditional replication.

```nix
databaseManagement.mkMySQL "mysql-cluster" {
  namespace = "databases";
  
  # MySQL configuration
  version = "8.0";
  replicas = 3;
  clusteringType = "group-replication";  # group-replication | traditional
  
  # Storage configuration
  storage = {
    size = "50Gi";
    class = "fast-ssd";
  };
  
  # Database configuration
  databases = {
    production = {
      encoding = "utf8mb4";
      collation = "utf8mb4_unicode_ci";
    };
  };
  
  # User configuration
  users = {
    app_user = {
      password = { secretRef = "mysql-passwords"; secretKey = "app_user"; };
      permissions = {
        "production.*" = [ "SELECT" "INSERT" "UPDATE" "DELETE" ];
      };
      hosts = [ "%.pod.cluster.local" "127.0.0.1" ];
    };
    replication = {
      password = { secretRef = "mysql-passwords"; secretKey = "replication"; };
      permissions = {
        "*.*" = [ "REPLICATION_SLAVE" "REPLICATION_SLAVE_ADMIN" ];
      };
      hosts = [ "%.pod.cluster.local" ];
    };
  };
  
  # Replication configuration
  replication = {
    mode = "asynchronous";  # asynchronous | semi-synchronous
    replicaParallelWorkers = 4;
    binlogFormat = "ROW";
    gtidMode = true;
  };
  
  # Backup configuration
  backup = {
    enabled = true;
    schedule = "0 3 * * *";
    type = "xtrabackup";  # xtrabackup | mysqldump
    retentionDays = 30;
    destination = {
      type = "s3";
      bucket = "database-backups";
      prefix = "mysql/";
    };
  };
  
  # Performance configuration
  performance = {
    maxConnections = 1000;
    innodbBufferPoolSize = "20GB";
    innodbLogFileSize = "512MB";
    queryCache = false;
    binlogSize = "100MB";
  };
  
  # Monitoring
  monitoring = {
    enabled = true;
    percona = true;  # Use Percona monitoring
    metricsPort = 9104;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| version | string | "8.0" | MySQL version |
| replicas | int | 3 | Number of replicas |
| clusteringType | string | "traditional" | Clustering mode |
| storage | object | {} | Storage configuration |
| databases | object | {} | Database definitions |
| users | object | {} | User definitions |
| replication | object | {} | Replication settings |
| backup | object | {} | Backup configuration |
| performance | object | {} | Performance settings |
| monitoring | object | {} | Monitoring configuration |

**Returns:** Kubernetes resources for MySQL deployment

**Usage Examples:**

```nix
# Traditional MySQL replication
mkMySQL "mysql-replicated" {
  namespace = "databases";
  version = "8.0";
  replicas = 2;
  clusteringType = "traditional";
  replication.mode = "semi-synchronous";
};

# Group Replication cluster
mkMySQL "mysql-gr" {
  namespace = "production";
  version = "8.0";
  replicas = 5;
  clusteringType = "group-replication";
};
```

### mkMongoDB

Creates a MongoDB deployment with replica sets and sharding support.

```nix
databaseManagement.mkMongoDB "mongo-cluster" {
  namespace = "databases";
  
  # MongoDB configuration
  version = "7.0";
  deploymentType = "replica-set";  # replica-set | sharded
  
  # Replica set configuration
  replicaSet = {
    name = "rs0";
    members = 3;
    arbiter = true;  # Add arbiter for even number of nodes
  };
  
  # Storage configuration
  storage = {
    size = "50Gi";
    class = "fast-ssd";
    engine = "wiredTiger";  # wiredTiger | mmapv1 (legacy)
    cacheSize = "20GB";
    journal = true;
  };
  
  # Sharding configuration (if deploymentType = "sharded")
  sharding = {
    enabled = false;
    shardKey = "_id";
    numShards = 3;
    configServers = 3;
    mongoS = 2;
  };
  
  # Authentication
  auth = {
    enabled = true;
    mode = "scram";  # scram | x509
    users = {
      admin = {
        password = { secretRef = "mongo-credentials"; secretKey = "admin"; };
        roles = [ "root" ];
      };
      app_user = {
        password = { secretRef = "mongo-credentials"; secretKey = "app_user"; };
        roles = [ "readWrite" ];
        databases = [ "production" ];
      };
    };
  };
  
  # Backup configuration
  backup = {
    enabled = true;
    schedule = "0 2 * * *";
    method = "mongodump";  # mongodump | snapshot
    retentionDays = 30;
    destination = {
      type = "s3";
      bucket = "database-backups";
      prefix = "mongodb/";
    };
  };
  
  # Performance tuning
  performance = {
    maxConnections = 500;
    ticketHolderQueueSize = 500;
    parallelCollectionScan = true;
    compressionLevel = 9;
  };
  
  # Monitoring
  monitoring = {
    enabled = true;
    prometheusExporter = true;
    exporterPort = 9216;
  };
  
  # Security
  security = {
    tlsEnabled = true;
    tlsMode = "requireTLS";
    ipWhitelist = [ "10.0.0.0/8" ];
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| version | string | "7.0" | MongoDB version |
| deploymentType | string | "replica-set" | Deployment type |
| replicaSet | object | {} | Replica set configuration |
| sharding | object | {} | Sharding configuration |
| storage | object | {} | Storage settings |
| auth | object | {} | Authentication settings |
| backup | object | {} | Backup configuration |
| performance | object | {} | Performance tuning |
| monitoring | object | {} | Monitoring settings |
| security | object | {} | Security settings |

**Returns:** Kubernetes resources for MongoDB deployment

**Usage Examples:**

```nix
# Replica set MongoDB
mkMongoDB "mongo-rs" {
  namespace = "databases";
  deploymentType = "replica-set";
  replicaSet.members = 3;
  storage.size = "30Gi";
};

# Sharded MongoDB cluster
mkMongoDB "mongo-sharded" {
  namespace = "production";
  deploymentType = "sharded";
  sharding = {
    enabled = true;
    numShards = 5;
  };
};
```

### mkRedis

Creates a Redis deployment with support for sentinel and cluster modes.

```nix
databaseManagement.mkRedis "redis-cache" {
  namespace = "cache";
  
  # Redis configuration
  version = "7.2";
  mode = "standalone";  # standalone | sentinel | cluster
  replicas = 0;
  
  # Cluster configuration
  cluster = {
    enabled = false;
    nodes = 6;  # Minimum 6 for cluster mode
    replicas = 1;
  };
  
  # Sentinel configuration
  sentinel = {
    enabled = false;
    sentinels = 3;
    quorum = 2;
    downAfterMilliseconds = 30000;
    failoverTimeout = 180000;
  };
  
  # Storage configuration
  storage = {
    persistence = "rdb";  # rdb | aof | mixed | none
    rdbSavePolicy = {
      "900" = 1;      # 1 change in 900 seconds
      "300" = 10;     # 10 changes in 300 seconds
      "60" = 10000;   # 10000 changes in 60 seconds
    };
    aofFsync = "everysec";  # always | everysec | no
    size = "10Gi";
    class = "fast-ssd";
  };
  
  # Memory configuration
  memory = {
    maxmemory = "8gb";
    maxmemoryPolicy = "allkeys-lru";  # eviction policy
  };
  
  # Security configuration
  security = {
    requirepass = { secretRef = "redis-credentials"; secretKey = "password"; };
    tlsEnabled = true;
    tlsMode = "prefer";
    aclEnabled = true;
    users = {
      default = {
        password = { secretRef = "redis-credentials"; secretKey = "password"; };
        permissions = [
          "+@all"
          "~*"
          "-@dangerous"
        ];
      };
    };
  };
  
  # Replication configuration
  replication = {
    disklessSync = true;
    disklessSyncDelay = 5;
    replicas = 0;
  };
  
  # Performance configuration
  performance = {
    timeout = 0;
    tcpBacklog = 511;
    tcpKeepalive = 300;
    hz = 10;
  };
  
  # Monitoring
  monitoring = {
    enabled = true;
    prometheusExporter = true;
    exporterPort = 9121;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| version | string | "7.2" | Redis version |
| mode | string | "standalone" | Operational mode |
| replicas | int | 0 | Number of replicas |
| cluster | object | {} | Cluster configuration |
| sentinel | object | {} | Sentinel configuration |
| storage | object | {} | Storage settings |
| memory | object | {} | Memory configuration |
| security | object | {} | Security settings |
| replication | object | {} | Replication settings |
| performance | object | {} | Performance configuration |
| monitoring | object | {} | Monitoring configuration |

**Returns:** Kubernetes resources for Redis deployment

**Usage Examples:**

```nix
# Standalone Redis
mkRedis "redis-dev" {
  namespace = "cache";
  version = "7.2";
  mode = "standalone";
  storage.persistence = "rdb";
};

# Redis Cluster
mkRedis "redis-cluster" {
  namespace = "production";
  mode = "cluster";
  cluster = {
    enabled = true;
    nodes = 9;
    replicas = 1;
  };
};

# Redis Sentinel (HA)
mkRedis "redis-ha" {
  namespace = "production";
  mode = "sentinel";
  sentinel = {
    enabled = true;
    sentinels = 3;
    quorum = 2;
  };
};
```

### mkDatabaseBackup

Configures automated backup strategies with retention and verification.

```nix
databaseManagement.mkDatabaseBackup "postgres-backup" {
  namespace = "databases";
  
  # Backup target
  target = {
    database = "postgres";
    type = "postgresql";  # postgresql | mysql | mongodb | redis
    host = "postgres.databases.svc.cluster.local";
    port = 5432;
    credentialSecret = "db-credentials";
  };
  
  # Schedule
  schedule = {
    frequency = "daily";  # hourly | daily | weekly | monthly
    time = "02:00";
    timezone = "UTC";
  };
  
  # Backup configuration
  backup = {
    type = "full";  # full | incremental | differential
    format = "binary";  # binary | sql
    compression = "gzip";  # none | gzip | bzip2 | zstd
    compressionLevel = 9;
  };
  
  # Retention policy
  retention = {
    daily = 7;      # Keep 7 daily backups
    weekly = 4;     # Keep 4 weekly backups
    monthly = 12;   # Keep 12 monthly backups
    yearly = 3;     # Keep 3 yearly backups
    minBackups = 5; # Always keep at least 5 recent backups
  };
  
  # Storage destination
  destination = {
    type = "s3";  # s3 | gcs | azure | local
    bucket = "database-backups";
    prefix = "postgres/";
    
    s3 = {
      endpoint = "https://s3.amazonaws.com";
      region = "us-east-1";
      credentialSecret = "s3-credentials";
      serverSideEncryption = "AES256";
      storageClass = "STANDARD_IA";  # Transition to cheaper storage
    };
  };
  
  # Backup verification
  verification = {
    enabled = true;
    frequency = "weekly";
    restoreTest = true;  # Test restore once a week
    integrityCheck = true;
  };
  
  # Notification
  notification = {
    enabled = true;
    onSuccess = true;
    onFailure = true;
    channels = [ "slack" "email" ];
    slackWebhook = { secretRef = "backup-notifications"; secretKey = "slack"; };
  };
  
  # Performance tuning
  performance = {
    parallelJobs = 4;
    networkBandwidth = "100Mbps";
    cpuLimit = "2";
    memoryLimit = "4Gi";
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| target | object | required | Backup source configuration |
| schedule | object | required | Backup schedule |
| backup | object | {} | Backup settings |
| retention | object | {} | Retention policy |
| destination | object | required | Backup destination |
| verification | object | {} | Verification settings |
| notification | object | {} | Notification settings |
| performance | object | {} | Performance settings |

**Returns:** Kubernetes resources for backup system

**Usage Examples:**

```nix
# PostgreSQL daily backups
mkDatabaseBackup "postgres-daily" {
  namespace = "backup";
  target = {
    database = "postgres";
    type = "postgresql";
    host = "postgres.databases.svc.cluster.local";
  };
  schedule.frequency = "daily";
  retention.daily = 7;
  destination = {
    type = "s3";
    bucket = "backups";
    prefix = "postgres/";
  };
};

# MongoDB hourly backups
mkDatabaseBackup "mongo-hourly" {
  namespace = "backup";
  target = {
    database = "production";
    type = "mongodb";
    host = "mongodb.databases.svc.cluster.local";
  };
  schedule.frequency = "hourly";
  backup.type = "incremental";
};
```

### mkReplication

Configures database replication with failover and load balancing.

```nix
databaseManagement.mkReplication "postgres-replication" {
  namespace = "databases";
  
  # Replication configuration
  replication = {
    type = "streaming";  # streaming | logical | physical | semi-sync
    mode = "synchronous";
    maxReplicas = 5;
  };
  
  # Primary configuration
  primary = {
    name = "postgres-primary";
    resources = {
      requests = { cpu = "2"; memory = "4Gi"; };
      limits = { cpu = "4"; memory = "8Gi"; };
    };
    storage = {
      size = "50Gi";
      class = "fast-ssd";
    };
  };
  
  # Replica configuration
  replicas = {
    count = 2;
    resources = {
      requests = { cpu = "1"; memory = "2Gi"; };
      limits = { cpu = "2"; memory = "4Gi"; };
    };
    storage = {
      size = "50Gi";
      class = "fast-ssd";
    };
  };
  
  # Failover configuration
  failover = {
    enabled = true;
    autoFailover = true;
    failoverTimeout = 300;  # seconds
    priorityReplica = "replica-1";  # Preferred target for promotion
  };
  
  # Load balancing
  loadBalancing = {
    enabled = true;
    readReplicas = true;  # Route reads to replicas
    strategy = "round-robin";  # round-robin | least-connections | random
  };
  
  # Monitoring and health checks
  health = {
    checkInterval = 10;  # seconds
    healthProbeInterval = 5;
    unhealthyThreshold = 3;
    replicationLag = "10s";  # Maximum allowed replication lag
  };
  
  # Backup during replication
  backup = {
    enabled = true;
    fromReplica = true;  # Backup from replica to not stress primary
    replicaSlot = "backup_slot";
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| replication | object | {} | Replication settings |
| primary | object | required | Primary configuration |
| replicas | object | required | Replica configuration |
| failover | object | {} | Failover settings |
| loadBalancing | object | {} | Load balancing configuration |
| health | object | {} | Health check settings |
| backup | object | {} | Backup configuration |

**Returns:** Kubernetes resources for replication system

**Usage Examples:**

```nix
# Streaming replication with automatic failover
mkReplication "postgres-ha" {
  namespace = "databases";
  replication = {
    type = "streaming";
    mode = "synchronous";
  };
  primary.name = "postgres-primary";
  replicas.count = 2;
  failover.autoFailover = true;
};
```

### mkDatabaseMigration

Manages database schema migrations and data transformations.

```nix
databaseManagement.mkDatabaseMigration "schema-upgrade" {
  namespace = "databases";
  
  # Source database
  source = {
    type = "postgresql";
    host = "postgres-old.databases.svc.cluster.local";
    port = 5432;
    database = "production";
    credentialSecret = "source-db-credentials";
  };
  
  # Target database
  target = {
    type = "postgresql";
    host = "postgres-new.databases.svc.cluster.local";
    port = 5432;
    database = "production";
    credentialSecret = "target-db-credentials";
  };
  
  # Migration strategy
  strategy = "online";  # online | offline | shadow
  
  # Migration phases
  phases = [
    {
      name = "schema-sync";
      type = "schema";
      action = "replicate";
      continueOnError = false;
    }
    {
      name = "data-sync";
      type = "data";
      action = "full-sync";
      batchSize = 10000;
    }
    {
      name = "validation";
      type = "validation";
      action = "count-compare";
      allowedDifference = 0;
    }
    {
      name = "cutover";
      type = "cutover";
      action = "switch-traffic";
      rollback = true;
    }
  ];
  
  # Performance tuning
  performance = {
    parallelWorkers = 4;
    batchSize = 5000;
    networkBandwidth = "500Mbps";
  };
  
  # Validation rules
  validation = {
    enabled = true;
    checks = [
      {
        type = "row-count";
        tolerance = 0.01;  # 1% tolerance
      }
      {
        type = "checksum";
        tolerance = 0;
      }
      {
        type = "schema-match";
        tolerance = 0;
      }
    ];
  };
  
  # Rollback configuration
  rollback = {
    enabled = true;
    timeout = 3600;  # seconds
    onFailure = "automatic";  # automatic | manual
  };
  
  # Monitoring
  monitoring = {
    enabled = true;
    trackProgress = true;
    trackLatency = true;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| source | object | required | Source database config |
| target | object | required | Target database config |
| strategy | string | "online" | Migration strategy |
| phases | list | [] | Migration phases |
| performance | object | {} | Performance tuning |
| validation | object | {} | Validation rules |
| rollback | object | {} | Rollback configuration |
| monitoring | object | {} | Monitoring settings |

**Returns:** Kubernetes resources for migration system

**Usage Examples:**

```nix
# Online schema migration
mkDatabaseMigration "pg-upgrade" {
  namespace = "databases";
  source = {
    type = "postgresql";
    host = "postgres-14.databases.svc.cluster.local";
    database = "production";
  };
  target = {
    type = "postgresql";
    host = "postgres-15.databases.svc.cluster.local";
    database = "production";
  };
  strategy = "online";
};
```

### mkPerformanceTuning

Configures performance optimization and resource allocation.

```nix
databaseManagement.mkPerformanceTuning "postgres-tuning" {
  namespace = "databases";
  
  # Target database
  target = {
    type = "postgresql";
    database = "postgres";
    host = "postgres.databases.svc.cluster.local";
  };
  
  # Memory optimization
  memory = {
    sharedBuffers = {
      percent = 0.25;  # 25% of total memory
      min = "128MB";
      max = "40GB";
    };
    effectiveCacheSize = {
      percent = 0.75;
    };
    workMem = {
      perConnection = "10MB";
      min = "1MB";
      max = "100MB";
    };
    maintenanceWorkMemory = {
      percent = 0.05;
    };
  };
  
  # CPU optimization
  cpu = {
    maxParallelWorkers = 8;
    maxParallelWorkersPerGather = 4;
    maxParallelMaintenanceWorkers = 4;
    randomPageCost = 1.1;  # SSD: 1.1, HDD: 4.0
  };
  
  # I/O optimization
  io = {
    checkpointTimeout = 900;  # seconds
    checkpointCompletionTarget = 0.9;
    wal = {
      buffers = "16MB";
      level = "logical";
      compression = "on";
    };
  };
  
  # Query planning
  planning = {
    geqoThreshold = 12;
    joinCollapseLimit = 8;
    fromCollapseLimit = 8;
    constraintExclusion = "partition";
  };
  
  # Logging for analysis
  logging = {
    minDuration = 1000;  # Log queries > 1 second
    statement = "all";
    duration = true;
    locks = true;
    checkpoints = true;
  };
  
  # Autovacuum tuning
  autovacuum = {
    enabled = true;
    naptime = 10;  # seconds
    analyzeThreshold = 50;
    analyzeScaleFactor = 0.1;
    vacuumThreshold = 50;
    vacuumScaleFactor = 0.1;
  };
  
  # Index optimization
  indexing = {
    automaticIndexing = true;
    autoExplain = true;
    analyzeQueryPlans = true;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| target | object | required | Target database config |
| memory | object | {} | Memory optimization |
| cpu | object | {} | CPU optimization |
| io | object | {} | I/O optimization |
| planning | object | {} | Query planning settings |
| logging | object | {} | Logging configuration |
| autovacuum | object | {} | Autovacuum settings |
| indexing | object | {} | Index optimization |

**Returns:** Performance configuration resource

**Usage Examples:**

```nix
# PostgreSQL performance tuning
mkPerformanceTuning "prod-postgres" {
  namespace = "databases";
  target = {
    type = "postgresql";
    host = "postgres.databases.svc.cluster.local";
  };
  memory.sharedBuffers.percent = 0.25;
  cpu.maxParallelWorkers = 16;
};
```

### mkDatabaseSecurity

Configures security policies and access controls.

```nix
databaseManagement.mkDatabaseSecurity "postgres-security" {
  namespace = "databases";
  
  # Target database
  target = {
    type = "postgresql";
    host = "postgres.databases.svc.cluster.local";
    database = "postgres";
  };
  
  # Encryption at rest
  encryption = {
    enabled = true;
    algorithm = "AES256";
    keyManagement = {
      type = "kms";  # kms | vault | local
      kmsKeyId = "arn:aws:kms:us-east-1:123456789:key/12345678";
    };
  };
  
  # TLS/SSL configuration
  tls = {
    enabled = true;
    mode = "require";  # disable | allow | prefer | require
    certificateSecret = "postgres-tls";
    certificatePath = "/etc/postgres/tls/server.crt";
    keyPath = "/etc/postgres/tls/server.key";
  };
  
  # Authentication
  authentication = {
    method = "scram";  # md5 | scram | ldap | kerberos
    passwordExpiry = 90;  # days
    lockoutPolicy = {
      enabled = true;
      maxAttempts = 5;
      lockoutDuration = 1800;  # 30 minutes
    };
  };
  
  # Authorization
  authorization = {
    rbac = true;
    rowLevelSecurity = true;
    columnEncryption = {
      enabled = true;
      columns = [ "ssn" "credit_card" "email" ];
    };
  };
  
  # Network security
  network = {
    firewallEnabled = true;
    allowedSubnets = [ "10.0.0.0/8" "172.16.0.0/12" ];
    denyedSubnets = [];
    ipv4Only = false;
  };
  
  # Audit logging
  auditLogging = {
    enabled = true;
    logAllStatements = false;
    logDdl = true;
    logDml = true;
    logErrors = true;
    retentionDays = 90;
  };
  
  # Compliance
  compliance = {
    framework = "GDPR";  # GDPR | HIPAA | PCI-DSS | SOC2
    dataExfiltrationPrevention = true;
    maskingRules = [
      {
        pattern = "email";
        maskingType = "hash";
      }
    ];
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| target | object | required | Target database config |
| encryption | object | {} | Encryption settings |
| tls | object | {} | TLS configuration |
| authentication | object | {} | Authentication settings |
| authorization | object | {} | Authorization settings |
| network | object | {} | Network security |
| auditLogging | object | {} | Audit logging |
| compliance | object | {} | Compliance settings |

**Returns:** Security configuration resources

**Usage Examples:**

```nix
# Production security configuration
mkDatabaseSecurity "prod-security" {
  namespace = "databases";
  target.type = "postgresql";
  encryption.enabled = true;
  tls = {
    enabled = true;
    mode = "require";
  };
  auditLogging.enabled = true;
};
```

### mkDatabaseMonitoring

Sets up comprehensive monitoring and alerting for databases.

```nix
databaseManagement.mkDatabaseMonitoring "postgres-monitoring" {
  namespace = "monitoring";
  
  # Target database
  target = {
    type = "postgresql";
    host = "postgres.databases.svc.cluster.local";
    port = 5432;
  };
  
  # Metrics collection
  metrics = {
    enabled = true;
    interval = 30;  # seconds
    retention = 15;  # days
    
    collectors = [
      "database"
      "queries"
      "connections"
      "replication"
      "storage"
      "performance"
      "locks"
    ];
  };
  
  # Prometheus integration
  prometheus = {
    enabled = true;
    exporterImage = "prometheuscommunity/postgres-exporter:v0.13";
    exporterPort = 9187;
    scrapeInterval = 30;
  };
  
  # Key metrics to track
  keyMetrics = [
    {
      name = "connections";
      alert = {
        warning = 80;  # % of max connections
        critical = 95;
      };
    }
    {
      name = "replication_lag";
      alert = {
        warning = 10000;  # milliseconds
        critical = 30000;
      };
    }
    {
      name = "slow_queries";
      alert = {
        warning = 10;  # queries per minute
        critical = 50;
      };
    }
    {
      name = "cache_hit_ratio";
      alert = {
        warning = 99;  # % hits
        critical = 95;
      };
    }
  ];
  
  # Alerting rules
  alerting = {
    enabled = true;
    rules = [
      {
        alert = "DatabaseDown";
        severity = "critical";
        condition = "up == 0";
        duration = "5m";
      }
      {
        alert = "HighConnectionUsage";
        severity = "warning";
        condition = "connections_percent > 80";
        duration = "10m";
      }
      {
        alert = "ReplicationLagHigh";
        severity = "critical";
        condition = "replication_lag > 30000";
        duration = "5m";
      }
    ];
  };
  
  # Dashboard configuration
  dashboards = {
    enabled = true;
    grafanaEnabled = true;
    dashboards = [
      "database-overview"
      "performance"
      "replication"
      "storage"
      "queries"
    ];
  };
  
  # Query analysis
  queryAnalysis = {
    enabled = true;
    slowQueryThreshold = 1000;  # milliseconds
    trackFullScans = true;
    indexUsageTracking = true;
  };
  
  # Log aggregation
  logging = {
    enabled = true;
    destination = "loki";  # loki | elasticsearch | splunk
    queryLogs = true;
    errorLogs = true;
    connectionLogs = false;
  };
}
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| namespace | string | "default" | Target namespace |
| target | object | required | Target database config |
| metrics | object | {} | Metrics collection |
| prometheus | object | {} | Prometheus settings |
| keyMetrics | list | [] | Key metrics to track |
| alerting | object | {} | Alerting configuration |
| dashboards | object | {} | Dashboard settings |
| queryAnalysis | object | {} | Query analysis |
| logging | object | {} | Log aggregation |

**Returns:** Monitoring configuration resources

**Usage Examples:**

```nix
# Complete monitoring setup
mkDatabaseMonitoring "prod-monitoring" {
  namespace = "monitoring";
  target = {
    type = "postgresql";
    host = "postgres.databases.svc.cluster.local";
  };
  metrics.enabled = true;
  prometheus.enabled = true;
  alerting.enabled = true;
  dashboards.enabled = true;
};
```

## Integration Patterns

### High Availability Setup

Combine replication with failover for HA:

```nix
let
  primary = mkPostgreSQL "postgres-primary" {
    namespace = "databases";
    replicas = 0;
  };
  
  replication = mkReplication "postgres-replication" {
    namespace = "databases";
    replication.mode = "synchronous";
    failover.autoFailover = true;
  };
in
{
  resources = [ primary replication ];
}
```

### Backup and Disaster Recovery

Combine backups with monitoring:

```nix
{
  backup = mkDatabaseBackup "postgres-backup" {
    namespace = "backup";
    schedule.frequency = "daily";
    destination = {
      type = "s3";
      bucket = "backups";
    };
  };
  
  monitoring = mkDatabaseMonitoring "backup-monitoring" {
    namespace = "monitoring";
    alerting.enabled = true;
  };
}
```

## Best Practices

### Resource Allocation

1. **Reserve adequate memory** for database processes
2. **Use fast storage** (SSD) for database files
3. **Monitor resource utilization** and scale accordingly
4. **Set resource limits** to prevent node issues

### Replication & Failover

1. **Use synchronous replication** for critical data
2. **Maintain multiple replicas** for redundancy
3. **Monitor replication lag** continuously
4. **Test failover procedures** regularly

### Backups & Recovery

1. **Automate backup scheduling** (daily minimum)
2. **Test restore procedures** regularly
3. **Store backups geographically** distributed
4. **Document recovery procedures** clearly

### Security

1. **Enable encryption at rest and in transit**
2. **Use strong authentication** (SCRAM, Kerberos)
3. **Implement least privilege** access control
4. **Enable audit logging** for compliance

### Performance

1. **Tune buffer pools** based on workload
2. **Optimize indexes** for query patterns
3. **Monitor slow queries** and optimize
4. **Configure connection pooling** appropriately

## Troubleshooting Guide

### Connection Issues

**Symptoms:** Cannot connect to database

**Solutions:**
- Check network policies and firewall rules
- Verify credentials are correct
- Check pod status and logs
- Verify DNS resolution

### Replication Lag

**Symptoms:** Replicas falling behind primary

**Solutions:**
- Check network bandwidth
- Reduce write load on primary
- Optimize disk I/O
- Consider async replication if tolerable

### Storage Issues

**Symptoms:** Out of disk space, slow performance

**Solutions:**
- Expand PVC size
- Implement data retention policies
- Archive old data
- Check for log accumulation

### High Memory Usage

**Symptoms:** Pod OOMKilled, slow queries

**Solutions:**
- Increase memory limits
- Adjust buffer pool size
- Optimize queries
- Check for memory leaks

## Related Modules

- **BATCH_PROCESSING**: Database backup jobs
- **EVENT_PROCESSING**: Real-time data streaming
- **MONITORING**: Database health monitoring

## References

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [MySQL Documentation](https://dev.mysql.com/doc/)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Redis Documentation](https://redis.io/docs/)
