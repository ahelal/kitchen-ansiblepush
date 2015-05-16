# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'kitchen-ansible/version'

Gem::Specification.new do |s|
  s.name              = "kitchen-ansiblepush"
  s.version           = Kitchen::AnsiblePush::VERSION
  s.authors           = ["Adham Helal"]
  s.email             = ["adham.helal@gmail.com"]
  s.homepage          = "https://github.com/ahelal/kitchen-ansiblepush"
  s.summary           = "ansible provisioner for test-kitchen"
  candidates          = Dir.glob("{lib}/**/*") +  ['README.md', 'kitchen-ansiblepush.gemspec']
  s.files             = candidates.sort
  s.platform          = Gem::Platform::RUBY
  s.require_paths     = ['lib']
  s.executables       = ['kitchen-ansible-inventory']
  s.rubyforge_project = '[none]'
  s.description       = <<-EOF
== DESCRIPTION:

Ansible push Provisioner for Test Kitchen

== FEATURES:

Supports running ansible in push mode

EOF

  s.add_runtime_dependency 'test-kitchen'
end
