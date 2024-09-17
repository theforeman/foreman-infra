# @summary A profile for the rpm repo machines
#
# @param stable_foreman
#   Latest Foreman release that users expect
#
# @param https
#   Whether to enable HTTPS. This is typically wanted but can only be enabled
#   in a 2 pass setup. First Apache needs to run for Letsencrypt to function.
#   Then Letsencrypt can be enabled. Also useful to turn off in test setups.
class profiles::repo::rpm (
  String[1] $stable_foreman,
  Boolean $https = true,
) {
  class { 'web':
    https      => $https,
    all_in_one => false,
  }
  contain web

  class { 'web::vhost::rpm':
    stable_foreman => $stable_foreman,
  }
  contain web::vhost::rpm

  contain web::vhost::stagingrpm
}
