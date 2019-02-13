define freight::user (
  $user         = 'freight',
  $home         = '/var/www/freight',
  $webdir       = "${home}/web",
  $stagedir     = "${home}/staged",
  $vhost        = 'deb',
  $vhost_https  = false,
  $cron_matches = 'all',
) {

  if $name == 'main' {
    # Can't use a standard rsync define here as we need to extend the
    # script to handle deployment too
    secure_ssh::receiver_setup { $user:
      user           => $user,
      foreman_search => 'host.hostgroup = Debian and (name = external_ip4 or name = external_ip6)',
      script_content => template('freight/rsync_main.erb'),
      ssh_key_name   => "rsync_${user}_key",
    }
    file { '/home/freight/rsync_cache':
      ensure => directory,
      owner  => $user,
    }
    # This ruby script is called from the secure_freight template
    file { '/home/freight/bin/secure_deploy_debs':
      ensure  => file,
      owner   => 'freight',
      mode    => '0700',
      content => template('freight/deploy_debs.erb'),
    }
  } else {
    secure_ssh::rsync::receiver_setup { $user:
      user           => $user,
      foreman_search => 'host.hostgroup = Debian and (name = external_ip4 or name = external_ip6)',
      script_content => template('freight/rsync.erb'),
    }
  }

  file { "${home}/freight.conf":
    ensure  => file,
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
  $directory_config = [
    {
      path    => $webdir,
      options => ['Indexes', 'FollowSymLinks'],
    },
    {
      path    => "${webdir}/dists",
      headers => 'Set Cache-Control "public, max-age=120"',
    },
    {
      path    => "${webdir}/dists/*/.refs/",
      deny    => 'from all',
    },
    {
      path    => "${webdir}/pool",
      headers => 'Set Cache-Control "public, max-age=2592000"',
    },
  ]

  # locations doesn't autorequire the headers module
  include ::apache::mod::headers

  apache::vhost { $vhost:
    port            => '80',
    servername      => "${vhost}.theforeman.org",
    docroot         => $webdir,
    docroot_owner   => $user,
    docroot_group   => $user,
    docroot_mode    => '0755',
    directories     => $directory_config,
  }

  if $vhost_https {
    apache::vhost { "${vhost}-https":
      port            => '443',
      servername      => "${vhost}.theforeman.org",
      docroot         => $webdir,
      docroot_owner   => $user,
      docroot_group   => $user,
      docroot_mode    => '0755',
      ssl             => true,
      ssl_cert        => '/etc/letsencrypt/live/theforeman.org/fullchain.pem',
      ssl_chain       => '/etc/letsencrypt/live/theforeman.org/chain.pem',
      ssl_key         => '/etc/letsencrypt/live/theforeman.org/privkey.pem',
      directories     => $directory_config,
    }
  }

  include ::rsync::server
  rsync::server::module { $vhost:
    path            => $webdir,
    list            => true,
    read_only       => true,
    comment         => "${vhost}.theforeman.org",
    require         => File[$webdir],
    uid             => 'nobody',
    gid             => 'nobody',
    max_connections => 5,
    exclude         => ['/dists/*/.refs/'],
  }
  file { "${webdir}/HEADER.html":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => file("${module_name}/${vhost}-HEADER.html"),
  }
  file { "${webdir}/foreman.asc":
    ensure => link,
    target => 'pubkey.gpg',
    owner  => 'root',
    group  => 'root',
  }

  if $::selinux {
    include ::selinux

    # Ensure contexts are correct for content copied between webroot and staging area
    selinux::fcontext { "fcontext-${user}":
      seltype  => 'public_content_t',
      pathspec => "/var/www/${user}(/.*)?",
    }
  }
}
