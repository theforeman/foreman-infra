# @api private
class slave::postgresql {
  # only CentOS slaves are used to run unit tests
  if $facts['os']['family'] == 'RedHat' {
    if $facts['os']['release']['major'] == '7' {
      ['postgresql-server', 'postgresql-devel', 'postgresql-client', 'postgresql'].each |$pkg| {
        package { "${pkg}-nonscl":
          ensure  => absent,
          name    => $pkg,
          before  => Class['postgresql::globals'],
        }
      }

      if $facts['os']['name'] == 'CentOS' {
        package { 'centos-release-scl-rh':
          ensure => 'present',
          before => Class['postgresql::globals'],
        }
      } elsif $facts['ec2_metadata'] {
        yumrepo { 'rhel-server-rhui-rhscl-7-rpms':
          enabled => true,
          before => Class['postgresql::globals'],
        }
      }

      yumrepo { 'foreman-infra-el7':
        descr    => 'foreman-infra-el7',
        baseurl  => 'https://yum.theforeman.org/infra/el7/',
        enabled  => true,
        gpgcheck => false,
      } ->
      package { 'rh-postgresql12-postgresql-evr':
        ensure  => 'present',
        notify  => Class['postgresql::server::service'],
        require => Class['postgresql::server::install'],
      }

      class { 'postgresql::globals':
        version              => '12',
        client_package_name  => 'rh-postgresql12-postgresql-syspaths',
        server_package_name  => 'rh-postgresql12-postgresql-server-syspaths',
        contrib_package_name => 'rh-postgresql12-postgresql-contrib-syspaths',
        service_name         => 'postgresql',
        datadir              => '/var/opt/rh/rh-postgresql12/lib/pgsql/data',
        confdir              => '/var/opt/rh/rh-postgresql12/lib/pgsql/data',
        bindir               => '/usr/bin',
      }

      file { '/etc/profile.d/enable_postgresql12_scl.sh':
        ensure  => absent,
      }

      file { '/usr/bin/pg_config':
        ensure => 'link',
        target => '/opt/rh/rh-postgresql12/root/usr/bin/pg_config',
      }
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

  include ::postgresql::client
  include ::postgresql::server

  Class['postgresql::server'] -> Package['postgresql-dev']

  # Simple known user/pass that will allow Jenkins to create its
  # own databases when required
  postgresql::server::role { 'foreman':
    password_hash => postgresql_password('foreman', 'foreman'),
    superuser     => true,
    login         => true,
    require       => Service['postgresql'],
  }
}
