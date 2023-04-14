# @summary A Redmine server
class profiles::redmine (
) {
  # Redmine is already included via ENC
  # TODO include redmine
  $backup_path = '/var/lib/redmine'

  include profiles::backup::sender

  restic::repository { 'redmine':
    backup_path  => $backup_path,
    backup_flags => ['--exclude', '/git'],
  }
}
