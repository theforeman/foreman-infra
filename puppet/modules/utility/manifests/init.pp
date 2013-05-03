class utility {
  include motd

  class { 'utility::repos': }

  package { "vim":
    ensure => present,
    name => $osfamily ? {
      Redhat => "vim-enhanced",
      default => "vim"
    }
  }

  package { "htop":
    ensure => present
  }

  package { "iftop":
    ensure => present
  }

  package { "screen":
    ensure => present
  }

  package { "rsync":
    ensure => present
  }

  package { "ruby-shadow":
    ensure => installed,
    name => $osfamily ? {
      Debian => "libshadow-ruby1.8",
      default => "ruby-shadow"
    }
  }

  # This can be expanded to include yum systems later
  case $::operatingsystem {
    fedora,redhat,centos,Scientific: {}
    Debian,Ubuntu: {
      package { ['puppet-common','puppet']:
        ensure  => '2.7.21-1puppetlabs1',
        require => Apt::Source['puppetlabs'],
      }
    }
    default: {}
  }

}
