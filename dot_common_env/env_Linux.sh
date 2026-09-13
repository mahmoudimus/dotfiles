SHELL=/usr/bin/zsh
# java stuff
if [ -f "$(which javac)" ]; then
    export JAVA_HOME=$(dirname $(dirname $(readlink -e $(which javac))))
fi

# Automatically start dbus
sudo /etc/init.d/dbus start &> /dev/null


if [[ $IS_WSL ]]; then
  function pbpaste() {
    powershell.exe -noninteractive -noprofile -command Get-Clipboard
  }
  function pbcopy() {
    powershell.exe -noninteractive -noprofile -command 'echo $input | Set-Clipboard'
  }
fi

if [[ $IS_BASH ]]; then
    if command hash locate 2> /dev/null; then
        alias locate="noglob locate"
        [[ -f "$HOME/locatedb" ]] && export LOCATE_PATH="$HOME/locatedb"
    fi
elif [[ $IS_ZSH ]]; then
    if builtin hash locate 2> /dev/null; then
        alias locate="noglob locate"
        [[ -f "$HOME/locatedb" ]] && export LOCATE_PATH="$HOME/locatedb"
    fi
fi
