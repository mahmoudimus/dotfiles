# do we have postgres cli?

_POSTGRES_VERSION=13
if [[ -d /Applications/Postgres.app/Contents/Versions/${_POSTGRES_VERSION}/bin ]]; then
    path[1,0]="/Applications/Postgres.app/Contents/Versions/${_POSTGRES_VERSION}/bin"
fi
unset _POSTGRES_VERSION
