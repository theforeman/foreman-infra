class slave::mysql {
  include mysql

  class { "mysql::server": } ->
  mysql_user { "foreman@localhost":
    ensure        => 'present',
    password_hash => mysql_password("foreman"),
  } ->
  mysql_grant { "foreman@localhost":
    ensure     => 'present',
    privileges => ["Create_priv", "Drop_priv"],
  } ->
  mysql_grant { "foreman@localhost/test%":
    ensure     => 'present',
    privileges => "all",
  }
}
