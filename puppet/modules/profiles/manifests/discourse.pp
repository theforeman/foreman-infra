# @summary Manage a Discourse server
# @see https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md
class profiles::discourse {
  yumrepo { 'docker-ce-stable':
    descr   => 'Docker CE Stable - $basearch',
    baseurl => 'https://download.docker.com/linux/centos/$releasever/$basearch/stable',
    gpgkey  => 'https://download.docker.com/linux/centos/gpg',
  }

  stdlib::ensure_packages(['docker-ce'], { require => Yumrepo['docker-ce-stable'] })

  service { 'docker':
    ensure  => 'running',
    enable  => true,
    require => Package['docker-ce'],
  }

  include discourse
  $backup_path = ["${discourse::root}/shared/standalone/backups"]

  include profiles::backup::sender

  restic::repository { 'discourse':
    backup_cap_dac_read_search => true,
    backup_path                => $backup_path,
    backup_pre_cmd             => ['+/usr/bin/docker exec app discourse backup'],
    backup_post_cmd            => [
      '-/bin/bash -c "/usr/local/bin/restic-prometheus-exporter | sponge /var/lib/prometheus/node-exporter/restic.prom"',
    ],
  }
}
