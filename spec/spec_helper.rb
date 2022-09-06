
# Add lib dir to Ruby's LOAD_PATH so we can easily require things in there
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'pry'
require 'rspec'

require 'simplecov'
SimpleCov.start

RSpec.configure do |config|
  config.tty = true
  config.color = true
end

def kitchen_root
  $spec_dir ||= File.expand_path(File.join(__dir__, 'assets'))
end
