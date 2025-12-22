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
  --vault-password-file=~/iCloudDrive/Allgemein/bin/vault_password_file \
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

### On the New Mac

1. **Open Terminal** (use the built-in Terminal.app, NOT iTerm2 if it's already installed)

2. **Log into Mac App Store** (setup will prompt you to verify this)

3. **Run init.sh**:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tuxpeople/mac-dev-playbook/master/init.sh)"
```

4. **Follow the prompts**:
   - Confirm you're logged into Mac App Store
   - Enter the hostname (must match the one you configured above)
   - Choose whether to sync files from iCloud Drive:
     - `y` = Download dotfiles and vault password from iCloud (requires iCloud sync)
     - `n` = Skip iCloud sync, you'll be prompted for vault password during Ansible run

### What Happens During Setup

The init.sh script will:

1. ✅ Install Command Line Tools (if needed)
2. ✅ Clone the playbook repository to `/tmp/git`
3. ✅ (Optional) Download files from iCloud Drive
4. ✅ Install Python dependencies and Ansible
5. ✅ Install Ansible Galaxy requirements
6. ✅ Configure system limits (max open files/processes)
7. ✅ Set hostname
8. ✅ Check for host configuration file
9. ✅ Run the full provisioning playbook (`plays/full.yml`)

### Password Prompts

Depending on your setup, you may be prompted for:

- **Sudo password**: At the beginning (for initial system changes)
- **Ansible Vault password**: If iCloud sync is skipped and no vault_password_file is found
  - This decrypts the `ansible_become_pass` from your host_vars file

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
- Ensure you're using the correct vault password (stored in `~/iCloudDrive/Allgemein/bin/vault_password_file` or your personal vault)
- If using iCloud sync, ensure the `vault_password_file` is accessible

**Error: "Cannot decrypt ansible_become_pass"**

The vault password doesn't match the one used to encrypt the host_vars file.

Solution:
- Verify the vault password is correct
- Re-encrypt the password in the host_vars file if needed

## After Setup

### Verify the Installation

```bash
# Check installed software
brew list
brew list --cask

# Check dotfiles
ls -la ~/development/github/tuxpeople/dotfiles

# Check SSH keys (if configured)
ls -la ~/.ssh
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

## Advanced: Without iCloud Sync

If you want to run the setup without iCloud Drive dependencies:

1. Answer `n` when prompted for iCloud sync
2. You'll be prompted for Ansible Vault password during playbook run
3. You can manually sync dotfiles and other files later

## File Locations

After successful setup:

- **Playbook**: `~/development/github/tuxpeople/mac-dev-playbook`
- **Dotfiles**: `~/development/github/tuxpeople/dotfiles`
- **Brewfiles**: In dotfiles repo under `machine/business_mac/` or `machine/private_mac/`
- **Logs**: Check Terminal output during run

## Reference Files

- Host configuration template: `inventories/host_vars/TEMPLATE.yml`
- Helper script: `scripts/create-host-config.sh`
- Full playbook: `plays/full.yml`
- Update playbook: `plays/update.yml`
