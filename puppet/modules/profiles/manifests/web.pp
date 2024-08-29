# @summary A profile for the web machines
#
# @param stable
#   Latest release that users expect
#
# @param debugs_htpasswds
#   Which htpasswds to create for the debug vhost
#
# @param https
#   Whether to enable HTTPS. This is typically wanted but can only be enabled
#   in a 2 pass setup. First Apache needs to run for Letsencrypt to function.
#   Then Letsencrypt can be enabled. Also useful to turn off in test setups.
class profiles::web (
  String[1] $stable,
  Hash[String, Hash] $debugs_htpasswds = {},
  Boolean $https = true,
) {
  contain awstats

  class { 'web':
    https => $https,
  }
  contain web

  contain web::vhost::archivedeb

  contain web::vhost::deb

  class { 'web::vhost::debugs':
    htpasswds => $debugs_htpasswds,
  }
  contain web::vhost::debugs

  contain web::vhost::downloads

  contain web::vhost::stagingdeb

  class { 'web::vhost::web':
    stable => $stable,
  }
  contain web::vhost::web

  class { 'web::vhost::yum':
    stable => $stable,
  }
  contain web::vhost::yum

  contain web::vhost::stagingyum
}
