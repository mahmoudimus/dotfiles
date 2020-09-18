set +x

if [ -n "$ZSH_VERSION" ]; then
    LOC=$0
elif [ -n "$BASH_VERSION" ]; then
    LOC=$BASH_SOURCE
fi

CWD=$(realpath $(dirname $LOC))

# since ls can be aliased by the time we're called and it can effect
# the output of this command
ITEMS=($(command /bin/ls -1 ${CWD}/sourceable_*.sh))

# TODO: alternative way to iterate through with bash instead of of zsh?
# for (( i=0; i<=${#ITEMS[@]} ; i+=1 )) ; do
#     echo "${ITEMS[i]}"
# done

for item in ${ITEMS}; do
    source $item
done

_SYSTEM_UNAME="$(uname -s)"
case "${_SYSTEM_UNAME}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN_${_SYSTEM_UNAME}"
esac
unset _SYSTEM_UNAME

_ENV_FILE="${CWD}/secrets_env_${machine}.sh"
if [[ -f "${_ENV_FILE}" ]]; then
    source ${_ENV_FILE}
fi
unset _ENV_FILE
