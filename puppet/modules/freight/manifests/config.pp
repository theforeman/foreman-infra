class freight::config {

  # Manual step: each user needs the GPG key in it's keyring

  freight::user { 'main':
    user         => 'freight',
    home         => '/home/freight',
    webdir       => '/var/www/vhosts/deb/htdocs',
    stagedir     => '/var/www/freight',
    vhost        => 'deb',
    cron_matches => ['nightly','scratch']
  }

  freight::user { 'staging':
    user         => 'freightstage',
    home         => '/home/freightstage',
    webdir       => '/var/www/vhosts/stagingdeb/htdocs',
    stagedir     => '/var/www/freightstage',
    vhost        => 'stagingdeb',
    cron_matches => 'all'
  }

  # Only 'freight' (i.e. prod repo) needs this, so it's not in the define
  secure_ssh::receiver_setup { 'deploy_debs':
    user           => 'freight',
    foreman_search => 'host.hostgroup = Debian and name = ipaddress',
    script_content => template('freight/deploy_debs.erb'),
  }
}
