# Shell Completion Installation Guide

Shell completions for Nixernetes CLI make working with the tool more efficient and enjoyable.

## Overview

Three completion scripts are available:
- **Bash** - For Bash 3.2+ (macOS, Linux)
- **Zsh** - For Zsh 5.0+ (modern shells)
- **Fish** - For Fish 2.3.0+ (user-friendly shell)

## Installation

### Bash Completion

**Option 1: System-wide installation**
```bash
# Linux
sudo cp completions/nixernetes-completion.bash /usr/share/bash-completion/completions/nixernetes

# Reload completions
exec bash
```

**Option 2: User-only installation**
```bash
# Create completions directory if needed
mkdir -p ~/.bash_completion.d

# Copy completion file
cp completions/nixernetes-completion.bash ~/.bash_completion.d/

# Add to ~/.bashrc
echo 'source ~/.bash_completion.d/nixernetes-completion.bash' >> ~/.bashrc

# Reload shell
source ~/.bashrc
```

**Option 3: Directly in shell config**
```bash
# Add to ~/.bashrc
source /path/to/nixernetes/completions/nixernetes-completion.bash
```

### Zsh Completion

**Option 1: Using Oh My Zsh**
```bash
# Copy to Oh My Zsh completions directory
cp completions/nixernetes-completion.zsh \
  ~/.oh-my-zsh/completions/_nixernetes

# Reload shell
exec zsh
```

**Option 2: System-wide installation**
```bash
# Create directory if needed
sudo mkdir -p /usr/share/zsh/site-functions

# Copy completion file
sudo cp completions/nixernetes-completion.zsh \
  /usr/share/zsh/site-functions/_nixernetes

# Reload shell
exec zsh
```

**Option 3: User-only installation**
```bash
# Create fpath directory
mkdir -p ~/.zsh/completions

# Copy completion file
cp completions/nixernetes-completion.zsh ~/.zsh/completions/_nixernetes

# Add to ~/.zshrc
echo 'fpath=(~/.zsh/completions $fpath)' >> ~/.zshrc
echo 'autoload -Uz compinit && compinit' >> ~/.zshrc

# Reload shell
exec zsh
```

### Fish Completion

**Option 1: User installation (easiest)**
```bash
# Create completions directory
mkdir -p ~/.config/fish/completions

# Copy completion file
cp completions/nixernetes-completion.fish \
  ~/.config/fish/completions/nixernetes.fish

# Reload shell
exec fish
```

**Option 2: System-wide installation**
```bash
# Copy to Fish system directory
sudo cp completions/nixernetes-completion.fish \
  /usr/share/fish/vendor_completions.d/nixernetes.fish

# Reload shell
exec fish
```

## Usage

### Bash Examples

```bash
# Press Tab after 'nixernetes' to see commands
$ nixernetes [TAB]
deploy  docs  generate  help  init  list  logs  template  test  upgrade  validate  version

# Complete subcommand options
$ nixernetes deploy --[TAB]
--config   --context  --dry-run  --force    --namespace  --timeout  --wait  --watch

# Complete file paths
$ nixernetes validate --config con[TAB]
config/main.nix  config/prod.nix  config/staging.nix

# Complete values
$ nixernetes deploy --namespace [TAB]
default       development   production    staging
```

### Zsh Examples

```zsh
# See available commands with descriptions
$ nixernetes [TAB]
validate  -- Validate configuration
init      -- Initialize project
generate  -- Generate YAML
deploy    -- Deploy to cluster

# Options with descriptions
$ nixernetes deploy --[TAB]
--config       -- Configuration file
--namespace    -- Kubernetes namespace
--dry-run      -- Perform dry-run
--wait         -- Wait for deployment

# Smart completion for file arguments
$ nixernetes template create [TAB]
simple-web    -- Simple web application
microservices -- Microservices architecture
static-site   -- Static site hosting
```

### Fish Examples

```fish
# Tab completion
$ nixernetes [TAB]
Shows: validate, init, generate, deploy, test, ...

# With descriptions
$ nixernetes deploy [TAB]
Shows full descriptions of options

# Suggest values
$ nixernetes deploy --namespace [TAB]
default, production, staging, development
```

## Verification

### Test Bash Completion

```bash
# Source the completion script
source completions/nixernetes-completion.bash

# Test by pressing Tab
nixernetes va[TAB]
# Should complete to: nixernetes validate

# Test with options
nixernetes deploy --[TAB]
# Should show available options
```

### Test Zsh Completion

```zsh
# Source the completion script
source completions/nixernetes-completion.zsh

# Test by pressing Tab
nixernetes va[TAB]
# Should complete to: nixernetes validate
```

### Test Fish Completion

```fish
# Fish loads completions automatically if in right directory
cd ~/.config/fish/completions

# Test by pressing Tab
nixernetes va[TAB]
# Should complete to: nixernetes validate
```

## Troubleshooting

### Completions not working

**Bash:**
```bash
# Verify completion script is sourced
grep nixernetes ~/.bashrc
# or
grep nixernetes ~/.bash_profile

# Manually reload
source /path/to/nixernetes-completion.bash

# Check for errors
bash -x -c "source /path/to/nixernetes-completion.bash"
```

**Zsh:**
```bash
# Verify fpath includes completions directory
echo $fpath

# Check if completion file is found
find $fpath -name "_nixernetes"

# Reload completions
compinit -D
```

**Fish:**
```bash
# Check completion file location
ls -la ~/.config/fish/completions/

# Reload completions
fish -c "complete -c nixernetes" | head -5

# Check for syntax errors
fish -n ~/.config/fish/completions/nixernetes.fish
```

### Completions outdated

When you update Nixernetes, you may want to update completions:

```bash
# Re-copy completion files from new version
cp /path/to/new/nixernetes/completions/* \
  /path/to/completions/directory/
```

### Custom completions

You can extend completions for custom commands:

**Bash:**
```bash
# Add to ~/.bash_completion.d/custom-nixernetes
complete -c nixernetes -f -a "custom-command" -d "My custom command"
```

**Zsh:**
```zsh
# Add to ~/.zsh/completions/_nixernetes_custom
_custom_nixernetes() {
    # Custom completion logic
}
```

**Fish:**
```fish
# Add to ~/.config/fish/completions/custom-nixernetes.fish
complete -c nixernetes -f -a "custom-command" -d "My custom command"
```

## Features

### Command Completion
All nixernetes commands are completed with descriptions:
- `validate` - Validate configuration
- `init` - Initialize project
- `generate` - Generate YAML
- `deploy` - Deploy to cluster
- And more...

### Option Completion
Options for each command are completed intelligently:
- Flags: `--strict`, `--dry-run`, etc.
- Values: Suggest valid options (yaml, json, etc.)
- Files: Suggest .nix files for --config

### Context-Aware
Completions adapt based on what you're typing:
- Different options for different commands
- File suggestions for file arguments
- Value suggestions for enum arguments

### Template Completions
All starter templates are auto-completed:
- `simple-web` - Simple web application
- `microservices` - Microservices architecture
- `static-site` - Static site hosting
- And more...

## Advanced Usage

### Generate Dynamic Completions

To generate completions dynamically from CLI:

```bash
# Python-based completion generation
python3 -c "
import sys
sys.path.insert(0, '/path/to/nixernetes')
from bin.nixernetes import NixernetesCommand
# Generate completions
"
```

### Completion Caching

For slow-to-generate completions, enable caching:

**Zsh:**
```zsh
# Cache completions
_cache_completions() {
    local cache_dir=~/.cache/zsh
    mkdir -p $cache_dir
    # Cache logic here
}
```

## Performance

Completions should complete in <100ms:

```bash
# Measure completion time
time nixernetes [TAB]

# If slow, check for network calls or file I/O
```

## Customization

### Custom Theme for Completions

**Zsh with Powerlevel10k:**
```zsh
# Customize completion colors
zstyle ':completion:*:nixernetes' group-name ''
zstyle ':completion:*:nixernetes:*' list-colors '=^(.*validate)=38;5;240'
```

**Fish with Oh My Fish:**
```fish
# Customize with theme
set -U fish_color_command cyan
```

## Uninstallation

To remove completions:

**Bash:**
```bash
# Remove completion file
rm ~/.bash_completion.d/nixernetes-completion.bash
# or
sudo rm /usr/share/bash-completion/completions/nixernetes
```

**Zsh:**
```bash
# Remove completion file
rm ~/.zsh/completions/_nixernetes
# or
sudo rm /usr/share/zsh/site-functions/_nixernetes
```

**Fish:**
```bash
# Remove completion file
rm ~/.config/fish/completions/nixernetes.fish
# or
sudo rm /usr/share/fish/vendor_completions.d/nixernetes.fish
```

## Getting Help

- **Bash:** `man bash-completion`
- **Zsh:** `man zshcompsys`
- **Fish:** `man fish-complete`

## Contributing

Have a better completion? Contribute!

1. Edit the completion script in `completions/`
2. Test thoroughly
3. Submit a pull request

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.
