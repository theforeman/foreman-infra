# @summary A Jenkins node
#
# @param koji_certificate
#   The client certificate used to authenticate to Koji. Used for RPM building.
# @param uploader
#   Whether the machine can upload Debian packages.
# @param username
#   The username to use for running the Jenkins node process
# @param homedir
#   The home directory for the user
# @param workspace
#   The workspace used by the Jenkins node process
# @param unittests
#   Whether the Jenkins node should be able to run Ruby (unit)tests
# @param packaging
#   Whether the node should be able to run packaging jobs
class slave (
  Optional[String] $koji_certificate    = undef,
  Boolean $uploader                     = true,
  String[1] $username                   = 'jenkins',
  Stdlib::Absolutepath $homedir         = "/home/${username}",
  Stdlib::Absolutepath $workspace       = "${homedir}/workspace",
  Boolean $unittests = $facts['os']['family'] == 'RedHat',
  Boolean $packaging = true,
) {
  if $facts['os']['family'] == 'RedHat' {
    $java_package = 'java-11-openjdk-headless'

    package { ['java-1.8.0-openjdk', 'java-1.8.0-openjdk-headless', 'java-1.8.0-openjdk-devel']:
      ensure => absent,
    }
    Package['java-1.8.0-openjdk-devel'] -> Package['java-1.8.0-openjdk'] -> Package['java-1.8.0-openjdk-headless']
  } else {
    $java_package = undef
  }

  class { 'java':
    package => $java_package,
  }

  include git

  # On Debian we use pbuilder with sudo
  if $facts['os']['family'] == 'Debian' {
    include sudo
    sudo::conf { "sudo-puppet-${username}":
      content => "${username} ALL=NOPASSWD: ALL",
    }
  }

  users::account { $username:
    homedir => $homedir,
    sudo    => false,
  }

  file { $workspace:
    ensure => directory,
    owner  => $username,
    group  => $username,
  }

  file { "${homedir}/.ssh/config":
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

  file { ["${homedir}/.config/hub", "${homedir}/.config/copr"]:
    ensure  => absent,
  }

  package {
    'asciidoc':
      ensure => present;
    'bzip2':
      ensure => present;
    'curl':
      ensure => present;
    'unzip':
      ensure => present;
    'ansible':
      ensure => latest;
  }

  if $unittests {
    class { 'slave::unittests':
      homedir => $homedir,
    }
  }

  # Packaging
  if $packaging {
    class { 'slave::packaging':
      koji_certificate => $koji_certificate,
      uploader         => $uploader,
      homedir          => $homedir,
      workspace        => $workspace,
    }
  }

  # Cleanup Jenkins Ruby processes from aborted builds after a day
  file { '/etc/cron.daily/ruby_cleaner':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => "#!/bin/sh\nps -eo pid,etime,comm | awk '(\$2 ~ /-/ && \$3 ~ /ruby/) { print \$1 }' | xargs kill -9 >/dev/null 2>&1 || true\n", # lint:ignore:140chars
  }

  file { '/etc/cron.daily/jenkins_cleaner':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => "#!/bin/sh\nfind ${workspace} /usr/local/rvm/gems/ -maxdepth 1 -mindepth 1 -type d -user jenkins -ctime +3 -exec rm -rf {} +\n", # lint:ignore:140chars
  }
}
