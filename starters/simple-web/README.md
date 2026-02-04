# Nixernetes Starter Kit: Simple Web Application

This starter kit provides a minimal setup for deploying a simple web application with Nixernetes.

## What's Included

- Single Nginx web server
- PostgreSQL database
- Redis cache
- Health checks and resource limits
- Example configuration

## Quick Start

1. Copy this directory to your project:
   ```bash
   cp -r starters/simple-web your-app
   cd your-app
   ```

2. Update `flake.nix` with your application details:
   ```nix
   # Change the project name
   nixernetes.config.name = "my-app";
   ```

3. Customize `config.nix`:
   ```nix
   # Update image references, ports, etc.
   ```

4. Deploy to Kubernetes:
   ```bash
   nix flake check --offline  # Verify configuration
   nix build  # Generate Kubernetes manifests
   kubectl apply -f result/manifest.yaml
   ```

## File Structure

```
simple-web/
├── flake.nix          # Nix flake definition
├── config.nix         # Nixernetes configuration
├── nginx.conf         # Nginx configuration (optional)
└── README.md          # This file
```

## Configuration

### Environment Variables

Edit `config.nix` to set environment variables:

```nix
environment = {
  NODE_ENV = "production";
  LOG_LEVEL = "info";
};
```

### Secrets

For sensitive data (passwords, API keys), use Kubernetes secrets:

```bash
kubectl create secret generic app-secrets \
  --from-literal=DB_PASSWORD=your-password
```

Then reference in your config:

```nix
env = [
  {
    name = "DB_PASSWORD";
    valueFrom = {
      secretKeyRef = {
        name = "app-secrets";
        key = "DB_PASSWORD";
      };
    };
  }
];
```

## Scaling

To scale your application, update the `replicas` field in `config.nix`:

```nix
replicas = 3;  # Run 3 instances
```

## Monitoring

Access logs:
```bash
kubectl logs deployment/my-app
```

Check resource usage:
```bash
kubectl top pods -l app=my-app
```

## Troubleshooting

### Pod won't start
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

### Can't reach application
```bash
# Check service
kubectl get svc

# Port forward for testing
kubectl port-forward svc/my-app 8080:80
curl http://localhost:8080
```

## Next Steps

- Review the [Getting Started Guide](../../GETTING_STARTED.md)
- Check [Module Reference](../../MODULE_REFERENCE.md) for all available options
- Explore [Real-World Examples](../../docs/EXAMPLES/) for more complex setups
- Read [CONTRIBUTING.md](../../CONTRIBUTING.md) if you want to extend this kit

## Support

- Questions? Check the [Troubleshooting Discussion](https://github.com/anomalyco/nixernetes/discussions/categories/help-wanted)
- Found an issue? [Report it](https://github.com/anomalyco/nixernetes/issues/new?template=bug_report.yml)
