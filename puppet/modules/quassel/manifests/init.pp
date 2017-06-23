class quassel (
  $users = 'undef'
) {

  $db_password = cache_data('db_password', random_password(32))
  $password    = postgresql_password('quasselcore', $db_password)

  # Prevents errors if run from /root etc.
  Postgresql_psql {
    cwd => '/',
  }

  include postgresql::client, postgresql::server
  postgresql::server::db { 'quassel':
    user     => 'quasselcore',
    password => $password,
  }

  package { 'quassel-core':
    ensure => installed
  }

  service { 'quasselcore':
    ensure => running
  }

  # User setup
  file { '/var/cache/quassel':
    ensure => directory,
  }

  file { '/usr/local/bin/quasselshell':
    ensure  => present,
    content => template('quassel/shell.erb'),
    mode    => 0755,
  }

  include sudo
  sudo::conf { 'sudo-puppet-quassel':
    content => '%quassel ALL=NOPASSWD:/usr/bin/quasselcore *',
  }

  if $users == 'undef' {
    # Create basic users, delete once foreman is updated
    quassel::user{ 'gsutcliffe':
      key => "AAAAB3NzaC1yc2EAAAADAQABAAABAQC+1sjrMV3VKV1zE5caeqE6rwU528I8bfNxbkYuWKyiR0n9jg2fWidCGdoWC6+KzMJqGqR/wO1m5VXj6lIKYyGbYm+f3SyI6B9NJ0h4P25fLcSGRCGwCvv3vkqehcDvir1bKwGU0BewrUwI5ljm4+nfAdhDO8hnrFKg8paRrbwRL7GeR/ZMCRMEFLsQT96z0NPUk5yDYWE3xCTcVKENP89OKc1Sk0J6Xk5FFDBrEExD/0cSe2WhblvVC7sL7k3YwLKbq36UxGTer1nCzY2v9AsUpI0hmqN4fwh1XDTPR6ONASRw1fazybrbFRnh/hmsm4X8EUAzbOClwXYBMixYwKmx"
    }
  } else {
    # Users hash is passed from Foreman
    create_resources(quassel::user, $users)
  }


}
