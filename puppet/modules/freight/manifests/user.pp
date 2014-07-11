define freight::user (
  $user         = 'freight',
  $home         = '/var/www/freight',
  $webdir       = "${home}/web",
  $stagedir     = "${home}/staged",
  $vhost        = 'deb',
  $cron_matches = 'all',
) {

  secure_rsync::receiver_setup { 'freight':
    user           => $user,
    foreman_search => 'host.hostgroup = Debian and name = ipaddress',
    script_content => template('freight/rsync.erb'),
  }

  file { "${home}/freight.conf":
    ensure  => present,
    mode    => '0644',
    content => template('freight/freight.conf.erb'),
    require => Package['freight'],
  }

  # $webdir should be created too, but since we normally override to point at
  # the vhost, we'll get a duplicate definition
  file { $stagedir:
    ensure => directory,
    owner  => $user,
    group  => $user,
  }

  # Cleanup old stuff
  file { "/etc/cron.daily/${user}":
    mode    => '0755',
    content => template('freight/cron.erb'),
  }

  # Website resources
  apache::vhost { $vhost:
    ensure         => present,
    config_content => template('freight/vhost.erb'),
    user           => $user,
    group          => $user,
    mode           => 0755,
  }

  include rsync::server
  rsync::server::module { $vhost:
    path      => $webdir,
    list      => true,
    read_only => true,
    comment   => "${vhost}.theforeman.org",
    require   => File[$webdir],
    uid       => 'nobody',
    gid       => 'nobody',
  }
  file { "${webdir}/HEADER.html":
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => "puppet:///modules/freight/${vhost}-HEADER.html",
  }
  file { "${webdir}/foreman.asc":
    ensure => link,
    target => 'pubkey.gpg',
    owner  => 'root',
    group  => 'root',
  }
}
