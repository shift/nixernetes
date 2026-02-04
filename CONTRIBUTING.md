# Contributing to Nixernetes

Thank you for your interest in contributing to Nixernetes! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

We are committed to providing a welcoming and inspiring community for all. Please read and follow our Code of Conduct in all interactions.

### Our Standards

- Use welcoming and inclusive language
- Be respectful of differing opinions and experiences
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

## How to Contribute

### Reporting Bugs

Before creating a bug report, check the issue list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

- Use a clear and descriptive title
- Describe the exact steps which reproduce the problem
- Provide specific examples to demonstrate the steps
- Describe the behavior you observed after following the steps
- Explain which behavior you expected to see instead and why
- Include screenshots or animated GIFs if possible
- Include your environment details:
  - Operating System and version
  - Nix version
  - Kubernetes version
  - Nixernetes version

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- A clear and descriptive title
- A detailed description of the suggested enhancement
- Specific examples to demonstrate the steps or point out the part of Nixernetes which the suggestion is related to
- A description of the current behavior and the expected behavior
- Possible implementation details or design considerations

### Pull Requests

- Fill in the required template
- Follow the Nix style guide
- Include appropriate test cases
- Update documentation as needed
- End all files with a newline

## Development Setup

### Prerequisites

- Nix 2.15+ with flakes enabled
- direnv (optional but recommended)
- Kubernetes 1.28 - 1.31 (for testing against actual clusters)
- git

### Getting Started

```bash
# Clone the repository
git clone https://github.com/nixernetes/nixernetes.git
cd nixernetes

# Option 1: Use direnv (recommended)
direnv allow

# Option 2: Or manually enter Nix shell
nix develop

# You now have access to: nix, nixpkgs-fmt, yq, jq, python3
```

### Project Structure

```
nixernetes/
├── src/
│   ├── lib/                 # 35 production modules
│   │   ├── foundation/      # Foundation modules (4)
│   │   ├── core/            # Core Kubernetes modules (5)
│   │   ├── security/        # Security & Compliance modules (8)
│   │   ├── observability/   # Observability modules (6)
│   │   ├── data-events/     # Data & Events modules (4)
│   │   ├── workloads/       # Workloads modules (4)
│   │   └── operations/      # Operations modules (4)
│   └── examples/            # Example configurations
├── backend/                 # Node.js/Express backend API
├── web-ui/                  # React web interface
├── terraform-provider/      # Terraform provider
├── tests/                   # Test files
├── docs/                    # Public documentation (34 files)
├── .internal/               # Internal team materials (gitignored)
└── .summaries/              # Session notes (gitignored)
```

### Code Style

#### Nix Code

We follow the nixpkgs style guide. Use `nixpkgs-fmt` to format all Nix files:

```bash
# Format a single file
nixpkgs-fmt src/lib/schema.nix

# Format all Nix files
find src -name "*.nix" -exec nixpkgs-fmt {} \;

# Or use the git hook (if enabled)
git pre-commit run
```

#### TypeScript/JavaScript

The backend API and web UI follow these conventions:

- Use TypeScript for type safety
- Follow ESLint configuration in the project
- Use Prettier for code formatting
- Use camelCase for variables and functions
- Use PascalCase for classes and components

```bash
# Format TypeScript files
cd backend && npm run format
cd ../web-ui && npm run format
```

#### Documentation

- Use clear, professional language
- Include code examples where appropriate
- Update table of contents for large documents
- Link to related documentation
- Keep line lengths reasonable (80-100 characters)

### Testing

#### Running Tests

```bash
# Run all Nix checks
nix flake check

# Run backend tests
cd backend && npm test

# Run integration tests
nix flake check --option timeout 300

# Test specific module
nix flake check --check module-name
```

#### Writing Tests

For Nix modules, add tests to `tests/integration-tests.nix`:

```nix
# Example test
testExample = {
  description = "Example test description";
  assertion = mkAssert (
    myModule.mkFunction { arg = value; }
  ) expectedResult;
};
```

For backend API, add tests to `backend/src/server.test.ts` using Vitest.

### Building

#### Build Targets

```bash
# Build all targets
nix build

# Build specific target
nix build .#lib-schema
nix build .#example-app

# Run development server
cd backend && npm run dev
cd ../web-ui && npm run dev

# Build production bundles
nix build .#backend:production
nix build .#web-ui:production

# Build Docker image
docker build -t nixernetes:latest .
```

### Module Development

When adding a new module:

1. Create the module file in the appropriate category under `src/lib/`
2. Follow the established module structure:

```nix
{ lib }:

{
  # Module description
  mkMyFeature = { 
    name,
    config ? {},
    # ... other parameters
  }:
  
  # Module implementation
  {
    # Resource definitions or builders
  };
  
  # Helper functions
  helper1 = /* ... */;
  helper2 = /* ... */;
}
```

3. Add tests in `tests/integration-tests.nix`
4. Add documentation in `docs/` directory
5. Update `flake.nix` to include the new module
6. Update `MODULE_REFERENCE.md` with API documentation

### Documentation

When contributing code, also update the relevant documentation:

1. **API Changes**: Update `docs/API.md` and `MODULE_REFERENCE.md`
2. **New Features**: Add to `docs/FEATURES.md` or create a new guide
3. **Examples**: Add example configurations to `src/examples/`
4. **Guides**: Create or update relevant guides in `docs/`

### Commit Message Guidelines

We follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

#### Types

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (formatting, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **chore**: Changes to build process, dependencies, etc

#### Scope

The scope should specify what is being changed:
- `core`: Core framework changes
- `schema`: Schema validation module
- `compliance`: Compliance framework
- `security`: Security module
- `api`: Backend API
- `ui`: Web UI
- `terraform`: Terraform provider
- `docs`: Documentation

#### Subject

- Use the imperative mood ("add feature" not "added feature")
- Don't capitalize first letter
- No period (.) at the end
- Limit to 50 characters
- Reference issues and PRs liberally after the subject line

#### Body

- Explain what and why, not how
- Wrap at 72 characters
- Separate from subject with blank line

#### Examples

```
feat(schema): add kubernetes 1.31 schema support

Add OpenAPI schema for Kubernetes 1.31 with new API groups
and deprecation notices for removed APIs.

Closes #123
```

```
fix(compliance): enforce audit logging for restricted level

Audit logging was optional for restricted compliance level.
Now enforce it as required per compliance standards.

Fixes #456
```

## Release Process

### Version Numbering

We follow [Semantic Versioning](https://semver.org/):

- **MAJOR** (X.0.0): Breaking changes
- **MINOR** (0.Y.0): New features (backward compatible)
- **PATCH** (0.0.Z): Bug fixes (backward compatible)

### Release Checklist

See `.internal/docs/RELEASE_CHECKLIST.md` for the complete release process.

Key steps:
1. Run full test suite (`nix flake check`)
2. Update `CHANGELOG.md`
3. Update version in `flake.nix`
4. Create release tag: `git tag -a v1.0.0 -m "Release v1.0.0"`
5. Create GitHub Release with release notes

## Community

### Communication Channels

- **GitHub Issues**: Report bugs and request features
- **GitHub Discussions**: Ask questions and share ideas
- **GitHub PR Comments**: Discuss code changes
- **Email**: For sensitive security issues, email security@nixernetes.dev

### Getting Help

- Check existing issues and discussions
- Review documentation in `docs/`
- Look at examples in `src/examples/`
- Open a discussion if your question is not covered

## Recognition

Contributors will be recognized in:
- Release notes
- `CONTRIBUTORS.md` file (if applicable)
- Project README

## Legal

By contributing to Nixernetes, you agree that your contributions will be licensed under the same MIT License that covers the project.

## Questions?

Feel free to open an issue labeled "question" or start a discussion on GitHub.

Thank you for contributing to Nixernetes!
