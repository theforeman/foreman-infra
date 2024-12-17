# @summary A base profile for all machines
class profiles::base (
) {
  include motd
  include puppet
  include ssh
  include timezone
  include unattended
  include users
  include utility
  include profiles::base::sysadmins
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
}
