# Clean out old tarballs
class foreman_debug_rsync::cron {
  cron { 'remove-old-tarballs':
    command => "/usr/bin/find ${foreman_debug_rsync::base} -type f -mtime +90 -exec rm {} \\;",
    user    => 'nobody',
    hour    => 3,
    minute  => 0,
  }
}
