# do we have postgres cli?
SHELL=/opt/homebrew/bin/zsh

# java stuff
export JAVA_HOME="$(/usr/libexec/java_home -v 1.8)"


_POSTGRES_VERSION=13
if [[ -d /Applications/Postgres.app/Contents/Versions/${_POSTGRES_VERSION}/bin ]]; then
    path[1,0]="/Applications/Postgres.app/Contents/Versions/${_POSTGRES_VERSION}/bin"
fi
unset _POSTGRES_VERSION


# https://apple.stackexchange.com/a/410920/30557
function heic2jpg() {
    find . -type f -iname '*.heic' | xargs -I{} sh -c '
  fileNoExt="${1%.*}"
  jpgFile="${fileNoExt}_heic_conv.jpg"
  sips -s format jpeg -s formatOptions best "$1" --out "$jpgFile"
  touch -r "$1" "$jpgFile"
  rm "$1"
  ' sh {}
}

ARCH=$(uname -m)
case $ARCH in
      x86_64|i?86_64*|i?386)
        HOMEBREW_PREFIX="/usr/local"
        eval "$(${HOMEBREW_PREFIX}/Homebrew/bin/brew shellenv)";
        ;;
      arm64*)
        HOMEBREW_PREFIX="/opt/homebrew"
        path[1,0]="${HOMEBREW_PREFIX}/bin"
        path[1,0]="${HOMEBREW_PREFIX}/sbin"
        path[1,0]="${HOMEBREW_PREFIX}/opt/openssl@1.1/bin"
        eval "$(${HOMEBREW_PREFIX}/bin/brew shellenv)";
        ;;
      *)
        echo "Unsupported host arch. Must be x86_64, 386, or arm64" >&2
        exit 1
        ;;
esac


# The next line enables z - jump around
# https://github.com/rupa/z
source_if_exists "${HOMEBREW_PREFIX}/opt/z/etc/profile.d/z.sh" || true

# Source virtual env wrapper
# We do not need virtualenvwrapper anymore, we just need pyenv
# VIRTUALENVWRAPPER_PYTHON=/usr/local/bin/python3
# export VIRTUALENVWRAPPER_VIRTUALENV_ARGS='--no-site-packages'
# export WORKON_HOME=$HOME/.virtualenvs
# export VIRTUALENVWRAPPER_PYTHON=${HOMEBREW_PREFIX}/bin/python3
# export PIP_VIRTUALENV_BASE=$WORKON_HOME
# if [[ -r ${HOMEBREW_PREFIX}/bin/virtualenvwrapper.sh ]]; then
#     source ${HOMEBREW_PREFIX}/bin/virtualenvwrapper.sh
# else
#     echo "WARNING: Can't find virtualenvwrapper.sh"
# fi

# export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"

export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
#
# export GROOVY_HOME=/usr/local/opt/groovy/libexec
# TODO move..
eval "$(jenv init -)"
eval "$(nodenv init -)"
eval "$(direnv hook zsh)"
eval "$(rbenv init -)"

# export CLOUDSDK_PYTHON="/usr/local/opt/python@3.8/libexec/bin/python"
# source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.zsh.inc"
# source "/usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.zsh.inc"

SDKROOT="/Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/SDKs/MacOSX.sdk"
if [[ -d "$SDKROOT" ]]; then
    export SDKROOT
elif [[ -d "/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk" ]]; then
    export SDKROOT="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
fi


if [[ $IS_BASH ]]; then
    if command hash glocate 2> /dev/null; then
        alias locate="noglob glocate"
        [[ -f "$HOME/locatedb" ]] && export LOCATE_PATH="$HOME/locatedb"
    fi
elif [[ $IS_ZSH ]]; then
    if builtin hash glocate 2> /dev/null; then
        alias locate="noglob glocate"
        [[ -f "$HOME/locatedb" ]] && export LOCATE_PATH="$HOME/locatedb"
    fi
fi

source_if_exists /Users/mahmoud/.iterm2_shell_integration.zsh
