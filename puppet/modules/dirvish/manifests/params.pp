class dirvish::params {

  # The place to store the backups
  $backup_location  = "/srv/backups"

  # Whether to create a symlink called "latest" when a
  # backup completes
  $symlink_latest   = true

  # Use systemd timers instead of cron for nightly execution?
  $use_systemd = false

  # The backups to perform. This is an example.
  $vaults = {
    test       => {
      client   => 'myclient',
      tree     => '/etc',
      excludes => [
        '*hosts*',
        '/etc/puppet'
      ]
    }
  }

  # Some packages don't provide a default cronjob
  $overwrite_cronjob = true

}
