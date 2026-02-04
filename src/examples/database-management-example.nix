# Database Management Examples
#
# This file contains 18+ production-ready database configuration examples
# including PostgreSQL, MySQL, MongoDB, and Redis deployments with various
# configurations for high availability, replication, and backup strategies.

{ lib, ... }:

{
  # Example 1: Simple PostgreSQL Deployment
  simplePostgreSQL = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = {
      name = "databases";
    };
  };

  postgresqlSimple = {
    apiVersion = "v1";
    kind = "PersistentVolumeClaim";
    metadata = {
      name = "postgres-simple-pvc";
      namespace = "databases";
    };
    spec = {
      accessModes = [ "ReadWriteOnce" ];
      storageClassName = "standard";
      resources = {
        requests = {
          storage = "10Gi";
        };
      };
    };
  };

  postgresqlSimpleDeployment = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "postgres-simple";
      namespace = "databases";
      labels = {
        "app.kubernetes.io/name" = "postgres";
        "app.kubernetes.io/version" = "15";
      };
    };
    spec = {
      replicas = 1;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "postgres";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "postgres";
          };
        };
        spec = {
          containers = [{
            name = "postgres";
            image = "postgres:15-alpine";
            
            env = [
              { name = "POSTGRES_DB"; value = "myapp"; }
              { name = "POSTGRES_USER"; value = "appuser"; }
              {
                name = "POSTGRES_PASSWORD";
                valueFrom.secretKeyRef = {
                  name = "postgres-secret";
                  key = "password";
                };
              }
            ];
            
            ports = [{ containerPort = 5432; name = "postgresql"; }];
            
            livenessProbe = {
              exec = {
                command = [ "pg_isready" "-U" "appuser" ];
              };
              initialDelaySeconds = 30;
              periodSeconds = 10;
            };
            
            readinessProbe = {
              exec = {
                command = [ "pg_isready" "-U" "appuser" ];
              };
              initialDelaySeconds = 5;
              periodSeconds = 5;
            };
            
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
              { name = "data"; mountPath = "/var/lib/postgresql/data"; }
            ];
          }];
          
          volumes = [
            {
              name = "data";
              persistentVolumeClaim = {
                claimName = "postgres-simple-pvc";
              };
            }
          ];
        };
      };
    };
  };

  postgresqlSimpleService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "postgres";
      namespace = "databases";
    };
    spec = {
      type = "ClusterIP";
      selector = {
        "app.kubernetes.io/name" = "postgres";
      };
      ports = [{
        port = 5432;
        targetPort = 5432;
        protocol = "TCP";
      }];
    };
  };

  # Example 2: PostgreSQL with HA and Replication
  postgresqlHAPVC = {
    apiVersion = "v1";
    kind = "PersistentVolumeClaim";
    metadata = {
      name = "postgres-ha-pvc";
      namespace = "databases";
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
  };

  postgresqlHAStatefulSet = {
    apiVersion = "apps/v1";
    kind = "StatefulSet";
    metadata = {
      name = "postgres-ha";
      namespace = "databases";
    };
    spec = {
      serviceName = "postgres-ha";
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "postgres";
          "app.kubernetes.io/component" = "ha";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "postgres";
            "app.kubernetes.io/component" = "ha";
          };
        };
        spec = {
          serviceAccountName = "postgres";
          
          initContainers = [{
            name = "init-chmod";
            image = "busybox";
            command = [ "sh" "-c" "chmod 700 /var/lib/postgresql/data || true" ];
            volumeMounts = [{
              name = "data";
              mountPath = "/var/lib/postgresql/data";
            }];
          }];
          
          containers = [{
            name = "postgres";
            image = "postgres:15";
            
            env = [
              { name = "POSTGRES_DB"; value = "production"; }
              { name = "POSTGRES_USER"; value = "postgres"; }
              {
                name = "POSTGRES_PASSWORD";
                valueFrom.secretKeyRef = {
                  name = "postgres-secret";
                  key = "password";
                };
              }
              { name = "PGDATA"; value = "/var/lib/postgresql/data/pgdata"; }
            ];
            
            command = [
              "postgres"
              "-c"
              "max_wal_senders=10"
              "-c"
              "max_replication_slots=10"
              "-c"
              "wal_keep_size=1GB"
              "-c"
              "hot_standby=on"
            ];
            
            ports = [{ containerPort = 5432; }];
            
            livenessProbe = {
              exec = {
                command = [ "pg_isready" "-U" "postgres" ];
              };
              initialDelaySeconds = 30;
              periodSeconds = 10;
              timeoutSeconds = 5;
            };
            
            readinessProbe = {
              exec = {
                command = [ "pg_isready" "-U" "postgres" ];
              };
              initialDelaySeconds = 5;
              periodSeconds = 5;
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
            
            volumeMounts = [
              { name = "data"; mountPath = "/var/lib/postgresql/data"; }
            ];
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

  postgresqlHAHeadlessService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "postgres-ha";
      namespace = "databases";
    };
    spec = {
      clusterIP = "None";
      selector = {
        "app.kubernetes.io/name" = "postgres";
        "app.kubernetes.io/component" = "ha";
      };
      ports = [{
        port = 5432;
        targetPort = 5432;
      }];
    };
  };

  # Example 3: MySQL Standalone Deployment
  mysqlStandalone = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "mysql-standalone";
      namespace = "databases";
    };
    spec = {
      replicas = 1;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "mysql";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "mysql";
          };
        };
        spec = {
          containers = [{
            name = "mysql";
            image = "mysql:8.0";
            
            env = [
              { name = "MYSQL_ROOT_PASSWORD"; valueFrom.secretKeyRef = {
                  name = "mysql-secret";
                  key = "root-password";
                };
              }
              { name = "MYSQL_DATABASE"; value = "application"; }
            ];
            
            ports = [{ containerPort = 3306; }];
            
            livenessProbe = {
              exec = {
                command = [
                  "mysqladmin"
                  "ping"
                  "-h"
                  "localhost"
                ];
              };
              initialDelaySeconds = 30;
              periodSeconds = 10;
            };
            
            readinessProbe = {
              exec = {
                command = [
                  "mysqladmin"
                  "ping"
                  "-h"
                  "localhost"
                ];
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
            
            volumeMounts = [
              { name = "data"; mountPath = "/var/lib/mysql"; }
              { name = "config"; mountPath = "/etc/mysql/conf.d"; }
            ];
          }];
          
          volumes = [
            {
              name = "data";
              persistentVolumeClaim = {
                claimName = "mysql-pvc";
              };
            }
            {
              name = "config";
              configMap = {
                name = "mysql-config";
              };
            }
          ];
        };
      };
    };
  };

  # Example 4: MySQL Group Replication Cluster
  mysqlGRStatefulSet = {
    apiVersion = "apps/v1";
    kind = "StatefulSet";
    metadata = {
      name = "mysql-gr";
      namespace = "databases";
    };
    spec = {
      serviceName = "mysql-gr";
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "mysql-gr";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "mysql-gr";
          };
        };
        spec = {
          containers = [{
            name = "mysql";
            image = "mysql:8.0";
            
            env = [
              { name = "MYSQL_ROOT_PASSWORD"; valueFrom.secretKeyRef = {
                  name = "mysql-secret";
                  key = "root-password";
                };
              }
              { name = "MYSQL_REPLICATION_USER"; value = "replicator"; }
              { name = "MYSQL_REPLICATION_PASSWORD"; valueFrom.secretKeyRef = {
                  name = "mysql-secret";
                  key = "replication-password";
                };
              }
            ];
            
            command = [
              "docker-entrypoint.sh"
              "mysqld"
              "--default-authentication-plugin=mysql_native_password"
              "--server-id=1"
              "--log-bin=/var/log/mysql/mysql-bin.log"
              "--binlog-do-db=application"
              "--relay-log=/var/log/mysql/mysql-relay-bin"
              "--relay-log-index=/var/log/mysql/mysql-relay-bin.index"
              "--master-info-repository=TABLE"
              "--relay-log-info-repository=TABLE"
              "--master-user=replicator"
              "--master-password=${MYSQL_REPLICATION_PASSWORD}"
              "--master-port=3306"
              "--master-retry-count=100"
            ];
            
            ports = [{ containerPort = 3306; }];
            
            volumeMounts = [
              { name = "data"; mountPath = "/var/lib/mysql"; }
              { name = "config"; mountPath = "/etc/mysql/conf.d"; }
            ];
          }];
          
          volumes = [
            {
              name = "config";
              configMap = {
                name = "mysql-gr-config";
              };
            }
          ];
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

  # Example 5: MongoDB Replica Set
  mongodbReplicaSet = {
    apiVersion = "apps/v1";
    kind = "StatefulSet";
    metadata = {
      name = "mongodb";
      namespace = "databases";
    };
    spec = {
      serviceName = "mongodb";
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "mongodb";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "mongodb";
          };
        };
        spec = {
          serviceAccountName = "mongodb";
          securityContext = {
            fsGroup = 999;
            runAsUser = 999;
            runAsNonRoot = true;
          };
          
          initContainers = [{
            name = "init-chmod";
            image = "busybox";
            command = [ "sh" "-c" "chmod 700 /data/db || true" ];
            volumeMounts = [{
              name = "data";
              mountPath = "/data/db";
            }];
          }];
          
          containers = [{
            name = "mongodb";
            image = "mongo:7.0";
            
            command = [
              "mongod"
              "--bind_ip_all"
              "--replSet=rs0"
              "--auth"
            ];
            
            env = [
              { name = "MONGO_INITDB_ROOT_USERNAME"; value = "admin"; }
              { name = "MONGO_INITDB_ROOT_PASSWORD"; valueFrom.secretKeyRef = {
                  name = "mongodb-secret";
                  key = "root-password";
                };
              }
            ];
            
            ports = [{ containerPort = 27017; }];
            
            livenessProbe = {
              exec = {
                command = [
                  "mongo"
                  "--eval"
                  "db.adminCommand('ping')"
                ];
              };
              initialDelaySeconds = 30;
              periodSeconds = 10;
            };
            
            readinessProbe = {
              exec = {
                command = [
                  "mongo"
                  "--eval"
                  "db.adminCommand('ping')"
                ];
              };
              initialDelaySeconds = 5;
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
            
            volumeMounts = [
              { name = "data"; mountPath = "/data/db"; }
            ];
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
              storage = "30Gi";
            };
          };
        };
      }];
    };
  };

  mongodbService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = {
      name = "mongodb";
      namespace = "databases";
    };
    spec = {
      clusterIP = "None";
      selector = {
        "app.kubernetes.io/name" = "mongodb";
      };
      ports = [{
        port = 27017;
        targetPort = 27017;
      }];
    };
  };

  # Example 6: MongoDB Sharded Cluster
  mongodbConfigServer = {
    apiVersion = "apps/v1";
    kind = "StatefulSet";
    metadata = {
      name = "mongodb-config";
      namespace = "databases";
    };
    spec = {
      serviceName = "mongodb-config";
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "mongodb-config";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "mongodb-config";
          };
        };
        spec = {
          containers = [{
            name = "mongodb";
            image = "mongo:7.0";
            
            command = [
              "mongod"
              "--configsvr"
              "--replSet=configrs"
              "--bind_ip_all"
            ];
            
            ports = [{ containerPort = 27017; }];
            
            volumeMounts = [
              { name = "data"; mountPath = "/data/db"; }
            ];
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
              storage = "10Gi";
            };
          };
        };
      }];
    };
  };

  # Example 7: Redis Standalone
  redisStandalone = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "redis-standalone";
      namespace = "cache";
    };
    spec = {
      replicas = 1;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "redis";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "redis";
          };
        };
        spec = {
          containers = [{
            name = "redis";
            image = "redis:7-alpine";
            
            command = [ "redis-server" ];
            args = [
              "/etc/redis/redis.conf"
              "--appendonly"
              "yes"
            ];
            
            ports = [{ containerPort = 6379; }];
            
            livenessProbe = {
              exec = {
                command = [ "redis-cli" "ping" ];
              };
              initialDelaySeconds = 5;
              periodSeconds = 10;
            };
            
            readinessProbe = {
              exec = {
                command = [ "redis-cli" "ping" ];
              };
              initialDelaySeconds = 1;
              periodSeconds = 1;
            };
            
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
            
            volumeMounts = [
              { name = "redis-config"; mountPath = "/etc/redis"; }
              { name = "redis-data"; mountPath = "/data"; }
            ];
          }];
          
          volumes = [
            {
              name = "redis-config";
              configMap = {
                name = "redis-config";
              };
            }
            {
              name = "redis-data";
              persistentVolumeClaim = {
                claimName = "redis-pvc";
              };
            }
          ];
        };
      };
    };
  };

  # Example 8: Redis Sentinel Setup
  redisSentinel = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "redis-sentinel";
      namespace = "cache";
    };
    spec = {
      replicas = 3;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "redis-sentinel";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "redis-sentinel";
          };
        };
        spec = {
          containers = [{
            name = "sentinel";
            image = "redis:7-alpine";
            
            command = [ "redis-sentinel" ];
            args = [ "/etc/sentinel/sentinel.conf" ];
            
            ports = [{ containerPort = 26379; }];
            
            resources = {
              requests = {
                cpu = "100m";
                memory = "64Mi";
              };
              limits = {
                cpu = "200m";
                memory = "128Mi";
              };
            };
            
            volumeMounts = [
              { name = "sentinel-config"; mountPath = "/etc/sentinel"; }
            ];
          }];
          
          volumes = [
            {
              name = "sentinel-config";
              configMap = {
                name = "sentinel-config";
              };
            }
          ];
        };
      };
    };
  };

  # Example 9: Redis Cluster
  redisCluster = {
    apiVersion = "apps/v1";
    kind = "StatefulSet";
    metadata = {
      name = "redis-cluster";
      namespace = "cache";
    };
    spec = {
      serviceName = "redis-cluster";
      replicas = 6;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "redis-cluster";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "redis-cluster";
          };
        };
        spec = {
          containers = [{
            name = "redis";
            image = "redis:7-alpine";
            
            command = [ "redis-server" ];
            args = [
              "--cluster-enabled"
              "yes"
              "--cluster-node-timeout"
              "5000"
              "--appendonly"
              "yes"
            ];
            
            ports = [
              { containerPort = 6379; name = "client"; }
              { containerPort = 16379; name = "gossip"; }
            ];
            
            resources = {
              requests = {
                cpu = "100m";
                memory = "256Mi";
              };
              limits = {
                cpu = "500m";
                memory = "512Mi";
              };
            };
            
            volumeMounts = [
              { name = "data"; mountPath = "/data"; }
            ];
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
              storage = "10Gi";
            };
          };
        };
      }];
    };
  };

  # Example 10: PostgreSQL Backup CronJob
  postgresqlBackupJob = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "postgres-backup";
      namespace = "backup";
    };
    spec = {
      schedule = "0 2 * * *";
      concurrencyPolicy = "Forbid";
      successfulJobsHistoryLimit = 7;
      failedJobsHistoryLimit = 3;
      
      jobTemplate = {
        spec = {
          activeDeadlineSeconds = 3600;
          
          template = {
            spec = {
              serviceAccountName = "backup-job";
              
              containers = [{
                name = "backup";
                image = "postgres:15";
                
                command = [ "sh" ];
                args = [
                  "-c"
                  ''
                    BACKUP_FILE="/backups/postgres-$(date +%Y%m%d-%H%M%S).sql.gz"
                    pg_dump -h postgres.databases.svc.cluster.local -U postgres \
                      | gzip > $BACKUP_FILE
                    echo "Backup saved to $BACKUP_FILE"
                  ''
                ];
                
                env = [
                  {
                    name = "PGPASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "postgres-secret";
                      key = "password";
                    };
                  }
                ];
                
                volumeMounts = [
                  { name = "backup"; mountPath = "/backups"; }
                ];
              }];
              
              volumes = [
                {
                  name = "backup";
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

  # Example 11: MySQL Backup CronJob
  mysqlBackupJob = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "mysql-backup";
      namespace = "backup";
    };
    spec = {
      schedule = "0 3 * * *";
      concurrencyPolicy = "Forbid";
      
      jobTemplate = {
        spec = {
          activeDeadlineSeconds = 3600;
          
          template = {
            spec = {
              containers = [{
                name = "backup";
                image = "mysql:8.0";
                
                command = [ "sh" ];
                args = [
                  "-c"
                  ''
                    BACKUP_FILE="/backups/mysql-$(date +%Y%m%d-%H%M%S).sql.gz"
                    mysqldump -h mysql.databases.svc.cluster.local -u root -p$MYSQL_ROOT_PASSWORD \
                      --all-databases | gzip > $BACKUP_FILE
                    echo "Backup saved to $BACKUP_FILE"
                  ''
                ];
                
                env = [
                  {
                    name = "MYSQL_ROOT_PASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "mysql-secret";
                      key = "root-password";
                    };
                  }
                ];
                
                volumeMounts = [
                  { name = "backup"; mountPath = "/backups"; }
                ];
              }];
              
              volumes = [
                {
                  name = "backup";
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

  # Example 12: MongoDB Backup CronJob
  mongodbBackupJob = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = {
      name = "mongodb-backup";
      namespace = "backup";
    };
    spec = {
      schedule = "0 1 * * *";
      concurrencyPolicy = "Forbid";
      
      jobTemplate = {
        spec = {
          activeDeadlineSeconds = 3600;
          
          template = {
            spec = {
              containers = [{
                name = "backup";
                image = "mongo:7.0";
                
                command = [ "sh" ];
                args = [
                  "-c"
                  ''
                    BACKUP_DIR="/backups/mongodb-$(date +%Y%m%d-%H%M%S)"
                    mongodump -h mongodb.databases.svc.cluster.local:27017 \
                      -u admin -p $MONGO_PASSWORD --authenticationDatabase admin \
                      --out $BACKUP_DIR
                    echo "Backup saved to $BACKUP_DIR"
                  ''
                ];
                
                env = [
                  {
                    name = "MONGO_PASSWORD";
                    valueFrom.secretKeyRef = {
                      name = "mongodb-secret";
                      key = "root-password";
                    };
                  }
                ];
                
                volumeMounts = [
                  { name = "backup"; mountPath = "/backups"; }
                ];
              }];
              
              volumes = [
                {
                  name = "backup";
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

  # Example 13: PostgreSQL with Monitoring Sidecar
  postgresqlWithMonitoring = {
    apiVersion = "apps/v1";
    kind = "Deployment";
    metadata = {
      name = "postgres-monitored";
      namespace = "databases";
    };
    spec = {
      replicas = 1;
      selector = {
        matchLabels = {
          "app.kubernetes.io/name" = "postgres-monitored";
        };
      };
      
      template = {
        metadata = {
          labels = {
            "app.kubernetes.io/name" = "postgres-monitored";
          };
          annotations = {
            "prometheus.io/scrape" = "true";
            "prometheus.io/port" = "9187";
            "prometheus.io/path" = "/metrics";
          };
        };
        spec = {
          containers = [
            {
              name = "postgres";
              image = "postgres:15";
              
              env = [
                { name = "POSTGRES_DB"; value = "myapp"; }
                { name = "POSTGRES_USER"; value = "postgres"; }
                { name = "POSTGRES_PASSWORD"; valueFrom.secretKeyRef = {
                    name = "postgres-secret";
                    key = "password";
                  };
                }
              ];
              
              ports = [{ containerPort = 5432; }];
              
              volumeMounts = [
                { name = "data"; mountPath = "/var/lib/postgresql/data"; }
              ];
            }
            
            {
              name = "postgres-exporter";
              image = "prometheuscommunity/postgres-exporter:v0.13";
              
              env = [
                { name = "DATA_SOURCE_NAME"; value = "postgresql://postgres:password@localhost:5432/myapp?sslmode=disable"; }
              ];
              
              ports = [{ containerPort = 9187; }];
              
              resources = {
                requests = {
                  cpu = "50m";
                  memory = "32Mi";
                };
                limits = {
                  cpu = "100m";
                  memory = "64Mi";
                };
              };
            }
          ];
          
          volumes = [
            {
              name = "data";
              persistentVolumeClaim = {
                claimName = "postgres-pvc";
              };
            }
          ];
        };
      };
    };
  };

  # Example 14: PostgreSQL Database Initialization ConfigMap
  postgresqlInitConfigMap = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "postgres-init-scripts";
      namespace = "databases";
    };
    data = {
      "init.sql" = ''
        -- Create application user
        CREATE USER app_user WITH PASSWORD 'secure_password';
        
        -- Create databases
        CREATE DATABASE production OWNER app_user;
        CREATE DATABASE staging OWNER app_user;
        
        -- Grant permissions
        GRANT ALL PRIVILEGES ON DATABASE production TO app_user;
        GRANT ALL PRIVILEGES ON DATABASE staging TO app_user;
        
        -- Create replication user
        CREATE USER replication_user WITH REPLICATION PASSWORD 'replication_password';
      '';
    };
  };

  # Example 15: MySQL Configuration ConfigMap
  mysqlConfigMap = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = {
      name = "mysql-config";
      namespace = "databases";
    };
    data = {
      "my.cnf" = ''
        [mysqld]
        max_connections = 1000
        innodb_buffer_pool_size = 20G
        innodb_log_file_size = 512M
        query_cache_type = 0
        query_cache_size = 0
        binlog_format = ROW
        server-id = 1
        log-bin = mysql-bin
        relay-log = mysql-relay-bin
        default-storage-engine = InnoDB
        
        [mysql]
        default-character-set = utf8mb4
        
        [mysqldump]
        quick
        quote-names
        max_allowed_packet = 16M
      '';
    };
  };

  # Example 16: PostgreSQL Storage Class
  postgresqlStorageClass = {
    apiVersion = "storage.k8s.io/v1";
    kind = "StorageClass";
    metadata = {
      name = "fast-ssd";
    };
    provisioner = "kubernetes.io/aws-ebs";
    parameters = {
      type = "gp3";
      iops = "3000";
      throughput = "125";
    };
    allowVolumeExpansion = true;
  };

  # Example 17: Database Namespace with RBAC
  databaseNamespace = {
    apiVersion = "v1";
    kind = "Namespace";
    metadata = {
      name = "databases";
      labels = {
        "app.kubernetes.io/name" = "database-tier";
      };
    };
  };

  databaseServiceAccount = {
    apiVersion = "v1";
    kind = "ServiceAccount";
    metadata = {
      name = "postgres";
      namespace = "databases";
    };
  };

  databaseRole = {
    apiVersion = "rbac.authorization.k8s.io/v1";
    kind = "Role";
    metadata = {
      name = "postgres-role";
      namespace = "databases";
    };
    rules = [
      {
        apiGroups = [ "" ];
        resources = [ "pods" "pods/log" ];
        verbs = [ "get" "list" "watch" ];
      }
      {
        apiGroups = [ "" ];
        resources = [ "secrets" ];
        resourceNames = [ "postgres-secret" ];
        verbs = [ "get" ];
      }
    ];
  };

  databaseRoleBinding = {
    apiVersion = "rbac.authorization.k8s.io/v1";
    kind = "RoleBinding";
    metadata = {
      name = "postgres-role-binding";
      namespace = "databases";
    };
    roleRef = {
      apiGroup = "rbac.authorization.k8s.io";
      kind = "Role";
      name = "postgres-role";
    };
    subjects = [{
      kind = "ServiceAccount";
      name = "postgres";
      namespace = "databases";
    }];
  };

  # Example 18: Database Network Policy
  databaseNetworkPolicy = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata = {
      name = "database-network-policy";
      namespace = "databases";
    };
    spec = {
      podSelector = {
        matchLabels = {
          "app.kubernetes.io/name" = "postgres";
        };
      };
      policyTypes = [ "Ingress" ];
      ingress = [
        {
          from = [
            {
              podSelector = {
                matchLabels = {
                  "app.kubernetes.io/component" = "application";
                };
              };
            }
          ];
          ports = [
            {
              protocol = "TCP";
              port = 5432;
            }
          ];
        }
      ];
    };
  };
}
