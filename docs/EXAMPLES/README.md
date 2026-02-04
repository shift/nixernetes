# Real-World Example Projects

This directory contains complete, production-ready example projects using Nixernetes.

## Available Examples

### 1. Static Website Hosting
**Difficulty:** Beginner  
**Components:** Nginx, CloudFront (AWS), Ingress  
**Use Cases:** Documentation sites, blogs, portfolios

[👉 Static Website Example](example-1-static-website.md)

### 2. Django + PostgreSQL Application
**Difficulty:** Intermediate  
**Components:** Django, PostgreSQL, Redis, Nginx  
**Use Cases:** Web applications, content management, e-commerce

[👉 Django Application Example](example-2-django-app.md)

### 3. Node.js Microservices
**Difficulty:** Intermediate  
**Components:** Node.js, PostgreSQL, RabbitMQ, Redis  
**Use Cases:** RESTful APIs, real-time applications, event-driven systems

[👉 Node.js Microservices Example](example-3-nodejs-microservices.md)

### 4. Machine Learning Pipeline
**Difficulty:** Advanced  
**Components:** Jupyter, TensorFlow, PostgreSQL, MinIO  
**Use Cases:** Model training, batch processing, data science workflows

[👉 ML Pipeline Example](example-4-ml-pipeline.md)

### 5. Real-Time Chat Application
**Difficulty:** Advanced  
**Components:** React, Node.js, WebSocket, PostgreSQL, Redis  
**Use Cases:** Chat applications, collaboration tools, live dashboards

[👉 Real-Time Chat Example](example-5-realtime-chat.md)

### 6. IoT Data Pipeline
**Difficulty:** Advanced  
**Components:** MQTT Broker, PostgreSQL, Grafana, Kafka  
**Use Cases:** IoT applications, sensor data, time-series data

[👉 IoT Data Pipeline Example](example-6-iot-pipeline.md)

## Quick Start

Each example includes:

✅ **Complete Nix configuration** - Ready to deploy  
✅ **Step-by-step instructions** - From zero to deployed  
✅ **Troubleshooting guide** - Common issues and solutions  
✅ **Production considerations** - Security, scaling, monitoring  
✅ **Customization guide** - How to adapt for your needs  

## Running Examples

```bash
# Clone the example
git clone https://github.com/nixernetes/nixernetes.git
cd nixernetes

# Navigate to example directory
cd docs/EXAMPLES

# Read the example
cat example-1-static-website.md

# Deploy (after reviewing)
./bin/nixernetes init my-project
# Copy configuration from example
nix develop
./bin/nixernetes deploy
```

## Example Categories

### Frontend Examples
- Static Website Hosting
- Real-Time Chat Application

### Backend Examples
- Django + PostgreSQL
- Node.js Microservices

### Data Examples
- Machine Learning Pipeline
- IoT Data Pipeline

## Choosing an Example

**Just starting?**
→ Begin with [Static Website](example-1-static-website.md)

**Building a web application?**
→ See [Django App](example-2-django-app.md) or [Node.js Microservices](example-3-nodejs-microservices.md)

**Working with data?**
→ See [ML Pipeline](example-4-ml-pipeline.md) or [IoT Pipeline](example-6-iot-pipeline.md)

**Building a real-time app?**
→ See [Real-Time Chat](example-5-realtime-chat.md)

## Contributing Examples

Have a great example project? We'd love to include it!

1. Fork the repository
2. Create your example in `docs/EXAMPLES/`
3. Follow the template: configuration + guide + troubleshooting
4. Submit a pull request

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for details.

## Learning Path

```
Beginner: Static Website
    ↓
Intermediate: Django or Node.js
    ↓
Advanced: ML Pipeline or IoT or Real-Time Chat
```

## Tips for Success

1. **Start simple** - Begin with the Static Website example
2. **Understand each component** - Read module documentation
3. **Test locally first** - Use minikube or kind
4. **Monitor your deployment** - Check logs and metrics
5. **Iterate and improve** - Add monitoring, scaling, etc.

## Support

Need help with an example?

- Check the **Troubleshooting** section in each example
- Read the [Module Reference](../../MODULE_REFERENCE.md)
- See the [Cloud Deployment Guides](../../docs/)
- Report issues on GitHub

---

**Ready to deploy?** Start with the [Static Website](example-1-static-website.md) example!
