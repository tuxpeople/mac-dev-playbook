#!/bin/bash
#
#  Use it with this in MacOS Terminal (not iTerm2 if already insalled, as iTerm will be quit ;-) ) 
#    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tuxpeople/mac-dev-playbook/master/init.sh)"
#
# set -e

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
echo "Are you logged into Mac Appstore?"
read -p "Press enter to continue"
echo ""
echo "Enter the hostname: "  
read newhostname  
echo ""
echo "Sudo magic, please enter sudo-password if asked"
# Sudo Magic :)
sudo -v

# Keep-alive: update existing `sudo` time stamp until we have finished
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

if [ ! -f "${HOME}/Library/Mobile Documents/com~apple~CloudDocs/Dateien/Allgemein/bin/add_vault_password" ]; then
  echo "Error: Login to iCloud First!"
  exit 1
fi

[ ! -d "/Library/Developer/CommandLineTools" ] && installcli

step "Preparing system"
echo " - Cloning Repo"
mkdir -p /tmp/git || exit 1
git clone https://github.com/tuxpeople/mac-dev-playbook.git /tmp/git || exit 1

echo " - Upgrading PIP"
pip3 install --upgrade pip || exit 1

echo " - Installing Ansible"
pip3 install --user --requirement /tmp/git/requirements.txt || exit 1
PATH="/usr/local/bin:$(python3 -m site --user-base)/bin:$PATH"
export PATH

echo " - Installing Ansible requirements"
ansible-galaxy install -r /tmp/git/requirements.yml || exit 1

echo " - Setting max open files"
cd /tmp/git
sudo cp files/system/limit.maxfiles.plist /Library/LaunchDaemons
sudo cp files/system/limit.maxproc.plist /Library/LaunchDaemons
sudo chown root:wheel /Library/LaunchDaemons/limit.maxfiles.plist
sudo chown root:wheel /Library/LaunchDaemons/limit.maxproc.plist
sudo launchctl load -w /Library/LaunchDaemons/limit.maxfiles.plist
sudo launchctl load -w /Library/LaunchDaemons/limit.maxproc.plist

# echo "Getting Brewfile"
# if [[ $(hostname) == ws* ]]; then
#   curl -sfL https://raw.githubusercontent.com/tuxpeople/dotfiles/master/machine/business/Brewfile > files/Brewfile
# else
#   curl -sfL https://raw.githubusercontent.com/tuxpeople/dotfiles/master/machine/private/Brewfile > files/Brewfile
# fi

if [ -n "${newhostname}" ]; then
  sudo scutil --set HostName ${newhostname}
  sudo scutil --set LocalHostName ${newhostname}
  sudo scutil --set ComputerName ${newhostname}
  sudo dscacheutil -flushcache ${newhostname}
fi

step "Starting Ansible run"
echo "If something went wrong, start this step again with:"
echo '     cd /tmp/git'
echo '     export newhostname=<HOSTNAME>'
echo '     ansible-playbook plays/full.yml -i inventories -l ${newhostname} --extra-vars "newhostname=${newhostname}"'
ansible-playbook plays/full.yml -i inventories -l ${newhostname} --extra-vars "newhostname=${newhostname}"
