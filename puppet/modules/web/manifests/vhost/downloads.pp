# @summary Set up the downloads vhost
# @api private
class web::vhost::downloads (
  Stdlib::Absolutepath $downloads_directory = '/var/www/vhosts/downloads/htdocs',
  Integer[0] $rsync_max_connections = 5,
) {
  $downloads_directory_config = [
    {
      path    => $downloads_directory,
      options => ['Indexes', 'FollowSymLinks', 'MultiViews'],
    },
    {
      path            => '.+\.(bz2|csv|gem|gz|img|iso|iso-img|iso-vmlinuz|pdf|tar|webm|rpm|deb)$',
      provider        => 'filesmatch',
      expires_active  => 'on',
      expires_default => 'access plus 30 days',
    },
  ]

  web::vhost { 'downloads':
    docroot      => $downloads_directory,
    docroot_mode => '2575',
    directories  => $downloads_directory_config,
  }

  include rsync::server
  rsync::server::module { 'downloads':
    path            => $downloads_directory,
    list            => true,
    read_only       => true,
    comment         => 'downloads.theforeman.org',
    uid             => 'nobody',
    gid             => 'nobody',
    max_connections => $rsync_max_connections,
  }

  file { "${downloads_directory}/HEADER.html":
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
    source => 'puppet:///modules/web/downloads-HEADER.html',
  }
}
