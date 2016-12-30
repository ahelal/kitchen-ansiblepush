#!/bin/bash
set -e
echo "Running travis "
DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

SETUP_VERSION="v0.2.0"
#SETUP_VERBOSITY="vv"

## Install Ansible 1.9
ANSIBLE_VERSIONS[0]="1.9.6"
INSTALL_TYPE[0]="pip"
ANSIBLE_LABEL[0]="v1.9"

## Install Ansible 2.0
ANSIBLE_VERSIONS[1]="2.0.2.0"
INSTALL_TYPE[1]="pip"
ANSIBLE_LABEL[1]="v2.0"

## Install Ansible 2.1
ANSIBLE_VERSIONS[2]="2.1.0.0"
INSTALL_TYPE[2]="pip"
ANSIBLE_LABEL[2]="v2.1"

## Install Ansible 2.2
ANSIBLE_VERSIONS[3]="2.2.0.0"
INSTALL_TYPE[3]="pip"
ANSIBLE_LABEL[3]="v2.2"

# Whats the default version
ANSIBLE_DEFAULT_VERSION="v1.9"

## Create a temp dir
filename=$( echo ${0} | sed 's|/||g' )
my_temp_dir="$(mktemp -dt ${filename}.XXXX)"

curl -s "https://raw.githubusercontent.com/ahelal/avm/${SETUP_VERSION}/setup.sh" -o "$my_temp_dir/setup.sh"

## Run the setup
. "$my_temp_dir/setup.sh"
