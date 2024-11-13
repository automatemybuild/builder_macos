# Varibles
export BASH_SILENCE_DEPRECATION_WARNING=1
export PATH=$PATH:$HOME/bin
export VISUAL=vim
export EDITOR=vim
[ -x "/opt/homebrew/bin/brew" ] && export PATH="$PATH:/opt/homebrew/bin"

# Source all files starting with .bashrc_
for file in $HOME/.bashrc_*; do
    if [ -f "$file" ]; then
        source "$file"
    fi
done

# Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]$ '

# Run commands
[ -x "$(command -v figlet)" ] && hostname -s | figlet
[ -f $HOME/.lastpatch ] && printf "Last patch: `cat $HOME/.lastpatch`  "
[ -f $HOME/.lastbackup ] && printf "Last backup: `cat $HOME/.lastbackup`"
echo
[ -x "$(command -v $HOME/bin/health2.sh)" ] && $HOME/bin/health2.sh
