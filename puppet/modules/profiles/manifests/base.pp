# @summary A base profile for all machines
class profiles::base (
) {
  include motd
  include openvox_repo
  include puppet
  include ssh
  include systemd
  include unattended
  if $facts['os']['family'] == 'RedHat' {
    package { 'ntp':
      ensure => absent,
      before => Class['chrony'],
    }
    include chrony
  } else {
    include ntp
  }

  # Ensure REX can log in
  class { 'foreman_proxy::plugin::remote_execution::ssh_user':
    manage_user => true,
  }

  include profiles::base::monitoring

  file { '/usr/local/sbin/reboot-inactive-system':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file("${module_name}/base/reboot-inactive-system"),
  }
}
