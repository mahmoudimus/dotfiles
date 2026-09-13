# do we have postgres cli?
SHELL=/opt/homebrew/bin/zsh

# java stuff
# JAVA_HOME is deliberately not set here. `jenv init -` unsets it a few lines
# down, and sdkman-init.sh (sourced later from gauss.local.sh) sets the value
# that actually survives, so the java_home call here only cost ~70ms per shell.


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
export NODENV_ROOT="${NODENV_ROOT:-$HOME/.nodenv}"

# Version managers used to cost one subprocess apiece on every interactive
# shell (`eval "$(foo init -)"`), roughly 0.7s in total. Putting the shims on
# PATH is the only part that has to happen before you actually run one, so do
# that directly and defer each manager's own init to its first invocation.
# The order below reproduces what the eager inits used to leave behind.
path[1,0]=(
  "$HOME/.rbenv/shims"
  "$NODENV_ROOT/bin"
  "$NODENV_ROOT/shims"
  "$HOME/.jenv/shims"
  "$PYENV_ROOT/shims"
  "$PYENV_ROOT/bin"
)

# export GROOVY_HOME=/usr/local/opt/groovy/libexec
# TODO move..
_lazy_version_manager() {
  local mgr=$1
  shift
  unfunction "$mgr"
  eval "$(command "$mgr" init -)"
  "$mgr" "$@"
}
for _mgr in pyenv rbenv nodenv jenv; do
  eval "${_mgr}() { _lazy_version_manager ${_mgr} \"\$@\" }"
done
unset _mgr

# direnv installs a precmd hook, so it genuinely has to load eagerly.
eval "$(direnv hook zsh)"

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

#export HOMEBREW_CASK_OPTS="--appdir=/Applications"

# env LDFLAGS="-L/usr/local/opt/libplist/lib" CPPFLAGS="-I/usr/local/opt/libplist/include" PKG_CONFIG_PATH="/usr/local/opt/libplist/lib/pkgconfig" brew install libimobiledevice ios-webkit-debug-proxy

# # If you need to have $LIB first in your PATH run:
# export PATH="/usr/local/opt/$LIB/bin:$PATH"

# # For compilers to find $LIB you may need to set:
# export LDFLAGS="-L/usr/local/opt/$LIB/lib"
# export CPPFLAGS="-I/usr/local/opt/$LIB/include"

# # For pkg-config to find $LIB you may need to set:
# export PKG_CONFIG_PATH="/usr/local/opt/$LIB/lib/pkgconfig"

source_if_exists /Users/mahmoud/.iterm2_shell_integration.zsh

function export_llm_keys() {
    if command -v op &> /dev/null; then
        export KIMI_API_KEY=$(op read "op://Private/KIMI_API_KEY/credential")
        export NVIDIA_NIM_API_KEY=$(op read "op://Private/NVIDIA_NIM_API_KEY/credential")
    fi
}
# ---------------------------------------------------------------------------
# IDA Pro / d810
#
# IDA_SDK and IDA_INSTALL_DIR are deliberately NOT set here -- they live in
# ~/dotfiles/files/zsh/zshenv. This file is reached via last_configs() in
# sourcer.sh, which .zshrc sources, so it only runs for INTERACTIVE shells;
# d810 builds launched from a non-interactive zsh would miss IDA_SDK and
# re-clone the SDK into every worktree. See the comment in zshenv.
