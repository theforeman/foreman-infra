class freight::config {

  # Manual step: each user needs the GPG key in it's keyring

  freight::user { 'main':
    user         => 'freight',
    home         => '/var/www/freight',
    webdir       => '/var/www/vhosts/deb/htdocs',
    vhost        => 'deb',
    cron_matches => ['nightly','scratch']
  }

  freight::user { 'staging':
    user         => 'freightstage',
    home         => '/var/www/freightstage',
    webdir       => '/var/www/vhosts/stagingdeb/htdocs',
    vhost        => 'stagingdeb',
    cron_matches => 'all'
  }

}
