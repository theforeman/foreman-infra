class slave::mysql {
  class { "mysql::server": } ->
  mysql_user { "foreman@localhost":
    ensure        => 'present',
    password_hash => mysql_password("foreman"),
  } ->
  mysql_grant { 'foreman@localhost/*.*':
    ensure     => 'present',
    privileges => ['CREATE', 'DROP'],
    table      => '*.*',
    user       => 'foreman@localhost',
  } ->
  mysql_grant { 'foreman@localhost/test%.*':
    ensure     => 'present',
    privileges => 'all',
    table      => 'test%.*',
    user       => 'foreman@localhost',
  }
}
