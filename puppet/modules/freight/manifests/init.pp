# Freight setup for Jenkins
#
# Assumes ~jenkins/.gnupg is created and has the Foreman secret key loaded
#
class freight {

  apt::source { 'freight':
    location    => 'http://packages.rcrowley.org',
    release     => 'squeeze',
    repos       => 'main',
    key         => '7DF49CEF',
    key_source  => 'http://packages.rcrowley.org/keyring.gpg',
    include_src => false,
  }

  package { 'freight':
    ensure  => installed,
    require => Apt::Source['freight'],
  }

  $freight_dir = '/var/lib/workspace/freight'

  file { '/etc/freight.conf':
    ensure  => present,
    mode    => 644,
    content => template('freight/freight.conf.erb'),
    require => Package['freight'],
  }

  file { "${freight_dir}":
    ensure => directory,
    owner  => jenkins,
    group  => jenkins,
  }

  file { "${freight_dir}/staged":
    ensure => directory,
    owner  => jenkins,
    group  => jenkins,
  }

  file { "${freight_dir}/web":
    ensure => directory,
    owner  => jenkins,
    group  => jenkins,
  }

  file { '/etc/cron.daily/freight':
    mode    => 755,
    content => template('freight/cron.erb'),
  }

}
