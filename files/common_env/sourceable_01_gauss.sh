path[1,0]="/usr/local/opt/openssl@1.1/bin"
path[1,0]="$HOME/.config/yarn/global/node_modules/.bin"
path[1,0]="$HOME/.yarn/bin"

# # The next line updates PATH for the Google Cloud SDK.
source_if_exists '/Users/mahmoud/bin/google-cloud-sdk/path.zsh.inc' || true
# # The next line enables shell command completion for gcloud.
source_if_exists '/Users/mahmoud/bin/google-cloud-sdk/completion.zsh.inc' || true
# # Enable Marker
source_if_exists "$HOME/.local/share/marker/marker.sh" || true
# The next line enables z - jump around
# https://github.com/rupa/z
source_if_exists "/usr/local/opt/z/etc/profile.d/z.sh" || true



# function source_if_exists(){
#     if [[ -s "$1" ]]; then source "$1"; return $?; fi
#     return false
# }


# [[ -s "$HOME/.local/share/marker/marker.sh" ]] && source "$HOME/.local/share/marker/marker.sh"
# path[1,0]="/usr/local/opt/openssl@1.1/bin"
# path[1,0]="$HOME/.config/yarn/global/node_modules/.bin"
# path[1,0]="$HOME/.yarn/bin"

# # # The next line updates PATH for the Google Cloud SDK.
# if [ -f '/Users/mahmoud/bin/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/mahmoud/bin/google-cloud-sdk/path.zsh.inc'; fi

# # # The next line enables shell command completion for gcloud.
# if [ -f '/Users/mahmoud/bin/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/mahmoud/bin/google-cloud-sdk/completion.zsh.inc'; fi

# # The next line enables z - jump around
# # https://github.com/rupa/z
# source_if_exists "/usr/local/opt/z/etc/profile.d/z.sh" || true
#[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# source_if_exists "${HOME}/.fzf.zsh" || true #

if command hash glocate > /dev/null; then
    alias locate="noglob glocate"
    [[ -f "$HOME/locatedb" ]] && export LOCATE_PATH="$HOME/locatedb"
fi
