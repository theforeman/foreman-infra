# @summary A profile for the debian repo machines
#
# @param stable
#   Latest release that users expect
class profiles::repo::deb (
  String[1] $stable,
) {
  contain web

  contain web::vhost::archivedeb

  class { 'web::vhost::deb':
    stable => $stable,
  }
  contain web::vhost::deb

  contain web::vhost::stagingdeb
}
