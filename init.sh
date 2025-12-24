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
  # https://gist.github.com/ChristopherA/a598762c3967a1f77e9ecb96b902b5db
  echo "Update MacOS & Install Command Line Interface. If this fails, do it manually."
  sudo /usr/sbin/softwareupdate -l
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  sudo /usr/sbin/softwareupdate -ia
  rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  echo "Sleep 20"
  sleep 20
  xcode-select --install
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
echo "Do you want to sync files from iCloud Drive? (y/N)"
echo "This will download dotfiles and vault password from iCloud."
read -r -p "Choose: " sync_icloud
sync_icloud=${sync_icloud:-n}
echo ""

[ ! -d "/Library/Developer/CommandLineTools" ] && installcli

step "Preparing system"
echo " - Cloning Repo"
if ! mkdir -p /tmp/git; then
  echo "❌ ERROR: Failed to create /tmp/git directory"
  echo "   Check permissions and disk space"
  exit 1
fi

if ! git clone https://github.com/tuxpeople/mac-dev-playbook.git /tmp/git; then
  echo "❌ ERROR: Failed to clone repository"
  echo "   Check internet connection and GitHub access"
  exit 1
fi

if [[ "${sync_icloud}" == "y" || "${sync_icloud}" == "Y" ]]; then
  echo " - Downloading important files from iCloud"
  cd ~
  IFS=$'\n'
  for FILE in "Library/Mobile Documents/com~apple~CloudDocs/Dateien/Allgemein/dotfiles/filelists/filelist.txt" "Library/Mobile Documents/com~apple~CloudDocs/Dateien/Allgemein/dotfiles/filelists/folderlist.txt"
  do
    while [ ! -f "${FILE}" ]
    do
      echo Checking for "${FILE}"
      brctl download "${FILE}"
      sleep 10
    done
  done
  while IFS= read -r FILE
  do
    while [ ! -f "${FILE}" ]
    do
      echo Checking for "${FILE}"
      brctl download "${FILE}"
      sleep 10
    done
  done < "Library/Mobile Documents/com~apple~CloudDocs/Dateien/Allgemein/dotfiles/filelists/filelist.txt"
  while IFS= read -r DIR
  do
    while [ ! -d "${DIR}" ]
    do
      echo Checking for "${DIR}"
      brctl download "${DIR}"
      sleep 10
    done
  done < "Library/Mobile Documents/com~apple~CloudDocs/Dateien/Allgemein/dotfiles/filelists/folderlist.txt"
  unset IFS

  if [ -f "${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Dateien/Allgemein/bin/add_vault_password" ]; then
    "${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Dateien/Allgemein/bin/add_vault_password"
  else
    echo "⚠️  WARNING: add_vault_password script not found in iCloud"
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
VAULT_PASSWORD_FILE="${HOME}/iCloudDrive/Allgemein/bin/vault_password_file"
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
  ANSIBLE_EXTRA_ARGS="--vault-password-file=${VAULT_PASSWORD_FILE}"
else
  echo "ℹ️  Vault password file not found"
  echo "You will be prompted for Ansible Vault password during playbook run"
  ANSIBLE_EXTRA_ARGS="--ask-vault-pass"
fi

step "Starting Ansible run"

echo "If something went wrong, start this step again with:"
echo "     cd /tmp/git"
echo "     export newhostname=<HOSTNAME>"
if [[ -n "${ANSIBLE_EXTRA_ARGS}" ]]; then
  echo "     ansible-playbook plays/full.yml -i inventories -l \${newhostname} --extra-vars \"newhostname=\${newhostname}\" --connection=local ${ANSIBLE_EXTRA_ARGS}"
fi

# shellcheck disable=SC2086
ansible-playbook plays/full.yml -i inventories -l "${newhostname}" --extra-vars "newhostname=${newhostname}" --connection=local ${ANSIBLE_EXTRA_ARGS}
