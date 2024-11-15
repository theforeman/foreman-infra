# @summary A profile for the machines hosting the website and downloads
#
# @param stable
#   Latest release that users expect
class profiles::website (
  String[1] $stable,
) {
  contain web

  contain web::vhost::downloads

  class { 'web::vhost::web':
    stable => $stable,
  }
  contain web::vhost::web
}
