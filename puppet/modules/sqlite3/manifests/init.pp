class sqlite3 {
  if ! defined(Package['libsqlite3-dev']) {
    package { "sqlite3-dev":
      ensure    => present,
      name      => $osfamily ? {
        Redhat  => "sqlite-devel",
        default => "libsqlite3-dev"
      }
    }
  }
}
