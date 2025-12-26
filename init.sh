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
echo "Enter the hostname: "
read -r newhostname
echo ""
[ ! -d "/Library/Developer/CommandLineTools" ] && installcli

step "Preparing system"
echo " - Preparing repository"

# Define target directory for permanent location
REPO_DIR="${HOME}/development/github/tuxpeople/mac-dev-playbook"

# Clean up existing directory if present (from previous run)
if [ -d "${REPO_DIR}" ]; then
  echo "   Removing existing ${REPO_DIR} directory"
  rm -rf "${REPO_DIR}"
fi

# Create parent directories
if ! mkdir -p "${HOME}/development/github/tuxpeople"; then
  echo "❌ ERROR: Failed to create parent directories"
  echo "   Check permissions and disk space"
  exit 1
fi

echo " - Cloning Repo to ${REPO_DIR}"
if ! git clone https://github.com/tuxpeople/mac-dev-playbook.git "${REPO_DIR}"; then
  echo "❌ ERROR: Failed to clone repository"
  echo "   Check internet connection and GitHub access"
  exit 1
fi

echo " - Upgrading PIP"
PYTHON_BIN="/Library/Developer/CommandLineTools/usr/bin/python3"
if ! ${PYTHON_BIN} -m pip install --upgrade pip --user; then
  echo "❌ ERROR: Failed to upgrade pip"
  echo "   Check Python installation: ${PYTHON_BIN}"
  exit 1
fi

echo " - Installing Ansible"
if ! ${PYTHON_BIN} -m pip install --user --requirement "${REPO_DIR}/requirements.txt"; then
  echo "❌ ERROR: Failed to install Ansible dependencies"
  echo "   Check ${REPO_DIR}/requirements.txt and internet connection"
  exit 1
fi
PATH="/usr/local/bin:$(${PYTHON_BIN} -m site --user-base)/bin:$PATH"
export PATH

echo " - Installing Ansible requirements"
if ! ansible-galaxy install -r "${REPO_DIR}/requirements.yml"; then
  echo "❌ ERROR: Failed to install Ansible Galaxy requirements"
  echo "   Check ${REPO_DIR}/requirements.yml and internet connection"
  exit 1
fi

echo " - Setting max open files"
cd "${REPO_DIR}"
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
HOST_VARS_FILE="${REPO_DIR}/inventories/host_vars/${newhostname}.yml"

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
  read -r -p "Continue anyway? (y/N): " continue_setup
  if [[ "${continue_setup}" != "y" && "${continue_setup}" != "Y" ]]; then
    echo "Aborting setup. Please create host configuration first."
    exit 1
  fi
fi

step "Running Bootstrap Playbook (Phase 1)"

echo "This will install:"
echo "  - Homebrew"
echo "  - Essential CLI tools (git, bash, jq, node)"
echo "  - 1Password app"
echo ""
echo "No vault password or iCloud sync required for this phase."
echo ""

# Run bootstrap playbook
# Override vault_password_file with /dev/null to prevent decryption attempts
# This allows bootstrap to run without vault secrets (Phase 1 doesn't need them)
ansible-playbook plays/bootstrap.yml -i inventories -l "${newhostname}" --connection=local --vault-password-file=/dev/null

echo ""
echo "=========================================="
echo "✅ Bootstrap Phase 1 Complete!"
echo "=========================================="
echo ""
echo "Next Steps (Phase 2 - Manual):"
echo ""
echo "  1. Grant Full Disk Access to Terminal (required for Phase 3):"
echo "     • Open System Settings → Privacy & Security → Full Disk Access"
echo "     • Click (+) and add Terminal.app"
echo "     • Required for SSH setup and system settings"
echo ""
echo "  2. Log into Mac App Store (if you use MAS apps):"
echo "     • Some apps in Brewfile may come from App Store"
echo "     • Open App Store and sign in"
echo ""
echo "  3. Open 1Password and sign in:"
echo "     • 1Password was installed to /Applications"
echo "     • Sign in with your account credentials"
echo ""
echo "  4. Wait for iCloud Drive to sync (optional):"
echo "     • If you use iCloud for dotfiles/SSH keys"
echo "     • Or skip if you don't use iCloud sync"
echo ""
echo "Then run Phase 3 (Full Configuration):"
echo "  (Vault password will be automatically read from 1Password)"
echo "  cd ~/development/github/tuxpeople/mac-dev-playbook"
echo "  ./scripts/macapply"
echo ""
echo "=========================================="
