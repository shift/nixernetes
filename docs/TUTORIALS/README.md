# Nixernetes Interactive Tutorials

Welcome to the Nixernetes tutorial series! These step-by-step guides will teach you how to deploy Kubernetes applications using Nixernetes.

## Tutorial Path

Follow these tutorials in order to progressively build your Nixernetes skills:

### Tutorial 1: Deploy Your First Web Application
**Duration:** 30-45 minutes  
**Difficulty:** Beginner  
**Learn:** Basic deployment, services, ingress

[👉 Tutorial 1: First Deployment](TUTORIAL_1_FIRST_DEPLOYMENT.md)

In this tutorial, you'll:
- Create a simple Nixernetes configuration
- Deploy an Nginx web server
- Expose it with a Service and Ingress
- Verify the deployment is working
- Scale the application

**Prerequisites:** None (apart from Nixernetes setup)

**Skills gained:**
- Basic Nixernetes configuration syntax
- Kubernetes resource basics
- Deployment and service management
- Ingress routing

---

### Tutorial 2: Database + API Deployment
**Duration:** 45-60 minutes  
**Difficulty:** Intermediate  
**Learn:** Stateful sets, persistent volumes, secrets, service discovery

[👉 Tutorial 2: Database + API](TUTORIAL_2_DATABASE_API.md)

In this tutorial, you'll:
- Deploy PostgreSQL with persistent storage
- Deploy a Node.js API backend
- Configure database credentials as secrets
- Enable service-to-service communication
- Verify data persistence
- Add network policies for security

**Prerequisites:** Complete Tutorial 1

**Skills gained:**
- StatefulSet deployments
- Persistent storage management
- Secret management
- Service discovery between pods
- Network policies
- Data validation

---

### Tutorial 3: Complete Microservices Stack
**Duration:** 90-120 minutes  
**Difficulty:** Advanced  
**Learn:** Multi-tier architecture, caching, messaging, monitoring

[👉 Tutorial 3: Microservices Stack](TUTORIAL_3_MICROSERVICES.md)

In this tutorial, you'll build a production-grade platform with:
- PostgreSQL database (with automated backups)
- Redis caching layer
- RabbitMQ message queue
- Node.js API backend
- Nginx frontend
- Prometheus monitoring
- Grafana dashboards
- Comprehensive network policies
- RBAC with least privilege

**Prerequisites:** Complete Tutorial 2

**Skills gained:**
- Complex multi-service deployments
- ConfigMaps and configuration management
- StatefulSet and Deployment patterns
- Observability stack setup
- Network policy composition
- RBAC configuration
- Production deployment patterns

---

## Learning Path Overview

```
Tutorial 1 (Web App)
    ↓
    Learn: Deployments, Services, Ingress
    Skills: Basic Kubernetes, Nixernetes syntax
    
Tutorial 2 (Database + API)
    ↓
    Learn: Persistence, Secrets, Service Discovery
    Skills: Stateful applications, Security
    
Tutorial 3 (Microservices)
    ↓
    Learn: Complex architectures, Monitoring, Production
    Skills: Enterprise deployments, Observability
```

## Quick Start

**Already familiar with Kubernetes?**

Jump directly to the tutorial that matches your use case:
- Simple web app → [Tutorial 1](TUTORIAL_1_FIRST_DEPLOYMENT.md)
- App + database → [Tutorial 2](TUTORIAL_2_DATABASE_API.md)
- Complex platform → [Tutorial 3](TUTORIAL_3_MICROSERVICES.md)

**Need specific topics?**

Search the tutorial docs for:
- **Deployments** - Tutorials 1, 2, 3
- **Stateful sets** - Tutorials 2, 3
- **Persistent storage** - Tutorials 2, 3
- **Services & networking** - Tutorials 1, 2, 3
- **Ingress** - Tutorials 1, 3
- **Secrets & ConfigMaps** - Tutorials 2, 3
- **Network policies** - Tutorials 2, 3
- **Monitoring** - Tutorial 3
- **RBAC** - Tutorial 3

## Tutorial Features

Each tutorial includes:

✅ **Step-by-step instructions** - Clear numbered steps  
✅ **Code examples** - Complete, ready-to-use Nix configurations  
✅ **Verification steps** - How to confirm everything is working  
✅ **Troubleshooting** - Common issues and solutions  
✅ **Next steps** - Where to go after completing  
✅ **Related resources** - Links to relevant guides and documentation  

## Common Patterns

Across all tutorials, you'll learn:

| Pattern | Tutorial | Purpose |
|---------|----------|---------|
| Simple deployment | 1 | Stateless services |
| Database deployment | 2, 3 | Persistent data |
| Multi-tier app | 2, 3 | Multiple services |
| Service discovery | 2, 3 | Pod-to-pod communication |
| Configuration | 2, 3 | ConfigMaps & Secrets |
| Network policies | 2, 3 | Network security |
| Monitoring | 3 | Observability |
| RBAC | 3 | Access control |

## Prerequisites Checklist

Before starting the tutorials, ensure you have:

- [ ] Nixernetes installed (see [GETTING_STARTED.md](../GETTING_STARTED.md))
- [ ] A Kubernetes cluster available:
  - [ ] Local (minikube, kind, or Docker Desktop)
  - [ ] Or cloud cluster (AWS EKS, GCP GKE, Azure AKS)
- [ ] kubectl configured and working
- [ ] Basic understanding of:
  - [ ] Kubernetes concepts (pods, services, deployments)
  - [ ] Nix syntax (basic, will be explained)
  - [ ] Docker/container concepts (basic)
  - [ ] Linux command line (basic)

## Getting Help

While working through the tutorials:

1. **For Kubernetes questions** → See [Module Reference](../MODULE_REFERENCE.md)
2. **For Nix syntax questions** → See [GETTING_STARTED.md](../GETTING_STARTED.md)
3. **For module-specific help** → See module documentation in `docs/`
4. **For deployment issues** → See cloud guides:
   - [AWS EKS](../DEPLOY_AWS_EKS.md)
   - [GCP GKE](../DEPLOY_GCP_GKE.md)
   - [Azure AKS](../DEPLOY_AZURE_AKS.md)
5. **For debugging** → See [CLI Reference](../CLI_REFERENCE.md)

## After the Tutorials

Once you've completed the tutorials, you're ready to:

- **Understand Nixernetes architecture** → Read [ARCHITECTURE.md](../ARCHITECTURE.md)
- **Explore advanced modules** → See [MODULE_REFERENCE.md](../MODULE_REFERENCE.md)
- **Deploy to production** → See cloud deployment guides
- **Optimize performance** → See [PERFORMANCE_TUNING.md](../PERFORMANCE_TUNING.md)
- **Secure your deployment** → See [SECURITY_HARDENING.md](../SECURITY_HARDENING.md)
- **Contribute to Nixernetes** → See [CONTRIBUTING.md](../CONTRIBUTING.md)

## Feedback & Issues

Have feedback on the tutorials?

- **Report issues:** Use GitHub Issues (see [CONTRIBUTING.md](../CONTRIBUTING.md))
- **Suggest improvements:** Open a discussion on GitHub
- **Share your success:** Tell us how the tutorials helped!

---

**Happy learning! 🚀**

Start with [Tutorial 1: Deploy Your First Web Application](TUTORIAL_1_FIRST_DEPLOYMENT.md)
