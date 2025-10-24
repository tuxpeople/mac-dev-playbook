# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a customized fork of Jeff Geerling's Mac Development Ansible Playbook for automated macOS setup and maintenance. It uses Ansible to provision and update multiple Mac machines (both business and private) with consistent configurations, software installations, and settings.

## Repository Architecture

### Inventory Structure

The repository manages multiple Macs through a hierarchical inventory system:

- **inventories/macs.list**: Defines host groups (`business_mac`, `private_mac`) and individual hosts
- **inventories/group_vars/**: Configuration inheritance hierarchy
  - `macs/`: Base configuration for all Macs
  - `business_mac/`: Business-specific overrides
  - `private_mac/`: Private-specific overrides
- **inventories/host_vars/**: Per-host configurations (e.g., `odin.yml`, `thor.yml`, `ws547.yml`)

Configuration cascades from general → group → host-specific, allowing shared defaults with targeted customization.

### Playbook Types

**main.yml**: Simple full provisioning playbook for initial setup
- Uses `default.config.yml` for configuration
- Runs all standard roles (homebrew, mas, dotfiles, dock, etc.)
- Suitable for fresh Mac setup

**plays/full.yml**: Complete provisioning with advanced features
- Sets up temporary passwordless sudo for automation
- Installs Rosetta 2 for Apple Silicon Macs
- Includes SSH key setup and additional pre-tasks
- Runs post-provision tasks from `post_provision_tasks` glob

**plays/update.yml**: Daily update/maintenance playbook
- Focused on updates (brew, cask, Microsoft, kubectl, GPG)
- Runs custom roles: `ansible-mac-update`, `munki_update`, `ansible-role-nvm`
- Uses environment variable `env_path` for proper PATH setup
- Manages temporary sudo permissions automatically

### Custom Roles

Located in `roles/`:

- **ansible-mac-update**: Handles macOS software updates, Homebrew updates, Microsoft updates, kubectl updates, SSH/GPG key management
- **munki_update**: Manages Munki package updates (when `munki_update` is enabled)
- **ansible-role-nvm**: Node.js version management via nvm
- **homebrew**: Symlinked from external ansible-collection-mac repository

### External Dependencies

Defined in `requirements.yml`:
- `elliotweiser.osx-command-line-tools`: Ensures Xcode CLI tools are installed
- `geerlingguy.dotfiles`: Manages dotfiles repository sync
- `geerlingguy.mac` collection: Provides homebrew, mas, and dock roles
- `aadl.softwareupdate`: macOS software update automation

## Common Commands

### Initial Setup

```bash
# Install Python 3.11.8 with pyenv and create virtualenv
pyenv install 3.11.8
pyenv virtualenv 3.11.8 mac-dev-playbook-venv
pyenv activate mac-dev-playbook-venv

# Install dependencies
pip3 install --requirement requirements.txt
ansible-galaxy install -r requirements.yml

# Run full provisioning
ansible-playbook plays/full.yml -i inventories -l $(hostname) --connection=local
```

### Daily Updates

```bash
# Run the macupdate script (located in scripts/macupdate)
# This script handles the complete update workflow:
# - Ensures tools are installed (pyenv, mise)
# - Sets up Python environment
# - Updates git repo
# - Installs requirements
# - Runs plays/update.yml

# Option 1: Run from repo
./scripts/macupdate

# Option 2: Create symlink for convenience (recommended)
ln -sf ~/development/github/tuxpeople/mac-dev-playbook/scripts/macupdate \
       ~/iCloudDrive/Allgemein/bin/macupdate
~/iCloudDrive/Allgemein/bin/macupdate
```

### Manual Playbook Execution

```bash
# Run specific playbook for current host
ansible-playbook plays/update.yml -i inventories -l $(hostname) --connection=local

# Run for specific host
ansible-playbook plays/update.yml -i inventories -l odin --connection=local

# Run with specific tags
ansible-playbook main.yml -i inventories -l $(hostname) --connection=local --tags "homebrew,dotfiles"

# Available tags: dotfiles, homebrew, mas, dock, sudoers, terminal, osx, fonts, extra-packages, sublime-text, post
```

## Configuration System

### Configuration Override Pattern

1. **default.config.yml**: Base defaults (from upstream)
2. **config.yml**: Optional local overrides (gitignored, user-specific)
3. **inventories/group_vars/macs/**: Shared configuration for all Macs
4. **inventories/group_vars/[business|private]_mac/**: Group-specific configs
5. **inventories/host_vars/hostname.yml**: Host-specific overrides

### Key Configuration Files

- **inventories/group_vars/macs/brew.yml**: Homebrew packages and casks for all Macs
- **inventories/group_vars/macs/dock.yml**: Dock configuration
- **inventories/group_vars/macs/dotfiles.yml**: Dotfiles repository settings
- **inventories/group_vars/macs/general.yml**: Core settings (timezone, Python interpreter, paths)
- **inventories/group_vars/macs/LaunchAgents.yml**: macOS LaunchAgent definitions
- **inventories/group_vars/macs/post.yml**: Post-provision task file globs
- **inventories/group_vars/macs/secrets.yml**: Encrypted sensitive data
- **inventories/group_vars/macs/munki.yml**: Munki configuration

### Important Variables

- `env_path`: Custom PATH including Homebrew, krew, and system paths
- `ansible_python_interpreter`: Uses CommandLineTools Python by default
- `the_user`: Current user (`ansible_user_id`)
- `configure_*`: Boolean flags to enable/disable features (dotfiles, osx, dock, etc.)
- `post_provision_tasks`: Glob patterns for additional task files to run

## Post-Provision Tasks

Located in `tasks/post/`, these run during the 'post' tag phase:

- **k8s.yml**: Kubernetes tool setup (kubectl, krew plugins)
- **gpg.yml**: GPG key configuration
- **github.yml**: GitHub CLI setup
- **vscode.yml**: VS Code configuration
- **iterm2.yml**: iTerm2 preferences
- **various-settings.yml**: Miscellaneous macOS settings
- **_launchagents.yml**: LaunchAgent installation

## Testing

The repository includes GitHub Actions CI (see `.github/workflows/` if present). When making changes:

1. Test locally on a non-production Mac first
2. Use `--check` mode for dry runs: `ansible-playbook plays/update.yml --check`
3. Use `--diff` to see what would change
4. Run with increased verbosity if needed: `-v`, `-vv`, or `-vvv`

## Workflow Notes

- The `macupdate` script is the primary maintenance tool - it orchestrates the entire update process
- Temporary passwordless sudo is automatically configured during playbook runs and removed afterward
- Configuration changes should be made in the appropriate inventory file level (not in playbooks directly)
- For new Macs: add hostname to `inventories/macs.list` and create corresponding host_vars file
- The homebrew role is symlinked from an external collection, modifications should be made there

## Documentation & Task Tracking

When starting a new session, Claude should read these files:

- **docs/sessions/SESSION_STATUS.md**: Current session status, what was done, what's next
- **docs/TODO.md**: Long-term tasks that span multiple sessions
- **docs/analysis/IMPROVEMENTS.md**: All identified code quality issues (64 remaining: 21 HIGH + 41 MEDIUM + 2 LOW)

**Purpose**:
- `SESSION_STATUS.md`: Session-specific progress tracking
- `TODO.md`: General tasks, ideas, maintenance items
- `IMPROVEMENTS.md`: Technical debt and code quality improvements

## Code Quality & Pre-Commit Checks

Before committing changes, always run:

```bash
# Lint YAML files
yamllint .

# Lint Ansible playbooks
ansible-lint

# Lint shell scripts
shellcheck scripts/*.sh init*.sh tests/*.sh
```

**Required for CI to pass:**
- yamllint: No errors (warnings are acceptable)
- ansible-lint: No errors
- shellcheck: No errors

**Common yamllint fixes:**
```bash
# Add document start marker
echo "---" | cat - file.yml > temp && mv temp file.yml

# Remove trailing spaces
sed -i '' 's/[[:space:]]*$//' file.yml

# Add newline at end of file
echo "" >> file.yml
```
