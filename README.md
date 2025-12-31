<img src="https://raw.githubusercontent.com/geerlingguy/mac-dev-playbook/master/files/Mac-Dev-Playbook-Logo.png" width="250" height="156" alt="Mac Dev Playbook Logo" />

# Mac Development Ansible Playbook

[![CI][badge-gh-actions]][link-gh-actions]

> **Note**: This repository was originally forked from [geerlingguy/mac-dev-playbook](https://github.com/geerlingguy/mac-dev-playbook) (last sync: June 26, 2024, commit [358f663](https://github.com/geerlingguy/mac-dev-playbook/commit/358f663)).
>
> **This fork has significantly diverged** (~289 commits ahead) with custom features for managing multiple Macs (business/private). It is maintained independently and does not merge upstream changes. See [Key Differences](#key-differences-from-upstream) below.

This playbook installs and configures software on multiple Macs for development and daily use. It supports managing both business and private Macs with different configurations through a hierarchical inventory system.

## Installation

### Fresh Mac Setup (Initial Installation)

For setting up a brand new Mac, the process is split into 3 phases:

**Phase 1 - Bootstrap (Automated):**

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tuxpeople/mac-dev-playbook/master/init.sh)"
```

This installs:

- Xcode Command Line Tools
- Homebrew
- Python and Ansible
- Essential CLI tools (git, bash, jq, node)
- 1Password app

**Phase 2 - Manual Setup (2-5 min):**

1. Open 1Password and sign in
2. Wait for iCloud Drive to sync (optional)

That's it! The Ansible vault password will be automatically read from 1Password in Phase 3.

**Phase 3 - Full Configuration (Automated):**

```bash
cd /tmp/git
./scripts/macapply
```

This completes the setup with dotfiles, Brewfile packages, system settings, and all configurations.

**Before running Phase 1**: Create `inventories/host_vars/<hostname>.yml` for your Mac. See [docs/NEW_MAC_SETUP.md](docs/NEW_MAC_SETUP.md) for complete step-by-step instructions.

### Applying Configuration Changes

After initial setup, use the `macapply` script to apply configuration changes:

```bash
# Apply all configuration changes
./scripts/macapply

# Apply only specific parts (faster)
./scripts/macapply --tags homebrew    # Homebrew packages
./scripts/macapply --tags dock        # Dock configuration
./scripts/macapply --tags osx         # macOS settings
./scripts/macapply --tags fonts       # Font installation
./scripts/macapply --tags dotfiles    # Dotfiles sync

# See CLAUDE.md for complete list of available tags

# Dry run (see what would change)
./scripts/macapply --check --diff
```

### Daily Updates

For daily maintenance (updates packages, system software, etc.):

```bash
./scripts/macupdate
```

> **For complete workflow documentation**, see [docs/WORKFLOWS.md](docs/WORKFLOWS.md).

### Use with a remote Mac

You can use this playbook to manage other Macs as well; the playbook doesn't even need to be run from a Mac at all! If you want to manage a remote Mac, either another Mac on your network, or a hosted Mac like the ones from [MacStadium](https://www.macstadium.com), you just need to make sure you can connect to it with SSH:

  1. (On the Mac you want to connect to:) Go to System Preferences > Sharing.
  2. Enable 'Remote Login'.

> You can also enable remote login on the command line:
>
> ```bash
> sudo systemsetup -setremotelogin on
> ```

Then edit `inventories/macs.list` in this repository and add your Mac to the appropriate group:

```ini
[business_mac]
ws547 ansible_host=192.168.1.100 ansible_user=yourusername

[private_mac]
odin ansible_host=192.168.1.101 ansible_user=yourusername
```

Create a corresponding host_vars file at `inventories/host_vars/<hostname>.yml` with host-specific configuration.

If you need to supply an SSH password (if you don't use SSH keys), make sure to pass the `--ask-pass` parameter to the `ansible-playbook` command.

### Running a specific set of tagged tasks

You can filter which part of the provisioning process to run by specifying a set of tags. The easiest way is to use the `macapply` script:

```bash
./scripts/macapply --tags "dotfiles,homebrew"
```

**Available tags**: `homebrew`, `dotfiles`, `dock`, `finder`, `system`, `maintenance`, `osx`, `fonts`, `extra-packages`, `post`, `mas`

> **Note**: The `mas` tag is currently disabled in `plays/full.yml`
> **For complete tag descriptions**, see [CLAUDE.md](CLAUDE.md#configuration-changes-after-editing-config-files)

Alternatively, you can run the playbook directly:

```bash
ansible-playbook plays/full.yml -i inventories -l $(hostname) --connection=local --tags "dotfiles,homebrew"
```

## Configuration

This fork uses a **hierarchical inventory system** for managing multiple Macs with shared and specific configurations.

### Configuration Hierarchy

Configuration cascades from general → group → host-specific:

```
inventories/
├── group_vars/
│   ├── macs/              # Shared across ALL Macs
│   │   ├── brew.yml       # Common Homebrew packages
│   │   ├── dock.yml       # Default Dock configuration
│   │   ├── general.yml    # Core settings
│   │   └── ...
│   ├── business_mac/      # Business Mac overrides
│   │   ├── brew.yml       # Business-specific packages
│   │   ├── dock.yml       # Business Dock layout
│   │   └── main.yml
│   └── private_mac/       # Private Mac overrides
│       ├── brew.yml       # Private-specific packages
│       ├── dock.yml       # Private Dock layout
│       └── main.yml
└── host_vars/
    ├── odin.yml           # Host-specific (odin)
    ├── thor.yml           # Host-specific (thor)
    └── ws547.yml          # Host-specific (ws547)
```

### Customizing Packages

**Example**: Adding packages to business Macs only:

```yaml
# inventories/group_vars/business_mac/brew.yml
homebrew_installed_packages:
  - kubectl
  - terraform
  - azure-cli

homebrew_cask_apps:
  - microsoft-teams
  - slack
```

**Example**: Host-specific configuration:

```yaml
# inventories/host_vars/odin.yml
ansible_become_pass: !vault |
  $ANSIBLE_VAULT;1.1;AES256
  ...

configure_dock: true
dockitems_persist:
  - name: "iTerm"
    path: "/Applications/iTerm.app/"
    pos: 1
```

For a complete list of available variables, see [CLAUDE.md](CLAUDE.md#configuration-system).

## Installed Applications / Packages

This fork manages packages through **Brewfiles** organized by Mac group:

- **Business Macs**: `files/brewfile/business_mac/Brewfile`
- **Private Macs**: `files/brewfile/private_mac/Brewfile`

Each Brewfile contains:

- Homebrew packages (CLI tools)
- Homebrew casks (GUI applications)
- Mac App Store apps (via `mas`)

**To see what's installed on your Mac**, check the Brewfile for your group.

### Dotfiles

Dotfiles from [tuxpeople/dotfiles](https://github.com/tuxpeople/dotfiles) are installed into the current user's home directory. This includes:

- Shell configuration (.bashrc, .zshrc)
- Git configuration
- macOS settings (.macos)
- And more

You can disable dotfiles management by setting `configure_dotfiles: false` in your configuration.

### Additional Configuration

The playbook also configures:

- macOS system settings (Dock, Finder, etc.)
- Development tools (kubectl, Node.js via nvm, Python via pyenv)
- Application preferences (VSCode, iTerm2, etc.)
- LaunchAgents for automation

See [CLAUDE.md](CLAUDE.md) for complete documentation.

## Full / From-scratch setup guide

Complete step-by-step instructions for setting up a brand new Mac:

**[docs/NEW_MAC_SETUP.md](docs/NEW_MAC_SETUP.md)** - Comprehensive guide covering:

- Prerequisites (what you need before running init.sh)
- Bootstrap process (init.sh)
- Post-setup verification
- Troubleshooting

**[docs/WORKFLOWS.md](docs/WORKFLOWS.md)** - When to use which script:

- `init.sh` - Fresh Mac setup (once per Mac)
- `macapply` - Apply configuration changes
- `macupdate` - Daily/weekly maintenance

## Testing the Playbook

This fork includes CI/CD testing via GitHub Actions. The CI pipeline runs:

- `yamllint` - YAML syntax and formatting validation
- `ansible-lint` - Ansible best practices validation
- `shellcheck` - Shell script analysis
- Integration tests on macOS runners

You can also run macOS inside a VM for testing changes before applying to production Macs. Recommended virtualization tools:

- [UTM](https://mac.getutm.app) - Free, macOS native
- [Tart](https://github.com/cirruslabs/tart) - CLI-based VM management

**Before committing changes**, run the lint tools locally:

```bash
yamllint .
ansible-lint
shellcheck scripts/*.sh init*.sh
```

## Ansible for DevOps

Check out [Ansible for DevOps](https://www.ansiblefordevops.com/), which teaches you how to automate almost anything with Ansible.

## Documentation

This repository follows a **layered documentation approach**:

### Technical Documentation (This Repository)

**For setup, usage, and technical details:**

- **[README.md](README.md)** (this file) - Quick start and basic usage
- **[CLAUDE.md](CLAUDE.md)** - Complete technical reference for AI assistants
- **[DOCUMENTATION_STRATEGY.md](DOCUMENTATION_STRATEGY.md)** - Documentation architecture
- **[docs/](docs/)** - Extended documentation (installation, playbooks, roles, troubleshooting)

### Conceptual Documentation (Obsidian Vault)

**For concepts, context, and Homelab integration:**

Located in Obsidian Vault: `~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Personal/📚 Wissen/🏠 Persönlich/🎨 Hobbys/Homelab/Clients/macOS/`

**Key documents:**

- **README.md** - macOS Management Overview & Homelab Integration
- **Ansible-Playbooks.md** - What each playbook does (conceptual)
- **Application-Management.md** - App lifecycle philosophy
- **Configuration-Profiles.md** - macOS Settings & Dotfiles (why)
- **Business-vs-Private.md** - Conceptual differences between Business & Private Macs

**Also see:**

- **Homelab/Decisions/** - Decision Records (e.g., "Why Ansible for Mac Management")
- **Homelab/README.md** - Homelab Hub (main overview)

> 💡 **Layered Documentation:**
> This repository contains **HOW** (technical implementation).
> Obsidian contains **WHY & WHAT** (concepts, decisions, integration).
>
> See [DOCUMENTATION_STRATEGY.md](DOCUMENTATION_STRATEGY.md) for details.

## Key Differences from Upstream

This fork has significantly diverged from the original geerlingguy/mac-dev-playbook with the following major changes:

### Multi-Mac Management

- **Hierarchical Inventory System**: Manage multiple Macs (business/private) with shared and specific configurations
- **Group Variables**: `inventories/group_vars/macs/`, `business_mac/`, `private_mac/`
- **Host Variables**: Per-host configuration in `inventories/host_vars/`

### Custom Workflows

- **`macupdate`** (`scripts/macupdate`): Daily maintenance script (updates packages, system, dotfiles)
- **`macapply`** (`scripts/macapply`): Apply configuration changes (runs `plays/full.yml` with tags)
- **`init.sh`**: Bootstrap script for fresh Mac setup

### Enhanced Playbooks

- **`plays/full.yml`**: Complete provisioning with temporary passwordless sudo, validation, pre-tasks
- **`plays/update.yml`**: Focused update playbook for daily maintenance
- **Pre-Tasks**: Rosetta2 installation, cleanup tasks, SSH setup, validation
- **Post-Tasks**: 15+ post-provision tasks (K8s, GPG, VSCode, iTerm2, etc.)

### Custom Roles

- **`ansible-mac-update`**: macOS software updates, Homebrew updates, Microsoft updates, kubectl
- **`munki_update`**: Munki package management
- **`morgangraphics.nvm`**: Node.js version management

### Package Management

- **Brewfiles in Ansible Repo**: Moved from dotfiles to `files/brewfile/business_mac/` and `private_mac/`
- **No MAS Integration**: Mac App Store apps managed via Homebrew casks instead
- **Centralized Python Version**: `.python-version` file for consistent Python versioning

### Improved Documentation

- **Comprehensive Docs**: `docs/WORKFLOWS.md`, `docs/NEW_MAC_SETUP.md`, `docs/PYTHON_VERSION_MANAGEMENT.md`
- **Analysis Documents**: `docs/analysis/REPOSITORY_REVIEW.md` and others
- **Session Tracking**: `docs/sessions/` for development history
- **CLAUDE.md**: AI assistant context with complete technical reference

### Key Benefits

- **Manage multiple Macs from single repository**
- **Separate business/private configurations**
- **Daily update workflow** (`macupdate`)
- **Configuration change workflow** (`macapply`)
- **Extensive documentation and decision records**

**Divergence Stats** (as of 2025-12-22):

- **289 commits ahead** of upstream
- **137 files changed**, 17,000+ lines added
- **Last sync**: June 26, 2024 ([358f663](https://github.com/geerlingguy/mac-dev-playbook/commit/358f663))

For detailed technical documentation, see [CLAUDE.md](CLAUDE.md).

## Author

This project was created by [Jeff Geerling](https://www.jeffgeerling.com/) (originally inspired by [MWGriffin/ansible-playbooks](https://github.com/MWGriffin/ansible-playbooks)).

Adapted and maintained by Thomas Deutsch for personal use.

[badge-gh-actions]: https://github.com/geerlingguy/mac-dev-playbook/workflows/CI/badge.svg?event=push
[link-gh-actions]: https://github.com/geerlingguy/mac-dev-playbook/actions?query=workflow%3ACI
