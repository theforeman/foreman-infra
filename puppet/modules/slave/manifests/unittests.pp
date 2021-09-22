# @api private
class slave::unittests(
  Stdlib::Absolutepath $homedir,
) {
  $is_el8 = $facts['os']['family'] == 'RedHat' and $facts['os']['release']['major'] == '8'

  # Build dependencies
  $libxml2_dev = $facts['os']['family'] ? {
    'RedHat' => 'libxml2-devel',
    default  => 'libxml2-dev'
  }

  $libxslt1_dev = $facts['os']['family'] ? {
    'RedHat' => 'libxslt-devel',
    default  => 'libxslt1-dev'
  }

  $libkrb5_dev = $facts['os']['family'] ? {
    'Debian' => 'libkrb5-dev',
    default  => 'krb5-devel'
  }

  $systemd_dev = $facts['os']['family'] ? {
    'Debian' => 'libsystemd-dev',
    default  => 'systemd-devel'
  }

  $sqlite3_dev = $facts['os']['family'] ? {
    'RedHat' => 'sqlite-devel',
    default  => 'libsqlite3-dev'
  }

  $libcurl_dev = $facts['os']['family'] ? {
    'RedHat' => 'libcurl-devel',
    default  => 'libcurl4-openssl-dev'
  }

  $libvirt_dev = $facts['os']['family'] ? {
    'Debian' => 'libvirt-dev',
    default  => 'libvirt-devel'
  }

  $firefox = $facts['os']['name'] ? {
    'Debian' => 'firefox-esr',
    default  => 'firefox'
  }

  package {
    $libxml2_dev:
      ensure => present;
    $libxslt1_dev:
      ensure => present;
    $libkrb5_dev:
      ensure => present;
    $systemd_dev:
      ensure => present;
    'freeipmi':
      ensure => present;
    'ipmitool':
      ensure => present;
    $firefox:
      ensure => present;
    $libvirt_dev:
      ensure => present;
    $libcurl_dev:
      ensure => present;
    $sqlite3_dev:
      ensure => present;
  }

  unless $is_el8 {
    package { ['python-virtualenv', 'transifex-client']:
      ensure => present,
    }
  }

  # nodejs/npm for JavaScript tests
  if $facts['os']['family'] == 'RedHat' {
    class { 'nodejs':
      repo_url_suffix       => '12.x',
      nodejs_package_ensure => latest,
      npm_package_ensure    => absent,
    } -> Package <| provider == 'npm' |>

    package { 'bower':
      ensure   => '1.7.9',
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
      content => template('slave/npm_cleaner.sh.erb'),
    }
  }

  # Needed for integration tests with headless chrome and Selenium
  if $facts['os']['family'] == 'RedHat' {
    include epel

    package { ['chromium', 'chromedriver']:
      ensure  => latest,
      require => Class['epel'],
    }
  }

  # Needed for foreman-selinux testing
  if $facts['os']['family'] == 'RedHat' {
    ensure_packages(['selinux-policy-devel'])
  }

  # needed by katello gem dependency qpid_proton
  # for katello-agent messaging
  if $facts['os']['family'] == 'RedHat' {
    package { 'qpid-proton-cpp-devel':
      ensure => latest,
    }
  }

  # Needed by foreman_openscap gem dependency OpenSCAP
  if $facts['os']['family'] == 'RedHat' {
    package { 'openscap':
      ensure => latest,
    }
  }

  # Increase OS limits, RH OSes ship them by default
  if $facts['os']['family'] == 'RedHat' {
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

  # Databases
  include slave::mysql
  include slave::postgresql
  # sqlite3 support was dropped in Foreman 2.1
  slave::db_config { 'sqlite3':
    ensure => absent,
  }

  # RVM
  include slave::rvm
}
