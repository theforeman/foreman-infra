class munin::client {
  package { 'munin-node':
    ensure => present
  }

  file { '/var/log/munin-node':
   ensure => directory
  }

  file { '/etc/munin/munin-node.conf':
    ensure => present,
    source => "puppet:///modules/munin/munin-node.conf",
    notify => Service['munin-node'],
    require => [Package['munin-node'],File['/var/log/munin-node']],
  }

  @@file { "/etc/munin/conf.d/$hostname":
     content => template("munin/munin-node-exported.cfg.erb"),
     tag => "munin",
  }

  service { 'munin-node':
    enable => true,
    ensure => running,
    require => Package['munin-node']
  }

}
