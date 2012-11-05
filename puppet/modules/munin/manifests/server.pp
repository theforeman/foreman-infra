class munin::server {
  package { 'munin':
    ensure => present
  }

  file { '/etc/munin/conf.d':
    ensure => directory,
    require => Package['munin']
  }

  File <<| tag == 'munin' |>>
}
