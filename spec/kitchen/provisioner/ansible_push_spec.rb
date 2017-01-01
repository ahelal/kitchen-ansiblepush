require_relative '../../spec_helper'

require 'kitchen'
require 'kitchen/provisioner/ansible_push'
require 'kitchen/errors'

describe Kitchen::Provisioner::AnsiblePush do
  let(:logged_output)   { StringIO.new }
  let(:logger)          { Logger.new(logged_output) }
  let(:platform) do
    instance_double(Kitchen::Platform, os_type: nil)
  end

  let(:config) do
    {
      test_base_path: '/b',
      kitchen_root: '/r',
      log_level: :info
    }
  end

  let(:suite) do
    instance_double('Kitchen::Suite', name: 'fries')
  end

  let(:instance) do
    instance_double('Kitchen::Instance', name: 'coolbeans', logger: logger, suite: suite, platform: platform)
  end

  # let(:machine_name) do
  #   'test'
  # end

  let(:provisioner) do
    Kitchen::Provisioner::AnsiblePush.new(config).finalize_config!(instance)
  end

  it 'provisioner api_version is 2' do
    expect(provisioner.diagnose_plugin[:api_version]).to eq(2)
  end

  it 'Should fail with no playbook file' do
    expect { provisioner.prepare_command }.to raise_error(Kitchen::UserError)
  end

  describe 'Baisc config' do
    let(:config) do
      {
        test_base_path: '/b',
        kitchen_root: '/r',
        log_level: :info,
        playbook: 'spec/assets/ansible_test.yml',
        generate_inv: false,
        remote_user: 'test'
      }
    end
    it 'prepare_command should be' do
      expect(provisioner.prepare_command).to be
    end
    it 'should set playbookname' do
      expect(config[:playbook]).to match('spec/assets/ansible_test.yml')
    end
    it 'User should be set' do
      expect(config[:remote_user]).to match('test')
    end
  end
end
