# Example 3: Node.js Microservices Architecture

Deploy a modern microservices system with Node.js services, message queues, and distributed data stores.

## Overview

This example demonstrates:
- Multiple independent Node.js microservices (API Gateway, User Service, Order Service, Payment Service)
- PostgreSQL for transactional data
- Redis for caching and session management
- RabbitMQ for asynchronous messaging
- Service-to-service communication
- Load balancing and auto-scaling
- Distributed logging and monitoring

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Clients (Web/Mobile)                │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────▼────────────┐
        │  API Gateway Service    │ (1 replica)
        │  Node.js (Express)      │
        └────────────┬────────────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
    ┌────▼──┐   ┌────▼──┐   ┌────▼──┐
    │ User  │   │ Order │   │ Payment
    │Service│   │Service│   │Service
    └────┬──┘   └────┬──┘   └────┬──┘
         │           │           │
         └───────────┼───────────┘
                     │
         ┌───────────┼───────────┐
         │           │           │
    ┌────▼──┐   ┌────▼──┐   ┌────▼──┐
    │PostgreSQL  RabbitMQ   Redis
    │(Database)  (Queue)  (Cache)
    └──────┘   └────────┘   └──────┘
```

## Configuration

Create `nodejs-microservices.nix`:

```nix
{ nixernetes, pkgs }:

let
  modules = nixernetes.modules;
in

{
  # PostgreSQL Database
  postgres = modules.database.postgresql {
    name = "microservices-db";
    namespace = "default";
    version = "15-alpine";
    resources = {
      requests = { memory = "256Mi"; cpu = "100m"; };
      limits = { memory = "512Mi"; cpu = "500m"; };
    };
    persistence = {
      size = "10Gi";
      storageClass = "fast-ssd";
    };
    backupSchedule = "0 2 * * *";  # Daily at 2 AM
  };

  # Redis Cache
  redis = modules.database.redis {
    name = "microservices-cache";
    namespace = "default";
    version = "7-alpine";
    resources = {
      requests = { memory = "128Mi"; cpu = "50m"; };
      limits = { memory = "256Mi"; cpu = "200m"; };
    };
    persistence = {
      size = "5Gi";
      storageClass = "standard";
    };
  };

  # RabbitMQ Message Broker
  rabbitmq = modules.messaging.rabbitmq {
    name = "microservices-mq";
    namespace = "default";
    version = "3.12-alpine";
    replicas = 3;
    resources = {
      requests = { memory = "256Mi"; cpu = "100m"; };
      limits = { memory = "512Mi"; cpu = "500m"; };
    };
    persistence = {
      size = "5Gi";
      storageClass = "standard";
    };
    clustering = true;
  };

  # API Gateway Service
  apiGateway = modules.workload.deployment {
    name = "api-gateway";
    namespace = "default";
    image = "node:18-alpine";
    replicas = 2;
    
    containers = [{
      name = "api-gateway";
      image = "node:18-alpine";
      ports = [{ name = "http"; containerPort = 3000; }];
      
      env = [
        { name = "NODE_ENV"; value = "production"; }
        { name = "PORT"; value = "3000"; }
        { name = "USER_SERVICE_URL"; value = "http://user-service:3001"; }
        { name = "ORDER_SERVICE_URL"; value = "http://order-service:3002"; }
        { name = "PAYMENT_SERVICE_URL"; value = "http://payment-service:3003"; }
        { name = "REDIS_URL"; value = "redis://microservices-cache:6379"; }
        { name = "RABBITMQ_URL"; value = "amqp://user:password@microservices-mq:5672"; }
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
        requests = { memory = "128Mi"; cpu = "50m"; };
        limits = { memory = "256Mi"; cpu = "200m"; };
      };
    }];

    strategy = {
      type = "RollingUpdate";
      rollingUpdate = {
        maxSurge = 1;
        maxUnavailable = 0;
      };
    };
  };

  # User Service
  userService = modules.workload.deployment {
    name = "user-service";
    namespace = "default";
    image = "node:18-alpine";
    replicas = 2;
    
    containers = [{
      name = "user-service";
      image = "node:18-alpine";
      ports = [{ name = "http"; containerPort = 3001; }];
      
      env = [
        { name = "NODE_ENV"; value = "production"; }
        { name = "PORT"; value = "3001"; }
        { name = "DATABASE_URL"; value = "postgresql://user:password@microservices-db:5432/microservices"; }
        { name = "REDIS_URL"; value = "redis://microservices-cache:6379"; }
        { name = "RABBITMQ_URL"; value = "amqp://user:password@microservices-mq:5672"; }
      ];

      livenessProbe = {
        httpGet = { path = "/health"; port = 3001; };
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };

      readinessProbe = {
        httpGet = { path = "/ready"; port = 3001; };
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };

      resources = {
        requests = { memory = "128Mi"; cpu = "50m"; };
        limits = { memory = "256Mi"; cpu = "200m"; };
      };
    }];
  };

  # Order Service
  orderService = modules.workload.deployment {
    name = "order-service";
    namespace = "default";
    image = "node:18-alpine";
    replicas = 2;
    
    containers = [{
      name = "order-service";
      image = "node:18-alpine";
      ports = [{ name = "http"; containerPort = 3002; }];
      
      env = [
        { name = "NODE_ENV"; value = "production"; }
        { name = "PORT"; value = "3002"; }
        { name = "DATABASE_URL"; value = "postgresql://user:password@microservices-db:5432/microservices"; }
        { name = "REDIS_URL"; value = "redis://microservices-cache:6379"; }
        { name = "RABBITMQ_URL"; value = "amqp://user:password@microservices-mq:5672"; }
        { name = "PAYMENT_SERVICE_URL"; value = "http://payment-service:3003"; }
      ];

      livenessProbe = {
        httpGet = { path = "/health"; port = 3002; };
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };

      readinessProbe = {
        httpGet = { path = "/ready"; port = 3002; };
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };

      resources = {
        requests = { memory = "128Mi"; cpu = "50m"; };
        limits = { memory = "256Mi"; cpu = "200m"; };
      };
    }];
  };

  # Payment Service
  paymentService = modules.workload.deployment {
    name = "payment-service";
    namespace = "default";
    image = "node:18-alpine";
    replicas = 1;
    
    containers = [{
      name = "payment-service";
      image = "node:18-alpine";
      ports = [{ name = "http"; containerPort = 3003; }];
      
      env = [
        { name = "NODE_ENV"; value = "production"; }
        { name = "PORT"; value = "3003"; }
        { name = "DATABASE_URL"; value = "postgresql://user:password@microservices-db:5432/microservices"; }
        { name = "RABBITMQ_URL"; value = "amqp://user:password@microservices-mq:5672"; }
        { name = "STRIPE_API_KEY"; valueFrom = { secretKeyRef = { name = "payment-secrets"; key = "stripe-key"; }; }; }
      ];

      livenessProbe = {
        httpGet = { path = "/health"; port = 3003; };
        initialDelaySeconds = 30;
        periodSeconds = 10;
      };

      readinessProbe = {
        httpGet = { path = "/ready"; port = 3003; };
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };

      resources = {
        requests = { memory = "128Mi"; cpu = "50m"; };
        limits = { memory = "256Mi"; cpu = "200m"; };
      };
    }];
  };

  # Services for each microservice
  apiGatewayService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "api-gateway"; namespace = "default"; };
    spec = {
      type = "LoadBalancer";
      selector = { app = "api-gateway"; };
      ports = [{ name = "http"; port = 80; targetPort = 3000; }];
    };
  };

  userServiceService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "user-service"; namespace = "default"; };
    spec = {
      type = "ClusterIP";
      selector = { app = "user-service"; };
      ports = [{ name = "http"; port = 3001; targetPort = 3001; }];
    };
  };

  orderServiceService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "order-service"; namespace = "default"; };
    spec = {
      type = "ClusterIP";
      selector = { app = "order-service"; };
      ports = [{ name = "http"; port = 3002; targetPort = 3002; }];
    };
  };

  paymentServiceService = {
    apiVersion = "v1";
    kind = "Service";
    metadata = { name = "payment-service"; namespace = "default"; };
    spec = {
      type = "ClusterIP";
      selector = { app = "payment-service"; };
      ports = [{ name = "http"; port = 3003; targetPort = 3003; }];
    };
  };

  # Secrets for sensitive data
  paymentSecrets = {
    apiVersion = "v1";
    kind = "Secret";
    metadata = { name = "payment-secrets"; namespace = "default"; };
    type = "Opaque";
    stringData = {
      "stripe-key" = "sk_live_XXXXXXXX";  # Replace with actual key
    };
  };

  # HPA for User Service
  userServiceHPA = {
    apiVersion = "autoscaling/v2";
    kind = "HorizontalPodAutoscaler";
    metadata = { name = "user-service-hpa"; namespace = "default"; };
    spec = {
      scaleTargetRef = { apiVersion = "apps/v1"; kind = "Deployment"; name = "user-service"; };
      minReplicas = 2;
      maxReplicas = 5;
      metrics = [
        {
          type = "Resource";
          resource = {
            name = "cpu";
            target = { type = "Utilization"; averageUtilization = 70; };
          };
        }
        {
          type = "Resource";
          resource = {
            name = "memory";
            target = { type = "Utilization"; averageUtilization = 80; };
          };
        }
      ];
    };
  };

  # HPA for Order Service
  orderServiceHPA = {
    apiVersion = "autoscaling/v2";
    kind = "HorizontalPodAutoscaler";
    metadata = { name = "order-service-hpa"; namespace = "default"; };
    spec = {
      scaleTargetRef = { apiVersion = "apps/v1"; kind = "Deployment"; name = "order-service"; };
      minReplicas = 2;
      maxReplicas = 5;
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

  # NetworkPolicy to restrict traffic
  networkPolicy = {
    apiVersion = "networking.k8s.io/v1";
    kind = "NetworkPolicy";
    metadata = { name = "microservices-policy"; namespace = "default"; };
    spec = {
      podSelector = { };
      policyTypes = ["Ingress" "Egress"];
      ingress = [
        {
          from = [{ podSelector = { matchLabels = { app = "api-gateway"; }; }; }];
          ports = [{ protocol = "TCP"; port = 3001; }];
        }
        {
          from = [{ podSelector = { matchLabels = { app = "api-gateway"; }; }; }];
          ports = [{ protocol = "TCP"; port = 3002; }];
        }
        {
          from = [{ podSelector = { matchLabels = { app = "order-service"; }; }; }];
          ports = [{ protocol = "TCP"; port = 3003; }];
        }
      ];
      egress = [
        { to = [{ podSelector = { }; }]; }
      ];
    };
  };
}
```

## Step-by-Step Deployment

### 1. Prepare the Environment

```bash
# Create a new project
mkdir my-microservices
cd my-microservices

# Initialize flake
cat > flake.nix << 'EOF'
{
  description = "Node.js Microservices with Nixernetes";
  
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
          kubernetes-helm
          nix
          nixernetes.packages.${system}.default
        ];
      };
    });
}
EOF

nix flake update
```

### 2. Create the Configuration File

Save the configuration above as `config.nix`:

```bash
cp nodejs-microservices.nix config.nix
```

### 3. Generate Kubernetes Manifests

```bash
# Enter nix environment
nix develop

# Generate YAML
nix eval --apply "builtins.toJSON" -f config.nix > manifests.json

# Convert to YAML (optional)
cat manifests.json | jq . > manifests.yaml
```

### 4. Deploy to Cluster

```bash
# Apply all manifests
kubectl apply -f manifests.yaml

# Watch deployment
kubectl get deployments -w

# Check service status
kubectl get services
```

### 5. Access the Services

```bash
# Get LoadBalancer IP
kubectl get svc api-gateway

# Test the API
curl http://EXTERNAL_IP/api/health

# Port-forward for local testing
kubectl port-forward svc/api-gateway 8080:80
```

## Application Code Example

### API Gateway (Node.js)

```javascript
// api-gateway/index.js
const express = require('express');
const axios = require('axios');
const redis = require('redis');
const amqp = require('amqplib');

const app = express();
const client = redis.createClient({ url: process.env.REDIS_URL });
let channel;

// Initialize message queue
async function initMQ() {
  const connection = await amqp.connect(process.env.RABBITMQ_URL);
  channel = await connection.createChannel();
}

// Health check
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Create user
app.post('/api/users', async (req, res) => {
  try {
    const response = await axios.post(
      `${process.env.USER_SERVICE_URL}/users`,
      req.body
    );
    
    // Clear user cache
    await client.del('users:*');
    
    // Publish event
    channel.publish(
      'events',
      'user.created',
      Buffer.from(JSON.stringify(response.data))
    );
    
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Create order
app.post('/api/orders', async (req, res) => {
  try {
    const response = await axios.post(
      `${process.env.ORDER_SERVICE_URL}/orders`,
      req.body
    );
    
    // Publish event
    channel.publish(
      'events',
      'order.created',
      Buffer.from(JSON.stringify(response.data))
    );
    
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Payment processing
app.post('/api/payments', async (req, res) => {
  try {
    const response = await axios.post(
      `${process.env.PAYMENT_SERVICE_URL}/payments`,
      req.body
    );
    
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

initMQ().then(() => {
  app.listen(3000, () => console.log('API Gateway running on port 3000'));
});
```

## Monitoring and Observability

### Check Service Logs

```bash
# API Gateway logs
kubectl logs -f deployment/api-gateway

# User Service logs
kubectl logs -f deployment/user-service

# Order Service logs
kubectl logs -f deployment/order-service
```

### Monitor Metrics

```bash
# CPU/Memory usage
kubectl top pods

# Pod events
kubectl describe pod <pod-name>

# Service connectivity
kubectl exec -it <pod-name> -- curl http://user-service:3001/health
```

### Database Access

```bash
# Connect to PostgreSQL
kubectl exec -it pod/microservices-db-0 -- psql -U user -d microservices

# Check Redis
kubectl exec -it pod/microservices-cache-0 -- redis-cli INFO

# Check RabbitMQ
kubectl port-forward svc/microservices-mq 15672:15672
# Access http://localhost:15672 (user: guest, password: guest)
```

## Scaling the Application

### Scale Individual Services

```bash
# Scale User Service to 5 replicas
kubectl scale deployment user-service --replicas=5

# Check replica status
kubectl get deployment user-service
```

### Auto-Scaling

The configuration includes HPAs that automatically scale services based on resource usage:

```bash
# View HPA status
kubectl get hpa

# Check HPA details
kubectl describe hpa user-service-hpa
```

## Troubleshooting

### Service Discovery Issues

```bash
# Check if services are discoverable
kubectl get svc

# Test DNS resolution from pod
kubectl exec -it <pod-name> -- nslookup user-service

# Check endpoints
kubectl get endpoints user-service
```

### Database Connection Issues

```bash
# Check PostgreSQL pod
kubectl get pod -l app=microservices-db

# View PostgreSQL logs
kubectl logs pod/microservices-db-0

# Test connection
kubectl exec -it pod/microservices-db-0 -- psql -c "SELECT version();"
```

### Message Queue Issues

```bash
# Check RabbitMQ pod
kubectl get pod -l app=microservices-mq

# Access RabbitMQ Management UI
kubectl port-forward svc/microservices-mq 15672:15672

# Check queues
kubectl exec -it pod/microservices-mq-0 -- rabbitmqctl list_queues
```

### Network Policy Issues

```bash
# Verify network policies
kubectl get networkpolicy

# Check policy rules
kubectl describe networkpolicy microservices-policy

# Test connectivity
kubectl exec -it <pod-name> -- curl http://user-service:3001/health
```

## Production Considerations

### 1. Resource Management
- Monitor resource usage with metrics-server
- Set appropriate requests/limits per service
- Use namespace quotas to prevent resource exhaustion

### 2. High Availability
- Run multiple replicas (2+) of each service
- Use pod disruption budgets for controlled downtime
- Configure cluster autoscaling for infrastructure

### 3. Security
- Use NetworkPolicies to restrict traffic
- Implement RBAC for service accounts
- Store secrets in Kubernetes Secrets or external vaults
- Enable pod security policies

### 4. Data Persistence
- Use persistent volumes for databases
- Configure automated backups for PostgreSQL
- Set up replication for critical data
- Test disaster recovery procedures

### 5. Observability
- Implement distributed tracing (Jaeger)
- Set up centralized logging (ELK/Loki)
- Configure Prometheus for metrics collection
- Create alerts for critical conditions

### 6. Service Mesh (Optional)
Consider using Istio or Linkerd for:
- Advanced traffic management
- Automatic retries and circuit breaking
- Distributed tracing
- mTLS for service-to-service communication

## Customization Guide

### Adding a New Microservice

1. Create service configuration in `config.nix`
2. Add service network policy rules
3. Create environment variables for other services
4. Deploy and test connectivity

### Changing Database Schema

```bash
# Connect to database
kubectl port-forward svc/microservices-db 5432:5432

# Run migrations
psql -h localhost -U user -d microservices < migration.sql
```

### Updating Service Replicas

```bash
# Edit deployment
kubectl edit deployment user-service

# Or use kubectl patch
kubectl patch deployment user-service -p '{"spec":{"replicas":3}}'
```

## Common Patterns

### Circuit Breaker Pattern

```javascript
const CircuitBreaker = require('opossum');

const breaker = new CircuitBreaker(async (url, data) => {
  return axios.post(url, data);
}, { timeout: 5000 });

app.post('/api/payments', async (req, res) => {
  try {
    const result = await breaker.fire(
      `${process.env.PAYMENT_SERVICE_URL}/payments`,
      req.body
    );
    res.json(result.data);
  } catch (error) {
    res.status(503).json({ error: 'Service temporarily unavailable' });
  }
});
```

### Saga Pattern for Distributed Transactions

```javascript
// Order Service manages saga
app.post('/api/orders', async (req, res) => {
  const orderId = generateId();
  
  try {
    // Step 1: Create order
    await axios.post(`${ORDER_SERVICE}/orders`, { id: orderId, ...req.body });
    
    // Step 2: Process payment
    const payment = await axios.post(`${PAYMENT_SERVICE}/payments`, {
      orderId,
      amount: req.body.total
    });
    
    // Step 3: Update inventory
    await axios.post(`${USER_SERVICE}/inventory`, {
      orderId,
      items: req.body.items
    });
    
    res.json({ orderId, status: 'success' });
  } catch (error) {
    // Compensating transactions
    await axios.post(`${ORDER_SERVICE}/orders/${orderId}/cancel`);
    res.status(500).json({ error: 'Transaction failed' });
  }
});
```

## Next Steps

1. Implement authentication/authorization between services
2. Add API rate limiting and quota management
3. Set up distributed tracing with Jaeger
4. Implement service mesh for advanced traffic management
5. Add comprehensive monitoring and alerting
6. Create backup and disaster recovery procedures

## Support

- Refer to [Service Mesh Module Docs](../../MODULE_REFERENCE.md#service-mesh)
- Check [Database Module Docs](../../MODULE_REFERENCE.md#database-management)
- Review [Messaging Module Docs](../../MODULE_REFERENCE.md#event-processing)
- See [Performance Tuning Guide](../../PERFORMANCE_TUNING.md)
