# @summary A Puppetserver with Foreman integration
class profiles::puppetserver {
  include puppet
  include puppet::server

  include foreman::repo
  class { 'foreman_proxy':
    puppet   => true,
    puppetca => true,
  }
  include foreman_proxy::plugin::ansible
  include foreman_proxy::plugin::remote_execution::script

  class { 'deploy':
    user => $puppet::server_environments_owner,
  }
}
