define freight::user (
  $user         = 'freight',
  $home         = '/var/www/freight',
  $vhost        = 'deb',
  $cron_matches,
) {
  include rsync::server

  # Disable password, we want this to be keys only
  user { $user:
    ensure     => present,
    home       => $home,
    managehome => true,
    password   => '!',
  }

  file { $home:
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => 0755,
  }

  file { "${home}/.ssh":
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => 0700,
  }

  file { "${home}/freight.conf":
    ensure  => present,
    mode    => 644,
    content => template('freight/freight.conf.erb'),
    require => Package['freight'],
  }

  file { ["${home}/staged", "${home}/web", "${home}/rsync_cache"]:
    ensure => directory,
    owner  => $user,
    group  => $user,
  }

  # Read the freight key from the puppetmaster
  $pub_key  = ssh_keygen({name => 'freight_key', public => 'public'})

  # Get the IPs of the Debian slaves from foreman
  $ip_data=foreman({
    'item'         => 'fact_values',
    'search'       => 'host.hostgroup = Debian and name = ipaddress',
    'foreman_user' => $::foreman_api_user,
    'foreman_pass' => $::foreman_api_password,
  })

  file { "${home}/.ssh/authorized_keys":
    ensure  => present,
    owner   => $user,
    group   => $user,
    mode    => 0644,
    content => template('freight/keys.erb'),
  }

  # Create validation script for rsync connections only
  file { "${home}/bin":
    ensure => directory,
    owner  => $user,
    group  => $user,
    mode   => 0755,
  }

  file { "${home}/bin/freight_rsync":
    ensure  => present,
    owner   => $user,
    group   => $user,
    mode    => 0755,
    content => template('freight/rsync.erb'),
  }

  # Cleanup old stuff
  file { "/etc/cron.daily/${user}":
    mode    => 755,
    content => template('freight/cron.erb'),
  }

  apache::vhost { $vhost:
    ensure         => present,
    config_content => template("freight/vhost.erb"),
    require        => File["${home}/web"],
  }
  rsync::server::module { $vhost:
    path      => "${home}/web",
    list      => true,
    read_only => true,
    comment   => "${vhost}.theforeman.org",
    require   => File["${home}/web"],
  }
  file { "${home}/web/HEADER.html":
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => 0644,
    source => "puppet:///modules/freight/${vhost}-HEADER.html",
  }
}
