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

  include profiles::backup::sender

  restic::repository { 'repo_rpm':
    backup_cap_dac_read_search => true,
    backup_path                => [$web::vhost::yum::yum_directory],
    backup_post_cmd            => [
      '-/bin/bash -c "/usr/local/bin/restic-prometheus-exporter | sponge /var/lib/prometheus/node-exporter/restic.prom"',
    ],
  }
}
