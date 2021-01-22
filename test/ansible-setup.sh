#!/bin/bash
set -ex
echo "Running ansible setup AVM "

export AVM_VERSION="v1.0.0"

export ANSIBLE_VERSIONS_0="1.9.6"
export INSTALL_TYPE_0="pip"
export ANSIBLE_LABEL_0="v2.8"

export ANSIBLE_VERSIONS_1="2.9.17"
export INSTALL_TYPE_1="pip"
export ANSIBLE_LABEL_1="v2.9"

export ANSIBLE_VERSIONS_2="2.8.17"
export INSTALL_TYPE_2="pip"
export ANSIBLE_LABEL_2="v2.10"

# Whats the default version
export ANSIBLE_DEFAULT_VERSION="v2.10"

## Create a temp dir to download avm
avm_dir="$(mktemp -d 2> /dev/null || mktemp -d -t 'mytmpdir')"
git clone https://github.com/ahelal/avm.git "${avm_dir}" > /dev/null 2>&1
## Run the setup
/bin/sh "${avm_dir}/setup.sh"

exit 0

