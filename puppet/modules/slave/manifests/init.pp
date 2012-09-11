class slave {
  file { "/var/lib/workspace":
    ensure => directory,
    owner => "jenkins",
    group => "jenkins"
  }

  package {
    "libxml2-dev":
      ensure => present,
      name => $osfamily ? {
        Debian => "libxml2-dev",
        default => "libxml2-devel"
      };
    "libxslt-dev":
      ensure => present,
      name => $osfamily ? {
        Debian => "libxslt-dev",
        default => "libxslt-devel"
      };
    "mysql-dev":
      ensure => present,
      name => $osfamily ? {
       Debian => "libmysqlclient-dev",
       default => "mysql-devel"
      };
    "postgresql-dev":
      ensure => present,
      name => $osfamily ? {
        Debian => "libpqxx3-dev",
      }
  }
}
