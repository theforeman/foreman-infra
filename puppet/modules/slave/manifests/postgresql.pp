# @api private
class slave::postgresql {
  # only CentOS slaves are used to run unit tests
  if $facts['os']['family'] == 'RedHat' {
    # Necessary for PostgreSQL EVR extension
    yumrepo { 'pulpcore':
      baseurl  => "http://yum.theforeman.org/pulpcore/3.39/el\$releasever/\$basearch/",
      descr    => 'Pulpcore',
      enabled  => true,
      gpgcheck => true,
      gpgkey   => 'https://yum.theforeman.org/pulpcore/3.39/GPG-RPM-KEY-pulpcore',
    } ->
    package { ['postgresql-evr']:
      ensure  => 'present',
      notify  => Class['postgresql::server::service'],
      require => Class['postgresql::server::install'],
    }
  }

  # Tune DB settings for Jenkins slaves, this is UNSAFE for production!
  $settings = {
    'fsync'                        => 'off',
    'full_page_writes'             => 'off',
    'synchronous_commit'           => 'off',
    'autovacuum'                   => 'off',
    'effective_cache_size'         => '512MB',
    'shared_buffers'               => '256MB',
    'checkpoint_completion_target' => '0.9',
    'wal_level'                    => 'minimal',
    'max_wal_senders'              => '0',
  }

  $settings.each |$setting, $value| {
    postgresql::server::config_entry { $setting:
      value => $value,
    }
  }

  Postgresql_psql {
    cwd => '/',
  }

  include postgresql::client
  include postgresql::server
  include postgresql::lib::devel

  # Simple known user/pass that will allow Jenkins to create its
  # own databases when required
  postgresql::server::role { 'foreman':
    password_hash => postgresql::postgresql_password('foreman', 'foreman'),
    superuser     => true,
    login         => true,
    require       => Service['postgresql'],
  }

  slave::db_config { 'postgresql':
    require => Postgresql::Server::Role['foreman'],
  }
}
