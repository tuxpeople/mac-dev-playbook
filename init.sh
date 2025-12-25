#!/bin/bash
#
#  Use it with this in MacOS Terminal (not iTerm2 if already insalled, as iTerm will be quit ;-) )
#    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tuxpeople/mac-dev-playbook/master/init.sh)"
#
set -e

_step_counter=0
function step() {
        _step_counter=$(( _step_counter + 1 ))
        printf '\n\033[1;36m%d) %s\033[0m\n' $_step_counter "$@" >&2  # bold cyan
}

function installcli() {
  # Check if already installed
  if xcode-select -p &>/dev/null; then
    echo "✓ Command Line Tools already installed at: $(xcode-select -p)"
    return 0
  fi

  # https://gist.github.com/ChristopherA/a598762c3967a1f77e9ecb96b902b5db
  echo "Installing Command Line Tools..."
  echo "This may require a restart of this script after installation completes."

  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  sudo /usr/sbin/softwareupdate -ia
  rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress

  # Try xcode-select --install as fallback
  if ! xcode-select -p &>/dev/null; then
    echo "Triggering GUI installation dialog..."
    xcode-select --install 2>/dev/null || true
    echo ""
    echo "⚠️  Command Line Tools installation may require manual completion."
    echo "   If a dialog appeared, click 'Install' and wait for completion."
    echo "   Then re-run this script:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/tuxpeople/mac-dev-playbook/master/init.sh)\""
    echo ""
    read -r -p "Press enter if installation is complete, or Ctrl+C to exit and restart later..."
  fi

  # Verify installation
  if ! xcode-select -p &>/dev/null; then
    echo "❌ ERROR: Command Line Tools installation failed or incomplete"
    echo "   Please install manually and re-run this script"
    exit 1
  fi

  echo "✓ Command Line Tools installed successfully"
}

step "Check prerequisites"

# Pre-flight checks
echo "Running pre-flight checks..."

# Check if user is admin
if ! groups | grep -q admin; then
  echo "❌ ERROR: Current user is not an administrator"
  echo "   This script requires admin privileges"
  exit 1
fi
echo "✓ User has admin privileges"

# Check internet connectivity
if ! ping -c 1 -W 2 github.com > /dev/null 2>&1; then
  echo "❌ ERROR: No internet connection detected"
  echo "   This script requires internet to download dependencies"
  exit 1
fi
echo "✓ Internet connection available"

# Check disk space (require at least 10GB free)
AVAILABLE_SPACE=$(df -g / | tail -1 | awk '{print $4}')
if [[ "${AVAILABLE_SPACE}" -lt 10 ]]; then
  echo "⚠️  WARNING: Low disk space (${AVAILABLE_SPACE}GB available)"
  echo "   Recommended: At least 10GB free space"
  read -r -p "Continue anyway? (y/N): " continue_low_space
  if [[ "${continue_low_space}" != "y" && "${continue_low_space}" != "Y" ]]; then
    echo "Aborting. Please free up disk space first."
    exit 1
  fi
else
  echo "✓ Sufficient disk space (${AVAILABLE_SPACE}GB available)"
fi

echo ""
echo "Are you logged into Mac Appstore?"
read -r -p "Press enter to continue"
echo ""
echo "Enter the hostname: "
read -r newhostname
echo ""
echo ""
echo "⚠️  IMPORTANT: Grant Full Disk Access to Terminal"
echo "The setup will enable SSH and configure system settings."
echo ""
echo "Steps:"
echo "  1. Open System Settings → Privacy & Security → Full Disk Access"
echo "  2. Click the (+) button and add Terminal.app"
echo "  3. Unlock with your password if needed"
echo ""
read -r -p "Press enter once you've granted Full Disk Access..."
echo ""
echo "Do you want to sync files from iCloud Drive? (y/N)"
echo "This will download dotfiles and vault password from iCloud."
read -r -p "Choose: " sync_icloud
sync_icloud=${sync_icloud:-n}
echo ""

[ ! -d "/Library/Developer/CommandLineTools" ] && installcli

step "Preparing system"
echo " - Preparing repository"

# Clean up existing /tmp/git if present (from previous run)
if [ -d "/tmp/git" ]; then
  echo "   Removing existing /tmp/git directory"
  rm -rf /tmp/git
fi

if ! mkdir -p /tmp/git; then
  echo "❌ ERROR: Failed to create /tmp/git directory"
  echo "   Check permissions and disk space"
  exit 1
fi

echo " - Cloning Repo"
if ! git clone https://github.com/tuxpeople/mac-dev-playbook.git /tmp/git; then
  echo "❌ ERROR: Failed to clone repository"
  echo "   Check internet connection and GitHub access"
  exit 1
fi

if [[ "${sync_icloud}" == "y" || "${sync_icloud}" == "Y" ]]; then
  echo " - Downloading important files from iCloud"
  cd ~

  # Check if brctl is available
  if ! command -v brctl &>/dev/null; then
    echo "⚠️  WARNING: brctl command not found"
    echo "   iCloud file downloads will be skipped"
    echo "   You may need to manually sync files from iCloud Drive"
  else
    # Download file and folder lists with timeout
    FILELIST="Library/Mobile Documents/com~apple~CloudDocs/Dateien/Allgemein/dotfiles/filelists/filelist.txt"
    FOLDERLIST="Library/Mobile Documents/com~apple~CloudDocs/Dateien/Allgemein/dotfiles/filelists/folderlist.txt"

    echo "   Downloading file lists from iCloud..."
    for LIST in "${FILELIST}" "${FOLDERLIST}"; do
      if [[ ! -f "${LIST}" ]]; then
        brctl download "${LIST}" 2>/dev/null || true
        # Wait up to 60 seconds for file to appear
        TIMEOUT=60
        ELAPSED=0
        while [[ ! -f "${LIST}" ]] && [[ ${ELAPSED} -lt ${TIMEOUT} ]]; do
          sleep 5
          ELAPSED=$((ELAPSED + 5))
        done

        if [[ ! -f "${LIST}" ]]; then
          echo "⚠️  WARNING: Could not download ${LIST}"
          echo "   Continuing without this list..."
        fi
      fi
    done

    # Download files from filelist.txt if available
    if [[ -f "${FILELIST}" ]]; then
      echo "   Downloading files from filelist..."
      while IFS= read -r FILE; do
        [[ -z "${FILE}" ]] && continue  # Skip empty lines
        if [[ ! -f "${FILE}" ]]; then
          brctl download "${FILE}" 2>/dev/null || true
          # Wait up to 30 seconds per file
          TIMEOUT=30
          ELAPSED=0
          while [[ ! -f "${FILE}" ]] && [[ ${ELAPSED} -lt ${TIMEOUT} ]]; do
            sleep 5
            ELAPSED=$((ELAPSED + 5))
          done

          if [[ ! -f "${FILE}" ]]; then
            echo "⚠️  Could not download: ${FILE}"
          fi
        fi
      done < "${FILELIST}"
    fi

    # Download folders from folderlist.txt if available
    if [[ -f "${FOLDERLIST}" ]]; then
      echo "   Downloading folders from folderlist..."
      while IFS= read -r DIR; do
        [[ -z "${DIR}" ]] && continue  # Skip empty lines
        if [[ ! -d "${DIR}" ]]; then
          brctl download "${DIR}" 2>/dev/null || true
          # Wait up to 30 seconds per folder
          TIMEOUT=30
          ELAPSED=0
          while [[ ! -d "${DIR}" ]] && [[ ${ELAPSED} -lt ${TIMEOUT} ]]; do
            sleep 5
            ELAPSED=$((ELAPSED + 5))
          done

          if [[ ! -d "${DIR}" ]]; then
            echo "⚠️  Could not download: ${DIR}"
          fi
        fi
      done < "${FOLDERLIST}"
    fi

    echo "✓ iCloud sync completed (some files may have been skipped)"

    # Try to run add_vault_password script if available (stores password in keychain)
    if [[ -f "${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Dateien/Allgemein/bin/add_vault_password" ]]; then
      echo "   Running add_vault_password script..."
      # Capture output and filter out "already exists" messages
      if OUTPUT=$("${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Dateien/Allgemein/bin/add_vault_password" 2>&1); then
        echo "✓ Vault password configured in keychain"
      else
        # Check if error was just "already exists"
        if echo "${OUTPUT}" | grep -q "already exists in the keychain"; then
          echo "✓ Vault password already configured in keychain"
        else
          echo "⚠️  WARNING: add_vault_password script encountered issues:"
          echo "${OUTPUT}"
          echo "   Continuing anyway..."
        fi
      fi
    fi
  fi
else
  echo " - Skipping iCloud sync (you'll need to provide vault password manually)"
fi

echo " - Upgrading PIP"
PYTHON_BIN="/Library/Developer/CommandLineTools/usr/bin/python3"
if ! ${PYTHON_BIN} -m pip install --upgrade pip --user; then
  echo "❌ ERROR: Failed to upgrade pip"
  echo "   Check Python installation: ${PYTHON_BIN}"
  exit 1
fi

echo " - Installing Ansible"
if ! ${PYTHON_BIN} -m pip install --user --requirement /tmp/git/requirements.txt; then
  echo "❌ ERROR: Failed to install Ansible dependencies"
  echo "   Check /tmp/git/requirements.txt and internet connection"
  exit 1
fi
PATH="/usr/local/bin:$(${PYTHON_BIN} -m site --user-base)/bin:$PATH"
export PATH

echo " - Installing Ansible requirements"
if ! ansible-galaxy install -r /tmp/git/requirements.yml; then
  echo "❌ ERROR: Failed to install Ansible Galaxy requirements"
  echo "   Check /tmp/git/requirements.yml and internet connection"
  exit 1
fi

echo " - Setting max open files"
cd /tmp/git
sudo cp files/system/limit.maxfiles.plist /Library/LaunchDaemons
sudo cp files/system/limit.maxproc.plist /Library/LaunchDaemons
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
sudo chown root:wheel /Library/LaunchDaemons/limit.maxproc.plist
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist
sudo launchctl load -w /Library/LaunchDaemons/limit.maxproc.plist

if [[ -n "${newhostname}" ]]; then
  sudo scutil --set HostName "${newhostname}"
  sudo scutil --set LocalHostName "${newhostname}"
  sudo scutil --set ComputerName "${newhostname}"
  sudo dscacheutil -flushcache
else
  newhostname="$(hostname)"
fi

step "Preparing Ansible configuration"

# Check if host_vars file exists in the repo
HOST_VARS_FILE="/tmp/git/inventories/host_vars/${newhostname}.yml"
VAULT_PASSWORD_FILE="${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Dateien/Allgemein/bin/vault_password_file"
ANSIBLE_EXTRA_ARGS=""

if [[ ! -f "${HOST_VARS_FILE}" ]]; then
  echo ""
  echo "⚠️  WARNING: No host configuration found!"
  echo "Expected file: inventories/host_vars/${newhostname}.yml"
  echo ""
  echo "You should create this file BEFORE running init.sh:"
  echo "  1. Use: ./scripts/create-host-config.sh ${newhostname}"
  echo "  2. Or: Copy inventories/host_vars/TEMPLATE.yml to inventories/host_vars/${newhostname}.yml"
  echo "  3. Commit and push to git"
  echo ""
  echo "Without this file, sudo password cannot be decrypted!"
  echo ""
  read -r -p "Continue anyway? (y/N): " continue_setup
  if [[ "${continue_setup}" != "y" && "${continue_setup}" != "Y" ]]; then
    echo "Aborting setup. Please create host configuration first."
    exit 1
  fi
fi

# Determine vault password source
if [[ -f "${VAULT_PASSWORD_FILE}" ]]; then
  echo "✓ Using vault password from: ${VAULT_PASSWORD_FILE}"
  ANSIBLE_EXTRA_ARGS=(--vault-password-file "${VAULT_PASSWORD_FILE}")
else
  echo "ℹ️  Vault password file not found"
  echo "You will be prompted for Ansible Vault password during playbook run"
  ANSIBLE_EXTRA_ARGS=(--ask-vault-pass)
fi

step "Starting Ansible run"

echo "If something went wrong, start this step again with:"
echo "     cd /tmp/git"
echo "     export newhostname=<HOSTNAME>"
if [[ ${#ANSIBLE_EXTRA_ARGS[@]} -gt 0 ]]; then
  echo "     ansible-playbook plays/full.yml -i inventories -l \${newhostname} --extra-vars \"newhostname=\${newhostname}\" --connection=local ${ANSIBLE_EXTRA_ARGS[*]}"
fi

ansible-playbook plays/full.yml -i inventories -l "${newhostname}" --extra-vars "newhostname=${newhostname}" --connection=local "${ANSIBLE_EXTRA_ARGS[@]}"
