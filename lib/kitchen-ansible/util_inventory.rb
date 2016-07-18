TEMP_INV_DIR = '.kitchen/ansiblepush'.freeze
TEMP_GROUP_FILE = "#{TEMP_INV_DIR}/ansiblepush_groups_inventory.yml".freeze

def write_var_to_yaml(yaml_file, hash_var)
  Dir.mkdir TEMP_INV_DIR unless File.exist?(TEMP_INV_DIR)
  File.open(yaml_file, 'w') do |file|
    file.write hash_var.to_yaml
  end
end

def generate_instance_inventory(name, host, mygroup, instance_connection_option, ansible_connection)
  unless instance_connection_option.nil?
    port = instance_connection_option[:port]
    keys = instance_connection_option[:keys]
    user = instance_connection_option[:user]
    pass = instance_connection_option[:pass]
  end

  temp_hash = {}
  temp_hash['ansible_ssh_host'] = host
  temp_hash['ansible_ssh_port'] = port if port
  temp_hash['ansible_ssh_private_key_file'] = keys[0] if keys
  temp_hash['ansible_ssh_user'] = user if user
  temp_hash['ansible_ssh_pass'] = pass if pass
  temp_hash['mygroup'] = mygroup if mygroup
  # Windows issue ignore SSL
  if ansible_connection == 'winrm'
    temp_hash['ansible_winrm_server_cert_validation'] = 'ignore'
    temp_hash['ansible_winrm_transport'] = 'ssl' # should be dynamic
  end
  { name => temp_hash }
end
