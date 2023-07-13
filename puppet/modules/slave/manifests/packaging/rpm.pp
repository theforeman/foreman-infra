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

  # To run obal
  $yaml = if $facts['os']['release']['major'] == '7' { 'python36-PyYAML' } else { 'python3-pyyaml' }
  ensure_packages(['python3', $yaml])

  # koji
  file { "${homedir}/bin":
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
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
      ensure    => file,
      mode      => '0600',
      owner     => 'jenkins',
      group     => 'jenkins',
      content   => $koji_certificate,
      show_diff => false,
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
    # Tito was used in the past, but no longer. This cleans up the files we used to have.
    package { 'tito':
      ensure => absent,
    }

    file { "${homedir}/.titorc":
      ensure => absent,
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
