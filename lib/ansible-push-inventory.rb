#!/usr/bin/env ruby
require 'yaml'
require 'json'

all =  []
groups =  Hash.new
hosts =  Hash.new
if File.exist?("ansiblepush_groups_inventory.yml")
  groups = YAML::load_file "ansiblepush_groups_inventory.yml"
end

Dir.glob('.kitchen/ansiblepush/ansiblepush_host_*.yml') do |inv_yml|
  vm = YAML::load_file inv_yml
  vm.each do |host, host_attr|
    if host_attr["group"]
      host_attr["group"].each do | group |
      groups[group] ||= []
        groups[group] << host
      end
      host_attr.delete("group")
    end
    hosts[host] = host_attr
    all << host
  end
end
inventory = {'all' => all, "hosts" => hosts}
inventory = groups.merge(inventory)

# Print our inventory
puts JSON.pretty_generate(inventory)