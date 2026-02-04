# CONTRIBUTING.md

# Contributing to Nixernetes

Thank you for your interest in contributing to Nixernetes! This document provides guidelines and instructions for contributing.

## Code of Conduct

- Be respectful and inclusive
- Provide constructive feedback
- Focus on ideas, not individuals
- Help others learn and grow

## Getting Started

### 1. Fork and Clone

```bash
git clone https://github.com/yourusername/nixernetes.git
cd nixernetes
direnv allow
```

### 2. Create a Branch

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/your-bug-fix
# or
git checkout -b docs/your-documentation
```

Branch naming conventions:
- `feature/*` - New features
- `fix/*` - Bug fixes
- `docs/*` - Documentation
- `refactor/*` - Code refactoring
- `test/*` - Tests
- `ci/*` - CI/CD improvements

### 3. Make Changes

- Write clean, readable code
- Follow existing code style
- Add tests for new functionality
- Update documentation

### 4. Validate Your Changes

```bash
# Run validations
nix flake check --offline

# Run tests
nix flake check

# Format code
nixpkgs-fmt src/

# Verify examples work
nix eval ./src/examples/your-example.nix --json
```

### 5. Commit Your Changes

Commit messages should be clear and descriptive:

```bash
git commit -m "feat: add new batch processing builder

- Implement mkBatchJob builder
- Support custom timeout settings
- Add integration tests (tests 159-161)
- Update documentation with examples"
```

Commit message format:
```
<type>: <short summary>

<longer description>

- Bullet points for details
- Each change clearly described
```

Types:
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation
- `style:` - Formatting (no logic change)
- `refactor:` - Code refactoring
- `test:` - Add/update tests
- `ci:` - CI/CD changes
- `chore:` - Build, dependencies, etc.

### 6. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
```

Then create a pull request on GitHub.

## Pull Request Process

### Before Submitting

1. **Pass all checks**: `nix flake check`
2. **Update tests**: Add tests for new features
3. **Update docs**: Document new functionality
4. **Update examples**: Show how to use new features
5. **Self-review**: Check your own code first

### PR Description Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] New feature
- [ ] Bug fix
- [ ] Documentation update
- [ ] Code refactoring
- [ ] Performance improvement

## Testing
- [ ] Added unit tests
- [ ] Added integration tests
- [ ] Manual testing completed

## Checklist
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests pass locally
- [ ] Flake checks pass
- [ ] No breaking changes (or documented)

## Related Issues
Closes #issue-number
```

### Review Process

1. Automatic checks run (flake checks, tests)
2. Code review by maintainers
3. Feedback and iteration
4. Approval and merge

## Contribution Types

### 1. Adding a New Module

Steps to add Module 36 (example):

1. **Create module file**: `src/lib/module-name.nix`
   - Follow existing module pattern
   - Include 10 builders (convention)
   - Add proper documentation

2. **Create documentation**: `docs/MODULE_NAME.md`
   - Overview section
   - Builder reference
   - Usage examples
   - Best practices

3. **Create examples**: `src/examples/module-name-example.nix`
   - 18 production-ready examples
   - Cover common use cases
   - Include comments

4. **Add integration tests**: `tests/integration-tests.nix`
   - 8 tests per module
   - Test builders
   - Test framework features

5. **Update flake.nix**:
   - Add module import
   - Add lib-* package
   - Add module tests
   - Add flake check

6. **Create PR with**:
   - All files above
   - Clear commit message
   - Link to related issues

### 2. Improving Documentation

1. Identify gap or improvement
2. Edit relevant `.md` file
3. Add examples if needed
4. Create PR with changes

### 3. Fixing Bugs

1. Create issue describing bug
2. Create branch: `fix/issue-description`
3. Make fix
4. Add test verifying fix
5. Create PR referencing issue

### 4. Improving Tests

1. Identify missing coverage
2. Add tests in `tests/integration-tests.nix`
3. Verify new tests pass
4. Create PR with explanation

## Code Style

### Nix Style

```nix
# Use consistent indentation (2 spaces)
let
  myVar = { ... };
in
{
  # Format functions nicely
  mkBuilder = config:
    let
      validated = validate config;
    in
    resource;
}
```

### Comments

```nix
# Comment what and why, not how
mkBuilder = config:
  # Validate that required fields are present
  let
    validated = lib.recursiveUpdate defaults config;
  in
  # Generate Kubernetes resource with framework labels
  resource;
```

### Naming

- `mkFoo` - Builders (constructors)
- `validateFoo` - Validators
- `fooToBar` - Converters
- `isFoo` - Predicates
- `fooList` - List data
- `defaultFoo` - Default values

## Testing

### Running Tests

```bash
# Run all tests
nix flake check

# Run specific test
nix eval ./tests/integration-tests.nix --offline

# Run with offline mode
nix flake check --offline
```

### Writing Tests

Add to `tests/integration-tests.nix`:

```nix
test-xyz = {
  description = "Test description";
  
  # Create test resources
  resources = [
    (mkBuilder { ... })
  ];
  
  # Verify expectations
  assertions = [
    (builtins.hasAttr "apiVersion" resource)
    (builtins.hasAttr "kind" resource)
  ];
};
```

## Releasing

For maintainers only:

1. Update version in `flake.nix`
2. Update `CHANGELOG.md`
3. Create tag: `git tag v1.0.0`
4. Push tags: `git push origin --tags`
5. Create GitHub release

## Resources

- **Documentation**: `/docs` directory
- **Examples**: `/src/examples` directory
- **API Reference**: `docs/API.md`
- **Architecture**: `ARCHITECTURE.md`
- **Getting Started**: `GETTING_STARTED.md`

## Questions?

- Open an issue with `question:` label
- Check existing issues/discussions
- Read documentation thoroughly

Thank you for contributing! 🎉

