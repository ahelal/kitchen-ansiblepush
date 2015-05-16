# -*- encoding: utf-8 -*-


# Add lib dir to Ruby's LOAD_PATH so we can easily require things in there
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'pry'
require 'rspec'


RSpec.configure do |config|
  config.tty = true
  config.color = true
end