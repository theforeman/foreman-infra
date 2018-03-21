# All RPM packaging tools
class slave::packaging::rpm (
  Optional[String] $koji_certificate = $slave::koji_certificate,
  Optional[String] $copr_login = $slave::copr_login,
  Optional[String] $copr_username = $slave::copr_username,
  Optional[String] $copr_token = $slave::copr_token,
) {
  package { ['koji', 'rpm-build', 'git-annex', 'pyliblzma']:
    ensure => latest,
  }

  # koji
  file { '/home/jenkins/bin':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { '/home/jenkins/bin/kkoji':
    ensure => link,
    owner  => 'jenkins',
    group  => 'jenkins',
    target => '/usr/bin/koji',
  }

  file { '/home/jenkins/.koji':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { '/home/jenkins/.koji/katello-config':
    ensure => absent,
  }

  file { '/home/jenkins/.koji/config':
    ensure => file,
    mode   => '0644',
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/slave/katello-config',
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

  file { '/home/jenkins/.katello-ca.cert':
    ensure => file,
    mode   => '0644',
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/slave/katello-ca.cert',
  }

  # tito
  package { 'tito':
    ensure => latest,
  }

  file { '/home/jenkins/.titorc':
    ensure => file,
    mode   => '0644',
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/slave/titorc',
  }

  file { '/tmp/tito':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  # copr
  package { 'copr-cli':
    ensure => latest,
  }

  file { '/home/jenkins/.config/copr':
    ensure  => file,
    mode    => '0640',
    owner   => 'jenkins',
    group   => 'jenkins',
    content => template('slave/copr.erb'),
  }

  # specs-from-koji
  package { ['scl-utils-build', 'rpmdevtools']:
    ensure => present,
  }
}
