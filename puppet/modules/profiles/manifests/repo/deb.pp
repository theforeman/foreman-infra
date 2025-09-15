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

  include profiles::backup::sender

  restic::repository { 'repo_deb':
    backup_cap_dac_read_search => true,
    backup_path                => [
      $web::vhost::deb::home,
      $web::vhost::deb::stagedir,
      $web::vhost::archivedeb::home,
      $web::vhost::archivedeb::stagedir,
    ],
    backup_post_cmd            => [
      '-/bin/bash -c "/usr/local/bin/restic-prometheus-exporter | sponge /var/lib/prometheus/node-exporter/restic.prom"',
    ],
  }
}
