class freight::config {

  # Manual step: each user needs the GPG key in it's keyring

  freight::user { 'main':
    user  => 'freight',
    home  => '/srv/freight',
    vhost => 'deb',
  }

  freight::user { 'staging':
    user => 'freightstage',
    home => '/srv/freightstage',
    vhost => 'stagingdeb',
  }

}
