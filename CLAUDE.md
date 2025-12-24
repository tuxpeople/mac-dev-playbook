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

### External Dependencies

Defined in `requirements.yml`:
- `elliotweiser.osx-command-line-tools`: Ensures Xcode CLI tools are installed
- `geerlingguy.dotfiles`: Manages dotfiles repository sync
- `geerlingguy.mac` collection: Provides homebrew, mas, and dock roles
- `aadl.softwareupdate`: macOS software update automation

## Common Commands

**See [docs/WORKFLOWS.md](docs/WORKFLOWS.md) for complete workflow documentation.**

### Initial Setup (Brand New Mac)

```bash
# Bootstrap a completely fresh Mac (runs before anything else)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tuxpeople/mac-dev-playbook/master/init.sh)"

# Prerequisites: Create inventories/host_vars/<hostname>.yml BEFORE running
# See: docs/NEW_MAC_SETUP.md
```

### Configuration Changes (After Editing Config Files)

```bash
# Apply all configuration changes
./scripts/macapply

# Or apply only specific parts (faster)
./scripts/macapply --tags homebrew  # Only Homebrew packages
./scripts/macapply --tags dock      # Only Dock configuration
./scripts/macapply --tags osx       # Only macOS settings

# Dry run (see what would change)
./scripts/macapply --check --diff

# Available tags: homebrew, dotfiles, mas, dock, osx, fonts, extra-packages, post
# Note: mas tag is currently disabled in plays/full.yml
```

### Daily Updates (Maintenance)

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

**Summary**:
- `init.sh`: Once per Mac (fresh setup)
- `macapply`: When you change configuration (brew.yml, dock.yml, etc.)
- `macupdate`: Daily/weekly (updates packages and system)
- `macrun`: Run individual post-provision tasks

### Running Individual Tasks

```bash
# Run individual post-provision tasks without sudo issues
./scripts/macrun printers   # Configure printers
./scripts/macrun fonts      # Install fonts
./scripts/macrun k8s        # Setup Kubernetes tools
./scripts/macrun gpg        # Configure GPG

# List all available tasks
./scripts/macrun

# With additional options (dry-run, verbose, etc.)
./scripts/macrun printers --check
./scripts/macrun printers -vv
```

**When to use**: When you need to run a specific post-provision task (like printer configuration) without running the entire playbook. This is especially useful when `./scripts/macapply --tags post` causes sudo issues with other tasks.

**Available tasks**: Run `./scripts/macrun` without arguments to see the full list.

### Manual Playbook Execution

```bash
# Run specific playbook for current host
ansible-playbook plays/update.yml -i inventories -l $(hostname) --connection=local

# Run for specific host
ansible-playbook plays/update.yml -i inventories -l odin --connection=local

# Run with specific tags
ansible-playbook main.yml -i inventories -l $(hostname) --connection=local --tags "homebrew,dotfiles"

# Available tags: dotfiles, homebrew, mas, dock, osx, fonts, extra-packages, post
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
- **inventories/group_vars/macs/fonts.yml**: Font management configuration (common, private, licensed)
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

- **fonts.yml**: Font installation (common, private, licensed fonts)
- **k8s.yml**: Kubernetes tool setup (kubectl, krew plugins)
- **printers.yml**: Printer installation and configuration using CUPS/lpadmin
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

## Font Management

This repository includes a three-tier font management system:

**1. Common Fonts** (`files/fonts/common/`)
- Installed on ALL Macs (business + private)
- Committed to git (free/open-source fonts only)
- Applied with: `./scripts/macapply --tags fonts`

**2. Private Fonts** (`files/fonts/private/`)
- Installed on private Macs only (odin, thor)
- Committed to git (free/open-source fonts only)
- Applied with: `./scripts/macapply --tags fonts`

**3. Licensed Fonts** (`~/iCloudDrive/Allgemein/fonts/licensed/`)
- Installed on private Macs only
- NOT committed to git (in `.gitignore`)
- Stored in iCloud Drive for syncing
- For fonts that cannot be redistributed

**Configuration**: `inventories/group_vars/macs/fonts.yml`

**Documentation**: See `files/fonts/README.md` for complete details

**Supported formats**: `.ttf`, `.otf` (both cases)

## Printer Management

This repository includes automated printer installation and configuration using CUPS/lpadmin.

**Configuration Files**:
- **inventories/group_vars/macs/printers.yml**: Base printer configuration for all Macs
- **inventories/group_vars/business_mac/printers.yml**: Business-specific printers (extends base config)
- **inventories/group_vars/private_mac/printers.yml**: Private-specific printers (if needed)

**Task Implementation**: `tasks/post/printers.yml`

**How It Works**:
1. Printers are defined in the `printers` list in inventory group_vars
2. Each printer configuration includes:
   - `name`: Printer name in CUPS
   - `uri`: Device URI (e.g., `dnssd://...` for AirPrint, `lpd://...` for LPD)
   - `description`: Human-readable description (optional)
   - `location`: Physical location (optional)
   - `ppd`: Path to PPD file (required for non-AirPrint printers)
   - `state`: `present` or `absent` (default: `present`)
   - `default`: Set as default printer (default: `false`)
   - `enabled`: Enable printer after adding (default: `true`)
   - `options`: Dictionary of printer options (e.g., `CNDuplex: DuplexFront`)

**Example Configuration**:
```yaml
configure_printers: true

printers:
  - name: canon_drucker
    uri: "dnssd://canon-drucker._ipps._tcp.local./?uuid=..."
    description: "Canon MF642C/643C/644C"
    location: "Arbeitszimmer"
    state: present
    default: true
    options:
      CNDuplex: DuplexFront
      PageSize: A4

  - name: Follow2Print
    uri: "lpd://{{ follow2print_username }}@10.129.217.220/Follow2Print"
    ppd: "/Library/Printers/PPDs/Contents/Resources/TA4008ci.PPD"
    state: present
    default: false
    options:
      printer-is-shared: "false"
```

**Application**:
```bash
# Recommended: Run individual printer task
./scripts/macrun printers

# Or apply via full playbook
./scripts/macapply

# Or run all post-provision tasks
./scripts/macapply --tags post
```

**Idempotency**:
- Tasks are idempotent and only report changes when actual modifications occur
- New printers are marked as "changed"
- Existing printer updates, option changes, and enable/accept operations run without reporting changes (since CUPS commands don't indicate if changes were made)
- Default printer is only changed if different from current default

**Notes**:
- Printers run during the 'post' tag phase via `tasks/post/printers.yml`
- The task uses `lpadmin` for printer management and requires sudo
- Use `./scripts/macrun printers` to avoid sudo issues when running tasks individually
- For pull-printing systems (like Follow2Print), the username in the URI is for job assignment, not authentication
- AirPrint/DNS-SD printers are auto-discovered and don't require PPD files

## Workflow Notes

- The `macupdate` script is the primary maintenance tool - it orchestrates the entire update process
- Temporary passwordless sudo is automatically configured during playbook runs and removed afterward
- Configuration changes should be made in the appropriate inventory file level (not in playbooks directly)
- For new Macs: add hostname to `inventories/macs.list` and create corresponding host_vars file
- The homebrew role comes from the `geerlingguy.mac` collection (v4.0.1)

## Documentation & Task Tracking

When starting a new session, Claude should read these files:

- **docs/sessions/SESSION_STATUS.md**: Current session status, what was done, what's next
- **docs/TODO.md**: Long-term tasks that span multiple sessions
- **docs/analysis/IMPROVEMENTS.md**: All identified code quality issues (64 remaining: 21 HIGH + 41 MEDIUM + 2 LOW)
- **docs/analysis/REPOSITORY_REVIEW.md**: Comprehensive architecture review and recommendations (2025-12-22)

**Key Documentation**:
- **docs/WORKFLOWS.md**: Complete guide for all workflows (init, apply, update)
- **docs/NEW_MAC_SETUP.md**: Step-by-step guide for setting up a new Mac
- **CLAUDE.md** (this file): AI assistant context and repository overview

**Purpose**:
- `SESSION_STATUS.md`: Session-specific progress tracking
- `TODO.md`: General tasks, ideas, maintenance items
- `IMPROVEMENTS.md`: Technical debt and code quality improvements
- `REPOSITORY_REVIEW.md`: Architecture analysis and prioritized improvement recommendations
- `WORKFLOWS.md`: When to use init.sh vs macapply vs macupdate
- `NEW_MAC_SETUP.md`: Prerequisites and steps for bootstrapping a new Mac

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
