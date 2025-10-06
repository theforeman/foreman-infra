# @summary Set up the archivedeb vhost
# @api private
class web::vhost::archivedeb (
  String $user = 'freightarchive',
  Stdlib::Absolutepath $home = "/home/${user}",
  Stdlib::Absolutepath $stagedir = "/var/www/${user}",
) {
  # Manual step: each user needs the GPG key in it's keyring
  freight::user { 'archive':
    user         => $user,
    home         => $home,
    webdir       => '/var/www/vhosts/archivedeb/htdocs',
    stagedir     => $stagedir,
    vhost        => 'archivedeb',
    cron_matches => [],
    cron_enable  => false,
  }

  secure_ssh::rsync::receiver_setup { $user:
    user           => $user,
    homedir        => $home,
    homedir_mode   => '0750',
    foreman_search => 'host.hostgroup = Debian and (name = external_ip4 or name = external_ip6)',
    script_content => template('freight/rsync.erb'),
  }
}
