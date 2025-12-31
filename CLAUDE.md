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

**plays/bootstrap.yml**: Minimal Phase 1 bootstrap playbook (NEW as of 2025-12-25)

- NO external dependencies (no vault password, no iCloud, no 1Password login)
- Installs Homebrew + essential CLI tools (git, bash, jq, node) + 1Password app
- Uses `homebrew_use_brewfile: false` (only installs packages from group_vars)
- Creates ~/iCloudDrive symlink (with ignore_errors if not synced)
- Purpose: Get Mac "Ansible-ready" with minimal tooling
- Called by init.sh (Phase 1), followed by manual 1Password setup (Phase 2), then macapply (Phase 3)

**plays/full.yml**: Complete provisioning with all dependencies (Phase 3)

- Requires vault password (from keychain), 1Password login, iCloud sync
- Sets up temporary passwordless sudo for automation
- Installs Rosetta 2 for Apple Silicon Macs
- Includes SSH key setup and additional pre-tasks
- Runs post-provision tasks from `post_provision_tasks` glob
- Uses `homebrew_use_brewfile: true` (installs packages from group_vars + Brewfile)
- Called by macapply script after bootstrap and manual setup

**plays/update.yml**: Daily update/maintenance playbook

- Focused on updates (brew, cask, Microsoft, kubectl, GPG)
- Runs custom roles: `ansible-mac-update`, `munki_update`, `ansible-role-nvm`
- Uses environment variable `env_path` for proper PATH setup
- Manages temporary sudo permissions automatically
- Called by macupdate script

**main.yml**: Legacy simple provisioning (deprecated, use bootstrap.yml + full.yml instead)

- Uses `default.config.yml` for configuration
- Runs all standard roles (homebrew, mas, dotfiles, dock, etc.)

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

### Initial Setup (Brand New Mac) - 3 Phases

**Phase 1 - Bootstrap (Automated):**

```bash
# Run init.sh - installs Homebrew, Ansible, essential tools, 1Password app
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tuxpeople/mac-dev-playbook/master/init.sh)"

# Prerequisites: Create inventories/host_vars/<hostname>.yml BEFORE running
# NO vault password, iCloud sync, or 1Password login required for Phase 1
```

**Phase 2 - Manual Setup (2-5 min):**

1. Open 1Password and sign in
2. Wait for iCloud Drive to sync (optional)

Vault password is automatically read from 1Password in Phase 3.

**Phase 3 - Full Configuration (Automated):**

```bash
cd /tmp/git
./scripts/macapply  # Runs plays/full.yml with all dependencies
```

**See**: [docs/NEW_MAC_SETUP.md](docs/NEW_MAC_SETUP.md) for detailed step-by-step guide

### Configuration Changes (After Editing Config Files)

```bash
# Apply all configuration changes
./scripts/macapply

# Or apply only specific parts (faster)
./scripts/macapply --tags homebrew       # Homebrew packages
./scripts/macapply --tags dotfiles       # Dotfiles sync
./scripts/macapply --tags dock           # Dock configuration
./scripts/macapply --tags finder         # Finder settings
./scripts/macapply --tags system         # System settings (Touch ID, SSH, wallpaper)
./scripts/macapply --tags maintenance    # Maintenance tasks
./scripts/macapply --tags osx            # macOS settings
./scripts/macapply --tags fonts          # Font installation
./scripts/macapply --tags extra-packages # Extra packages (npm, pip, gem, composer)
./scripts/macapply --tags post           # Post-provision tasks (all custom tasks)

# Dry run (see what would change)
./scripts/macapply --check --diff

# Available tags (complete list):
# - homebrew: Homebrew packages from group_vars and Brewfiles
# - dotfiles: Sync dotfiles repository
# - dock: Dock configuration (dockitems)
# - finder: Finder settings
# - system: System settings (Touch ID, SSH, wallpaper)
# - launchagents: LaunchAgents/Daemons management (disable unwanted agents)
# - maintenance: Maintenance tasks
# - osx: macOS defaults and settings
# - fonts: Font installation (common, private, licensed)
# - extra-packages: Extra packages (npm, pip, gem, composer)
# - post: All post-provision tasks (includes finder, system, launchagents, maintenance, and custom tasks)
# - mas: Mac App Store apps (CURRENTLY DISABLED - see plays/full.yml comments)
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

# Available tags: dotfiles, homebrew, mas, dock, osx, fonts, extra-packages, launchagents, post
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

## Business Mac App Deployment

This repository supports deploying custom apps to business Macs from iCloudDrive. This is useful for Safari web apps, internal tools, or apps not available via Homebrew.

### Overview

**Configuration**: `tasks/post/business_mac-settings.yml`

**Storage Location**: `~/iCloudDrive/Allgemein/apps/`

**Deployment Target**: `/Applications/`

### Current Apps

Two Safari web apps are deployed to business Macs:

1. **Open Umb.app** - UMB web application (Position 1 in Dock)
2. **Vertec.app** - Vertec time tracking (Position 3 in Dock)

### How It Works

The deployment process:

```yaml
- name: Copy business apps from iCloudDrive
  ansible.builtin.command:
    cmd: cp -R "{{myhomedir}}/iCloudDrive/Allgemein/apps/{{ business_app }}" "/Applications/"
  loop:
    - "Open Umb.app"
    - "Vertec.app"
  loop_control:
    loop_var: business_app
  args:
    creates: "/Applications/{{ business_app }}"  # Make idempotent
```

### Adding a New Business App

1. **Save the app to iCloudDrive**:

   ```bash
   # For Safari web apps: File > Add to Dock
   # Then move the .app from Applications to iCloudDrive
   mv "/Applications/Your App.app" ~/iCloudDrive/Allgemein/apps/
   ```

2. **Add to deployment list** in `tasks/post/business_mac-settings.yml`:

   ```yaml
   loop:
     - "Open Umb.app"
     - "Vertec.app"
     - "Your App.app"  # Add your new app
   ```

3. **Add to Dock** (optional) in `inventories/group_vars/business_mac/dock.yml`:

   ```yaml
   - name: "Your App"
     path: "\"/Applications/Your App.app\""
     pos: 4  # Choose position
   ```

4. **Apply configuration**:

   ```bash
   ./scripts/macapply
   ```

### Why This Approach?

**Advantages**:

- Apps sync automatically via iCloudDrive to all business Macs
- Works for Safari web apps (not in Homebrew)
- Works for internal/proprietary apps
- Version controlled via git (deployment config)
- Single source of truth (iCloudDrive)

**When to Use**:

- Safari web apps (company intranets, web tools)
- Internal company apps not in Homebrew
- Licensed apps stored in iCloudDrive

**When NOT to Use**:

- Apps available in Homebrew → Use Brewfile instead
- Apps in Mac App Store → Use mas_installed_apps (if enabled)
- Universal apps for all Macs → Add to general homebrew packages

### Notes

- Safari web apps are regular `.app` bundles and work like native apps
- Deployment uses `cp -R` instead of `ansible.builtin.copy` for proper .app bundle handling
- Task is idempotent via `creates` parameter - only copies if app doesn't exist
- Deployment runs during business_mac-settings tasks
- iCloudDrive must be mounted and synced before deployment

## Business Mac Login Items Management

This repository automatically removes unwanted Login Items on business Macs to reduce startup clutter and improve boot performance.

### Overview

**Configuration**: `inventories/group_vars/business_mac/login_items.yml`

**Task Implementation**: `tasks/post/business_mac-settings.yml`

**Execution**: Runs during post-provision phase (`--tags post`)

### How It Works

1. Gets current Login Items via osascript (System Events)
2. Checks if unwanted items are present
3. Removes them automatically

```yaml
login_items_to_remove:
  - "Microsoft SharePoint"  # Not needed at startup
  - "Rambox"                # Used occasionally, doesn't need auto-start
```

### Login Items Kept

These apps remain in Login Items (required for functionality):

- **DisplayLink Manager** - Docking station support
- **OneDrive** - File synchronization
- **Jabra Direct** - Headset support
- **Fokus arbeiten** - Apple Shortcuts automation for Focus mode
- **Magnet** - Window manager

### Adding Items to Remove

1. **Edit configuration** in `inventories/group_vars/business_mac/login_items.yml`:

   ```yaml
   login_items_to_remove:
     - "Microsoft SharePoint"
     - "Rambox"
     - "Your Unwanted App"  # Add new item
   ```

2. **Apply configuration**:

   ```bash
   ./scripts/macapply --tags post
   # Or for full apply
   ./scripts/macapply
   ```

### Manual Verification

Check current Login Items:

```bash
osascript -e 'tell application "System Events" to get the name of every login item'
```

Or via System Settings:

- System Settings → General → Login Items

### Notes

- Task is idempotent - only removes items that exist
- Uses osascript for reliable cross-version compatibility
- Fails gracefully if System Events is not accessible
- Items can be manually re-added in System Settings if needed

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

**Pre-commit hooks are configured and run automatically on every commit.**

### Automated Checks (via pre-commit)

Pre-commit hooks are installed and will run automatically before each commit:

```bash
# Pre-commit runs automatically on: git commit

# Manual run on all files:
pre-commit run --all-files

# Update hook versions:
pre-commit autoupdate
```

**Active Hooks:**

- ✅ yamllint (YAML syntax/style)
- ✅ ansible-lint (Ansible best practices, optional)
- ✅ shellcheck (Shell script linting)
- ✅ markdownlint (Markdown formatting)
- ✅ trailing-whitespace (auto-fix)
- ✅ end-of-file-fixer (auto-fix)
- ✅ check-yaml, check-merge-conflict, check-case-conflict, etc.

**Configuration:**

- `.pre-commit-config.yaml`: Hook configuration
- `.markdownlint.json`: Markdown rules (relaxed)

**Skip hooks (emergency only):**

```bash
git commit --no-verify -m "emergency fix"
```

### Manual Checks (Alternative)

If pre-commit is not available, run manually:

```bash
# Lint YAML files
yamllint .

# Lint Ansible playbooks (optional)
ansible-lint

# Lint shell scripts
shellcheck scripts/*.sh init*.sh tests/*.sh
```

## Ansible Best Practices

### Loop Variable Naming

**IMPORTANT**: Always use explicit `loop_var` names in `loop_control` to avoid variable collisions and improve code readability.

**Problem**: Using the default `item` variable can cause conflicts when:

- Loops are nested (e.g., within `vars` definitions)
- Multiple tasks reference each other
- Debugging complex playbooks

**Solution**: Always specify a descriptive `loop_var` name that reflects what you're iterating over.

**Good Examples**:

```yaml
# Printer configuration
- name: Add new printers
  ansible.builtin.command: lpadmin -p "{{ printer.name }}" ...
  loop: "{{ printers }}"
  loop_control:
    loop_var: printer

# Dock items
- name: Set the default Dock items
  shell: "/usr/local/bin/dockutil --add {{ dock_item.path }} ..."
  loop: "{{ dockitems }}"
  loop_control:
    loop_var: dock_item
    label: "{{ dock_item.name }}"

# Font files
- name: Install common fonts
  ansible.builtin.copy:
    src: "{{ font_file.path }}"
    dest: "{{ fonts_target_dir }}/{{ font_file.path | basename }}"
  loop: "{{ common_fonts_found.files }}"
  loop_control:
    loop_var: font_file
    label: "{{ font_file.path | basename }}"

# Configuration settings
- name: Set macOS default settings
  community.general.osx_defaults:
    domain: "{{ default_setting['domain'] }}"
    key: "{{ default_setting['key'] }}"
    value: "{{ default_setting['value'] }}"
  loop: "{{ defaults }}"
  loop_control:
    loop_var: default_setting
    label: "{{ default_setting['name'] }}"
```

**Bad Example** (causes warnings):

```yaml
# DON'T: Using default 'item' variable
- name: Add new printers
  ansible.builtin.command: lpadmin -p "{{ item.name }}" ...
  loop: "{{ printers }}"
  # No loop_control - will cause conflicts if nested loops exist
```

**When to Use**:

- Always use `loop_var` when iterating over complex objects
- Always use `loop_var` when there's any possibility of nesting
- Use descriptive names: `printer`, `dock_item`, `font_file`, `default_setting`, etc.
- Combine with `label` to keep output clean (shows only relevant info, not entire object)

**Benefits**:

- Prevents "loop variable collision" warnings
- Makes code self-documenting (clear what you're iterating over)
- Easier debugging (descriptive variable names in error messages)
- Future-proof (works even if loops become nested later)

## Recent Improvements

### init.sh Robustness (2025-12-25)

The init.sh bootstrap script has been significantly improved for fresh Mac setups:

**Problem Background**: During setup of new Mac "saga", 5 critical issues were encountered and initially fixed with workarounds. These have now been replaced with proper solutions.

**Key Improvements**:

1. **Restart-Resilient**: Script can be safely restarted if interrupted
   - Detects already-installed Xcode Command Line Tools
   - Automatically cleans up `/tmp/git` before cloning
   - Provides clear instructions if manual restart needed

2. **Python Version Flexibility**: Works with Python 3.9+ (System) and Python 3.11+ (pyenv)
   - `requirements.txt` uses flexible version ranges (`ansible>=9.0`)
   - pip automatically selects best version for available Python
   - Same requirements file works for both init.sh and macupdate

3. **Robust iCloud Downloads**: Handles missing files gracefully
   - Checks if `brctl` command is available
   - Timeouts prevent endless loops (60s for lists, 30s per file/folder)
   - Continues setup even if some iCloud files are missing
   - Clear warnings for skipped files

4. **Better Error Handling**: Non-critical errors don't stop setup
   - Keychain "already exists" errors are handled gracefully
   - add_vault_password script failures logged as warnings
   - Setup continues to completion when possible

5. **Improved UX**: Clear feedback and error messages
   - Step-by-step progress indicators
   - Specific error messages with solutions
   - Instructions for manual intervention when needed

**Impact**: Fresh Mac setups are now significantly more reliable and require less manual intervention.

**See Also**:

- **docs/NEW_MAC_SETUP.md**: Updated troubleshooting guide
- **docs/PYTHON_VERSION_MANAGEMENT.md**: Requirements.txt strategy explained
- **docs/sessions/SESSION_STATUS.md**: Session 4 details (2025-12-25)

### Vault Password Bootstrap & Python Optimization (2025-12-25)

Resolved chicken-egg problem with vault password script and optimized Python environment setup for faster macapply runs.

**Problem Background**: The vault password script (`~/bin/vault_password_mac_dev_playbook`) is deployed by `plays/full.yml`, but Ansible needs the script to decrypt secrets BEFORE running the playbook. Also, macapply was using full Python setup on every run (slow, unnecessary).

**Key Improvements**:

1. **Vault Password Bootstrap**: macapply creates the script if it doesn't exist
   - Reads 1Password reference from `inventories/group_vars/macs/onepassword.yml`
   - Generates script before running ansible-playbook
   - playbook later updates script from template (idempotent)
   - Flow: macapply creates → ansible runs → template updates → subsequent runs use template version

2. **Python Setup Optimization**: macapply uses lightweight environment activation
   - Old: `full_python_setup` (install Python, create venv, install requirements)
   - New: `setup_python_env` (just activate existing venv)
   - Use `macupdate` for full environment setup/updates
   - macapply is for frequent config changes → should be fast

3. **Clear Separation of Concerns**:
   - `init.sh`: Bootstrap with system Python (once per Mac)
   - `macupdate`: Full pyenv environment setup/maintenance (weekly)
   - `macapply`: Lightweight activation + config application (after changes)

**Architecture**: Vault Password Flow

```
macapply bootstrap → ~/bin/vault_password_mac_dev_playbook
                  ↓
ansible.cfg (vault_password_file) → script → op read → 1Password
                  ↓
plays/full.yml template → updates script (idempotent)
```

**Impact**:

- macapply works on first run (no "vault password file not found" error)
- macapply runs faster (no unnecessary Python reinstalls)
- Clean bootstrap mechanism (no manual intervention needed)

**Related Commits**:

- f3d15ab: Template-based vault password script with ansible.cfg integration
- 3955b0e: Vault password bootstrap and Python optimization

### Init.sh Vault Password Fix (2025-12-26)

Resolved chicken-egg problem in fresh Mac setup where ansible.cfg references vault_password_file before secrets can be decrypted.

**Problem**: On fresh Macs during Phase 1 (init.sh → plays/bootstrap.yml):

- ansible.cfg references `vault_password_file = ~/bin/vault_password_mac_dev_playbook`
- 1Password isn't set up yet, so vault password isn't available
- Ansible tries to decrypt `inventories/group_vars/macs/secrets.yml`
- Error: "Decryption failed (no vault secrets were found that could decrypt)"

**Solution Evolution** (5 iterations):

1. **Dummy vault password file** (af76019, c27aa77) - Didn't work
   - Created dummy script returning placeholder password
   - Failed: Ansible still tried to decrypt secrets.yml with wrong password

2. **Separate plays/ansible.cfg** (68b5637) - Didn't work
   - Created duplicate ansible.cfg without vault_password_file
   - Failed: Ansible still tried to decrypt secrets.yml

3. **Temporary sed edit** (f3de506) - Didn't work
   - `sed` removes vault_password_file line temporarily
   - Failed: Ansible still tried to decrypt secrets.yml

4. **--vault-password-file=/dev/null** (3d640b7) - Didn't work
   - Command-line option overrides ansible.cfg
   - Failed: "ERROR! Attempting to decrypt but no vault secrets found"

5. **Temporarily hide secrets.yml** (90c1912) - Almost there!
   - `mv secrets.yml → secrets.yml.bootstrap_disabled`
   - Run bootstrap.yml (no encrypted file found)
   - `mv secrets.yml.bootstrap_disabled → secrets.yml` (restore)
   - **Root cause**: Ansible ALWAYS loads all group_vars, and if encrypted file exists, it MUST decrypt
   - Only solution: Make the file not exist temporarily
   - But: Also found encrypted `ansible_become_pass` in host_vars!

6. **Hide all vault files + interactive sudo** (38591ce) - Final solution ✅
   - Hide both `secrets.yml` AND `host_vars/{hostname}.yml`
   - Use `--ask-become-pass` for interactive sudo password
   - Restore both files after bootstrap completes
   - Handles ALL vault-encrypted files in inventory
   - Interactive sudo password is acceptable for Phase 1 (fresh Mac setup)

**Final Flow**:

```
init.sh: hide secrets.yml + host_vars → bootstrap.yml --ask-become-pass → restore files
         (Phase 1)                      (no encrypted files, interactive sudo) (cleanup)
                                                ↓
macapply: Creates real vault password script → plays/full.yml
          (Phase 3)                             (with all secrets from vault)
```

**Impact**:

- Fresh Mac setup works without vault/decryption errors
- No duplicate config files to maintain
- Single source of truth (root ansible.cfg)
- Clean, simple solution

**Related Commits**:

- af76019: Initial dummy password approach (didn't work)
- c27aa77: Simplified dummy handling (didn't work)
- 68b5637: Separate ansible.cfg approach (didn't work)
- f3de506: Temporary sed edit approach (didn't work)
- 3d640b7: --vault-password-file=/dev/null (didn't work)
- 90c1912: Hide secrets.yml (almost - missed host_vars!)
- 38591ce: Final solution - hide all vault files + interactive sudo ✅

**Lesson learned**: Ansible behavior with vault-encrypted files (both group_vars AND host_vars) is non-negotiable - if the file exists, Ansible will try to decrypt it. The only reliable solution is to temporarily remove ALL vault-encrypted files and use interactive prompts for sensitive data during bootstrap.
