# ruby stuff
# rbenv stuff here

# java stuff
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk1.7.0_06.jdk/Contents/Home
export PATH=${PATH}:${HOME}/code/java/play/current

# ec2 stuff
export AWS_BIN_HOME=${HOME}/bin/aws
export EC2_PRIVATE_KEY=${HOME}/.aws/poundpay-pk-3JZCT2P7X6ZV5UPFZRTK4Q6RAOFE4IRI.pem
export EC2_CERT=${HOME}/.aws/poundpay-cert-3JZCT2P7X6ZV5UPFZRTK4Q6RAOFE4IRI.pem
export EC2_ACCNO=4819-1673-9571
export EC2_URL='https://ec2.us-west-1.amazonaws.com'
export AWS_ELB_URL='https://elasticloadbalancing.us-west-1.amazonaws.com'

export AWS_USER=mahmoud
export AWS_USER_KEYPAIR=mahmoud-gauss
export ACCESS_KEY=`awk -F, '{ print $2 }' ${HOME}/.aws/mahmoud-poundpay-console-2014-12-23.csv | tail -1`
export SECRET_KEY=`awk -F, '{ print $3 }' ${HOME}/.aws/mahmoud-poundpay-console-2014-12-23.csv | tail -1`

# vagrant file for aws provider
export AWS_ACCESS_KEY_ID=${ACCESS_KEY}
export AWS_SECRET_ACCESS_KEY=${SECRET_KEY}
export AWS_HOME=${HOME}/.aws
export KITCHEN_KEY_PAIR_NAME=${AWS_USER_KEYPAIR}
export KITCHEN_SSH_KEY=~/.ssh/id_rsa

export GIT_EDITOR=emacsclient
export VISUAL=${GIT_EDITOR}
export EDITOR=${VISUAL}

### Added by the Heroku Toolbelt
export PATH="/usr/local/heroku/bin:$PATH"

# Emacs Bin
export PATH=/Applications/Emacs.app/Contents/MacOS/bin:$PATH

# Packer Bin
export PATH=/usr/local/bin/packer:${PATH}
export CONFUCIUS_ROOT=/Users/mahmoud/code/bal/rb/confucius/


export SSL_CERT_FILE=/usr/local/opt/curl-ca-bundle/share/ca-bundle.crt

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8


# balanced stuff
export BALANCED_DEV_BASE_DIR=~/code/bal/py/

# kitchen sync
export KITCHEN_SYNC_MODE=rsync

# docker
export DOCKER_HOST=10.2.0.10:2375
