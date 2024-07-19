define freight::user (
  String $user,
  Stdlib::Absolutepath $home,
  Stdlib::Absolutepath $webdir,
  Stdlib::Absolutepath $stagedir,
  String $vhost,
  Variant[String, Array[String]] $cron_matches,
  Optional[String[1]] $stable = undef,
) {
  require freight

  stdlib::ensure_packages(['ruby'])

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

  # vhosts don't autorequire the expires module
  # https://github.com/puppetlabs/puppetlabs-apache/pull/2559
  # limit to not EL7 as there we use apache::default_mods
  if $facts['os']['family'] != 'RedHat' or $facts['os']['release']['major'] != '7' {
    include apache::mod::expires
  }
  include apache::mod::alias
  include apache::mod::autoindex
  include apache::mod::dir
  include apache::mod::mime

  web::vhost { $vhost:
    docroot       => $webdir,
    docroot_owner => $user,
    docroot_group => $user,
    docroot_mode  => '0755',
    directories   => $directory_config,
  }

  file { "${webdir}/HEADER.html":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp("${module_name}/${vhost}-HEADER.html.epp", { 'stable' => $stable }),
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
