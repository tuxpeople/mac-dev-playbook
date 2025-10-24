#!/bin/bash
#
# DEPRECATED: This script is deprecated in favor of scripts/macupdate
#
# This script provides basic Ansible dependency installation without the
# full Python environment setup (pyenv, virtualenv) that macupdate provides.
#
# Consider using: scripts/macupdate
# Or for minimal setup: Use the commands below directly
#
set -e

echo "⚠️  WARNING: init_light.sh is deprecated!"
echo "Consider using: scripts/macupdate for full Python environment setup"
echo ""
echo "Continuing with minimal Ansible installation..."
echo ""

pip3 install --requirement requirements.txt || exit 1
PATH="/usr/local/bin:$(python3 -m site --user-base)/bin:$PATH"
export PATH
ansible-galaxy install -r requirements.yml || exit 1

echo ""
echo "✓ Ansible dependencies installed"
echo ""
echo "For future updates, use: scripts/macupdate"
