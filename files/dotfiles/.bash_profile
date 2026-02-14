export GPG_TTY=$(tty)
export HASTE_SERVER=https://paste.eighty-three.me
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

#export GITHUB_TOKEN=$(op read op://Private/mwh2l5r44jahhh53gb6i4d4kbe/personal_token_with_repo)

# Homebrew path
if [ "$(uname -m)" == "arm64" ]; then
	eval $(/opt/homebrew/bin/brew shellenv bash)
else
	export PATH="/usr/local/opt/gnu-tar/libexec/gnubin:/usr/local/sbin:/usr/local/bin:$PATH"
fi

# Add `~/bin`, my iCloud Drive bin and krew to the `$PATH`
export PATH="$HOME/bin:$HOME/iCloudDrive/Allgemein/bin/:${HOME}/.krew/bin:$PATH:${HOME}/.local/bin"

# # Add python dir to the path
# if [ -f /usr/local/bin/python3 ]; then
# 	MYPYTHON="/usr/local/bin/python3"
# elif [ -f /opt/homebrew/bin/python3 ]; then
# 	MYPYTHON="/opt/homebrew/bin/python3"
# else
# 	MYPYTHON="/Library/Developer/CommandLineTools/usr/bin/python3"
# fi
# export PATH="$(${MYPYTHON} -m site --user-base)/bin:$PATH"

eval "$(direnv hook bash)"

# Initialize mise (Homebrew installation)
eval "$(mise activate bash)"

export PYENV_ROOT="$HOME/.pyenv"
command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"
# eval "$(pyenv virtualenv-init -)"  # Not needed in newer pyenv versions - integrated into 'pyenv init'

# command -v set_worklocation >/dev/null && set_worklocation

#eval "$(keychain --eval --ignore-missing --quiet --inherit any $(ls -1 ${HOME}/.ssh/id* | grep -v ".pub" | xargs -L1 basename | tr '\n' ' '))"
#eval "$(keychain --eval --ignore-missing --quiet --inherit any /Users/tdeutsch/.ssh/id_rsa)"

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{path,bash_prompt,exports,aliases,functions,extra}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file"
done
unset file

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Append to the Bash history file, rather than overwriting it
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
	shopt -s "$option" 2>/dev/null
done

# Add tab completion for many Bash commands
if which brew &>/dev/null && [ -r "$(brew --prefix)/etc/profile.d/bash_completion.sh" ]; then
	# Ensure existing Homebrew v1 completions continue to work
	export BASH_COMPLETION_COMPAT_DIR="$(brew --prefix)/etc/bash_completion.d"
	source "$(brew --prefix)/etc/profile.d/bash_completion.sh"
elif [ -f /etc/bash_completion ]; then
	source /etc/bash_completion
fi

if command -v flux >/dev/null 2>&1; then
	# Keep Flux CLI autocompletion available when Homebrew's loader misses it
	source <(flux completion bash)
fi

if command -v kubectl >/dev/null 2>&1; then
	# Restore kubectl autocompletion which used to be provided via the CLI
	source <(kubectl completion bash)
fi

# Enable tab completion for `g` by marking it as an alias for `git`
if type _git &>/dev/null; then
	complete -o default -o nospace -F _git g
fi

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh

# Add tab completion for `defaults read|write NSGlobalDomain`
# You could just use `-g` instead, but I like being explicit
complete -W "NSGlobalDomain" defaults

# Add `killall` tab completion for common apps
complete -o "nospace" -W "Contacts Calendar Dock Finder Mail Safari iTunes SystemUIServer Terminal Twitter" killall

if [ -f "$HOME/.cargo/env" ]; then
	source "$HOME/.cargo/env"
fi
