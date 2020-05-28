# Customize to your needs...
# Set the list of directories that Zsh searches for programs.
path=(
    $HOME/bin
    $HOME/.local/bin
    /usr/local/{bin,sbin}
    $path
)

SHELL=/usr/local/bin/zsh

function source_if_exists(){
    # [[ -s "/usr/local/opt/z/etc/profile.d/z.sh" ]] && source "/usr/local/opt/z/etc/profile.d/z.sh"
    if [[ -s "$1" ]]; then source "$1"; return $?; fi
    return false
}

# The next line enables z - jump around
# https://github.com/rupa/z
source_if_exists "/usr/local/opt/z/etc/profile.d/z.sh" || true
# [[ -s "/usr/local/opt/z/etc/profile.d/z.sh" ]] && source "/usr/local/opt/z/etc/profile.d/z.sh"
