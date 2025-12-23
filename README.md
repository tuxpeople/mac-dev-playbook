<img src="https://raw.githubusercontent.com/geerlingguy/mac-dev-playbook/master/files/Mac-Dev-Playbook-Logo.png" width="250" height="156" alt="Mac Dev Playbook Logo" />

# Mac Development Ansible Playbook

[![CI][badge-gh-actions]][link-gh-actions]

> **Note**: This repository was originally forked from [geerlingguy/mac-dev-playbook](https://github.com/geerlingguy/mac-dev-playbook) (last sync: June 26, 2024, commit [358f663](https://github.com/geerlingguy/mac-dev-playbook/commit/358f663)).
>
> **This fork has significantly diverged** (~289 commits ahead) with custom features for managing multiple Macs (business/private). It is maintained independently and does not merge upstream changes. See [Key Differences](#key-differences-from-upstream) below.

This playbook installs and configures software on multiple Macs for development and daily use. It supports managing both business and private Macs with different configurations through a hierarchical inventory system.

## Installation

  1. Ensure Apple's command line tools are installed (`xcode-select --install` to launch the installer).
  2. [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/index.html):

     1. Run the following command to add Python 3 to your $PATH: `export PATH="$HOME/Library/Python/3.9/bin:/opt/homebrew/bin:$PATH"`
     2. Upgrade Pip: `sudo pip3 install --upgrade pip`
     3. Install Ansible: `pip3 install ansible`

  3. Clone or download this repository to your local drive.
  4. Run `ansible-galaxy install -r requirements.yml` inside this directory to install required Ansible roles.
  5. Run `ansible-playbook main.yml --ask-become-pass` inside this directory. Enter your macOS account password when prompted for the 'BECOME' password.

> Note: If some Homebrew commands fail, you might need to agree to Xcode's license or fix some other Brew issue. Run `brew doctor` to see if this is the case.

### Use with a remote Mac

You can use this playbook to manage other Macs as well; the playbook doesn't even need to be run from a Mac at all! If you want to manage a remote Mac, either another Mac on your network, or a hosted Mac like the ones from [MacStadium](https://www.macstadium.com), you just need to make sure you can connect to it with SSH:

  1. (On the Mac you want to connect to:) Go to System Preferences > Sharing.
  2. Enable 'Remote Login'.

> You can also enable remote login on the command line:
>
>     sudo systemsetup -setremotelogin on

Then edit the `inventory` file in this repository and change the line that starts with `127.0.0.1` to:

```
[ip address or hostname of mac]  ansible_user=[mac ssh username]
```

If you need to supply an SSH password (if you don't use SSH keys), make sure to pass the `--ask-pass` parameter to the `ansible-playbook` command.

### Running a specific set of tagged tasks

You can filter which part of the provisioning process to run by specifying a set of tags using `ansible-playbook`'s `--tags` flag. The tags available are `dotfiles`, `homebrew`, `mas`, `extra-packages` and `osx`.

    ansible-playbook main.yml -K --tags "dotfiles,homebrew"

## Overriding Defaults

Not everyone's development environment and preferred software configuration is the same.

You can override any of the defaults configured in `default.config.yml` by creating a `config.yml` file and setting the overrides in that file. For example, you can customize the installed packages and apps with something like:

```yaml
homebrew_installed_packages:
  - cowsay
  - git
  - go

mas_installed_apps:
  - { id: 443987910, name: "1Password" }
  - { id: 498486288, name: "Quick Resizer" }
  - { id: 557168941, name: "Tweetbot" }
  - { id: 497799835, name: "Xcode" }

composer_packages:
  - name: hirak/prestissimo
  - name: drush/drush
    version: '^8.1'

gem_packages:
  - name: bundler
    state: latest

npm_packages:
  - name: webpack

pip_packages:
  - name: mkdocs

configure_dock: true
dockitems_remove:
  - Launchpad
  - TV
dockitems_persist:
  - name: "Sublime Text"
    path: "/Applications/Sublime Text.app/"
    pos: 5
```

Any variable can be overridden in `config.yml`; see the supporting roles' documentation for a complete list of available variables.

## Included Applications / Configuration (Default)

Applications (installed with Homebrew Cask):

  - [ChromeDriver](https://sites.google.com/chromium.org/driver/)
  - [Docker](https://www.docker.com/)
  - [Dropbox](https://www.dropbox.com/)
  - [Firefox](https://www.mozilla.org/en-US/firefox/new/)
  - [Google Chrome](https://www.google.com/chrome/)
  - [Handbrake](https://handbrake.fr/)
  - [Homebrew](http://brew.sh/)
  - [LICEcap](http://www.cockos.com/licecap/)
  - [nvALT](http://brettterpstra.com/projects/nvalt/)
  - [Sequel Ace](https://sequel-ace.com) (MySQL client)
  - [Slack](https://slack.com/)
  - [Sublime Text](https://www.sublimetext.com/)
  - [Transmit](https://panic.com/transmit/) (S/FTP client)

Packages (installed with Homebrew):

  - autoconf
  - bash-completion
  - doxygen
  - gettext
  - gifsicle
  - git
  - gh
  - go
  - gpg
  - httpie
  - iperf
  - libevent
  - sqlite
  - nmap
  - node
  - nvm
  - php
  - ssh-copy-id
  - cowsay
  - readline
  - openssl
  - pv
  - wget
  - wrk
  - zsh-history-substring-search

My [dotfiles](https://github.com/geerlingguy/dotfiles) are also installed into the current user's home directory, including the `.osx` dotfile for configuring many aspects of macOS for better performance and ease of use. You can disable dotfiles management by setting `configure_dotfiles: no` in your configuration.

Finally, there are a few other preferences and settings added on for various apps and services.

## Full / From-scratch setup guide

Since I've used this playbook to set up something like 20 different Macs, I decided to write up a full 100% from-scratch install for my own reference (everyone's particular install will be slightly different).

You can see my full from-scratch setup document here: [full-mac-setup.md](full-mac-setup.md).

## Testing the Playbook

Many people have asked me if I often wipe my entire workstation and start from scratch just to test changes to the playbook. Nope! This project is [continuously tested on GitHub Actions' macOS infrastructure](https://github.com/geerlingguy/mac-dev-playbook/actions?query=workflow%3ACI).

You can also run macOS itself inside a VM, for at least some of the required testing (App Store apps and some proprietary software might not install properly). I currently recommend:

  - [UTM](https://mac.getutm.app)
  - [Tart](https://github.com/cirruslabs/tart)

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
