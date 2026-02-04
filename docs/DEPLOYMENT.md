Deployment Guide

This guide covers deploying Nixernetes in different environments:
local development, Docker, and Kubernetes.

Table of Contents

1. Local Development Setup
2. Docker Deployment
3. Kubernetes Deployment
4. Configuration Reference
5. Troubleshooting
6. Performance Tuning

1. LOCAL DEVELOPMENT SETUP

Prerequisites

- Node.js 18+ and npm/yarn
- TypeScript 5+
- nix and direnv (optional, for NixOS compatibility)
- better-sqlite3 (automatically installed with npm)

Quick Start

1. Install dependencies:

   cd backend
   npm install

   cd ../web-ui
   npm install

2. Initialize database:

   cd backend
   npm run db:migrate

3. Start development servers:

   # Terminal 1: Backend
   cd backend
   npm run dev

   # Terminal 2: Frontend
   cd web-ui
   npm run dev

4. Access the application:

   - Web UI: http://localhost:5173
   - Backend API: http://localhost:8080
   - Health Check: http://localhost:8080/health

Development Configuration

Create a .env file in the backend directory:

   PORT=8080
   NODE_ENV=development
   DB_PATH=./nixernetes.db

Frontend Configuration

The frontend automatically detects the backend URL during development:
- Development (Vite): Uses http://localhost:8080
- Production: Uses the same origin as the web server

2. DOCKER DEPLOYMENT

Local Docker Development

Use docker-compose for local development with all services:

   docker-compose up

This starts:
- Frontend development server on port 5173
- Backend development server on port 8080
- Shared data volume for the database

Viewing Logs

   # All services
   docker-compose logs -f

   # Specific service
   docker-compose logs -f backend
   docker-compose logs -f frontend

Stopping Services

   docker-compose down

Production Docker Image

Build the production image:

   docker build -t nixernetes:latest .

Run the production image:

   docker run -p 8080:8080 \
     -e NODE_ENV=production \
     -e DB_PATH=/app/data/nixernetes.db \
     -v nixernetes-data:/app/data \
     nixernetes:latest

Docker Environment Variables

- PORT: Server port (default: 8080)
- NODE_ENV: development or production
- DB_PATH: Path to SQLite database file
- LOG_LEVEL: debug, info, warn, error

3. KUBERNETES DEPLOYMENT

Prerequisites

- Kubernetes 1.24+ cluster
- kubectl configured
- Container registry access

Create ConfigMap for Environment

   kubectl create configmap nixernetes-config \
     --from-literal=NODE_ENV=production \
     --from-literal=PORT=8080

Create Persistent Volume

   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: nixernetes-data
   spec:
     accessModes:
       - ReadWriteOnce
     resources:
       requests:
         storage: 10Gi

Deploy with Kubernetes Manifest

   apiVersion: apps/v1
   kind: Deployment
   metadata:
     name: nixernetes
   spec:
     replicas: 1
     selector:
       matchLabels:
         app: nixernetes
     template:
       metadata:
         labels:
           app: nixernetes
       spec:
         containers:
         - name: nixernetes
           image: nixernetes:latest
           ports:
           - containerPort: 8080
           envFrom:
           - configMapRef:
               name: nixernetes-config
           volumeMounts:
           - name: data
             mountPath: /app/data
           livenessProbe:
             httpGet:
               path: /health
               port: 8080
             initialDelaySeconds: 10
             periodSeconds: 30
           readinessProbe:
             httpGet:
               path: /health
               port: 8080
             initialDelaySeconds: 5
             periodSeconds: 10
         volumes:
         - name: data
           persistentVolumeClaim:
             claimName: nixernetes-data

Create Service

   apiVersion: v1
   kind: Service
   metadata:
     name: nixernetes
   spec:
     selector:
       app: nixernetes
     ports:
     - protocol: TCP
       port: 80
       targetPort: 8080
     type: LoadBalancer

Deploy to Kubernetes

   kubectl apply -f configmap.yaml
   kubectl apply -f pvc.yaml
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml

Verify Deployment

   # Check pods
   kubectl get pods -l app=nixernetes

   # View logs
   kubectl logs -f deployment/nixernetes

   # Get service IP
   kubectl get svc nixernetes

4. CONFIGURATION REFERENCE

Backend Configuration

Environment Variables:

- PORT: Server port (default: 8080)
- NODE_ENV: development or production
- DB_PATH: Path to SQLite database (default: ./nixernetes.db)
- CORS_ORIGIN: Allowed CORS origins (default: http://localhost:5173)
- LOG_LEVEL: Logging level (debug, info, warn, error)

Database Configuration

The backend automatically initializes the SQLite database with:

- projects table: Project metadata
- manifests table: Kubernetes manifests
- configurations table: K8s configurations
- modules table: Nix module references
- activity table: Audit trail

See backend/src/db/database.ts for schema details.

Frontend Configuration

Environment Variables:

- VITE_API_URL: Backend API URL (default: http://localhost:8080)
- VITE_APP_NAME: Application name
- VITE_ENVIRONMENT: Environment identifier

5. TROUBLESHOOTING

Database Errors

"database is locked"

This usually means two processes are writing to the database simultaneously.

Solution:
- Ensure only one backend server is running
- Delete *.db-shm and *.db-wal files to reset WAL state
- Check disk space and permissions

Module Loading Issues

Frontend shows "Failed to load resources"

Solution:
- Check backend is running: curl http://localhost:8080/health
- Verify CORS settings in backend
- Check browser console for specific errors
- Enable debug logging: NODE_ENV=development

Port Already in Use

"Address already in use" error

Solution:
- Find process using port: lsof -i :8080
- Change PORT environment variable
- Use different ports for dev and prod

6. PERFORMANCE TUNING

Database Optimization

Enable query logging to identify slow queries:

   NODE_ENV=development LOG_LEVEL=debug npm run dev

Add indexes for frequently queried fields in database.ts if needed.

Frontend Optimization

- Vite automatically optimizes during build
- Check bundle size: npm run build
- Enable gzip compression in production

Backend Optimization

- Use connection pooling for multiple database connections
- Implement caching for frequently accessed data
- Monitor memory usage: NODE_OPTIONS=--max-old-space-size=512

Example Production Configuration

backend/.env:

   PORT=8080
   NODE_ENV=production
   DB_PATH=/data/nixernetes.db
   CORS_ORIGIN=https://example.com
   LOG_LEVEL=warn

Health Checks

The backend exposes a health endpoint:

   GET /health
   Response: { "status": "ok" }

Use this for:
- Docker HEALTHCHECK
- Kubernetes livenessProbe
- Load balancer health checks

Scaling Considerations

Nixernetes is designed for single-instance deployment with SQLite.

For multi-instance deployments:

1. Replace SQLite with PostgreSQL
2. Implement shared session storage
3. Use file locking or distributed locking
4. Add load balancer in front
5. Set up database replication

Currently single-instance is sufficient for most use cases due to:
- Low write throughput (manifest updates)
- Efficient SQLite WAL mode
- Local filesystem performance

Monitoring and Logging

Enable structured logging for production:

   NODE_ENV=production \
   LOG_LEVEL=info \
   LOG_FORMAT=json \
   npm run start

Recommended monitoring tools:
- Prometheus for metrics
- ELK Stack for logs
- Jaeger for distributed tracing

See MONITORING.md for detailed setup.

Backup and Recovery

Database Backup

   # Backup SQLite database
   cp nixernetes.db nixernetes.db.backup

   # Automated daily backup
   0 2 * * * cp /app/data/nixernetes.db /backups/nixernetes.db.$(date +\%Y\%m\%d)

Disaster Recovery

1. Stop backend: docker-compose down or kubectl delete pod
2. Restore database: cp nixernetes.db.backup nixernetes.db
3. Start backend: docker-compose up or kubectl apply

For Kubernetes with persistent volumes:
- Snapshots are handled by storage class
- Restore via PVC snapshot mechanism

Additional Resources

- Development: DEVELOPMENT.md
- Architecture: ARCHITECTURE.md
- API Reference: API.md
- Manifest Validation: MANIFEST_VALIDATION.md
