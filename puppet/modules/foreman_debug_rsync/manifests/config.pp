class foreman_debug_rsync::config {

  include 'rsync'
  include 'rsync::server'

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

  if $selinux {
    include selinux

    selinux::boolean { 'allow_rsync_anon_write': }

    package { 'selinux-policy-devel':
      ensure => installed,
    } ->
    selinux::module { 'rsync_debug':
      ensure => 'present',
      source => 'puppet:///modules/foreman_debug_rsync/rsync_debug.te',
    }
  }
}
