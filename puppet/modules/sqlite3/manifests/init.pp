class sqlite3 {
  package { "sqlite3-dev":
    ensure => present,
    name => $osfamily ? {
      Redhat => "sqlite-devel",
      Debian => "libsqlite3-dev"
    }
  }
}
