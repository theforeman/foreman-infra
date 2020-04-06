# @api private
class slave::mysql {
  # Tune DB settings for Jenkins slaves, this is UNSAFE for production!
  $override_options = {
    'mysqld' => {
      'innodb-flush-log-at-trx-commit' => '0',
      'innodb-doublewrite'             => '0',
      'sync_frm'                       => '0',
    },
  }

  class { '::mysql::server':
    override_options => $override_options,
  }

  mysql_user { 'foreman@localhost':
    ensure        => 'present',
    password_hash => mysql_password('foreman'),
  }

  mysql_grant { 'foreman@localhost/*.*':
    ensure     => 'present',
    privileges => ['CREATE', 'DROP'],
    table      => '*.*',
    user       => 'foreman@localhost',
  }

  mysql_grant { 'foreman@localhost/test%.*':
    ensure     => 'present',
    privileges => 'all',
    table      => 'test%.*',
    user       => 'foreman@localhost',
  }

  class { 'mysql::bindings':
    client_dev => true,
  }
}
