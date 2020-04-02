# All RPM packaging tools
# @api private
class slave::packaging::rpm (
  Stdlib::Absolutepath $homedir,
  Optional[String] $koji_certificate = undef,
) {
  package { ['koji', 'rpm-build', 'git-annex', 'pyliblzma', 'createrepo']:
    ensure => latest,
  }

  # koji
  file { "${homedir}/bin":
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { "${homedir}/bin/kkoji":
    ensure => link,
    owner  => 'jenkins',
    group  => 'jenkins',
    target => '/usr/bin/koji',
  }

  file { "${homedir}/.koji":
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { "${homedir}/.koji/katello-config":
    ensure => absent,
  }

  file { "${homedir}/.koji/config":
    ensure => file,
    mode   => '0644',
    owner  => 'jenkins',
    group  => 'jenkins',
    source => 'puppet:///modules/slave/katello-config',
  }

  if $koji_certificate {
    file { "${homedir}/.katello.cert":
      ensure  => file,
      mode    => '0600',
      owner   => 'jenkins',
      group   => 'jenkins',
      content => $koji_certificate,
    }
  } else {
    file { '/home/jenkins/.katello.cert':
      ensure  => absent,
    }
  }

  file { "${homedir}/.katello-ca.cert":
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

  file { "${homedir}/.titorc":
    ensure  => file,
    mode    => '0644',
    owner   => 'jenkins',
    group   => 'jenkins',
    content => "KOJI_OPTIONS=-c ~/.koji/config build --nowait\n",
  }

  file { '/tmp/tito':
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  # specs-from-koji
  package { ['scl-utils-build', 'rpmdevtools']:
    ensure => present,
  }

  # Needed for EL8 repoclosure on EL7 nodes
  if $facts['os']['family'] == 'RedHat' {
    if $facts['os']['name'] == 'RedHat' {
      yumrepo { 'rhel-7-server-rhui-extras-rpms':
        enabled => true,
        before  => Package['dnf'],
      }
    } else {
      yumrepo { 'rhel-7-server-rhui-extras-rpms':
        ensure => absent,
      }
    }
  }

  package { ['dnf', 'dnf-plugins-core']:
    ensure => present,
  }
}
