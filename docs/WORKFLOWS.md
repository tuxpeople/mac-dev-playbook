---
# Mac Dev Playbook Workflows

This document explains the different workflows and when to use which script/playbook.
---

## Overview: Three Different Scenarios

```
┌─────────────────────────────────────────────────────────────────┐
│ SCENARIO 1: Brand New Mac (Once per Mac)                        │
│ ────────────────────────────────────────────────────────────────│
│ Use: init.sh                                                     │
│ Purpose: Bootstrap a completely fresh Mac from scratch          │
│ Prerequisites: None (runs before anything else)                 │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ SCENARIO 2: Configuration Changes (As needed)                   │
│ ────────────────────────────────────────────────────────────────│
│ Use: macapply                                                    │
│ Purpose: Apply configuration changes to existing Mac            │
│ Prerequisites: Ansible already installed (via macupdate/init)   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ SCENARIO 3: Daily Updates (Daily/Weekly)                        │
│ ────────────────────────────────────────────────────────────────│
│ Use: macupdate                                                   │
│ Purpose: Keep Mac up-to-date (brew, system, etc.)              │
│ Prerequisites: Ansible already installed (via init or previous) │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ SCENARIO 4: Run Individual Task (As needed)                     │
│ ────────────────────────────────────────────────────────────────│
│ Use: macrun <task_name>                                          │
│ Purpose: Run a specific post-provision task                     │
│ Prerequisites: Ansible already installed (via macupdate/init)   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Scenario 1: Brand New Mac Setup

**When**: You got a new Mac or did a clean macOS install

**Overview**: The setup is split into 3 phases for better reliability:

### Phase 1: Bootstrap (Automated)

**Script**: `init.sh`

**What it does**:

1. Runs pre-flight checks (admin, internet, disk space)
2. Installs Xcode Command Line Tools (if needed)
3. Clones this repository to `/tmp/git`
4. Installs Python and Ansible (system Python)
5. Installs Ansible Galaxy requirements
6. Configures system limits (max files/processes)
7. Sets hostname
8. Creates ~/iCloudDrive symlink
9. Runs `plays/bootstrap.yml`:
   - Installs Homebrew
   - Installs essential CLI tools (git, bash, jq, node)
   - Installs 1Password app

**How to run**:

```bash
# From a fresh Mac (Terminal.app, not iTerm2)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tuxpeople/mac-dev-playbook/master/init.sh)"
```

**Duration**: 30-45 minutes

**Important**:

- You must create `inventories/host_vars/<hostname>.yml` BEFORE running this
- NO vault password, iCloud sync, or 1Password login required
- Ultra-robust - cannot fail due to external dependencies

### Phase 2: Manual Setup (User-controlled)

**What to do**:

1. **Open 1Password** (installed in Phase 1) and **sign in**
2. **Wait for iCloud Drive to sync** (optional, if you use iCloud)
3. **Add vault password to keychain**:

   ```bash
   ~/iCloudDrive/Allgemein/bin/add_vault_password
   ```

**Duration**: 5-10 minutes

### Phase 3: Full Configuration (Automated)

**Script**: `macapply`

**What it does**:

1. Runs `plays/full.yml` with all dependencies available
2. Installs all Brewfile packages (hundreds of apps)
3. Configures dotfiles (with SSH keys from iCloud)
4. Configures Hazel (with license from 1Password)
5. Applies Dock settings, macOS settings, fonts
6. Clones GitHub repositories
7. Runs all post-provision tasks

**How to run**:

```bash
cd /tmp/git
./scripts/macapply
```

**Duration**: 20-30 minutes

**Total Time**: ~60-90 minutes (mostly automated)

**Frequency**: Once per Mac (or after clean install)

**See**: [docs/NEW_MAC_SETUP.md](NEW_MAC_SETUP.md) for detailed step-by-step guide

---

## Scenario 2: Configuration Changes

**When**: You made configuration changes and want to apply them

### Examples of Configuration Changes

- Added a new Homebrew package to `brew.yml`
- Changed Dock settings in `dock.yml`
- Updated dotfiles configuration
- Added new post-provision tasks
- Changed macOS settings in `tasks/osx.yml`
- Added new fonts
- Changed terminal settings

**Script**: `macapply`

**What it does**:

1. Activates the pyenv virtualenv (mac-dev-playbook-venv)
2. Runs `plays/full.yml` on the current Mac
3. Applies all configuration (or specific tags)

**How to run**:

```bash
# Full configuration apply
macapply

# Only specific parts (using tags)
macapply --tags homebrew     # Only Homebrew packages
macapply --tags dotfiles     # Only dotfiles
macapply --tags dock         # Only Dock configuration
macapply --tags osx          # Only macOS settings
macapply --tags post         # Only post-provision tasks

# Multiple tags
macapply --tags homebrew,dotfiles,dock

# Dry run (see what would change without changing)
macapply --check --diff

# Verbose output
macapply -v
macapply -vv   # More verbose
macapply -vvv  # Very verbose
```

**Available tags**:

- `homebrew` - Homebrew packages and casks
- `dotfiles` - Dotfiles synchronization
- `mas` - Mac App Store apps (if enabled)
- `dock` - Dock configuration
- `sudoers` - Sudoers configuration
- `terminal` - Terminal settings
- `osx` - macOS system settings
- `fonts` - Font installation
- `extra-packages` - Extra packages (composer, gem, npm, pip)
- `sublime-text` - Sublime Text configuration
- `post` - Post-provision tasks

**Duration**: 5-30 minutes (depending on what changed)

**Frequency**: Whenever you change configuration

### Common Workflows

#### Adding a new Homebrew package

```bash
# 1. Edit configuration
vim inventories/group_vars/macs/brew.yml
# Add package to homebrew_installed_packages or homebrew_cask_apps

# 2. Apply only Homebrew changes
macapply --tags homebrew

# 3. Verify
brew list | grep your-package
```

#### Changing Dock configuration

```bash
# 1. Edit configuration
vim inventories/group_vars/macs/dock.yml
# Modify dockitems_persist or dockitems_remove

# 2. Apply only Dock changes
macapply --tags dock

# 3. Dock will restart automatically
```

#### Updating all configuration

```bash
# Pull latest changes from git
cd ~/development/github/tuxpeople/mac-dev-playbook
git pull

# Apply everything
macapply

# Or dry run first to see what will change
macapply --check --diff
```

---

## Scenario 3: Daily Updates

**When**: Regular maintenance (daily or weekly)

**Script**: `macupdate`

**What it does**:

1. Ensures pyenv and mise are installed
2. Sets up Python environment (pyenv + virtualenv)
3. Updates git repository
4. Installs/updates Python requirements
5. Installs/updates Ansible Galaxy requirements
6. Runs `plays/update.yml` which:
   - Updates Homebrew packages
   - Updates Homebrew casks
   - Runs macOS software updates
   - Updates Microsoft apps (if enabled)
   - Updates kubectl (if enabled)
   - Updates SSH/GPG keys (if enabled)
   - Syncs dotfiles
   - Runs Munki updates (if enabled)
   - Updates Node.js via nvm (if enabled)

**How to run**:

```bash
# Option 1: From repo
cd ~/development/github/tuxpeople/mac-dev-playbook
./scripts/macupdate

# Option 2: Create symlink (recommended, do once)
ln -sf ~/development/github/tuxpeople/mac-dev-playbook/scripts/macupdate \
       ~/iCloudDrive/Allgemein/bin/macupdate

# Then run from anywhere
macupdate
```

**Duration**: 5-15 minutes

**Frequency**: Daily or weekly

**Note**: This does NOT apply configuration changes. For that, use `macapply`.

---

## Scenario 4: Running Individual Tasks

**When**: You need to run a specific post-provision task without running the entire playbook

**Script**: `macrun`

**Why it exists**:

- Avoids sudo permission issues when running `macapply --tags post`
- Faster than running full playbook
- Cleaner output for debugging specific tasks
- Automatically handles sudo setup/cleanup

**What it does**:

1. Sets up temporary passwordless sudo
2. Runs the specified post-provision task from `tasks/post/`
3. Cleans up sudo permissions automatically (even on failure)

**How to run**:

```bash
# List all available tasks
macrun

# Run specific tasks
macrun printers    # Configure printers
macrun fonts       # Install fonts
macrun k8s         # Setup Kubernetes tools
macrun gpg         # Configure GPG
macrun vscode      # Setup VS Code

# With options
macrun printers --check       # Dry run
macrun printers -vv           # Verbose output
macrun printers --check -vv   # Dry run + verbose
```

**Available tasks**:
Run `macrun` without arguments to see the complete list of available tasks from `tasks/post/`.

**Duration**: 1-5 minutes (depends on task)

**Frequency**: As needed (e.g., after changing printer configuration)

### Common Use Cases

#### Configure printers after config change

```bash
# 1. Edit printer configuration
vim inventories/group_vars/macs/printers.yml
# Add or modify printer

# 2. Run only printer task
macrun printers

# 3. Verify
lpstat -p -d
```

#### Install fonts after adding new fonts

```bash
# 1. Add font files to files/fonts/common/ or files/fonts/private/
cp ~/Downloads/MyFont.ttf files/fonts/common/

# 2. Run only font task
macrun fonts

# 3. Fonts are installed and cache is rebuilt
```

#### Setup Kubernetes tools on new environment

```bash
# Configure kubectl and install krew plugins
macrun k8s
```

**When to use macrun vs macapply**:

| Use Case                        | Use                    | Why                            |
| ------------------------------- | ---------------------- | ------------------------------ |
| Single task after config change | `macrun <task>`        | Faster, cleaner output         |
| Multiple tasks                  | `macapply --tags post` | More efficient                 |
| Full configuration apply        | `macapply`             | Updates everything             |
| Debugging a specific task       | `macrun <task> -vv`    | Easier to see what's happening |
| Sudo permission issues          | `macrun <task>`        | Handles sudo automatically     |

---

## Decision Tree: Which Script Should I Use?

```
Start
  │
  ├─ Is this a brand new Mac (or clean install)?
  │  └─ YES → Use init.sh (one time only)
  │  └─ NO  → Continue ↓
  │
  ├─ Did I change configuration files (brew.yml, dock.yml, etc.)?
  │  └─ YES → Continue ↓
  │     │
  │     ├─ Is it a single post-provision task (printers, fonts, etc.)?
  │     │  └─ YES → Use macrun <task> (faster)
  │     │  └─ NO  → Use macapply (full config)
  │     │
  │  └─ NO  → Continue ↓
  │
  └─ Do I want to update packages/system?
     └─ YES → Use macupdate (daily updates)
     └─ NO  → No action needed
```

---

## Quick Reference

| What do you want?        | Use this                   | Example                       |
| ------------------------ | -------------------------- | ----------------------------- |
| Set up a brand new Mac   | `init.sh`                  | `curl ... \| bash`            |
| Add a Homebrew package   | `macapply --tags homebrew` | After editing `brew.yml`      |
| Change Dock layout       | `macapply --tags dock`     | After editing `dock.yml`      |
| Update macOS settings    | `macapply --tags osx`      | After editing `tasks/osx.yml` |
| Apply all config changes | `macapply`                 | After editing multiple files  |
| Configure printers       | `macrun printers`          | After editing `printers.yml`  |
| Install fonts            | `macrun fonts`             | After adding font files       |
| Run any single post-task | `macrun <task>`            | See `macrun` for list         |
| Update Homebrew packages | `macupdate`                | Daily/weekly maintenance      |
| Update macOS system      | `macupdate`                | Daily/weekly maintenance      |
| See what would change    | `macapply --check --diff`  | Before applying               |

---

## Important Notes

### init.sh vs macapply

**DO NOT run init.sh after initial setup!**

- `init.sh` clones repo to `/tmp/git` (temporary location)
- `init.sh` installs Homebrew again (unnecessary)
- `init.sh` installs Ansible again (unnecessary)
- `init.sh` is only for COMPLETELY FRESH Macs

**For configuration changes, always use macapply**

### macapply vs macupdate

**They serve different purposes:**

| Feature        | macapply                      | macupdate                 |
| -------------- | ----------------------------- | ------------------------- |
| Playbook       | `plays/full.yml`              | `plays/update.yml`        |
| Purpose        | Apply configuration           | Update packages/system    |
| When           | After config changes          | Daily/weekly              |
| Homebrew       | Installs packages from config | Updates existing packages |
| macOS Settings | Applies osx.yml settings      | Doesn't change settings   |
| Dotfiles       | Syncs from repo               | Syncs from repo           |
| Duration       | 5-30 min                      | 5-15 min                  |

**You might need both:**

```bash
# 1. Make config change
vim inventories/group_vars/macs/brew.yml  # Add new package

# 2. Apply the change
macapply --tags homebrew

# 3. Later, update packages
macupdate  # Updates the package you just installed
```

---

## Advanced Usage

### Testing Configuration Before Applying

Always a good idea before major changes:

```bash
# See what would change
macapply --check --diff

# If it looks good, apply for real
macapply
```

### Applying Partial Configuration

Instead of running the full playbook, target specific areas:

```bash
# Only configuration
macapply --tags dotfiles,osx,terminal

# Only packages
macapply --tags homebrew,mas

# Everything except certain tags
macapply --skip-tags mas,sublime-text
```

### Verbose Output for Debugging

```bash
macapply -v      # Show task names
macapply -vv     # Show task names and results
macapply -vvv    # Show everything (debug level)
```

---

## Troubleshooting

### "ansible-playbook: command not found"

You need to set up the Python environment first:

```bash
# Run macupdate once to set up environment
macupdate
```

### "No host configuration found"

You need to create `inventories/host_vars/<hostname>.yml`:

```bash
# Use helper script
./scripts/create-host-config.sh $(hostname -s)

# Or copy template
cp inventories/host_vars/TEMPLATE.yml inventories/host_vars/$(hostname -s).yml
# Edit and encrypt password
```

### "Vault password incorrect"

Make sure you have the vault password file or know the password:

```bash
# Check if file exists
ls ${HOME}/Library/Mobile\ Documents/com~apple~CloudDocs/Dateien/Allgemein/bin/vault_password_file

# If not, you'll be prompted (or specify different file)
macapply --vault-password-file=/path/to/vault_password
```

### Changes not taking effect

Make sure you:

1. Saved your configuration changes
2. Used the right tags (or no tags for full run)
3. Check for errors in the Ansible output

---

## See Also

- [NEW_MAC_SETUP.md](NEW_MAC_SETUP.md) - Complete guide for setting up a new Mac
- [REPOSITORY_REVIEW.md](analysis/REPOSITORY_REVIEW.md) - Architecture review and recommendations
- [CLAUDE.md](../CLAUDE.md) - AI assistant context and repository overview
- [TODO.md](TODO.md) - Known issues and future improvements
