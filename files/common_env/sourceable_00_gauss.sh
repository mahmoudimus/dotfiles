# Customize to your needs...
# Set the list of directories that Zsh searches for programs.
path=(
    $HOME/.gitextras
    $HOME/bin
    $HOME/.local/bin
    /usr/local/{bin,sbin}
    "$path[@]"
)

SHELL=/usr/local/bin/zsh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
[[ -s "$HOME/.local/share/marker/marker.sh" ]] && source "$HOME/.local/share/marker/marker.sh"
path[1,0]="/usr/local/opt/openssl@1.1/bin"
path[1,0]="$HOME/.config/yarn/global/node_modules/.bin"
path[1,0]="$HOME/.yarn/bin"

# # The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/mahmoud/bin/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/mahmoud/bin/google-cloud-sdk/path.zsh.inc'; fi

# # The next line enables shell command completion for gcloud.
if [ -f '/Users/mahmoud/bin/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/mahmoud/bin/google-cloud-sdk/completion.zsh.inc'; fi

function source_if_exists(){
    if [[ -s "$1" ]]; then source "$1"; return $?; fi
    return false
}

# The next line enables z - jump around
# https://github.com/rupa/z
source_if_exists "/usr/local/opt/z/etc/profile.d/z.sh" || true
