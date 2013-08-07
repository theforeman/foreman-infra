class utility($sysadmins = ['/dev/null']) {
  include motd

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

  # TODO: replace with theforeman/puppet-puppet
  $osmajor = regsubst($::operatingsystemrelease, '\..*', '')
  $puppet_packages = $::osfamily ? {
    Debian => ['puppet-common','puppet'],
    RedHat => ['puppet']
  }
  package { $puppet_packages:
    ensure => present
  }

  mailalias { 'sysadmins':
    ensure    => present,
    recipient => $sysadmins,
  }
  mailalias { 'root':
    ensure    => present,
    recipient => 'sysadmins',
  }
}
