# @summary Set up the deb vhost
# @api private
class web::vhost::deb (
  String $user = 'freight',
  Stdlib::Absolutepath $homedir = "/home/${user}",
  Boolean $setup_receiver = true,
) {
  # Manual step: each user needs the GPG key in it's keyring
  freight::user { 'main':
    user         => $user,
    home         => $homedir,
    webdir       => '/var/www/vhosts/deb/htdocs',
    stagedir     => '/var/www/freight',
    vhost        => 'deb',
    cron_matches => ['nightly', 'scratch'],
  }

  if $setup_receiver {
    # Can't use a standard rsync define here as we need to extend the
    # script to handle deployment too
    secure_ssh::receiver_setup { $user:
      user           => $user,
      foreman_search => 'host.hostgroup = Debian and (name = external_ip4 or name = external_ip6)',
      script_content => template('freight/rsync_main.erb'),
      ssh_key_name   => "rsync_${user}_key",
    }
    file { "${homedir}/rsync_cache":
      ensure => directory,
      owner  => $user,
    }
    # This ruby script is called from the secure_freight template
    file { "${homedir}/bin/secure_deploy_debs":
      ensure  => file,
      owner   => 'freight',
      mode    => '0700',
      content => template('freight/deploy_debs.erb'),
    }
  }
}
