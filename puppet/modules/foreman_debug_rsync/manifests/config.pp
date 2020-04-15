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
    incoming_chmod  => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
    outgoing_chmod  => 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  }

  if $facts['os']['selinux']['enabled'] {
    include selinux

    selinux::boolean { 'allow_rsync_anon_write': }

    selinux::module { 'rsync_debug':
      ensure    => 'present',
      source_te => 'puppet:///modules/foreman_debug_rsync/rsync_debug.te',
      builder   => 'refpolicy',
    }
  }
}
