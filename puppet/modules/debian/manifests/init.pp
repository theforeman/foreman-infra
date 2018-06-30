# uses a 3rd-party pbuilder module to create
# tgz images of the specified OSs, as well as a hook script and an
# execution script. This can be use to build a package.
#
class debian {
  package { 'gem2deb':
    ensure => present,
  }

  case $::architecture {
    'amd64': {
      debian::pbuilder_setup {
        'bionic64':
          ensure     => present,
          arch       => 'amd64',
          release    => 'bionic',
          apturl     => 'http://ubuntu.osuosl.org/ubuntu/',
          aptcontent => "deb http://ubuntu.osuosl.org/ubuntu/ bionic main restricted universe\ndeb-src http://ubuntu.osuosl.org/ubuntu/ bionic main restricted universe\n";
        'bionic32':
          ensure     => present,
          arch       => 'i386',
          release    => 'bionic',
          apturl     => 'http://ubuntu.osuosl.org/ubuntu/',
          aptcontent => "deb http://ubuntu.osuosl.org/ubuntu/ bionic main restricted universe\ndeb-src http://ubuntu.osuosl.org/ubuntu/ bionic main restricted universe\n";
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
        'stretch64':
          ensure     => present,
          arch       => 'amd64',
          release    => 'stretch',
          puppetlabs => false,
          apturl     => 'http://ftp.us.debian.org/debian',
          aptcontent => "deb http://ftp.us.debian.org/debian/ stretch main non-free contrib\ndeb-src http://ftp.us.debian.org/debian/ stretch main non-free contrib\n";
        'stretch32':
          ensure     => present,
          arch       => 'i386',
          release    => 'stretch',
          puppetlabs => false,
          apturl     => 'http://ftp.us.debian.org/debian',
          aptcontent => "deb http://ftp.us.debian.org/debian/ stretch main non-free contrib\ndeb-src http://ftp.us.debian.org/debian/ stretch main non-free contrib\n";
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
          apturl     => 'http://ftp.de.debian.org/debian',
          aptcontent => "deb http://ftp.de.debian.org/debian/ jessie main non-free contrib\ndeb-src http://ftp.de.debian.org/debian/ jessie main non-free contrib\n";
        'stretch':
          ensure     => present,
          arch       => 'armhf',
          release    => 'stretch',
          puppetlabs => false,
          apturl     => 'http://ftp.de.debian.org/debian',
          aptcontent => "deb http://ftp.de.debian.org/debian/ stretch main non-free contrib\ndeb-src http://ftp.de.debian.org/debian/ stretch main non-free contrib\n";
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
        'bionic':
          ensure     => present,
          arch       => 'arm64',
          release    => 'bionic',
          apturl     => 'http://ports.ubuntu.com/ubuntu-ports',
          aptcontent => "deb http://ports.ubuntu.com/ubuntu-ports bionic main restricted universe\ndeb-src http://ports.ubuntu.com/ubuntu-ports bionic main restricted universe\n";
        'jessie':
          ensure     => present,
          arch       => 'arm64',
          release    => 'jessie',
          apturl     => 'http://ftp.de.debian.org/debian',
          aptcontent => "deb http://ftp.de.debian.org/debian/ jessie main non-free contrib\ndeb-src http://ftp.de.debian.org/debian/ jessie main non-free contrib\n";
        'stretch':
          ensure     => present,
          arch       => 'arm64',
          release    => 'stretch',
          puppetlabs => false,
          apturl     => 'http://ftp.de.debian.org/debian',
          aptcontent => "deb http://ftp.de.debian.org/debian/ stretch main non-free contrib\ndeb-src http://ftp.de.debian.org/debian/ stretch main non-free contrib\n";
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

  # Add freight setup
  include ::freight::uploader

  # TODO: Cleanup failed pbuilder mounts as a cron
}
