#!/bin/bash
#
# Helper script to create a new host configuration
# Usage: ./scripts/create-host-config.sh <hostname>
#

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <hostname>"
    echo ""
    echo "Example: $0 odin"
    exit 1
fi

HOSTNAME="$1"
HOST_VARS_FILE="inventories/host_vars/${HOSTNAME}.yml"
TEMPLATE_FILE="inventories/host_vars/TEMPLATE.yml"

# Check if file already exists
if [ -f "${HOST_VARS_FILE}" ]; then
    echo "Error: ${HOST_VARS_FILE} already exists!"
    exit 1
fi

# Check if template exists
if [ ! -f "${TEMPLATE_FILE}" ]; then
    echo "Error: Template file ${TEMPLATE_FILE} not found!"
    exit 1
fi

echo "Creating host configuration for: ${HOSTNAME}"
echo ""

# Ask for username
read -r -p "Enter ansible_user (default: tdeutsch): " ANSIBLE_USER
ANSIBLE_USER=${ANSIBLE_USER:-tdeutsch}

# Ask for sudo password
echo ""
echo "Enter sudo password for encryption:"
read -r -s SUDO_PASSWORD
echo ""

# Check if vault password file exists
VAULT_PASSWORD_FILE="${HOME}/iCloudDrive/Allgemein/bin/vault_password_file"

if [ -f "${VAULT_PASSWORD_FILE}" ]; then
    echo "Using vault password file: ${VAULT_PASSWORD_FILE}"
    ENCRYPTED_PASSWORD=$(ansible-vault encrypt_string \
        --vault-password-file="${VAULT_PASSWORD_FILE}" \
        "${SUDO_PASSWORD}" \
        --name 'ansible_become_pass' 2>/dev/null | grep -v "^Encryption" | sed 's/^ansible_become_pass: //')
else
    echo "Vault password file not found, you'll need to enter vault password:"
    ENCRYPTED_PASSWORD=$(ansible-vault encrypt_string \
        --ask-vault-pass \
        "${SUDO_PASSWORD}" \
        --name 'ansible_become_pass' 2>/dev/null | grep -v "^Encryption" | sed 's/^ansible_become_pass: //')
fi

# Create host_vars file
cat > "${HOST_VARS_FILE}" << EOF
---
# Host configuration for ${HOSTNAME}
# Created: $(date +%Y-%m-%d)

ansible_user: ${ANSIBLE_USER}
ansible_become_pass: ${ENCRYPTED_PASSWORD}

# Optional: Use 1Password for sudo password instead of vault
# Uncomment if you prefer 1Password (requires 1Password CLI installed)
# onepassword_sudo_item: "op://Private/Mac Admin/password"

# Host-specific overrides (optional)
# configure_dock: true
# configure_dotfiles: true
# configure_osx: true
EOF

echo ""
echo "✅ Created: ${HOST_VARS_FILE}"
echo ""
echo "Next steps:"
echo "  1. Review and edit ${HOST_VARS_FILE} if needed"
echo "  2. Add '${HOSTNAME}' to inventories/macs.list under [business_mac] or [private_mac]"
echo "  3. Commit the changes to git"
echo ""
