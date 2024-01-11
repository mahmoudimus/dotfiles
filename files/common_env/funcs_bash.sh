function .. (){
    local arg=${1:-1};
    local dir=""
    while [ $arg -gt 0 ]; do
        dir="../$dir"
        arg=$(($arg - 1));
    done
    cd $dir >&/dev/null
}

function realpath() {
    OURPWD=$PWD
    cd "$(dirname "$1")"
    LINK=$(readlink "$(basename "$1")")
    while [ "$LINK" ]; do
        cd "$(dirname "$LINK")"
        LINK=$(readlink "$(basename "$1")")
    done
    REALPATH="$PWD/$(basename "$1")"
    cd "$OURPWD"
    echo $REALPATH
}

function extract () {
    if [ -f $1 ] ; then
        case $1 in
            *.tar.bz2)  tar xjvf $1 ;;
            *.tar.bz)   tar xjvf $1 ;;
            *.tar.gz)   tar xvzf $1 ;;
            *.bz2)      bunzip2 $1  ;;
            *.rar)      rar x $1    ;;
            *.gz)       gunzip $1   ;;
            *.tar)      tar xvf $1  ;;
            *.zip)      unzip $1    ;;
            *.Z)        uncompress $1   ;;
            *)      echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

function unzip_them() {
    for e in *.zip; do
        unzip -o $e
    done
}

function go_go_gadget_etags() {
    CWD=${1?"USAGE: go_go_gadget_etags TARGET_DIR"}
    TAGSDIR=${2-${HOME}/emacs-tagsp}
    cd ${CWD}
    # etags $(find . -type f | sed 's@\(\s\+\)@\\\1@g')
    etags $(find ${CWD} -follow -type f | xargs -i echo "{}")
    etags --append --include=$(echo ${TAGSDIR}/*tags | sed 's@ @ --include=@g')
}

function ccf() {
    TARGET_DIRECTORY=${1:?"What's the directory to clean up, champ?"}
    NUM_CLEANED=$(find ${TARGET_DIRECTORY} -follow -iregex '.*.py[co]' | wc -l)
    find ${TARGET_DIRECTORY} -follow -iregex '.*.py[co]' | xargs rm
    echo "Cleaned ${NUM_CLEANED} files. :)"
}

function cdworkon () {
  workon $1;
  # find all the directories in the /code directory
  files=$(find ${HOME}/code -name $1 2>/dev/null | grep -v ".git")
  for e in $files; do
      # this check essentially just checks to see if its a directory
      # and if it is, we will change our directory path to it and quit
      # loop iteration
      if [ -d "$e" ] && [ -n "$(echo ${e} | grep bal/py/${1})" ]; then
          cd $e;
          break;
      fi
  done
}

function find_and_replace() {
  echo "find `pwd` -name \"*.py\" | xargs grep -l 'SEARCH_TERM' | xargs perl -p -i -e 's/SEARCH_TERM/REPLACE_WITH/g'"
}


function fix_usr_local_bin_path() {
# fix the patch for
    TEMP_PATH=$(python -c "
path = '${PATH}'.split(':'); \
usrbin = path.index('/usr/bin'); \
usrlocalbin = path.index('/usr/local/bin'); \
path[usrbin], path[usrlocalbin] = path[usrlocalbin], path[usrbin]; \
print ':'.join(path)
")

    if [ $? -eq 0 ]; then
        export PATH=$TEMP_PATH
    fi
}

function whats-listening-on-port() {
    sudo lsof -n -i4TCP:$1 | grep LISTEN
}

function port_fwd_to_pypi() {
    ssh -L 3141:localhost:3141 pypi-prod-4mebwd-10-3-105-37.vandelay.io -Nv
    #ssh -L 3141:localhost:3141 pypi.vandelay.io -Nv
}

function port_fwd_to_rabbitmq() {
    ssh -L 15762:localhost:15762 bmsg-prod-87qaq0-n01-10-3-9-249.vandelay.io -Nv
}

function port_fwd_toknox_rabbitmq() {
    ssh -L15672:localhost:15672 knox-api-04
}

function setup_ansible_project() {
    # ln -s /Users/mahmoud/code/bal/ops/vagabond `pwd`/vagabond
    workon ansible

    # Vagabond
    VAGABOND_PATH=/Users/mahmoud/code/bal/ops/vagabond
    if [ ! -f Vagrantfile ]; then
        ln -s ${VAGABOND_PATH}/Vagrantfile Vagrantfile
    fi

    ## .vagrantuser customizations
    if [ ! -f .vagrantuser ]; then
    cat <<EOF >! .vagrantuser
# -*- mode: yaml -*-
---
ansible_playbook: *YOUR_ANSIBLE_PLAYBOOK*/site.yml
EOF
    fi

}


function setup_gihub_repo() {
    GIT_REPO=${1:?"Need a github repository.. git@github.com..."}
    COMMIT_MSG=${2-"first commit"}

    # git already exists
    if [ -d .git ]; then
        git remote add origin $GIT_REPO
        git push -u origin master
        exit $?
    fi
    cwd=$(pwd)
    git init
    # directory empty?
    if [ ! "$(ls -A $cwd)" ]; then
        touch README.md
        git add README.md
    else
        git add .
    fi
    git commit -m $COMMIT_MSG
    git remote add origin $GIT_REPO
    git push -u origin master
    unset cwd
}

function clone_organization() {
    set +x
    GIT_ORG_NAME=${1:?"Need an org name"}
    CONFIG_FILE=${2:=~/.github.cfg}
    GH_USER=$(awk -F '= ' '{if (! ($0 ~ /^;/) && $0 ~ /user/) print $2}' ${CONFIG_FILE})
    GH_PW=$(awk -F '= ' '{if (! ($0 ~ /^;/) && $0 ~ /password/) print $2}' ${CONFIG_FILE})
    curl -u ${GH_USER}:${GH_PW} \
         -s "https://api.github.com/orgs/${GIT_ORG_NAME}/repos?per_page=200" \
          | ruby -rubygems -e 'require "json"; JSON.load(STDIN.read).each { |repo| %x[git clone #{repo["ssh_url"]} ]}'
}

function update_all_git_repos() {
    TPUT_BIN=/usr/bin/tput
    for e in *;
    do
        if [ ! -d $e ]; then
            echo "$(${TPUT_BIN} setaf 1)Not a directory: $e $(${TPUT_BIN} sgr 0)";
            continue;
        fi

        cd $e
        git pull
        if [ $? -ne 0 ]; then
            echo "$(${TPUT_BIN} setaf 1)Git didnt succeed on: $e $(${TPUT_BIN} sgr 0)";
        fi;
        cd ../;
    done
}

function decode_url() {
    _ARGS=(-c 'import sys, urllib.parse; print(urllib.parse.unquote(sys.stdin.read()))')
    COMMAND=python3
    # test if file descriptor 0 (/dev/stdin) was opened by a terminal
    # XXX: bash4+ if read -t 0; then
    if [ -t 0 ]; then
        # tests for CLI invocation arguments
        if [ $# -gt 0 ]; then
            # echo all CLI arguments to command
            echo "$*" | ${COMMAND} "${_ARGS[@]}"
        fi
    else
        # else if stdin is piped (i.e. not terminal input),
        # output stdin to command (cat - and cat are shorthand for cat /dev/stdin)
        cat - | ${COMMAND} "${_ARGS[@]}"
    fi

    unset COMMAND
}


function loop_example () {
    echo 'e=10; while [ $e -ne 0 ]; do echo "$e" ; e=$(($e - 1));done'
}

function loopit() {
    e=${1:?"how many times do you want to loop?"}
    _cmd=${2:?"cmd? (i.e. /usr/bin/curl)"}
    shift 2;
    if [ $# -eq 0 ]; then
        cat <<EOF

The third parameter should be an array of arguments (i.e. (-o /dev/null -H ... ))
Here's a working example:

  _arg=(-o /dev/null https://tntcmkg5bn7.SANDBOX.verygoodproxy.com/post -H "Content-type: application/json"); loopit 3 '/usr/bin/curl' "\${_arg[@]}"
EOF
        return -1;
    fi
    _args=("$@")
    # for _var in "$@"; do
    #     _args+=($_var)
    # done
    echo $_args
    while [ $e -ne 0 ]; do
        ${_cmd} "${_args[@]}";
        e=$(($e - 1));
    done
}

function perfcurl() {
    _ARGS=(-o /dev/null -s \
              -w 'Establish Connection: %{time_connect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n' \
              https://tntcmkg5bn7.SANDBOX.verygoodproxy.com/post   \
              -H "Content-type: application/json" \
              -d '{"secret": "foo"}')
    loopit 10 curl ${_ARGS}
}

function set_ssl_headers() {
    export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
    export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
    export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"
}

function function_exists() {
    declare -f -F $1 > /dev/null
    return $?
}

function source_if_exists(){
    # function do_it(){
    #     echo "Hello, old friend."
    # }

    # if i_should; then
    #     do_it
    # fi
    if [[ -s "$1" ]]; then source "$1"; return $?; fi
    return false
}


# https://superuser.com/q/39751/27279
# Note that PATH should already be marked as exported, so reexporting
# is not needed.

function pathappend() {
    # This:
    #  - checks whether the directory exists
    #  - is a directory before adding it
    #  - adds the new directory to the end of the path
    for ARG in "$@"
    do
        if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
            PATH="${PATH:+"$PATH:"}$ARG"  # adds to the end of the path
        fi
    done
}

function pathprepend() {
    # This:
    #  - checks whether the directory exists
    #  - is a directory before adding it
    #  - adds the new directory to the beginning of the path
    for ((i=$#; i>0; i--));
    do
        ARG=${!i}
        if [ -d "$ARG" ] && [[ ":$PATH:" != *":$ARG:"* ]]; then
            PATH="$ARG${PATH:+":$PATH"}" # adds to the front of the path
        fi
    done
}

# USAGE: path_unique [path]
# path - a colon delimited list. Defaults to $PATH is not specified.
# RETURNS: `path` with duplicated directories removed
function path_unique() {
    in_path=${1:-$PATH}
    path=':'

    # Wrap the while loop in '{}' to be able to access the updated `path variable
    # as the `while` loop is run in a subshell due to the piping to it.
    # https://stackoverflow.com/questions/4667509/shell-variables-set-inside-while-loop-not-visible-outside-of-it
    printf '%s\n' "$in_path" \
        | /bin/tr -s ':' '\n'    \
        | {
        while read -r dir; do
            left="${path%:$dir:*}" # remove last occurrence to end
            if [ "$path" = "$left" ]; then
                # PATH doesn't contain $dir
                path="$path$dir:"
            fi
        done
        # strip ':' pads
        path="${path#:}"
        path="${path%:}"
        # return
        printf '%s\n' "$path"
    }
}

function append_paths() { # append a group of paths together, leaving out redundancies
    # use as: export PATH="$(append_paths "$PATH" "dir1" "dir2")
    # start at the end:
    #  - join all arguments with :,
    #  - split the result on :,
    #  - pick out non-empty elements which haven't been seen and which are directories,
    #  - join with :,
    #  - print
    perl -le 'print join ":", grep /\w/ && !$seen{$_}++ && -d $_, split ":", join ":", @ARGV;' "$@"
}

function pathmunge () {
    if ! echo $PATH | /usr/bin/egrep -q "(^|:)$1($|:)" ; then
        if [ "$2" = "after" ] ; then
            PATH=$PATH:$1
        else
            PATH=$1:$PATH
        fi
    fi
}

function fixtty() {
    reset
    stty stop undef
    clear
}

function prune_path() {
    local new_path=":"
    local old_ifs="$IFS"
    IFS=":"
    for entry in $PATH; do
        if ! [[ "$new_path" =~ ":${entry}:" ]]; then
            new_path="${new_path}${entry}:"
        fi
    done
    IFS="$old_ifs"
    new_path="${new_path#:}"
    PATH="${new_path%:}"
    export PATH
}


function update_presto() {
    cd $ZPREZTODIR
    git pull
    # https://github.com/sorin-ionescu/prezto/issues/1514#issuecomment-347724966
    git submodule sync
    git submodule update --init --recursive
}

function m-color-map() {
    for i in {0..255}; do print -Pn "%K{$i}  %k%F{$i}${(l:3::0:)i}%f " ${${(M)$((i%6)):#3}:+$'\n'}; done
}


function _emacsfun() {
    local cmd frames

    # Build the Emacs Lisp command to check for suitable frames
    # See https://www.gnu.org/software/emacs/manual/html_node/elisp/Frames.html#index-framep
    case "$*" in
        *-t*|*--tty*|*-nw*) cmd="(memq 't (mapcar 'framep (frame-list)))" ;; # if != nil, there are tty frames
        *) cmd="(delete 't (mapcar 'framep (frame-list)))" ;; # if != nil, there are graphical terminals (x, w32, ns)
    esac

    # Check if there are suitable frames
    frames="$(emacsclient -a '' -n -e "$cmd" 2>/dev/null |sed 's/.*\x07//g' )"

    # Only create another X frame if there isn't one present
    if [ -z "$frames" -o "$frames" = nil ]; then
        emacsclient --alternate-editor="" --create-frame "$@"
        return $?
    fi

    emacsclient --alternate-editor="" "$@"
}

function e() {
    # Adapted from https://github.com/davidshepherd7/emacs-read-stdin/blob/master/emacs-read-stdin.sh
    # If the second argument is - then write stdin to a tempfile and open the
    # tempfile. (first argument will be `--no-wait` passed in by the plugin.zsh)
    if [ $# -ge 2 -a "$2" = "-" ]; then
        # Create a tempfile to hold stdin
        tempfile="$(mktemp --tmpdir emacs-stdin-$USERNAME.XXXXXXX 2>/dev/null \
    || mktemp -t emacs-stdin-$USERNAME)" # support BSD mktemp
        # Redirect stdin to the tempfile
        cat - > "$tempfile"
        # Reset $2 to the tempfile so that "$@" works as expected
        set -- "$1" "$tempfile" "${@:3}"
    fi

    _emacsfun --no-wait "$@"
}
