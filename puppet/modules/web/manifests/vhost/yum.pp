# @summary Set up the yum vhost
# @api private
class web::vhost::yum (
  String[1] $stable,
  Integer[0] $rsync_max_connections = 5,
  Stdlib::Fqdn $servername = 'yum.theforeman.org',
  Stdlib::Absolutepath $yum_directory = '/var/www/vhosts/yum/htdocs',
) {
  $yum_directory_config = [
    {
      path            => $yum_directory,
      options         => ['Indexes', 'FollowSymLinks', 'MultiViews'],
      expires_active  => 'on',
      expires_default => 'access plus 2 minutes',
    },
    {
      path            => '.+\.(bz2|gz|rpm|xz)$',
      provider        => 'filesmatch',
      expires_active  => 'on',
      expires_default => 'access plus 30 days',
    },
    {
      path            => 'repomd.xml',
      provider        => 'files',
      expires_active  => 'on',
      expires_default => 'access plus 2 minutes',
    },
  ]

  web::vhost { 'yum':
    servername   => $servername,
    docroot      => $yum_directory,
    docroot_mode => '2575',
    directories  => $yum_directory_config,
  }

  include rsync::server
  rsync::server::module { 'yum':
    path            => $yum_directory,
    list            => true,
    read_only       => true,
    comment         => $servername,
    uid             => 'nobody',
    gid             => 'nobody',
    max_connections => $rsync_max_connections,
  }

  if $facts['os']['family'] == 'RedHat' {
    package { 'createrepo':
      ensure => present,
    }
  }

  ['HEADER.html', 'robots.txt', 'RPM-GPG-KEY-foreman'].each |$filename| {
    file { "${yum_directory}/${filename}":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => file("web/yum/${filename}"),
    }
  }

  ['releases', 'plugins', 'client'].each |$directory| {
    file { "${yum_directory}/${directory}":
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }

    file { "${yum_directory}/${directory}/latest":
      ensure => link,
      target => $stable,
    }
  }

  file { "${yum_directory}/releases/nightly":
    ensure => link,
    target => '../nightly',
  }

  file { "${yum_directory}/rails":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "${yum_directory}/rails/latest":
    ensure => link,
    target => "foreman-${stable}",
  }
}
