$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'kitchen-ansible/version'

Gem::Specification.new do |gem|
  gem.name              = 'kitchen-ansiblepush'
  gem.version           = Kitchen::AnsiblePush::VERSION
  gem.authors           = ['Adham Helal']
  gem.email             = ['adham.helal@gmail.com']
  gem.licenses          = ['MIT']
  gem.homepage          = 'https://github.com/ahelal/kitchen-ansiblepush'
  gem.summary           = 'ansible provisioner for test-kitchen'
  candidates            = Dir.glob('{lib}/**/*') + ['README.md', 'kitchen-ansiblepush.gemspec', 'callback/changes.py']
  gem.files             = candidates.sort
  gem.platform          = Gem::Platform::RUBY
  gem.require_paths     = ['lib']
  gem.executables       = ['kitchen-ansible-inventory']
  gem.rubyforge_project = '[none]'
  gem.description       = <<-EOF
== DESCRIPTION:

Ansible push Provisioner for Test Kitchen

== FEATURES:

Supports running ansible in push mode

EOF

  gem.add_runtime_dependency 'test-kitchen', '~> 1.4'
end
