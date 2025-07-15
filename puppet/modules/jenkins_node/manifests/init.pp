# @summary A Jenkins node
#
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
class jenkins_node (
  Boolean $uploader                     = true,
  String[1] $username                   = 'jenkins',
  Stdlib::Absolutepath $homedir         = "/home/${username}",
  Stdlib::Absolutepath $workspace       = "${homedir}/workspace",
  Boolean $unittests = $facts['os']['family'] == 'RedHat',
  Boolean $packaging = true,
) {
  include fastly_purge

  if $facts['os']['family'] == 'RedHat' {
    $java_package = 'java-17-openjdk-headless'

    package { ['java-11-openjdk', 'java-11-openjdk-headless', 'java-11-openjdk-devel']:
      ensure => absent,
    }
    Package['java-11-openjdk-devel'] -> Package['java-11-openjdk'] -> Package['java-11-openjdk-headless']
  } elsif $facts['os']['family'] == 'Debian' {
    $java_package = 'openjdk-17-jdk'

    package { ['openjdk-11-jdk', 'openjdk-11-jdk-headless', 'openjdk-11-jre', 'openjdk-11-jre-headless']:
      ensure => absent,
    }
    Package['openjdk-11-jdk'] -> Package['openjdk-11-jre'] -> Package['openjdk-11-jdk-headless'] -> Package['openjdk-11-jre-headless']
  } else {
    $java_package = undef
  }

  class { 'java':
    package => $java_package,
  }

  include vcsrepo::manage::git

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
    source => 'puppet:///modules/jenkins_node/gitconfig',
  }

  file { "${homedir}/.gemrc":
    ensure => file,
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/jenkins_node/gemrc',
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
      ensure => present;
  }

  if $unittests {
    class { 'jenkins_node::unittests':
      homedir => $homedir,
    }
  }

  # Packaging
  if $packaging {
    class { 'jenkins_node::packaging':
      uploader  => $uploader,
      homedir   => $homedir,
      workspace => $workspace,
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
    ensure => absent,
  }

  file { '/usr/local/sbin/reboot-jenkins-node':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => file("${module_name}/reboot-jenkins-node"),
  }
}
