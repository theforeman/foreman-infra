# uses a (slightly modified) 3rd-party pbuilder module to create
# tgz images of the specified OSs, as well as a hook script and an
# execution script. This can be use to build a package.
#
class debian {

  package { 'gem2deb': ensure => present }

  case $architecture {
    'amd64': {
      debian::pbuilder_setup {
        'wheezy64':
          ensure     => present,
          arch       => 'amd64',
          release    => 'wheezy',
          apturl     => 'http://ftp.us.debian.org/debian',
          aptcontent => "deb http://ftp.us.debian.org/debian/ wheezy main non-free contrib\ndeb-src http://ftp.us.debian.org/debian/ wheezy main non-free contrib\n";
        'wheezy32':
          ensure     => present,
          arch       => 'i386',
          release    => 'wheezy',
          apturl     => 'http://ftp.us.debian.org/debian',
          aptcontent => "deb http://ftp.us.debian.org/debian/ wheezy main non-free contrib\ndeb-src http://ftp.us.debian.org/debian/ wheezy main non-free contrib\n";
        'jessie64':
          ensure     => present,
          arch       => 'amd64',
          release    => 'jessie',
          apturl     => 'http://ftp.us.debian.org/debian',
          aptcontent => "deb http://ftp.us.debian.org/debian/ jessie main non-free contrib\ndeb-src http://ftp.us.debian.org/debian/ jessie main non-free contrib\n";
        'jessie32':
          ensure     => present,
          arch       => 'i386',
          release    => 'jessie',
          apturl     => 'http://ftp.us.debian.org/debian',
          aptcontent => "deb http://ftp.us.debian.org/debian/ jessie main non-free contrib\ndeb-src http://ftp.us.debian.org/debian/ jessie main non-free contrib\n";
        'precise64':
          ensure     => present,
          arch       => 'amd64',
          release    => 'precise',
          apturl     => 'http://ubuntu.osuosl.org/ubuntu/',
          aptcontent => "deb http://ubuntu.osuosl.org/ubuntu/ precise main restricted universe\ndeb-src http://ubuntu.osuosl.org/ubuntu/ precise main restricted universe\n";
        'precise32':
          ensure     => present,
          arch       => 'i386',
          release    => 'precise',
          apturl     => 'http://ubuntu.osuosl.org/ubuntu/',
          aptcontent => "deb http://ubuntu.osuosl.org/ubuntu/ precise main restricted universe\ndeb-src http://ubuntu.osuosl.org/ubuntu/ precise main restricted universe\n";
        'trusty64':
          ensure     => present,
          arch       => 'amd64',
          release    => 'trusty',
          apturl     => 'http://ubuntu.osuosl.org/ubuntu/',
          aptcontent => "deb http://ubuntu.osuosl.org/ubuntu/ trusty main restricted universe\ndeb-src http://ubuntu.osuosl.org/ubuntu/ trusty main restricted universe\n";
        'trusty32':
          ensure     => present,
          arch       => 'i386',
          release    => 'trusty',
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
        'wheezy':
          ensure     => present,
          arch       => 'armhf',
          release    => 'wheezy',
          apturl     => 'http://ftp.de.debian.org/debian',
          aptcontent => "deb http://ftp.de.debian.org/debian/ wheezy main non-free contrib\ndeb-src http://ftp.de.debian.org/debian/ wheezy main non-free contrib\n";
        'jessie':
          ensure     => present,
          arch       => 'armhf',
          release    => 'jessie',
          apturl     => 'http://ftp.de.debian.org/debian',
          aptcontent => "deb http://ftp.de.debian.org/debian/ jessie main non-free contrib\ndeb-src http://ftp.de.debian.org/debian/ jessie main non-free contrib\n";
        'precise':
          ensure     => present,
          arch       => 'armhf',
          release    => 'precise',
          apturl     => 'http://ports.ubuntu.com/ubuntu-ports',
          aptcontent => "deb http://ports.ubuntu.com/ubuntu-ports precise main restricted universe\ndeb-src http://ports.ubuntu.com/ubuntu-ports precise main restricted universe\n";
        'trusty':
          ensure     => present,
          arch       => 'armhf',
          release    => 'trusty',
          apturl     => 'http://ports.ubuntu.com/ubuntu-ports',
          aptcontent => "deb http://ports.ubuntu.com/ubuntu-ports trusty main restricted universe\ndeb-src http://ports.ubuntu.com/ubuntu-ports trusty main restricted universe\n";
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
        'jessie':
          ensure     => present,
          arch       => 'arm64',
          release    => 'jessie',
          apturl     => 'http://ftp.uk.debian.org/debian',
          aptcontent => "deb http://ftp.uk.debian.org/debian/ jessie main non-free contrib\ndeb-src http://ftp.uk.debian.org/debian/ jessie main non-free contrib\n";
        'trusty':
          ensure     => present,
          arch       => 'arm64',
          release    => 'trusty',
          apturl     => 'http://ports.ubuntu.com/ubuntu-ports',
          aptcontent => "deb http://ports.ubuntu.com/ubuntu-ports trusty main restricted universe\ndeb-src http://ports.ubuntu.com/ubuntu-ports trusty main restricted universe\n";
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
