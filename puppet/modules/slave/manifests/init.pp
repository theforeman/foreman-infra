class slave (
  $github_user         = undef,
  $github_oauth        = undef,
  $jenkins_build_token = undef,
  $koji_certificate    = undef,
  $rackspace_username  = undef,
  $rackspace_password  = undef,
  $rackspace_tenant    = undef,
  $copr_login          = undef,
  $copr_username       = undef,
  $copr_token          = undef,
) {
  file { '/var/lib/workspace':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { '/var/lib/workspace/workspace':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { '/home/jenkins/.gitconfig':
    ensure => file,
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/slave/gitconfig',
  }

  file { '/home/jenkins/.gemrc':
    ensure => file,
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/slave/gemrc',
  }

  # test-pull-requests scanner script
  file { '/home/jenkins/pr_tests':
    ensure  => directory,
    owner   => 'jenkins',
    group   => 'jenkins',
    purge   => true,
    recurse => true,
  }
  file { '/home/jenkins/pr_tests/cache':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  if $github_user and $github_oauth and $jenkins_build_token {
    file { '/home/jenkins/.config':
      ensure => directory,
      owner  => 'jenkins',
      group  => 'jenkins',
    }

    file { '/home/jenkins/.config/hub':
      ensure  => file,
      mode    => '0600',
      owner   => 'jenkins',
      group   => 'jenkins',
      content => template('slave/hub_config.erb'),
    }
  }

  # Build dependencies
  package {
    'libxml2-dev':
      ensure => present,
      name   => $::osfamily ? {
        'RedHat' => 'libxml2-devel',
        default  => 'libxml2-dev'
      };
    'libxslt1-dev':
      ensure => present,
      name   => $::osfamily ? {
        'RedHat' => 'libxslt-devel',
        default  => 'libxslt1-dev'
      };
    'mysql-dev':
      ensure => present,
      name   => $::osfamily ? {
        'RedHat' => $::operatingsystemmajrelease ? {
          '6'     => 'mysql-devel',
          default => 'mariadb-devel',
        },
        default  => 'libmysqlclient-dev'
      };
    'postgresql-dev':
      ensure => present,
      name   => $::osfamily ? {
        'Debian' => 'libpq-dev',
        default  => 'postgresql-devel'
      };
    'libkrb5-dev':
      ensure => present,
      name   => $::osfamily ? {
        'Debian' => 'libkrb5-dev',
        default  => 'krb5-devel'
      };
    'systemd-devel':
      ensure => present,
      name   => $::osfamily ? {
        'Debian' => 'libsystemd-dev',
        default  => 'systemd-devel'
      };
    'freeipmi':
      ensure => present;
    'ipmitool':
      ensure => present;
    'firefox':
      ensure => present,
      name   => $::operatingsystem ? {
        'Debian' => 'iceweasel',
        default  => 'firefox'
      };
    'augeas-dev':
      ensure => present,
      name   => $::osfamily ? {
        'Debian' => 'libaugeas-dev',
        default  => 'augeas-devel'
      };
    'libvirt-dev':
      ensure => present,
      name   => $osfamily ? {
        'Debian' => 'libvirt-dev',
        default  => 'libvirt-devel'
      };
    'asciidoc':
      ensure => present;
    'bzip2':
      ensure => present;
    'unzip':
      ensure => present;
    'ansible':
      ensure => latest;
    'python-virtualenv':
      ensure => present;
    'libcurl-dev':
      ensure => present,
      name   => $::osfamily ? {
        'RedHat' => 'libcurl-devel',
        default  => 'libcurl4-openssl-dev'
      };
  }

  # this might clash with RVM on Ubuntu(?) otherwise
  if ! defined(Package['libsqlite3-dev']) {
    package { 'sqlite3-dev':
      ensure    => present,
      name      => $osfamily ? {
        'RedHat' => 'sqlite-devel',
        default  => 'libsqlite3-dev'
      }
    }
  }

  # bash JSON parser
  file { '/usr/local/bin/JSON.sh':
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
    source => 'puppet:///modules/slave/JSON.sh',
  }

  # nodejs/npm for Katello JavaScript tests
  # packages only really available on EL6+
  if $::osfamily == 'RedHat' {
    package { 'npm':
      ensure  => present,
      require => Package['bzip2'],
    } -> Package <| provider == 'npm' |>

    package { 'bower':
      ensure   => '1.7.9',
      provider => npm,
    }
    package { 'phantomjs':
      ensure   => latest,
      provider => npm,
    }
    package { 'grunt-cli':
      ensure   => present,
      provider => npm,
    }

    # temporary dir
    file { '/home/jenkins/tmp':
      ensure => directory,
      owner  => 'jenkins',
      group  => 'jenkins',
      mode   => '0775',
    }

    # Cleanup temporary dir
    file { '/etc/cron.daily/npm_tmp_cleaner':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => "#!/bin/sh\nfind ~jenkins/tmp -maxdepth 1 -name 'npm-*' -type d -mtime +1 -exec rm -rf {} +\n",
    }
  }

  # Needed for integration tests with headless chrome and Selenium
  if $::osfamily == 'RedHat' {
    include ::epel

    package { ['chromium', 'chromedriver']:
      ensure  => latest,
      require => Class['epel'],
    }
  }

  # Needed for foreman-selinux testing
  if $::osfamily == 'RedHat' {
    ensure_packages(['selinux-policy-devel'])
  }

  # needed by katello gem dependency qpid-messaging
  # to interface with candlepin's event topic
  if $::osfamily == 'RedHat' {
    yumrepo { 'katello-pulp':
      ensure => absent,
    }

    package { 'qpid-cpp-client-devel':
      ensure => latest,
    }
  }

  # Needed by foreman_openscap gem dependency OpenSCAP
  if $::osfamily == 'RedHat' {
    yumrepo { 'isimluk-openscap':
      ensure => absent,
    }

    package { 'openscap':
      ensure => latest,
    }
  }

  # Increase OS limits, RH OSes ship them by default
  if $::osfamily == 'RedHat' {
    file { '/etc/security/limits.d':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      recurse => true,
      purge   => true,
    }

    file { '/etc/security/limits.d/90-nproc.conf':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => template('slave/90-nproc.conf.erb'),
    }
  }

  # Java
  include ::slave::java

  # Databases
  include ::slave::mysql, ::slave::postgresql
  slave::db_config { 'mysql': }
  slave::db_config { 'sqlite3': }
  slave::db_config { 'postgresql': }

  # RVM
  include ::slave::rvm

  # RPM packaging
  if $::osfamily == 'RedHat' {
    include ::slave::packaging::rpm
  }

  if $::architecture == 'x86_64' or $::architecture == 'amd64' {
    include slave::docker
  }

  if $rackspace_username and $rackspace_password and $rackspace_tenant and ($::architecture == 'x86_64' or $::architecture == 'amd64') {
    class { '::slave::vagrant':
      username    => Sensitive($rackspace_username),
      password    => Sensitive($rackspace_password),
      tenant_name => Sensitive($rackspace_tenant),
    }
  } else {
    package { 'vagrant':
      ensure => absent,
    }

    file { '/home/jenkins/.vagrant.d':
      ensure => absent,
    }
  }

  # Cleanup Jenkins Xvfb processes from aborted builds after a day
  file { '/etc/cron.daily/xvfb_cleaner':
    ensure => absent,
  }

  # Cleanup Jenkins Ruby processes from aborted builds after a day
  file { '/etc/cron.daily/ruby_cleaner':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => "#!/bin/sh\nps -eo pid,etime,comm | awk '(\$2 ~ /-/ && \$3 ~ /ruby/) { print \$1 }' | xargs kill -9 >/dev/null 2>&1 || true\n",
  }
}
