# All RPM packaging tools
# @api private
class slave::packaging::rpm (
  Stdlib::Absolutepath $homedir,
  String $user,
  Stdlib::Absolutepath $workspace,
  Optional[String] $koji_certificate = undef,
) {
  # TODO: Fix on EL8 and get rid of this
  $is_el8 = $facts['os']['release']['major'] == '8'

  package { ['koji', 'rpm-build', 'createrepo', 'copr-cli']:
    ensure => installed,
  }

  if $is_el8 {
    yumrepo { 'git-annex':
      name     => 'git-annex',
      baseurl  => 'https://downloads.kitenet.net/git-annex/linux/current/rpms/',
      enabled  => '1',
      gpgcheck => '0',
    } ->
    package { ['git-annex-standalone']:
      ensure => installed,
    }
  } else {
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

  secure_ssh::rsync::uploader_key { 'yumrepostage':
    user       => $user,
    dir        => "${workspace}/staging_key",
    manage_dir => true,
  }
}
