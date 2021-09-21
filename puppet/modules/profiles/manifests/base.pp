# @summary A base profile for all machines
class profiles::base (
) {
  include puppet
  include ssh
  include timezone
  include users
  include utility
  if $facts['os']['family'] == 'RedHat' and versioncmp($facts['os']['release']['major'], '8') >= 0 {
    include chrony
  } else {
    include ntp
  }
}
