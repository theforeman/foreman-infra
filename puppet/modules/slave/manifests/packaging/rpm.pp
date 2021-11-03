# All RPM packaging tools
# @api private
class slave::packaging::rpm (
  Stdlib::Absolutepath $homedir,
  Optional[String] $koji_certificate = undef,
) {
  # TODO: Fix on EL8 and get rid of this
  $is_el8 = $facts['os']['release']['major'] == '8'

  package { ['koji', 'rpm-build', 'createrepo']:
    ensure => installed,
  }

  unless $is_el8 {
    package { ['git-annex', 'pyliblzma']:
      ensure => installed,
    }
  }

  # koji
  file { "${homedir}/bin":
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
  }

  file { "${homedir}/bin/kkoji":
    ensure => absent,
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
    file { "${homedir}/.katello.cert":
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

  unless $is_el8 {
    # tito
    # Work around to fix https://github.com/rpm-software-management/tito/pull/354#issuecomment-613523823
    # Pulled from the infra repository
    package { 'tito':
      ensure => '0.6.12',
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
