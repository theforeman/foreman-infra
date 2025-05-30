require 'rspec-puppet'
require 'rspec-puppet-facts'
include RspecPuppetFacts

add_custom_fact :root_home, '/root'
add_custom_fact :service_provider, 'systemd'
add_custom_fact :sudoversion, '1.8.23'

def on_supported_os(opts = {})
  opts[:supported_os] ||= [
    {
      'operatingsystem'        => 'CentOS',
      'operatingsystemrelease' => ['9'],
    },
    {
      'operatingsystem'        => 'Debian',
      'operatingsystemrelease' => ['11', '12'],
    },
  ]
  super(opts)
end

base_dir = File.dirname(File.expand_path(__dir__))

RSpec.configure do |c|
  c.module_path     = [File.join(base_dir, 'modules'), File.join(base_dir, 'external_modules'), File.join(base_dir, 'test_modules')].join(File::PATH_SEPARATOR)
  c.hiera_config    = File.join(base_dir, 'hiera.yaml')
  c.environmentpath = base_dir
  c.strict_variables = true
end
