# @summary Set up the stagingdeb vhost
# @api private
class web::vhost::stagingdeb(
  String $user = 'freightstage',
  Boolean $setup_receiver = true,
) {
  # Manual step: each user needs the GPG key in it's keyring
  freight::user { 'staging':
    user         => $user,
    home         => "/home/${user}",
    webdir       => '/var/www/vhosts/stagingdeb/htdocs',
    stagedir     => "/var/www/${user}",
    vhost        => 'stagingdeb',
    cron_matches => 'all',
  }

  if $setup_receiver {
    secure_ssh::rsync::receiver_setup { $user:
      user           => $user,
      foreman_search => 'host.hostgroup = Debian and (name = external_ip4 or name = external_ip6)',
      script_content => template('freight/rsync.erb'),
    }
  }
}
