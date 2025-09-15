# @summary Set up the stagingdeb vhost
# @api private
class web::vhost::stagingdeb(
  String $user = 'freightstage',
  Stdlib::Absolutepath $home = "/home/${user}",
  Stdlib::Absolutepath $stagedir = "/var/www/${user}",
) {
  # Manual step: each user needs the GPG key in it's keyring
  freight::user { 'staging':
    user         => $user,
    home         => $home,
    webdir       => '/var/www/vhosts/stagingdeb/htdocs',
    stagedir     => $stagedir,
    vhost        => 'stagingdeb',
    cron_matches => 'all',
  }

  secure_ssh::rsync::receiver_setup { $user:
    user           => $user,
    homedir        => $home,
    homedir_mode   => '0750',
    foreman_search => 'host.hostgroup = Debian and (name = external_ip4 or name = external_ip6)',
    script_content => template('freight/rsync.erb'),
  }
}
