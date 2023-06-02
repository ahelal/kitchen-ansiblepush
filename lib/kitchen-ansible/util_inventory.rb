require 'fileutils'

TEMP_INV_DIR = '.kitchen/ansiblepush'.freeze
TEMP_GROUP_FILE = "ansiblepush_groups_inventory.yml".freeze

def write_var_to_yaml(yaml_file, hash_var)
  base_path = File.dirname(yaml_file)
  FileUtils.mkdir_p base_path unless File.exist?(base_path)
  File.open(yaml_file, 'w') do |file|
    file.write hash_var.to_yaml
  end
end

def generate_instance_inventory(name, host, mygroup, instance_connection_option, conf)
  unless instance_connection_option.nil?
    port = instance_connection_option[:port]
    keys = instance_connection_option[:keys]
    user = instance_connection_option[:user]
    pass = instance_connection_option[:pass] if instance_connection_option[:pass]
    pass = instance_connection_option[:password] if instance_connection_option[:password]
  end

  temp_hash = {}
  temp_hash['ansible_host'] = host
  temp_hash['ansible_ssh_host'] = host
  temp_hash['ansible_ssh_port'] = port if port
  temp_hash['ansible_ssh_private_key_file'] = keys[0] if keys
  temp_hash['ansible_ssh_user'] = user if user
  temp_hash['ansible_ssh_pass'] = pass if pass
  temp_hash['mygroup'] = mygroup if mygroup
  temp_hash['ansible_ssh_port'] = conf[:ansible_port] if conf[:ansible_port]
  # Windows issue ignore SSL
  if conf[:ansible_connection] == 'winrm'
    temp_hash['ansible_winrm_server_cert_validation'] = 'ignore'
    temp_hash['ansible_winrm_transport'] = 'ssl'
    temp_hash['ansible_connection'] = 'winrm'
    temp_hash['ansible_user'] = temp_hash['ansible_ssh_user']
  end
  { name => temp_hash }
end
