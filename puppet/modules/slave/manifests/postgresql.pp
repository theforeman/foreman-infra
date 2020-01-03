# @api private
class slave::postgresql {
  # only CentOS slaves are used to run unit tests
  if $::osfamily == 'RedHat' {
    if $::operatingsystemmajrelease == '7' {

      package { 'centos-release-scl-rh':
        ensure => 'present',
        before => Class['postgresql::globals'],
      }

      package { 'non_scl_pg_server':
        name   => 'postgresql-server',
        ensure => 'absent',
        before => Class['postgresql::globals'],
      }

      class { 'postgresql::globals':
        version              => '10',
        client_package_name  => 'postgresql',
        server_package_name  => 'rh-postgresql10-postgresql-server-syspaths',
        contrib_package_name => 'rh-postgresql10-postgresql-contrib-syspaths',
        service_name         => 'postgresql',
        datadir              => '/var/opt/rh/rh-postgresql10/lib/pgsql/data',
        confdir              => '/var/opt/rh/rh-postgresql10/lib/pgsql/data',
        bindir               => '/usr/bin',
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
  }

  Postgresql_psql {
    cwd => '/',
  }

  include ::postgresql::client
  include ::postgresql::server

  # Simple known user/pass that will allow Jenkins to create its
  # own databases when required
  postgresql::server::role { 'foreman':
    password_hash => postgresql_password('foreman', 'foreman'),
    superuser     => true,
    login         => true,
  }
}
