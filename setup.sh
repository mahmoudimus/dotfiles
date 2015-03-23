#!/bin/bash
# taken from: http://www.eightbitraptor.com/post/bootstrapping-osx-ansible
set -e

echo 'Installing Ansible'

# prefer pip for installing python packages over the older easy_install
#
if [[ ! -x `which pip` ]]; then
    sudo easy_install pip
fi

if [[ -x `which pip` && ! -x `which ansible` ]]; then
    sudo CFLAGS=-Qunused-arguments CPPFLAGS=-Qunused-arguments \
	 pip install ansible
fi
