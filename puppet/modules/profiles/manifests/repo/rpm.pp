# @summary A profile for the rpm repo machines
#
# @param stable_foreman
#   Latest Foreman release that users expect
class profiles::repo::rpm (
  String[1] $stable_foreman,
) {
  contain web

  class { 'web::vhost::yum':
    stable => $stable_foreman,
  }
  contain web::vhost::yum

  contain web::vhost::stagingyum

  class { 'web::vhost::rpm':
    stable_foreman => $stable_foreman,
  }
  contain web::vhost::rpm

  contain web::vhost::stagingrpm
}
