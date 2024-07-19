# @summary A profile for the debian repo machines
#
# @param stable
#   Latest release that users expect
#
# @param https
#   Whether to enable HTTPS. This is typically wanted but can only be enabled
#   in a 2 pass setup. First Apache needs to run for Letsencrypt to function.
#   Then Letsencrypt can be enabled. Also useful to turn off in test setups.
class profiles::repo::deb (
  String[1] $stable,
  Boolean $https = true,
) {
  class { 'web':
    https => $https,
  }
  contain web

  contain web::vhost::archivedeb

  class { 'web::vhost::deb':
    stable => $stable,
  }
  contain web::vhost::deb

  contain web::vhost::stagingdeb
}
