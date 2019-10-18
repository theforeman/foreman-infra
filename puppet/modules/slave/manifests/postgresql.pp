# @api private
class slave::postgresql {
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

  # only CentOS slaves are used to run unit tests
  if $::osfamily == 'RedHat' {
    # Tune DB settings for Jenkins slaves, this is UNSAFE for production!
    $settings = {
      'fsync'                        => 'off',
      'full_page_writes'             => 'off',
      'synchronous_commit'           => 'off',
      'autovacuum'                   => 'off',
      'effective_cache_size'         => '512MB',
      'shared_buffers'               => '256MB',
      'checkpoint_segments'          => '20',
      'checkpoint_completion_target' => '0.9',
      'wal_level'                    => 'minimal',
    }

    $settings.each |$setting, $value| {
      postgresql::server::config_entry { $setting:
        value => $value,
      }
    }
  }
}
