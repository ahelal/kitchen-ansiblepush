require 'kitchen'
require 'kitchen/provisioner/base'
require 'kitchen-ansible/util-inventory.rb'

module Kitchen
  module Provisioner
    class AnsiblePush < Base
      kitchen_provisioner_api_version 2
      default_config :ansible_config, nil
      default_config :verbose, nil
      default_config :diff, nil
      default_config :groups, nil
      default_config :extra_vars, nil
      default_config :sudo, nil
      default_config :sudo_user, nil
      default_config :remote_user, nil
      default_config :private_key, nil
      default_config :ask_vault_pass, nil
      default_config :vault_password_file, nil
      default_config :limit, nil
      default_config :tags, nil
      default_config :skip_tags, nil
      default_config :start_at_task, nil
      default_config :host_key_checking, false
      default_config :mygroup, nil
      default_config :playbook, nil
      default_config :generate_inv, true

      def prepare_command
        validate_config
        prepare_inventory
        complie_config
      end

      def run_command
        info("*************** AnsiblePush run ***************")
        exec_command(@command_env, @command, "ansible-playbook")
        info("*************** AnsiblePush end run *******************")
        debug("[#{name}] Converge completed (#{config[:sleep]}s).")
      end

      protected

      def exec_command(env, command, desc)
        debug("env=%s command=%s" % [env, command] )
        system(env, "#{command}")
        exit_code = $?.exitstatus
        debug("ansible-playbook exit code = #{exit_code}")
        if exit_code.to_i != 0
          raise "%s returned a non zeroo '%s'. Please see the output above." % [ desc, exit_code.to_s ]
        end
      end

      def prepare_inventory
        @machine_name = instance.to_str.gsub(/[<>]/, '').split("-").drop(1).join("-")
        @instance_connection_option = instance.transport.instance_variable_get(:@connection_options)
        @hostname = @instance_connection_option[:hostname]
        write_instance_inventory(@machine_name , @hostname, config[:mygroup])
      end

      def complie_config()
        debug("compile_config")
        options = []
        options << "--extra-vars=#{self.get_extra_vars_argument}" if config[:extra_vars]
        options << "--sudo" if config[:sudo]
        options << "--sudo-user=#{config[:sudo_user]}" if config[:sudo_user]
        options << "--user=#{config[:remote_user]}" if self.get_remote_user
        options << "--private-key=#{config[:private_key]}" if config[:private_key]
        options << "#{self.get_verbosity_argument}" if config[:verbose]
        options << "--diff" if config[:diff]
        options << "--ask-sudo-pass" if config[:ask_sudo_pass]
        options << "--ask-vault-pass" if config[:ask_vault_pass]
        options << "--vault-password-file=#{config[:vault_password_file]}" if config[:vault_password_file]
        options << "--tags=%s" % self.as_list_argument(config[:tags]) if config[:tags]
        options << "--skip-tags=%s" % self.as_list_argument(config[:skip_tags]) if config[:skip_tags]
        options << "--start-at-task=#{config[:start_at_task]}" if config[:start_at_task]
        if config[:generate_inv]
          dynamic_inventory_path = Shellwords.escape(File.expand_path("#{File.dirname(__FILE__)}/../../kitchen-ansible/kitchen-ansiblepush-dinv.rb"))
          options << "--inventory-file=#{dynamic_inventory_path}" 
        end
        ##options << "--inventory-file=#{ssh_inv}," if ssh_inv
        # By default we limit by the current machine,
        if config[:limit]
          options << "--limit=#{as_list_argument(config[:limit])}"
        else
          options << "--limit=#{@machine_name}"
        end

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
            # Accept the usage of '@' prefix in Vagrantfile (e.g. '@vars.yml' and 'vars.yml' are both supported)
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

      def get_remote_user
        if config[:remote_user]
          return config[:remote_user]
        elsif @instance_connection_option[:username]
          config[:remote_user] = @instance_connection_option[:username]
          return @instance_connection_option[:username]
        else
          return nil
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