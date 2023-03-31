# @summary A Redmine server
class profiles::redmine (
) {
  include redmine
  $backup_path = $redmine::data_dir

  include profiles::backup::sender

  restic::repository { 'redmine':
    backup_path  => $backup_path,
    backup_flags => ['--exclude', '/git'],
  }
}
