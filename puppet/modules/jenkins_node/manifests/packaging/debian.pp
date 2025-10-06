# @api private
class jenkins_node::packaging::debian (
  String $user,
  Stdlib::Absolutepath $workspace,
  Boolean $uploader = true,
  Stdlib::HTTPUrl $debian_mirror = 'http://deb.debian.org/debian/',
  Stdlib::HTTPUrl $ubuntu_mirror = 'http://archive.ubuntu.com/ubuntu/',
) {
  package { 'gem2deb':
    ensure => present,
  }

  stdlib::ensure_packages(['python3-pip', 'python3-setuptools', 'zstd'])

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

  jenkins_node::pbuilder_setup {
    'bookworm64':
      ensure     => present,
      arch       => 'amd64',
      release    => 'bookworm',
      apturl     => $debian_mirror,
      aptcontent => "deb ${debian_mirror} bookworm main non-free contrib\ndeb-src ${debian_mirror} bookworm main non-free contrib\n",
      nodesource => true;
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
    content => file('jenkins_node/pbuilder_sudoers'),
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
