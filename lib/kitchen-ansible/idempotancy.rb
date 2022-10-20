require 'securerandom'

def idempotency_test
  info('*************** idempotency test ***************')
  conf[:playbooks].each do |playbook|
    _idempotency_test_single(playbook)
  end
end

def _idempotency_test_single(playbook)
  file_path = "/tmp/kitchen_ansible_callback/#{SecureRandom.uuid}.changes"
  exec_ansible_command(
    command_env.merge(
      'ANSIBLE_CALLBACK_PLUGINS'   => "#{File.dirname(__FILE__)}/../../callback/",
      'ANSIBLE_CALLBACK_WHITELIST' => 'changes',
      'PLUGIN_CHANGES_FILE'        => file_path
    ),
    command(playbook),
    'ansible-playbook'
  )
  debug("idempotency file #{file_path}")
  # Check ansible callback if changes has occured in the second run
  if File.file?(file_path)
    task = 0
    info('idempotency test [Failed]')
    File.open(file_path, 'r') do |f|
      f.each_line do |line|
        task += 1
        info(" #{task}> #{line.strip}")
      end
    end
    raise "idempotency test Failed. Number of non idempotent tasks: #{task}" if conf[:fail_non_idempotent]
    # If we reach this point we should give a warning
    info('Warning idempotency test [failed]')
  else
    info('idempotency test [passed]')
  end
end
