# Security Policy

## Supported Versions

Use this section to tell people about which versions of Nixernetes are currently being supported with security updates.

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Reporting a Vulnerability

**Please do not report security vulnerabilities through public GitHub issues.**

Instead, please send an email to the project maintainers. When reporting a vulnerability, please include:

- A description of the vulnerability
- Steps to reproduce the vulnerability
- Potential impact of the vulnerability
- Any suggested fixes (if known)

We will acknowledge receipt of your report within 48 hours and provide regular updates on our progress.

### Security Contact

- Email: security@nixernetes.dev
- GPG Key: [Available on request]

## Security Best Practices

This project follows security best practices including:

- Zero-trust networking with default-deny policies
- Least-privilege RBAC configurations
- Pod Security Standards enforcement
- Compliance enforcement across all compliance levels
- Image scanning integration
- Secrets management through ExternalSecrets

### For Users

When using Nixernetes in production:

1. **Never commit secrets to version control**
   - Use ExternalSecrets or your cloud provider's secret management
   - Keep sensitive data in external secret stores (Vault, AWS Secrets Manager, etc.)

2. **Use appropriate compliance levels**
   - Development: `low` or `unrestricted`
   - Production: `medium` or `high`
   - Regulated environments: `restricted`

3. **Keep dependencies updated**
   - Regularly update Nix packages with `nix flake update`
   - Update backend dependencies with `npm update`
   - Monitor security advisories for dependencies

4. **Review generated manifests**
   - Always review generated Kubernetes manifests before deployment
   - Use `nixernetes validate` before deploying
   - Test in staging environments first

5. **Enable network policies**
   - Nixernetes generates zero-trust policies automatically
   - Ensure default-deny policies are in place
   - Review dependency-based egress rules

## Security Features

Nixernetes includes the following security features:

### Compliance Levels

Five compliance levels from Unrestricted to Restricted, each with increasing security requirements:
- **Unrestricted**: Basic RBAC, no additional requirements
- **Low**: Audit logging, basic RBAC
- **Medium**: Audit logging, encryption, RBAC enforced, NetworkPolicy required
- **High**: All medium requirements + mutual TLS, strict pod security, enhanced isolation
- **Restricted**: All high requirements + binary authorization, image scanning, audit ID tracking

### RBAC Generation

Automatic generation of ServiceAccounts, Roles, and RoleBindings with least-privilege access:
- Pre-built roles for common patterns
- Custom permission support
- Namespace-scoped access control

### Network Policies

Zero-trust networking with:
- Default-deny policies
- Dependency-based egress rules
- Ingress control on exposed ports
- DNS and kube-dns access

### Security Scanning

Integration with:
- Image vulnerability scanners
- Container image signing
- Binary authorization
- Admission controllers

## Vulnerability Disclosure Process

1. **Report**: Send vulnerability details to security@nixernetes.dev
2. **Acknowledge**: We will acknowledge within 48 hours
3. **Investigate**: We will investigate and verify the vulnerability
4. **Fix**: We will develop a fix following responsible disclosure
5. **Coordinate**: We will coordinate disclosure timing with you
6. **Disclose**: We will publicly disclose the vulnerability after the fix is released

## Security Updates

Security updates will be released as patch versions (x.x.x). Users are encouraged to:

1. Subscribe to security advisories on GitHub
2. Keep dependencies up to date
3. Monitor the CHANGELOG for security-related updates
4. Upgrade promptly when security releases are published

## Security-Related Configuration

Example secure configuration:

```nix
{
  applications.myApp = {
    name = "myapp";
    image = "myapp:1.0";
    
    compliance = {
      framework = "SOC2";
      level = "high";
      owner = "platform-team";
    };
    
    # Use ExternalSecrets for sensitive data
    secrets = {
      databasePassword = externalSecrets.mkExternalSecret {
        name = "db-password";
        secretStore = "vault";
        remoteRef = { key = "secret/data/db/password"; };
      };
    };
  };
}
```

## Additional Resources

- [Security Hardening Guide](docs/SECURITY_HARDENING.md)
- [Compliance Framework](docs/SECURITY_POLICIES.md)
- [Contributing Security Guidelines](CONTRIBUTING.md#security-considerations)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
