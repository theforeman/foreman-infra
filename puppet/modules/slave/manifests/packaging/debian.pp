# @api private
class slave::packaging::debian(
  String $user,
  Stdlib::Absolutepath $workspace,
  Boolean $uploader = true,
  Stdlib::HTTPUrl $debian_mirror = 'http://deb.debian.org/debian/',
  Stdlib::HTTPUrl $ubuntu_mirror = 'http://archive.ubuntu.com/ubuntu/',
) {
  package { 'gem2deb':
    ensure => present,
  }

  if $facts['os']['name'] == 'Debian' and versioncmp($facts['os']['release']['major'], '11') >= 0 {
    ensure_packages(['python3-pip', 'python3-setuptools'])
  } else {
    ensure_packages(['python-pip', 'python-setuptools'])
  }

  ensure_packages(['zstd'])

  if $facts['os']['name'] == 'Debian' {
    include apt::backports

    Class['Apt::Backports'] ->
    apt::pin { 'debootstrap':
      packages => 'debootstrap',
      priority => 500,
      release  => "${facts['os']['distro']['codename']}-backports",
    } ->
    Class['Pbuilder::Common']
  }

  slave::pbuilder_setup {
    'bionic64':
      ensure     => present,
      arch       => 'amd64',
      release    => 'bionic',
      apturl     => $ubuntu_mirror,
      aptcontent => "deb ${ubuntu_mirror} bionic main restricted universe\ndeb-src ${ubuntu_mirror} bionic main restricted universe\n";
    'bullseye64':
      ensure     => present,
      arch       => 'amd64',
      release    => 'bullseye',
      apturl     => $debian_mirror,
      aptcontent => "deb ${debian_mirror} bullseye main non-free contrib\ndeb-src ${debian_mirror} bullseye main non-free contrib\n";
    'buster64':
      ensure     => present,
      arch       => 'amd64',
      release    => 'buster',
      apturl     => $debian_mirror,
      aptcontent => "deb ${debian_mirror} buster main non-free contrib\ndeb-src ${debian_mirror} buster main non-free contrib\n";
    'focal64':
      ensure     => present,
      arch       => 'amd64',
      release    => 'focal',
      apturl     => $ubuntu_mirror,
      aptcontent => "deb ${ubuntu_mirror} focal main restricted universe\ndeb-src ${ubuntu_mirror} focal main restricted universe\n";
    'jammy64':
      ensure     => present,
      arch       => 'amd64',
      release    => 'jammy',
      apturl     => $ubuntu_mirror,
      aptcontent => "deb ${ubuntu_mirror} jammy main restricted universe\ndeb-src ${ubuntu_mirror} jammy main restricted universe\n";
  }

  include sudo
  sudo::conf { 'sudo-puppet-pbuilder-envkeep':
    ensure  => 'present',
    content => file('slave/pbuilder_sudoers'),
  }

  shellvar { 'extend_pbuilder_path':
    ensure   => present,
    target   => '/etc/pbuilderrc',
    variable => 'PATH',
    value    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  }

  if $uploader {
    # Add freight setup
    class { 'freight::uploader':
      user      => $user,
      workspace => $workspace,
    }
    contain freight::uploader
  }

  # TODO: Cleanup failed pbuilder mounts as a cron
}
