class freight2::config {

  $freight_home = '/srv/freight'
  $freight_user = 'freight'

  # Setup the user, group, and ssh keys
  class { 'freight2::user':
    user => $freight_user,
    home => $freight_home,
  }

  file { '/etc/freight.conf':
    ensure  => present,
    mode    => 644,
    content => template('freight2/freight.conf.erb'),
    require => Package['freight'],
  }

  file { "${freight_home}/staged":
    ensure => directory,
    owner  => $freight_user,
    group  => $freight_user,
  }

  file { "${freight_home}/web":
    ensure => directory,
    owner  => $freight_user,
    group  => $freight_user,
  }

  file { "${freight_home}/rsync_cache":
    ensure => directory,
    owner  => $freight_user,
    group  => $freight_user,
  }

  file { '/etc/cron.daily/freight':
    mode    => 755,
    content => template('freight2/cron.erb'),
  }

}
