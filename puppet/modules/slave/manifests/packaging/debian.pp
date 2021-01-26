# @api private
class slave::packaging::debian(
  String $user,
  Stdlib::Absolutepath $workspace,
  Boolean $uploader = true,
) {
  package { 'gem2deb':
    ensure => present,
  }

  case $facts['os']['architecture'] {
    'amd64': {
      slave::pbuilder_setup {
        'bionic64':
          ensure     => present,
          arch       => 'amd64',
          release    => 'bionic',
          apturl     => 'http://ubuntu.osuosl.org/ubuntu/',
          aptcontent => "deb http://ubuntu.osuosl.org/ubuntu/ bionic main restricted universe\ndeb-src http://ubuntu.osuosl.org/ubuntu/ bionic main restricted universe\n";
        'buster64':
          ensure     => present,
          arch       => 'amd64',
          release    => 'buster',
          apturl     => 'http://deb.debian.org/debian',
          aptcontent => "deb http://deb.debian.org/debian/ buster main non-free contrib\ndeb-src http://deb.debian.org/debian/ buster main non-free contrib\n";
        'focal64':
          ensure     => present,
          arch       => 'amd64',
          release    => 'focal',
          apturl     => 'http://ubuntu.osuosl.org/ubuntu/',
          aptcontent => "deb http://ubuntu.osuosl.org/ubuntu/ focal main restricted universe\ndeb-src http://ubuntu.osuosl.org/ubuntu/ focal main restricted universe\n";
        'stretch64':
          ensure     => absent,
          arch       => 'amd64',
          release    => 'stretch',
          apturl     => 'http://deb.debian.org/debian',
          aptcontent => "deb http://deb.debian.org/debian/ stretch main non-free contrib\ndeb-src http://deb.debian.org/debian/ stretch main non-free contrib\n";
        'xenial64':
          ensure     => absent,
          arch       => 'amd64',
          release    => 'xenial',
          apturl     => 'http://ubuntu.osuosl.org/ubuntu/',
          aptcontent => "deb http://ubuntu.osuosl.org/ubuntu/ xenial main restricted universe\ndeb-src http://ubuntu.osuosl.org/ubuntu/ xenial main restricted universe\n";
      }
    }

    'armv7l': {
      slave::pbuilder_setup {
        'bionic':
          ensure     => present,
          arch       => 'armhf',
          release    => 'bionic',
          apturl     => 'http://ports.ubuntu.com/ubuntu-ports',
          aptcontent => "deb http://ports.ubuntu.com/ubuntu-ports bionic main restricted universe\ndeb-src http://ports.ubuntu.com/ubuntu-ports bionic main restricted universe\n";
        'buster':
          ensure     => present,
          arch       => 'armhf',
          release    => 'buster',
          apturl     => 'http://deb.debian.org/debian',
          aptcontent => "deb http://deb.debian.org/debian/ buster main non-free contrib\ndeb-src http://deb.debian.org/debian/ buster main non-free contrib\n";
        'stretch':
          ensure     => present,
          arch       => 'armhf',
          release    => 'stretch',
          apturl     => 'http://deb.debian.org/debian',
          aptcontent => "deb http://deb.debian.org/debian/ stretch main non-free contrib\ndeb-src http://deb.debian.org/debian/ stretch main non-free contrib\n";
        'xenial':
          ensure     => present,
          arch       => 'armhf',
          release    => 'xenial',
          apturl     => 'http://ports.ubuntu.com/ubuntu-ports',
          aptcontent => "deb http://ports.ubuntu.com/ubuntu-ports xenial main restricted universe\ndeb-src http://ports.ubuntu.com/ubuntu-ports xenial main restricted universe\n";
      }
    }

    'aarch64': {
      slave::pbuilder_setup {
        'bionic':
          ensure     => present,
          arch       => 'arm64',
          release    => 'bionic',
          apturl     => 'http://ports.ubuntu.com/ubuntu-ports',
          aptcontent => "deb http://ports.ubuntu.com/ubuntu-ports bionic main restricted universe\ndeb-src http://ports.ubuntu.com/ubuntu-ports bionic main restricted universe\n";
        'buster':
          ensure     => present,
          arch       => 'arm64',
          release    => 'buster',
          apturl     => 'http://deb.debian.org/debian',
          aptcontent => "deb http://deb.debian.org/debian/ buster main non-free contrib\ndeb-src http://deb.debian.org/debian/ buster main non-free contrib\n";
        'stretch':
          ensure     => present,
          arch       => 'arm64',
          release    => 'stretch',
          apturl     => 'http://deb.debian.org/debian',
          aptcontent => "deb http://deb.debian.org/debian/ stretch main non-free contrib\ndeb-src http://deb.debian.org/debian/ stretch main non-free contrib\n";
        'xenial':
          ensure     => present,
          arch       => 'arm64',
          release    => 'xenial',
          apturl     => 'http://ports.ubuntu.com/ubuntu-ports',
          aptcontent => "deb http://ports.ubuntu.com/ubuntu-ports xenial main restricted universe\ndeb-src http://ports.ubuntu.com/ubuntu-ports xenial main restricted universe\n";
      }
    }
    default: {}
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
