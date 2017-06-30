class slave::postgresql {
  Postgresql_psql {
    cwd => "/",
  }

  include postgresql::client
  include postgresql::server

  # Simple known user/pass that will allow Jenkins to create its
  # own databases when required
  postgresql::server::role { "foreman":
    password_hash => postgresql_password("foreman", "foreman"),
    superuser     => true,
    login         => true,
    require       => Class["postgresql::server"],
  }

  # Tune DB settings for Jenkins slaves, this is UNSAFE for production!
  postgresql::server::config_entry { 'fsync':
    value => 'off',
  }

  postgresql::server::config_entry { 'full_page_writes':
    value => 'off',
  }

  postgresql::server::config_entry { 'synchronous_commit':
    value => 'off',
  }
}
