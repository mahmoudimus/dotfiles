set +x

# 0 is true, all others are false (think exit codes)
#
# $OSTYPE instead of `uname`: no subprocess, and the old `$(uname) =~ darwin`
# tests never matched because uname prints "Darwin", so IS_MAC was never set.
case "$OSTYPE" in
    linux*)  export IS_LINUX=0 ;;
    darwin*) export IS_MAC=0 ;;
    cygwin*) export IS_CYGWIN=0 ;;
esac

if [[ $IS_LINUX && -r /proc/version && "$(</proc/version)" =~ [Mm]icrosoft ]]; then
  export IS_WSL=0
fi

if [ -n "$ZSH_VERSION" ]; then
    LOC=$0
    export IS_ZSH=0
elif [ -n "$BASH_VERSION" ]; then
    LOC=$BASH_SOURCE
    export IS_BASH=0
fi

# Directory holding this file (~/.common_env). A subshell, so the cd never
# touches the directory stack (AUTO_PUSHD is on in .zshrc).
COMMON_ENV_DIR=$(cd "$(dirname "$LOC")" && pwd -P)
unset LOC

function load_the_files() {
    local item
    for item in "${COMMON_ENV_DIR}"/sourceable_*.sh; do
        [ -f "$item" ] && source "$item"
    done
}

# Called by .zshrc after this file: secrets_env_<Machine>.sh, then
# env_<Machine>.sh, then <short hostname>.sh.
function last_configs() {

    _SYSTEM_UNAME="$(uname -s)"
    case "${_SYSTEM_UNAME}" in
        Linux*)     machine=Linux;;
        Darwin*)    machine=Mac;;
        CYGWIN*)    machine=Cygwin;;
        MINGW*)     machine=MinGw;;
        *)          machine="UNKNOWN_${_SYSTEM_UNAME}"
    esac
    unset _SYSTEM_UNAME

    _ENV_FILE="${COMMON_ENV_DIR}/secrets_env_${machine}.sh"
    if [[ -f "${_ENV_FILE}" ]]; then
        source "${_ENV_FILE}"
    fi

    _ENV_FILE="${COMMON_ENV_DIR}/env_${machine}.sh"
    if [[ -f "${_ENV_FILE}" ]]; then
        source "${_ENV_FILE}"
    fi

    # Short hostname: macOS often reports "pascal.local", but the per-host
    # files are named without the domain (gauss.sh, al-khwarizmi.sh).
    _HOST="$(uname -n)"
    _ENV_FILE="${COMMON_ENV_DIR}/${_HOST%%.*}.sh"
    if [[ -f "${_ENV_FILE}" ]]; then
        source "${_ENV_FILE}"
    fi
    unset _ENV_FILE _HOST
}


load_the_files
