define freight::user (
  $user         = 'freight',
  $home         = '/var/www/freight',
  $webdir       = "${home}/web",
  $stagedir     = "${home}/staged",
  $vhost        = 'deb',
  $cron_matches = 'all',
) {

  if $name == 'main' {
    # Can't use a standard rsync define here as we need to extend the
    # script to handle deployment too
    secure_ssh::receiver_setup { $user:
      user           => $user,
      foreman_search => 'host.hostgroup = Debian and name = external_ip4',
      script_content => template('freight/rsync_main.erb'),
      ssh_key_name   => "rsync_${user}_key",
    }
    file { '/home/freight/rsync_cache':
      ensure => directory,
      owner  => $user,
    }
    # This ruby script is called from the secure_freight template
    file { '/home/freight/bin/secure_deploy_debs':
      ensure  => present,
      owner   => 'freight',
      mode    => '0700',
      content => template('freight/deploy_debs.erb'),
    }
  } else {
    secure_ssh::rsync::receiver_setup { $user:
      user           => $user,
      foreman_search => 'host.hostgroup = Debian and name = external_ip4',
      script_content => template('freight/rsync.erb'),
    }
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
    port            => '80',
    servername      => "${vhost}.theforeman.org",
    docroot         => $webdir,
    docroot_owner   => $user,
    docroot_group   => $user,
    docroot_mode    => 0755,
    custom_fragment => template('freight/vhost.erb'),
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
