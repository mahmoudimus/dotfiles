# set -x

if [ -n "$ZSH_VERSION" ]; then
  LOC=$0
elif [ -n "$BASH_VERSION" ]; then
  LOC=$BASH_SOURCE
fi

CWD=$(realpath $(dirname $LOC))

ITEMS=$(ls -1 ${CWD}/sourceable_*.sh)

for item in ${ITEMS}; do
    source $item
done
