# Multi-Tier Application Deployment Guide

This guide walks through deploying a comprehensive, production-grade multi-tier application using Nixernetes.

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Detailed Component Guide](#detailed-component-guide)
5. [Security & Compliance](#security--compliance)
6. [Observability](#observability)
7. [Troubleshooting](#troubleshooting)
8. [Production Checklist](#production-checklist)

## Architecture Overview

The example application implements a modern, cloud-native architecture with proper separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    Internet Users                           │
└─────────────────────────────────────────────────────────────┘
                            │
                    ┌───────▼────────┐
                    │   Ingress      │
                    │   (TLS/SSL)    │
                    └───────┬────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
    ┌────▼────┐        ┌────▼────┐       ┌────▼────┐
    │Frontend  │        │API      │       │Grafana  │
    │(Nginx)   │        │Gateway  │       │(Monitoring)
    │3 replicas│        │2 replicas│      │
    └──────────┘        └────┬────┘       └─────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
    ┌────▼────┐         ┌────▼────┐        ┌────▼────┐
    │PostgreSQL│         │Redis    │        │RabbitMQ │
    │Database  │         │Cache    │        │Queue    │
    │(1 replica)         │         │        │         │
    └──────────┘         └─────────┘        └─────────┘
                             │
                    ┌────────▼─────────┐
                    │  Prometheus      │
                    │  (Time-series DB)│
                    └──────────────────┘
```

### Components

| Component | Purpose | Replicas | Compliance |
|-----------|---------|----------|-----------|
| **Frontend (Nginx)** | SPA distribution, reverse proxy | 3 | SOC2/Strict |
| **API Gateway** | REST API server, business logic | 2 | SOC2/Strict |
| **PostgreSQL** | Primary data store | 1 (HA possible) | SOC2/Strict |
| **Redis** | Session & cache layer | 1 | SOC2/Strict |
| **RabbitMQ** | Async task queue | 1 | SOC2/Strict |
| **Prometheus** | Metrics collection | 1 | SOC2/Standard |
| **Grafana** | Visualization & dashboards | 1 | SOC2/Standard |

## Prerequisites

### Local Environment

- Nix with flakes support
- A Kubernetes cluster (v1.28+)
  - Recommended: Kind for local testing, EKS/GKE/AKS for production
- `kubectl` configured to access your cluster
- ExternalSecrets Operator installed (if using secrets)
- Prometheus Stack (optional, for monitoring)

### Cluster Requirements

```bash
# Verify cluster version
kubectl version

# Should be 1.28 or later
```

### Storage Requirements

- **PostgreSQL**: 50Gi SSD storage
- **RabbitMQ**: 20Gi standard storage
- **Prometheus**: 100Gi SSD storage
- **Grafana**: ConfigMaps only (no persistent volume)

Total: ~170Gi

## Quick Start

### 1. Prepare Vault for Secrets

```bash
# Unseal Vault and login
vault login

# Create secret policies
vault kv put secret/database/postgres \
  password=$(openssl rand -base64 32)

vault kv put secret/app/postgres \
  username="app_user" \
  password=$(openssl rand -base64 32)

vault kv put secret/app/api \
  key=$(openssl rand -base64 32)

vault kv put secret/app/security \
  jwt_secret=$(openssl rand -base64 32)

vault kv put secret/messaging/rabbitmq \
  password=$(openssl rand -base64 32)

vault kv put secret/monitoring/grafana \
  admin_password=$(openssl rand -base64 32)
```

### 2. Deploy to Kubernetes

```bash
# Enter Nixernetes dev environment
cd /home/shift/code/ideas/nixernetes
nix develop

# Generate manifests (example)
nix build .#example-app -o manifests

# Apply to cluster
kubectl create namespace production
kubectl apply -f manifests/

# Verify deployment
kubectl -n production get pods
kubectl -n production get svc
```

### 3. Verify Services

```bash
# Check all pods are running
kubectl -n production get pods -w

# Port-forward to test locally
kubectl -n production port-forward svc/frontend 8080:80
kubectl -n production port-forward svc/grafana 3000:3000

# Visit in browser:
# http://localhost:8080 (Application)
# http://localhost:3000 (Grafana)
```

## Detailed Component Guide

### Frontend (Nginx)

The frontend serves a React SPA with proper configuration:

**Key Features**:
- 3 replicas for high availability
- SPA routing support (fallback to index.html)
- Reverse proxy to API
- Health checks every 10 seconds
- Resource limits: 250m CPU, 256Mi memory

**Configuration**:
```nix
configMap = {
  "nginx.conf" = ''
    location /api/ {
      proxy_pass http://api-gateway:8080;
      # Proper headers forwarding
    }
  '';
};
```

**Deployment**:
```bash
# Check logs
kubectl -n production logs -f deploy/frontend

# Scale if needed
kubectl -n production scale deploy/frontend --replicas=5

# Update image
kubectl -n production set image deploy/frontend \
  frontend=myregistry/myapp:v2.0
```

### API Gateway (Node.js)

The backend API handles business logic:

**Key Features**:
- 2 replicas for failover
- Connects to PostgreSQL, Redis, RabbitMQ
- Metrics exposed on port 9090
- Health checks: `/health` and `/health/ready`
- Secrets injected from Vault

**Environment Variables**:
```bash
NODE_ENV=production
DATABASE_HOST=postgres
REDIS_URL=redis://redis:6379
RABBITMQ_URL=amqp://guest:guest@rabbitmq:5672
```

**Health Endpoints**:
```bash
# Liveness (is it running?)
curl http://api-gateway:8080/health

# Readiness (is it ready for traffic?)
curl http://api-gateway:8080/health/ready

# Metrics (for Prometheus)
curl http://api-gateway:9090/metrics
```

### PostgreSQL Database

Primary data store with persistence:

**Key Features**:
- 50Gi persistent volume (SSD recommended)
- Automated backups via WAL
- Health checks every 10 seconds
- Monitoring via postgres_exporter
- Audit logging enabled

**Setup**:
```bash
# Initialize database (first deployment)
kubectl -n production exec -it postgres-0 -- \
  createdb -U postgres appdb

# Run migrations
kubectl -n production exec -it postgres-0 -- \
  psql -U app_user -d appdb -f /migrations/schema.sql

# Backup
kubectl -n production exec -it postgres-0 -- \
  pg_dump -U postgres appdb > backup.sql
```

**Monitoring**:
```bash
# Check database size
kubectl -n production exec postgres-0 -- \
  psql -U postgres -c "SELECT pg_database.datname, \
    pg_size_pretty(pg_database_size(pg_database.datname)) \
    FROM pg_database;"

# Check connections
kubectl -n production exec postgres-0 -- \
  psql -U postgres -c "SELECT datname, count(*) \
    FROM pg_stat_activity GROUP BY datname;"
```

### Redis Cache

In-memory cache with persistence:

**Key Features**:
- 1Gi memory limit
- LRU eviction policy
- AOF persistence enabled
- Health checks every 10 seconds
- Monitoring via redis_exporter

**Usage**:
```bash
# Connect to Redis
kubectl -n production exec -it redis-0 -- redis-cli

# Inside redis-cli:
> INFO stats
> DBSIZE
> MEMORY STATS
```

### RabbitMQ Queue

Message broker for async tasks:

**Key Features**:
- 20Gi persistent volume
- Admin console on port 15672
- Health checks every 10 seconds
- Monitoring via rabbitmq_exporter
- Default guest/guest credentials (change in production!)

**Admin Interface**:
```bash
# Port forward to admin UI
kubectl -n production port-forward svc/rabbitmq 15672:15672

# Visit: http://localhost:15672
# Username: guest
# Password: guest (from Vault in production)
```

### Prometheus Monitoring

Time-series database for metrics:

**Key Features**:
- 100Gi persistent volume
- Scrapes all components every 15 seconds
- 15-day retention by default
- Health checks every 10 seconds

**Metrics Collected**:
- API Gateway requests, latency, errors
- PostgreSQL connections, queries
- Redis memory usage, evictions
- RabbitMQ queue depth
- Kubernetes resource usage

**Access**:
```bash
# Port forward
kubectl -n production port-forward svc/prometheus 9090:9090

# Visit: http://localhost:9090
# Query examples:
# - up{} - Service availability
# - rate(http_requests_total[5m]) - Request rate
# - container_memory_usage_bytes{} - Memory usage
```

### Grafana Dashboards

Visualization and alerting:

**Key Features**:
- 1 replica with Prometheus datasource
- Pre-configured dashboards
- Alert rules
- User management

**Setup**:
```bash
# Port forward
kubectl -n production port-forward svc/grafana 3000:3000

# Visit: http://localhost:3000
# Default: admin / changeme (change immediately!)
# Datasource: Prometheus (pre-configured)

# Create dashboard:
# 1. New Dashboard
# 2. Add Panel
# 3. Query: rate(http_requests_total[5m])
# 4. Visualize
```

## Security & Compliance

### Default Network Policies

The deployment uses default-deny network policies with explicit allow rules:

```yaml
# Implicit behavior:
# - All ingress DENIED by default
# - All egress DENIED by default
# - Explicit rules allow specific traffic

# Frontend can:
# ✓ Receive traffic from Ingress
# ✓ Send traffic to API Gateway

# API Gateway can:
# ✓ Receive traffic from Frontend
# ✓ Send traffic to PostgreSQL, Redis, RabbitMQ
# ✓ Send metrics to Prometheus
```

### RBAC (Role-Based Access Control)

Service accounts with minimal permissions:

```yaml
# Each component has its own service account
# with only necessary permissions

api-gateway:
  - read configmaps
  - read secrets (via ExternalSecrets)

postgres:
  - none (no cluster API access needed)

monitoring:
  - read pods (scrape metrics)
  - read nodes
```

### Secrets Management

All sensitive data stored in Vault:

```bash
# Vault paths used:
secret/database/postgres       # DB root password
secret/app/postgres            # App DB credentials
secret/app/api                 # API keys
secret/app/security            # JWT secrets
secret/messaging/rabbitmq      # Queue credentials
secret/monitoring/grafana      # Dashboard admin password
```

### Compliance Labels

All resources labeled with compliance metadata:

```yaml
nixernetes.io/framework: "SOC2"
nixernetes.io/compliance-level: "strict"  # or "standard"
nixernetes.io/owner: "platform-eng"
nixernetes.io/data-classification: "confidential"  # or "internal"
```

### Data Classification

- **Confidential**: PostgreSQL, API Gateway, RabbitMQ
  - Requires encryption at rest
  - Requires encryption in transit
  - Audit logging required
  
- **Internal**: Frontend, Redis, Monitoring
  - Encryption recommended
  - Standard logging

## Observability

### Metrics Available

```
# Request metrics (API Gateway)
http_requests_total{method, status, path}
http_request_duration_seconds{method, path}
http_request_size_bytes{}
http_response_size_bytes{}

# Database metrics (PostgreSQL)
pg_connections_total
pg_query_duration_seconds
pg_connection_max

# Cache metrics (Redis)
redis_memory_used_bytes
redis_keyspace_hits_total
redis_keyspace_misses_total
redis_evicted_keys_total

# Queue metrics (RabbitMQ)
rabbitmq_queue_messages_total
rabbitmq_queue_consumers
```

### Dashboards

Pre-configured in Grafana:

1. **Application Overview**
   - Request rate, latency, errors
   - API latency percentiles (p50, p95, p99)
   - Active requests

2. **Database**
   - Connection count
   - Query latency
   - Cache hit ratio
   - Disk usage

3. **Infrastructure**
   - CPU/Memory per pod
   - Network I/O
   - Disk I/O
   - Node health

4. **Errors**
   - HTTP 5xx errors
   - Application exceptions
   - Database errors
   - Queue failures

### Alerting

Example alert rules (to configure):

```yaml
# High error rate
expr: rate(http_requests_total{status=~"5.."}[5m]) > 0.05

# Database connection pool near limit
expr: pg_connections_total / pg_connection_max > 0.8

# Pod memory usage
expr: container_memory_usage_bytes / container_memory_limit > 0.9

# Persistent volume space
expr: kubelet_volume_stats_used_bytes / kubelet_volume_stats_capacity_bytes > 0.85
```

## Troubleshooting

### Pod Fails to Start

```bash
# Check pod status
kubectl -n production describe pod <pod-name>

# Check logs
kubectl -n production logs <pod-name>

# Check events
kubectl -n production get events --sort-by='.lastTimestamp'

# Common issues:
# - ImagePullBackOff: Docker image not found
# - CrashLoopBackOff: Pod crashes on start (check logs)
# - Pending: Waiting for resources (check node resources)
```

### Connectivity Issues

```bash
# Test DNS
kubectl -n production exec <pod> -- nslookup postgres

# Test network policy
kubectl -n production exec <pod> -- \
  nc -zv postgres 5432

# Test service discovery
kubectl -n production exec <pod> -- \
  wget -O- http://api-gateway:8080/health
```

### Database Issues

```bash
# Check PostgreSQL logs
kubectl -n production logs -f statefulset/postgres

# Connect to database
kubectl -n production exec -it postgres-0 -- \
  psql -U postgres

# Check connections
psql> SELECT datname, count(*) FROM pg_stat_activity GROUP BY datname;

# Check disk space
psql> SELECT pg_database.datname, pg_size_pretty(pg_database_size(pg_database.datname)) FROM pg_database;
```

### Performance Issues

```bash
# Check resource usage
kubectl -n production top pods
kubectl -n production top nodes

# Check metrics in Prometheus
# Visit: http://localhost:9090

# Check logs for slow queries
kubectl -n production logs -f deploy/api-gateway | grep "duration"
```

## Production Checklist

Before deploying to production:

### Security
- [ ] All default passwords changed
- [ ] Vault configured with proper authentication
- [ ] TLS certificates obtained (Let's Encrypt or internal CA)
- [ ] Network policies reviewed and tested
- [ ] RBAC permissions minimal
- [ ] Secrets encrypted at rest in etcd
- [ ] Pod security policies enforced

### High Availability
- [ ] Frontend scaled to 3+ replicas
- [ ] API Gateway scaled to 2+ replicas
- [ ] Database replication configured
- [ ] Redis persistence enabled
- [ ] RabbitMQ clustering considered
- [ ] Multi-AZ node distribution

### Observability
- [ ] Prometheus retention configured (15+ days)
- [ ] Grafana dashboards created
- [ ] Alerts configured and tested
- [ ] Log aggregation setup (ELK, Loki, etc.)
- [ ] Tracing configured (Jaeger, Zipkin)

### Backups & Disaster Recovery
- [ ] PostgreSQL backups automated (daily)
- [ ] Backup tested with restore procedure
- [ ] RabbitMQ queue backups verified
- [ ] Etcd backup schedule confirmed
- [ ] Disaster recovery runbook created

### Performance & Capacity
- [ ] Load testing completed
- [ ] Resource requests/limits tuned
- [ ] Autoscaling policies configured
- [ ] Database indexed appropriately
- [ ] Redis memory configured correctly
- [ ] RabbitMQ queue limits set

### Compliance & Audit
- [ ] Compliance labels applied
- [ ] Audit logging enabled
- [ ] Data classification verified
- [ ] Compliance documentation created
- [ ] Security scan completed (Trivy/Snyk)

### Documentation
- [ ] Runbooks created
- [ ] Troubleshooting guide completed
- [ ] Team trained on operations
- [ ] Escalation procedures defined
- [ ] Change management process documented

## Additional Resources

- [Nixernetes Main Documentation](../README.md)
- [Testing Guide](../docs/TESTING.md)
- [CI/CD Integration](../docs/CI_CD.md)
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [RabbitMQ Documentation](https://www.rabbitmq.com/documentation.html)
- [Prometheus Documentation](https://prometheus.io/docs/)

## Support

For issues or questions:

1. Check this guide
2. Review Kubernetes events: `kubectl describe pod <pod>`
3. Check pod logs: `kubectl logs <pod>`
4. Review Prometheus metrics
5. Check Grafana dashboards

For Nixernetes-specific issues, see the main README and testing documentation.
