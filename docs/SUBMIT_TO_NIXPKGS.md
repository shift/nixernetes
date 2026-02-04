# Submitting Nixernetes to Official Nixpkgs

This guide walks through submitting Nixernetes to the official Nixpkgs repository.

## What is Nixpkgs?

Nixpkgs is the official package repository for Nix:
- Thousands of packages available
- Simple installation: `nix-shell -p nixernetes`
- Part of the NixOS ecosystem
- Maintained by the Nix community

## Benefits of Being in Nixpkgs

- ✅ Easier discovery and adoption
- ✅ Official endorsement
- ✅ Community maintenance help
- ✅ Automatic updates
- ✅ Cross-platform availability
- ✅ System integration

## Prerequisites

Before submitting, ensure:

- [ ] Nixernetes is stable and production-ready
- [ ] All tests pass
- [ ] Documentation is complete
- [ ] GitHub repository is public and well-maintained
- [ ] License is compatible with Nixpkgs (MIT recommended)
- [ ] You have GitHub account with contribution history

## Nixpkgs Package Structure

### Directory Layout

```
nixpkgs/
├── pkgs/
│   ├── applications/
│   ├── development/
│   │   └── tools/
│   │       └── nixernetes/
│   │           ├── default.nix
│   │           └── package.nix
│   └── ...
```

For Nixernetes, likely location: `pkgs/development/tools/nixernetes/`

### Package File (default.nix)

```nix
{ lib, stdenv, fetchFromGitHub, nix, nixpkgs }:

stdenv.mkDerivation rec {
  pname = "nixernetes";
  version = "1.0.0";
  
  src = fetchFromGitHub {
    owner = "nixernetes";
    repo = "nixernetes";
    rev = "v${version}";
    sha256 = "sha256-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=";
  };
  
  buildInputs = [ nix ];
  
  dontBuild = true;
  dontConfigure = true;
  
  installPhase = ''
    mkdir -p $out
    cp -r . $out/
  '';
  
  meta = with lib; {
    description = "Enterprise-grade Nix-driven Kubernetes manifest framework";
    homepage = "https://github.com/nixernetes/nixernetes";
    license = licenses.mit;
    maintainers = [ maintainers.yourGitHubHandle ];
    platforms = platforms.all;
  };
}
```

## Step-by-Step Submission

### Step 1: Fork nixpkgs

```bash
# Fork on GitHub at https://github.com/NixOS/nixpkgs

# Clone your fork
git clone https://github.com/YOUR_USERNAME/nixpkgs.git
cd nixpkgs

# Add upstream
git remote add upstream https://github.com/NixOS/nixpkgs.git
git fetch upstream

# Create feature branch
git checkout -b add-nixernetes
```

### Step 2: Create Package Directory

```bash
# Create directory for the package
mkdir -p pkgs/development/tools/nixernetes

# Create default.nix (see template above)
cat > pkgs/development/tools/nixernetes/default.nix << 'EOF'
# [paste content from template]
EOF
```

### Step 3: Calculate sha256 Hash

```bash
# Get the SHA256 hash of the source
nix-prefetch-github nixernetes nixernetes v1.0.0

# Output will look like:
# {
#   "sha256": "0abc123...",
#   "commit": "...",
#   ...
# }

# Update the sha256 in default.nix with this value
```

Or use automated method:

```bash
# Let nix calculate it for you
cd nixpkgs
# Set sha256 to "" in default.nix

# Run:
nix build -f default.nix -A nixernetes

# Error will show correct sha256
# Copy and update default.nix
```

### Step 4: Test the Package Locally

```bash
# Build the package
nix build -f default.nix -A nixernetes

# Test installation
nix-shell -p nixernetes

# Verify commands work
./bin/nixernetes --help
./bin/nixernetes list
```

### Step 5: Add to All-Packages

Edit `pkgs/top-level/all-packages.nix`:

```nix
# Find appropriate section (tools, development, etc.)
# Add around line 5000 in alphabetical order:

nixernetes = callPackage ../development/tools/nixernetes { };
```

### Step 6: Check for Existing Packages

```bash
# Search for related packages that might conflict
grep -r "nixernetes" pkgs/

# Look for similar Kubernetes tools
grep -r "kubernetes" pkgs/development/tools/ | head -20
```

### Step 7: Run Nixpkgs Tests

```bash
# Check if package builds (requires some time)
nix build -f default.nix -A nixernetes

# Evaluate package without building
nix eval -f default.nix -A nixernetes.meta

# Check for warnings
nix eval --impure -f default.nix -A nixernetes
```

### Step 8: Create Pull Request

```bash
# Commit your changes
git add pkgs/development/tools/nixernetes/
git add pkgs/top-level/all-packages.nix
git commit -m "nixernetes: add v1.0.0"

# Push to your fork
git push origin add-nixernetes
```

Then:

1. Go to https://github.com/NixOS/nixpkgs/pulls
2. Click "New Pull Request"
3. Select your branch
4. Fill in PR template:

```markdown
# Description

Adds Nixernetes v1.0.0 to Nixpkgs.

## Motivation and Context

Nixernetes is an enterprise-grade Nix-driven Kubernetes manifest 
framework with 35 production-ready modules.

Links:
- GitHub: https://github.com/nixernetes/nixernetes
- Documentation: https://docs.nixernetes.dev
- Release: https://github.com/nixernetes/nixernetes/releases/tag/v1.0.0

## Type of change

- [x] New package
- [ ] Update package
- [ ] Update package version
- [ ] Remove package

## Testing

- [x] Tested with `nix build`
- [x] Tested with `nix-shell -p nixernetes`
- [x] Commands execute correctly

## Checklist

- [x] Included package in `pkgs/top-level/all-packages.nix`
- [x] Used correct architecture (platform field)
- [x] Included `meta.maintainers`
- [x] Package description is accurate
- [x] License is correct (MIT)
- [x] No IFD (import from derivation) in the package
```

### Step 9: Address Review Comments

Maintainers may suggest:

1. **Maintainer Changes**
   - Keep maintained (if you'll maintain it)
   - Or add: `maintainers = with lib.maintainers; [ ];`

2. **Package Structure**
   - May suggest different location
   - May request platform-specific handling

3. **Testing**
   - May ask for more complete tests
   - May request specific configuration examples

4. **Documentation**
   - Update nixpkgs documentation if relevant
   - Add release notes mention

### Step 10: Merge and Celebrate!

Once approved:
- Maintainers merge your PR
- Package available via:
  ```bash
  nix-shell -p nixernetes
  nix shell nixpkgs#nixernetes
  nix run nixpkgs#nixernetes -- --help
  ```

## Long-term Maintenance

### Keeping Package Updated

When new versions release:

1. Update version in package
2. Calculate new sha256
3. Create new PR with changes
4. Follow same review process

```bash
# Example update
git checkout -b update-nixernetes-1.1.0
# Edit: version, sha256
git add ...
git commit -m "nixernetes: 1.0.0 -> 1.1.0"
git push origin update-nixernetes-1.1.0
```

### Being a Nixpkgs Maintainer

As maintainer of the package:

- Monitor package status
- Respond to issues related to Nixernetes in Nixpkgs
- Update for new releases
- Review dependency changes
- Handle compatibility issues

## Common Issues

### Build Failures

```bash
# Check full build log
nix build -f default.nix -A nixernetes --print-build-logs

# Common issues:
# - Missing dependencies (add to buildInputs)
# - Wrong hash (recalculate)
# - Network access needed (use fetchgit instead)
```

### Platform Issues

```nix
# Package on specific platforms only
platforms = lib.platforms.unix;  # Unix/Linux/macOS only
platforms = lib.platforms.linux; # Linux only
platforms = lib.platforms.all;   # All platforms
```

### Dependency Issues

```bash
# Check available packages
nix-env -qa | grep name-fragment

# Find package in Nixpkgs
nix search nixpkgs kubernetes

# Use callPackage to inject dependencies
callPackage ./default.nix {
  someLib = specialLib;
}
```

## Advanced: Flakes Support

If nixpkgs supports your flake.nix:

```nix
# In nixpkgs, reference the flake
nixernetes = inputs.nixernetes.defaultPackage.${system};

# Or use flake-utils:
nixernetes = (flake-utils.lib.evalFlake (inputs.nixernetes)).defaultPackage.${system};
```

## Communication

### Nixpkgs Community

- **GitHub Issues:** Report bugs in nixpkgs
- **Discourse:** Discuss at https://discourse.nixos.org/
- **IRC:** #nixos on Libera.Chat
- **Matrix:** #nixos on Nixos.org

### PR Review Timeline

Typical timelines:
- New packages: 1-4 weeks review
- Updates: 1-2 weeks review
- Critical fixes: 1-3 days

Be patient and responsive to feedback!

## Success Checklist

- [ ] Fork nixpkgs repository
- [ ] Create package directory
- [ ] Write default.nix with correct hash
- [ ] Test locally with `nix build`
- [ ] Add to all-packages.nix
- [ ] Create descriptive PR
- [ ] Respond to review comments
- [ ] Address any requested changes
- [ ] PR merged to nixpkgs
- [ ] Celebrate! 🎉

## After Acceptance

### Announce

```markdown
# Nixernetes is now in Nixpkgs!

You can now install Nixernetes directly:

```bash
nix shell nixpkgs#nixernetes
```

Or add to your environment:

```bash
nix-env -i nixernetes
```

Thanks to @maintainerName for the review!
```

### Update Documentation

- [ ] Update README with Nixpkgs install option
- [ ] Update GETTING_STARTED.md
- [ ] Announce in releases notes
- [ ] Share on social media

## Resources

- [Nixpkgs Manual](https://nixos.org/manual/nixpkgs/stable/)
- [Contributing to Nixpkgs](https://github.com/NixOS/nixpkgs/blob/master/CONTRIBUTING.md)
- [Package Guidelines](https://nixos.org/manual/nixpkgs/stable/#sec-package-guidelines)
- [Nixpkgs Issues](https://github.com/NixOS/nixpkgs/issues)

---

## Timeline

Estimated total time: **4-8 weeks**

- Week 1: Prepare package and submit
- Week 2-3: Initial review and feedback
- Week 3-6: Address comments and iterate
- Week 6-8: Final review and merge

Be prepared for constructive feedback and willing to improve the package!
