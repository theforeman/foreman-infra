# @summary A profile for the web machines
#
# @param stable
#   Latest release that users expect
class profiles::web (
  String[1] $stable,
) {
  contain web

  contain web::vhost::archivedeb

  class { 'web::vhost::deb':
    stable => $stable,
  }
  contain web::vhost::deb

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
