require_relative '../../spec_helper'

require 'kitchen'
require 'kitchen/provisioner/ansible_push'

describe 'Options' do
  let(:logged_output)   { StringIO.new }
  let(:logger)          { Logger.new(logged_output) }
  let(:platform) do
    instance_double(Kitchen::Platform, os_type: nil)
  end

  let(:suite) do
    instance_double('Kitchen::Suite', name: 'fries')
  end

  let(:instance) do
    instance_double('Kitchen::Instance', name: 'coolbeans', logger: logger, suite: suite, platform: platform)
  end

  context 'Min options' do
    let(:config) do
      {
        test_base_path: '/b',
        kitchen_root: '/r',
        log_level: :info,
        playbook: 'spec/assets/ansible_test.yml',
        generate_inv: false,
        remote_user: 'test',
        sudo: true,
        sudo_user: 'kitchen'
      }
    end

    let(:provisioner) do
      Kitchen::Provisioner::AnsiblePush.new(config).finalize_config!(instance)
    end

    it 'match min' do
      expect(provisioner.options).to eq(['--become', '--become-user=kitchen',
                                         '--user=test', '--limit='])
    end
  end

  context 'pass password enabled' do
    let(:config) do
      {
        test_base_path: '/b',
        kitchen_root: '/r',
        log_level: :info,
        playbook: 'spec/assets/ansible_test.yml',
        generate_inv: false,
        remote_user: 'test2',
        become: true,
        become_user: 'kitchen2',
        become_method: 'sudo',
        diff: true,
        private_key: '/tmp/rsa_key',
        ask_vault_pass: true,
        start_at_task: 'c1',
        raw_arguments: '-raw',
        timeout: 10,
        force_handlers: true,
        step: true,
        module_path: '/xxx',
        scp_extra_args: 'x',
        sftp_extra_args: 'y',
        ssh_common_args: 'z',
        ssh_extra_args: 'r',
        pass_transport_password: true
        # skip_tags: 'b1',
        # verbose: "vvvv",
        # ansible_connection: 'smart',
        # extra_vars:
        # groups: ""
        # vault_password_file: '/tmp/vaut.key',
      }
    end

    let(:provisioner) do
      Kitchen::Provisioner::AnsiblePush.new(config).finalize_config!(instance)
    end

    let(:transport) do
      class_double('Kitchen::Transport', name: 'hotbeans')
    end

    let(:instance) do
      instance_double('Kitchen::Instance', name: 'coolbeans', transport: transport, logger: logger, suite: suite, platform: platform)
    end

    before do
      allow(transport).to receive(:instance_variable_get).with(:@connection_options).and_return(password: 'mocked_password')
    end

    it 'password is as variable in cmdline' do
      expect(provisioner.options).to include("-e ansible_password='mocked_password'")
    end
  end

  context 'all options' do
    let(:config) do
      {
        test_base_path: '/b',
        kitchen_root: '/r',
        log_level: :info,
        playbook: 'spec/assets/ansible_test.yml',
        generate_inv: false,
        remote_user: 'test2',
        become: true,
        become_user: 'kitchen2',
        become_method: 'sudo',
        diff: true,
        private_key: '/tmp/rsa_key',
        ask_vault_pass: true,
        start_at_task: 'c1',
        raw_arguments: '-raw',
        timeout: 10,
        force_handlers: true,
        step: true,
        module_path: '/xxx',
        scp_extra_args: 'x',
        sftp_extra_args: 'y',
        ssh_common_args: 'z',
        ssh_extra_args: 'r',
        # skip_tags: 'b1',
        # verbose: "vvvv",
        # ansible_connection: 'smart',
        # extra_vars:
        # groups: ""
        # vault_password_file: '/tmp/vaut.key',
        # pass_transport_password: false
      }
    end

    let(:provisioner) do
      Kitchen::Provisioner::AnsiblePush.new(config).finalize_config!(instance)
    end

    it 'match all' do
      expect(provisioner.options).to eq(['--become', '--become-user=kitchen2', '--user=test2', '--become-method=sudo',
                                         '--private-key=/tmp/rsa_key', '--diff', '--ask-vault-pass', '--start-at-task=c1',
                                         '--limit=', '--timeout=10', '--force-handlers=true', '--step=true',
                                         '--module-path=/xxx', '--scp-extra-args=x', '--sftp-extra-args=y', '--ssh-common-args=z',
                                         '--ssh-extra-args=r', '-raw'])
    end
  end
end
