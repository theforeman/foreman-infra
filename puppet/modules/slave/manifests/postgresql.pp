class slave::postgresql {
  include postgresql::client
  include postgresql::server

  # Simple known user/pass that will allow Jenkins to create its
  # own databases when required
  postgresql::role { "foreman":
    password_hash => postgresql_password("foreman", "foreman"),
    createdb      => true,
    login         => true,
    require       => Class["postgresql::server"],
  }
}
