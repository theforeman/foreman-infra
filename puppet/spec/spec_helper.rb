RSpec.configure do |c|
  c.mock_with :rspec
end

require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
include RspecPuppetFacts

add_custom_fact :root_home, '/root'
add_custom_fact :rvm_installed, false
add_custom_fact :sudoversion, '1.8.23'
