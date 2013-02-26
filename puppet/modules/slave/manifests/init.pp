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

  slave::db_config { "mysql": }
  slave::db_config { "sqlite3": }
  slave::db_config { "postgresql": }

  include rvm
  if $rvm_installed == "true" {
    rvm::system_user { "jenkins": }
    slave::rvm_config { "ruby-1.8.7":
      version => "ruby-1.8.7-p371",
    }
    slave::rvm_config { "ruby-1.9.2":
      version => "ruby-1.9.2-p320",
    }
    slave::rvm_config { "ruby-1.9.3":
      version => "ruby-1.9.3-p392",
    }
    slave::rvm_config { "ruby-2.0.0":
      version => "ruby-2.0.0-p0",
    }
  }
}
