# @summary A base profile for all machines
class profiles::base (
) {
  include motd
  include puppet
  include ssh
  include timezone
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
}
