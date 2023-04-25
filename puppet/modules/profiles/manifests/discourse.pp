# @summary Manage a Discourse server
# @see https://github.com/discourse/discourse/blob/main/docs/INSTALL-cloud.md
class profiles::discourse {
  $root = '/var/discourse'
  # TODO: manage docker
  # TODO: vcsrepo https://github.com/discourse/discourse_docker.git on $root

  include profiles::backup::sender

  restic::repository { 'discourse':
    backup_cap_dac_read_search => true,
    backup_path                => ["${root}/containers", "${root}/shared/standalone/backups"],
  }
}
