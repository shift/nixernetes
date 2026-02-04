# Nixernetes Starter Kit: Static Site

Perfect for deploying static websites (documentation, blogs, etc.) with Nixernetes.

## What's Included

- Nginx web server optimized for static content
- Minimal resource usage
- CDN-ready configuration
- HTTPS support (with cert-manager)
- Caching headers and compression

## Quick Start

1. Copy this directory:
   ```bash
   cp -r starters/static-site your-site
   cd your-site
   ```

2. Update site content in `html/` directory:
   ```bash
   cp -r /path/to/your/html/* html/
   ```

3. Deploy:
   ```bash
   nix build
   kubectl apply -f result/manifest.yaml
   ```

## File Structure

```
static-site/
├── flake.nix       # Nix configuration
├── config.nix      # Nixernetes config
├── nginx.conf      # Nginx settings
├── html/           # Your website files
│   ├── index.html
│   ├── css/
│   ├── js/
│   └── images/
└── README.md
```

## Configuration

### Enable HTTPS

Update `config.nix`:

```nix
ingress = {
  enabled = true;
  hosts = ["mysite.com" "www.mysite.com"];
  tls.enabled = true;
  tls.issuer = "letsencrypt-prod";
};
```

### Custom Domain

```nix
ingress.hosts = ["yourdomain.com"];
```

### Caching

Nginx automatically caches static assets. Configure expiry in `nginx.conf`:

```nginx
# Cache images for 30 days
location ~* \.(jpg|jpeg|png|gif|ico|css|js)$ {
  expires 30d;
  add_header Cache-Control "public, immutable";
}

# Don't cache HTML
location ~* \.html$ {
  expires 1h;
  add_header Cache-Control "public, max-age=3600";
}
```

## Deployment

### Local Testing

```bash
kubectl port-forward svc/static-site 8080:80
curl http://localhost:8080
```

### Production

```bash
# Create namespace
kubectl create namespace production

# Deploy
kubectl -n production apply -f result/manifest.yaml

# Verify
kubectl -n production get svc
```

## Monitoring

Check logs:
```bash
kubectl logs -f deployment/static-site
```

Monitor traffic:
```bash
kubectl top pods -l app=static-site
```

## Updating Content

To update your site:

1. Update files in `html/`
2. Rebuild and deploy:
   ```bash
   nix build
   kubectl apply -f result/manifest.yaml
   ```

## With CI/CD

Automate deployment with GitHub Actions:

```yaml
name: Deploy Site
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: nix build
      - run: kubectl apply -f result/manifest.yaml
```

## Performance Tips

1. **Minimize assets** - Use tools like imagemin, cssnano
2. **Compress** - Nginx gzip compression is enabled
3. **Cache assets** - Set proper Cache-Control headers
4. **Use CDN** - Put CloudFlare in front for global distribution
5. **Monitor** - Check Core Web Vitals

## Support

- Questions? Check the [Troubleshooting Discussion](https://github.com/anomalyco/nixernetes/discussions/categories/help-wanted)
- Found an issue? [Report it](https://github.com/anomalyco/nixernetes/issues/new?template=bug_report.yml)
