# Release Checklist for Maintainers

This checklist ensures consistent, high-quality releases of Nixernetes.

## Pre-Release (1 week before)

- [ ] Review all open issues and PRs
- [ ] Identify breaking changes
- [ ] Plan migration guide if needed
- [ ] Update roadmap if necessary
- [ ] Notify stakeholders of upcoming release

## Code Preparation (3-5 days before)

- [ ] Run full test suite: `nix flake check`
- [ ] Run all integration tests: `nix flake check`
- [ ] Check code quality:
  - [ ] No linting errors: `nixpkgs-fmt check src/`
  - [ ] No security issues: Review security scanning
  - [ ] No breaking changes documented
- [ ] Test on multiple Kubernetes versions:
  - [ ] 1.28.x
  - [ ] 1.29.x
  - [ ] 1.30.x
  - [ ] 1.31.x
- [ ] Test on multiple cloud platforms:
  - [ ] AWS EKS
  - [ ] GCP GKE
  - [ ] Azure AKS
- [ ] Performance regression testing
  - [ ] Build time < 2 seconds
  - [ ] Manifest evaluation < 1 second
  - [ ] Generated manifest size acceptable

## Documentation (2-3 days before)

- [ ] Update CHANGELOG.md with all changes
  - [ ] Features section
  - [ ] Enhancements section
  - [ ] Bug fixes section
  - [ ] Security fixes section (if any)
  - [ ] Deprecated features section (if any)
  - [ ] Breaking changes section (if any)
- [ ] Update version in `flake.nix`
  - [ ] Update version string
  - [ ] Update flake.lock if needed
- [ ] Review module documentation:
  - [ ] All modules documented
  - [ ] API changes documented
  - [ ] Examples updated
- [ ] Update tutorials:
  - [ ] Check compatibility with new version
  - [ ] Update example code if needed
- [ ] Review architecture documentation:
  - [ ] Updated if design changed
  - [ ] No broken links
- [ ] Check cloud deployment guides:
  - [ ] AWS EKS guide current
  - [ ] GCP GKE guide current
  - [ ] Azure AKS guide current

## Communication (1-2 days before)

- [ ] Draft release notes:
  - [ ] Summary of major changes
  - [ ] Migration guide (if breaking changes)
  - [ ] Upgrade instructions
  - [ ] Known issues (if any)
  - [ ] Thank you to contributors
- [ ] Plan announcement channels:
  - [ ] GitHub Releases
  - [ ] Project README
  - [ ] Documentation site (if applicable)
- [ ] Prepare deprecation notices (if applicable):
  - [ ] Clear timeline for deprecation
  - [ ] Migration path documented

## Release Day

### Morning - Final Checks

- [ ] Final full test run: `nix flake check`
- [ ] Verify no uncommitted changes: `git status`
- [ ] Verify all tests pass in CI/CD
- [ ] Review recent commits for issues
- [ ] Create release branch: `git checkout -b release/v1.0.0`

### Create Release Tag

```bash
# Update version in flake.nix
# Example: version = "1.0.0";
vim flake.nix

# Update CHANGELOG.md
# Replace [Unreleased] with [1.0.0] - YYYY-MM-DD

# Commit version and changelog
git add flake.nix CHANGELOG.md
git commit -m "chore: Bump version to 1.0.0"

# Create annotated tag
git tag -a v1.0.0 -m "Release v1.0.0: Feature X, Feature Y, Security Fix Z"

# Push branch and tag
git push origin release/v1.0.0
git push origin v1.0.0
```

- [ ] Verify tag created: `git tag -l v1.0.0`
- [ ] Verify tag message: `git tag -v v1.0.0`
- [ ] Verify push succeeded: `git ls-remote origin v1.0.0`

### Create GitHub Release

- [ ] Go to GitHub Releases page
- [ ] Click "Create a new release"
- [ ] Set tag: `v1.0.0`
- [ ] Set title: `Release 1.0.0: Your Title Here`
- [ ] Add release notes from CHANGELOG.md
- [ ] Include:
  - [ ] Summary of changes
  - [ ] Major features
  - [ ] Bug fixes
  - [ ] Security updates
  - [ ] Known issues
  - [ ] Migration guide (if needed)
  - [ ] Upgrade instructions
  - [ ] Contributor acknowledgments
- [ ] Mark as latest (if applicable)
- [ ] Publish release

### Post-Release - Day Of

- [ ] Verify GitHub Release is published
- [ ] Test installation from release:
  ```bash
  git clone https://github.com/nixernetes/nixernetes.git -b v1.0.0
  cd nixernetes
  nix flake check --offline
  ```
- [ ] Check download metrics (if available)
- [ ] Monitor for early bug reports
- [ ] Prepare hotfix branch if critical issues found

### Post-Release - Documentation Updates

- [ ] Update project README
  - [ ] Update version badge
  - [ ] Update "Latest Release" section
- [ ] Update "Getting Started" guide
  - [ ] Version-specific instructions
- [ ] Update documentation site (if applicable)
  - [ ] Deploy new version
  - [ ] Update version selector
- [ ] Add blog post or announcement (if applicable)
- [ ] Update status page with new version

### Post-Release - Community

- [ ] Announce on:
  - [ ] GitHub Discussions
  - [ ] Project email list (if applicable)
  - [ ] Social media (if applicable)
  - [ ] Community Slack/Discord (if applicable)
- [ ] Monitor feedback for issues
- [ ] Prepare for hotfix if needed
- [ ] Start planning next release

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** - Breaking changes to APIs or core functionality
- **MINOR** - New features, backward compatible
- **PATCH** - Bug fixes, backward compatible

Examples:
- v1.0.0 → Major release
- v1.1.0 → Minor release (new feature)
- v1.1.1 → Patch release (bug fix)
- v2.0.0 → Major release (breaking change)

## Release Frequency

- **Patch releases** - As needed for critical bugs/security fixes
- **Minor releases** - Every 4-6 weeks with new features
- **Major releases** - Every 6-12 months with significant changes

## Support Timeline

- **Current version** - Full support
- **Previous minor version** - Security fixes only
- **Older versions** - End of life, no support

## Hotfix Process

If critical bugs found after release:

1. Create hotfix branch: `git checkout -b hotfix/v1.0.1`
2. Fix the issue
3. Run full test suite
4. Update CHANGELOG.md with Hotfix section
5. Bump patch version: v1.0.0 → v1.0.1
6. Follow "Create Release Tag" section
7. Announce hotfix with severity details
8. Merge back to main and develop branches

## Rollback Process

If release has critical issues:

1. Publish hotfix with fix
2. Document issue in CHANGELOG.md
3. Add to "Known Issues" section of release notes
4. Notify users via:
   - [ ] GitHub Releases update
   - [ ] Email (if list available)
   - [ ] Documentation site
5. Monitor adoption of hotfix
6. Consider yanking problematic version if not yet widely used

## Metrics to Track

After each release, monitor:

- [ ] Download count
- [ ] GitHub stars
- [ ] Bug reports
- [ ] Feature requests
- [ ] User feedback
- [ ] Community contributions

## Release Checklist for 1.0.0

- [ ] All 35 modules tested
- [ ] 158 integration tests passing
- [ ] 24 flake checks passing
- [ ] All examples working
- [ ] All tutorials verified
- [ ] Cloud guides tested
- [ ] Security audit completed
- [ ] Performance benchmarks passed
- [ ] Documentation complete
- [ ] Community infrastructure ready

## Emergency Release Procedure

For critical security issues:

1. Create hotfix branch immediately
2. Fix the issue
3. Run essential tests (not full suite if time-critical)
4. Update CHANGELOG.md
5. Create and publish release
6. **Immediately announce** via all channels:
   - [ ] GitHub Security Advisory
   - [ ] Email notification
   - [ ] Social media
7. Provide:
   - [ ] Issue description (without exposing exploit)
   - [ ] Fix summary
   - [ ] Urgency level
   - [ ] Upgrade instructions
8. Plan follow-up communication

## Release Communication Template

```markdown
# Release v1.0.0: [Title]

**Released:** YYYY-MM-DD

## Summary

[High-level overview of what's new and important]

## Major Features

- Feature 1 - Description
- Feature 2 - Description
- Feature 3 - Description

## Bug Fixes

- Fix 1 - Description
- Fix 2 - Description

## Security Updates

- Security fix 1 - Description (if any)

## Breaking Changes

[If any breaking changes, describe migration path]

## Migration Guide

[Step-by-step if applicable]

## Upgrade Instructions

```bash
# Update to latest
git clone https://github.com/nixernetes/nixernetes.git -b v1.0.0
cd nixernetes

# Or if already cloned
git fetch origin
git checkout v1.0.0
```

## Known Issues

[List any known limitations]

## Contributors

Thank you to all contributors for this release:
- @contributor1
- @contributor2
- etc.

## What's Next

[Preview of upcoming features]
```

## Maintenance

- [ ] Keep checklist updated as process evolves
- [ ] Review after each release for improvements
- [ ] Get feedback from team
- [ ] Update based on lessons learned

---

**Questions about releases?** Open an issue or see [CONTRIBUTING.md](../CONTRIBUTING.md)
