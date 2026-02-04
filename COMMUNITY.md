# Contributing to Nixernetes

Thank you for your interest in contributing to Nixernetes! This document outlines how you can help make Nixernetes better.

## Ways to Contribute

### Report Bugs
- Check if the bug has already been reported in [GitHub Issues](https://github.com/anomalyco/nixernetes/issues)
- Use the [Bug Report](https://github.com/anomalyco/nixernetes/issues/new?template=bug_report.yml) template
- Include environment details (OS, Nix version, Kubernetes version)
- Provide error messages and relevant logs

### Suggest Features
- Check existing [Feature Requests](https://github.com/anomalyco/nixernetes/discussions/categories/ideas)
- Use the [Feature Request](https://github.com/anomalyco/nixernetes/issues/new?template=feature_request.yml) issue template
- Describe the problem your feature solves
- Provide example use cases

### Improve Documentation
- Fix typos and unclear explanations
- Add examples and tutorials
- Improve API documentation
- Create deployment guides
- Use the [Documentation](https://github.com/anomalyco/nixernetes/issues/new?template=documentation.yml) issue template

### Share Projects & Use Cases
- Show what you've built with Nixernetes
- Share deployment patterns and best practices
- Post in [Show & Tell](https://github.com/anomalyco/nixernetes/discussions/categories/show-and-tell) discussions

### Ask for Help
- Check the [Getting Started Guide](docs/GETTING_STARTED.md) first
- Review the [Module Reference](MODULE_REFERENCE.md)
- Use [Troubleshooting](https://github.com/anomalyco/nixernetes/discussions/categories/help-wanted) discussions

## Development Setup

### Prerequisites
- NixOS or Nix (Linux/macOS)
- Git
- Basic familiarity with Nix and Kubernetes

### Getting Started
1. Clone the repository:
   ```bash
   git clone https://github.com/anomalyco/nixernetes.git
   cd nixernetes
   ```

2. Enter the development shell:
   ```bash
   nix develop
   ```
   Or with direnv:
   ```bash
   echo "use flake" > .envrc
   direnv allow
   ```

3. Verify setup:
   ```bash
   nix flake check --offline
   python3 bin/nixernetes --help
   ```

## Contribution Workflow

### 1. Create a Feature Branch
```bash
git checkout -b feature/your-feature-name
# or for bug fixes
git checkout -b fix/your-bug-fix
```

### 2. Make Your Changes
- Write clean, well-documented code
- Follow the existing code style
- Add tests for new functionality
- Update documentation as needed

### 3. Test Your Changes
```bash
# Run all checks
nix flake check --offline

# Run specific tests
nix develop -c -- python3 -m pytest tests/test_your_feature.py

# Test the CLI
python3 bin/nixernetes --help
```

### 4. Commit Your Changes
```bash
git add .
git commit -m "feat: Add new feature" # or "fix:", "docs:", etc.
```

Follow conventional commits:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation
- `refactor:` for code refactoring
- `test:` for test changes
- `chore:` for maintenance

### 5. Push and Create a Pull Request
```bash
git push origin feature/your-feature-name
```

Create a PR using the [Pull Request Template](PULL_REQUEST_TEMPLATE.md).

## Code Style Guide

### Nix
- Use 2-space indentation
- Use descriptive variable names
- Add comments for complex logic
- Follow the module pattern in existing code

### Python
- Follow PEP 8
- Use type hints where possible
- Write docstrings for functions
- Use meaningful variable names

### Documentation
- Use clear, accessible language
- Include code examples
- Add diagrams where helpful
- Keep README files up to date

## Commit Message Guidelines

Good commit messages help maintain project history and make it easier to understand changes.

### Format
```
<type>(<scope>): <subject>

<body>

<footer>
```

### Examples
```
feat(cli): Add template command for web deployments

Implement new 'nixernetes template' command with 6 predefined
configurations for common deployment patterns.

Fixes #123
```

```
fix(validation): Handle null values in YAML validation

Prevents crash when validating configurations with null fields.

Closes #456
```

## Review Process

1. **Automated Checks**: All PRs must pass automated tests and checks
2. **Code Review**: A maintainer will review your code for:
   - Correctness and quality
   - Documentation completeness
   - Test coverage
   - Adherence to guidelines
3. **Approval**: PRs require at least one approval before merging
4. **Merge**: Squash and merge commits are preferred for clean history

## Reporting Security Issues

Please do not create public GitHub issues for security vulnerabilities. Instead, email security@anomalyco.com with:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Suggested fix (if available)

We'll acknowledge receipt within 48 hours and work on a fix.

## Community Guidelines

See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) for our community standards and expectations.

## Getting Help

- **Documentation**: [docs/](docs/) directory
- **Examples**: [docs/EXAMPLES/](docs/EXAMPLES/) for real-world use cases
- **Discussions**: [GitHub Discussions](https://github.com/anomalyco/nixernetes/discussions)
- **Issues**: [GitHub Issues](https://github.com/anomalyco/nixernetes/issues)

## Maintainers

The Nixernetes project is maintained by the Anomaly team. For questions about maintainership or governance, contact maintainers@anomalyco.com.

## License

By contributing to Nixernetes, you agree that your contributions will be licensed under the same license as the project (MIT License).

---

Thank you for making Nixernetes better! Your contributions are valued and appreciated.
