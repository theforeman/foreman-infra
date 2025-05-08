# @summary A Foreman application server
class profiles::foreman {
  include foreman
  include foreman::repo
  include foreman::compute::libvirt
  include foreman::compute::openstack
  include foreman::plugin::ansible
  include foreman::plugin::puppet
  include foreman::plugin::remote_execution

  include puppet

  puppet::config::main { 'dns_alt_names':
    value => $foreman::serveraliases,
  }

  package {'rubygem-foreman_maintain':
    ensure => present,
  }

  $backup_base_path = '/var/backups'
  $backup_path = "${backup_base_path}/foreman"

  file { $backup_base_path:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
  file { $backup_path:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }

  include profiles::backup::sender

  restic::repository { 'foreman':
    backup_cap_dac_read_search => true,
    backup_path                => $backup_path,
    backup_pre_cmd             => ["+/usr/bin/foreman-maintain backup online --assumeyes --preserve-directory ${backup_path}"],
  }
}
