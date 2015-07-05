require 'kitchen'
require 'kitchen/provisioner/base'
require 'kitchen-ansible/util-inventory.rb'
require 'json'

module Kitchen

  class Busser
    def non_suite_dirs
      %w{data}
    end
  end

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
      default_config :raw_arguments, nil
      default_config :idempotency_test, false

      # For tests disable if not needed
      default_config :chef_bootstrap_url, "https://www.getchef.com/chef/install.sh"

      def prepare_command
        validate_config
        prepare_inventory if config[:generate_inv]
        complie_config
        # Place holder so a string is returned. This will execute true on remote host 
        return "true"
      end

      def install_command
        # Must install chef for busser and serverspec to work :(
        info("*************** AnsiblePush install_command ***************")
        omnibus_download_dir = config[:omnibus_cachier] ? "/tmp/vagrant-cache/omnibus_chef" : "/tmp"
        chef_url = config[:chef_bootstrap_url]
        if chef_url
          <<-INSTALL
            sh -c '
            #{Util.shell_helpers}
            if [ ! -d "/opt/chef" ]
            then
              echo "-----> Installing Chef Omnibus needed by busser and serverspec"
              mkdir -p #{omnibus_download_dir}
              if [ ! -x #{omnibus_download_dir}/install.sh ]
              then
                do_download #{chef_url} #{omnibus_download_dir}/install.sh
              fi

              sudo sh #{omnibus_download_dir}/install.sh -d #{omnibus_download_dir}
              echo "-----> End Installing Chef Omnibus"
            fi

            # Fix for https://github.com/test-kitchen/busser/issues/12
            if [ -h /usr/bin/ruby ]; then
                L=$(readlink -f /usr/bin/ruby)
                sudo rm /usr/bin/ruby
                sudo ln  -s $L /usr/bin/ruby
            fi
            '
          INSTALL
        end
      end

      def run_command
        info("*************** AnsiblePush run ***************")
        exec_ansible_command(@command_env, @command, "ansible-playbook")
        # idempotency test
        if config[:idempotency_test]
          info("*************** idempotency test ***************")
          @command_env["ANSIBLE_CALLBACK_PLUGINS"] = "#{File.dirname(__FILE__)}/../../../callback/"
          exec_ansible_command(@command_env, @command, "ansible-playbook")
          # Check ansible callback if changes has occured in the second run
          file_path = "/tmp/kitchen_ansible_callback/changes"
          if File.file?(file_path)
            task = 0
            info("idempotency test [Failed]")
            File.open(file_path, "r") do |f| 
              f.each_line do |line|
                task += 1
                info(" #{task}> #{line.strip}")
              end
            end
            raise "idempotency test Failed. Number of non idemptent tasks: #{task}"

          else
            info("idempotency test [passed]")
          end
        end
        info("*************** AnsiblePush end run *******************")
        debug("[#{name}] Converge completed (#{config[:sleep]}s).")
        # Place holder so a string is returned. This will execute true on remote host 
        return "true"    
      end

      protected

      def exec_ansible_command(env, command, desc)
        debug("env=%s command=%s" % [env, command] )
        system(env, "#{command}")
        exit_code = $?.exitstatus
        debug("ansible-playbook exit code = #{exit_code}")
        if exit_code.to_i != 0
          raise "%s returned a non zero '%s'. Please see the output above." % [ desc, exit_code.to_s ]
        end
      end

      def prepare_inventory
        @machine_name = instance.name.gsub(/[<>]/, '').split("-").drop(1).join("-")
        debug("machine_name=" + @machine_name.to_s)
        @instance_connection_option = instance.transport.instance_variable_get(:@connection_options)
        debug("instance_connection_option=" + @instance_connection_option.to_s)
        hostname =  if @instance_connection_option.nil?
                       @machine_name
                    else
                        @instance_connection_option[:hostname]
                    end
        debug("hostname=" + hostname)
        write_instance_inventory(@machine_name, hostname, config[:mygroup], @instance_connection_option)
      end

      def complie_config()
        debug("compile_config")
        options = []
        options << "--extra-vars='#{self.get_extra_vars_argument}'" if config[:extra_vars]
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
        options << "--inventory-file=`which kitchen-ansible-inventory`" if config[:generate_inv]
        ##options << "--inventory-file=#{ssh_inv}," if ssh_inv
        
        # By default we limit by the current machine,
        if config[:limit]
          options << "--limit=#{as_list_argument(config[:limit])}"
        else
          options << "--limit=#{@machine_name}"
        end
      
        #Add raw argument as final thing
        options << config[:raw_arguments] if config[:raw_arguments]

        @command = (%w(ansible-playbook) << options << config[:playbook]).flatten.join(" ")
        debug("Ansible push command= %s" % @command)
        @command_env = {
          "PYTHONUNBUFFERED" => "1", # Ensure Ansible output isn't buffered
          "ANSIBLE_FORCE_COLOR" => "true",
          "ANSIBLE_HOST_KEY_CHECKING" => "#{config[:host_key_checking]}",
        }
        @command_env["ANSIBLE_CONFIG"]=config[:ansible_config] if config[:ansible_config]
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
            # Accept the usage of '@' (e.g. '@vars.yml' and 'vars.yml' are both supported)
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
        elsif !@instance_connection_option.nil? and @instance_connection_option[:username]
          config[:remote_user] = @instance_connection_option[:username]
          return @instance_connection_option[:username]
        else
          return false
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