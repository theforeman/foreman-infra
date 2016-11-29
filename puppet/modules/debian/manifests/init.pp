# uses a (slightly modified) 3rd-party pbuilder module to create
# tgz images of the specified OSs, as well as a hook script and an
# execution script. This can be use to build a package.
#
class debian {

  package { 'gem2deb': ensure => present }

  case $::architecture {
    'amd64': {
      debian::pbuilder_setup {
        'jessie64':
          ensure     => present,
          arch       => 'amd64',
          release    => 'jessie',
          nodesource => true,
          apturl     => 'http://ftp.us.debian.org/debian',
          aptcontent => "deb http://ftp.us.debian.org/debian/ jessie main non-free contrib\ndeb-src http://ftp.us.debian.org/debian/ jessie main non-free contrib\n";
        'jessie32':
          ensure     => present,
          arch       => 'i386',
          release    => 'jessie',
          nodesource => true,
          apturl     => 'http://ftp.us.debian.org/debian',
          aptcontent => "deb http://ftp.us.debian.org/debian/ jessie main non-free contrib\ndeb-src http://ftp.us.debian.org/debian/ jessie main non-free contrib\n";
        'trusty64':
          ensure     => present,
          arch       => 'amd64',
          release    => 'trusty',
          nodesource => true,
          apturl     => 'http://ubuntu.osuosl.org/ubuntu/',
          aptcontent => "deb http://ubuntu.osuosl.org/ubuntu/ trusty main restricted universe\ndeb-src http://ubuntu.osuosl.org/ubuntu/ trusty main restricted universe\n";
        'trusty32':
          ensure     => present,
          arch       => 'i386',
          release    => 'trusty',
          nodesource => true,
          apturl     => 'http://ubuntu.osuosl.org/ubuntu/',
          aptcontent => "deb http://ubuntu.osuosl.org/ubuntu/ trusty main restricted universe\ndeb-src http://ubuntu.osuosl.org/ubuntu/ trusty main restricted universe\n";
        'xenial64':
          ensure     => present,
          arch       => 'amd64',
          release    => 'xenial',
          apturl     => 'http://ubuntu.osuosl.org/ubuntu/',
          aptcontent => "deb http://ubuntu.osuosl.org/ubuntu/ xenial main restricted universe\ndeb-src http://ubuntu.osuosl.org/ubuntu/ xenial main restricted universe\n";
        'xenial32':
          ensure     => present,
          arch       => 'i386',
          release    => 'xenial',
          apturl     => 'http://ubuntu.osuosl.org/ubuntu/',
          aptcontent => "deb http://ubuntu.osuosl.org/ubuntu/ xenial main restricted universe\ndeb-src http://ubuntu.osuosl.org/ubuntu/ xenial main restricted universe\n";
      }
    }

    'armv7l': {
      debian::pbuilder_setup {
        'jessie':
          ensure     => present,
          arch       => 'armhf',
          release    => 'jessie',
          nodesource => true,
          apturl     => 'http://ftp.de.debian.org/debian',
          aptcontent => "deb http://ftp.de.debian.org/debian/ jessie main non-free contrib\ndeb-src http://ftp.de.debian.org/debian/ jessie main non-free contrib\n";
        'xenial':
          ensure     => present,
          arch       => 'armhf',
          release    => 'xenial',
          apturl     => 'http://ports.ubuntu.com/ubuntu-ports',
          aptcontent => "deb http://ports.ubuntu.com/ubuntu-ports xenial main restricted universe\ndeb-src http://ports.ubuntu.com/ubuntu-ports xenial main restricted universe\n";
      }
    }

    'aarch64': {
      debian::pbuilder_setup {
        'xenial':
          ensure     => present,
          arch       => 'arm64',
          release    => 'xenial',
          apturl     => 'http://ports.ubuntu.com/ubuntu-ports',
          aptcontent => "deb http://ports.ubuntu.com/ubuntu-ports xenial main restricted universe\ndeb-src http://ports.ubuntu.com/ubuntu-ports xenial main restricted universe\n";
      }
    }
  }

  shellvar { 'extend_pbuilder_path':
    ensure   => present,
    target   => '/etc/pbuilderrc',
    variable => 'PATH',
    value    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin',
  }

  # Add freight setup
  include freight::uploader

  # TODO: Cleanup failed pbuilder mounts as a cron

}
