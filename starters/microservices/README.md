# Nixernetes Starter Kit: Microservices Architecture

This starter kit provides a foundation for deploying a microservices-based application with Nixernetes.

## What's Included

- Multiple independent services (frontend, API, worker)
- PostgreSQL database with connection pooling
- Redis for caching and sessions
- RabbitMQ for async messaging
- Service-to-service communication
- Health checks and auto-scaling
- Example monitoring setup

## Quick Start

1. Copy this directory to your project:
   ```bash
   cp -r starters/microservices your-app
   cd your-app
   ```

2. Update service names in `config.nix`:
   ```nix
   services = {
     frontend = { ... };
     api = { ... };
     worker = { ... };
   };
   ```

3. Deploy:
   ```bash
   nix flake check --offline
   nix build
   kubectl apply -f result/manifest.yaml
   ```

## Architecture

```
┌─────────────┐
│  Frontend   │ (React/Vue web app)
└──────┬──────┘
       │
┌──────▼───────┐
│  API Service │ (Node.js/Python)
└──────┬───────┘
       │
  ┌────┴────┐
  │          │
┌─▼──┐  ┌──▼──┐
│ DB │  │Cache│
└────┘  └─────┘
  │
┌─▼────────┐
│ RabbitMQ │
└──────────┘
  │
┌─▼──────────┐
│   Worker   │ (Background jobs)
└────────────┘
```

## Service Communication

- **Frontend → API**: HTTP/REST or GraphQL
- **API → Database**: Direct connection with pooling
- **API → Cache**: Direct Redis connection
- **API → Message Queue**: AMQP
- **Worker → Message Queue**: Consume events
- **Worker → Database**: Direct connection

## Configuration

Each service has independent configuration:

```nix
frontend = {
  image = "myrepo/frontend:latest";
  port = 3000;
  env = { API_URL = "http://api:5000"; };
};

api = {
  image = "myrepo/api:latest";
  port = 5000;
  env = { 
    DATABASE_URL = "postgresql://...";
    REDIS_URL = "redis://cache:6379";
  };
};

worker = {
  image = "myrepo/worker:latest";
  env = {
    QUEUE_URL = "amqp://rabbitmq:5672";
    DATABASE_URL = "postgresql://...";
  };
};
```

## Scaling

Each service can be scaled independently:

```bash
# Scale API to 5 replicas
kubectl scale deployment/api --replicas=5

# Or set in config.nix
api.replicas = 5;
```

## Monitoring

Check service health:

```bash
# View all services
kubectl get pods -l tier=microservices

# Check service logs
kubectl logs -f deployment/api -n default

# Monitor resource usage
kubectl top pods -l tier=microservices
```

## Service Discovery

Services discover each other using Kubernetes DNS:

- `api.default.svc.cluster.local:5000` (from frontend)
- `cache.default.svc.cluster.local:6379` (from api)
- `rabbitmq.default.svc.cluster.local:5672` (from worker)

## Database Migrations

For database migrations, use init containers:

```nix
api = {
  initContainers = [{
    name = "migrate";
    image = "myrepo/api:latest";
    command = ["npm" "run" "migrate"];
    env = { DATABASE_URL = "postgresql://..."; };
  }];
};
```

## Message Queue

Use RabbitMQ for async communication:

```python
# In your worker service
import pika

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host='rabbitmq')
)
channel = connection.channel()

def callback(ch, method, properties, body):
    print(f"Processing: {body}")
    ch.basic_ack(delivery_tag=method.delivery_tag)

channel.basic_consume(
    queue='tasks', 
    on_message_callback=callback
)
channel.start_consuming()
```

## Next Steps

- Review [Real-World Microservices Example](../../docs/EXAMPLES/example-3-nodejs-microservices.md)
- Check [Module Reference](../../MODULE_REFERENCE.md) for advanced options
- Read about [service mesh](../../docs/SERVICE_MESH.md) for production deployments
- Explore [monitoring and observability](../../docs/MONITORING.md)

## Troubleshooting

### Services can't communicate

Check service DNS:
```bash
kubectl exec -it <pod> -- nslookup api.default.svc.cluster.local
```

### Message queue is full

Monitor RabbitMQ:
```bash
kubectl exec -it rabbitmq-0 -- rabbitmqctl status
```

### Database connection issues

Check database logs:
```bash
kubectl logs -f deployment/postgres
```

Verify connection string:
```bash
echo $DATABASE_URL  # Check from within pod
```

## Support

- Questions? Check the [Troubleshooting Discussion](https://github.com/anomalyco/nixernetes/discussions/categories/help-wanted)
- Found an issue? [Report it](https://github.com/anomalyco/nixernetes/issues/new?template=bug_report.yml)
