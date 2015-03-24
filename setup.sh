#!/bin/bash
# Credits:
# - http://www.eightbitraptor.com/post/bootstrapping-osx-ansible
# - https://github.com/hanjianwei/dotfiles/blob/master/m

set -e

# Log <type> <msg>
log() {
  printf "  \033[36m%10s\033[0m : \033[90m%s\033[0m\n" $1 $2
}

# Exit with the given <msg ...>
abort() {
  printf "\n  \033[31mError: $@\033[0m\n\n" && exit 1
}


# Begin Setup

log 'Installing' 'Ansible'

# prefer pip for installing python packages over the older easy_install
#
if [[ ! -x `which pip` ]]; then
    sudo easy_install pip
fi

if [[ -x `which pip` && ! -x `which ansible` ]]; then
    sudo CFLAGS=-Qunused-arguments CPPFLAGS=-Qunused-arguments \
	 pip install ansible
fi


#
# Mac OSX Only
#

# Install xcode
function install_xcode() {
  if [[ ! -x /usr/bin/xcode-select ]]; then
      if [[ ! -d "/Applications/Xcode.app" ]]; then
	  log install "Xcode.app"
	  open "macappstore://itunes.apple.com/cn/app/id497799835"
      fi
      exit 1
  fi

  if [[ ! -x /usr/bin/gcc ]]; then
    log install "command line tools"
    xcode-select --install
    exit 1
  fi
}

if [[ "$OSTYPE" == "darwin"* ]]; then
    install_xcode
fi
