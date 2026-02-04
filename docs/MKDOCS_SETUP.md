# GitHub Pages Documentation Site Setup

This guide helps set up a beautiful documentation site for Nixernetes using GitHub Pages and MkDocs.

## What is GitHub Pages?

GitHub Pages is a free static site hosting service that:
- Automatically deploys from your repository
- Uses GitHub Actions for CI/CD
- Supports custom domains
- Includes SSL/TLS certificates
- Has zero hosting costs

## Architecture

```
┌─────────────────────────────────────────┐
│     Your Documentation (Markdown)       │
│           in /docs directory            │
└──────────────────┬──────────────────────┘
                   │
         ┌─────────▼─────────┐
         │  GitHub Actions   │
         │  (CI/CD Pipeline) │
         │ - Build MkDocs    │
         │ - Run Tests       │
         │ - Deploy Site     │
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  GitHub Pages     │
         │  (Static Host)    │
         └─────────┬─────────┘
                   │
         ┌─────────▼─────────┐
         │  Your Domain      │
         │  nixernetes.dev   │
         │  (Optional)       │
         └───────────────────┘
```

## Setup Steps

### Step 1: Install MkDocs Locally

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate

# Install MkDocs and theme
pip install mkdocs mkdocs-material mkdocs-awesome-pages pymdown-extensions

# Verify installation
mkdocs --version
```

### Step 2: Review mkdocs.yml

The repository already includes a complete `mkdocs.yml` configuration with:
- Material theme (professional, mobile-responsive)
- Search functionality
- Code syntax highlighting
- Emoji support
- Tabs and collapsible sections
- Mermaid diagrams

### Step 3: Organize Documentation

Ensure your docs directory structure matches mkdocs.yml:

```
docs/
├── index.md                 # Homepage
├── getting-started/
│   ├── quick-start.md
│   ├── installation.md
│   ├── first-deployment.md
│   └── troubleshooting.md
├── tutorials/
│   ├── index.md
│   ├── tutorial-1.md
│   ├── tutorial-2.md
│   └── tutorial-3.md
├── examples/
│   └── ... (example documentation)
├── modules/
│   └── ... (module documentation)
├── guides/
│   └── ... (guide documentation)
├── cloud/
│   └── ... (cloud deployment guides)
├── community/
│   └── ... (community documentation)
└── assets/
    ├── stylesheets/
    │   └── extra.css
    └── javascripts/
        └── extra.js
```

### Step 4: Test Locally

```bash
# Build the site
mkdocs build

# This creates the 'site/' directory with static HTML

# Test locally
mkdocs serve

# Visit http://localhost:8000 in your browser
```

### Step 5: Enable GitHub Pages

1. Go to your repository **Settings**
2. Scroll to **Pages** section
3. Under **Source**, select:
   - **Deploy from a branch**
4. Under **Branch**, select:
   - Branch: `gh-pages`
   - Folder: `/ (root)`
5. Click **Save**

### Step 6: Enable GitHub Actions

1. Go to your repository **Actions** tab
2. Look for the "Build and Deploy Documentation" workflow
3. If not present, create it (already included in this repo)

The workflow automatically:
- Builds the site when docs change
- Deploys to the `gh-pages` branch
- Updates GitHub Pages

### Step 7: Verify Deployment

After pushing changes:

1. Go to **Actions** tab
2. Watch the "Build and Deploy Documentation" workflow run
3. Once completed (green ✓), visit your site:
   - Default: `https://your-username.github.io/nixernetes/`
   - Or: `https://nixernetes.dev` (if custom domain configured)

## Custom Domain Setup

### Using a Custom Domain

#### Option A: GitHub Custom Domain

1. Register domain (GoDaddy, Namecheap, etc.)
2. Go to repository **Settings** → **Pages**
3. Under "Custom domain", enter: `nixernetes.dev`
4. Click **Save**
5. GitHub automatically creates `CNAME` file
6. Configure your domain registrar:
   - Type: `A` records pointing to GitHub IPs
   - Or: `CNAME` record pointing to `username.github.io`

#### Option B: Subdomain (Recommended)

1. Use `docs.nixernetes.dev` instead of `nixernetes.dev`
2. Create `CNAME` record:
   - Name: `docs`
   - Value: `username.github.io`
3. Set custom domain in repository settings

### DNS Configuration

For GitHub Pages, configure these A records:

```
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```

Or use CNAME record:
```
your-username.github.io
```

## Site Structure

### Home Page (index.md)

```markdown
# Nixernetes Documentation

Welcome to the complete Nixernetes documentation.

## What is Nixernetes?

Brief overview...

## Quick Links

- [Getting Started](getting-started/quick-start.md)
- [Tutorials](tutorials/)
- [Modules](modules/)

## Latest News

Key announcements...
```

### Getting Started Section

- Quick Start - 5 minute setup
- Installation - Detailed setup
- First Deployment - Your first app
- Troubleshooting - Common issues

### Modules Section

Organized by category (Foundation, Core, Security, etc.) with:
- Module overview
- Builder functions
- Configuration options
- Examples
- Best practices

### Examples Section

Real-world deployments:
- Static website
- Django application
- Microservices
- ML pipeline
- Real-time chat
- IoT applications

### Community Section

- Contributing guide
- Code of conduct
- GitHub Discussions
- Release process
- Roadmap

## Content Best Practices

### Writing Documentation

1. **Clear Structure**
   ```markdown
   # Main Title
   ## Section
   ### Subsection
   ```

2. **Code Examples**
   - Use fenced code blocks with language identifier
   - Include complete, runnable examples
   - Highlight important lines with `!!!`

3. **Admonitions**
   ```markdown
   !!! note "Important Note"
       This is important information
   
   !!! warning "Warning"
       Be careful about this
   
   !!! tip "Pro Tip"
       Helpful suggestion
   ```

4. **Tabs for Variations**
   ```markdown
   === "AWS"
       AWS-specific instructions
   
   === "GCP"
       GCP-specific instructions
   
   === "Azure"
       Azure-specific instructions
   ```

5. **Mermaid Diagrams**
   ```mermaid
   graph LR
       A[Pods] --> B[Services]
       B --> C[Ingress]
   ```

6. **Tables**
   ```markdown
   | Column 1 | Column 2 |
   |----------|----------|
   | Value 1  | Value 2  |
   ```

### SEO Optimization

Add metadata to pages:

```markdown
---
title: Page Title
description: Brief description for search engines
keywords: keyword1, keyword2, keyword3
---
```

### Performance

- Keep pages focused and concise
- Use headings properly (hierarchy)
- Link related content
- Include table of contents (auto-generated)
- Optimize images

## Customization

### Custom CSS

Create `docs/assets/stylesheets/extra.css`:

```css
/* Custom Nixernetes branding */
.md-header {
    background-color: #0D1B3E;
}

.md-typeset h1 {
    color: #0D5CFF;
}

/* Custom colors */
:root {
    --md-primary-fg-color: #0D5CFF;
    --md-primary-bg-color: #0D1B3E;
}
```

### Custom JavaScript

Create `docs/assets/javascripts/extra.js`:

```javascript
// Custom analytics, interactive features, etc.
console.log('Nixernetes Documentation');
```

### Theme Customization

In `mkdocs.yml`:

```yaml
theme:
  palette:
    # Light mode
    - scheme: default
      primary: blue
      accent: blue
    # Dark mode
    - scheme: slate
      primary: blue
      accent: blue
```

## Search Functionality

The Material theme includes built-in search:
- Automatically indexes all content
- Searches in real-time as you type
- No external service required
- Results highlight matching content

### Improving Search

- Use descriptive headings
- Include keywords in content
- Create proper hierarchy
- Link related pages

## Analytics

### Google Analytics

Add to mkdocs.yml:

```yaml
extra:
  analytics:
    provider: google
    property: G-XXXXXXXXXX  # Your GA property ID
```

Then:
1. Create Google Analytics account
2. Create property for your domain
3. Get Measurement ID
4. Replace in mkdocs.yml

### Usage Statistics

Monitor in Google Analytics:
- Page views
- User engagement
- Popular pages
- Traffic sources
- Device types

## Deployment Troubleshooting

### Site not deploying

1. Check GitHub Actions:
   - Go to **Actions** tab
   - Look for workflow errors
   - Review logs

2. Common issues:
   - Missing `gh-pages` branch
   - Incorrect CNAME file
   - Python/dependencies not installed
   - mkdocs.yml syntax error

### Pages not found (404)

1. Verify file paths in mkdocs.yml
2. Ensure files exist in docs/
3. Check for capitalization issues
4. Rebuild locally: `mkdocs build`

### Custom domain not working

1. Check CNAME file in gh-pages branch
2. Verify DNS configuration
3. Wait 24 hours for DNS propagation
4. Verify domain is registered correctly

## Maintenance

### Regular Tasks

- [ ] Weekly: Review new content
- [ ] Monthly: Check search analytics
- [ ] Quarterly: Update version info
- [ ] Yearly: Audit links and update outdated content

### Link Checking

```bash
# Install link checker
pip install mkdocs-link-validator

# Add to mkdocs.yml plugins
# - link-validator

# Run build with validation
mkdocs build
```

### Content Updates

1. Edit markdown files
2. Test locally: `mkdocs serve`
3. Commit changes
4. Push to main
5. GitHub Actions automatically deploys

## Advanced Features

### Versioned Documentation

For different versions of Nixernetes:

```bash
# Install versioning plugin
pip install mkdocs-version-plugin
```

### Analytics Dashboards

Create dashboards in Google Analytics to track:
- New vs returning visitors
- Most popular sections
- User journey
- Conversion funnels

### Search Analytics

Monitor in Google Search Console:
- Search queries bringing users to your site
- Click-through rate
- Average position in search results
- Crawl statistics

## Success Metrics

A healthy documentation site has:

- ✅ 100+ pages indexed
- ✅ <2 second page load time
- ✅ Mobile-responsive (100% mobile users)
- ✅ 1000+ monthly page views
- ✅ >50% users from search
- ✅ Low bounce rate (<30%)
- ✅ High engagement (pages/session >3)

## Quick Reference

```bash
# Development
mkdocs serve              # Run local server
mkdocs build              # Build site
mkdocs clean              # Remove build folder

# Deployment (automatic via GitHub Actions)
git add docs/
git commit -m "docs: Update..."
git push origin main      # Triggers automatic deployment
```

## Resources

- [MkDocs Documentation](https://www.mkdocs.org/)
- [Material Theme](https://squidfunk.github.io/mkdocs-material/)
- [GitHub Pages](https://pages.github.com/)
- [Markdown Guide](https://www.markdownguide.org/)

---

## Status

Your documentation site is ready for deployment!

- [x] mkdocs.yml configured
- [x] GitHub Actions workflow created
- [x] Documentation structure organized
- [ ] Custom domain configured (optional)
- [ ] Content migrated
- [ ] Site deployed

**Next step:** Review the mkdocs.yml configuration and ensure all documentation files are in the correct locations.
