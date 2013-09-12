class freight::config {

  # Manual step: each user needs the GPG key in it's keyring

  class { 'freight::user':
    user  => 'freight',
    home  => '/srv/freight',
    vhost => 'deb',
  }

  class { 'freight::user':
    user => 'freightstage',
    home => '/srv/freightstage',
    vhost => 'stagingdeb',
  }

}
