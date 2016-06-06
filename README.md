# kitchen-ansiblepush
[![Gem Version](https://badge.fury.io/rb/kitchen-ansiblepush.svg)](https://badge.fury.io/rb/kitchen-ansiblepush)
[![Gem Downloads](http://ruby-gem-downloads-badge.herokuapp.com/kitchen-ansiblepush?type=total&color=brightgreen)](https://rubygems.org/gems/kitchen-ansiblepush)
[![Build Status](https://travis-ci.org/ahelal/kitchen-ansiblepush.svg?branch=master)](https://travis-ci.org/ahelal/kitchen-ansiblepush)

A test-kitchen plugin that adds the support for ansible in push mode

## Intro
This kitchen plugin adds ansible as a provisioner in push mode. Ansible will run from your host rather than run from guest machines.  

## How to install 

### Ruby gem
```
gem install kitchen-ansiblepush
```

### To install from code 
``` 
git clone git@github.com:ahelal/kitchen-ansiblepush.git
cd kitchen-ansiblepush
gem build kitchen-ansiblepush.gemspec
gem install kitchen-ansiblepush-<version>.gem
```

## kitchen.yml Options
```yaml
provisioner         :
    ## required options
    name                : ansible_push
    playbook            : "../../plays/web.yml"     # Path to Play yaml
    ##
    ## Optional  argument
    ansible_config      : "/path/to/ansible/ansible.cfg" # path to ansible config file
    verbose             : "vvvv" #  verbose level v, vv, vvv, vvvv
    diff                : true  # print file diff
    mygroup             : "web" # ansible group, or list of groups
    raw_arguments       : "--timeout=200"
    extra_vars          : "@vars.yml"
    tags                : [ "that", "this" ]
    skip_tags           : [ "notme", "orme" ]
    start_at_task       : [ "five" ]
    # Hash of other groups
    groups              : 
         db             :
            - db01
    sudo                : true
    sudo_user           : root
    remote_user         : ubuntu
    private_key         : "/path..../id_rsa"
    ask_vault_pass      : true
    vault_password_file : "/..../file"
    host_key_checking   : false
    generate_inv        : true
    use_instance_name   : false  # use short (platform) instead of instance name by default
    idempotency_test    : false
    ssh_extra_args      : "-o IdentitiesOnly=yes"  # only available in ansible v2.1 and up
    chef_bootstrap_url  : "https://www.getchef.com/chef/install.sh" # set to false to disable chef install
```
## idempotency test
If you want to check your code is idempotent you can use the idempotency_test. Essentially, this will run Ansible twice and check nothing changed in the next run. If something changed it will list the tasks. Note: If your using Ansible callback in your config this might conflict.
```yaml
    idempotency_test: True
    fail_non_idempotent: True
```

If your running ansible V2 you need to white list the callback ``` callback_whitelist = changes``` in **ansible.cfg**
You can also choose to not to fail if idempotency test fails.

##  Ansible version
Since ansiblepush uses the host to run Ansible. you can simply specify the path of your ansible-playbook executable in your .kitchen.yml
```yaml
ansible_playbook_bin : /path/to/ansible-playbook
```

You can use venv and install multi version of ansible or if you prefer you can use an automated installer [ansible-setup](https://github.com/AutomationWIthAnsible/ansible-setup) you can install multi version of ansible.
For further example you can check a matrix test [ansible-usermanage](https://github.com/AutomationWithAnsible/ansible-usermanage/blob/master/.kitchen.yml)

## Disable chef installation
By default chef is installed and serverspec stuff. if you dont want to install 
```yaml
chef_bootstrap_url: nil
```
## TODO
- Enable envirionment var ANSIBLE_CALLBACK_WHITELIST="changes" before call
- Tests (PRs for tests is highligh appreciated)


