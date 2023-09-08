# @summary A Redmine server
class profiles::redmine (
) {
  # Redmine is already included via ENC
  # TODO include redmine
  $backup_path = '/var/lib/redmine'

  include profiles::backup::sender
  include redmine

  include sudo
  sudo::conf { "sudo-puppet-backup-redmine":
    content => "restic ALL=($redmine::username) NOPASSWD: /usr/bin/pg_dump",
  }

  restic::repository { 'redmine':
    backup_cap_dac_read_search => true,
    backup_path                => $backup_path,
    backup_flags               => ['--exclude', "${backup_path}/git"],
    backup_pre_cmd             => ["/usr/bin/sudo -u $redmine::username pg_dump --file=${backup_path}/redmine.backup.sql $redmine::db_name"],
  }
}
