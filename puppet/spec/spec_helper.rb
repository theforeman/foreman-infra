require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'
include RspecPuppetFacts

add_custom_fact :concat_basedir, '/doesnotexist'
add_custom_fact :root_home, '/root'
add_custom_fact :rvm_installed, false
