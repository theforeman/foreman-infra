class slave($github_user = undef,
            $github_oauth = undef,
            $jenkins_build_token = undef,
            $koji_certificate = undef,
            $rackspace_username = undef,
            $rackspace_api_key = undef) {
  file { "/var/lib/workspace":
    ensure => directory,
    owner => "jenkins",
    group => "jenkins"
  }

  file { "/home/jenkins/.gitconfig":
    ensure => file,
    owner  => "jenkins",
    group  => "jenkins",
    source => "puppet:///modules/slave/gitconfig",
  }

  file { "/home/jenkins/.gemrc":
    ensure => file,
    owner  => "jenkins",
    group  => "jenkins",
    source => "puppet:///modules/slave/gemrc",
  }

  # test-pull-requests scanner script
  slave::pr_test_config { [
    "foreman",
    "smart_proxy",
    "foreman_packaging",
    "hammer_cli",
    "hammer_cli_foreman",
    "hammer_cli_foreman_discovery",
    "katello",
    "katello_installer",
    "bastion",
    "kafo",
    "kafo_parsers",
    "foreman_bootdisk",
    "foreman_discovery",
    "foreman_docker",
    "foreman_salt",
    "smart_proxy_discovery",
  ]: }
  slave::pr_test_config { "hammer_cli_katello":
    ensure => absent,
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
  }

  # Build dependencies
  package {
    "libxml2-dev":
      ensure => present,
      name => $osfamily ? {
        RedHat => "libxml2-devel",
        default => "libxml2-dev"
      };
    "libxslt1-dev":
      ensure => present,
      name => $osfamily ? {
        RedHat => "libxslt-devel",
        default => "libxslt1-dev"
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
    "libkrb5-dev":
      ensure => present,
      name => $osfamily ? {
        Debian => "libkrb5-dev",
        default => "krb5-devel"
      };
    "ipmitool":
      ensure => present;
    "firefox":
      ensure => present,
      name => $osfamily ? {
        Debian  => "iceweasel",
        default => "firefox"
      };
    "xvfb":
      ensure => present,
      name => $osfamily ? {
        Debian  => "xvfb",
        default => "xorg-x11-server-Xvfb"
      };
    "augeas-dev":
      ensure => present,
      name => $osfamily ? {
        Debian => "libaugeas-dev",
        default => "augeas-devel"
      }
  }

  # bash JSON parser
  file { '/usr/local/bin/JSON.sh':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => "puppet:///modules/slave/JSON.sh",
  }

  # nodejs/npm for Katello JavaScript tests
  # packages only really available on EL6+
  if $osfamily == 'RedHat' {
    package { 'npm':
      ensure => present,
    } -> Package <| provider == 'npm' |>

    package { 'bower':
      ensure   => '1.3.12',
      provider => npm,
    }
    package { ['phantomjs', 'grunt-cli']:
      ensure   => present,
      provider => npm,
    }
  }

  # needed by katello gem dependency qpid-messaging
  # to interface with candlepin's event topic
  if $osfamily == 'RedHat' {
    yumrepo { 'katello-pulp':
      descr    => "Katello Pulp Repo",
      baseurl  => "http://fedorapeople.org/groups/katello/releases/yum/nightly/pulp/RHEL/\$releasever/\$basearch",
      gpgcheck => '0',
      enabled  => '1',
    } ->
    package { 'qpid-cpp-client-devel':
      ensure => present,
    }
  }

  # specs-from-koji
  if $osfamily == 'RedHat' {
    package {
      'scl-utils-build':
        ensure => present;
      'rpmdevtools':
        ensure => present
    }
  }

  # Databases
  include slave::mysql, slave::postgresql
  slave::db_config { "mysql": }
  slave::db_config { "sqlite3": }
  slave::db_config { "postgresql": }

  # RVM
  class { 'rvm':
    version => '1.25.33',
  }
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
      version => "ruby-2.0.0-p353",
    }
    slave::rvm_config { "ruby-2.1":
      version => "ruby-2.1.2",
    }

    # Cleanup log dirs
    file { '/etc/cron.daily/rvm_log_cleaner':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => "#!/bin/sh\n[ -e /usr/local/rvm/log ] || exit 0;\nfind /usr/local/rvm/log -maxdepth 1 -mtime +31 -exec rm -rf {} +\n"
    }
  }

  # Koji
  if $osfamily == 'RedHat' {
    package {
      'koji':
        ensure => present;
      'rpm-build':
        ensure => present;
      'tito':
        ensure => present;
      'git-annex':
        ensure => present;
      'pyliblzma':
        ensure => present
    }
  }
  file { "/home/jenkins/.koji":
    ensure => directory,
    owner  => "jenkins",
    group  => "jenkins",
  }
  file { "/home/jenkins/.titorc":
    ensure => file,
    mode   => 0644,
    owner  => "jenkins",
    group  => "jenkins",
    source => "puppet:///modules/slave/titorc",
  }
  file { "/home/jenkins/.koji/katello-config":
    ensure => file,
    mode   => 0644,
    owner  => "jenkins",
    group  => "jenkins",
    source => "puppet:///modules/slave/katello-config",
  }
  file { "/home/jenkins/.katello-ca.cert":
    ensure => file,
    mode   => 0644,
    owner  => "jenkins",
    group  => "jenkins",
    source => "puppet:///modules/slave/katello-ca.cert",
  }
  if $koji_certificate {
    file { "/home/jenkins/.katello.cert":
      ensure  => file,
      mode    => 0600,
      owner   => "jenkins",
      group   => "jenkins",
      content => $koji_certificate,
    }
  }

  if $rackspace_username and $rackspace_api_key {
    class { 'slave::vagrant':
      username => $rackspace_username,
      api_key  => $rackspace_api_key,
    }
  }

  # Cleanup Jenkins Xvfb processes from aborted builds after a day
  file { '/etc/cron.daily/xvfb_cleaner':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => "#!/bin/sh\nps -eo pid,etime,comm | awk '(\$2 ~ /-/ && \$3 ~ /Xvfb/) { print \$1 }' | xargs kill >/dev/null 2>&1 || true\n"
  }
}
