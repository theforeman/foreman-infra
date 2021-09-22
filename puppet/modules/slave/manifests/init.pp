class slave (
  Optional[String] $koji_certificate    = undef,
  Boolean $uploader                     = true,
  Stdlib::Absolutepath $homedir         = '/home/jenkins',
  Stdlib::Absolutepath $workspace       = '/home/jenkins/workspace',
  Boolean $unittests = $facts['os']['family'] == 'RedHat',
  Boolean $packaging = true,
) {
  include java

  include git

  # On Debian we use pbuilder with sudo
  $sudo = $facts['os']['family'] ? {
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

  file { ["${homedir}/.config/hub", "${homedir}/.config/copr"]:
    ensure  => absent,
  }

  package {
    'asciidoc':
      ensure => present;
    'bzip2':
      ensure => present;
    'unzip':
      ensure => present;
    'ansible':
      ensure => latest;
  }

  if $unittests {
    class {'slave::unittests':
      homedir => $homedir,
    }
  }

  # Packaging
  if $packaging {
    class {'slave::packaging':
      koji_certificate => $koji_certificate,
      uploader         => $uploader,
      homedir          => $homedir,
      workspace        => $workspace,
    }
  }

  if $facts['os']['architecture'] in ['x86_64', 'amd64'] and !$facts['os']['release']['major'] == '8' {
    include slave::docker
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
