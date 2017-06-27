# Freight toplevel class
#
# Dependencies
#
# * puppetlabs-apt
#
# Assumptions
#
#   Assumes ~freight/.gnupg exists and has the repo secret key loaded
#
# Further setup
#
#   You probably want to point a vhost at $freight_home
#
class freight($https = false) {

  contain ::freight::install
  contain ::freight::config

  Class['freight::install'] ~> Class['freight::config']
}
