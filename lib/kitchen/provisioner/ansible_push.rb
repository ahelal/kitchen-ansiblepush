require 'kitchen'
require 'kitchen/provisioner/base'

module Kitchen
  module Provisioner

    #default_config :ansible_version, nil
    class AnsiblePush < Base
      kitchen_provisioner_api_version 2

      default_config :ansible_config, nil
      default_config :verbose, nil
      default_config :groups, nil
      default_config :extra_vars, nil
      default_config :sudo, nil
      default_config :sudo_user, nil
      default_config :ask_vault_pass, nil
      default_config :vault_password_file, nil
      default_config :limit, nil
      default_config :tags, nil
      default_config :skip_tags, nil
      default_config :start_at_task, nil
      default_config :host_key_checking, false
      default_config :playbook, nil
      
      def prepare_command
        puts "************* AnsiblePush Prepare **********"
        validate_config
        complie_config
      end
      
      def run_command
        puts "*************** AnsiblePush run ***************"
        x=@instance.transport.instance_variable_get(:@connection_options)
        info("[dasdasdasd]")
        hostname=x[:hostname]
        #exec_command("ansible -i #{hostname}, -m setup all -u ubuntu")
        puts "*************** AnsiblePush end run *******************"
        debug("[#{name}] Converge completed (#{config[:sleep]}s).")
      end

    protected

     def exec_command(command)
        system(command)
      end

      def complie_config()
        puts config.to_yaml
      end

      def validate_config()
        info("validate_config")
        puts "++++++++++++++++", File.new(Dir.new(".").path)
        
        # Check if playbook options
        if !config[:playbook]
          raise 'No playbook defined. Please specify one in .kitchen.yml'
        end
        if !File.exist?(config[:playbook])
          raise "playbook '%s' could not be found. Please check path" % config[:playbook]
        end
        
        # Check valut password path
        if config[:vault_password_file] and !File.exist?(config[:vault_password_file])
          raise "Vault password '%s' could not be found. Please check path" % config[:vault_password_file]
        end
      
        # Validate that extra_vars is either a hash, or a path to an existing file
        if config[:extra_vars] 
          extra_vars_is_valid = config[:extra_vars].kind_of?(Hash) || config[:extra_vars].kind_of?(String)
          if config[:extra_vars].kind_of?(String)
            # Accept the usage of '@' prefix in Vagrantfile (e.g. '@vars.yml'
            # and 'vars.yml' are both supported)
            match_data = /^@?(.+)$/.match(config[:extra_vars])
            extra_vars_path = match_data[1].to_s
            expanded_path = Pathname.new(extra_vars_path).expand_path(machine.env.root_path)
            extra_vars_is_valid = expanded_path.exist?
            if extra_vars_is_valid
              @extra_vars = '@' + extra_vars_path
            end
          end
          if !extra_vars_is_valid
           raise "ansible extra_vars is in valid ", type:  config[:extra_vars].class.to_s, value: config[:extra_vars].to_s
          end
        end
      end
    end
  end
end