# @summary Set up the docs vhost
# @api private
class web::vhost::docs (
  Stdlib::Absolutepath $docs_directory = '/var/www/vhosts/docs/htdocs',
) {
  $docs_directory_config = [
    {
      path    => $docs_directory,
      options => ['Indexes', 'FollowSymLinks', 'MultiViews'],
    },
  ]

  web::vhost { 'docs':
    docroot       => $docs_directory,
    directories   => $docs_directory_config,
    docroot_owner => 'website',
    docroot_group => 'website',
    docroot_mode  => '0755',
  }
}
