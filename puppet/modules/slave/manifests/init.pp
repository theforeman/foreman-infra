class slave($github_user = undef,
            $github_oauth = undef,
            $jenkins_build_token = undef) {
  file { "/var/lib/workspace":
    ensure => directory,
    owner => "jenkins",
    group => "jenkins"
  }

  file { ["/home/jenkins/test_pull_request_not_mergable", "/home/jenkins/test_pull_request_proxy_not_mergable"]:
    ensure => file,
    owner => "jenkins",
    group => "jenkins",
  }

  file { "/home/jenkins/.gitconfig":
    ensure => file,
    owner  => "jenkins",
    group  => "jenkins",
    source => "puppet:///modules/slave/gitconfig",
  }

  if $github_user and $github_oauth and $jenkins_build_token {
    file { "/home/jenkins/.config":
      ensure => directory,
      owner  => "jenkins",
      group  => "jenkins",
    }

    file { "/home/jenkins/.config/hub":
      ensure  => file,
      mode    => 0600,
      owner   => "jenkins",
      group   => "jenkins",
      content => template("slave/hub_config.erb"),
    }

    file {
      "/home/jenkins/.test_pull_requests.json":
        ensure  => file,
        owner   => "jenkins",
        group   => "jenkins",
        content => template("slave/test_pull_requests.json.erb"),
        require => File['/var/lib/workspace'];
      "/home/jenkins/.test_pull_requests_proxy.json":
        ensure  => file,
        owner   => "jenkins",
        group   => "jenkins",
        content => template("slave/test_pull_requests_proxy.json.erb"),
        require => File['/var/lib/workspace']
    }
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
      };
    "ipmitool":
      ensure => present
  }

  include slave::mysql, slave::postgresql
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
