# @summary The Dirvish server side
#
# @param backup_location
#   The place to store the backups
# @param symlink_latest
#   Whether to create a symlink called "latest" when a backup completes
# @param use_systemd
#   Use systemd timers instead of cron for nightly execution?
# @param vaults
#   The backups to perform.
# @param overwrite_cronjob
#   Some packages don't provide a default cronjob
class dirvish (
  $backup_location   = '/srv/backups',
  Boolean $symlink_latest = true,
  Hash $vaults = {},
  Boolean $use_systemd = false,
  Boolean $overwrite_cronjob = true,
) {
  contain dirvish::install
  contain dirvish::config
  contain dirvish::service

  Class['dirvish::install'] ~> Class['dirvish::config'] ~> Class['dirvish::service']
}
