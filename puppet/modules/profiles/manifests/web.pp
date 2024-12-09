# @summary A profile for the web machines
#
# @param stable
#   Latest release that users expect
class profiles::web (
  String[1] $stable,
) {
  contain web

  contain web::vhost::downloads

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
