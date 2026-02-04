# Example 6: IoT Data Pipeline

Deploy a complete IoT solution with MQTT message broker, time-series database, real-time dashboards, and historical analysis.

## Overview

This example demonstrates:
- MQTT broker (Mosquitto) for device communication
- TimescaleDB for efficient time-series data storage
- Node.js services for data ingestion and processing
- Grafana for real-time visualization and dashboards
- Kafka for event streaming and data processing
- InfluxDB for alternative time-series storage
- Data retention and archival policies

## Architecture

```
┌──────────────────────────────────────────────────────┐
│        IoT Devices (Sensors, Actuators)              │
│        (Temperature, Humidity, Pressure, etc)        │
└─────────────┬──────────────────────────────────────┐
              │ MQTT Protocol (Port 1883)             │
        ┌─────▼─────────────────┐                     │
        │  Mosquitto Broker     │ (2 replicas)        │
        │  (MQTT Server)        │                     │
        └─────┬─────────────────┘                     │
              │                                        │
    ┌─────────┼──────────────────┐                    │
    │         │                  │                    │
┌───▼──┐ ┌────▼──────┐ ┌─────────▼──┐ ┌───────────┐
│Ingest│ │TimescaleDB│ │  Grafana   │ │  Kafka   │
│Worker│ │(Time-     │ │(Dashboard) │ │(Streaming)
│  3   │ │ Series)   │ │            │ │           
└───┬──┘ └───────────┘ └────────────┘ └────┬──────┘
    │
    │   PostgreSQL (Metadata + Hot Storage)
    │
    ├─ Retention Policy (30 days in TimescaleDB)
    │
    └─ Cold Storage Archive (S3/MinIO)
```

## Configuration

Create `iot-pipeline.nix`:

```nix
{ nixernetes, pkgs }:

let
  modules = nixernetes.modules;
in

{
  # PostgreSQL for metadata and TimescaleDB extension
  postgres = modules.database.postgresql {
    name = "iot-db";
    namespace = "default";
    version = "15-alpine";
    resources = {
      requests = { memory = "512Mi"; cpu = "250m"; };
      limits = { memory = "2Gi"; cpu = "1000m"; };
    };
    persistence = {
      size = "100Gi";
      storageClass = "fast-ssd";
    };
    backupSchedule = "0 1 * * *";
    environment = [
      { name = "POSTGRES_INITDB_ARGS"; value = "-c shared_preload_libraries=timescaledb"; }
    ];
  };

  # Mosquitto MQTT Broker
  mosquitto = modules.messaging.mqtt {
    name = "iot-mqtt";
    namespace = "default";
    replicas = 2;
    resources = {
      requests = { memory = "128Mi"; cpu = "100m"; };
      limits = { memory = "256Mi"; cpu = "500m"; };
    };
    persistence = {
      size = "10Gi";
      storageClass = "standard";
    };
    config = {
      "mosquitto.conf" = ''
        listener 1883
        protocol mqtt

        listener 9001
        protocol websockets

        persistence true
        persistence_location /mosquitto/data/

        log_dest file /mosquitto/log/mosquitto.log
        log_type all

        max_connections -1
        max_inflight_messages 20
      '';
    };
  };

  # Data Ingestion Service
  ingestionService = modules.workload.deployment {
    name = "iot-ingest";
    namespace = "default";
    image = "node:18-alpine";
    replicas = 3;
    
    containers = [{
      name = "ingest";
      image = "node:18-alpine";
      ports = [{ name = "http"; containerPort = 3000; }];
      
      env = [
        { name = "NODE_ENV"; value = "production"; }
        { name = "MQTT_BROKER"; value = "iot-mqtt:1883"; }
        { name = "TIMESCALE_URL"; value = "postgresql://user:password@iot-db:5432/iot"; }
        { name = "KAFKA_BROKERS"; value = "iot-kafka:9092"; }
        { name = "LOG_LEVEL"; value = "info"; }
      ];

      livenessProbe = {
        httpGet = { path = "/health"; port = 3000; };
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };

      readinessProbe = {
        httpGet = { path = "/ready"; port = 3000; };
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };

      resources = {
        requests = { memory = "256Mi"; cpu = "200m"; };
        limits = { memory = "512Mi"; cpu = "500m"; };
      };
    }];
  };

  # Data Processing Service
  processingService = modules.workload.deployment {
    name = "iot-process";
    namespace = "default";
    image = "node:18-alpine";
    replicas = 2;
    
    containers = [{
      name = "process";
      image = "node:18-alpine";
      ports = [{ name = "http"; containerPort = 3001; }];
      
      env = [
        { name = "NODE_ENV"; value = "production"; }
        { name = "TIMESCALE_URL"; value = "postgresql://user:password@iot-db:5432/iot"; }
        { name = "KAFKA_BROKERS"; value = "iot-kafka:9092"; }
        { name = "ALERT_THRESHOLD"; value = "35"; }  # Temperature alert
      ];

      resources = {
        requests = { memory = "256Mi"; cpu = "100m"; };
        limits = { memory = "512Mi"; cpu = "500m"; };
      };
    }];
  };

  # Kafka for Event Streaming
  kafka = modules.messaging.kafka {
    name = "iot-kafka";
    namespace = "default";
    replicas = 3;
    resources = {
      requests = { memory = "512Mi"; cpu = "250m"; };
      limits = { memory = "1Gi"; cpu = "1000m"; };
    };
    persistence = {
      size = "50Gi";
      storageClass = "standard";
    };
  };

  # Grafana for Dashboard
  grafana = modules.workload.deployment {
    name = "iot-grafana";
    namespace = "default";
    image = "grafana/grafana:latest";
    replicas = 1;
    
    containers = [{
      name = "grafana";
      image = "grafana/grafana:latest";
      ports = [{ name = "http"; containerPort = 3000; }];
      
      env = [
        { name = "GF_SECURITY_ADMIN_PASSWORD"; value = "admin"; }
        { name = "GF_SECURITY_ADMIN_USER"; value = "admin"; }
        { name = "GF_INSTALL_PLUGINS"; value = "grafana-timeseries-panel"; }
      ];

      volumeMounts = [
        { name = "grafana-storage"; mountPath = "/var/lib/grafana"; }
        { name = "grafana-datasources"; mountPath = "/etc/grafana/provisioning/datasources"; }
      ];

      resources = {
        requests = { memory = "256Mi"; cpu = "100m"; };
        limits = { memory = "512Mi"; cpu = "500m"; };
      };
    }];

    volumes = [
      {
        name = "grafana-storage";
        persistentVolumeClaim = { claimName = "grafana-storage"; };
      }
      {
        name = "grafana-datasources";
        configMap = { name = "grafana-datasources"; };
      }
    ];
  };

  # Grafana DataSources Configuration
  grafanaDatasources = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = { name = "grafana-datasources"; namespace = "default"; };
    data = {
      "datasource.yaml" = ''
        apiVersion: 1
        datasources:
          - name: TimescaleDB
            type: postgres
            url: postgresql://user:password@iot-db:5432/iot
            database: iot
            user: user
            secureJsonData:
              password: password
            isDefault: true
      '';
    };
  };

  # Grafana Storage PVC
  grafanaStoragePVC = {
    apiVersion = "v1";
    kind = "PersistentVolumeClaim";
    metadata = { name = "grafana-storage"; namespace = "default"; };
    spec = {
      accessModes = ["ReadWriteOnce"];
      storageClassName = "standard";
      resources = { requests = { storage = "10Gi"; }; };
    };
  };

  # Data Archival CronJob
  archivalJob = {
    apiVersion = "batch/v1";
    kind = "CronJob";
    metadata = { name = "iot-archival"; namespace = "default"; };
    spec = {
      schedule = "0 0 * * *";  # Daily at midnight
      jobTemplate = {
        spec = {
          template = {
            spec = {
              containers = [{
                name = "archiver";
                image = "node:18-alpine";
                command = ["/bin/bash" "-c"];
                args = ["node /scripts/archive.js"];
                
                env = [
                  { name = "TIMESCALE_URL"; value = "postgresql://user:password@iot-db:5432/iot"; }
                  { name = "ARCHIVE_DAYS"; value = "30"; }  # Keep 30 days in hot storage
                  { name = "S3_BUCKET"; value = "iot-archive"; }
                ];

                volumeMounts = [
                  { name = "archive-script"; mountPath = "/scripts"; }
                ];
              }];

              volumes = [
                {
                  name = "archive-script";
                  configMap = { name = "archival-script"; };
                }
              ];

              restartPolicy = "OnFailure";
            };
          };
        };
      };
    };
  };

  # Archival Script
  archivalScript = {
    apiVersion = "v1";
    kind = "ConfigMap";
    metadata = { name = "archival-script"; namespace = "default"; };
    data = {
      "archive.js" = ''
        const pg = require('pg');
        const AWS = require('aws-sdk');

        const pool = new pg.Pool({
          connectionString: process.env.TIMESCALE_URL
        });

        const s3 = new AWS.S3({
          region: 'us-east-1'
        });

        async function archiveOldData() {
          const archiveDays = parseInt(process.env.ARCHIVE_DAYS || '30');
          const cutoffDate = new Date();
          cutoffDate.setDate(cutoffDate.getDate() - archiveDays);

          // Export old data
          const result = await pool.query(
            'SELECT * FROM sensor_data WHERE time < $1 ORDER BY time',
            [cutoffDate]
          );

          if (result.rows.length === 0) {
            console.log('No data to archive');
            return;
          }

          // Save to S3
          const csvData = convertToCSV(result.rows);
          const filename = `iot-archive-${cutoffDate.toISOString().split('T')[0]}.csv`;

          await s3.putObject({
            Bucket: process.env.S3_BUCKET,
            Key: filename,
            Body: csvData,
            ContentType: 'text/csv'
          }).promise();

          // Delete from database
          await pool.query(
            'DELETE FROM sensor_data WHERE time < $1',
            [cutoffDate]
          );

          console.log(`Archived ${result.rows.length} records to ${filename}`);
        }

        function convertToCSV(rows) {
          const headers = Object.keys(rows[0]);
          const csvHeaders = headers.join(',');
          const csvRows = rows.map(row => 
            headers.map(h => row[h]).join(',')
          );
          return [csvHeaders, ...csvRows].join('\\n');
        }

        archiveOldData().catch(console.error);
      '';
    };
  };

  # Services
  mqttService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "iot-mqtt"; namespace = "default"; };
    spec = {
      type = "LoadBalancer";
      selector = { app = "iot-mqtt"; };
      ports = [
        { name = "mqtt"; port = 1883; targetPort = 1883; }
        { name = "websockets"; port = 9001; targetPort = 9001; }
      ];
    };
  };

  ingestionService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "iot-ingest"; namespace = "default"; };
    spec = {
      type = "ClusterIP";
      selector = { app = "iot-ingest"; };
      ports = [{ name = "http"; port = 3000; targetPort = 3000; }];
    };
  };

  processingService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "iot-process"; namespace = "default"; };
    spec = {
      type = "ClusterIP";
      selector = { app = "iot-process"; };
      ports = [{ name = "http"; port = 3001; targetPort = 3001; }];
    };
  };

  grafanaService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "iot-grafana"; namespace = "default"; };
    spec = {
      type = "LoadBalancer";
      selector = { app = "iot-grafana"; };
      ports = [{ name = "http"; port = 80; targetPort = 3000; }];
    };
  };

  # HPA for ingestion
  ingestionHPA = {
    apiVersion = "autoscaling/v2";
    kind = "HorizontalPodAutoscaler";
    metadata = { name = "iot-ingest-hpa"; namespace = "default"; };
    spec = {
      scaleTargetRef = { apiVersion = "apps/v1"; kind = "Deployment"; name = "iot-ingest"; };
      minReplicas = 3;
      maxReplicas = 10;
      metrics = [
        {
          type = "Resource";
          resource = {
            name = "cpu";
            target = { type = "Utilization"; averageUtilization = 70; };
          };
        }
      ];
    };
  };
}
```

## Step-by-Step Deployment

### 1. Setup Cluster

```bash
mkdir my-iot-pipeline
cd my-iot-pipeline

nix develop
cp iot-pipeline.nix config.nix
```

### 2. Deploy Infrastructure

```bash
# Create manifests
nix eval --apply "builtins.toJSON" -f config.nix > manifests.json

# Deploy
kubectl apply -f manifests.json

# Verify deployment
kubectl get deployments
kubectl get services
```

### 3. Configure MQTT Broker

```bash
# Get MQTT service IP
kubectl get svc iot-mqtt

# Test MQTT connection
mosquitto_pub -h EXTERNAL_IP -t sensors/temp -m "25.5"
mosquitto_sub -h EXTERNAL_IP -t sensors/#
```

### 4. Setup Grafana Dashboards

```bash
# Get Grafana URL
kubectl get svc iot-grafana

# Access Grafana (admin/admin by default)
# http://EXTERNAL_IP

# Create dashboard with UID: sensor-dashboard
# Add panels:
# - Temperature over time
# - Humidity levels
# - Pressure readings
# - Alert status
```

## Ingestion Service Code

```javascript
// ingest.js
const mqtt = require('mqtt');
const pg = require('pg');
const { Kafka } = require('kafkajs');

const pool = new pg.Pool({
  connectionString: process.env.TIMESCALE_URL,
  max: 10
});

const kafka = new Kafka({
  clientId: 'iot-ingest',
  brokers: process.env.KAFKA_BROKERS.split(',')
});

const producer = kafka.producer();
const mqttClient = mqtt.connect(`mqtt://${process.env.MQTT_BROKER}`);

// Initialize TimescaleDB
async function initDB() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS sensor_data (
      time TIMESTAMPTZ NOT NULL,
      device_id TEXT NOT NULL,
      sensor_type TEXT NOT NULL,
      value FLOAT NOT NULL,
      unit TEXT
    );

    SELECT create_hypertable(
      'sensor_data', 'time',
      if_not_exists => true
    );

    CREATE INDEX IF NOT EXISTS idx_sensor_device_time
      ON sensor_data (device_id, sensor_type, time DESC);
  `);
}

// MQTT message handler
mqttClient.on('message', async (topic, message) => {
  try {
    const [, deviceId, sensorType] = topic.split('/');
    const value = parseFloat(message.toString());
    const now = new Date();

    // Store in TimescaleDB
    await pool.query(
      `INSERT INTO sensor_data (time, device_id, sensor_type, value, unit)
       VALUES ($1, $2, $3, $4, $5)`,
      [now, deviceId, sensorType, value, getUnit(sensorType)]
    );

    // Publish to Kafka for processing
    await producer.send({
      topic: 'sensor-events',
      messages: [{
        key: deviceId,
        value: JSON.stringify({
          device_id: deviceId,
          sensor_type: sensorType,
          value,
          timestamp: now
        })
      }]
    });

    console.log(`Ingested: ${deviceId}/${sensorType}=${value}`);
  } catch (error) {
    console.error('Ingestion error:', error);
  }
});

// Subscribe to all sensor topics
mqttClient.subscribe('sensors/#');

// Health check
const express = require('express');
const app = express();

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.get('/ready', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({ status: 'ready' });
  } catch (error) {
    res.status(503).json({ status: 'not ready' });
  }
});

app.listen(3000, () => console.log('Ingestion service running on port 3000'));

function getUnit(sensorType) {
  const units = {
    'temperature': '°C',
    'humidity': '%',
    'pressure': 'hPa',
    'co2': 'ppm'
  };
  return units[sensorType] || '';
}
```

## Processing Service Code

```javascript
// process.js
const { Kafka } = require('kafkajs');
const pg = require('pg');

const pool = new pg.Pool({
  connectionString: process.env.TIMESCALE_URL
});

const kafka = new Kafka({
  clientId: 'iot-processor',
  brokers: process.env.KAFKA_BROKERS.split(',')
});

const consumer = kafka.consumer({ groupId: 'iot-processors' });

async function processEvents() {
  await consumer.connect();
  await consumer.subscribe({ topic: 'sensor-events' });

  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      const event = JSON.parse(message.value);
      
      // Check for anomalies
      if (event.sensor_type === 'temperature' && event.value > process.env.ALERT_THRESHOLD) {
        await raiseAlert(`High temperature alert: ${event.value}°C`);
      }

      // Calculate aggregates
      await updateAggregates(event);

      // Store processed event
      await pool.query(
        `INSERT INTO processed_events (device_id, event_type, data, processed_at)
         VALUES ($1, $2, $3, NOW())`,
        [event.device_id, event.sensor_type, JSON.stringify(event)]
      );
    }
  });
}

async function raiseAlert(message) {
  // Send alert (email, Slack, etc.)
  console.warn(`ALERT: ${message}`);
  
  await pool.query(
    `INSERT INTO alerts (message, severity, created_at)
     VALUES ($1, $2, NOW())`,
    [message, 'warning']
  );
}

async function updateAggregates(event) {
  const interval = '1 hour';
  
  await pool.query(`
    INSERT INTO sensor_stats (time_bucket, device_id, sensor_type, avg_value, max_value, min_value, count)
    SELECT 
      time_bucket('${interval}', time),
      device_id,
      sensor_type,
      AVG(value),
      MAX(value),
      MIN(value),
      COUNT(*)
    FROM sensor_data
    WHERE device_id = $1 AND sensor_type = $2
    GROUP BY time_bucket('${interval}', time), device_id, sensor_type
  `, [event.device_id, event.sensor_type]);
}

processEvents().catch(console.error);
```

## Device Integration Example

```python
# Python device script
import paho.mqtt.client as mqtt
import json
import time
from datetime import datetime

broker = 'MQTT_SERVICE_IP'
device_id = 'device-001'

def on_connect(client, userdata, flags, rc):
    if rc == 0:
        print("Connected to MQTT broker")
    else:
        print(f"Failed to connect, return code {rc}")

client = mqtt.Client()
client.on_connect = on_connect
client.connect(broker, 1883, 60)

def publish_sensor_data():
    temperature = 22.5
    humidity = 65
    
    client.publish(f'sensors/{device_id}/temperature', temperature)
    client.publish(f'sensors/{device_id}/humidity', humidity)

client.loop_start()

while True:
    publish_sensor_data()
    time.sleep(60)  # Publish every minute
```

## Monitoring and Alerting

### Query Recent Data

```sql
-- Latest readings
SELECT device_id, sensor_type, value, time
FROM sensor_data
WHERE time > NOW() - INTERVAL '1 hour'
ORDER BY time DESC
LIMIT 100;

-- Temperature trends
SELECT 
  time_bucket('5 minutes', time) as bucket,
  device_id,
  AVG(value) as avg_temp
FROM sensor_data
WHERE sensor_type = 'temperature'
  AND time > NOW() - INTERVAL '24 hours'
GROUP BY bucket, device_id
ORDER BY bucket DESC;
```

### Set Alert Rules in Grafana

1. Create Alert
2. Set condition: `temperature > 35°C`
3. Configure notification channel (Slack, email, etc.)
4. Set evaluation interval: 1 minute

## Troubleshooting

### MQTT Connection Issues

```bash
# Test MQTT broker
kubectl exec -it pod/iot-mqtt-0 -- mosquitto_sub -t "sensors/#" -u user -P password

# Check broker logs
kubectl logs pod/iot-mqtt-0

# Test from ingestion pod
kubectl exec -it pod/iot-ingest-0 -- nc -zv iot-mqtt 1883
```

### Data Not Appearing in Grafana

```bash
# Check TimescaleDB connection
kubectl exec -it pod/iot-db-0 -- psql -c "SELECT COUNT(*) FROM sensor_data;"

# Verify data insertion
kubectl logs -f deployment/iot-ingest

# Check Grafana datasource
kubectl port-forward svc/iot-grafana 3000:3000
# Configuration > Data Sources > Test
```

### Processing Lag

```bash
# Monitor Kafka consumer lag
kubectl exec -it pod/iot-kafka-0 -- kafka-consumer-groups --bootstrap-server localhost:9092 --group iot-processors --describe

# Check processing pod logs
kubectl logs -f deployment/iot-process
```

## Production Considerations

### 1. Data Retention
- Hot storage (TimescaleDB): 30 days
- Warm storage (Archive): 1 year
- Cold storage (S3): Archive after 1 year

### 2. Scalability
- Use Kafka topics partitioned by device_id
- Scale ingestion service based on message rate
- Use TimescaleDB compression for old data

### 3. Security
- Require MQTT authentication
- Use TLS/SSL for all connections
- Implement device certificate management
- Enable database encryption

### 4. Monitoring
- Track MQTT connection count
- Monitor database query performance
- Alert on data pipeline delays
- Track storage growth

### 5. High Availability
- Run MQTT broker with replication
- Configure PostgreSQL replication
- Use Kafka for fault-tolerant queueing
- Distribute processing across multiple nodes

## Advanced Patterns

### Time-Series Data Compression

```sql
-- Enable compression in TimescaleDB
ALTER TABLE sensor_data SET (
  timescaledb.compress,
  timescaledb.compress_orderby = 'time DESC'
);

-- Compress old chunks
SELECT compress_chunk(chunk) FROM show_chunks('sensor_data') 
WHERE chunk_name < NOW() - INTERVAL '24 hours';
```

### Continuous Aggregates

```sql
-- Real-time hourly rollup
CREATE MATERIALIZED VIEW sensor_hourly AS
SELECT
  time_bucket('1 hour', time) as hour,
  device_id,
  sensor_type,
  AVG(value) as avg_value,
  MAX(value) as max_value,
  MIN(value) as min_value
FROM sensor_data
GROUP BY hour, device_id, sensor_type;
```

## Next Steps

1. Implement device provisioning and management
2. Add ML-based anomaly detection
3. Create mobile app for remote monitoring
4. Implement data sharing with external partners
5. Add predictive maintenance capabilities

## Support

- MQTT Specifications: https://mqtt.org/mqtt-specification
- TimescaleDB Docs: https://docs.timescale.com
- Grafana Documentation: https://grafana.com/docs/
- Kafka Documentation: https://kafka.apache.org/documentation/
