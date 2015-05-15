TEMP_INV_DIR = ".kitchen/ansiblepush"
TEMP_GROUP_FILE = "#{TEMP_INV_DIR}/ansiblepush_groups_inventory.yml"



def write_instance_inventory(name, host, mygroup)
  Dir.mkdir TEMP_INV_DIR if !File.exist?(TEMP_INV_DIR)
  if mygroup
    host = { name => { 'ansible_ssh_host' => host, 'mygroup' => mygroup } }
  else
    host = { name => { 'ansible_ssh_host' => host } }
  end
  
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