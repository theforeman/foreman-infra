class slave::postgresql {
  Postgresql_psql {
    cwd => "/",
  }

  include postgresql::client
  include postgresql::server

  # Simple known user/pass that will allow Jenkins to create its
  # own databases when required
  postgresql::role { "foreman":
    password_hash => postgresql_password("foreman", "foreman"),
    superuser     => true,
    login         => true,
    require       => Class["postgresql::server"],
  }
}
