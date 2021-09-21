# @summary A base profile for all machines
class profiles::base (
) {
  include puppet
  include ssh
  include timezone
  include users
  include utility
  unless $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '8' {
    include ntp
  } else {
    include chrony
  }
}
