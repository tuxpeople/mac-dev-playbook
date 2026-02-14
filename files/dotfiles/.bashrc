[ -n "$PS1" ] && source ~/.bash_profile;
#. "$HOME/.op"

if [ -f "$HOME/.cargo/env" ]; then
	source "$HOME/.cargo/env"
fi
