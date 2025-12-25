---

# New Mac Setup Guide

Complete guide for setting up a new Mac with this playbook.

## Prerequisites

Before running init.sh on the new Mac, complete these preparation steps:

### 1. Create Host Configuration (On Your Current Machine)

Choose one of these methods:

**Option A: Use the helper script (Recommended)**

```bash
cd ~/development/github/tuxpeople/mac-dev-playbook
./scripts/create-host-config.sh <new-hostname>
```

This will:

- Prompt for ansible_user (default: tdeutsch)
- Prompt for sudo password
- Encrypt the password with Ansible Vault
- Create `inventories/host_vars/<new-hostname>.yml`

**Option B: Manual creation**

```bash
# Copy template
cp inventories/host_vars/TEMPLATE.yml inventories/host_vars/<new-hostname>.yml

# Edit the file
vim inventories/host_vars/<new-hostname>.yml

# Encrypt your sudo password
ansible-vault encrypt_string \
  --vault-password-file=~/Library/Mobile\ Documents/com~apple~CloudDocs/Dateien/Allgemein/bin/vault_password_file  \
  'your-sudo-password' \
  --name 'ansible_become_pass'

# Paste the encrypted output into the host_vars file
```

### 2. Add Host to Inventory

Edit `inventories/macs.list` and add your new hostname:

```ini
[macs:children]
business_mac
private_mac

[business_mac]
ws547
<new-business-hostname>  # Add here

[private_mac]
odin
thor
<new-private-hostname>   # Or add here
```

### 3. Commit to Git

```bash
git add inventories/host_vars/<new-hostname>.yml
git add inventories/macs.list
git commit -m "Add configuration for <new-hostname>"
git push
```

## Running the Setup

The setup is split into 3 phases for better reliability and control:

### Phase 1: Bootstrap (Automated) - init.sh

**On the New Mac:**

1. **Open Terminal** (use the built-in Terminal.app, NOT iTerm2 if already installed)

2. **Grant Full Disk Access to Terminal**:
   - Open System Settings → Privacy & Security → Full Disk Access
   - Click (+) and add Terminal.app
   - Required for SSH setup and system configuration

3. **Log into Mac App Store** (setup will prompt you to verify this)

4. **Run init.sh**:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tuxpeople/mac-dev-playbook/master/init.sh)"
```

5. **Follow the prompts**:
   - Confirm you're logged into Mac App Store
   - Enter the hostname (must match the one you configured in Prerequisites)

**What Phase 1 Does:**

The init.sh script (bootstrap phase) will:

1. ✅ Run pre-flight checks (admin privileges, internet, disk space)
2. ✅ Install Xcode Command Line Tools (if needed)
3. ✅ Clone the playbook repository to `/tmp/git`
4. ✅ Install Python dependencies and Ansible
5. ✅ Install Ansible Galaxy requirements
6. ✅ Configure system limits (max open files/processes)
7. ✅ Set hostname
8. ✅ Create ~/iCloudDrive symlink
9. ✅ Run bootstrap playbook (`plays/bootstrap.yml`):
   - Install Homebrew
   - Install essential CLI tools (git, bash, jq, node)
   - Install 1Password app

**Important:** Phase 1 requires **NO vault password**, **NO iCloud sync**, and **NO 1Password login**.
This makes it ultra-robust and impossible to fail due to missing external dependencies.

### Phase 2: Manual Configuration (5-10 minutes)

After Phase 1 completes, you'll see instructions for manual steps:

1. **Open 1Password and sign in**:
   - 1Password was installed to /Applications during Phase 1
   - Sign in with your account credentials

2. **Wait for iCloud Drive to sync** (optional):
   - If you use iCloud for dotfiles/SSH keys, wait for sync to complete
   - Skip this if you don't use iCloud sync

3. **Add vault password to macOS Keychain**:

```bash
~/iCloudDrive/Allgemein/bin/add_vault_password
```

This stores the Ansible Vault password in your keychain so Phase 3 can run without prompting.

### Phase 3: Full Configuration (Automated) - macapply

Once Phase 2 is complete, run the full configuration:

```bash
cd /tmp/git
./scripts/macapply
```

**What Phase 3 Does:**

The macapply script (`plays/full.yml`) will:

1. ✅ Install all Brewfile packages (hundreds of apps)
2. ✅ Configure dotfiles (with SSH keys from iCloud)
3. ✅ Configure Hazel (with license from 1Password)
4. ✅ Configure Dock
5. ✅ Apply macOS settings
6. ✅ Install fonts
7. ✅ Clone GitHub repositories
8. ✅ Run all post-provision tasks
9. ✅ Configure printers
10. ✅ Everything else

**Password Prompts:**

- **Phase 1**: Only interactive sudo (system password)
- **Phase 2**: 1Password master password (manual login)
- **Phase 3**: Vault password automatically from keychain (no prompt)

### Troubleshooting

**Error: "No host configuration found"**

You forgot to create `inventories/host_vars/<hostname>.yml` before running init.sh.

Solution:

1. Exit the init.sh script
2. Create the host configuration on another machine (see Prerequisites above)
3. Commit and push to git
4. Re-run init.sh

**Error: "Vault password incorrect"**

You entered the wrong Ansible Vault password.

Solution:

- Ensure you're using the correct vault password (stored in `~/Library/Mobile\ Documents/com~apple~CloudDocs/Dateien/Allgemein/bin/vault_password_file` or your personal vault)
- If using iCloud sync, ensure the `vault_password_file` is accessible

**Error: "Cannot decrypt ansible_become_pass"**

The vault password doesn't match the one used to encrypt the host_vars file.

Solution:

- Verify the vault password is correct
- Re-encrypt the password in the host_vars file if needed

**Error: "Command Line Tools installation stops the script"**

After installing Xcode Command Line Tools, the script may exit.

Solution (Automatic as of 2025-12-25):

- The script now automatically detects if tools are already installed
- If installation is needed, it provides clear instructions to restart
- Simply re-run the init.sh command to continue from where it stopped

**Error: "Repository directory already exists" (/tmp/git)**

When restarting the script, git clone fails because /tmp/git already exists.

Solution (Automatic as of 2025-12-25):

- The script now automatically cleans up /tmp/git before cloning
- No manual intervention needed

**Error: "No matching distribution found for ansible==X.X.X"**

Python version incompatibility with fixed Ansible version.

Solution (Automatic as of 2025-12-25):

- requirements.txt now uses flexible version ranges (ansible>=9.0)
- pip automatically selects the best version for your Python version
- Works with Python 3.9+ (System Python) and Python 3.11+ (pyenv)

**Error: "Keychain item already exists"**

During iCloud sync, you see: "SecKeychainItemCreateFromContent: item already exists"

Solution (Automatic as of 2025-12-25):

- Script now gracefully handles "already exists" errors
- Non-critical keychain errors are logged as warnings
- Setup continues without interruption

**Error: "SyntaxError: Missing parentheses in call to 'print'"**

Python 2 syntax error in dependencies (ushlex package).

Solution (Automatic as of 2025-12-25):

- Fixed by using ansible>=9.0 with compatible dependencies
- No longer installs packages with Python 2 syntax

## After Setup

### Verify the Installation

After Phase 3 completes, verify everything is set up correctly:

```bash
# Check installed software
brew list
brew list --cask

# Check dotfiles
ls -la ~/development/github/tuxpeople/dotfiles

# Check SSH keys (if configured)
ls -la ~/.ssh

# Verify Ansible is working
ansible --version
```

### Move Repository from /tmp/git (Optional)

The repository is initially cloned to `/tmp/git`. You may want to move it:

```bash
# Move to permanent location
mv /tmp/git ~/development/github/tuxpeople/mac-dev-playbook

# Or use the default location if dotfiles already set it up
cd ~/development/github/tuxpeople/mac-dev-playbook
```

### Daily Updates

For daily maintenance and updates, use the `macupdate` script:

```bash
# Option 1: Run from repo
cd ~/development/github/tuxpeople/mac-dev-playbook
./scripts/macupdate

# Option 2: Create symlink (recommended, do this once)
ln -sf ~/development/github/tuxpeople/mac-dev-playbook/scripts/macupdate \
       ~/iCloudDrive/Allgemein/bin/macupdate

# Then run from anywhere
macupdate
```

## Workflow Summary

The 3-phase approach provides:

- **Phase 1 (init.sh)**: Ultra-robust bootstrap, no external dependencies → 30-45 min
- **Phase 2 (manual)**: User-controlled 1Password/iCloud setup → 5-10 min
- **Phase 3 (macapply)**: Full configuration with all dependencies available → 20-30 min

**Benefits:**

- Phase 1 cannot fail due to missing secrets or iCloud
- User has control over when to set up 1Password
- Phase 3 runs smoothly with all dependencies ready
- Better error isolation (which phase has the problem?)
- Can re-run Phase 3 multiple times (idempotent)

## File Locations

After successful setup:

- **Playbook**: `/tmp/git` (initially) → move to `~/development/github/tuxpeople/mac-dev-playbook`
- **Dotfiles**: `~/development/github/tuxpeople/dotfiles` (cloned in Phase 3)
- **Brewfiles**: `files/brewfile/business_mac/` or `files/brewfile/private_mac/`
- **iCloud symlink**: `~/iCloudDrive` → `~/Library/Mobile Documents/com~apple~CloudDocs/Dateien`

## Reference Files

- **Bootstrap playbook**: `plays/bootstrap.yml` (Phase 1)
- **Full playbook**: `plays/full.yml` (Phase 3)
- **Update playbook**: `plays/update.yml` (for macupdate)
- **Host configuration template**: `inventories/host_vars/TEMPLATE.yml`
- **Helper script**: `scripts/create-host-config.sh`
- **Apply script**: `scripts/macapply` (runs full.yml)
- **Update script**: `scripts/macupdate` (runs update.yml)
