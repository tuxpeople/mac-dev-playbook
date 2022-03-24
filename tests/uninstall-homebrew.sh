#!/bin/bash
#
# Uninstalls Homebrew using the official uninstall script.

# Download and run the uninstall script.
curl -sLO https://raw.githubusercontent.com/Homebrew/install/master/uninstall.sh
chmod +x ./uninstall.sh
sudo ./uninstall.sh --force

# Clean up Homebrew directories.
sudo rm -rf $(brew --prefix)/Homebrew
sudo rm -rf $(brew --prefix)/Caskroom
sudo rm -rf $(brew --prefix)/bin/brew
