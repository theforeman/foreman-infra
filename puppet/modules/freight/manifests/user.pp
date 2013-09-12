define freight::user (
  $user         = 'freight',
  $home         = '/srv/freight',
  $vhost        = 'deb',
  $cron_matches,
) {

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

  # Read the dirvish key from the puppetmaster
  $pub_key  = ssh_keygen({name => 'freight_key', public => 'public'})

  # TODO: get these IPs from somewhere... Foreman?
  file { "${home}/.ssh/authorized_keys":
    ensure  => present,
    owner   => $user,
    group   => $user,
    mode    => 0644,
    content => "from=\"5.9.188.106\",command=\"${home}/bin/freight_rsync\" ssh-rsa ${pub_key} freight_key\n",
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

}
