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

[ ! -d "/Library/Developer/CommandLineTools" ] && installcli

step "Preparing system"
echo " - Cloning Repo"
mkdir -p /tmp/git || exit 1
git clone https://github.com/tuxpeople/mac-dev-playbook.git /tmp/git || exit 1

echo " - Downloading important files"
cd ~
IFS=$'\n'
for FILE in Library/Mobile\ Documents/com~apple~CloudDocs/Dateien/Allgemein/dotfiles/filelists/filelist.txt Library/Mobile\ Documents/com~apple~CloudDocs/Dateien/Allgemein/dotfiles/filelists/folderlist.txt
do
  while [ ! -f "${FILE}" ]
  do
    echo Checking for "${FILE}"
    brctl download ${FILE}
    sleep 10
  done
done
for FILE in $(cat Library/Mobile\ Documents/com~apple~CloudDocs/Dateien/Allgemein/dotfiles/filelists/filelist.txt)
do
  while [ ! -f "${FILE}" ]
  do
    echo Checking for "${FILE}"
    brctl download ${FILE}
    sleep 10
  done
done
for DIR in $(cat Library/Mobile\ Documents/com~apple~CloudDocs/Dateien/Allgemein/dotfiles/filelists/folderlist.txt)
do
  while [ ! -d "${DIR}" ]
  do
    echo Checking for "${DIR}"
    brctl download ${DIR}
    sleep 10
  done
done
unset IFS
${HOME}/Library/Mobile\ Documents/com~apple~CloudDocs/Dateien/Allgemein/bin/add_vault_password

echo " - Upgrading PIP"
PYTHON_BIN="/Library/Developer/CommandLineTools/usr/bin/python3"
${PYTHON_BIN} -m pip install --upgrade pip --user || exit 1

echo " - Installing Ansible"
${PYTHON_BIN} -m pip install --user --requirement /tmp/git/requirements.txt || exit 1
PATH="/usr/local/bin:$(${PYTHON_BIN} -m site --user-base)/bin:$PATH"
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

if [ -n "${newhostname}" ]; then
  sudo scutil --set HostName ${newhostname}
  sudo scutil --set LocalHostName ${newhostname}
  sudo scutil --set ComputerName ${newhostname}
  sudo dscacheutil -flushcache
else
  newhostname="$(hostname)"
fi

step "Starting Ansible run"
echo "If something went wrong, start this step again with:"
echo '     cd /tmp/git'
echo '     export newhostname=<HOSTNAME>'
echo '     ansible-playbook plays/full.yml -i inventories -l ${newhostname} --extra-vars "newhostname=${newhostname}" --connection=local'
ansible-playbook plays/full.yml -i inventories -l ${newhostname} --extra-vars "newhostname=${newhostname}" --connection=local
