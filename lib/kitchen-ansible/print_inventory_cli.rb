#!/usr/bin/env ruby
require 'yaml'
require 'json'
require 'kitchen-ansible/util_inventory.rb'

class PrintInventory
  def initialize
    @inventory = {}
    @all = []
    @groups = if File.exist?(TEMP_GROUP_FILE)
                read_from_yaml TEMP_GROUP_FILE
              else
                {}
              end
    @hosts = {}
  end

  def read_from_yaml(yaml_file)
    YAML.load_file yaml_file
  end

  def read_all_hosts
    Dir.glob(TEMP_INV_DIR + '/ansiblepush_host_*.yml')
  end

  def construct
    read_all_hosts.each do |inv_yml|
      vm = read_from_yaml inv_yml
      vm.each do |host, host_attr|
        if host_attr['mygroup']
          if host_attr['mygroup'].is_a?(Hash)
            host_attr['mygroup'].each do |group|
              @groups[group] ||= []
              @groups[group] << host
            end
          elsif host_attr['mygroup'].is_a?(String)
            @groups[host_attr['mygroup']] ||= []
            @groups[host_attr['mygroup']] << host
          elsif host_attr['mygroup'].is_a?(Array)
            host_attr['mygroup'].each do |group|
              @groups[group] ||= []
              @groups[group] << host
            end
          end
        end
        host_attr.delete('mygroup')
        @hosts[host] = host_attr
        @all << host
      end
    end

    @inventory = { 'all' => @all, '_meta' => { 'hostvars' => @hosts } }
    @groups.merge(@inventory)
  end

  def output_json
    puts JSON.pretty_generate(@inventory)
  end

  def run
    @inventory = construct
    output_json
  end
end
