#!/bin/bash
#
#  Bootstrap a new Mac — Phase 1
#  Run in Terminal (not iTerm2):
#    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tuxpeople/mac-dev-playbook/master/init.sh)"
#
set -euo pipefail

# ── Constants ────────────────────────────────────────────────────────────────
REPO_URL="https://github.com/tuxpeople/mac-dev-playbook.git"
REPO_DIR="${HOME}/development/github/tuxpeople/mac-dev-playbook"
VENV_NAME="mac-dev-playbook-venv"

# ── Helpers ──────────────────────────────────────────────────────────────────
step() { printf '\n\033[1;36m▶ %s\033[0m\n' "$*" >&2; }
ok()   { printf '  \033[0;32m✓ %s\033[0m\n' "$*" >&2; }
die()  { printf '  \033[0;31m✗ %s\033[0m\n' "$*" >&2; exit 1; }

# ── Trap: restore vault/config files on any exit ─────────────────────────────
SECRETS_FILE=""
HOST_VARS_FILE=""
ANSIBLE_CFG=""

restore_bootstrap_files() {
    [[ -n "${SECRETS_FILE}"  && -f "${SECRETS_FILE}.bootstrap_disabled"  ]] && \
        mv "${SECRETS_FILE}.bootstrap_disabled"  "${SECRETS_FILE}"
    [[ -n "${HOST_VARS_FILE}" && -f "${HOST_VARS_FILE}.bootstrap_disabled" ]] && \
        mv "${HOST_VARS_FILE}.bootstrap_disabled" "${HOST_VARS_FILE}"
    [[ -n "${ANSIBLE_CFG}"   && -f "${ANSIBLE_CFG}.bootstrap_disabled"   ]] && \
        mv "${ANSIBLE_CFG}.bootstrap_disabled"   "${ANSIBLE_CFG}"
}
trap restore_bootstrap_files EXIT

# ── Pre-flight ───────────────────────────────────────────────────────────────
step "Pre-flight checks"
groups | grep -q admin || die "Current user is not an administrator"
ok "Admin privileges confirmed"
ping -c1 -W2 github.com &>/dev/null || die "No internet connection"
ok "Internet connection available"

# ── Hostname ─────────────────────────────────────────────────────────────────
step "Hostname"
printf '  Enter new hostname (leave empty to keep "%s"): ' "$(hostname -s)"
read -r newhostname
[[ -z "${newhostname}" ]] && newhostname="$(hostname -s)"

# ── Xcode Command Line Tools ─────────────────────────────────────────────────
step "Xcode Command Line Tools"
if xcode-select -p &>/dev/null; then
    ok "Already installed: $(xcode-select -p)"
else
    xcode-select --install 2>/dev/null || true
    echo "  Waiting for installation (click 'Install' in the dialog)..."
    until xcode-select -p &>/dev/null; do sleep 5; done
    ok "Installed"
fi

# ── Homebrew ─────────────────────────────────────────────────────────────────
step "Homebrew"
if command -v brew &>/dev/null; then
    ok "Already installed"
else
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    ok "Installed"
fi

# Make Homebrew available in this session
if [[ -x "/opt/homebrew/bin/brew" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
elif [[ -x "/usr/local/bin/brew" ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
fi

# ── pyenv + 1Password ────────────────────────────────────────────────────────
step "pyenv, pyenv-virtualenv, 1Password"
brew install pyenv pyenv-virtualenv 1password 1password-cli
ok "Installed"

# ── Clone / update repository ────────────────────────────────────────────────
step "Repository"
mkdir -p "${HOME}/development/github/tuxpeople"
if [[ -d "${REPO_DIR}/.git" ]]; then
    git -C "${REPO_DIR}" pull --ff-only
    ok "Updated: ${REPO_DIR}"
else
    git clone "${REPO_URL}" "${REPO_DIR}"
    ok "Cloned: ${REPO_DIR}"
fi
cd "${REPO_DIR}"

# ── Python environment ───────────────────────────────────────────────────────
step "Python environment"
PYTHON_VERSION="$(cat .python-version)"
echo "  Installing Python ${PYTHON_VERSION} via pyenv (may take a few minutes)..."

export PYENV_ROOT="${HOME}/.pyenv"
export PATH="${PYENV_ROOT}/bin:${PATH}"
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"

pyenv install --skip-existing "${PYTHON_VERSION}"
ok "Python ${PYTHON_VERSION} ready"

if ! pyenv versions | grep -q "^  ${VENV_NAME}$"; then
    pyenv virtualenv "${PYTHON_VERSION}" "${VENV_NAME}"
    ok "Virtualenv '${VENV_NAME}' created"
else
    ok "Virtualenv '${VENV_NAME}' already exists"
fi

# Activate: add venv bin directly to PATH (reliable in non-interactive scripts)
export PATH="${PYENV_ROOT}/versions/${VENV_NAME}/bin:${PATH}"

pip install --quiet --upgrade pip
pip install --quiet -r requirements.txt
ok "Requirements installed (ansible: $(ansible --version | head -n1))"

# ── Ansible Galaxy requirements ──────────────────────────────────────────────
step "Ansible Galaxy requirements"
ansible-galaxy install -r requirements.yml
ok "Galaxy requirements installed"

# ── System file limits ───────────────────────────────────────────────────────
step "System file limits"
sudo cp files/system/limit.maxfiles.plist /Library/LaunchDaemons/
sudo cp files/system/limit.maxproc.plist  /Library/LaunchDaemons/
sudo chown root:wheel \
    /Library/LaunchDaemons/limit.maxfiles.plist \
    /Library/LaunchDaemons/limit.maxproc.plist
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist
sudo launchctl load -w /Library/LaunchDaemons/limit.maxproc.plist
ok "File limits configured"

# ── Set hostname ─────────────────────────────────────────────────────────────
step "Setting hostname to '${newhostname}'"
sudo scutil --set HostName      "${newhostname}"
sudo scutil --set LocalHostName "${newhostname}"
sudo scutil --set ComputerName  "${newhostname}"
sudo dscacheutil -flushcache
ok "Hostname set"

# ── Validate host configuration ──────────────────────────────────────────────
step "Host configuration"
HOST_VARS_FILE="${REPO_DIR}/inventories/host_vars/${newhostname}.yml"
if [[ ! -f "${HOST_VARS_FILE}" ]]; then
    printf '\n  \033[0;31m✗ No host config found: inventories/host_vars/%s.yml\033[0m\n' "${newhostname}" >&2
    echo ""
    echo "  Create it before running init.sh:"
    echo "    cp inventories/host_vars/TEMPLATE.yml inventories/host_vars/${newhostname}.yml"
    echo "  Then commit + push, and re-run this script."
    exit 1
fi
ok "Found: inventories/host_vars/${newhostname}.yml"

# ── Bootstrap Playbook ───────────────────────────────────────────────────────
step "Bootstrap Playbook (Phase 1)"
echo "  Temporarily hiding vault-encrypted files (will be restored automatically)..."

SECRETS_FILE="${REPO_DIR}/inventories/group_vars/macs/secrets.yml"
ANSIBLE_CFG="${REPO_DIR}/ansible.cfg"

[[ -f "${SECRETS_FILE}" ]]   && mv "${SECRETS_FILE}"   "${SECRETS_FILE}.bootstrap_disabled"
[[ -f "${HOST_VARS_FILE}" ]] && mv "${HOST_VARS_FILE}" "${HOST_VARS_FILE}.bootstrap_disabled"

# Remove vault_password_file from ansible.cfg (script doesn't exist yet)
if [[ -f "${ANSIBLE_CFG}" ]]; then
    cp "${ANSIBLE_CFG}" "${ANSIBLE_CFG}.bootstrap_disabled"
    grep -v vault_password_file "${ANSIBLE_CFG}.bootstrap_disabled" > "${ANSIBLE_CFG}"
fi

echo "  You will be prompted for your sudo password..."
ansible-playbook plays/bootstrap.yml \
    -i inventories \
    -l "${newhostname}" \
    --connection=local \
    --ask-become-pass

# (trap will restore vault files on EXIT)

# ── Done ─────────────────────────────────────────────────────────────────────
printf '\n\033[1;32m%s\033[0m\n' "══════════════════════════════════════════"
printf '\033[1;32m%s\033[0m\n'   "  Bootstrap Phase 1 complete!"
printf '\033[1;32m%s\033[0m\n'   "══════════════════════════════════════════"
cat << EOF

Next steps (Phase 2 — manual, ~5 min):
  1. Open 1Password and sign in
  2. Enable CLI integration in 1Password:
       Settings → Developer → "Integrate with 1Password CLI"
  3. Verify op works:  op account list
  4. Wait for iCloud Drive to sync (optional)

Then Phase 3 (automated):
  cd ${REPO_DIR}
  ./scripts/macapply

EOF
