# @summary A profile for the web machines
#
# @param stable
#   Latest release that users expect
#
# @param next
#   Next release (current nightly). To be updated as part of branching.
#
# @param debugs_htpasswds
#   Which htpasswds to create for the debug vhost
#
# @param https
#   Whether to enable HTTPS. This is typically wanted but can only be enabled
#   in a 2 pass setup. First Apache needs to run for Letsencrypt to function.
#   Then Letsencrypt can be enabled. Also useful to turn off in test setups.
#
# @param rsync_max_connections
#   Maximum connection per rsync target. Using a small value to try and reduce
#   server load
class profiles::web (
  String[1] $stable = '3.10',
  String[1] $next = '3.12',
  Hash[String, Hash] $debugs_htpasswds = {},
  Boolean $https = true,
  Integer[0] $rsync_max_connections = 10,
) {
  contain awstats

  contain foreman_debug_rsync

  class { 'web':
    https => $https,
  }
  contain web

  contain web::vhost::archivedeb

  contain web::vhost::deb

  class { 'web::vhost::debugs':
    htpasswds      => $debugs_htpasswds,
  }
  contain web::vhost::debugs

  class { 'web::vhost::downloads':
    rsync_max_connections => $rsync_max_connections,
  }
  contain web::vhost::downloads

  contain web::vhost::stagingdeb

  class { 'web::vhost::web':
    stable => $stable,
    next   => $next,
  }
  contain web::vhost::web

  class { 'web::vhost::yum':
    stable                => $stable,
    rsync_max_connections => $rsync_max_connections,
  }
  contain web::vhost::yum

  contain web::vhost::stagingyum
}
