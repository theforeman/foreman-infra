class sqlite3 {
  package { "sqlite3-dev":
    ensure => present,
    name => $osfamily ? {
      Redhat => "sqlite-devel",
      default => "libsqlite3-dev"
    }
  }
}
