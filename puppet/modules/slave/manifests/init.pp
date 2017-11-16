class slave (
  $github_user         = undef,
  $github_oauth        = undef,
  $jenkins_build_token = undef,
  $koji_certificate    = undef,
  $rackspace_username  = undef,
  $rackspace_api_key   = undef,
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
  slave::pr_test_config { [
    'bastion',
    'foreman_ansible',
    'foreman_bootdisk',
    'foreman_digitalocean',
    'foreman_discovery',
    'foreman_docker',
    'foreman_expire_hosts',
    'foreman_host_extra_validator',
    'foreman_host_rundeck',
    'foreman_monitoring',
    'foreman_omaha',
    'foreman_openscap',
    'foreman_packaging',
    'foreman_pipeline',
    'foreman_remote_execution',
    'foreman_salt',
    'foreman_setup',
    'foreman_tasks',
    'foreman_templates',
    'foreman_userdata',
    'hammer_cli',
    'hammer_cli_foreman',
    'hammer_cli_foreman_discovery',
    'kafo',
    'kafo_parsers',
    'katello',
    'katello_packaging',
    'puppetdb_foreman',
    'smart_proxy',
    'smart_proxy_abrt',
    'smart_proxy_discovery',
    'smart_proxy_dynflow',
    'smart_proxy_monitoring',
    'smart_proxy_omaha',
    'smart_proxy_openscap',
    'smart_proxy_pulp',
    'smart_proxy_remote_execution_ssh',
  ]: }
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
    'xvfb':
      ensure => present,
      name   => $::osfamily ? {
        'Debian' => 'xvfb',
        default  => 'xorg-x11-server-Xvfb'
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
    'unzip':
      ensure => present;
    'ansible':
      ensure => latest;
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
      ensure => present,
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
      mode    => '0775',
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

  # needed by katello gem dependency qpid-messaging
  # to interface with candlepin's event topic
  if $::osfamily == 'RedHat' {
    yumrepo { 'katello-pulp':
      ensure => absent,
    }

    if $::operatingsystemmajrelease == '6' {
      yumrepo { 'qpid':
        descr    => 'qpid/qpid copr',
        baseurl  => 'https://copr-be.cloud.fedoraproject.org/results/@qpid/qpid/epel-6-$basearch/',
        gpgcheck => '1',
        gpgkey   => 'https://copr-be.cloud.fedoraproject.org/results/@qpid/qpid/pubkey.gpg',
        enabled  => '1',
        before   => Package['qpid-cpp-client-devel'],
      }
    }

    package { 'qpid-cpp-client-devel':
      ensure => latest,
    }
  }

  # Needed by foreman_openscap gem dependency OpenSCAP
  if $::osfamily == 'RedHat' {
    yumrepo { 'isimluk-openscap':
      enabled     => 1,
      gpgcheck    => 0,
      descr       => 'isimluk-openscap',
      baseurl     => "http://copr-be.cloud.fedoraproject.org/results/isimluk/OpenSCAP/epel-${::operatingsystemmajrelease}-\$basearch/",
      includepkgs => ['openscap'],
    } ->
    package { 'openscap':
      ensure => latest,
    }
  }

  # specs-from-koji
  if $::osfamily == 'RedHat' {
    package {
      'scl-utils-build':
        ensure => present;
      'rpmdevtools':
        ensure => present;
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
  class { '::rvm':
    version => '1.26.11',
  }
  if $rvm_installed == true {
    rvm::system_user { 'jenkins':
      create => false,
    }

    if $::architecture == 'x86_64' or $::architecture == 'amd64' {
      slave::rvm_config { 'ruby-1.8.7':
        version => 'ruby-1.8.7-p371',
      }
      slave::rvm_config { 'ruby-1.9.2':
        version => 'ruby-1.9.2-p320',
      }
      slave::rvm_config { 'ruby-1.9.3':
        version => 'ruby-1.9.3-p392',
      }
      slave::rvm_config { 'ruby-2.0.0':
        version => 'ruby-2.0.0-p643',
      }
    }
    slave::rvm_config { 'ruby-2.1':
      version => 'ruby-2.1.5',
    }
    slave::rvm_config { 'ruby-2.2':
      version => 'ruby-2.2.5',
    }
    slave::rvm_config { 'ruby-2.3':
      version => 'ruby-2.3.1',
    }
    slave::rvm_config { 'ruby-2.4':
      version => 'ruby-2.4.0',
    }

    # Cleanup log dirs
    file { '/etc/cron.daily/rvm_log_cleaner':
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
      content => "#!/bin/sh\n[ -e /usr/local/rvm/log ] || exit 0;\nfind /usr/local/rvm/log -maxdepth 1 -mtime +31 -exec rm -rf {} +\n",
    }
  }

  # Koji
  if $::osfamily == 'RedHat' {
    package {
      'koji':
        ensure => latest;
      'rpm-build':
        ensure => latest;
      'tito':
        ensure => latest;
      'git-annex':
        ensure => latest;
      'pyliblzma':
        ensure => latest;
      'copr-cli':
        ensure => latest;
    }
  }
  file { '/home/jenkins/.koji':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }
  file { '/home/jenkins/.titorc':
    ensure => file,
    mode   => '0644',
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/slave/titorc',
  }
  file { '/home/jenkins/.koji/katello-config':
    ensure => file,
    mode   => '0644',
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/slave/katello-config',
  }
  file { '/home/jenkins/.katello-ca.cert':
    ensure => file,
    mode   => '0644',
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/slave/katello-ca.cert',
  }
  file { '/home/jenkins/.config/copr':
    ensure   => file,
    mode     => '0640',
    owner    => 'jenkins',
    group    => 'jenkins',
    content  => template('slave/copr.erb'),
  }
  if $koji_certificate {
    file { '/home/jenkins/.katello.cert':
      ensure  => file,
      mode    => '0600',
      owner   => 'jenkins',
      group   => 'jenkins',
      content => $koji_certificate,
    }
  }
  file { '/tmp/tito':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  if $rackspace_username and $rackspace_api_key and ($::architecture == 'x86_64' or $::architecture == 'amd64') {
    class { '::slave::vagrant':
      username => $rackspace_username,
      api_key  => $rackspace_api_key,
    }
  }

  # Cleanup Jenkins Xvfb processes from aborted builds after a day
  file { '/etc/cron.daily/xvfb_cleaner':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => "#!/bin/sh\nps -eo pid,etime,comm | awk '(\$2 ~ /-/ && \$3 ~ /Xvfb/) { print \$1 }' | xargs kill >/dev/null 2>&1 || true\n",
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
