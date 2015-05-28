# kitchen-ansible

A test-kitchen plugin that adds the support for ansible in push mode

## TODO
* Tests

## Intro
This kitchen plugin adds ansible as a provisioner in push mode. Ansible will run from your host rather than run from guest machines.  

## How to install 

This gem is still not published 
for now you can clone the repo then run 

``` 
git clone git@github.com:ahelal/kitchen-ansiblepush.git
cd kitchen-ansiblepush
gem build kitchen-ansiblepush.gemspec
sudo gem install kitchen-ansiblepush-<version>.gem
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
    mygroup             : "web" # ansible group 
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
    
```
