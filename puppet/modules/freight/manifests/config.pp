class freight::config {

  # Manual step: each user needs the GPG key in it's keyring

  freight::user { 'main':
    user         => 'freight',
    home         => '/home/freight',
    webdir       => '/var/www/vhosts/deb/htdocs',
    stagedir     => '/var/www/freight',
    vhost        => 'deb',
    vhost_https  => $freight::https,
    cron_matches => ['nightly','scratch']
  }

  freight::user { 'staging':
    user         => 'freightstage',
    home         => '/home/freightstage',
    webdir       => '/var/www/vhosts/stagingdeb/htdocs',
    stagedir     => '/var/www/freightstage',
    vhost        => 'stagingdeb',
    vhost_https  => $freight::https,
    cron_matches => 'all'
  }

}
