TEMP_INV_DIR = ".kitchen/ansiblepush"
TEMP_GROUP_FILE = "#{TEMP_INV_DIR}/ansiblepush_groups_inventory.yml"



def write_instance_inventory(name, host, mygroup, instance_connection_option, ansible_connection)
  Dir.mkdir TEMP_INV_DIR if !File.exist?(TEMP_INV_DIR)

  unless instance_connection_option.nil?
        port = instance_connection_option[:port]
        keys = instance_connection_option[:keys]
        user = instance_connection_option[:user]
        pass = instance_connection_option[:pass]
  end

  temp_hash = Hash.new
  temp_hash["ansible_ssh_host"] = host
  temp_hash["ansible_ssh_port"] = port if port
  temp_hash["ansible_ssh_private_key_file"] = keys[0] if keys
  temp_hash["ansible_ssh_user"] = user if user
  temp_hash["ansible_ssh_pass"] = pass if pass
  temp_hash["mygroup"] = mygroup if mygroup
  # WIndows issue ignore SSL
  if ansible_connection == "winrm"
    temp_hash["ansible_winrm_server_cert_validation"] = "ignore"
    temp_hash["ansible_winrm_transport"] = "ssl"
  end

  host = { name => temp_hash }
  File.open("%s/ansiblepush_host_%s.yml" % [TEMP_INV_DIR, name], "w") do |file|
    file.write host.to_yaml
  end
end

def write_group_inventory(groups)
  Dir.mkdir TEMP_INV_DIR if !File.exist?(TEMP_INV_DIR)
  File.open(TEMP_GROUP_FILE, "w") do |file|
    file.write groups.to_yaml
  end
end
