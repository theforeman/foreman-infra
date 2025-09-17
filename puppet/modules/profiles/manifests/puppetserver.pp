# @summary A Puppetserver with Foreman integration
class profiles::puppetserver {
  include openvox_repo
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

  include profiles::backup::sender

  restic::repository { 'puppetserver':
    backup_cap_dac_read_search => true,
    backup_path                => [
      '/etc/puppetlabs/puppet/data',
      '/etc/puppetlabs/puppet/ssl',
      '/opt/puppetlabs/server/data/puppetserver/ssh',
      '/opt/puppetlabs/server/data/puppetserver/foreman_cache_data',
    ],
    backup_post_cmd            => [
      '-/bin/bash -c "/usr/local/bin/restic-prometheus-exporter | sponge /var/lib/prometheus/node-exporter/restic.prom"',
    ],
  }
}
