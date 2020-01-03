class slave (
  Optional[String] $github_user         = undef,
  Optional[String] $github_oauth        = undef,
  Optional[String] $jenkins_build_token = undef,
  Optional[String] $koji_certificate    = undef,
  Optional[String] $copr_login          = undef,
  Optional[String] $copr_username       = undef,
  Optional[String] $copr_token          = undef,
  Boolean $uploader                     = true,
  Stdlib::Absolutepath $homedir         = '/home/jenkins',
  Stdlib::Absolutepath $workspace       = '/var/lib/workspace',
) {
  # On Debian we use pbuilder with sudo
  $sudo = $facts['osfamily'] ? {
    'Debian' => 'ALL=NOPASSWD: ALL',
    default  => '',
  }

  users::account { 'jenkins':
    homedir => $homedir,
    sudo    => $sudo,
  }

  file { $workspace:
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { "${workspace}/workspace":
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { '/home/jenkins/.ssh/config':
    ensure  => file,
    mode    => '0600',
    owner   => 'jenkins',
    group   => 'jenkins',
    content => "StrictHostKeyChecking no\n",
  }

  file { "${homedir}/.gitconfig":
    ensure => file,
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/slave/gitconfig',
  }

  file { "${homedir}/.gemrc":
    ensure => file,
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/slave/gemrc',
  }

  file { "${homedir}/.config":
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  if $github_user and $github_oauth and $jenkins_build_token {
    file { "${homedir}/.config/hub":
      ensure  => file,
      mode    => '0600',
      owner   => 'jenkins',
      group   => 'jenkins',
      content => template('slave/hub_config.erb'),
    }
  } else {
    file { "${homedir}/.config/hub":
      ensure  => absent,
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
    'wget':
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

  # nodejs/npm for JavaScript tests
  if $::osfamily == 'RedHat' {
    class { 'nodejs':
      repo_url_suffix       => '12.x',
      nodejs_package_ensure => latest,
      npm_package_ensure    => absent,
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
    file { "${homedir}/tmp":
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
    package { 'qpid-cpp-client-devel':
      ensure => latest,
    }
  }

  # Needed by foreman_openscap gem dependency OpenSCAP
  if $::osfamily == 'RedHat' {
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

  # Packaging
  case $facts['os']['family'] {
    'RedHat': {
      class { 'slave::packaging::rpm':
        homedir          => $homedir,
        koji_certificate => $koji_certificate,
        copr_login       => $copr_login,
        copr_username    => $copr_username,
        copr_token       => $copr_token,
      }
      contain slave::packaging::rpm
    }
    'Debian': {
      class { 'slave::packaging::debian':
        uploader  => $uploader,
        user      => 'jenkins',
        workspace => $workspace,
      }
      contain slave::packaging::debian
    }
    default: {}
  }

  if $::architecture == 'x86_64' or $::architecture == 'amd64' {
    include slave::docker
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
