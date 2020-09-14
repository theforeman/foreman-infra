# @summary Set up the downloads vhost
# @api private
class web::vhost::downloads (
  Stdlib::Absolutepath $downloads_directory = '/var/www/vhosts/downloads/htdocs',
  Integer[0] $rsync_max_connections = 5,
  String $user = 'downloads',
  Boolean $setup_receiver = true,
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

  if $setup_receiver {
    secure_ssh::receiver_setup { $user:
      user           => $user,
      foreman_search => 'host ~ node*.jenkins.osuosl.theforeman.org and (name = external_ip4 or name = external_ip6)',
      script_content => template('web/rsync_downloads.sh.erb'),
    }
  }

  web::vhost { 'downloads':
    docroot       => $downloads_directory,
    docroot_owner => $user,
    docroot_group => $user,
    docroot_mode  => '0755',
    directories   => $downloads_directory_config,
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
