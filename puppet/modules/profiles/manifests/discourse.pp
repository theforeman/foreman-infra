# @summary Manage a Discourse server
# @see https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md
class profiles::discourse {
  $root = '/var/discourse'

  if $facts['os']['family'] == 'RedHat' {
    yumrepo { 'docker-ce-stable':
      descr   => 'Docker CE Stable - $basearch',
      baseurl => 'https://download.docker.com/linux/centos/$releasever/$basearch/stable',
      gpgkey  => 'https://download.docker.com/linux/centos/gpg',
    }

    ensure_packages(['docker-ce'], { require => Yumrepo['docker-ce-stable'] })

    service { 'docker':
      ensure  => 'running',
      enable  => true,
      require => Package['docker-ce'],
    }

    ensure_packages(['git'])

    vcsrepo { $root:
      ensure   => present,
      provider => git,
      source   => 'https://github.com/discourse/discourse_docker.git',
    }
  }

  include profiles::backup::sender

  restic::repository { 'discourse':
    backup_cap_dac_read_search => true,
    backup_path                => ["${root}/containers", "${root}/shared/standalone/backups"],
  }
}
