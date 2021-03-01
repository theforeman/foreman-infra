# @api private
class slave::packaging::debian(
  String $user,
  Stdlib::Absolutepath $workspace,
  Boolean $uploader = true,
  Stdlib::HTTPUrl $debian_mirror = 'http://deb.debian.org/debian/',
  Stdlib::HTTPUrl $ubuntu_mirror = 'http://ubuntu.osuosl.org/ubuntu/',
) {
  package { 'gem2deb':
    ensure => present,
  }

  include apt::backports

  Class['Apt::Backports'] ->
  apt::pin { 'debootstrap':
    packages => 'debootstrap',
    priority => 500,
    release  => 'buster-backports',
  } ->
  Class['Pbuilder::Common']

  slave::pbuilder_setup {
    'bionic64':
      ensure     => present,
      arch       => 'amd64',
      release    => 'bionic',
      apturl     => $ubuntu_mirror,
      aptcontent => "deb ${ubuntu_mirror} bionic main restricted universe\ndeb-src ${ubuntu_mirror} bionic main restricted universe\n";
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
