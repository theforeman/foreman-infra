define freight::user (
  String $user,
  Stdlib::Absolutepath $home,
  Stdlib::Absolutepath $webdir,
  Stdlib::Absolutepath $stagedir,
  String $vhost,
  Variant[String, Array[String]] $cron_matches,
) {
  require freight

  ensure_packages(['ruby'])

  file { "${home}/freight.conf":
    ensure  => file,
    owner   => 'root',
    group   => $user,
    mode    => '0644',
    content => template('freight/freight.conf.erb'),
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
    owner   => 'root',
    group   => 'root',
    content => template('freight/cron.erb'),
    require => Package['ruby'],
  }

  # Website resources
  $directory_config = [
    {
      path    => $webdir,
      options => ['Indexes', 'FollowSymLinks'],
    },
    {
      path            => "${webdir}/dists",
      expires_active  => 'on',
      expires_default => 'access plus 2 minutes',
    },
    {
      path    => "${webdir}/dists/*/.refs/",
      require => 'all denied',
    },
    {
      path    => "${webdir}/pool",
      expires_active  => 'on',
      expires_default => 'access plus 30 days',
    },
  ]

  # locations doesn't autorequire the headers module
  include apache::mod::headers

  web::vhost { $vhost:
    docroot       => $webdir,
    docroot_owner => $user,
    docroot_group => $user,
    docroot_mode  => '0755',
    directories   => $directory_config,
  }

  include rsync::server
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

  if $facts['os']['selinux']['enabled'] {
    include selinux

    # Ensure contexts are correct for content copied between webroot and staging area
    selinux::fcontext { "fcontext-${user}":
      seltype  => 'public_content_t',
      pathspec => "${stagedir}(/.*)?",
    }
  }
}
