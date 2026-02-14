[ -n "$PS1" ] && source ~/.bash_profile;
#. "$HOME/.op"

if [ -d $HOME/.cargo/env ]; then
	source $HOME/.cargo/env
fi