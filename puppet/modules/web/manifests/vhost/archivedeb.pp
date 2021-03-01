# @summary Set up the archivedeb vhost
# @api private
class web::vhost::archivedeb(
  String $user = 'freightarchive',
  Stdlib::Absolutepath $home = "/home/${user}",
) {
  # Manual step: each user needs the GPG key in it's keyring
  freight::user { 'archive':
    user         => $user,
    home         => $home,
    webdir       => '/var/www/vhosts/archivedeb/htdocs',
    stagedir     => "/var/www/${user}",
    vhost        => 'archivedeb',
    cron_matches => [],
  }
}
