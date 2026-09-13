# ruby stuff
# rbenv stuff here

# graalvm build
export MX_PYTHON_VERSION=3

export AWS_USER=mahmoud
export AWS_USER_KEYPAIR=mahmoud-gauss
# export ACCESS_KEY=`awk -F, '{ print $2 }' ${HOME}/.aws/mahmoud-xxx.csv | tail -1`
# export SECRET_KEY=`awk -F, '{ print $3 }' ${HOME}/.aws/mahmoud-xxx.csv | tail -1`

# emacsclient when it exists; otherwise keep what .zshrc set, since an editor
# that is not installed breaks `git commit`. Use choose_editor to switch.
if command -v emacsclient > /dev/null 2>&1; then
    export GIT_EDITOR=emacsclient
    export VISUAL=${GIT_EDITOR}
    export EDITOR=${VISUAL}
fi

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8
