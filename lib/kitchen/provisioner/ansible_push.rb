require 'json'
require 'open3'
require 'kitchen'
require 'kitchen/errors'
require 'kitchen/provisioner/base'
require 'kitchen-ansible/util_inventory'
require 'kitchen-ansible/chef_installation'
require 'kitchen-ansible/idempotancy'

module Kitchen
  class Busser
    def non_suite_dirs
      %w[{data}]
    end
  end

  module Provisioner
    class AnsiblePush < Base
      kitchen_provisioner_api_version 2
      default_config :ansible_playbook_bin, 'ansible-playbook'
      default_config :ansible_config, nil
      default_config :verbose, nil
      default_config :diff, nil
      default_config :groups, nil
      default_config :extra_vars, nil
      default_config :sudo, nil
      default_config :become, nil
      default_config :become_user, nil
      default_config :become_method, nil
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
      default_config :generate_inv_path, '`which kitchen-ansible-inventory`'
      default_config :raw_arguments, nil
      default_config :idempotency_test, false
      default_config :fail_non_idempotent, true
      default_config :use_instance_name, false
      default_config :ansible_connection, 'smart'
      default_config :timeout, nil
      default_config :force_handlers, nil
      default_config :step, nil
      default_config :module_path, nil
      default_config :scp_extra_args, nil
      default_config :sftp_extra_args, nil
      default_config :ssh_extra_args, nil
      default_config :ssh_common_args, nil
      default_config :module_path, nil
      default_config :pass_transport_password, false
      default_config :environment_vars, {}

      # For tests disable if not needed
      default_config :chef_bootstrap_url, 'https://omnitruck.chef.io/install.sh'

      # Validates the config and returns it.  Has side-effect of
      # possibly setting @extra_vars which doesn't seem to be used
      def conf
        return @validated_config if defined? @validated_config

        raise UserError, 'No playbook defined. Please specify one in .kitchen.yml' unless config[:playbook]

        raise UserError, "playbook '#{config[:playbook]}' could not be found. Please check path" unless File.exist?(config[:playbook])

        if config[:vault_password_file] && !File.exist?(config[:vault_password_file])
          raise UserError, "Vault password '#{config[:vault_password_file]}' could not be found. Please check path"
        end

        # Validate that extra_vars is either a hash, or a path to an existing file
        if config[:extra_vars]
          extra_vars_is_valid = config[:extra_vars].is_a?(Hash) || config[:extra_vars].is_a?(String)
          if config[:extra_vars].is_a?(String)
            # Accept the usage of '@' (e.g. '@vars.yml' and 'vars.yml' are both supported)
            match_data = /^@?(.+)$/.match(config[:extra_vars])
            extra_vars_path = match_data[1].to_s
            expanded_path = Pathname.new(extra_vars_path).expand_path(Dir.pwd)
            extra_vars_is_valid = expanded_path.exist?

            @extra_vars = '@' + extra_vars_path if extra_vars_is_valid
          end

          raise UserError, "ansible extra_vars is in valid type: #{config[:extra_vars].class} value: #{config[:extra_vars]}" unless extra_vars_is_valid
        end

        unless config[:environment_vars].is_a?(Hash)
          raise UserError,
                "ansible environment_vars is not a `Hash` type. Given type: #{config[:environment_vars].class}"
        end

        info('Ansible push config validated')
        @validated_config = config
      end

      def machine_name
        return @machine_name if defined? @machine_name
        @machine_name = if config[:use_instance_name]
                          instance.name.gsub(/[<>]/, '')
                        elsif config[:custom_instance_name]
                          config[:custom_instance_name]
                        else
                          instance.name.gsub(/[<>]/, '').split('-').drop(1).join('-')
                        end
        debug('machine_name=' + @machine_name.to_s)
        @machine_name
      end

      def options_user
        ## Support sudo and become
        temp_options = []
        raise UserError, '"sudo" and "become" are mutually_exclusive' if conf[:sudo] && conf[:become]
        temp_options << '--become' if conf[:sudo] || conf[:become]

        raise UserError, '"sudo_user" and "become_user" are mutually_exclusive' if conf[:sudo_user] && conf[:become_user]
        if conf[:sudo_user]
          temp_options << "--become-user=#{conf[:sudo_user]}"
        elsif conf[:become_user]
          temp_options << "--become-user=#{conf[:become_user]}"
        end
        temp_options << "--user=#{conf[:remote_user]}" if remote_user
        temp_options << "--become-method=#{conf[:become_method]}" if conf[:become_method]
        temp_options << '--ask-sudo-pass' if conf[:ask_sudo_pass]

        # if running on windows in ec2 and password is obtained via get-password
        temp_options << "-e ansible_password='#{instance.transport.instance_variable_get(:@connection_options)[:password]}'" if conf[:pass_transport_password]

        temp_options
      end

      def options
        return @options if defined? @options
        # options = options_user | options
        options = options_user
        options << "--extra-vars='#{extra_vars_argument}'" if conf[:extra_vars]
        options << "--private-key=#{conf[:private_key]}" if conf[:private_key]
        options << '--diff' if conf[:diff]
        options << '--ask-vault-pass' if conf[:ask_vault_pass]
        options << "--vault-password-file=#{conf[:vault_password_file]}" if conf[:vault_password_file]
        options << "--tags=#{as_list_argument(conf[:tags])}" if conf[:tags]
        options << "--skip-tags=#{as_list_argument(conf[:skip_tags])}" if conf[:skip_tags]
        options << "--start-at-task=#{conf[:start_at_task]}" if conf[:start_at_task]
        options << "--inventory-file=#{conf[:generate_inv_path]}" if conf[:generate_inv]
        options << verbosity_argument.to_s if conf[:verbose]
        # By default we limit by the current machine,
        options << if conf[:limit]
                     "--limit=#{as_list_argument(conf[:limit])}"
                   else
                     "--limit=#{machine_name}"
                   end
        options << "--timeout=#{conf[:timeout]}" if conf[:timeout]
        options << "--force-handlers=#{conf[:force_handlers]}" if conf[:force_handlers]
        options << "--step=#{conf[:step]}" if conf[:step]
        options << "--module-path=#{conf[:module_path]}" if conf[:module_path]
        options << "--scp-extra-args=#{conf[:scp_extra_args]}" if conf[:scp_extra_args]
        options << "--sftp-extra-args=#{conf[:sftp_extra_args]}" if conf[:sftp_extra_args]
        options << "--ssh-common-args=#{conf[:ssh_common_args]}" if conf[:ssh_common_args]
        options << "--ssh-extra-args=#{conf[:ssh_extra_args]}" if conf[:ssh_extra_args]
        # Add raw argument at the end
        options << conf[:raw_arguments] if conf[:raw_arguments]
        @options = options
      end

      def command
        return @command if defined? @command
        @command = [conf[:ansible_playbook_bin]]
        @command = (@command << options << conf[:playbook]).flatten.join(' ')
        debug("Ansible push command= #{@command}")
        @command
      end

      def command_env
        return @command_env if defined? @command_env
        @command_env = {
          'PYTHONUNBUFFERED' => '1', # Ensure Ansible output isn't buffered
          'ANSIBLE_FORCE_COLOR' => 'true',
          'ANSIBLE_HOST_KEY_CHECKING' => conf[:host_key_checking].to_s
        }
        @command_env['ANSIBLE_CONFIG'] = conf[:ansible_config] if conf[:ansible_config]

        # NOTE: Manually merge to fix keys possibly being Symbol(s)
        conf[:environment_vars].each do |key, value|
          @command_env[key.to_s] = value
        end
        @command_env
      end

      def prepare_command
        prepare_inventory if conf[:generate_inv]
        # Place holder so a string is returned. This will execute true on remote host
        true_command
      end

      def true_command
        # Place holder so a string is returned. This will execute true on remote host
        if conf[:ansible_connection] == 'winrm'
          '$TRUE'
        else
          'true'
        end
      end

      def install_command
        info('*************** AnsiblePush install_command ***************')
        # Test if ansible-playbook is installed and give a meaningful error message
        version_check = command + ' --version'
        _, stdout, stderr, wait_thr = Open3.popen3(command_env, version_check)
        exit_status = wait_thr.value
        raise UserError, "#{version_check} returned a non zero '#{exit_status}' stdout : '#{stdout.read}', stderr: '#{stderr.read}'" unless exit_status.success?
        omnibus_download_dir = conf[:omnibus_cachier] ? '/tmp/vagrant-cache/omnibus_chef' : '/tmp'
        chef_installation(conf[:chef_bootstrap_url], omnibus_download_dir)
      end

      def chef_installation(chef_url, omnibus_download_dir)
        if chef_url && (chef_url != 'nil') # ignore string nil
          scripts = []
          scripts << Util.shell_helpers
          scripts << chef_installation_script(chef_url, omnibus_download_dir)
          <<-INSTALL
            sh -c #{scripts.join("\n")}
          INSTALL
        else
          true_command # Place holder so a string is returned. This will execute true on remote host
        end
      end

      def run_command
        info('*************** AnsiblePush run ***************')
        exec_ansible_command(command_env, command, 'ansible-playbook')
        idempotency_test if conf[:idempotency_test]
        info('*************** AnsiblePush end run *******************')
        debug("[#{name}] Converge completed (#{conf[:sleep]}s).")
        true_command # Place holder so a string is returned. This will execute true on remote host
      end

      protected

      def exec_ansible_command(env, command, desc)
        debug("env=#{env} command=#{command}")
        system(env, command.to_s)
        exit_code = $CHILD_STATUS.exitstatus
        debug("ansible-playbook exit code = #{exit_code}")
        raise UserError, "#{desc} returned a non zero #{exit_code}. Please see the output above." if exit_code.to_i != 0
      end

      def instance_connection_option
        return @instance_connection_option if defined? @instance_connection_option
        @instance_connection_option = instance.transport.instance_variable_get(:@connection_options)
        debug('instance_connection_option=' + @instance_connection_option.to_s)
        @instance_connection_option
      end

      def prepare_inventory
        if instance_connection_option.nil?
          hostname = machine_name
        elsif !instance_connection_option[:hostname].nil?
          hostname = instance_connection_option[:hostname]
        elsif !instance_connection_option[:endpoint].nil?
          require 'uri'
          urlhost = URI.parse(instance_connection_option[:endpoint])
          hostname = urlhost.host
        end
        debug("hostname='#{hostname}'")
        # Generate hosts
        hosts = generate_instance_inventory(machine_name, hostname, conf[:mygroup], instance_connection_option, conf)
        write_var_to_yaml("#{TEMP_INV_DIR}/ansiblepush_host_#{machine_name}.yml", hosts)
        # Generate groups (if defined)
        write_var_to_yaml(TEMP_GROUP_FILE, conf[:groups]) if conf[:groups]
      end

      def extra_vars_argument
        if conf[:extra_vars].is_a?(String) && conf[:extra_vars] =~ /^@.+$/
          # A JSON or YAML file is referenced
          conf[:extra_vars]
        else
          # Expected to be a Hash after config validation.
          conf[:extra_vars].to_json
        end
      end

      def remote_user
        if conf[:remote_user]
          conf[:remote_user]
        elsif !instance_connection_option.nil? && instance_connection_option[:username]
          conf[:remote_user] = instance_connection_option[:username]
          instance_connection_option[:username]
        else
          false
        end
      end

      def as_list_argument(v)
        v.is_a?(Array) ? v.join(',') : v
      end

      def verbosity_argument
        if conf[:verbose].to_s =~ /^v+$/
          # ansible-playbook accepts "silly" arguments like '-vvvvv' as '-vvvv' for now
          "-#{conf[:verbose]}"
        else
          # safe default, in case input strays
          '-v'
        end
      end
    end
  end
end
