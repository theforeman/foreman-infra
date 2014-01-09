class foreman_debug_rsync::config {

  include 'rsync'
  include 'rsync::server'

  file { $foreman_debug_rsync::base:
    ensure => directory,
    mode   => 775,
    owner  => 'nobody',
    group  => 'nobody',
  }

  rsync::server::module{ 'debug-incoming':
    path            => $foreman_debug_rsync::base,
    require         => File[$foreman_debug_rsync::base],
    comment         => 'Write-only place for foreman-debug',
    max_connections => 15,
    read_only       => 'no',
    write_only      => 'yes',
    list            => 'no',
    uid             => 'nobody',
    gid             => 'nobody',
  }

}
