# Tutorial 1: Deploy Your First Web Application

This step-by-step tutorial walks you through deploying a simple web application using Nixernetes.

## What You'll Learn

- Creating a basic Nixernetes configuration
- Deploying a web application with Nginx
- Exposing your application to the internet
- Validating and generating Kubernetes manifests
- Deploying to a real Kubernetes cluster

## Prerequisites

- Nixernetes installed and configured (see [GETTING_STARTED.md](../GETTING_STARTED.md))
- A Kubernetes cluster (local kind/minikube or cloud EKS/GKE/AKS)
- kubectl configured to access your cluster
- Basic understanding of Kubernetes concepts

## Step 1: Create Your Project

```bash
# Initialize a new Nixernetes project
./bin/nixernetes init my-web-app
cd my-web-app

# Verify the project structure
ls -la
cat flake.nix
```

The generated project includes:
- `flake.nix` - Project definition with devShell
- `deployments.nix` - Your application configuration
- A README with quick-start commands

## Step 2: Define Your Web Application

Create a file named `web-app.nix`:

```nix
# Import Nixernetes
{ pkgs, nixernetes }:

let
  # Import core modules
  modules = nixernetes.modules;
  
in {
  # Define your web application deployment
  deployment = {
    name = "nginx-app";
    namespace = "default";
    
    # Use the Deployments module to create a deployment
    spec = modules.deployments.mkSimpleDeployment {
      name = "nginx";
      image = "nginx:1.25";
      replicas = 2;
      
      # Configure resource limits
      resources = {
        requests = {
          memory = "64Mi";
          cpu = "100m";
        };
        limits = {
          memory = "128Mi";
          cpu = "200m";
        };
      };
      
      # Port configuration
      ports = [{
        containerPort = 80;
        name = "http";
      }];
      
      # Liveness probe - restart if unhealthy
      livenessProbe = {
        httpGet = {
          path = "/";
          port = 80;
        };
        initialDelaySeconds = 10;
        periodSeconds = 10;
      };
      
      # Readiness probe - mark ready for traffic
      readinessProbe = {
        httpGet = {
          path = "/";
          port = 80;
        };
        initialDelaySeconds = 5;
        periodSeconds = 5;
      };
    };
    
    # Create a Service to expose the deployment
    service = modules.services.mkSimpleService {
      name = "nginx";
      selector = { app = "nginx"; };
      ports = [{
        port = 80;
        targetPort = 80;
        protocol = "TCP";
      }];
      type = "ClusterIP";
    };
    
    # Create an Ingress to expose publicly
    ingress = modules.ingress.mkSimpleIngress {
      name = "nginx";
      hosts = [{
        host = "myapp.example.com";
        paths = [{
          path = "/";
          pathType = "Prefix";
          backend = {
            service = {
              name = "nginx";
              port = { number = 80; };
            };
          };
        }];
      }];
    };
  };
}
```

## Step 3: Validate Your Configuration

Before deploying, validate that your configuration is correct:

```bash
# Validate syntax and structure
./bin/nixernetes validate web-app.nix

# Output should show:
# ✓ Configuration is valid
# ✓ All required fields present
# ✓ Type checking passed
```

## Step 4: Generate Kubernetes Manifests

Convert your Nix configuration to Kubernetes YAML:

```bash
# Generate YAML manifests
./bin/nixernetes generate web-app.nix > manifests.yaml

# View the generated YAML
cat manifests.yaml

# You'll see:
# - Deployment with 2 replicas
# - Service exposing port 80
# - Ingress for external access
```

## Step 5: Review Generated Manifests

The generated manifests include:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
spec:
  replicas: 2
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            memory: 64Mi
            cpu: 100m
          limits:
            memory: 128Mi
            cpu: 200m
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
```

## Step 6: Dry-Run Deployment

Test the deployment without actually applying it:

```bash
# Dry-run the deployment
./bin/nixernetes deploy --dry-run web-app.nix

# Or with kubectl
kubectl apply -f manifests.yaml --dry-run=client

# Output shows what would be created:
# deployment.apps/nginx created (dry run)
# service/nginx created (dry run)
# ingress.networking.k8s.io/nginx created (dry run)
```

## Step 7: Deploy to Your Cluster

Deploy the application to your Kubernetes cluster:

```bash
# Deploy the application
./bin/nixernetes deploy web-app.nix

# Or manually with kubectl
kubectl apply -f manifests.yaml

# Output:
# deployment.apps/nginx created
# service/nginx created
# ingress.networking.k8s.io/nginx created
```

## Step 8: Verify Deployment

Check that your application is running:

```bash
# Watch pod creation
kubectl get pods -w

# Wait for pods to be Ready
kubectl get pods -o wide

# Output should show:
# NAME                    READY   STATUS    RESTARTS   AGE
# nginx-xxxxx             1/1     Running   0          10s
# nginx-yyyyy             1/1     Running   0          10s

# Check the service
kubectl get svc
# Output:
# NAME         TYPE        CLUSTER-IP     PORT(S)   AGE
# nginx        ClusterIP   10.96.140.1    80/TCP    10s

# Check the ingress
kubectl get ingress
# Output:
# NAME    CLASS   HOSTS                 ADDRESS       PORTS   AGE
# nginx   nginx   myapp.example.com     192.168.1.1   80      10s
```

## Step 9: Access Your Application

Access your deployed application:

```bash
# Option 1: Port-forward through kubectl
kubectl port-forward svc/nginx 8080:80
# Then visit http://localhost:8080

# Option 2: Use the Ingress (requires Ingress controller)
# Visit http://myapp.example.com (after DNS is configured)

# Option 3: Inside the cluster
kubectl exec -it <pod-name> -- curl localhost
```

## Step 10: View Logs

Monitor your application logs:

```bash
# View logs from a specific pod
kubectl logs nginx-xxxxx

# Follow logs in real-time
kubectl logs -f nginx-xxxxx

# View logs from all pods in the deployment
kubectl logs -l app=nginx

# View logs of the last container restart
kubectl logs --previous nginx-xxxxx
```

## Step 11: Scale Your Application

Increase the number of replicas:

```nix
# Update web-app.nix: change replicas to 5
replicas = 5;

# Validate and redeploy
./bin/nixernetes validate web-app.nix
./bin/nixernetes deploy web-app.nix

# Watch the new pods start
kubectl get pods -w
```

## Step 12: Update Your Application

Deploy a new version:

```nix
# Update web-app.nix: change the image tag
image = "nginx:1.26";

# Validate and redeploy
./bin/nixernetes deploy web-app.nix

# Watch the rolling update
kubectl rollout status deployment/nginx
kubectl get pods -o wide
```

## Next Steps

Congratulations! You've successfully:
- Created a Nixernetes configuration
- Generated Kubernetes manifests
- Deployed to a cluster
- Scaled and updated your application

### Learn More

- **[Tutorial 2: Database + API Deployment](TUTORIAL_2_DATABASE_API.md)** - Add a database backend
- **[Tutorial 3: Complete Microservices Stack](TUTORIAL_3_MICROSERVICES.md)** - Multi-tier application
- **[Module Reference](../MODULE_REFERENCE.md)** - Explore all available modules
- **[Performance Tuning](../PERFORMANCE_TUNING.md)** - Optimize your deployments
- **[Security Hardening](../SECURITY_HARDENING.md)** - Secure your application

## Troubleshooting

### Pods not starting?
```bash
# Check pod events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check resource availability
kubectl top nodes
kubectl top pods
```

### Ingress not working?
```bash
# Verify Ingress controller is installed
kubectl get daemonset -n ingress-nginx

# Check Ingress status
kubectl describe ingress nginx

# Verify DNS is configured
nslookup myapp.example.com
```

### Image pull errors?
```bash
# Verify image exists
docker pull nginx:1.25

# Check image pull policy
kubectl describe pod <pod-name>

# Use pre-pulled images if in private network
```

## Summary

You now understand:
- How to create Nixernetes configurations
- How to validate and generate manifests
- How to deploy to Kubernetes
- How to monitor and update applications

The next tutorials build on these skills to create more complex deployments!
