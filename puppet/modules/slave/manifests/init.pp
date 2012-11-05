class slave {
  file { "/var/lib/workspace":
    ensure => directory,
    owner => "jenkins",
    group => "jenkins"
  }

  file { "/home/jenkins/.test_pull_requests.json":
    ensure => file,
    owner => "jenkins",
    group => "jenkins",
    source => "puppet:///modules/slave/test_pull_requests.json",
    require => File['/var/lib/workspace']
  }

  package {
    "libxml2-dev":
      ensure => present,
      name => $osfamily ? {
        RedHat => "libxml2-devel",
        default => "libxml2-dev"
      };
    "libxslt-dev":
      ensure => present,
      name => $osfamily ? {
        RedHat => "libxslt-devel",
        default => "libxslt-dev"
      };
    "mysql-dev":
      ensure => present,
      name => $osfamily ? {
       RedHat => "mysql-devel",
       default => "libmysqlclient-dev"
      };
    "postgresql-dev":
      ensure => present,
      name => $osfamily ? {
        Debian => "libpq-dev",
        default => "postgresql-devel"
      }
  }
}
