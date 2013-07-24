# == Class: exim
#
# Installs and manages Exim.
#
# === Parameters
#
# [*mail_relay*]
#  Mail relay server.
#
# [*root_email*]
#  Address to forward root email to. Default: root@DOMAIN
#
# === Examples
#
# class { 'exim':
#   mail_relay => 'mail.example.com',
#   root_email => 'root@example.com',
# }
#
# === Authors
#
# Sergey Stankevich
#
class exim (
  $mail_relay = false,
  $root_email = "root@${::domain}"
) {

  # Module compatibility check
  $compatible = [ 'Debian', 'Ubuntu' ]
  if ! ($::operatingsystem in $compatible) {
    fail("Module is not compatible with ${::operatingsystem}")
  }

  # Parameter validation
  if ! $mail_relay {
    fail('exim: mail_relay parameter must not be empty')
  }

  Class['exim::install'] -> Class['exim::config']

  include exim::install
  include exim::config

}
