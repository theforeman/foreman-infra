# @summary A Foreman application server
class profiles::foreman {
  include foreman
  include foreman::repo
  include foreman::compute::libvirt
  include foreman::compute::openstack
  include foreman::plugin::ansible
  include foreman::plugin::puppet
  include foreman::plugin::remote_execution

  puppet::config::main { 'dns_alt_names':
    value => $foreman::serveraliases,
  }
}
