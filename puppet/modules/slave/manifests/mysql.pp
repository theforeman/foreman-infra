class slave::mysql {
  include mysql

  class { "mysql::server": } ->

  database_user { "foreman@localhost":
    password_hash => mysql_password("foreman"),
    provider      => mysql,
  } ->

  database_grant { "foreman@localhost":
    privileges => ["Create_priv", "Drop_priv"],
    provider   => mysql,
  } ->

  database_grant { "foreman@localhost/test%":
    privileges => "all",
    provider => mysql,
  }
}
