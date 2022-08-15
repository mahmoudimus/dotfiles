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

available() {
  command -v $1 > /dev/null; 
  return $?;
}

# Begin Setup


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
    # install homebrew
    if ! available brew; then
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
      brew install python3
    fi
fi

log 'Installing' 'Ansible'

# prefer pip for installing python packages over the older easy_install
#
if ! available pip3; then
    curl -fsSL https://bootstrap.pypa.io/get-pip.py -o /tmp/get-pip.py
    sudo python /tmp/get-pip.py
    rm /tmp/get-pip.py
fi

if available pip3 && available ansible; then
    sudo CFLAGS=-Qunused-arguments CPPFLAGS=-Qunused-arguments \
	 /usr/local/bin/pip3 install ansible
fi
