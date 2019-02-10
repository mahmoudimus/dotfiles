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
