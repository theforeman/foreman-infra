# @summary A Redmine server
class profiles::redmine (
) {
  # Redmine is already included via ENC
  # TODO include redmine
  $backup_path = '/var/lib/redmine'

  class {'profiles::backup::sender':
    username => $redmine::username,
  }

  restic::repository { 'redmine':
    backup_path    => $backup_path,
    backup_flags   => ['--exclude', "${backup_path}/git"],
    backup_pre_cmd => ["pg_dump --file=${backup_path}/redmine.backup.sql $redmine::db_name"],
    user           => $redmine::username,
  }
}
