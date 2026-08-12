# Source main environment file
. ~/.env.sh

# Paths
# Ensure path arrays do not contain duplicates.
typeset -gU cdpath fpath mailpath path

# Brew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Less
export LESS="-R -J -f -i -M -Q -S -X -F"

# Set the list of directories that Zsh searches for programs.
path=($HOME/.rd/bin $HOME/.local/bin $HOME/bin /usr/local/{bin,sbin} $path)

