# golang specific stuff
# export PATH=$PATH:/usr/local/opt/go/libexec/bin
#export GOVERSION=1.12.2
#export GOROOT=/usr/local/Cellar/go/${GOVERSION}
# Respect a GOPATH already chosen by .zshrc (~/go when it exists).
export GOPATH=${GOPATH:-${HOME}/src/go}
if [[ -d "$GOPATH/bin" ]]; then
    path[1,0]="$GOPATH/bin"
fi
