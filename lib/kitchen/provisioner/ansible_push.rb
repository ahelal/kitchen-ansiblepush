require 'kitchen'
require 'kitchen/provisioner/base'

module Kitchen
  module Provisioner
    #default_config :ansible_version, nil
    class AnsiblePush < Base
      kitchen_provisioner_api_version 2
      default_config :ansible_config, nil
      default_config :verbose, nil
      default_config :diff, nil
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
        validate_config
        complie_config
      end

      def run_command
        info("*************** AnsiblePush run ***************")
        info(" Running %s" % @command  ) 
        exec_command(@command_env, @command, "ansible-playbook")
        info("*************** AnsiblePush end run *******************")
        debug("[#{name}] Converge completed (#{config[:sleep]}s).")
      end

      protected

      def exec_command(env, command, desc)
        debug("env=%s running=%s" % [env, command] )
        system(env, command)
        exit_code = `echo $?`
        if exit_code != 0
          raise '%s returned a non zeroo. Please see the output above.' % desc
        end
      end

      def complie_config()
        debug("compile_config")
        options = %W[--private-key=PRVI_VAR --user=USER_VAR]
        options << "--extra-vars=#{self.get_extra_vars_argument}" if config[:extra_vars]
        options << "--sudo" if config[:sudo]
        options << "--sudo-user=#{config[:sudo_user]}" if config[:sudo_user]
        options << "#{self.get_verbosity_argument}" if config[:verbose]
        options << "--diff" if config[:diff] 
        options << "--ask-sudo-pass" if config[:ask_sudo_pass]
        options << "--ask-vault-pass" if config[:ask_vault_pass]
        options << "--vault-password-file=#{config[:vault_password_file]}" if config[:vault_password_file]
        options << "--tags=%s" % self.as_list_argument(config[:tags]) if config[:tags]
        options << "--skip-tags=%s" % self.as_list_argument(config[:skip_tags]) if config[:skip_tags]
        options << "--start-at-task=#{config[:start_at_task]}" if config[:start_at_task]
        machine_options = @instance.transport.instance_variable_get(:@connection_options)
        ssh_inv= machine_options[:hostname]
        options << "--inventory-file=#{ssh_inv}," if ssh_inv
        # TODO: inventory
        debug("#{options}")
        @command = (%w(ansible-playbook) << options << config[:playbook]).flatten.join(" ")
        debug("Ansible push command= %s" % @command)
        @command_env = {
          "PYTHONUNBUFFERED" => "1", # Ensure Ansible output isn't buffered 
          "ANSIBLE_FORCE_COLOR" => "true",
          "ANSIBLE_HOST_KEY_CHECKING" => "#{config[:host_key_checking]}",
        }
        info("Ansible push compile conig done")
      end

      def validate_config()
        if !config[:playbook]
          raise 'No playbook defined. Please specify one in .kitchen.yml'
        end

        if !File.exist?(config[:playbook])
          raise "playbook '%s' could not be found. Please check path" % config[:playbook]
        end

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
            expanded_path = Pathname.new(extra_vars_path).expand_path(Dir.pwd)
            extra_vars_is_valid = expanded_path.exist?
            if extra_vars_is_valid
              @extra_vars = '@' + extra_vars_path
            end
          end
          if !extra_vars_is_valid
            raise "ansible extra_vars is in valid type: %s value: %s" % [config[:extra_vars].class.to_s, config[:extra_vars].to_s]
          end
        end
        info("Ansible push config validated")
      end

      def get_extra_vars_argument()
        if config[:extra_vars].kind_of?(String) and config[:extra_vars] =~ /^@.+$/
          # A JSON or YAML file is referenced (requires Ansible 1.3+)
          return config[:extra_vars]
        else
        # Expected to be a Hash after config validation. (extra_vars as
        # JSON requires Ansible 1.2+, while YAML requires Ansible 1.3+)
          return config[:extra_vars].to_json
        end
      end

      def as_list_argument(v)
        v.kind_of?(Array) ? v.join(',') : v
      end

      def get_verbosity_argument
        if config[:verbose].to_s =~ /^v+$/
          # ansible-playbook accepts "silly" arguments like '-vvvvv' as '-vvvv' for now
          return "-#{config[:verbose]}"
        else
        # safe default, in case input strays
          return '-v'
        end
      end

    end
  end
end